# ternux JSON output schemas

All JSON output from `ternux <command> --json` follows this structure:

## Common fields

| Field | Type | Always present |
|-------|------|----------------|
| `command` | string | yes |
| `status` | string | yes — `ok`, `warning`, `error`, `complete`, `partial`, etc. |
| `timestamp` | string (ISO 8601) | yes |
| `version` | string | yes |

## Command-specific schemas

### `ternux doctor --json`

```json
{
  "command": "doctor",
  "status": "warning",
  "timestamp": "2026-08-15T14:30:00Z",
  "version": "1.3.0",
  "android_version": "14",
  "architecture": "aarch64",
  "gpu": "Adreno (730)",
  "backend": "zink-turnip",
  "renderer": "zink Vulkan (Adreno (TM) ... (MESA_TURNIP))",
  "vulkan": "yes",
  "issues": ["phantom_process_killer_enabled", "virgl_missing"],
  "recommended_actions": [
    "disable phantom process killer",
    "install VirGL renderer: pkg install virglrenderer-android -y"
  ]
}
```

### `ternux info --json`

```json
{
  "command": "info",
  "status": "ok",
  "timestamp": "2026-08-15T14:30:00Z",
  "version": "1.3.0",
  "android_version": "14",
  "architecture": "aarch64",
  "model": "SM-S908E",
  "manufacturer": "samsung",
  "ram_gb": "12",
  "storage_gb": "64",
  "termux_version": "0.118.1",
  "gpu": "Adreno (730)",
  "vulkan": "yes",
  "backend": "zink-turnip",
  "renderer": "zink Vulkan (Adreno (TM) ... (MESA_TURNIP))",
  "phantom_process_killer": "enabled"
}
```

### `ternux benchmark --json`

```json
{
  "command": "benchmark",
  "status": "complete",
  "timestamp": "2026-08-15T14:30:00Z",
  "version": "1.3.0",
  "glmark2_score": "1425",
  "vkmark_score": "850",
  "renderer": "zink Vulkan (Adreno (TM) ... (MESA_TURNIP))",
  "gpu": "Adreno (730)",
  "backend": "zink-turnip",
  "vulkan": "yes",
  "results": "glmark2:1425,vkmark:850,renderer:zink Vulkan (Adreno (TM) ... (MESA_TURNIP)),status:hardware_accelerated"
}
```

### `ternux profile --json`

```json
{
  "command": "profile",
  "status": "complete",
  "timestamp": "2026-08-15T14:30:00Z",
  "version": "1.3.0",
  "android_version": "14",
  "architecture": "aarch64",
  "model": "SM-S908E",
  "manufacturer": "samsung",
  "ram_gb": "12",
  "storage_gb": "64",
  "termux_version": "0.118.1",
  "gpu": "Adreno (730)",
  "vulkan": "yes (Adreno)",
  "backend": "zink-turnip",
  "phantom_process_killer": "enabled"
}
```

### `ternux verify --json`

```json
{
  "command": "verify",
  "status": "passed",
  "timestamp": "2026-08-15T14:30:00Z",
  "version": "1.3.0",
  "checks": "termux-x11:installed,proot-distro:installed,pulseaudio:installed,launcher:present,debian:installed,debian_services:ok,turnip_driver:present",
  "android_version": "14",
  "gpu": "Adreno (730)"
}
```

### `ternux backend --json`

```json
{
  "command": "backend",
  "status": "ok",
  "timestamp": "2026-08-15T14:30:00Z",
  "version": "1.3.0",
  "gpu": "Adreno (730)",
  "backend": "zink-turnip",
  "renderer": "zink Vulkan (Adreno (TM) ... (MESA_TURNIP))",
  "vulkan": "yes (Adreno)",
  "available_backends": "zink-turnip,virgl"
}
```

## Error response (any command)

```json
{
  "command": "doctor",
  "status": "error",
  "timestamp": "2026-08-15T14:30:00Z",
  "version": "1.3.0",
  "error": "Not running inside Termux environment"
}
```

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*