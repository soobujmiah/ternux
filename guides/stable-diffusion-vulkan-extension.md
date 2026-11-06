# Stable Diffusion CPU + Vulkan extension (preview)

This optional extension installs `stable-diffusion.cpp`'s `sd-cli` with CPU and Vulkan backends into the Debian ARM64 guest. It does not download models, Vulkan drivers, or Android vendor runtimes. Vulkan GPU use requires a working guest Vulkan ICD; CPU remains available without Vulkan.

## Install

From the Termux host:

```sh
ternux extension install stable-diffusion
```

This downloads the pinned ARM64 prerelease, verifies its SHA-256, validates archive paths and package identity, and atomically installs it. Debian glibc 2.39 or newer and the `libgomp1` and `libvulkan1` runtime packages are required. The extension includes a checksummed upstream/dependency license-notice bundle.

## Model location and use

Keep model weights outside the extension. The included SD 1.5 Q8 GGUF qualification model is available under `/sdcard/Llms/ternux-v2-validation/` after the user-authorized local transfer. Its SHA-256 is `d0555243938c62faeefb4ac93f6c7a053ad373a4290c5256bce229aeb193bf94`. The model card identifies the weights as CreativeML OpenRAIL-M; comply with that license and the base model terms.

```sh
source "$HOME/.local/opt/ternux-extensions/stable-diffusion/env.sh"
MODEL=/sdcard/Llms/ternux-v2-validation/stable-diffusion-v1-5-pruned-emaonly-Q8_0.gguf

# CPU-only, low-resolution diagnostic (slow on this phone)
sd-cli --backend cpu --model "$MODEL" \
  --prompt 'a small red robot in a garden, clean illustration' \
  --threads 4 --output /tmp/ternux-sd-cpu.png --width 256 --height 256 --steps 20 --seed 42

# Adreno GPU: tiled VAE is needed for reliable 512x512 on SM8735
sd-cli --backend vulkan0 --model "$MODEL" \
  --prompt 'a small red robot in a garden, clean illustration' \
  --threads 4 --output /tmp/ternux-sd-vulkan.png --width 512 --height 512 --steps 10 --seed 42 \
  --vae-tiling --vae-tile-size 256x256
```

The [model card](https://huggingface.co/second-state/stable-diffusion-v1-5-GGUF/blob/main/README.md) lists CreativeML OpenRAIL-M; follow that license and the base model terms. Check pinned CLI options with `sd-cli --help`.

On the Adreno 825, untiled 512×512 Vulkan lost the device during VAE decode. `--vae-tiling --vae-tile-size 256x256` completed a same-size 10-step full-Vulkan image in 101.9s. CPU backend produced a 256×256/10-step image in 194.4s, but it was blocky; CPU image quality is not qualified. A mixed fallback, `--backend diffusion=vulkan0,te=cpu,vae=cpu`, saved a 512×512/10-step image in 221s with RSS around 3.4 GiB. Check the Vulkan ICD with `vulkaninfo --summary`.

For the full commands, measurements, model checksum and gate decisions, see the [device qualification handoff](../handoffs/stable-diffusion-cpu-vulkan-qualification-2026-11-07.md).

Build/ABI and tiled Vulkan image path passed; CPU quality, broader image quality, speed/memory range, cancellation, restart and sustained-use gates remain open. This is not qualified for stable release.

## Remove

```sh
rm -rf "$HOME/.local/opt/ternux-extensions/stable-diffusion"
```

This removes only the extension; model weights remain in `/sdcard/Llms`.
