---
name: Device report
about: Share your device configuration for compatibility tracking
title: '[Device] '
labels: device-report
assignees: ''
---

**Device**
- Manufacturer:
- Model:
- Android version:
- Kernel (`uname -r`):
- Architecture (`uname -m`):
- RAM:
- Storage free:

**GPU**
- GPU detected (`ternux info --json | jq '.gpu'`):
- Backend (`ternux backend show`):
- Vulkan support (`ternux info --json | jq '.vulkan'`):
- Renderer (`glxinfo | grep 'renderer string'`):

**Ternux version**: `ternux --version`

**Notes**
Anything notable about this device's experience.