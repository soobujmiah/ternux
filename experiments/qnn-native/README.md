# Standalone Android QNN discovery from Debian PRoot

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

The source uses only a small public API prefix and checks the observed core API
before invoking backend functions. It is scoped to the observed vendor runtime;
model/tensor execution requires matching, properly licensed QNN headers.

Compile as **Android/Bionic**, using an Android compiler. My small local
diagnostic used existing Termux Clang 21.1.8 targeting
`aarch64-unknown-linux-android24`. This is intentional for this Android helper;
the Debian llama.cpp build uses a separate glibc toolchain.

```bash
# Debian PRoot, with the existing Android-target compiler visible
/data/data/com.termux/files/usr/bin/clang -O2 -Wall -Wextra -Werror \
  experiments/qnn-native/probe.c -ldl -o /tmp/ternux-qnn-native-probe
env -u LD_PRELOAD \
  LD_LIBRARY_PATH=/vendor/lib64:/vendor/lib64/egl:/system/lib64 \
  /system/bin/linker64 /tmp/ternux-qnn-native-probe
```

The local diagnostic binary has a Termux-specific RUNPATH and is not a portable
release asset. Release compilation must use a pinned Android NDK on GitHub and
inspect the ELF, dependencies, runpaths, and actual device execution.

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
context deserialization. This verifies **compatible VAE context loading** for
this device/process/runtime combination. It does not verify graph execution,
output tensors, a correct image, or the other context members.

The initial successful-load process then crashed during `dlclose` of HTP,
after all QNN handle free calls returned 0. The short-lived helper now retains
that library until process exit after explicit handle cleanup; the repeated
probe exited 0. Keep this lifecycle limitation when designing a persistent
helper. Full raw logs are local scratch evidence under
`/home/sbj/npu-probe-2026-10-13/qnn-context-vae-encoder-official-runtime-final.txt`.

Reproduce with a licensed QNN 2.29.0 Android runtime directory containing the
V73 stub/skel. The archive remains at its original path:

```bash
/data/data/com.termux/files/usr/bin/clang -O2 -Wall -Wextra -Werror \
  experiments/qnn-native/context_inspect.c -ldl -o /tmp/ternux-qnn-context-inspect
python3 experiments/qnn-native/archive_input.py \
  --archive /sdcard/Llms/AbsoluteReality_qnn2.28_8gen2.zip \
  --member vae_encoder.bin --inspect-helper /tmp/ternux-qnn-context-inspect \
  --load-htp --runtime-dir /absolute/path/to/licensed/qnn-2.29-v73-runtime
```

## Remaining inference gates

1. Obtain matching, properly licensed QNN execution headers and decode the
   graph/tensor metadata. The small hand-written prefix is for bounded discovery
   only; do not guess full graph/tensor ABI layouts.
2. Run a fixed-input, known-output VAE graph test with explicit HTP attribution,
   numerical/output checks and repeat cleanup. Then qualify UNet separately.
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
