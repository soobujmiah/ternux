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
sd-cli --backend cpu \
  --model /sdcard/Llms/ternux-v2-validation/stable-diffusion-v1-5-pruned-emaonly-Q8_0.gguf \
  --prompt 'a small red robot in a garden, clean illustration' \
  --output /tmp/ternux-sd-cpu.png --width 512 --height 512 --steps 10 --seed 42
```

For Vulkan, change `--backend cpu` to `--backend vulkan0`. Start with 512×512 and 10 steps on memory-constrained devices. The Vulkan route needs a functioning Vulkan ICD (`vulkaninfo --summary`); if device initialization fails, use CPU. Confirm exact CLI flags with `sd-cli --help` for the installed pinned build.

This preview has build/ABI qualification only until a real target-device image workload, CPU/Vulkan output checks, quality, performance, memory use, cancellation, and restart behavior are recorded. Do not interpret a successful install as a stable release qualification.

## Remove

```sh
rm -rf "$HOME/.local/opt/ternux-extensions/stable-diffusion"
```

This removes only the extension; model weights remain in `/sdcard/Llms`.
