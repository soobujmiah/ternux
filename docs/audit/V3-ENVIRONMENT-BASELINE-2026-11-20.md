# Ternux V3 initial environment baseline

**Captured:** 2026-11-20 (Asia/Dhaka)\
**Repository:** `/data/data/com.termux/files/home/ternux`\
**Purpose:** reproducible Phase 0 snapshot before V3 implementation.

## Source checkout

- Host/runtime: Android 16, ARM64 (`arm64-v8a`), native Termux shell; Linux kernel reports Android-hosted environment.
- Branch: `main`; `HEAD` and `origin/main`: `f04b7261ef9ba2dba2c38fd987f760e80583f2d2`.
- `origin`: `https://github.com/soobujmiah/ternux.git`.
- `git status --short --branch`: `## main...origin/main`; clean, no untracked non-ignored files.
- Git history begins with current main and recent commits; local branch is not ahead/behind origin at capture.
- Tracked paths: 1,791. See [`FILE-INVENTORY.md`](FILE-INVENTORY.md) for path, mode, byte size, and SHA-256 checklist.
- Ignored local artifacts observed: `.astro/`, `dist/`, `node_modules/`, Python `__pycache__/` directories, and `distro-test-retest.log`. These are not tracked source. Their complete 9,879-path ignored inventory, hashes, and limits is in [`IGNORED-ARTIFACT-INVENTORY.md`](IGNORED-ARTIFACT-INVENTORY.md). No cleanup was performed.
- Repo contract: [`AI_ASSISTANT.md`](../../AI_ASSISTANT.md). It requests `AGENT_NAVIGATION.md`, but no such file exists in this checkout; this absence is recorded and not silently replaced.

## Host and available tooling

- Device model reported by Android property: `25053RT47C`; Android release `16`; ABI `arm64-v8a`.
- CPU count reported: 8. `/proc/meminfo`: 11,503,324 kB total, 5,518,128 kB available at the latest continuation check (a point-in-time value).
- Internal Termux home filesystem: 232 GB total, 171 GB used, 61 GB available at latest continuation check. No external/shared storage was scanned.
- Available commands observed: `git`, `adb` (present but unusable; see below), `proot-distro`, `proot`, `termux-info`, `pkg`, `python3`, `node` (present but unusable; see below), and `gh`. `shellcheck` was not found on native Termux PATH; it is available in the installed Debian guest.
- Native Ternux CLI: `/data/data/com.termux/files/usr/bin/ternux`, reports `ternux v2.0.1`.
- `ternux doctor --quick --json`: status `ok`; 17 checks OK, 0 warnings, 0 failures, 3 informational. Reports Android 16, aarch64, ~61 GB free, ~5 GB available RAM, four installed managed guests (Alpine, Debian, Kali, Ubuntu), Termux:X11 and PulseAudio installed, Adreno 825, Vulkan enumerated, recommended Zink, renderer `zink Vulkan 1.4 (Adreno (TM) 825 (MESA_TURNIP))`. These are doctor observations at capture, not independent graphics qualification.
- `ternux distro list`: 15 catalog profiles, 4 installed and labeled device-qualified by Ternux. The only installed profiles are Debian, Ubuntu, Kali, Alpine. `ternux manager status` reports direct CLI mode, guest manager available, 4 guests; Debian and Ubuntu desktops running. This records product output; the profile qualification claims are independently re-audited separately.
- Read-only guest `/etc/os-release` results: Debian 13.7 (trixie); Ubuntu 26.04.1 LTS (Resolute); Kali rolling 2026.3; Alpine 3.24.4. These are guest release IDs at capture, not a claim that every package is current.
- Android device access via `adb` was attempted read-only (`adb devices -l` and property reads) and failed before execution: Termux `adb` could not link because symbol `_ZNSt6__ndk113__hash_memoryEPKvm` was unavailable. Therefore no ADB device enumeration or shell evidence is available from that binary in this session.
- Astro website build/format invocation could not start because native Termux `node` fails at dynamic linking with the same missing Android NDK symbol. Debian's installed toolchain has Bats, ShellCheck, and PyYAML 6.0.2; it does not currently have `node`/`npm`. A later isolated Node v22.23.5 ARM64 binary was run inside Debian PRoot against a temporary copy of the worktree: `npm ci`, Astro build (124 pages and 60 finalized routes), and Prettier format check passed. The native Termux toolchain remains unusable, and no Debian Node/npm package was installed.

## Active project-owned runtime observed

- Process inspection showed a running Ternux Debian PRoot desktop, Termux:X11 display `:1`, XFCE session processes, IBus, PulseAudio, session D-Bus, Ternux window-fit helper, and the PRoot guest process. Do not interpret this as an inventory of every host service; the process capture was scoped to identify Ternux-owned runtime processes.
- `ternux doctor` reports Alpine, Debian, Kali, and Ubuntu are installed. Exact guest package versions and full component inventory remain to be captured.
- No process was stopped, no Ternux installation was changed, and no Android settings were changed.

### Continuation check — 2026-11-20

- Reconfirmed `HEAD == origin/main == f04b7261ef9ba2dba2c38fd987f760e80583f2d2`, branch `main`, and the expected GitHub origin. At this snapshot the audit had seven modified tracked documentation files and nine untracked audit deliverables. The later continuation has 37 modified tracked files, nine audit documents plus one untracked workflow-policy test; these are audit work, not pre-existing source changes.
- Re-ran `ternux --version`, `ternux manager status`, and `ternux doctor --quick --json`: v2.0.1; direct CLI/guest manager; four installed guests; Debian and Ubuntu desktops running; 17 OK, zero warnings/failures, three informational checks. Renderer still reports Zink/Vulkan 1.4/Turnip on Adreno 825.
- Re-ran `nproc`, `/proc/meminfo`, `df`, and `termux-info`: eight cores, 11,503,324 kB total memory, 5,518,128 kB available at that instant, 61 GB free on the 232 GB internal filesystem, Android 16, Termux F-Droid 0.119.0-beta.3, arm64-v8a. No shared-storage scan was made.
- Rechecked native `node`, `npm`, and `adb`; all fail before startup on missing Android linker symbol `_ZNSt6__ndk113__hash_memoryEPKvm`. Debian PRoot exposes node/npm paths through host binds but has no installed Debian Node/npm packages; Bats 1.11.1, NumPy 2.2.4, PyYAML 6.0.2, and ShellCheck 0.10.0 are installed there.
- Process inspection again found the Debian PRoot/XFCE session, Termux:X11 `:1`, IBus, PulseAudio, D-Bus, and Ternux window-fit helper. Guest X sockets `:1`–`:4` exist. No process, mount, guest, or service was changed. Process arguments include long guest startup scripts, so only process names/ownership were used as evidence.
- Current ignored build/dependency artifacts remain excluded by `.gitignore`; no cleanup was performed. Initial source-baseline facts above remain tied to the clean checkout before audit deliverables and documentation corrections.

## Test/build dependencies and evidence boundary

- Node project dependencies exist locally (`node_modules/` ignored); `package.json` names Astro `^7.4.7`, `marked` `^18.0.1`, `marked-gfm-heading-id` `^4.1.4`, Prettier `^3.9.10`, and `prettier-plugin-astro` `^1.1.1`. Actual resolved versions are pending lockfile/dependency review.
- The exact-head CI runs and repeated local checks completed during this audit are recorded in [`TEST-EVIDENCE-MATRIX.md`](TEST-EVIDENCE-MATRIX.md). Native Termux Node remains unusable; the isolated Debian PRoot Node run is build evidence, not physical-device package qualification.
- `.repo/STATUS.md` is generated and predates this checkout: it reports SHA `3bfb0fb…`, while current `HEAD` is `f04b726…`. It is stale at this capture and must not be treated as current exact-head CI evidence.
- GitHub Actions query after confirming `origin/main == HEAD` showed current-head Validate run `44671809723`, Termux APT package artifact run `44671809736`, and Repository State Contract run `44671809722`, all completed successfully on `f04b7261ef9ba2dba2c38fd987f760e80583f2d2` at 2026-11-20 04:03:22 UTC. These are CI evidence, not physical-device qualification. Despite those runs, the checked-in generated `.repo/STATUS.md` still reflects the prior SHA at capture.
- Read-only `python3 tests/live_source_parity.py` checked 1,648 live Ternux-owned paths across native Termux and four guests and reported 17 mismatches: 11 native source/module/resource mismatches, two unmapped Debian/Ubuntu `/usr/local/bin/ternux-app-center` files, plus current package-manager launcher parity mismatches in all four guests. No live component was modified.
- Repository workflow source contains 64 GitHub `uses:` action refs; all 64 are tag refs rather than full 40-character SHA pins. `uninstall.sh` direct-pipe recovery fetches `core.sh`, `desktop.sh`, and `uninstall.sh` from mutable `raw.githubusercontent.com/.../main`. Startup authentication and password creation use one salted SHA-256 digest. These are independently observed high/medium-priority review leads, not yet fully risk-tested findings.
- `tests/firefox_package_matrix.sh` requires Docker; no `docker` command or local Docker socket was found in this runtime. CI on Ubuntu can cover that matrix; this local limitation is separate from the exact-head CI success above.
- The prior audit `docs/audit/REPOSITORY-FULL-AUDIT-2026-11-20.md` remains unchanged and is historical evidence. It reports a baseline at older SHAs and expressly limits its scope; all findings will be independently reassessed.

## Reproduction commands

Run from the repository root:

```sh
git status --short --branch
git rev-parse HEAD
git rev-parse origin/main
git remote -v
git ls-files | wc -l
getprop ro.product.model
getprop ro.build.version.release
getprop ro.product.cpu.abi
nproc
grep -E 'MemTotal|MemAvailable' /proc/meminfo
df -h "$HOME" "$PREFIX"
ternux --version
ternux doctor --quick --json
adb devices -l  # currently fails at Termux adb dynamic linker stage
```


### Runtime recheck — 2026-11-20 09:47 UTC

- Re-read Android properties: model `25053RT47C`, Android 16, `arm64-v8a`; eight CPU cores. The internal 232 GB filesystem had about 61 GB free. `free -h` showed 10 GiB RAM and about 4.7 GiB available; a nearby `ternux doctor --quick` sample reported about 4.0 GB available, illustrating point-in-time variation.
- Native `/data/data/com.termux/files/usr/bin/ternux --version` reports v2.0.1. `ternux manager status` reports direct CLI mode, guest manager available, four installed guests, and running Debian/Ubuntu desktops. `ternux distro list` reports Debian, Ubuntu, Kali, and Alpine installed and ready; the other eleven catalog recipes are not installed. The managed extension root `~/.local/opt/ternux-extensions` was absent at this recheck.
- `ternux status --json` returned four guest records: Debian/Ubuntu `READY` with active desktops on `:1` and `:2`; Kali/Alpine `STOPPED`. X11 socket/server and PulseAudio observations also appear for the stopped profiles, consistent with shared host services; they are not evidence those guests have active desktop sessions. The read-only query made no lifecycle changes.
- Process-name inspection saw Termux:X11 servers `:1` (Debian) and `:2` (Ubuntu), two PRoot processes and their guest desktop processes, PulseAudio, and session D-Bus. Other system processes included Codex and image loaders; they are unrelated to Ternux. No process, service, guest, mount, or Android setting was changed.
- First bounded attempts had transient delays: `ternux status --json` exceeded a 15-second wrapper but completed under a 60-second wrapper; `ternux doctor --quick` exceeded a 60-second wrapper once, then an immediate traced retry completed with 17 OK, 0 warnings, 0 failures, and 3 informational checks. Doctor reported Adreno 825, hardware Vulkan enumeration, and Zink Vulkan 1.4/Turnip. This is diagnostic evidence only, not a new graphics qualification.
- Git remained on `main` with `HEAD == origin/main == f04b7261ef9ba2dba2c38fd987f760e80583f2d2`; audit worktree changes are listed in the current inventory delta. Native `adb` still cannot start because of the Android linker symbol failure documented above. All 9,879 current ignored paths were compared to the ignored-artifact ledger by size and SHA-256 (symlink target text for symlinks); there were zero missing, stale, or mismatched entries.
