# Standalone Android QNN discovery from Debian PRoot

## SD1.5 CLIP input preparation (2026-10-14)

I added [`clip_conditioning.py`](clip_conditioning.py) as an independent CPU-side
preparation step. Given already-tokenized content IDs, `token_emb.bin` and
`pos_emb.bin`, it emits 77 x 768 little-endian FP32 values for MNN's
`input_embedding`. It uses BOS 49406, EOS/pad 49407 and at most 75 content
tokens. It accepts either an FP16 token table or a legacy FP32 token table;
FP32 token values are narrowed to FP16 before lookup, matching the reference's
table handling. Position values remain FP32. A synthetic sparse-table unit
test checks row selection, padding, weight multiplication and position addition.

This module does not tokenize prompt text or execute `clip_v2.mnn`. Its token ID
contract comes from the pinned Local Dream reference, but actual compatibility
with the archive's tokenizer, tables and MNN model is not yet verified. No
model archive or Qualcomm runtime was accessed for this step.

```bash
python3 -m unittest discover -s experiments/qnn-native -p 'test_clip_conditioning.py' -v
python3 experiments/qnn-native/clip_conditioning.py \
  --content-ids-json /absolute/scratch/content-ids.json \
  --token-emb /absolute/scratch/token_emb.bin \
  --pos-emb /absolute/scratch/pos_emb.bin \
  --output /absolute/scratch/input_embedding.f32
```

The output path must be new. The example paths are placeholders; model members
must stay within the existing archive handling boundary and must not be
committed or redistributed.

The [2026-10-13 engineering handoff](HANDOFF-2026-10-13.md) records the exact
stop point, verified device evidence and the next work for another agent.

This is an experimental, independently written Android/Bionic helper, not an
installed extension or a Stable Diffusion inference implementation. Local Dream
is a source reference only; it is not required or installed.

## Verified on 2026-10-13

I ran `probe.c` on Redmi Turbo 4 Pro / SM8735 / Android 16 from Debian 13 ARM64
PRoot through `/system/bin/linker64`. The existing vendor HTP and System
libraries loaded without being copied. Both provider queries returned status
0 and one provider. HTP reported core API 2.22.0, backend API 5.29.0, and runtime
build `v2.29.0.241129103708_105762`. The API getter agreed with the provider
prefix. Backend creation returned status 0 with a non-null handle; freeing it
returned status 0. The exact sanitized output is
[the discovery record](redmi-sm8735-discovery-2026-10-13.jsonl).

These results establish Android runtime discovery and backend initialization.
They do not establish a DSP session, context/model loading, graph execution, or
correct NPU inference. The native QNN experiment is separate from the existing
Debian/glibc llama.cpp Hexagon experiment.

## Reproduce the bounded probe

The source uses a bounded public API prefix and checks the observed core API
before invoking backend functions. The CI-built VAE metadata probe saw one
`model` graph: input `input` [1,3,512,512] and outputs `mean` and `std`
[1,4,64,64], all QNN UFIXED_POINT_16. The decoder has one `model` graph,
input `input` [1,4,64,64] and output `output` [1,3,512,512], also
UFIXED_POINT_16. These shapes were repeated on the physical device. Correct
tensor numerics still need an independent oracle.

Build the Android/Bionic helper in GitHub Actions with the pinned NDK
28.2.13676358 using [`qnn-native-probe.yml`](../../.github/workflows/qnn-native-probe.yml).
The PRoot Debian workstation runs `archive_input.py` and launches the Android
helper through `/system/bin/linker64`; the Debian llama.cpp build uses a Linux
ARM64/glibc toolchain. No native Termux include or compiler path is part of the
supported build. The earlier exploratory device result used Termux Clang and is
kept as historical evidence only. The CI-built ELF subsequently repeated the
device checks; the artifact is still experimental, not a release package.

The pinned NDK build passed [run 38405297620](https://github.com/soobujmiah/ternux/actions/runs/38405297620)
at commit `ddbece7009ab5d062d312da3999c1c6c70205a6e`. Its artifact is
`ternux-qnn-native-probe-android-arm64` (expires 2026-10-27). The owner
explicitly authorized downloading this **test artifact** in this session.
It and the later graph probe artifact from
[run 38406862573](https://github.com/soobujmiah/ternux/actions/runs/38406862573)
were downloaded to isolated scratch. After unzipping, run
`sha256sum -c SHA256SUMS` from inside that directory. The workflow checked
AArch64 ELF and rejected Termux-specific RUNPATHs. The downloaded CI ELF has
only `libc.so` and `libdl.so` dependencies, no RUNPATH, and passed physical
device checks on SM8735. No Qualcomm library or model is in it.

```bash
# In PRoot, after the authorized artifact is in scratch and checksums pass:
env -u LD_PRELOAD \
  LD_LIBRARY_PATH=/vendor/lib64:/vendor/lib64/egl:/system/lib64 \
  /system/bin/linker64 /absolute/path/to/ternux-qnn-native-probe
```

## VAE context load on the physical device

The owner-authorized archive stayed at its original `/sdcard/Llms/` path.
`archive_input.py` streamed only `vae_encoder.bin` into a sealed anonymous
memfd, verified the ZIP CRC and SHA-256, and passed the FD to `context_inspect.c`.
No model member was extracted to disk. The member was 41,438,176 bytes with
SHA-256 `c7bd0cf7cce2cda7b073379bef97f58f5c0ea850d8e3d86933a5939f80570faa`.
QNN System 1.2.0 reported binary metadata version 3, backend ID 6, compiled
core API 2.21.0/backend API 5.28.0, build
`v2.28.0.241029232508_102474`. The metadata output size was zero despite a
valid metadata pointer/status 0, so it is not a byte count of the graph.

The first device-create attempt **failed** with QNN status 14001: Android's
linker could not access the existing vendor `libQnnHtpV73Stub.so` from this
process. Qualcomm's official `qnn-runtime` 2.29.0 Maven AAR contains a V73 stub
and skel. The AAR was downloaded to scratch, SHA-256
`6fc813b1195801462ef6c8f70a2d7767eec7fb4e75f64db032c63b3f81ad9c00`.
Its AI Stack License permits copying for application development and benchmarking
but prohibits standalone redistribution. No Qualcomm binary is committed here
or approved as a Ternux release asset. The two necessary files were extracted
only to scratch. The helper used those runtime files through `LD_LIBRARY_PATH`
and `ADSP_LIBRARY_PATH`, without changing Android permissions or firmware.

On Redmi Turbo 4 Pro / SM8735, Android 16, the retry returned **status 0** for
HTP backend create, device create, VAE context create-from-binary, and all
context/device/backend/logger free calls. The QNN log reported CDSP transport,
SM8735 detection, one graph named `model`, weight transfer and successful
context deserialization. The CI-built helper repeated context and graph
retrieval for both VAE encoder and decoder. This verifies **compatible VAE
context loading** for this device/process/runtime combination. It does not
verify a correct image, UNet, CLIP, or independent tensor numerics.

The initial successful-load process then crashed during `dlclose` of HTP,
after all QNN handle free calls returned 0. The short-lived helper now retains
that library until process exit after explicit handle cleanup; the repeated
probe exited 0. Keep this lifecycle limitation when designing a persistent
helper. Full raw logs are local scratch evidence under
`/home/sbj/npu-probe-2026-10-13/qnn-context-vae-encoder-official-runtime-final.txt`.

Reproduce with the **CI-built** helper and a licensed QNN 2.29.0 Android
runtime directory containing the V73 stub/skel. The archive remains at its
original path:

```bash
python3 experiments/qnn-native/archive_input.py \
  --archive /sdcard/Llms/AbsoluteReality_qnn2.28_8gen2.zip \
  --member vae_encoder.bin \
  --inspect-helper /absolute/path/to/ternux-qnn-context-inspect \
  --load-htp --runtime-dir /absolute/path/to/licensed/qnn-2.29-v73-runtime
```

For a bounded graph execute probe, replace `--load-htp` with `--execute-htp`.
This option currently accepts only `vae_encoder.bin`. CI run `38406862573` on
the physical device executed that graph twice with one fixed raw zero `uint16`
input. Both QNN calls returned status 0, CDSP logs reported graph completion,
both output buffers changed, and each output repeated bit-for-bit. The FNV64
hashes were `ae97b25a95bdac33` (`mean`) and `7fb11db45bb92b10` (`std`)
on both runs. This is **verified HTP graph execution and repeatability**, not a
known-output correctness result. The raw log is local scratch evidence at
`/home/sbj/npu-probe-2026-10-13/ci-qnn-vae-execute-run-38406862573.log`.

The decoder context load and graph retrieve also returned status 0. Its member
was 59,945,848 bytes, SHA-256
`42edf1474eea665f593b8c35daf64169da220b6e4095c860eaca494610579ccc`.
No decoder graph execution was attempted. Neither VAE member was copied to disk.

The same CI-built helper inspected and loaded `unet.bin` from the original ZIP
through a sealed anonymous memfd. Its 880,827,736 bytes had SHA-256
`32ab6474a0bf5150f484dc48d68a7db22d56bc9a908edb9620a839daf47c9f60`.
The `model` graph has `sample` [1,4,64,64] UFIXED_POINT_16, `timestamp`
[1] datatype 50, and `text_embedding` [1,77,768] UFIXED_POINT_16 inputs;
`output` is [1,4,64,64] UFIXED_POINT_16. HTP backend/device/context create,
CDSP graph retrieve, and all handle cleanup returned status 0. This verifies
UNet context compatibility for this exact process/runtime, not UNet execution
or image generation. Raw local log:
`/home/sbj/npu-probe-2026-10-13/ci-qnn-unet-load-run-38406862573.log`.

## Remaining inference gates

The opt-in [`known_add.c`](known_add.c) diagnostic was built by the pinned
Android NDK workflow. [CI run 38411428947](https://github.com/soobujmiah/ternux/actions/runs/38411428947)
passed and its checksum-verified AArch64 artifact ran on Redmi Turbo 4 Pro /
SM8735 / Android 16 from Debian PRoot. It constructed a 64-element
UFIXED_POINT_16 `ElementWiseAdd` graph. Backend, device, context, graph,
three tensors, node, finalize, execute, and all handle cleanup returned 0.
Every output matched an independently calculated integer sum: 0 mismatches
of 64. Verbose QNN logs identify the V73 skeleton on `cdsp`, an active
transport session and completed graph execution. This is **verified
known-answer QNN HTP tensor computation through a PRoot-launched Bionic
process**. It does not prove the VAE/UNet outputs are numerically correct.

The first attempt returned QNN tensor status 7004 because the probe attached
APP_WRITE client buffers during tensor registration. HTP requires those
buffers to be null until graph execution. The corrected CI build registered
tensors first and then attached buffers. A matching licensed QNN 2.29
`libQnnHtpPrepare.so`, V73 stub and skel were used in isolated scratch,
extracted from the official runtime AAR. The Prepare file SHA-256 was
`3aff1dcffde399a41ac13ad6a933a49f67c0ef26df5acc876731884a7c735294`.
Neither it nor any Qualcomm runtime is in the CI artifact or Ternux repo.

After verifying the CI artifact with `sha256sum -c SHA256SUMS`, the bounded
reproduction from Debian PRoot is:

```bash
env -u LD_PRELOAD \
  LD_LIBRARY_PATH=/absolute/path/to/licensed/qnn-2.29-v73-runtime:/vendor/lib64:/vendor/lib64/egl:/system/lib64 \
  ADSP_LIBRARY_PATH=/absolute/path/to/licensed/qnn-2.29-v73-runtime \
  /system/bin/linker64 /absolute/path/to/ternux-qnn-known-add
```

An additional opt-in decoder preview accepts only the pinned VAE decoder
SHA-256. It executes the decoder twice for a quantized real-zero latent,
compares the raw tensors, returns the output through an anonymous FD, and
converts NCHW UFIXED_POINT_16 output to a PNG in Debian scratch. The output
file must be a new absolute path; the original ZIP stays in place. This
preview is a graph/output-transport check, not a known image oracle or a
Stable Diffusion text-to-image pipeline. [CI run 38412413332](https://github.com/soobujmiah/ternux/actions/runs/38412413332)
passed after a transient NDK-download unzip failure on its first attempt. The
checksum-verified artifact ran on SM8735: two decoder executions returned 0
and repeated exactly (raw FNV64 `d478b3703844afbe`). The anonymous output FD
carried 1,572,864 bytes. Debian rendered a 512x512 RGB PNG, 62,004 bytes,
SHA-256 `37e5cab392140b53b262bdbaf9c976adaee4e725789515115330eaa4424a54cf`.
A visual check found a mostly uniform muted image with edge variation, expected
for a zero-latent diagnostic but not independently checked against a reference.
The PNG and raw log remain in local scratch; no model member was extracted.

```bash
python3 experiments/qnn-native/archive_input.py \
  --archive /sdcard/Llms/AbsoluteReality_qnn2.28_8gen2.zip \
  --member vae_decoder.bin \
  --inspect-helper /absolute/path/to/ternux-qnn-context-inspect \
  --execute-decoder --output-png /absolute/scratch/path/decoder-zero.png \
  --runtime-dir /absolute/path/to/licensed/qnn-2.29-v73-runtime
```

An opt-in fixed-input UNet diagnostic uses only the pinned `unet.bin` member:
quantized real-zero sample and text embedding, integer timestep `999`, two
executions, and an exact repeat check. This is a bounded compute test; no
text prompt, scheduler, expected tensor or final image is involved.
[CI run 38413205585](https://github.com/soobujmiah/ternux/actions/runs/38413205585)
passed and its checksum-verified helper executed the UNet graph twice on the
physical SM8735. Both calls returned 0 with V73/CDSP logs and exact repeated
output FNV64 `43f9d6c70dc574c9`. Inputs were quantized real-zero sample
(raw code `34900`), quantized real-zero text embedding (raw code `30105`) and
INT32 timestep `999`. This verifies bounded UNet graph execution, not a
known-output UNet result or a prompt-driven generation.

```bash
python3 experiments/qnn-native/archive_input.py \
  --archive /sdcard/Llms/AbsoluteReality_qnn2.28_8gen2.zip \
  --member unet.bin \
  --inspect-helper /absolute/path/to/ternux-qnn-context-inspect \
  --execute-unet \
  --runtime-dir /absolute/path/to/licensed/qnn-2.29-v73-runtime
```

A later CI artifact from [run 38410204285](https://github.com/soobujmiah/ternux/actions/runs/38410204285)
also re-ran the encoder with a quantized **real-value zero** input. The input
uses scale `3.05180438e-05`, offset `-32768`; raw code `32768` represents real
zero, while the earlier raw code `0` represents approximately `-1`. Two
real-zero executions matched bit-for-bit (`mean` FNV64
`deb8b84b57841ffd`, `std` `c9f7be81df56cb75`). A third run with raw code
zero reproduced the earlier `ae97b25a95bdac33` and `7fb11db45bb92b10`
hashes. The outputs differed between these two inputs. This verifies input
sensitivity and repeatability, not an independent VAE expected tensor. The
metadata probe now reports per-tensor scales and offsets for encoder, decoder
and UNet; see the device log for exact values.

1. Obtain an independent expected tensor for the exact fixed VAE input, verify
   output encoding/quantization, and compare numerical values. Then qualify
   decoder and UNet outputs against suitable independent references. Their
   fixed-input execution is already verified.
2. Prove a fixed-input, known-output VAE graph result with explicit HTP
   attribution and repeat cleanup. The current repeated-output probe is an
   execution gate, not a numerical-correctness gate.
3. Implement our own SD1.5 pipeline: tokenizer/embedding input, scheduler, MNN
   CLIP execution on CPU and QNN UNet/VAE on HTP. A loaded QNN context alone
   cannot generate an image.
4. Expose our own bounded request/response IPC to PRoot. A child process with
   framed pipes is the first candidate; no installed Android app dependency.
5. Run fixed prompt/seed/size image tests with per-stage logs, image decoding,
   repeatability and visual review. Keep CPU, GPU and HTP attribution explicit.
6. Build portable pinned artifacts, inspect ABI/ELF/RUNPATH, validate licensing,
   then perform installed-artifact tests before any Ternux release.

## Source references

- [Qualcomm Android QNN runtime 2.29.0 AAR/POM](https://repo.maven.apache.org/maven2/com/qualcomm/qti/qnn-runtime/2.29.0/qnn-runtime-2.29.0.pom)
- [Qualcomm public QNN interface](https://docs.qualcomm.com/bundle/publicresource/topics/80-63442-10/api-rst_file_include_QNN_QnnInterface_h.html)
- [Qualcomm public API version types](https://docs.qualcomm.com/nav/home/api-rst_program_listing_file_include_QNN_QnnTypes_h.html?product=924033590759186372)
- [Local Dream source reference, fixed revision](https://github.com/xororz/local-dream/tree/647dc6f54b2859e4af59000746fde9c047627ff1)
- [Reference SD1.5 stage assignment](https://github.com/xororz/local-dream/blob/647dc6f54b2859e4af59000746fde9c047627ff1/app/src/main/cpp/src/PipelineSd15Npu.hpp)

The reference's current build requests QAIRT 2.50.0.260828; my vendor runtime
is 2.29.0. No equivalence or compatibility is assumed. No reference pipeline
code, proprietary libraries, firmware, headers, or weights are committed here.
