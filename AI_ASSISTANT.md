# Ternux repository guidance

This file contains Ternux-specific working rules. Load SKB's
`ASSISTANT_CONTEXT.md` and `profile/assistant-guidance.md`; use
`AGENT_NAVIGATION.md`, `standards/policy-resolution.md`, and the relevant
task-specific standards as the shared engineering, evidence, authorization,
and knowledge-return baseline. This file defines only Ternux-specific rules.

## Sources of truth

- Installer behavior and supported commands: source code and `COMMANDS.md`.
- User entry points: root `README.md` and the English/Bengali website home pages.
- Detailed usage and reproducibility: `docs/`, `guides/`, and `experiments/`.
- Release gates and current accelerator qualification: `docs/ACCELERATOR-RELEASE-PLAN.md`.
- Generated branch/build/test state: `.repo/STATUS.md`; do not edit `.repo/` by hand.
- Current implementation facts follow the checked-out source and GitHub Actions
  evidence. Distinguish `main`, open pull requests, local changes, and deployed
  website content when reporting status.

## Documentation contract

- Keep README and website home pages compact, with easy installation and basic
  usage. Keep full procedures, technical details, and experiment history in the
  repository docs.
- Maintain aligned English and Bengali docs, navigation, reciprocal language
  links, and stable section links.
- Classify evidence precisely: **measured**, **observed**, **verified**, or
  **untested**. A build, renderer report, backend detection, inference correctness,
  and performance measurement are separate claims.
- Do not combine Blender viewport identification with EEVEE render measurements;
  do not combine llama.cpp evidence with stable-diffusion.cpp or the separate QNN
  SD1.5 experiment.
- **Blender render default on the established Termux/PRoot Redmi workstation:**
  use EEVEE Next with Adreno GPU offload through Zink/Turnip. For headless
  rendering, use `--with-blender` to install Blender and Xvfb, then run Blender
  with `DISPLAY=:9` and `GALLIUM_DRIVER=zink` (see
  `experiments/cartoon-pipeline/README.md`). Do not
  switch to Cycles or software rendering, or ask the owner to restate this
  preference. First verify the actual runtime and renderer; if this workstation
  path is unavailable, explain the limitation. Follow a different route only
  when the owner requests it.
- **When starting Blender work as an agent, check whether this session exposes
  `blender-gpu.gpu_check`, `blender-gpu.render_script`, and
  `blender-gpu.render_blend`.** If available, use the Ternux local MCP tools
  and follow `docs/BLENDER-MCP.md`; run `gpu_check` before rendering. MCP
  registration is client-specific: Claude Code's user registration does not
  grant access to another agent client. If the tools are absent, say so and use
  the documented direct Blender command or ask the owner to connect the client.
- **Driving that render from an agent:** `tools/blender-gpu-mcp/` wraps exactly the
  command above as an MCP server (`gpu_check`, `render_script`, `render_blend`),
  so the environment cannot be silently lost between calls. Prefer it over
  re-deriving `DISPLAY`/`GALLIUM_DRIVER` per shell-out, and run `gpu_check`
  before reporting a render failure: `EGL_BAD_MATCH` means no display and
  `Illegal instruction` means llvmpipe was selected — neither is a scene problem.
  It keeps `--factory-startup`, so it does not change the measured baseline.
- Update the canonical docs in the same change as behavior or evidence changes.
  CI refreshes generated `.repo/` state after eligible `main` builds; it cannot
  author or infer human-written explanations and decisions.
- Keep one canonical record for each active topic. Preserve historical evidence
  where useful, but remove completed handoffs when their unique facts have been
  transferred to canonical docs and all inbound links are updated.

## Release and evidence boundaries

- Do not treat experimental HTP or QNN paths as supported release features.
- Keep release assets, checksums, manifests, installer behavior, and the release
  plan consistent; verify each claim against the relevant workflow or device log.
- Physical GPU/NPU, thermal, inference, and rendering claims require evidence
  from the actual target device. CI success alone is not device qualification.
