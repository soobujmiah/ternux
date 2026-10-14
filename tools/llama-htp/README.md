# Experimental llama.cpp Hexagon HTP adapter

This directory contains the Ternux adapter used by the optional
`llama-htp-experimental` extension. It connects the Debian PRoot process to the
Android Qualcomm DSP Binder service, receives a CDSP FastRPC descriptor, and
passes that descriptor only to the launched llama.cpp process. The adapter
never changes `/dev/fastrpc-cdsp` permissions.

The route is device-specific and experimental. It pins the known-output-safe
llama.cpp settings observed on SM8735: HVX matmul selected with
`GGML_HEXAGON_MM_SELECT=1`, all model layers offered to HTP, and flash attention
off. HMX and flash-attention combinations have returned wrong output. Other
models, SoCs, cancellation, fallback, and sustained operation need independent
qualification. Do not describe this extension as supported NPU inference.

The broker handles terminal SIGINT/SIGTERM/SIGHUP by forwarding the signal to
the isolated inference process group, escalating to TERM/KILL after bounded
waits, closing the CDSP session, and returning a signal-style exit status. The
device test must verify `closeSession` after cancellation before this behavior
can be called qualified.

Runtime dependencies are Debian's `libgbinder1`, `libglibutil1`, and
`libfastrpc1` packages, plus Python 3. The archive includes only Ternux's
launcher, Binder client, and small FastRPC open interposer; it does not bundle
Qualcomm libraries, firmware, models, or Android permissions.

Usage after installing the experimental extension:

```bash
ternux extension install llama-htp-experimental
~/.local/opt/ternux-extensions/llama-htp-experimental/bin/htp-run \
  -m "$HOME/models/model.gguf" \
  -p 'What is 2 + 2? Reply with only the number.' -n 8
```

This does not configure automatic CPU/GPU fallback. If broker setup or HTP
inference fails, the command reports failure; run a separate CPU or Vulkan
command to use those backends.
