"""Run the authorized SD1.5 CLIP MNN model on CPU from anonymous memory.

Requires MNN and numpy. The model member stays in the original ZIP; only the
derived last_hidden_state tensor is written to a new scratch output path.
"""

import argparse
import hashlib
import os
import zipfile
from pathlib import Path


MEMBER = "output_512/qnn_models_8gen2/clip_v2.mnn"
MODEL_SIZE = 156316304
MODEL_SHA256 = "61a14cec536964d2ea32244b7cc47e28df62fa4d3f11e955aadf06401c0a9d9e"
SHAPE = (1, 77, 768)


def model_memfd(archive):
    if archive.getinfo(MEMBER).file_size != MODEL_SIZE:
        raise ValueError("unexpected CLIP model size")
    fd = os.memfd_create("ternux-clip-mnn", flags=0)
    try:
        digest = hashlib.sha256()
        with archive.open(MEMBER) as source, os.fdopen(os.dup(fd), "wb") as target:
            while chunk := source.read(1024 * 1024):
                digest.update(chunk)
                target.write(chunk)
        if digest.hexdigest() != MODEL_SHA256:
            raise ValueError("unexpected CLIP model SHA-256")
        return fd
    except BaseException:
        os.close(fd)
        raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=Path, required=True)
    parser.add_argument("--input", type=Path, required=True,
                        help="77x768 little-endian FP32 input_embedding")
    parser.add_argument("--output", type=Path, required=True,
                        help="new scratch path for FP32 last_hidden_state")
    args = parser.parse_args()
    try:
        import MNN
        import numpy as np
    except ImportError as error:
        parser.error(f"MNN and numpy are required: {error}")
    if args.input.stat().st_size != 77 * 768 * 4:
        raise ValueError("unexpected CLIP input size")
    data = np.fromfile(args.input, dtype="<f4").reshape(SHAPE)
    if not np.isfinite(data).all():
        raise ValueError("non-finite CLIP input")

    with zipfile.ZipFile(args.archive) as archive:
        fd = model_memfd(archive)
    try:
        interpreter = MNN.Interpreter(f"/proc/self/fd/{fd}")
        session = interpreter.createSession({"backend": "CPU", "thread": 1})
        input_tensor = interpreter.getSessionInput(session, "input_embedding")
        output_tensor = interpreter.getSessionOutput(session, "last_hidden_state")
        if input_tensor.getShape() != SHAPE or output_tensor.getShape() != SHAPE:
            raise ValueError("unexpected MNN tensor shape")
        host = MNN.Tensor(SHAPE, MNN.Halide_Type_Float, data,
                          input_tensor.getDimensionType())
        hashes = []
        for run in range(3):
            if not input_tensor.copyFrom(host):
                raise RuntimeError("MNN input copy failed")
            actual_input = input_tensor.getNumpyData()
            if not np.array_equal(actual_input, data):
                raise RuntimeError("MNN input differs from source tensor")
            interpreter.runSession(session)
            output = np.array(output_tensor.getNumpyData(), copy=True)
            if output.shape != SHAPE or not np.isfinite(output).all():
                raise RuntimeError("unexpected or non-finite CLIP output")
            hashes.append(hashlib.sha256(output.tobytes()).hexdigest())
            print("run", run + 1, "output_sha256", hashes[-1], flush=True)
        if len(set(hashes)) != 1:
            raise RuntimeError("CLIP output did not repeat exactly")
        with args.output.open("xb") as target:
            target.write(output.astype("<f4", copy=False).tobytes())
        print("output", args.output, "shape", SHAPE, "sha256", hashes[0])
    finally:
        os.close(fd)


if __name__ == "__main__":
    main()
