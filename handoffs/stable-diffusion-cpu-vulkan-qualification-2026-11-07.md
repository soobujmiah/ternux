# Stable Diffusion CPU/Vulkan device qualification — 2026-11-07

## Scope and artifact provenance

This handoff records a real-device workload for the draft `stable-diffusion`
CPU/Vulkan extension. It does not qualify a stable Ternux release or generalize
beyond this device and model.

- Device: Xiaomi Redmi Turbo 4 Pro, Qualcomm SM8735, Adreno 825.
- Guest: Debian 13 PRoot, glibc 2.41; Mesa Turnip 27.0.0.
- Runtime candidate: ARM64 `stable-diffusion.cpp` build from pinned upstream
  commit `5a1ba5d895bec4e07deab80d6d791721cd59d9c2`; draft PR #59.
- Model source: `second-state/stable-diffusion-v1-5-GGUF`, pinned revision
  `031b5f5df991f511b3f5fa8fed6d99048ababb69`.
- Model: `/sdcard/Llms/ternux-v2-validation/stable-diffusion-v1-5-pruned-emaonly-Q8_0.gguf`
- Model size: 1,763,578,176 bytes (about 1.64 GiB).
- Model SHA-256: `d0555243938c62faeefb4ac93f6c7a053ad373a4290c5256bce229aeb193bf94`.
- Model card identifies CreativeML OpenRAIL-M; preserve its terms and base
  model terms. Model weights are user-provided and are not part of the package.
- Download was staged, verified, copied to `/sdcard/Llms`, then the temporary
  download was deleted. Existing QNN model assets were not modified.
- Generated images are retained at
  `/sdcard/Llms/ternux-v2-validation/results-54d6e22/`.

## Commands and observed results

All commands used the exact model path above and seed 42. Times are end-to-end
wall times reported by the runner unless a host `time` measurement is stated.

| Route | Settings | Result |
|---|---|---|
| CPU | 256×256, 1 step | Image saved; 47.0s. Smoke test only; one step is not a quality sample. |
| Vulkan | 256×256, 1 step | Image saved; 11.2s. Adreno 825 identified by `ggml_vulkan`; smoke test only. |
| Vulkan | 512×512, 10 steps, no VAE tiling | Sampling completed, then Vulkan device was lost during VAE decode after about 60.8s. No complete output. `vulkaninfo --summary` still enumerated the Adreno afterward. |
| Mixed Vulkan UNet + CPU text encoder/VAE | 512×512, 10 steps | Complete coherent image saved; 220.95s. Vulkan UNet sampling 69.10s, CPU VAE 150.96s, observed RSS about 3.47 GiB near completion. |
| Vulkan | 512×512, 10 steps, `--vae-tiling --vae-tile-size 256x256` | Complete coherent image saved; 101.94s runner time / 1m43.278s host time. Vulkan sampler 69.15s, tiled VAE decode 32.27s. All components used Vulkan0. This is the successful GPU recipe on this device. |
| CPU | 256×256, 4 steps | Image saved; 103.82s. Visually blocky/artifacted. |
| CPU | 256×256, 10 steps, default flash attention | Image saved; 194.41s. Visually blocky and poor semantic match. |
| CPU | 256×256, 10 steps, flash attention off | Image saved; 231.42s. Still blocky; disabling flash attention did not fix quality or speed. |
| CPU | 256×256, 20 steps, default flash attention | Image saved; 391.67s / 6m32.576s host time. Visually inspected: severe blocky artifacts; not acceptable image quality. |

The CPU 20-step image is `cpu-256-20.png`. It was directly reviewed after
completion. More steps did not make the CPU output visually acceptable; CPU
image generation is therefore **not quality-qualified**. Do not advertise the
CPU route as a usable image-generation capability based on this evidence.

## Reproduction

From Debian, after installing the extension:

```sh
source "$HOME/.local/opt/ternux-extensions/stable-diffusion/env.sh"
MODEL=/sdcard/Llms/ternux-v2-validation/stable-diffusion-v1-5-pruned-emaonly-Q8_0.gguf
sd-cli --backend vulkan0 --model "$MODEL" \
  --prompt "a small red robot in a garden, clean illustration" \
  --threads 4 --output /tmp/ternux-sd-vulkan.png \
  --width 512 --height 512 --steps 10 --seed 42 \
  --vae-tiling --vae-tile-size 256x256
```

CPU diagnostic command:

```sh
sd-cli --backend cpu --model "$MODEL" \
  --prompt "a small red robot in a garden, clean illustration" \
  --threads 4 --output /tmp/ternux-sd-cpu.png \
  --width 256 --height 256 --steps 20 --seed 42
```

## Qualification decision and remaining gates

- **Vulkan image path:** bounded target-device pass with VAE tiling at 512×512,
  10 steps. Untiled 512×512 is unreliable on this device and must not be the
  documented default.
- **CPU image path:** user excluded CPU picture output from the current image
  qualification. The observed 256×256/20-step run was severely artifacted;
  leave CPU image quality unqualified and do not claim it. It does not block
  the now-verified Adreno Vulkan path.
- **Extension packaging:** build/ABI/license-notice checks passed in workflow
  run `42303285336`; its public optional prerelease was checksum-verified and
  installed by Ternux's actual extension manager. Doctor detection and an
  installed-package target workload pass. Fresh-install selection and
  post-install removal/repair are still untested.
- **Broader reliability:** cancellation, restart, longer sustained runs,
  different Adreno devices, model quality range, and memory/thermal range remain
  unqualified.
- **Release:** Ternux v2 remains held by this and other release-plan gates.

## Public prerelease and managed-install workload

After the CPU image was excluded from this release decision, PR #59 was merged
and the optional extension prerelease was published from main by workflow run
`42303285336`.

- Public release: `ternux-stable-diffusion-vulkan-linux-arm64-master-1053`.
- Archive size: 27,367,156 bytes; SHA-256:
  `64a2761e680f0791eba476a24f476533c9ae35989d4ab6bbe2ecda26d0d9f336`.
- The Termux-side Ternux CLI ran `ternux extension install stable-diffusion`.
  It downloaded the public archive and `.sha256`, verified checksum and package
  layout/license manifest, then atomically installed it at
  `/home/ternux/.local/opt/ternux-extensions/stable-diffusion`.
- `ternux doctor --json` reported `ext_stable-diffusion` OK and identified the
  installed pinned artifact. Doctor also reported one unrelated existing
  `llama-htp-experimental_libs` warning (9 HTP shared libraries unavailable);
  no doctor failures. After the workload, the new CLI `repair` command
  checksum-verified and replaced the recognized install; `sd-cli --help`
  worked afterward, and the SD1.5 model stayed in `/sdcard/Llms`. The new
  `remove` command deleted only the managed extension directory; the model
  remained. Reinstall from the public release passed again and doctor still
  reported the extension OK (30 OK, 0 failed, 1 existing HTP warning).
- The installed package generated
  `/sdcard/Llms/ternux-v2-validation/results-54d6e22/managed-extension-vulkan-512-10.png`
  from the direct `/sdcard/Llms/...Q8_0.gguf` path. Settings were Vulkan0,
  512×512, 10 steps, seed 42, VAE tile size 256×256. It saved a coherent robot
  garden image; runner generation time was 92.91s, shell wall time 1m35.962s.
  The output SHA-256 is
  `b59b0b3e43226b4ae484b433aadf4d681eb87de7ee300b78a9adc1029a2ec65a`.
  Auto-fit kept diffusion compute on Adreno Vulkan and staged text/VAE weights
  in host RAM; model bytes remained on shared `/sdcard` storage.
- CPU output remains unqualified and is not claimed. Optional fresh-install
  selection, cancellation/restart, sustained-use and broader device/model
  coverage remain open. Managed repair, removal and reinstall are verified on
  the active Debian guest; the extension remains installed after the test.

The earlier extracted workflow candidate archive had SHA-256
`a193996aef0efd6d1843957fb9a77ac36edbf47edb30bd366d13c0c1a538cb29`.
The model and generated outputs remain outside the Git repository.

## Clean guest optional dependency provisioning (2026-11-07)

I installed a separate Debian 13 Trixie PRoot guest named `ternux-clean-apt`; the active Debian guest and its extension tree were left unchanged. The rootfs started without `sudo`, `libgomp1`, or `libvulkan1`. I then provisioned the base Ternux preconditions (`sudo` plus the `ternux` user/passwordless sudo), and invoked the repository's actual `tnx_phase_extras ternux stable-diffusion` phase with its guest-login target bound to the isolated alias. APT installed the previously absent `libgomp1` and `libvulkan1` and their Debian runtime dependencies. The real extension manager downloaded the public pinned archive and checksum, verified and installed it under the clean guest's `/home/ternux/.local/opt/ternux-extensions/stable-diffusion`.

Post-install checks on that guest:

- `TERNUX_DISTRO=ternux-clean-apt TERNUX_USER=ternux bash bin/ternux doctor extensions --json` returned overall status `ok`; the extension check identified `ternux-stable-diffusion-vulkan-linux-arm64-master-1053` as installed, with no extension warnings or failures.
- The guest reported Debian GNU/Linux 13 (Trixie), glibc 2.41; `sd-cli --help` started successfully.
- `ldd -r` resolved `libgomp.so.1`, `libvulkan.so.1`, and all other dynamic dependencies without missing libraries or undefined symbols.
- Installed Debian runtime versions were `libgomp1 14.2.0-19` and `libvulkan1 1.4.309.0-1`.

This closes clean-guest dependency provisioning, managed artifact installation, Turnip setup, and a real GPU workload for the optional extension. The exact Ternux GPU phase installed the pinned Mesa 27.0.0 Turnip archive and license notices in this isolated guest. `vulkaninfo --summary` enumerated Adreno 825 as Vulkan GPU0 (`turnip Mesa driver`, Mesa 27.0.0-devel); llvmpipe appeared separately as GPU1. The existing Q8_0 model at `/sdcard/Llms/ternux-v2-validation/stable-diffusion-v1-5-pruned-emaonly-Q8_0.gguf` then generated a 512×512, 10-step tiled-Vulkan image in 91.18 s, with CLIP, diffusion model and VAE all assigned to Vulkan0. The PNG was valid and its SHA-256 `b59b0b3e43226b4ae484b433aadf4d681eb87de7ee300b78a9adc1029a2ec65a` exactly matches the previously reviewed same-seed output, confirming deterministic output across the two guest setups. The test output is retained temporarily at `/data/data/com.termux/files/usr/tmp/ternux-clean-guest-512-10.png`; the source model was read in place and not modified. This does not qualify a fresh X11 desktop or fresh-install menu selection. Cancellation/restart, sustained use, and broader device/model coverage remain open. The isolated guest was removed on 2026-11-11 after the validation run; `proot-distro list` then reported no installed containers. This alias was created explicitly for clean-APT qualification and was never part of the normal installer. A fresh Ternux install creates only its selected guest (default `debian`), reusing that guest if already installed. The active desktop was not changed by the clean-guest test.

Reproduction outline from the Ternux Termux host:

```bash
proot-distro install --name ternux-clean-apt debian:trixie
# In that isolated guest, install the Ternux base precondition sudo, create
# user ternux, and configure passwordless sudo. Then, from the repository:
ROOT="$PWD"
. "$ROOT/lib/phases.sh"
_TNX_DISTRO=ternux-clean-apt
export _TNX_DISTRO
# Bind the installer phase to this isolated alias; the extension dispatch also
# reads _TNX_DISTRO after loading the project core functions.
tnx_guest_login() { proot-distro login ternux-clean-apt "$@"; }
_TNX_SRC="$ROOT"
export _TNX_SRC
tnx_phase_extras ternux stable-diffusion
TERNUX_DISTRO=ternux-clean-apt TERNUX_USER=ternux bash bin/ternux doctor extensions --json
# Install vulkan-tools as a test utility, then check Adreno discovery and run:
proot-distro login ternux-clean-apt --user ternux -- bash -lc 'sudo apt-get install -y vulkan-tools && vulkaninfo --summary'
proot-distro login ternux-clean-apt --user ternux --shared-tmp -- bash -lc '''
  ext="$HOME/.local/opt/ternux-extensions/stable-diffusion"
  . "$ext/env.sh"
  sd-cli --backend vulkan0 --model /sdcard/Llms/ternux-v2-validation/stable-diffusion-v1-5-pruned-emaonly-Q8_0.gguf \
    --prompt "a small red robot in a garden, clean illustration" --threads 4 \
    --output /tmp/ternux-clean-guest-512-10.png --width 512 --height 512 \
    --steps 10 --seed 42 --vae-tiling --vae-tile-size 256x256
'''
```
