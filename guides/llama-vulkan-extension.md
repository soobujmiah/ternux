# llama.cpp CPU + Vulkan extension (ARM64)

This repository guide covers the automatic Ternux installer and a manual,
checksum-verified installation. The website's [quick guide](https://soobujmiah.github.io/ternux/docs/QUICK-START.html#optional-local-cpu--vulkan-language-model)
keeps only the shortest setup path; this page is the detailed reference.

## Scope and requirements

- This is the `ternux-llama-vulkan-linux-arm64-b11582` **prerelease**, built
  from llama.cpp commit `af50f2f248b475d9760f8e67503d01c0f194f5f4`.
- Run it inside Ternux's Debian ARM64 glibc guest. The installer command itself
  runs in the Termux host; the manual route runs in Debian.
- The package provides llama.cpp CPU and Vulkan backends. It does not install
  model weights, a Vulkan driver/ICD, or HTP/QNN support. Keep GGUF files in
  their current location. Vulkan needs a functioning system Vulkan ICD; on the
  tested Adreno setup, the device was `Vulkan0`.
- This is a device-validated prerelease, not a claim of clean-device driver
  qualification or long-session stability. See the [benchmark evidence](https://soobujmiah.github.io/ternux/docs/BENCHMARKS.html#2026-10-14-published-vulkan-extension-install-and-inference).

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
