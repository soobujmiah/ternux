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
sd-cli --backend cpu \
  --model /sdcard/Llms/ternux-v2-validation/stable-diffusion-v1-5-pruned-emaonly-Q8_0.gguf \
  --prompt 'a small red robot in a garden, clean illustration' \
  --output /tmp/ternux-sd-cpu.png --width 512 --height 512 --steps 10 --seed 42
```

Vulkan-er jonno `--backend cpu`-r jaygay `--backend vulkan0` din. Kom memory-r device-e prothome 512×512, 10 step nin. Vulkan chalate Vulkan ICD (`vulkaninfo --summary`) thik thaka dorkar; device init fail korle CPU use korun. Installed pinned build-er exact flag dekhte `sd-cli --help` chalan.

Target device-e ashol image workload, CPU/Vulkan output check, quality, speed, memory, cancel o restart test record na howa porjonto build/ABI chara baki qualification complete noy. Install success-ke stable release approval dhorben na.

## Remove

```sh
rm -rf "$HOME/.local/opt/ternux-extensions/stable-diffusion"
```

Eta sudhu extension delete kore; `/sdcard/Llms`-er model thakbe.
