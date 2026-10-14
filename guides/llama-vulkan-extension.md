# llama.cpp CPU + Vulkan extension (ARM64)

This repository guide covers the automatic Ternux installer and a manual,
checksum-verified installation. The website's [quick guide](https://soobujmiah.github.io/ternux/docs/QUICK-START.html#optional-local-cpu--vulkan-language-model)
keeps only the shortest setup path; this page is the detailed reference.

## Scope and requirements

- This is the `ternux-llama-vulkan-linux-arm64-b11582` **prerelease**, built
  from llama.cpp commit `af50f2f248b475d9760f8e67503d01c0f194f5f4`.
- Run it inside Ternux's Debian ARM64 glibc guest. The installer command itself
  runs in the Termux host; the manual route runs in Debian.
- The published binaries require **glibc 2.38 or newer**. Ternux's tested
  Debian PRoot currently has glibc 2.41. The guest also needs OpenSSL 3
  (`libssl3` or `libssl3t64`), `libgomp1`, and `libvulkan1`; if they are
  missing, install the matching runtime packages in Debian. The extension installer
  refuses an older glibc before downloading or writing files.
- The package provides llama.cpp CPU and Vulkan backends. It does not install
  model weights, a Vulkan driver/ICD, or HTP/QNN support. Keep GGUF files in
  their current location. Vulkan needs a functioning system Vulkan ICD; on the
  tested Adreno setup, the device was `Vulkan0`.
- This is a device-validated prerelease, not a claim of clean-device driver
  qualification or long-session stability. See the [device qualification record](#device-qualification-record).

## Route A: automatic install (recommended)

In **Termux**, list the available extension and install it:

```bash
ternux extension list
ternux extension install llama-vulkan
```

The host CLI delegates to the selected Debian guest. The guest-side installer
checks Linux ARM64/glibc, downloads the pinned release and its SHA-256 sidecar,
checks the archive digest, validates member paths and links, checks the package
manifest and required files, then atomically installs to:

```text
$HOME/.local/opt/ternux-extensions/llama-vulkan
```

An existing destination is not overwritten. There is no in-place updater. To
replace an installation, first inspect it and deliberately remove the exact
extension directory, then repeat the install command. Do not remove the parent
`ternux-extensions` directory if it contains other extensions.

In Debian, source the environment and check available devices:

```bash
source "$HOME/.local/opt/ternux-extensions/llama-vulkan/env.sh"
llama-cli --version
llama-cli --list-devices
```

Run a CPU baseline (no GPU layers):

```bash
llama-cli -m /path/to/model.gguf -ngl 0 \
  -p 'What is 2 + 2? Answer with the number only.' -n 8
```

Run on Vulkan (change the model path to your existing GGUF):

```bash
llama-cli -m /path/to/model.gguf -dev Vulkan0 -ngl 99 \
  -p 'What is 2 + 2? Answer with the number only.' -n 8
```

`Vulkan0` must appear in `--list-devices`; use the reported device name if it
differs. `-ngl 99` requests offload of all eligible model layers; confirm the
verbose run log to see how many were actually assigned. If no Vulkan device is
listed, keep using `-ngl 0` and diagnose the system ICD/driver before retrying.

## Route B: manual install

Use this when you want to inspect and verify the release yourself or cannot use
the host extension command. Run all commands in the **Debian guest**, as your
normal user. This installs a versioned directory so it does not collide with
the automatic install path.

Check the ABI baseline and required system libraries first:

```bash
getconf GNU_LIBC_VERSION   # must report glibc 2.38 or newer
if apt-cache show libssl3t64 >/dev/null 2>&1; then
  SSL_PACKAGE=libssl3t64
else
  SSL_PACKAGE=libssl3
fi
sudo apt install libgomp1 libvulkan1 "$SSL_PACKAGE"
```

Download the archive and published checksum sidecar over HTTPS, then verify the
archive digest:

```bash
TAG=ternux-llama-vulkan-linux-arm64-b11582
ASSET="$TAG.tar.gz"
RELEASE="https://github.com/soobujmiah/ternux/releases/download/$TAG"
CACHE="$HOME/.cache/ternux-artifacts/$TAG"
mkdir -p "$CACHE"
cd "$CACHE"
curl -fL --retry 3 -o "$ASSET" "$RELEASE/$ASSET"
curl -fL --retry 3 -o "$ASSET.sha256" "$RELEASE/$ASSET.sha256"
sha256sum -c "$ASSET.sha256"
```

Expected archive SHA-256 for this published build:

```text
3753fa3044ec258732cc52729eafc42c0cbf5b476f27fd247be3619617611d9e  ternux-llama-vulkan-linux-arm64-b11582.tar.gz
```

Before extraction, inspect archive names and confirm all entries are below the
expected top-level directory. The automatic route also validates links and
package layout; prefer it if you do not need a manual install.

```bash
tar -tzf "$ASSET" | less
```

Only continue if every path is under
`ternux-llama-vulkan-linux-arm64-b11582/`, with no absolute path or `..` path
component. Extract into a new, version-specific directory; stop if it already
exists:

```bash
DEST="$HOME/.local/opt/ternux-extensions/llama-vulkan-b11582"
mkdir -p "$(dirname "$DEST")"
test ! -e "$DEST" && test ! -L "$DEST" || {
  printf 'Destination already exists: %s\n' "$DEST" >&2
  exit 1
}
STAGE="$(mktemp -d "$(dirname "$DEST")/.llama-vulkan-b11582.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
tar --no-same-owner -xzf "$ASSET" -C "$STAGE"
test -x "$STAGE/$TAG/bin/llama-cli"
test -f "$STAGE/$TAG/env.sh"
grep -Fq '"artifact": "ternux-llama-vulkan-linux-arm64-b11582"' \
  "$STAGE/$TAG/build-manifest.json"
mv "$STAGE/$TAG" "$DEST"
```

Load that version's environment and test CPU first:

```bash
source "$DEST/env.sh"
llama-cli --version
llama-cli --list-devices
llama-cli -m /path/to/model.gguf -ngl 0 \
  -p 'What is 2 + 2? Answer with the number only.' -n 8
```

Then try Vulkan only if the expected device is listed:

```bash
llama-cli -m /path/to/model.gguf -dev Vulkan0 -ngl 99 \
  -p 'What is 2 + 2? Answer with the number only.' -n 8
```

Manual installation verifies the published archive hash and the package's basic
layout, but does not provide all host delegation, archive safety, atomicity, and
reinstall protections of Route A. Keep the verified archive and checksum
sidecar if you need an audit trail.

## Troubleshooting and removal

- **`ternux: command not found` in Termux:** install/update Ternux first and run
  the command in the host Termux shell, not inside Debian.
- **Installer says Linux ARM64 glibc is required:** the guest-side operation was
  invoked outside the Debian ARM64 guest; use Route A from Termux or enter the
  correct guest for Route B.
- **No `Vulkan0`:** the package may still run on CPU. Check `vulkaninfo
  --summary` and the guest's Vulkan ICD/driver setup. The extension does not
  install Turnip or another driver.
- **Existing destination:** inspect the named path before removing it. The
  automatic and manual paths are separate. Never delete a directory whose
  contents you have not checked.
- **Model path error:** the extension does not move model files. Pass the
  existing GGUF path with `-m`.

To remove only the automatic install, inspect then remove its exact path from
your Debian home:

```bash
ls -la "$HOME/.local/opt/ternux-extensions/llama-vulkan"
rm -rf -- "$HOME/.local/opt/ternux-extensions/llama-vulkan"
```

For the manual route, substitute the versioned path
`llama-vulkan-b11582`. Model weights and the cached release archive are separate
and are not removed by these commands.

## Device qualification record

On 2026-10-14, I installed the published archive through
`ternux extension install llama-vulkan` into a new isolated Debian guest home;
my workstation install and the existing Qwen2.5 1.5B Q4_0 model were left in
place. The archive checksum is recorded above. The package manifest identifies
the pinned llama.cpp commit and device validation; the package contains its
upstream MIT license, uses `$ORIGIN/../lib`, and had no unresolved dynamic
dependencies in Debian PRoot.

I audited all 69 ELF files in the extracted archive offline: all were AArch64,
used `$ORIGIN/../lib`, and required no GLIBC symbol newer than 2.38. The audit
confirmed the package-local dependencies and the upstream license. The system
runtime needs OpenSSL 3 (`libssl3` or `libssl3t64`), `libgomp1`, and
`libvulkan1`; the installer checks their shared libraries and the glibc minimum
before downloading. The current release workflow includes this ABI audit, but
its latest successful artifact run predates the audit step. [Run #3](https://github.com/soobujmiah/ternux/actions/runs/38457240250)
succeeded on 2026-10-13 at commit `b568b9f`; it is not evidence that the new
audit step has passed. A fresh artifact build remains open.

Using the existing model in place, the installed package returned `4` for the
same greedy `2 + 2` prompt on CPU (`-ngl 0`) and Vulkan
(`-dev Vulkan0 -ngl 99`). Verbose Vulkan output identified Adreno 825 and
assigned all 29/29 layers. A reinstall attempt preserved the existing binary
hash and returned the expected already-installed error. Local logs are retained
under `/home/sbj/npu-probe-2026-10-13/ternux-vulkan-device-test/`.

In a separate bounded cancellation series, I sent SIGINT during live CPU and
Vulkan generation three times per backend. Each process stopped with exit 0;
fresh known-answer runs on both backends returned `4`. Intermediate attempts
interrupted immediately after seeing `4` had signal exits and are excluded from
the clean-stop result. At the end, battery temperature was 41.1 C, sampled skin
temperature 44.1 C, hottest sampled CPU 76.8 C, and Android thermal status 0.
This does not establish long-duration stability, NPU cancellation, system
fallback, or clean-device graphics setup. Detailed logs and the run method are
in the same local scratch directory.
