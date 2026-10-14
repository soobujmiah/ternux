---
title: "Blender GPU MCP"
description: "Use Ternux's local Blender GPU MCP from a connected coding-agent client."
lang: "en"
alt_url: "/bn/docs/BLENDER-MCP.html"
---

Ternux includes a local, standard-library-only MCP server that gives a connected
agent three tools for the established headless Blender GPU route. It invokes the
same `DISPLAY=:9 GALLIUM_DRIVER=zink blender -b --factory-startup` path used by
the measured EEVEE workflow; it does not add an in-Blender plugin or change the
render baseline.

## Make sure the agent can see the tools

MCP access is specific to the client session. This command registers the server
for the current user in **Claude Code**:

```bash
claude mcp add --scope user blender-gpu -- python3 ~/ternux/tools/blender-gpu-mcp/server.py
```

Run it once from the environment where Claude Code and the Ternux checkout are
available. Then type `/mcp` in the Claude Code session or start a new session,
and confirm that `blender-gpu` exposes `gpu_check`, `render_script`, and
`render_blend`.

Other coding-agent clients need their own MCP connection to this local stdio
server. Installing or registering it in Claude Code does not make the tools
available to every agent. Before asking an agent to render, check that these
tool names are present in that session. If they are absent, reconnect/configure
the MCP client first; the agent must not claim to have called the MCP tools.

## Choose a tool

| Tool | Use it for | Main inputs |
|---|---|---|
| `gpu_check` | Check that the display and Zink/Turnip renderer are ready. Run this first after a zero-frame render. | Optional display, default `:9`. |
| `render_script` | Run a Blender Python script, optionally after opening a `.blend`. | Absolute script path; optional absolute `.blend`, script arguments, display, and timeout. |
| `render_blend` | Render one frame, a frame range, or the scene's full range from an existing `.blend`. | Absolute `.blend` path and absolute output prefix; optional frame bounds, display, and timeout. |

You can ask the connected agent in normal language, for example:

- “Check the Blender GPU route before rendering.” → `gpu_check`
- “Render `/absolute/project/render.py` to `/absolute/project/test.png`.” →
  `render_script`, with the output path passed after `--` as a script argument.
- “Render frames 1–120 from `/absolute/project/scene.blend` to
  `/absolute/project/frames/frame_`.” → `render_blend` with `frame_start: 1`
  and `frame_end: 120`.

The included smoke scene can be rendered through `render_script` with absolute
paths:

```text
script:      /absolute/path/ternux/tools/blender-gpu-mcp/examples/smoke_render.py
script_args: ["/absolute/path/to/output/frame.png"]
```

The equivalent direct command is:

```bash
DISPLAY=:9 GALLIUM_DRIVER=zink blender -b --factory-startup \
  --python /absolute/path/ternux/tools/blender-gpu-mcp/examples/smoke_render.py \
  -- /absolute/path/to/output/frame.png
```

The server starts Xvfb on `:9` only if that display is not already available.
It requires absolute paths, does not search directories, and deletes nothing.
The tool response reports frames written, render timing, output paths, and a
diagnosis when the render path fails.

## Read a zero-frame result

Run `gpu_check` first, then use the reported diagnosis:

- **`EGL_BAD_MATCH`**: Blender had no usable X display/GL context. The headless
  route needs Xvfb on `:9`.
- **`Illegal instruction` / `SIGILL` with `llvmpipe`**: Mesa selected the
  software renderer. A valid Adreno run must report Zink over Turnip; check the
  renderer from `gpu_check` before retrying.

These errors identify a display/renderer setup failure; they do not establish
that the scene itself is faulty. Do not switch to Cycles or software rendering
for the established Redmi workstation.

## Evidence

On 2026-10-14, the established Redmi Turbo 4 Pro setup reported Zink over
Adreno 825 / Mesa Turnip. One 320×180 EEVEE Next smoke frame took 2.49 seconds
of Blender time and 6.92 seconds wall time including process startup and shader
compilation. This points to that dated measurement; it is not a new benchmark
or a promise for other devices. See the [MCP implementation and verification
record](https://github.com/soobujmiah/ternux/blob/main/tools/blender-gpu-mcp/README.md)
and [rendering workflow](https://github.com/soobujmiah/ternux/blob/main/experiments/cartoon-pipeline/README.md).
