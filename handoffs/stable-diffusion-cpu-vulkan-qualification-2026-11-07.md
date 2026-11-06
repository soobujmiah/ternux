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
- **CPU image path:** visual failure at 256×256 through 20 steps. Investigate
  backend/model compatibility or mark CPU execution diagnostic-only; repeat
  visual review after a runtime/model change.
- **Extension packaging:** build/ABI/license-notice checks passed in workflow
  run `42295461009`, but that only validates an extracted candidate. It has not
  been published or installed by Ternux's actual extension manager. Do not mark
  extension installation complete until checksum-verified managed install,
  doctor detection, removal/repair behavior, and an installed-package workload
  are tested.
- **Broader reliability:** cancellation, restart, longer sustained runs,
  different Adreno devices, model quality range, and memory/thermal range remain
  unqualified.
- **Release:** Ternux v2 remains held by this and other release-plan gates.

The temporary workflow archive was checksum-verified before extraction; its
SHA-256 was
`a193996aef0efd6d1843957fb9a77ac36edbf47edb30bd366d13c0c1a538cb29`.
The model and generated outputs remain outside the Git repository.
