# Stable Diffusion CPU + Vulkan extension (preview)

Ei optional extension Debian ARM64 guest-e `stable-diffusion.cpp`-er `sd-cli` install kore; CPU ebong Vulkan backend thake. Model, Vulkan driver ba Android vendor runtime download kore na. Guest-e kajer Vulkan ICD thakle GPU route cholbe; Vulkan na thakleo CPU use kora jabe.

## Install

Termux host theke:

```sh
ternux extension install stable-diffusion
```

Pinned ARM64 prerelease download kore SHA-256, archive path o package identity verify kore atomic install hoy. Debian glibc 2.39 ba notun ebong `libgomp1`, `libvulkan1` runtime package dorkar. Extension-er sathe upstream/dependency license notice-er checksum thake.

## Model-er path o use

Model extension-er baire rakhun. User-authorized SD 1.5 Q8 GGUF model `/sdcard/Llms/ternux-v2-validation/`-e ache. SHA-256: `d0555243938c62faeefb4ac93f6c7a053ad373a4290c5256bce229aeb193bf94`. Model card-e CreativeML OpenRAIL-M deya ache; oi license ebong base model-er terms mene cholun.

```sh
source "$HOME/.local/opt/ternux-extensions/stable-diffusion/env.sh"
MODEL=/sdcard/Llms/ternux-v2-validation/stable-diffusion-v1-5-pruned-emaonly-Q8_0.gguf

# CPU-only, low-resolution diagnostic (slow on this phone)
sd-cli --backend cpu --model "$MODEL" \
  --prompt 'a small red robot in a garden, clean illustration' \
  --threads 4 --output /tmp/ternux-sd-cpu.png --width 256 --height 256 --steps 20 --seed 42

# Adreno GPU: tiled VAE is required for reliable 512x512 on SM8735
sd-cli --backend vulkan0 --model "$MODEL" \
  --prompt 'a small red robot in a garden, clean illustration' \
  --threads 4 --output /tmp/ternux-sd-vulkan.png --width 512 --height 512 --steps 10 --seed 42 \
  --vae-tiling --vae-tile-size 256x256
```

Test-e model card-e CreativeML OpenRAIL-M deya ache; oi license ebong base model-er terms mene cholun. Pinned CLI option `sd-cli --help` diye dekhun.

Adreno 825-e 512x512 pure Vulkan tiling chara VAE decode-e device-lost hoyechilo. `--vae-tiling --vae-tile-size 256x256` diye same resolution-er 10-step full-Vulkan image save hoyeche (101.9s). CPU backend 256x256/10-step image save koreche (194.4s), kintu output blocky chilo; CPU quality ekhono qualify hoyni. Mixed fallback `--backend diffusion=vulkan0,te=cpu,vae=cpu` output save koreche, kintu 512x512/10-step-e 221s legeche ebong RSS praye 3.4 GiB hoyechilo. `vulkaninfo --summary` diye Vulkan ICD check korun.

Puro command, measurement, model checksum ebong gate decision [device qualification handoff](../../handoffs/stable-diffusion-cpu-vulkan-qualification-2026-11-07.md)-e ache.

Public prerelease checksum verify kore `ternux extension install stable-diffusion` diye install hoyeche; `ternux doctor` extension detect kore. Installed binary `/sdcard/Llms` theke model niye tiled Vulkan VAE-te 512×512/10-step coherent image 92.91s-e generate koreche. CPU image quality unqualified. Broader quality, memory range, cancellation, restart o sustained-use gate khola; eta stable Ternux release noy.

## Remove

```sh
rm -rf "$HOME/.local/opt/ternux-extensions/stable-diffusion"
```

Eta sudhu extension delete kore; `/sdcard/Llms`-er model thakbe.
