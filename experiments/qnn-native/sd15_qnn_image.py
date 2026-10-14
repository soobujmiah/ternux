#!/usr/bin/env python3
"""Run one fixed-seed SD1.5 image using the in-place QNN archive.

CLIP runs on CPU through the archive's MNN model. UNet and VAE decoder run on
Qualcomm HTP through a persistent Android/Bionic helper. Model ZIP members are
streamed to sealed anonymous memfds; only the final PNG and text logs touch disk.
"""

import argparse
from contextlib import ExitStack
import hashlib
import json
import math
import os
from pathlib import Path
import struct
import subprocess
import time
import zipfile
import zlib

import numpy as np

from archive_input import DECODER_SHA256, UNET_SHA256, member_fd
from clip_archive_probe import EXPECTED_SHA256, PREFIX, stream_memfd
from clip_conditioning import WIDTH, ROWS, build_input, padded_ids
from clip_mnn_probe import MODEL_SHA256, MODEL_SIZE, MEMBER as CLIP_MEMBER


def _read_exact(stream, size):
    data = bytearray()
    while len(data) < size:
        part = stream.read(size - len(data))
        if not part:
            raise EOFError(f"helper closed its response after {len(data)} of {size} bytes")
        data.extend(part)
    return bytes(data)


def _write_png(path, raw_u16, scale, offset):
    values = np.frombuffer(raw_u16, dtype="<u2").astype(np.float32)
    if values.size != 3 * 512 * 512 or not np.isfinite(scale) or scale <= 0:
        raise ValueError("decoder returned an invalid tensor or quantizer")
    pixels = ((values + offset) * scale + 1.0) * 127.5
    pixels = np.clip(np.rint(pixels), 0, 255).astype(np.uint8)
    pixels = pixels.reshape(3, 512, 512).transpose(1, 2, 0)
    rows = b"".join(b"\x00" + pixels[y].tobytes() for y in range(512))

    def chunk(name, payload):
        body = name + payload
        return struct.pack(">I", len(payload)) + body + struct.pack(">I", zlib.crc32(body))

    png = (b"\x89PNG\r\n\x1a\n" +
           chunk(b"IHDR", struct.pack(">IIBBBBB", 512, 512, 8, 2, 0, 0, 0)) +
           chunk(b"IDAT", zlib.compress(rows, 6)) + chunk(b"IEND", b""))
    with Path(path).open("xb") as output:
        output.write(png)
    return hashlib.sha256(png).hexdigest(), len(png)


def dpm_schedule(steps):
    """SD1.5 scaled-linear training noise schedule and leading DPM++ steps."""
    if not 2 <= steps <= 50:
        raise ValueError("steps must be between 2 and 50")
    beta = np.linspace(math.sqrt(0.00085), math.sqrt(0.012), 1000, dtype=np.float64) ** 2
    alpha_bar = np.cumprod(1.0 - beta)
    sigmas_all = np.sqrt((1.0 - alpha_bar) / alpha_bar)
    timesteps = np.floor((steps - np.arange(steps, dtype=np.float64)) * 999.0 / steps + 0.5).astype(np.int32)
    sigmas = np.concatenate((sigmas_all[timesteps], np.array([0.0])))
    return timesteps, sigmas


def dpm_step(sample, epsilon, index, sigmas, prior_x0):
    sigma = float(sigmas[index])
    sigma_next = float(sigmas[index + 1])
    alpha = 1.0 / math.sqrt(1.0 + sigma * sigma)
    sigma_t = sigma * alpha
    x0 = (sample - sigma_t * epsilon) / alpha
    if sigma_next == 0.0:
        return x0, x0
    alpha_next = 1.0 / math.sqrt(1.0 + sigma_next * sigma_next)
    h = math.log(sigma / sigma_next)
    ratio = math.exp(-h) - 1.0
    if not prior_x0:
        updated = (sigma_next / sigma) * sample - alpha_next * ratio * x0
    else:
        sigma_previous = float(sigmas[index - 1])
        h_previous = math.log(sigma_previous / sigma)
        r0 = h_previous / h
        correction = (x0 - prior_x0[-1]) / r0
        updated = ((sigma_next / sigma) * sample - alpha_next * ratio * x0
                   - 0.5 * alpha_next * ratio * correction)
    return updated.astype(np.float32, copy=False), x0.astype(np.float32, copy=False)


def _clip_hidden(archive, prompts):
    from tokenizers import Tokenizer
    import MNN

    tokenizer_name = PREFIX + "tokenizer.json"
    tokenizer_bytes = archive.read(tokenizer_name)
    if hashlib.sha256(tokenizer_bytes).hexdigest() != EXPECTED_SHA256["tokenizer.json"]:
        raise ValueError("unexpected tokenizer SHA-256")
    tokenizer = Tokenizer.from_str(tokenizer_bytes.decode("utf-8"))

    with ExitStack() as stack:
        token_fd = stream_memfd(archive, "token_emb.bin")
        stack.callback(os.close, token_fd)
        pos_fd = stream_memfd(archive, "pos_emb.bin")
        stack.callback(os.close, pos_fd)
        clip_info = archive.getinfo(CLIP_MEMBER)
        if clip_info.file_size != MODEL_SIZE:
            raise ValueError("unexpected CLIP model size")
        model_fd = os.memfd_create("ternux-sd15-clip", 0)
        stack.callback(os.close, model_fd)
        digest = hashlib.sha256()
        with archive.open(CLIP_MEMBER) as source:
            while chunk := source.read(1024 * 1024):
                digest.update(chunk)
                view = memoryview(chunk)
                while view:
                    n = os.write(model_fd, view)
                    if n <= 0:
                        raise OSError("short CLIP memfd write")
                    view = view[n:]
        if digest.hexdigest() != MODEL_SHA256:
            raise ValueError("unexpected CLIP model SHA-256")

        interpreter = MNN.Interpreter(f"/proc/self/fd/{model_fd}")
        session = interpreter.createSession({"backend": "CPU", "thread": 1})
        input_tensor = interpreter.getSessionInput(session, "input_embedding")
        output_tensor = interpreter.getSessionOutput(session, "last_hidden_state")
        expected_shape = (1, ROWS, WIDTH)
        if tuple(input_tensor.getShape()) != expected_shape or tuple(output_tensor.getShape()) != expected_shape:
            raise ValueError("unexpected MNN CLIP tensor shape")

        result = []
        for prompt in prompts:
            content_ids = tokenizer.encode(prompt, add_special_tokens=False).ids
            ids = padded_ids(content_ids)
            values = build_input(content_ids, Path(f"/proc/self/fd/{token_fd}"),
                                 Path(f"/proc/self/fd/{pos_fd}"))
            data = np.asarray(values, dtype="<f4").reshape(expected_shape)
            host = MNN.Tensor(expected_shape, MNN.Halide_Type_Float, data,
                              input_tensor.getDimensionType())
            if not input_tensor.copyFrom(host):
                raise RuntimeError("MNN CLIP input copy failed")
            if not np.array_equal(input_tensor.getNumpyData(), data):
                raise RuntimeError("MNN CLIP input readback mismatch")
            start = time.monotonic()
            interpreter.runSession(session)
            hidden = np.array(output_tensor.getNumpyData(), dtype="<f4", copy=True)
            if hidden.shape != expected_shape or not np.isfinite(hidden).all():
                raise RuntimeError("MNN CLIP output is invalid")
            print(json.dumps({"stage": "clip_cpu", "prompt": prompt,
                              "content_ids": content_ids, "token_ids": ids,
                              "seconds": round(time.monotonic() - start, 4),
                              "sha256": hashlib.sha256(hidden.tobytes()).hexdigest()}), flush=True)
            result.append(hidden.reshape(-1))
        return result


def _start_server(helper, fd, mode, runtime_dir, log_file):
    env = os.environ.copy()
    env.pop("LD_PRELOAD", None)
    runtime_path = str(runtime_dir.resolve())
    env["LD_LIBRARY_PATH"] = runtime_path + ":/vendor/lib64:/vendor/lib64/egl:/system/lib64"
    env["ADSP_LIBRARY_PATH"] = runtime_path
    proc = subprocess.Popen(["/system/bin/linker64", str(helper), "--fd", str(fd), mode],
                            stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                            stderr=log_file, env=env, pass_fds=(fd,))
    ready = None
    while True:
        line = proc.stdout.readline()
        if not line:
            code = proc.wait()
            raise RuntimeError(f"{mode} helper exited before ready (status {code}); see {log_file.name}")
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            raise RuntimeError(f"non-JSON helper startup output: {line[:200]!r}")
        if event.get("stage") == "qnn_server_ready":
            ready = event
            break
        print(json.dumps(event), flush=True)
    return proc, ready


def _qnn_run_unet(proc, ready, sample, timestep, embedding):
    sample = np.asarray(sample, dtype="<f4").reshape(4 * 64 * 64)
    embedding = np.asarray(embedding, dtype="<f4").reshape(77 * 768)
    if not np.isfinite(sample).all() or not np.isfinite(embedding).all():
        raise ValueError("non-finite UNet input")
    proc.stdin.write(struct.pack("<Ii", 1, int(timestep)))
    proc.stdin.write(sample.tobytes())
    proc.stdin.write(embedding.tobytes())
    proc.stdin.flush()
    status = struct.unpack("<i", _read_exact(proc.stdout, 4))[0]
    if status:
        raise RuntimeError(f"QNN UNet graph returned failure status {status}")
    encoded = np.frombuffer(_read_exact(proc.stdout, 4 * 64 * 64 * 2), dtype="<u2").astype(np.float32)
    result = (encoded + ready["output_offset"]) * ready["output_scale"]
    return result.reshape(1, 4, 64, 64)


def _qnn_decode(proc, ready, latents):
    latents = np.asarray(latents, dtype="<f4").reshape(4 * 64 * 64)
    if not np.isfinite(latents).all():
        raise ValueError("non-finite VAE decoder input")
    proc.stdin.write(struct.pack("<I", 2))
    proc.stdin.write(latents.tobytes())
    proc.stdin.flush()
    status = struct.unpack("<i", _read_exact(proc.stdout, 4))[0]
    if status:
        raise RuntimeError(f"QNN VAE decoder returned failure status {status}")
    return _read_exact(proc.stdout, 3 * 512 * 512 * 2)


def run(args):
    archive_path = Path(args.archive)
    helper = Path(args.helper)
    runtime_dir = Path(args.runtime_dir)
    output = Path(args.output)
    for path in (archive_path, helper):
        if not path.is_file():
            raise FileNotFoundError(path)
    if not runtime_dir.is_dir():
        raise FileNotFoundError(runtime_dir)
    if output.exists():
        raise FileExistsError(output)
    timesteps, sigmas = dpm_schedule(args.steps)
    start_total = time.monotonic()

    with zipfile.ZipFile(archive_path) as archive:
        negative, positive = _clip_hidden(archive, [args.negative_prompt, args.prompt])

        unet_log = Path(str(output) + ".unet.log")
        with unet_log.open("xb") as log_file:
            with member_fd(archive_path, "unet.bin") as (unet_fd, evidence):
                if evidence["sha256"] != UNET_SHA256:
                    raise ValueError("UNet context SHA-256 mismatch")
                print(json.dumps({"stage": "model_stream", **evidence}), flush=True)
                proc, ready = _start_server(helper, unet_fd, "--serve-unet", runtime_dir, log_file)
                if ready.get("kind") != "unet":
                    raise RuntimeError("unexpected UNet helper handshake")
                rng = np.random.default_rng(args.seed)
                latent = rng.standard_normal((1, 4, 64, 64), dtype=np.float32) * np.float32(sigmas[0])
                prior_x0 = []
                try:
                    for index, timestep in enumerate(timesteps):
                        step_start = time.monotonic()
                        # The denoiser consumes a sigma-scaled model input;
                        # the DPM solver below keeps the unscaled sample.
                        sigma = np.float32(sigmas[index])
                        model_input = latent / np.sqrt(sigma * sigma + np.float32(1.0))
                        uncond = _qnn_run_unet(proc, ready, model_input, timestep, negative)
                        cond = _qnn_run_unet(proc, ready, model_input, timestep, positive)
                        epsilon = uncond + args.cfg * (cond - uncond)
                        latent, x0 = dpm_step(latent, epsilon, index, sigmas, prior_x0)
                        prior_x0.append(x0)
                        prior_x0 = prior_x0[-2:]
                        if not np.isfinite(latent).all():
                            raise RuntimeError(f"non-finite latent after step {index}")
                        print(json.dumps({"stage": "unet_step", "index": index + 1,
                                          "total": len(timesteps), "timestep": int(timestep),
                                          "seconds": round(time.monotonic() - step_start, 3),
                                          "latent_min": float(latent.min()),
                                          "latent_max": float(latent.max()),
                                          "latent_std": float(latent.std())}), flush=True)
                    proc.stdin.write(struct.pack("<I", 0))
                    proc.stdin.flush()
                    if proc.wait(timeout=30) != 0:
                        raise RuntimeError(f"UNet helper failed; see {unet_log}")
                except BaseException:
                    if proc.poll() is None:
                        proc.kill()
                        proc.wait()
                    raise

        decoder_log = Path(str(output) + ".decoder.log")
        with decoder_log.open("xb") as log_file:
            with member_fd(archive_path, "vae_decoder.bin") as (decoder_fd, evidence):
                if evidence["sha256"] != DECODER_SHA256:
                    raise ValueError("decoder context SHA-256 mismatch")
                print(json.dumps({"stage": "model_stream", **evidence}), flush=True)
                proc, ready = _start_server(helper, decoder_fd, "--serve-decoder", runtime_dir, log_file)
                if ready.get("kind") != "decoder":
                    if proc.poll() is None:
                        proc.kill()
                        proc.wait()
                    raise RuntimeError("unexpected decoder helper handshake")
                try:
                    # SD 1.5 VAE latents are scaled by 0.18215 before decoding.
                    raw = _qnn_decode(proc, ready, latent / np.float32(0.18215))
                    proc.stdin.write(struct.pack("<I", 0))
                    proc.stdin.flush()
                    if proc.wait(timeout=30) != 0:
                        raise RuntimeError(f"decoder helper failed; see {decoder_log}")
                except BaseException:
                    if proc.poll() is None:
                        proc.kill()
                        proc.wait()
                    raise
        digest, size = _write_png(output, raw, ready["output_scale"], ready["output_offset"])
    print(json.dumps({"stage": "image_complete", "path": str(output),
                      "bytes": size, "sha256": digest, "width": 512, "height": 512,
                      "seed": args.seed, "steps": args.steps, "cfg": args.cfg,
                      "scheduler": "DPM++ 2M, scaled-linear beta, leading spacing",
                      "total_seconds": round(time.monotonic() - start_total, 3),
                      "image_oracle": "visual_review_and_seed_repeat_only",
                      "model_copy_to_disk": False}), flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", required=True)
    parser.add_argument("--helper", required=True)
    parser.add_argument("--runtime-dir", required=True)
    parser.add_argument("--output", required=True, help="new PNG path; never overwrites")
    parser.add_argument("--prompt", default="photorealistic landscape photograph of a quiet tropical river at dawn, thin mist above water, forested hills in the distance, natural soft golden light, realistic colors, fine photographic detail")
    parser.add_argument("--negative-prompt", default="illustration, painting, cartoon, CGI, 3d render, text, watermark, low resolution, blurry, oversaturated")
    parser.add_argument("--steps", type=int, default=20)
    parser.add_argument("--cfg", type=float, default=7.5)
    parser.add_argument("--seed", type=int, default=20261014)
    args = parser.parse_args()
    if not math.isfinite(args.cfg) or not 1.0 <= args.cfg <= 20.0:
        parser.error("--cfg must be finite and in [1,20]")
    run(args)


if __name__ == "__main__":
    main()
