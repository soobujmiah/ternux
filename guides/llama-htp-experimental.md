# Experimental llama.cpp Hexagon HTP extension

This guide covers the optional `llama-htp-experimental` Ternux extension. It
packages a Linux ARM64 llama.cpp build with a Ternux Binder/FastRPC broker and
launcher. It is a device-specific experiment for Qualcomm SM8735 / Hexagon V73,
not a supported or production-ready Ternux feature.

## Current evidence and limits

The known-answer-safe configuration observed on SM8735 uses HVX-only matmul
(`GGML_HEXAGON_MM_SELECT=1`) with flash attention disabled. A short
CPU/HTP comparison and a 2,955-token prompt / 511-token generation returned the
expected recall key on this device; HTP was slower than Vulkan in the clean-idle
comparison. HMX-selected matmul and flash attention enabled under the prior
default attention selection each produced wrong answers in separate checks.
Explicit HVX attention selection reduced the operator failures but reproduced
seven numerical errors; neither path is qualified by this package.

The current launcher forces HTP0, all eligible layers, the observed
HVX/flash-attention-off settings. The broker forwards SIGINT/SIGTERM/SIGHUP to
the isolated inference process group, then escalates to TERM/KILL after bounded
waits and reports the CDSP `closeSession` result. Source-level device checks
returned `4` and verified a broker SIGINT exit 130 with child shutdown and
`closeSession [0, 0]`. The exact package archive from workflow run `38560288558` was installed into
an isolated home: known-answer output was `4`, all 31 layers were assigned to
HTP0, child exit was 0, and `closeSession` returned `[0, 0]`. Its bounded SIGINT
check exited 130 after child shutdown and clean `closeSession`. A follow-up build
`38562008524` corrects only package README/manifest dependency metadata; direct
archive comparison confirmed every runtime file and symlink is identical.
Restart behavior, other models/SoCs,
optimized HTP configurations and sustained operation remain unqualified. There is no automatic CPU/Vulkan fallback; a
failed HTP invocation returns an error.

Current gates and dated device evidence stay in the single
[accelerator release plan](../docs/ACCELERATOR-RELEASE-PLAN.md) and
[device benchmark record](device-benchmark-evidence.md).

## Latest operator checks

On 2026-10-14, the Linux ARM64 package from workflow run `38567329752`
(SHA-256 `7eb99a5532c2741fce2b84c757b9182bd69c891d907513c67f51e0c51e4c2211`)
was used for operator checks on the Redmi Turbo 4 Pro / SM8735.
The broker acquired the CDSP descriptor and reported a clean session close for
each run. The local Debian runtime used the already-extracted `libgbinder`,
`libglibutil`, and FastRPC files; an isolated scratch symlink supplied the
unversioned `libcdsprpc.so` name normally provided by `libfastrpc-dev`. No
package was installed and no Ternux runtime configuration was changed.

With the default HMX matmul selection, `test-backend-ops -b HTP0 -o MUL_MAT`
finished with 529 failing cases. Every reported numerical error was `inf` and
the backend reported **FAIL**; HTP hardware information was v73, HMX present,
and 8 MB VTCM. The HVX-only rerun with `GGML_HEXAGON_MM_SELECT=1` completed
**1,389/1,389 HTP `MUL_MAT` tests** successfully. The CPU backend was skipped,
and the broker reported a clean `closeSession [0, 0]`. This result covers this
operator suite only, not all HTP operators.

This confirms an HMX `MUL_MAT` correctness problem on SM8735; it does not prove
why it happens. Upstream has a similar v73 report for an SM7750 device whose
HMX does not support FP16, and a separate v75 report about a flash-attention
queue race. These are related diagnostic leads from different devices, not a
confirmed root cause for SM8735: [SM7750 HMX report](https://github.com/ggml-org/llama.cpp/issues/29473),
[SM8650 flash-attention report](https://github.com/ggml-org/llama.cpp/issues/26759).
The device's HMX FP16 capability and other HVX operator coverage still need
separate checks. A first `FLASH_ATTN_EXT` run selected HVX matmul with
`GGML_HEXAGON_MM_SELECT=1` but left flash-attention selection at default; it hit
a 120-second bound with 1,848 infinite numerical-error cases and 112 passes
among 4,660 output lines (exit 124), so that run was incomplete. A later run
explicitly selected HVX for both matmul and attention with
`GGML_HEXAGON_MM_SELECT=1 GGML_HEXAGON_FA_SELECT=1` and completed the suite:
2,593 of 5,332 unique cases passed, 2,732 were unsupported, and 7 failed with
finite numerical errors above tolerance. A filtered rerun reproduced all 7
failing parameter cases. The test exited 1 for these correctness failures; the
broker closed the CDSP session cleanly. This narrows the earlier error pattern
but does not qualify flash attention. The HTP launcher continues to force HVX
matmul with flash attention off. Raw logs are under
`/home/sbj/npu-probe-2026-10-13/htp-op-qualification-38567329752/`.

A broad HVX-selected `test-backend-ops -b HTP0` run used reduced queue settings
(`GGML_HEXAGON_OPBATCH=128`, `GGML_HEXAGON_OPQUEUE=2`). Before abort it logged
3,520 passing cases, 45 numerical-error failures in `DIV`, `GET_ROWS`,
`SWIGLU_CLAMP`, `ADD`, and `SUB`, and 4,874 unsupported cases. The child then
aborted on `dspqueue_read failed: 0x0000002e` (exit -6); the broker closed the
CDSP session cleanly. This was incomplete, not a broad-suite pass. An isolated
`MUL_MAT_W4A4` check passed 1/1; the all-operator abort cause remains unknown.

## Requirements

- Ternux's Debian ARM64 glibc guest, glibc 2.38 or newer.
- Qualcomm SM8735 with the vendor DSP service available to the current
  Termux/PRoot process. Other devices are not qualified.
- Debian packages `libgbinder1`, `libglibutil1`, `libfastrpc1` and
  `libfastrpc-dev`. The development package supplies the unversioned
  `libcdsprpc.so` linker name loaded by llama.cpp; `libfastrpc1` alone only
  installs the versioned runtime name.
- A GGUF model at a path the Debian guest can read. The extension does not
  download, copy or bundle model weights.

When HTP is selected in Ternux's interactive installer, it enables Debian
Trixie Backports `main` and `contrib` and installs these runtime packages before
installing the extension. For a later manual `ternux extension install` command,
install the runtime packages in the Debian guest first:

```bash
sudo apt install libgbinder1 libglibutil1 libfastrpc1 libfastrpc-dev
```

On Debian 13, `libgbinder1` and `libglibutil1` are available from
Trixie Backports, while `libfastrpc1` and `libfastrpc-dev` are in its `contrib` component. If apt
cannot find them, configure the official `trixie-backports` source with `main`
and `contrib`, update package indexes, then retry. See Debian's package records
for [`libgbinder1`](https://packages.debian.org/trixie-backports/arm64/libs/libgbinder1),
[`libglibutil1`](https://packages.debian.org/trixie-backports/arm64/libs/libglibutil1),
[`libfastrpc1`](https://packages.debian.org/trixie-backports/arm64/contrib/libfastrpc1),
and [`libfastrpc-dev`](https://packages.debian.org/trixie-backports/arm64/libdevel/libfastrpc-dev).

The launcher never changes `/dev/fastrpc-cdsp` permissions and does not bundle
Qualcomm vendor libraries or firmware.

## Install and run

From Termux, install the experimental package through the Ternux CLI:

```bash
ternux extension list
ternux extension install llama-htp-experimental
```

If the installer reports missing Binder/FastRPC libraries, install the Debian
packages above in the guest, then repeat the command. The installer checks the
release checksum, archive paths, package manifest, launcher and broker files,
and installs atomically without replacing an existing extension directory.

In Debian, run the launcher with your existing model path:

```bash
"$HOME/.local/opt/ternux-extensions/llama-htp-experimental/bin/htp-run" \
  -m /path/to/model.gguf \
  -p 'What is 2 + 2? Reply with only the number.' -n 8
```

The launcher selects the observed HVX-only / flash-attention-off configuration
and requests all eligible model layers for HTP. Check the output and exit code;
do not infer correct inference from a successful model load or HTP operator
profile alone. Keep the model at its current path. For a separate CPU or Vulkan
run, install `llama-vulkan` and follow the
[CPU/Vulkan extension guide](llama-vulkan-extension.md).

## Removal

Inspect the exact installation first. If you choose to remove only this
extension, stop its inference process and remove this directory from the Debian
guest:

```text
$HOME/.local/opt/ternux-extensions/llama-htp-experimental
```

The extension does not remove model files, system packages, or another
extension.
