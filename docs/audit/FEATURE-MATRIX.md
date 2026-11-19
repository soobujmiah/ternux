# Ternux feature and qualification matrix

**Audit snapshot:** 2026-11-13, 16:11 UTC. This matrix applies to Ternux
v2.0.0 on the documented Redmi Turbo 4 Pro reference device unless a row says
otherwise. “Installed”, “detected”, “initialized”, “executed correctly”, and
“measured” are separate evidence levels.

## Current repository audit update — 2026-11-20

The current source, website, release, automated checks, and local verification
were re-audited on 2026-11-20. v2.0.1 is the published source release; the
stable Termux APT channel remains withdrawn, and `pkg install ternux` is not
available. The current v3 and website scope, findings, command results, and
environment limits are recorded in the
[2026-11-20 repository audit](REPOSITORY-FULL-AUDIT-2026-11-20.md). The older
tables below remain dated snapshots and must not be read as today's installed
or release state.

## Historical owner scope correction — 2026-11-18

The owner revoked the 2026-11-14 decision that moved the former v3 platform
scope into the next v2 release. Version 2 is frozen to the current
implementation; new architecture and capabilities remain v3 work. The proposed
next release is v2.0.1 because that version is unused in local and remote tag
history. It is a local candidate only, not a published release.

The owner confirms the v2 verified desktop baseline as **Debian, Ubuntu, Kali
Linux, and Alpine Linux**. Evidence depth differs: the clean-container Firefox
CI matrix covers Debian, Ubuntu, and Alpine; Kali has a detailed installed
reference-device desktop check but no clean Kali install in that CI matrix.
Kali evidence is limited to the existing Redmi Turbo 4 Pro guest and the
specific checks recorded in [device verification](DEVICE-VERIFICATION.md).
This baseline does not qualify other Android devices, GPUs, every application,
or every workload. The historical rows below are retained as dated evidence
and are not silently rewritten.

**Historical distribution decision (2026-11-14; superseded 2026-11-18):**
v2.0.0 GitHub release removed; its tag retained. Stable APT withdrawn in Pages
run `43532161200` (stable paths HTTP 404, opt-in signed RC HTTP 200). The
2026-11-14 direction that required former v3 scope for the next v2 release was
revoked by the owner on 2026-11-18. It is preserved here as history and is not a
current release requirement.

The 12:20 UTC read-only diagnostic recheck confirmed all three live guests
remain READY. Debian and Alpine probes used their session displays and reported
Zink/Turnip. Ubuntu also reported Zink/Turnip when queried with the running
session's environment; the default doctor path falsely reported software
fallback because its optional overlay library-path marker was absent. An older
saved `archlinux` selection also caused default doctor to report Debian
missing, despite the active Debian desktop. Regression fixes merged in PR #204
and are in current main; the released package remains unchanged.

## Source update after the 2026-11-13 audit snapshot

On 2026-11-14, the managed reference-device follow-up freshly installed Ubuntu
and Alpine, retained Debian, and verified all three with Turnip/Zink and
synthetic xdotool terminal input. The complete live evidence is in
[DEVICE-VERIFICATION.md](DEVICE-VERIFICATION.md). The current source branch also
adds `tx control`, a read-only loopback browser snapshot; its local security and
CLI integration tests pass. This does not add it to the withdrawn v2.0.0
package, and it does not qualify physical Android keyboard input.

## Local v2.0.1 window-fit correction — 2026-11-18

The local candidate now retains a user's moved window position when resizing;
it clamps the position only when needed to keep the resized window inside the
work area. The behavior was reproduced with the installed watcher and verified
with the local source watcher in one live Debian/XFCE `:1` session using
`xdotool`. The installed helper was not replaced, and this source change is not
published. See [device verification](DEVICE-VERIFICATION.md) for the geometry
values and test boundary.

## Implemented and verified

| Capability | Evidence | Scope |
|---|---|---|
| v2.0.0 release and signed Termux APT channel | Historical tag, `.deb`, checksum and signed-index evidence; stable distribution withdrawn 2026-11-14 | Not currently available from stable APT; existing installs remain intact |
| Debian, Ubuntu, Alpine provisioning and management | Clean-guest CI and release records; current live `tx status` and `tx verify` pass for all three | These are the only v2-supported desktop guests; Debian has deeper qualification evidence |
| Firefox package/runtime qualification | Clean CI browser matrix for exactly Debian, Ubuntu, Alpine; prior live desktop launches observed on all three | Does not qualify other guest recipes or every browser update indefinitely |
| Separate live desktop sessions | Current `tx status`: Debian `:0`, Ubuntu `:1`, Alpine `:2`, all `READY`; X11 and PulseAudio route checks report ready | Existing device sessions only; not a clean reinstall test |
| Kali reference-device desktop check | Existing Kali guest on `:3`: doctor 26 OK / 0 warnings / 0 failures; Zink Vulkan 1.4 on Turnip / Adreno 825; Firefox opened Example Domain; Avro Ctrl+Space cycled English → Bangla → English; PulseAudio loopback captured 242,536 bytes; tiny normal windows were constrained by the live window-fit helper | Current installed guest only; does not add Kali to the v2-supported clean-install/browser CI matrix or qualify other devices |
| Guest shared-storage behavior | Installer and release documentation preserve default Android shared-storage exposure; scoped grant/revoke commands are implemented | Does not expose Termux private application data; path grants remain explicit where used |

## Implemented but partially verified

| Capability | Evidence | Remaining limit |
|---|---|---|
| Adreno graphics stack | Current `tx verify` and per-guest `tx doctor` report Turnip present and Zink Vulkan 1.4 rendering in all four installed guests; Debian, Ubuntu, Kali, and Alpine were checked on the Xiaomi 25053RT47C / Adreno 825 reference device | This qualifies the installed profiles on this device; it does not qualify another Android or GPU family or establish workload performance |
| Audio integration | Fresh Ubuntu, Kali, and Alpine desktop routes resolved `tcp:127.0.0.1:4714`; 2-second `paplay` test tones exited 0 and the owner confirmed audibility. Existing Debian VLC playback was also owner-confirmed. | These named playback sessions only; capture, other apps/devices, process-kill recovery, and clean Termux reinstall are not verified. |
| IBus Bengali/English switching | On 2026-11-16, the owner confirmed physical-keyboard switching in all installed distros; a focused live Alpine terminal check also switched English → Avro Bengali → English through the IBus session | Physical input evidence is owner-reported; the independent check exercised synthetic X11 input on the Xiaomi reference device |
| Theme, window fit, and application UI | Earlier live evidence covers GTK/XFCE, titlebar, oversized-window fitting, and tested Firefox controls | Not every toolkit, custom titlebar, menu icon, or future third-party app is covered; not visually rechecked in this snapshot |
| Shared phone-display window handling | On 2026-11-15, Debian, Ubuntu, Kali, and Alpine live helpers constrained undersized normal windows to a centered 371×516 minimum outer frame on 640×1386 displays; XFCE Terminal Ctrl+plus/minus changed and persisted its font preference on Debian | Current installed guests and tested window types; zoom persistence was exercised in a live Debian X11 terminal |
| Terfetch host and guest startup | On 2026-11-16, native Termux and Debian, Ubuntu, Kali, and Alpine were refreshed from the repository source and passed live source parity; desktop output was screenshot-checked on all four guests, including compact Kali/Alpine monograms on phone-width terminals. Automated checks cover side-by-side logo/facts, single-line fields, and 24–160 columns | Resizing is picked up at the next prompt and refresh preserves scrollback; narrow logo labels are compact monograms rather than full artwork |
| Android camera still capture and microphone recording apps | Termux:API companion APK and `termux-api` package are installed; a local detector fix falls back from Android `cmd` to Termux `pm` | Detector verified; this audit did not capture a photo or test microphone permission/status. No continuous camera stream or guest webcam device is established |
| Native manager read-only JSON CLI | `main` has status, guest, capability, and display payloads; display reporting was source-device invoked | The installed v2.0.0 package returns `Unknown command: manager`; source evidence does not promote the released package |
| v3 workspace display allocation | `main` defaults target native `:0`, Debian `:1`, Ubuntu `:2`, Alpine `:3`; collision guards and read-only current/target report implemented and tested | Live v2 mapping remains `:0/:1/:2`; migration is required and intentionally not performed |
| Native Unix-socket manager service | Explicit foreground, read-only service implemented in current source; device and integration-tested | Not in released v2.0.0 package; no supervisor; the source dashboard is separate from this socket service |
| Local Control Center dashboard | Current working source adds confirmation-bound start/stop for installed Ternux desktops, durable jobs, and job polling alongside loopback snapshots | Not in withdrawn v2.0.0; this working branch has backend integration tests, while device-browser actions, native Android UI, supervisor, and cancellation remain unverified/incomplete |
| CPU/Vulkan LLM workload | Optional installer path and separate device evidence exist for the declared workload/model profile | Preview/optional scope; no broad model, memory, performance, or device guarantee |

## Documented but not implemented

| Capability | Current state |
|---|---|
| Full native Control Center | Partial working-source browser dashboard now has typed desktop actions and durable jobs; full dashboard, native Android client, service-backed sessions, and diagnostics remain incomplete |
| Manager-service authorization and service-owned HTTP adapter | Unix peer-UID authorization exists; the separate browser adapter has a one-hour session key, Host/Origin checks, and action-specific CSRF protection. Service-owned HTTP adapter and authenticated service sessions remain unimplemented |
| Guest lifecycle mutations through the broader manager API | Limited browser start/stop slice exists in working source; general service/API mutation contracts remain incomplete |
| Unified v3 Compute, AI, Device Bridge, and Workspace orchestration | Architecture exists; no v3 orchestrator or broker implementation |
| Model registry, metadata/checksum lifecycle, local inference server management | Future Ternux-owned architecture only; no unified v3 model manager/service. Unrelated product integration is out of scope. |
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
| Additional named PRoot distro recipes | Not part of frozen v2. Arch, Fedora, Void, openSUSE Tumbleweed, CentOS Stream, and Gentoo are v3 feasibility candidates; each needs its own qualification before a support claim |
| Other Android SoCs, GPUs, and Android versions | No compatibility claim follows from this device snapshot; state device-specific boundaries for each future release |
| Broader sustained thermal/resource qualification | Future v3 compute and performance work; use measured per-device workloads and make no synthetic thermal promises |
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

## Current local candidate evidence update — 2026-11-19

The historical matrix above remains a dated snapshot. The following evidence
updates that snapshot for the local v2.0.1 candidate on the same Redmi Turbo 4
Pro / Android 16 / Adreno 825 device; it does not describe a published release.

| Capability | New evidence | Boundary |
|---|---|---|
| Fresh managed desktop install | Ubuntu Resolute, Kali rolling, and Alpine v3.24 were installed from the local candidate and reached Ternux `READY`; existing Debian was retained. | Existing Termux host only; not clean Android/Termux reinstall. Kali clean-container/browser CI remains absent. |
| Audio playback | Each fresh Ubuntu, Kali, and Alpine desktop resolved `tcp:127.0.0.1:4714` / `OpenSL_ES_sink`; `paplay` test tone exited 0 and the owner confirmed audibility. Existing Debian VLC playback was owner-confirmed separately. | Tested playback sessions only; capture, Android process-kill recovery, other devices, and all applications are not qualified. |
| Termux:API discovery | `cmd package path` and `pm path` returned the installed companion APK; `termux-api` package state is installed. The local candidate falls back to `pm` if `cmd` cannot confirm it; the live installed module hash matches this source. | Detection verified; camera capture and microphone permission request/status not tested. |
| Window-fit helper | Local source hash equals deployed helper hash in Debian, Ubuntu, Kali, and Alpine. | Interactive move/resize retention was directly tested only on Debian/XFCE. Hash equality is not behavioral qualification of the other guests. |
| Focused regression suite | `bash tests/focused.sh`: 212 passed, 0 failed. | `tests/bootstrap_source_sync.sh` still fails against the old immutable pin because it lacks the uncommitted local source correction; do not count it as passing. |

The local release reconciliation records the exact audio and bootstrap evidence.
No GitHub repository write, release tag, artifact publication, or remote release
change was performed during this update.

At the latest 2026-11-19 read-only status recheck, all four guests were READY
with X11 running and PulseAudio route-ready; individual `tx verify` passed for
Debian, Ubuntu, Kali, and Alpine. This point-in-time status does not rule out
intermittent X11 stalls or qualify all application behavior.
