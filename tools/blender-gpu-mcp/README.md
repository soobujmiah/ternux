# blender-gpu-mcp

An MCP server that lets an AI agent render with Blender on the Adreno GPU without
re-deriving the environment every time.

The route it wraps is the one the benchmarks were taken with:

```sh
Xvfb :9 -screen 0 1280x720x24 &
DISPLAY=:9 GALLIUM_DRIVER=zink blender -b --factory-startup --python render.py
```

Both halves are load-bearing. With no display Blender falls back to EGL and ends
with `EGL_BAD_MATCH`; with a display but Mesa's own driver choice it renders
through `llvmpipe`, which dies with `Illegal instruction` on this hardware. Both
failures produce zero frames and neither says anything about the scene, which is
what makes them expensive to debug by hand.

## Why a wrapper rather than an in-Blender addon

The widely known Blender MCP servers put a socket inside a running Blender
through an addon. That needs addons enabled — so no `--factory-startup` — and a
live main loop, which `blender -b` does not have: it exits as soon as the
`--python` script returns and never pumps `bpy.app.timers`. Keeping the verified
command intact and wrapping it means the renderer reached over MCP is the same
renderer `docs/BENCHMARKS.md` measured, with no addon in the process and nothing
left running between renders.

## Install

Python standard library only — nothing to install for the server itself. It needs
`blender` and `Xvfb` present (`bash install.sh --with-blender`), and reads
`glxinfo` when available.

```bash
claude mcp add --scope user blender-gpu -- python3 ~/ternux/tools/blender-gpu-mcp/server.py
```

Any MCP client that speaks stdio works the same way; the server is local stdio
only and holds no credentials.

## Tools

| Tool | What it does |
|---|---|
| `gpu_check` | Brings up Xvfb if that display is not already serving, then reports the OpenGL renderer string (must contain `zink`), `gpu_path_ok`, and the Blender version. Run it first whenever a render wrote zero frames. |
| `render_script` | Runs a `bpy` script: `blender -b --factory-startup [blend] --python <script> [-- args]`. Returns exit code, frames written, mean frame time, the paths Blender reported saving, a `diagnosis`, and the tail of stdout. |
| `render_blend` | Renders an existing `.blend`: one frame (`frame_start`), a range (`frame_start`+`frame_end`), or the file's own range. |

## Deliberate limits

- Absolute paths only; a relative or missing path is refused before Blender starts.
- It never enumerates a directory — every path is one the caller named. That
  includes `/sdcard`, where the project files now live: explicit paths work,
  discovery is not offered.
- It starts `Xvfb` only when that display is down, and never stops one it did
  not start.
- It deletes nothing. The only writes are the output paths Blender itself writes.
- It runs the Python it is given, which is the same authority an agent already
  has in this workspace — but it is why this server belongs on local stdio and
  nowhere else.

## Verification

**Measured** 2026-10-14, Redmi Turbo 4 Pro, Debian 13 trixie under PRoot,
Blender 4.3.2: `gpu_check` returned
`zink Vulkan 1.4(Adreno (TM) 825 (MESA_TURNIP))` with `gpu_path_ok: true`, and
`render_script` on `examples/smoke_render.py` wrote one 320×180 EEVEE Next frame
in 2.49 s of Blender time (6.92 s wall, including process start and shader
compilation). A missing script path was refused with `isError: true` instead of
reaching Blender.

Reproduce with the example:

```bash
DISPLAY=:9 GALLIUM_DRIVER=zink blender -b --factory-startup \
  --python examples/smoke_render.py -- /absolute/path/frame.png
```
