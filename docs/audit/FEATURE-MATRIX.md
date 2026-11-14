# Ternux feature and qualification matrix

**Audit snapshot:** 2026-11-13, 16:11 UTC. This matrix applies to Ternux
v2.0.0 on the documented Redmi Turbo 4 Pro reference device unless a row says
otherwise. “Installed”, “detected”, “initialized”, “executed correctly”, and
“measured” are separate evidence levels.

**Current distribution decision (2026-11-14):** v2.0.0 GitHub release removed;
its Git tag retained. Stable APT withdrawn in Pages run `43532161200` (stable
paths HTTP 404, opt-in signed RC HTTP 200). Do not republish stable v2. The next
stable target is v3 after its architecture and acceptance gates are complete.

The 12:20 UTC read-only diagnostic recheck confirmed all three live guests
remain READY. Debian and Alpine probes used their session displays and reported
Zink/Turnip. Ubuntu also reported Zink/Turnip when queried with the running
session's environment; the default doctor path falsely reported software
fallback because its optional overlay library-path marker was absent. An older
saved `archlinux` selection also caused default doctor to report Debian
missing, despite the active Debian desktop. Regression fixes merged in PR #204
and are in current main; the released package remains unchanged.

## Implemented and verified

| Capability | Evidence | Scope |
|---|---|---|
| v2.0.0 release and signed Termux APT channel | Historical tag, `.deb`, checksum and signed-index evidence; stable distribution withdrawn 2026-11-14 | Not currently available from stable APT; existing installs remain intact |
| Debian, Ubuntu, Alpine provisioning and management | Clean-guest CI and release records; current live `tx status` and `tx verify` pass for all three | These are the only v2-supported desktop guests; Debian has deeper qualification evidence |
| Firefox package/runtime qualification | Clean CI browser matrix for exactly Debian, Ubuntu, Alpine; prior live desktop launches observed on all three | Does not qualify other guest recipes or every browser update indefinitely |
| Separate live desktop sessions | Current `tx status`: Debian `:0`, Ubuntu `:1`, Alpine `:2`, all `READY`; X11 and PulseAudio route checks report ready | Existing device sessions only; not a clean reinstall test |
| Guest shared-storage behavior | Installer and release documentation preserve default Android shared-storage exposure; scoped grant/revoke commands are implemented | Does not expose Termux private application data; path grants remain explicit where used |

## Implemented but partially verified

| Capability | Evidence | Remaining limit |
|---|---|---|
| Adreno graphics stack | Current `tx verify` reports Turnip present in all three guests; earlier device records document Zink/Turnip and graphics workload checks | This audit did not rerun `glxinfo`, Vulkan workload correctness, or performance; driver presence alone is not renderer qualification |
| Audio integration | Current per-guest status reports PulseAudio running and route-ready | No playback/capture workload was run in this read-only audit; route status is not proof every GUI mixer or app renders correctly |
| IBus Bengali/English switching | XFCE config/helper and earlier synthetic probes exist | Alpine synthetic event probes conflict; physical Android keyboard delivery is not certified |
| Theme, window fit, and application UI | Earlier live evidence covers GTK/XFCE, titlebar, oversized-window fitting, and tested Firefox controls | Not every toolkit, custom titlebar, menu icon, or future third-party app is covered; not visually rechecked in this snapshot |
| Android camera still capture and microphone recording apps | Host Termux:API-backed app implementations and permission/lifecycle code exist | This audit did not capture a photo or record audio; no continuous camera stream or guest webcam device is established |
| Native manager read-only JSON CLI | `main` has status, guest, capability, and display payloads; display reporting was source-device invoked | The installed v2.0.0 package returns `Unknown command: manager`; source evidence does not promote the released package |
| v3 workspace display allocation | `main` defaults target native `:0`, Debian `:1`, Ubuntu `:2`, Alpine `:3`; collision guards and read-only current/target report implemented and tested | Live v2 mapping remains `:0/:1/:2`; migration is required and intentionally not performed |
| Native Unix-socket manager service | Explicit foreground, read-only service implemented in the working source; device and integration-tested | Not in released v2.0.0 package; no supervisor or GUI |
| CPU/Vulkan LLM workload | Optional installer path and separate device evidence exist for the declared workload/model profile | Preview/optional scope; no broad model, memory, performance, or device guarantee |

## Documented but not implemented

| Capability | Current state |
|---|---|
| Native Termux Control Center GUI | Mobile-first host-side architecture and UX specified; graphical client not implemented |
| Service authorization/session and HTTP loopback adapter | Designed; no service runtime, session token enforcement, CSRF handling, or web client |
| Guest lifecycle mutations through the v3 API | Designed; current v3 CLI payloads are read-only |
| Unified v3 Compute, AI, Device Bridge, and Workspace orchestration | Architecture exists; no v3 orchestrator or broker implementation |
| Model registry, metadata/checksum lifecycle, local inference server management | Architecture and LAI boundary specified; no unified v3 model manager/service |
| Workspace templates, snapshot/recovery UI, and extension SDK | Roadmap/design only; no v3 implementation |

## Experimental

| Capability | Evidence and boundary |
|---|---|
| llama.cpp HTP/HMX | Experimental SM8735/V73 artifacts; known operator/numerical limitations exclude stable support |
| QNN image generation | Research-only artifact; production correctness and performance gates remain open |
| Stable Diffusion CPU/Vulkan | Preview extension; constrained successful runs do not qualify general image quality, stability, or performance |
| Additional AI artifacts | Prerelease status and per-artifact evidence are listed in release history; do not imply they ship as the stable base package |

## Deferred

| Capability | Disposition |
|---|---|
| Twelve additional named PRoot distro recipes | Keep source implementations; defer clean desktop/browser qualification to v3, one profile at a time |
| Other Android SoCs, GPUs, and Android versions | Build a device matrix in v3; Redmi Turbo 4 Pro evidence is not universal compatibility |
| Broader sustained thermal/resource qualification | Use measured per-device workloads in the v3 Compute program; no synthetic thermal promises |
| Full third-party toolkit/theme coverage | Add targeted toolkit probes as real compatibility needs arise; no blanket promise |

## Unsupported

| Capability | Boundary |
|---|---|
| Direct `/dev/video*` webcam streaming from Android camera hardware into a PRoot guest | Ternux Camera uses on-demand Termux:API still capture; it does not create a V4L2 webcam or continuous preview stream |
| General Android NPU/QNN acceleration | Device presence or package installation does not establish an accessible, correct NPU backend; only isolated experimental artifacts are documented |
| Kernel-level containers or root privileges | PRoot is a userland compatibility environment inside Termux, not root or kernel-container isolation |

## Evidence index

- [Current v2 and post-release report](../release/V2-RELEASE-REPORT.md)
- [Release-time v2 report](../V2-RELEASE-REPORT.md)
- [Device verification](DEVICE-VERIFICATION.md)
- [Repository state](REPOSITORY-STATE.md)
- [v2 machine gate inventory](../release-gates.json)
- [v3 implementation status](../project/IMPLEMENTATION-STATUS.md)
