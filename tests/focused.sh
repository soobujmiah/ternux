#!/usr/bin/env bash
# Focused dependency-free tests for installer safety and state semantics.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0
ok() { printf 'ok %d - %s\n' "$((pass + fail + 1))" "$1"; pass=$((pass + 1)); }
not_ok() { printf 'not ok %d - %s\n' "$((pass + fail + 1))" "$1"; fail=$((fail + 1)); }
check() {
  local name="$1"; shift
  if "$@"; then ok "$name"; else not_ok "$name"; fi
}

printf 'TAP version 13\n'

# Persisted custom user is the default for later CLI modules.
state="$TMP/state-user"
mkdir -p "$state"
printf 'user=alice\n' > "$state/state"
check "core loads persisted Debian user" env -u TERNUX_USER \
  TERNUX_STATE_DIR="$state" HOME="$TMP/home-user" bash -c \
  '. "$1/lib/core.sh"; test "$TERNUX_USER" = alice' _ "$ROOT"

# Container detection must support PRoot-Distro 5's machine-readable list,
# older Alias/Status output, and both known on-disk rootfs layouts.
if env TERNUX_STATE_DIR="$TMP/state-proot-list" HOME="$TMP/home-proot-list" \
  PREFIX="$TMP/prefix-proot-list" bash -c '
    . "$1/lib/core.sh"
    tnx_has_cmd(){ [ "$1" = proot-distro ]; }
    mode=v5
    proot-distro(){
      case "$mode:$*" in
        "v5:list --quiet") printf "ubuntu\ndebian\n" ;;
        "legacy:list --quiet") return 2 ;;
        "legacy:list") cat <<"EOF"
Installed distributions:
  * Debian GNU/Linux
    Alias: debian
    Status: installed
EOF
          ;;
      esac
    }
    tnx_debian_installed || exit
    mode=legacy
    tnx_debian_installed || exit
    mode=absent
    ! tnx_debian_installed || exit
    mkdir -p "$PREFIX/var/lib/proot-distro/containers/debian/rootfs"
    tnx_debian_installed || exit
    rm -rf "$PREFIX/var/lib/proot-distro/containers"
    mkdir -p "$PREFIX/var/lib/proot-distro/installed-rootfs/debian"
    tnx_debian_installed
  ' _ "$ROOT"; then
  ok "Debian probe supports current, legacy and on-disk PRoot layouts"
else
  not_ok "Debian probe supports current, legacy and on-disk PRoot layouts"
fi

# An existing v5 Debian container must be reused, never passed to install again.
if env TERNUX_STATE_DIR="$TMP/state-debian-reuse" HOME="$TMP/home-debian-reuse" \
  PREFIX="$TMP/prefix-debian-reuse" MARKER="$TMP/debian-install-called" bash -c '
    . "$1/lib/phases.sh"
    tnx_has_cmd(){ [ "$1" = proot-distro ]; }
    tnx_install_guest_cli(){ :; }
    proot-distro(){
      case "$1" in
        list) [ "${2:-}" = --quiet ] && echo debian ;;
        install) : > "$MARKER"; return 9 ;;
        login) return 0 ;;
      esac
    }
    tnx_phase_debian alice >/dev/null && [ ! -e "$MARKER" ]
  ' _ "$ROOT"; then
  ok "Debian phase reuses a PRoot-Distro 5 container"
else
  not_ok "Debian phase reuses a PRoot-Distro 5 container"
fi

# The Debian base keeps VLC + Zenity; Firefox stays optional. Welcome content is
# guest-managed and one-time with or without a browser; VLC uses XCB output.
if env TERNUX_STATE_DIR="$TMP/state-welcome" HOME="$TMP/home-welcome" \
  PREFIX="$TMP/prefix-welcome" MARKER="$TMP/welcome-script" bash -c '
    . "$1/lib/phases.sh"
    tnx_debian_installed(){ return 0; }
    tnx_install_guest_cli(){ :; }
    tnx_guest_login(){ if [ "${3:-}" = bash ] && [ "${4:-}" = -c ] && [[ "$5" == *ternux-welcome.desktop* ]]; then printf "%s\n" "$5" > "$MARKER"; bash -n "$MARKER" || return 1; fi; return 0; }
    tnx_phase_debian alice >/dev/null &&
      grep -q "Exec=/usr/local/bin/ternux-welcome" "$MARKER" &&
      grep -q "mousepad.*fonts-noto-core.*ibus ibus-avro devilspie2" "$1/lib/phases.sh" &&
      grep -q "xfce4-taskmanager.*xfce4-terminal zenity vlc arc-theme" "$1/lib/phases.sh" &&
      grep -q "vout=xcb_x11" "$1/lib/phases.sh" &&
      grep -q "avcodec-hw=none" "$1/lib/phases.sh" &&
      grep -q "qt-minimal-view=0" "$1/lib/phases.sh" &&
      grep -q "qt-video-autoresize=0" "$1/lib/phases.sh" &&
      grep -q "qt-system-tray=0" "$1/lib/phases.sh" &&
      grep -q "rm -f /usr/local/bin/ternux-volume-control /usr/local/bin/pavucontrol" "$1/lib/phases.sh" &&
      ! grep -q "GTK_THEME=\\|GDK_BACKEND=\\|GTK_MODULES" "$1/lib/phases.sh" &&
      grep -q "dbus-run-session -- sh -c" "$1/lib/phases.sh" &&
      grep -q "ibus_tries" "$1/lib/phases.sh" &&
      grep -q "pm-is-supported" "$1/lib/phases.sh" &&
      grep -q "pavucontrol" "$1/lib/phases.sh" &&
      grep -q "devilspie2" "$1/lib/phases.sh" &&
      grep -q "pulseaudio pulseaudio-utils pavucontrol" "$1/lib/phases.sh" &&
      grep -q "ibus-avro" "$1/lib/phases.sh" &&
      grep -q "fonts-noto-core" "$1/lib/phases.sh" &&
      grep -q "ternux-window-fit.desktop" "$MARKER" &&
      grep -q "set_window_geometry" "$1/lib/ternux-window-fit.lua" &&
      ! grep -q "xfce4-terminal vlc firefox-esr" "$1/lib/phases.sh" &&
      sh -n "$1/lib/ternux-welcome.sh" &&
      grep -q "firefox-esr --new-window" "$1/lib/ternux-welcome.sh" &&
      grep -q "welcome-seen" "$1/lib/ternux-welcome.sh" &&
      grep -q "ternux benchmark" "$1/lib/ternux-welcome-gui.py" &&
      grep -q "height = max(250, min(400, screen_height - 96))" "$1/lib/ternux-welcome-gui.py" &&
      grep -q "Ctrl+Space" "$1/lib/ternux-welcome-gui.py" &&
      grep -q "Sobuj Miah" "$1/lib/ternux-welcome-gui.py" &&
      python3 -m py_compile "$1/lib/ternux-welcome-gui.py" &&
      grep -q "ternux-wallpaper.svg" "$1/lib/phases.sh"
  ' _ "$ROOT"; then
  ok "first-run welcome, optional Firefox, Zenity, VLC XCB output are guest-managed"
else
  not_ok "first-run welcome, optional Firefox, Zenity, VLC XCB output are guest-managed"
fi

# The optional browser receives the welcome URL only on its first guest login.
welcome_bin="$TMP/welcome-bin"
welcome_state="$TMP/welcome-state"
mkdir -p "$welcome_bin"
cat > "$welcome_bin/firefox-esr" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$WELCOME_CALLS"
EOF
chmod +x "$welcome_bin/firefox-esr"
if WELCOME_CALLS="$TMP/welcome-calls" XDG_STATE_HOME="$welcome_state" HOME="$TMP/welcome-home" \
  PATH="$welcome_bin:/usr/bin:/bin" sh "$ROOT/lib/ternux-welcome.sh" && \
  WELCOME_CALLS="$TMP/welcome-calls" XDG_STATE_HOME="$welcome_state" HOME="$TMP/welcome-home" \
  PATH="$welcome_bin:/usr/bin:/bin" sh "$ROOT/lib/ternux-welcome.sh" && \
  [ "$(wc -l < "$TMP/welcome-calls")" -eq 1 ] && \
  grep -q 'https://soobujmiah.github.io/ternux/' "$TMP/welcome-calls"; then
  ok "website welcome redirect runs once per guest user"
else
  not_ok "website welcome redirect runs once per guest user"
fi

# GPU updater uses the validated Zink driver workflow through the CLI alias.
if env TERNUX_STATE_DIR="$TMP/state-gpu-update" HOME="$TMP/home-gpu-update" \
  MARKER="$TMP/gpu-update-called" bash -c '
    . "$1/lib/backend.sh"
    tnx_state_get(){ [ "$1" = backend ] && echo zink; }
    tnx_detect_backend(){ echo zink; }
    tnx_phase_gpu(){ [ "$1" = zink ] && : > "$MARKER"; }
    TERNUX_JSON=1 tnx_cmd_gpu update >/dev/null && [ -f "$MARKER" ]
  ' _ "$ROOT"; then
  ok "GPU CLI updater reuses the validated Zink install phase"
else
  not_ok "GPU CLI updater reuses the validated Zink install phase"
fi

# A caller-provided host toolchain path must not override Termux APT libraries.
if env LD_LIBRARY_PATH="$TMP/foreign-libraries" TERNUX_STATE_DIR="$TMP/state-pkg-env" \
  HOME="$TMP/home-pkg-env" bash -c '
    . "$1/lib/core.sh"
    pkg(){ [ "${LD_LIBRARY_PATH-unset}" = "" ] && [ "$*" = "install ternux" ]; }
    apt-cache(){ [ "${LD_LIBRARY_PATH-unset}" = "" ] && [ "$*" = "policy ternux" ]; }
    tnx_termux_pkg install ternux && tnx_termux_apt_cache policy ternux
  ' _ "$ROOT"; then
  ok "Termux package tools ignore a caller-supplied LD_LIBRARY_PATH"
else
  not_ok "Termux package tools ignore a caller-supplied LD_LIBRARY_PATH"
fi

# Package setup keeps the current mirror and suppresses pkg's all-mirror sweep;
# it must not open the full-screen termux-change-repo dialog inside the frame.
if env TERNUX_STATE_DIR="$TMP/state-repos" HOME="$TMP/home-repos" \
  PREFIX="$TMP/prefix-repos" MARKER="$TMP/change-repo-called" bash -c '
    . "$1/lib/phases.sh"
    termux-change-repo(){ : > "$MARKER"; return 1; }
    termux-setup-storage(){ :; }
    proot-distro(){ :; }; termux-x11(){ :; }; pulseaudio(){ :; }; setsid(){ :; }
    tnx_spin_run(){ [ "${TERMUX_PKG_NO_MIRROR_SELECT:-}" = 1 ]; }
    tnx_phase_packages virgl >/dev/null && [ ! -e "$MARKER" ]
  ' _ "$ROOT"; then
  ok "package phase avoids repository dialogs and mirror sweeps"
else
  not_ok "package phase avoids repository dialogs and mirror sweeps"
fi

# Package artifacts must survive the Astro build, which owns dist/.
check "Termux APT artifacts live outside the website dist directory" bash -c '
  grep -Fq "artifacts/ternux-apt/debs" "$1/packaging/termux/build.sh" &&
  grep -Fq "artifacts/ternux-apt/debs" "$1/packaging/termux/manifest.json" &&
  ! grep -R -q "dist/ternux-apt" "$1/packaging/termux"
' _ "$ROOT"

# Repository builds must bind the exact package checksum to a verified full
# signing fingerprint, export only the public key, and remove stale signatures.
apt_fixture="$TMP/apt-fixture"
mkdir -p "$apt_fixture/packaging/termux" "$apt_fixture/artifacts/ternux-apt/debs" "$apt_fixture/lib"
cp "$ROOT/packaging/termux/build-repository.sh" "$apt_fixture/packaging/termux/"
cp "$ROOT/packaging/termux/build.sh" "$apt_fixture/packaging/termux/"
printf 'TERNUX_VERSION="2.0.0"\n' > "$apt_fixture/lib/core.sh"
printf '{"Version":"@VERSION@"}\n' > "$apt_fixture/packaging/termux/manifest.json"
printf 'deb payload\n' > "$apt_fixture/artifacts/ternux-apt/debs/ternux_2.0.0_all.deb"
printf 'stale package\n' > "$apt_fixture/artifacts/ternux-apt/debs/ternux_1.3.0_all.deb"
cat > "$apt_fixture/fake-create-package" <<'EOF'
#!/usr/bin/env bash
set -eu
printf 'current package\n' > "$FAKE_PACKAGE_OUTPUT/ternux_2.0.0_all.deb"
EOF
chmod +x "$apt_fixture/fake-create-package"
if env TERMUX_CREATE_PACKAGE="$apt_fixture/fake-create-package" \
  FAKE_PACKAGE_OUTPUT="$apt_fixture/artifacts/ternux-apt/debs" \
  bash "$apt_fixture/packaging/termux/build.sh" >/dev/null &&
  [[ -s "$apt_fixture/artifacts/ternux-apt/debs/ternux_2.0.0_all.deb" ]] &&
  [[ ! -e "$apt_fixture/artifacts/ternux-apt/debs/ternux_1.3.0_all.deb" ]]; then
  ok "package rebuild keeps only the current Ternux package artifact"
else
  not_ok "package rebuild keeps only the current Ternux package artifact"
fi
cat > "$apt_fixture/fake-apt-repo" <<'EOF'
#!/usr/bin/env bash
set -eu
sign=0
if [[ "$1" = --sign ]]; then sign=1; shift; fi
input="$1"; output="$2"; dist="$3"; component="$4"
mkdir -p "$output/dists/$dist/$component/binary-all"
release="$output/dists/$dist"
deb="ternux_2.0.0_all.deb"
hash="$(sha256sum "$input/$deb" | awk '{print $1}')"
printf 'Package: ternux\nVersion: 2.0.0\nArchitecture: all\nFilename: dists/%s/%s/binary-all/%s\nSHA256: %s\n\n' \
  "$dist" "$component" "$deb" "$hash" > "$release/$component/binary-all/Packages"
printf 'Codename: termux\nSuite: stable\nRelease\n' > "$release/Release"
if ((sign)); then printf 'signed\n' > "$release/InRelease"; fi
EOF
cat > "$apt_fixture/fake-gpg" <<'EOF'
#!/usr/bin/env bash
set -eu
if [[ " $* " == *" --verify "* ]]; then
  printf '[GNUPG:] VALIDSIG %s 20261106 0 0 4 0 1 8 00 %s\n' "$FAKE_SIGNER_FINGERPRINT" "${FAKE_PRIMARY_FINGERPRINT:-$FAKE_SIGNING_FINGERPRINT}"
  exit 0
fi
if [[ " $* " == *" --clearsign "* ]]; then
  output=""; previous=""
  for argument in "$@"; do
    [[ "$previous" != --output ]] || output="$argument"
    previous="$argument"
  done
  printf 'SIGNED InRelease\n' > "$output"
  exit 0
fi
if [[ " $* " == *" --export "* ]]; then
  printf 'PUBLIC KEY ONLY\n'
  exit 0
fi
if [[ " $* " == *" --show-keys "* ]]; then
  printf 'pub:::::::::\nfpr:::::::::%s:\n' "${FAKE_KEY_FINGERPRINT:-$FAKE_SIGNING_FINGERPRINT}"
  exit 0
fi
exit 9
EOF
chmod +x "$apt_fixture/fake-apt-repo" "$apt_fixture/fake-gpg"
apt_fingerprint=0123456789ABCDEF0123456789ABCDEF01234567
if env TERMUX_APT_REPO_TOOL="$apt_fixture/fake-apt-repo" GPG="$apt_fixture/fake-gpg" \
  TERNUX_APT_SIGNING_FINGERPRINT="$apt_fingerprint" FAKE_SIGNING_FINGERPRINT="$apt_fingerprint" \
  FAKE_SIGNER_FINGERPRINT="$apt_fingerprint" \
  bash "$apt_fixture/packaging/termux/build-repository.sh" --sign >"$apt_fixture/sign-success.log" 2>&1 &&
  grep -q '^PUBLIC KEY ONLY$' "$apt_fixture/artifacts/ternux-apt/repository/ternux-archive-key.asc" &&
  grep -q '^Origin: Ternux$' "$apt_fixture/artifacts/ternux-apt/repository/dists/stable/Release" &&
  grep -q '^Codename: stable$' "$apt_fixture/artifacts/ternux-apt/repository/dists/stable/Release" &&
  [[ -s "$apt_fixture/artifacts/ternux-apt/repository/dists/stable/InRelease" ]] &&
  [[ -s "$apt_fixture/artifacts/ternux-apt/repository/ternux-archive-key.asc" ]]; then
  ok "signed APT build verifies its full fingerprint and exports only public key"
else
  cat "$apt_fixture/sign-success.log" >&2 2>/dev/null || true
  not_ok "signed APT build verifies its full fingerprint and exports only public key"
fi
if env TERMUX_APT_REPO_TOOL="$apt_fixture/fake-apt-repo" GPG="$apt_fixture/fake-gpg" \
  TERNUX_APT_SIGNING_FINGERPRINT="$apt_fingerprint" \
  FAKE_SIGNING_FINGERPRINT="$apt_fingerprint" \
  FAKE_SIGNER_FINGERPRINT=FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF \
  FAKE_PRIMARY_FINGERPRINT="$apt_fingerprint" \
  FAKE_KEY_FINGERPRINT="$apt_fingerprint" \
  bash "$apt_fixture/packaging/termux/build-repository.sh" --sign >/dev/null 2>&1; then
  ok "APT signing accepts a verified signing subkey under the pinned primary key"
else
  not_ok "APT signing accepts a verified signing subkey under the pinned primary key"
fi
if env TERMUX_APT_REPO_TOOL="$apt_fixture/fake-apt-repo" GPG="$apt_fixture/fake-gpg" \
  TERNUX_APT_SIGNING_FINGERPRINT="$apt_fingerprint" \
  FAKE_SIGNING_FINGERPRINT=FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF \
  FAKE_SIGNER_FINGERPRINT=FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF \
  bash "$apt_fixture/packaging/termux/build-repository.sh" --sign >/dev/null 2>&1; then
  not_ok "signed APT build rejects a different key fingerprint"
else
  ok "signed APT build rejects a different key fingerprint"
fi
if env TERMUX_APT_REPO_TOOL="$apt_fixture/fake-apt-repo" GPG="$apt_fixture/fake-gpg" \
  TERNUX_APT_SIGNING_FINGERPRINT="$apt_fingerprint" \
  FAKE_SIGNING_FINGERPRINT="$apt_fingerprint" \
  FAKE_SIGNER_FINGERPRINT="$apt_fingerprint" \
  FAKE_KEY_FINGERPRINT=FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF \
  bash "$apt_fixture/packaging/termux/build-repository.sh" --sign >/dev/null 2>&1; then
  not_ok "signed APT build rejects a public key with a different fingerprint"
else
  ok "signed APT build rejects a public key with a different fingerprint"
fi
if env TERMUX_APT_REPO_TOOL="$apt_fixture/fake-apt-repo" \
  bash "$apt_fixture/packaging/termux/build-repository.sh" >/dev/null &&
  [[ ! -e "$apt_fixture/artifacts/ternux-apt/repository/dists/stable/InRelease" ]] &&
  [[ ! -e "$apt_fixture/artifacts/ternux-apt/repository/ternux-archive-key.asc" ]]; then
  ok "unsigned APT rebuild removes stale signature and public-key files"
else
  not_ok "unsigned APT rebuild removes stale signature and public-key files"
fi

printf 'stale package\n' > "$apt_fixture/artifacts/ternux-apt/debs/ternux_1.3.0_all.deb"
if env TERMUX_APT_REPO_TOOL="$apt_fixture/fake-apt-repo" \
  bash "$apt_fixture/packaging/termux/build-repository.sh" >/dev/null 2>&1; then
  not_ok "APT build rejects stale or unrelated package versions"
else
  ok "APT build rejects stale or unrelated package versions"
fi
rm -f "$apt_fixture/artifacts/ternux-apt/debs/ternux_1.3.0_all.deb"

outside_apt_artifacts="$TMP/apt-outside-artifacts"
mkdir -p "$outside_apt_artifacts/ternux-apt/debs"
printf 'outside marker\n' > "$outside_apt_artifacts/marker"
rm -rf "$apt_fixture/artifacts"
ln -s "$outside_apt_artifacts" "$apt_fixture/artifacts"
if env TERMUX_APT_REPO_TOOL="$apt_fixture/fake-apt-repo" \
  bash "$apt_fixture/packaging/termux/build-repository.sh" >/dev/null 2>&1; then
  not_ok "APT build refuses a symlinked artifacts directory"
else
  [[ -f "$outside_apt_artifacts/marker" ]] && ok "APT build refuses a symlinked artifacts directory" ||
    not_ok "APT build refuses a symlinked artifacts directory"
fi

# Build archives that exercise target-only validation. An unrelated symlink is
# legitimate; a symlink at either selected target is not.
fixture="$TMP/archive"
mkdir -p "$fixture/wrap/usr/lib/aarch64-linux-gnu" \
         "$fixture/wrap/usr/share/vulkan/icd.d" "$fixture/wrap/usr/lib/extra"
printf driver > "$fixture/wrap/usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so"
printf '{}' > "$fixture/wrap/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json"
ln -s ../libvulkan_freedreno.so "$fixture/wrap/usr/lib/extra/legitimate-link.so"
tar -czf "$TMP/good.tar.gz" -C "$fixture" wrap

check "Turnip validator accepts exact regular targets plus unrelated symlinks" \
  env TERNUX_STATE_DIR="$TMP/state-archive" HOME="$TMP/home-archive" bash -c \
  '. "$1/lib/phases.sh"; tnx_validate_turnip_archive "$2"' _ "$ROOT" "$TMP/good.tar.gz"

rm -f "$fixture/wrap/usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so"
ln -s libvulkan_other.so "$fixture/wrap/usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so"
tar -czf "$TMP/bad-link.tar.gz" -C "$fixture" wrap
if env TERNUX_STATE_DIR="$TMP/state-archive-bad" HOME="$TMP/home-archive-bad" bash -c \
  '. "$1/lib/phases.sh"; tnx_validate_turnip_archive "$2"' _ "$ROOT" "$TMP/bad-link.tar.gz"; then
  not_ok "Turnip validator rejects a selected symlink"
else
  ok "Turnip validator rejects a selected symlink"
fi


# Pavucontrol uses Debian’s stock desktop entry without environment overrides.
if python3 - "$ROOT/lib/phases.sh" <<'PAVUCHECK'
import pathlib, sys
source = pathlib.Path(sys.argv[1]).read_text()
assert "rm -f /usr/local/bin/ternux-volume-control /usr/local/bin/pavucontrol" in source
assert "Exec=/usr/local/bin/ternux-volume-control" not in source
assert "GTK_THEME=" not in source and "GDK_BACKEND=" not in source
PAVUCHECK
then
  ok "Pavucontrol inherits the shared desktop theme and launch environment"
else
  not_ok "Pavucontrol inherits the shared desktop theme and launch environment"
fi

# The APT package must carry all resources read relative to its installed phase module.
if python3 - "$ROOT/packaging/termux/manifest.json" "$ROOT" <<'PYMANIFEST'
import json, pathlib, sys
manifest = json.loads(pathlib.Path(sys.argv[1]).read_text())
root = pathlib.Path(sys.argv[2])
files = manifest["data_files"]
required = {
    "lib/ternux/ternux-welcome.sh": "lib/ternux-welcome.sh",
    "lib/ternux/ternux-welcome-gui.py": "lib/ternux-welcome-gui.py",
    "lib/ternux/ternux-window-fit.lua": "lib/ternux-window-fit.lua",
    "lib/ternux/ternux-wallpaper.svg": "lib/ternux-wallpaper.svg",
}
assert all(files.get(dest, {}).get("source") == source for dest, source in required.items())
assert all((root / source).is_file() for source in required.values())
PYMANIFEST
then
  ok "APT manifest includes all Debian phase resources"
else
  not_ok "APT manifest includes all Debian phase resources"
fi

# A missing installer asset must stop the Debian phase before any guest mutation.
resource_fixture="$TMP/resource-fixture"
cp -R "$ROOT/lib" "$resource_fixture"
rm -f "$resource_fixture/lib/ternux-welcome-gui.py"
if env TERNUX_STATE_DIR="$TMP/state-missing-resource" HOME="$TMP/home-missing-resource" \
  bash -c '. "$1/lib/phases.sh"; tnx_phase_debian ternux' _ "$resource_fixture" >/dev/null 2>&1; then
  not_ok "Debian phase fails closed when a packaged resource is missing"
else
  ok "Debian phase fails closed when a packaged resource is missing"
fi

# Generated launchers must target the chosen account, use repeatable --env
# correctly, and start VirGL only on the VirGL route.
launcher_home="$TMP/home-launcher"
mkdir -p "$launcher_home"
if env TERNUX_STATE_DIR="$TMP/state-launcher" HOME="$launcher_home" bash -c '
  . "$1/lib/phases.sh"
  tnx_phase_launcher alice zink en_US.UTF-8 >/dev/null
  tnx_phase_aliases alice bash >/dev/null
  bash -n "$HOME/x.sh" &&
  grep -q "^# TERNUX_DESKTOP_LAUNCHER=12$" "$HOME/x.sh" &&
  grep -q -- "--user alice" "$HOME/x.sh" &&
  grep -q -- "--env DISPLAY=:0" "$HOME/x.sh" &&
  grep -Fq "pkill -9 -f \"^termux-x11 com\\.termux\\.x11([[:space:]]|$)\"" "$HOME/x.sh" &&
  ! grep -Fq "pkill -9 -f termux-x11" "$HOME/x.sh" &&
  grep -q "termux-x11 :0 -legacy-drawing -ac" "$HOME/x.sh" &&
  grep -q "stop_legacy_ternuxx_audio" "$HOME/x.sh" &&
  grep -Fq "ternuxx\\/audio\\/default\\.pa" "$HOME/x.sh" &&
  grep -q "IconThemeName --create -t string -s Adwaita" "$HOME/x.sh" &&
  grep -q "ThemeName --create -t string -s Adwaita-dark" "$HOME/x.sh" &&
  grep -q "defaults_marker=\"/home/alice/.config/ternux/desktop-defaults-v1\"" "$HOME/x.sh" &&
  grep -q "install -d -m 0755" "$HOME/x.sh" &&
  grep -q "dbus-run-session -- sh -c" "$HOME/x.sh" &&
  ! grep -q "dbus-launch --exit-with-session" "$HOME/x.sh" &&
  grep -Fq "session_pid=\\\$!" "$HOME/x.sh" &&
  grep -Fq "wait \\\$session_pid" "$HOME/x.sh" &&
  grep -Fq "[ \\\$tries -ge 50 ]" "$HOME/x.sh" &&
  grep -q "adwaita-icon-theme xfce4 xfce4-taskmanager" "$1/lib/phases.sh" &&
  ! grep -q "adwaita-gtk-theme" "$1/lib/phases.sh" &&
  ! grep -q "pm-utils" "$1/lib/phases.sh" &&
  grep -q "GTK_IM_MODULE=ibus QT_IM_MODULE=ibus XMODIFIERS=@im=ibus" "$HOME/x.sh" &&
  grep -Fq "ibus-daemon --daemonize --xim --replace" "$HOME/x.sh" &&
  grep -Fq "pkill -TERM -x ibus-daemon" "$HOME/x.sh" &&
  grep -Fq "unset IBUS_ADDRESS" "$HOME/x.sh" &&
  ! grep -q -- "--env IBUS_ADDRESS=" "$HOME/x.sh" &&
  grep -q "image-style --create -t int -s 5" "$1/lib/phases.sh" &&
  grep -Fq "monitor0/workspace0/last-image" "$1/lib/phases.sh" &&
  grep -Fq "monitor1/workspace0/last-image" "$1/lib/phases.sh" &&
  grep -q "pgrep -x xfdesktop" "$1/lib/phases.sh" &&
  grep -q "xfdesktop --reload" "$1/lib/phases.sh" &&
  grep -q -- "--env LC_ALL=en_US.UTF-8" "$HOME/x.sh" &&
  grep -q "^trap cleanup EXIT$" "$HOME/x.sh" &&
  grep -qF '\''/run/user/$(id -u)'\'' "$HOME/x.sh" &&
  grep -qF '\''rm -f "$TMPDIR"/.X11-unix/X*'\'' "$HOME/x.sh" &&
  grep -q "pulseaudio --kill.*pkill -KILL -x pulseaudio" "$HOME/x.sh" &&
  grep -q "candidate=4713; candidate<=4722" "$HOME/x.sh" &&
  grep -q "lscpu -p=CPU,MODELNAME" "$HOME/x.sh" &&
  grep -Fq -- "--bind \"\$TNX_CPUINFO_FILE:/proc/cpuinfo\"" "$HOME/x.sh" &&
  grep -Fq "model name\\t: " "$HOME/x.sh" &&
  grep -q "PULSE_MODULE_ID=.*pactl load-module module-native-protocol-tcp" "$HOME/x.sh" &&
  grep -Fq "TNX_PID_FILE=\"\${TNX_PID_FILE:-\$HOME/.local/share/ternux/session/desktop.pid}\"" "$HOME/x.sh" &&
  grep -Fq "cat \"\$TNX_PID_FILE\"" "$HOME/x.sh" &&
  grep -q -- "--env PULSE_SERVER=\"tcp:127.0.0.1:\$PULSE_PORT\"" "$HOME/x.sh" &&
  ! grep -q "PULSE_SERVER=tcp:127.0.0.1:4713" "$HOME/x.sh" &&
  ! grep -q "pkill.*dbus" "$HOME/x.sh" &&
  grep -q "chmod 700 ~/.runtime" "$HOME/x.sh" &&
  ! grep -q "^virgl_test_server_android " "$HOME/x.sh" &&
  ! grep -q "pkill.*dbus" "$HOME/.bashrc" &&
  grep -q "alias x=.*ternux start" "$HOME/.bashrc" &&
  grep -q "alias killx=.*ternux stop" "$HOME/.bashrc" &&
  grep -q "alias xgo=.*ternux start" "$HOME/.bashrc" &&
  grep -q "login debian --shared-tmp --user alice" "$HOME/.bashrc" &&
  grep -q "droot=.*login debian --shared-tmp" "$HOME/.bashrc"
' _ "$ROOT"; then
  ok "Zink launcher and aliases preserve user and backend boundaries"
else
  not_ok "Zink launcher and aliases preserve user and backend boundaries"
fi

if env TERNUX_STATE_DIR="$TMP/state-pulse-port" HOME="$TMP/home-pulse-port" bash -c '
  mkdir -p "$HOME"
  . "$1/lib/phases.sh"
  tnx_phase_launcher ternux zink en_US.UTF-8 >/dev/null
  sed -n "/^PULSE_PORT=.*/,/^# Display/{ /^# Display/d; p; }" "$HOME/x.sh" > "$2/audio-bridge.sh"
  pactl(){
    case "$*" in
      *port=4713*) return 1 ;;
      *port=4714*) printf 91; return 0 ;;
      *) return 2 ;;
    esac
  }
  . "$2/audio-bridge.sh" >/dev/null
  [ "$PULSE_PORT" = 4714 ] && [ "$PULSE_MODULE_ID" = 91 ]
' _ "$ROOT" "$TMP"; then
  ok "launcher falls back to an available loopback audio port after a collision"
else
  not_ok "launcher falls back to an available loopback audio port after a collision"
fi

if env TERNUX_STATE_DIR="$TMP/state-repair-launcher" HOME="$TMP/home-repair-launcher" bash -c '
  mkdir -p "$HOME"
  . "$1/lib/repair.sh"
  tnx_state_get(){ case "$1" in backend) echo zink;; user) echo ternux;; locale) echo en_US.UTF-8;; esac; }
  tnx_ok(){ :; }; tnx_warn(){ :; }; tnx_state_set(){ :; }
  cat > "$HOME/x.sh" <<"OLD"
#!/bin/bash
exit 0
OLD
  chmod +x "$HOME/x.sh"
  _TNX_REPAIR_CHANGED=0
  _tnx_repair_launcher || exit
  [ "$_TNX_REPAIR_CHANGED" = 1 ] && grep -q '^PULSE_PORT=""$' "$HOME/x.sh" || exit
  _TNX_REPAIR_CHANGED=0
  _tnx_repair_launcher || exit
  [ "$_TNX_REPAIR_CHANGED" = 0 ]
' _ "$ROOT"; then
  ok "repair upgrades a legacy launcher and leaves a current launcher intact"
else
  not_ok "repair upgrades a legacy launcher and leaves a current launcher intact"
fi

if env TERNUX_STATE_DIR="$TMP/state-virgl" HOME="$TMP/home-virgl" bash -c '
  mkdir -p "$HOME"
  . "$1/lib/phases.sh"
  tnx_phase_launcher bob virgl bn_BD.UTF-8 >/dev/null
  bash -n "$HOME/x.sh" &&
  grep -q "^virgl_test_server_android " "$HOME/x.sh" &&
  ! grep -q "MESA_LOADER_DRIVER_OVERRIDE=zink" "$HOME/x.sh"
' _ "$ROOT"; then
  ok "VirGL launcher starts only the fallback renderer"
else
  not_ok "VirGL launcher starts only the fallback renderer"
fi

# English and Bengali manual launchers must stay executable and preserve the
# generated Zink launcher's cleanup, runtime-UID, environment and permission
# invariants.
manual_en="$TMP/manual-en-launcher.sh"
manual_bn="$TMP/manual-bn-launcher.sh"
if python3 - "$ROOT/docs/MANUAL.md" "$manual_en" "$ROOT/bn/docs/MANUAL.md" "$manual_bn" <<'PY'
from pathlib import Path
import re, sys
for source, output in ((sys.argv[1], sys.argv[2]), (sys.argv[3], sys.argv[4])):
    blocks = re.findall(r'^```bash\n(.*?)^```[ \t]*$', Path(source).read_text(), re.M | re.S)
    hits = [block for block in blocks if block.startswith('#!/data/data/com.termux/files/usr/bin/bash')]
    if len(hits) != 1:
        raise SystemExit(f'{source}: expected one launcher, found {len(hits)}')
    Path(output).write_text(hits[0])
PY
then
  if bash -n "$manual_en" && bash -n "$manual_bn" && cmp -s "$manual_en" "$manual_bn" &&
     grep -q '^trap cleanup EXIT$' "$manual_en" &&
     grep -qF '/run/user/$(id -u)' "$manual_en" &&
     grep -qF 'rm -f "$TMPDIR"/.X11-unix/X*' "$manual_en" &&
     grep -q 'pulseaudio --kill.*pkill -KILL -x pulseaudio' "$manual_en" &&
     grep -q "candidate=4713; candidate<=4722" "$manual_en" &&
     grep -q "export PULSE_SERVER=\"tcp:127.0.0.1:\$PULSE_PORT\"" "$manual_en" &&
     ! grep -q "PULSE_SERVER=tcp:127.0.0.1:4713" "$manual_en" &&
     ! grep -q 'pkill.*dbus' "$manual_en" &&
     grep -q -- '--env MESA_LOADER_DRIVER_OVERRIDE=zink' "$manual_en" &&
     grep -q 'chmod 700 ~/.runtime' "$manual_en" &&
     ! grep -q '^virgl_test_server_android ' "$manual_en"; then
    ok "manual Zink launchers match generated launcher invariants"
  else
    not_ok "manual Zink launchers match generated launcher invariants"
  fi
else
  not_ok "manual Zink launchers match generated launcher invariants"
fi

# Required failure must stop dependants and only successful phases are marked.
if env TERNUX_STATE_DIR="$TMP/state-required" HOME="$TMP/home-required" bash -c '
  . "$1/lib/phases.sh"
  order="$2/order-required"
  tnx_require_termux(){ :; }; tnx_confirm(){ :; }
  tnx_banner(){ :; }; tnx_phase_header(){ :; }; tnx_celebrate(){ :; }
  tnx_summary_box(){ :; }; tnx_next_steps(){ :; }; tnx_log_error(){ :; }
  tnx_phase_preflight(){ echo preflight >> "$order"; }
  tnx_phase_packages(){ echo packages >> "$order"; return 7; }
  tnx_phase_cli(){ echo cli >> "$order"; }
  set +e
  tnx_install --yes >/dev/null 2>&1
  rc=$?
  set -e
  test "$rc" -eq 7 &&
  test "$(tr "\n" " " < "$order")" = "preflight packages " &&
  tnx_state_done phase_preflight &&
  ! tnx_state_done phase_packages
' _ "$ROOT" "$TMP"; then
  ok "required phase failure stops dependants and is not marked complete"
else
  not_ok "required phase failure stops dependants and is not marked complete"
fi

# Optional failure is retained as final nonzero status but verification runs.
if env TERNUX_STATE_DIR="$TMP/state-optional" HOME="$TMP/home-optional" bash -c '
  . "$1/lib/phases.sh"
  order="$2/order-optional"
  tnx_require_termux(){ :; }; tnx_confirm(){ :; }
  tnx_banner(){ :; }; tnx_phase_header(){ :; }; tnx_celebrate(){ :; }
  tnx_summary_box(){ :; }; tnx_next_steps(){ :; }; tnx_log_error(){ :; }
  for name in preflight packages cli debian gpu audio_fonts launcher aliases phantom verify; do
    eval "tnx_phase_${name}(){ echo ${name} >> \"\$order\"; }"
  done
  tnx_phase_extras(){ echo extras >> "$order"; return 9; }
  set +e
  tnx_install --yes --with-dev >/dev/null 2>&1
  rc=$?
  set -e
  test "$rc" -eq 9 &&
  grep -qx verify "$order" &&
  ! tnx_state_done phase_extras &&
  tnx_state_done phase_verify
' _ "$ROOT" "$TMP"; then
  ok "optional failure continues to verification and remains nonzero"
else
  not_ok "optional failure continues to verification and remains nonzero"
fi

# The wrapper must not silently force --yes for local invocation.
if grep -q 'tnx_install --yes' "$ROOT/install.sh"; then
  not_ok "install wrapper passes --yes only when requested"
else
  ok "install wrapper passes --yes only when requested"
fi

# Direct CLI installation rejects malformed options before any phase starts.
if env TERNUX_STATE_DIR="$TMP/state-install-args" HOME="$TMP/home-install-args" bash -c '
  . "$1/lib/phases.sh"
  reached=0; tnx_require_termux(){ reached=1; }
  set +e
  tnx_install --user >/dev/null 2>&1; missing=$?
  tnx_install --not-an-option >/dev/null 2>&1; unknown=$?
  set -e
  [ "$missing" -eq 2 ] && [ "$unknown" -eq 2 ] && [ "$reached" -eq 0 ]
' _ "$ROOT"; then
  ok "install rejects missing values and unknown options before phases"
else
  not_ok "install rejects missing values and unknown options before phases"
fi

# Android child-process reporting distinguishes enabled, disabled and unknown
# instead of treating every unreadable value as enabled.
for phantom_case in enabled disabled unknown; do
  if env TERNUX_STATE_DIR="$TMP/state-phantom-$phantom_case" \
    HOME="$TMP/home-phantom-$phantom_case" bash -c '
      . "$1/lib/phases.sh"
      phantom_case="$2"
      getprop(){ echo 34; }
      tnx_detect_phantom_killer(){ echo "$phantom_case"; }
      out="$(tnx_phase_phantom)"
      case "$phantom_case" in
        enabled)  grep -q "reported as enabled" <<<"$out" && grep -q "Signal 9 can also mean memory pressure" <<<"$out" ;;
        disabled) grep -q "reported as disabled" <<<"$out" && ! grep -q "Could not read" <<<"$out" ;;
        unknown)  grep -q "Could not read.*do not assume" <<<"$out" && ! grep -q "reported as enabled" <<<"$out" ;;
      esac
    ' _ "$ROOT" "$phantom_case"; then
    ok "phantom setting reports $phantom_case conservatively"
  else
    not_ok "phantom setting reports $phantom_case conservatively"
  fi
done

# Doctor must recommend differential diagnosis, not a categorical system-wide
# safeguard change, when the readable monitor state is enabled.
if env TERNUX_STATE_DIR="$TMP/state-doctor" HOME="$TMP/home-doctor" bash -c '
  mkdir -p "$HOME" "$TERNUX_STATE_DIR"
  printf "backend=virgl\n" > "$TERNUX_STATE_DIR/state"
  : > "$HOME/x.sh"
  . "$1/lib/doctor.sh"
  TERNUX_JSON=1
  tnx_is_termux(){ :; }
  tnx_has_cmd(){ return 0; }
  proot-distro(){ [ "${1:-}" = list ] && echo "debian installed"; }
  tnx_detect_storage_gb(){ echo 10; }
  tnx_detect_vulkan(){ echo yes; }
  tnx_detect_gpu(){ echo Mali; }
  tnx_detect_backend(){ echo virgl; }
  tnx_detect_renderer(){ echo unknown; }
  tnx_detect_phantom_killer(){ echo enabled; }
  tnx_detect_android_version(){ echo 14; }
  tnx_detect_arch(){ echo aarch64; }
  out="$(tnx_cmd_doctor)" || exit
  python3 -c '\''import json,sys
x=json.loads(sys.argv[1])
a=" ".join(x["recommended_actions"])
assert "Review Android process restrictions and other Signal 9 causes" in a
assert "Disable" not in a
assert x["backend"] == "virgl"'\'' "$out"
' _ "$ROOT"; then
  ok "doctor emits a qualified Android process action"
else
  not_ok "doctor emits a qualified Android process action"
fi

# Matching stored target hashes are treated as healthy; a changed target
# invokes the validated GPU phase instead of trusting file presence alone.
for hash_case in matching changed; do
  if env TERNUX_STATE_DIR="$TMP/state-hash-$hash_case" \
    HOME="$TMP/home-hash-$hash_case" bash -c '
      mkdir -p "$HOME" "$TERNUX_STATE_DIR"
      cat > "$HOME/x.sh" <<"EOF"
#!/usr/bin/env bash
# --user alice
export MESA_LOADER_DRIVER_OVERRIDE=zink
EOF
      chmod +x "$HOME/x.sh"
      . "$1/lib/repair.sh"
      hash_case="$2"
      scratch="$3"
      _tnx_repair_kgsl_available(){ :; }
      tnx_has_cmd(){ [ "$1" = proot-distro ]; }
      tnx_state_get(){
        case "$1" in
          backend) echo zink ;;
          freedreno_driver_sha) echo expected-driver ;;
          freedreno_icd_sha) echo expected-icd ;;
          user) echo alice ;;
          locale) echo en_US.UTF-8 ;;
        esac
      }
      tnx_state_set(){ :; }
      proot-distro(){
        case "$*" in
          *libvulkan_freedreno.so*) [ "$hash_case" = matching ] && echo "expected-driver  file" || echo "changed-driver  file" ;;
          *freedreno_icd.aarch64.json*) echo "expected-icd  file" ;;
        esac
      }
      tnx_phase_gpu(){ echo gpu > "$scratch/gpu-called"; }
      _TNX_REPAIR_CHANGED=0
      _tnx_repair_backend >/dev/null || exit
      if [ "$hash_case" = matching ]; then
        [ ! -e "$scratch/gpu-called" ] && [ "$_TNX_REPAIR_CHANGED" = 0 ]
      else
        [ -e "$scratch/gpu-called" ] && [ "$_TNX_REPAIR_CHANGED" = 1 ]
      fi
    ' _ "$ROOT" "$hash_case" "$TMP"; then
    ok "repair handles $hash_case validated Turnip target hashes"
  else
    not_ok "repair handles $hash_case validated Turnip target hashes"
  fi
done

# Backend repair installs a missing VirGL host component, applies canonical
# state, and regenerates a launcher whose backend does not match.
if env TERNUX_STATE_DIR="$TMP/state-backend" HOME="$TMP/home-backend" bash -c '
  mkdir -p "$HOME" "$TERNUX_STATE_DIR"
  . "$1/lib/repair.sh"
  scratch="$2"
  state_log="$scratch/state-log"
  tnx_state_get(){ case "$1" in backend) echo virgl;; user) echo bob;; locale) echo bn_BD.UTF-8;; esac; }
  tnx_state_set(){ printf "%s=%s\n" "$1" "$2" >> "$state_log"; }
  tnx_has_cmd(){
    case "$1" in
      virgl_test_server_android) [ -e "$scratch/virgl-installed" ] ;;
      *) return 1 ;;
    esac
  }
  pkg(){ [ "$*" = "install -y virglrenderer-android" ] && : > "$scratch/virgl-installed"; }
  tnx_phase_launcher(){ printf "%s|%s|%s\n" "$1" "$2" "$3" > "$scratch/launcher-args"; }
  _TNX_REPAIR_CHANGED=0
  _tnx_repair_backend >/dev/null &&
  grep -qx "backend=virgl" "$scratch/state-log" &&
  grep -qx "bob|virgl|bn_BD.UTF-8" "$scratch/launcher-args" &&
  [ "$_TNX_REPAIR_CHANGED" = 1 ]
' _ "$ROOT" "$TMP"; then
  ok "repair applies VirGL and regenerates the backend launcher"
else
  not_ok "repair applies VirGL and regenerates the backend launcher"
fi

# The legacy doctor/repair route may call the GPU phase with `auto`. On a
# non-KGSL device that must resolve to VirGL instead of entering the Turnip
# download path.
if env TERNUX_STATE_DIR="$TMP/state-auto-virgl" HOME="$TMP/home-auto-virgl" \
  TERNUX_KGSL_DEVICE="$TMP/absent-kgsl" bash -c '
  . "$1/lib/phases.sh"
  marker="$2/turnip-auto-called"
  tnx_has_cmd(){ [ "$1" = virgl_test_server_android ]; }
  tnx_resolve_freedreno_asset(){ : > "$marker"; return 1; }
  tnx_phase_gpu auto >/dev/null && [ ! -e "$marker" ]
' _ "$ROOT" "$TMP"; then
  ok "auto GPU repair resolves a non-KGSL device to VirGL"
else
  not_ok "auto GPU repair resolves a non-KGSL device to VirGL"
fi

# Exercise the legacy install.sh doctor dispatcher with isolated local library
# mocks. On this non-KGSL test host, both GPU repair and verification must
# receive the resolved VirGL backend rather than the literal `auto` value.
doctor_wrapper="$TMP/doctor-wrapper"
mkdir -p "$doctor_wrapper/lib"
cp "$ROOT/install.sh" "$doctor_wrapper/install.sh"
cat > "$doctor_wrapper/lib/core.sh" <<'EOF'
TERNUX_VERSION=1.3.0
tnx_info(){ :; }; tnx_ok(){ :; }; tnx_warn(){ :; }; tnx_fail(){ :; }
tnx_debug(){ :; }; tnx_step(){ :; }; tnx_confirm(){ :; }
tnx_state_done(){ [ "$1" != phase_gpu ]; }
tnx_state_mark(){ printf '%s\n' "$1" >> "$DOCTOR_MARKS"; }
tnx_state_clear(){ :; }; tnx_require_termux(){ :; }
EOF
cat > "$doctor_wrapper/lib/phases.sh" <<'EOF'
tnx_phase_preflight(){ [ "${FAIL_PREFLIGHT:-0}" != 1 ] || return 9; }
tnx_phase_packages(){ :; }; tnx_phase_debian(){ :; }
tnx_phase_audio_fonts(){ :; }; tnx_phase_launcher(){ :; }; tnx_phase_aliases(){ :; }
tnx_phase_gpu(){ [ "${FAIL_GPU:-0}" != 1 ] || return 7; printf '%s\n' "$1" > "$DOCTOR_GPU"; }
tnx_phase_verify(){ printf '%s\n' "$2" > "$DOCTOR_VERIFY"; }
EOF
: > "$doctor_wrapper/lib/ui.sh"
if env TERNUX_KGSL_DEVICE="$TMP/absent-kgsl" DOCTOR_GPU="$TMP/doctor-gpu" \
  DOCTOR_VERIFY="$TMP/doctor-verify" DOCTOR_MARKS="$TMP/doctor-marks" \
  HOME="$TMP/home-doctor-wrapper" bash "$doctor_wrapper/install.sh" --doctor --fix --backend auto >/dev/null &&
  grep -qx virgl "$TMP/doctor-gpu" && grep -qx virgl "$TMP/doctor-verify" &&
  grep -qx phase_gpu "$TMP/doctor-marks"; then
  ok "legacy doctor fix propagates the resolved backend"
else
  not_ok "legacy doctor fix propagates the resolved backend"
fi

# The standalone parser returns usage status 2 for missing values, including
# when the following token is another option. Doctor repair must stop before
# every mutation when preflight fails.
bash "$doctor_wrapper/install.sh" --user >/dev/null 2>&1; user_rc=$?
bash "$doctor_wrapper/install.sh" --locale --status >/dev/null 2>&1; locale_rc=$?
bash "$doctor_wrapper/install.sh" --backend --doctor >/dev/null 2>&1; backend_rc=$?
if [ "$user_rc" -eq 2 ] && [ "$locale_rc" -eq 2 ] && [ "$backend_rc" -eq 2 ]; then
  ok "standalone installer reports missing option values as usage errors"
else
  not_ok "standalone installer reports missing option values as usage errors"
fi

rm -f "$TMP/doctor-gpu" "$TMP/doctor-verify" "$TMP/doctor-marks"
env FAIL_PREFLIGHT=1 DOCTOR_GPU="$TMP/doctor-gpu" DOCTOR_VERIFY="$TMP/doctor-verify" \
  DOCTOR_MARKS="$TMP/doctor-marks" HOME="$TMP/home-doctor-wrapper" \
  bash "$doctor_wrapper/install.sh" --doctor --fix --backend auto >/dev/null 2>&1
preflight_rc=$?
if [ "$preflight_rc" -eq 9 ] && [ ! -e "$TMP/doctor-gpu" ] &&
   [ ! -e "$TMP/doctor-verify" ] && [ ! -e "$TMP/doctor-marks" ]; then
  ok "doctor fix aborts before repair phases when preflight fails"
else
  not_ok "doctor fix aborts before repair phases when preflight fails"
fi

rm -f "$TMP/doctor-gpu" "$TMP/doctor-verify" "$TMP/doctor-marks"
env FAIL_GPU=1 DOCTOR_GPU="$TMP/doctor-gpu" DOCTOR_VERIFY="$TMP/doctor-verify" \
  DOCTOR_MARKS="$TMP/doctor-marks" HOME="$TMP/home-doctor-wrapper" \
  bash "$doctor_wrapper/install.sh" --doctor --fix --backend virgl >/dev/null 2>&1
doctor_phase_rc=$?
if [ "$doctor_phase_rc" -eq 7 ] && [ ! -e "$TMP/doctor-gpu" ] &&
   grep -qx virgl "$TMP/doctor-verify" && [ ! -e "$TMP/doctor-marks" ]; then
  ok "doctor fix preserves a failed repair phase status after verification"
else
  not_ok "doctor fix preserves a failed repair phase status after verification"
fi

# Profile names are filenames and must not traverse outside the state profile
# directory. Valid conservative names must continue to save and load.
if env TERNUX_STATE_DIR="$TMP/state-profile-names" HOME="$TMP/home-profile-names" bash -c '
  mkdir -p "$HOME" "$TERNUX_STATE_DIR"
  . "$1/lib/profile.sh"
  tnx_detect_android_version(){ echo 14; }; tnx_detect_arch(){ echo aarch64; }
  tnx_detect_model(){ echo phone; }; tnx_detect_manufacturer(){ echo vendor; }
  tnx_detect_ram_gb(){ echo 8; }; tnx_detect_storage_gb(){ echo 10; }
  tnx_detect_termux_version(){ echo current; }; tnx_detect_gpu(){ echo Adreno; }
  tnx_detect_vulkan(){ echo yes; }; tnx_detect_backend(){ echo zink; }
  tnx_detect_phantom_killer(){ echo unknown; }
  for op in save load compare; do
    set +e; tnx_cmd_profile "$op" ../../escaped >/dev/null 2>&1; rc=$?; set -e
    [ "$rc" -eq 2 ] || exit
  done
  [ ! -e "$2/escaped" ] && [ ! -e "$TERNUX_STATE_DIR/escaped" ] &&
  tnx_cmd_profile save phone-1 >/dev/null &&
  [ -f "$TERNUX_STATE_DIR/profiles/phone-1" ] &&
  tnx_cmd_profile load phone-1 >/dev/null
' _ "$ROOT" "$TMP"; then
  ok "profile names cannot traverse outside the profiles directory"
else
  not_ok "profile names cannot traverse outside the profiles directory"
fi

# A failure in one repair step does not suppress later steps, but the aggregate
# command remains nonzero and its JSON reports a partial result.
if env TERNUX_STATE_DIR="$TMP/state-repair-aggregate" HOME="$TMP/home-repair-aggregate" bash -c '
  mkdir -p "$HOME" "$TERNUX_STATE_DIR"
  . "$1/lib/repair.sh"
  tnx_require_termux(){ :; }
  marker="$2/repair-order"
  _tnx_repair_curl(){ echo curl >> "$marker"; return 9; }
  _tnx_repair_x11(){ echo x11 >> "$marker"; }
  _tnx_repair_backend(){ echo backend >> "$marker"; }
  _tnx_repair_launcher(){ echo launcher >> "$marker"; }
  _tnx_repair_mesa_cache(){ echo cache >> "$marker"; }
  _tnx_repair_pulseaudio(){ echo audio >> "$marker"; }
  TERNUX_JSON=1
  set +e
  out="$(tnx_cmd_repair)"; rc=$?
  set -e
  [ "$rc" -eq 1 ] && [ "$(wc -l < "$marker")" -eq 6 ] &&
  python3 -c '\''import json,sys; x=json.loads(sys.argv[1]); assert x["status"] == "partial"'\'' "$out"
' _ "$ROOT" "$TMP"; then
  ok "repair aggregates step failures and keeps running"
else
  not_ok "repair aggregates step failures and keeps running"
fi

# Scoped uninstall is validated only in a temporary home with mocked container
# operations: cancellation preserves data, and explicit --yes removes only the
# requested mocked container.
if env TERNUX_STATE_DIR="$TMP/state-uninstall" HOME="$TMP/home-uninstall" bash -c '
  mkdir -p "$HOME" "$TERNUX_STATE_DIR" "$2"
  : > "$HOME/x.sh"
  . "$1/lib/uninstall.sh"
  scratch="$2"
  _tnx_uninstall_stop(){ echo stopped >> "$scratch/uninstall-log"; }
  tnx_has_cmd(){ [ "$1" = proot-distro ]; }
  proot-distro(){
    [ "$1" = list ] && { echo "debian installed"; return; }
    [ "$1" = remove ] && echo removed >> "$scratch/uninstall-log"
  }
  _tnx_uninstall_confirm(){ [ "${TERNUX_YES:-0}" = 1 ]; }
  set +e
  tnx_cmd_uninstall container >/dev/null; cancelled=$?
  set -e
  [ "$cancelled" -eq 1 ] && grep -qx stopped "$scratch/uninstall-log" &&
  ! grep -q removed "$scratch/uninstall-log" || exit
  : > "$scratch/uninstall-log"
  tnx_cmd_uninstall container --yes >/dev/null &&
  grep -qx stopped "$scratch/uninstall-log" && grep -qx removed "$scratch/uninstall-log" &&
  [ -e "$HOME/x.sh" ] && [ -d "$TERNUX_STATE_DIR" ]
' _ "$ROOT" "$TMP"; then
  ok "scoped uninstall confirms container deletion and preserves other scopes"
else
  not_ok "scoped uninstall confirms container deletion and preserves other scopes"
fi

# Alias removal uses a same-directory replacement, preserves file mode, and
# refuses malformed marker order or symlink targets without truncation.
if env TERNUX_STATE_DIR="$TMP/state-uninstall-alias" HOME="$TMP/home-uninstall-alias" bash -c '
  mkdir -p "$HOME" "$TERNUX_STATE_DIR"
  . "$1/lib/uninstall.sh"
  cat > "$HOME/.bashrc" <<"EOF"
before
# ==== TERNUX ALIASES ====
alias x="~/x.sh"
# ==== END TERNUX ALIASES ====
after
EOF
  chmod 640 "$HOME/.bashrc"; : > "$HOME/x.sh"
  tnx_cmd_uninstall launcher >/dev/null &&
  [ ! -e "$HOME/x.sh" ] && [ "$(stat -c %a "$HOME/.bashrc")" = 640 ] &&
  [ "$(cat "$HOME/.bashrc")" = $'\''before\nafter'\'' ] || exit

  printf "%s\n%s\n%s\n" "# ==== END TERNUX ALIASES ====" keep "# ==== TERNUX ALIASES ====" > "$HOME/.zshrc"
  printf "%s\n" managed-elsewhere > "$HOME/bashrc-target"
  rm -f "$HOME/.bashrc"; ln -s "$HOME/bashrc-target" "$HOME/.bashrc"
  before_zsh="$(sha256sum "$HOME/.zshrc")"
  before_target="$(sha256sum "$HOME/bashrc-target")"
  set +e; tnx_cmd_uninstall launcher >/dev/null; rc=$?; set -e
  [ "$rc" -ne 0 ] && [ -L "$HOME/.bashrc" ] &&
  [ "$(sha256sum "$HOME/.zshrc")" = "$before_zsh" ] &&
  [ "$(sha256sum "$HOME/bashrc-target")" = "$before_target" ] &&
  ! compgen -G "$HOME/.zshrc.ternux-uninstall.*" >/dev/null
' _ "$ROOT"; then
  ok "scoped alias uninstall is atomic and preserves malformed files"
else
  not_ok "scoped alias uninstall is atomic and preserves malformed files"
fi

# The published standalone route must fetch and syntax-check the same scoped
# implementation when neither a CLI nor a local checkout is available. Use a
# mock downloader and temporary home; the state scope is non-destructive.
if env HOME="$TMP/home-uninstall-remote" PREFIX="$TMP/empty-prefix" \
       TERNUX_HOST_PREFIX="$TMP/empty-prefix" \
       MOCK_REPO="$ROOT" MOCK_LOG="$TMP/remote-downloads" bash -c '
  set -e
  mkdir -p "$HOME" "$2/mockbin" "$PREFIX/bin" "$2/standalone"
  cp "$1/uninstall.sh" "$2/standalone/uninstall.sh"
  cat > "$2/mockbin/curl" <<"EOF"
#!/usr/bin/env bash
set -e
url=""; dest=""
while [ $# -gt 0 ]; do
  case "$1" in
    -o) dest="$2"; shift 2 ;;
    http*) url="$1"; shift ;;
    *) shift ;;
  esac
done
case "$url" in
  */lib/core.sh) src="$MOCK_REPO/lib/core.sh" ;;
  */lib/uninstall.sh) src="$MOCK_REPO/lib/uninstall.sh" ;;
  *) exit 22 ;;
esac
printf "%s\n" "$url" >> "$MOCK_LOG"
cp "$src" "$dest"
EOF
  chmod +x "$2/mockbin/curl"
  PATH="$2/mockbin:$PATH" bash "$2/standalone/uninstall.sh" state --yes >/dev/null
  [ "$(wc -l < "$MOCK_LOG")" -eq 2 ] &&
  grep -q "/lib/core.sh$" "$MOCK_LOG" && grep -q "/lib/uninstall.sh$" "$MOCK_LOG" &&
  grep -q "pkill -KILL -x pulseaudio" "$1/lib/uninstall.sh" &&
  ! grep -q "pkill.*dbus" "$1/lib/uninstall.sh"
' _ "$ROOT" "$TMP"; then
  ok "standalone uninstall loads the scoped implementation safely"
else
  not_ok "standalone uninstall loads the scoped implementation safely"
fi

# Public structured-output paths must emit exactly one parseable object and
# canonicalize legacy backend state. This is an executable parse probe, not a
# grep for JSON-looking text.
if env TERNUX_STATE_DIR="$TMP/state-json" HOME="$TMP/home-json" bash -c '
  mkdir -p "$HOME" "$TERNUX_STATE_DIR"
  printf "backend=zink-turnip\n" > "$TERNUX_STATE_DIR/state"
  for cmd in info backend state profile verify; do
    out="$(bash "$1/bin/ternux" "$cmd" --json 2>/dev/null)" || [ "$cmd" = verify ] || exit
    CMD="$cmd" JSON_OUT="$out" python3 -c '\''
import json, os
raw=os.environ["JSON_OUT"]
dec=json.JSONDecoder()
obj,end=dec.raw_decode(raw)
assert not raw[end:].strip(), "trailing non-JSON output"
assert obj["command"] == os.environ["CMD"]
for key in ("status", "timestamp", "version"):
    assert key in obj
if "backend" in obj:
    assert obj["backend"] != "zink-turnip"
'\'' || exit
  done
  out="$(bash "$1/bin/ternux" verify --json 2>/dev/null)"; rc=$?
  [ "$rc" -ne 0 ] && JSON_OUT="$out" python3 -c '\''
import json, os
obj=json.loads(os.environ["JSON_OUT"])
assert obj["command"] == "verify"
assert obj["status"] == "failed"
'\''
' _ "$ROOT"; then
  ok "documented JSON paths are clean, parseable and canonical"
else
  not_ok "documented JSON paths are clean, parseable and canonical"
fi

# Verification must fail—not merely warn—when Debian is absent or when its
# desktop-service/passwordless-sudo probe fails. Both paths must still emit one
# valid structured object.
if env TERNUX_STATE_DIR="$TMP/state-verify-failures" HOME="$TMP/home-verify-failures" \
  TERNUX_KGSL_DEVICE="$TMP/absent-kgsl" PREFIX="$TMP/empty-prefix-verify" bash -c '
  mkdir -p "$HOME" "$TERNUX_STATE_DIR"
  : > "$HOME/x.sh"; chmod +x "$HOME/x.sh"
  . "$1/lib/doctor.sh"
  tnx_has_cmd(){ return 0; }
  tnx_state_get(){ [ "$1" = backend ] && echo virgl; }
  for mode in absent services; do
    proot-distro(){
      if [ "$1" = list ]; then
        [ "$mode" = services ] && echo "debian installed"
        return 0
      fi
      return 1
    }
    TERNUX_JSON=1
    set +e; out="$(tnx_cmd_verify 2>/dev/null)"; rc=$?; set -e
    [ "$rc" -eq 1 ] || exit
    MODE="$mode" JSON_OUT="$out" python3 -c '\''
import json, os
obj=json.loads(os.environ["JSON_OUT"])
assert obj["command"] == "verify" and obj["status"] == "failed"
needle = "debian:not_installed" if os.environ["MODE"] == "absent" else "debian_services:failed"
assert needle in obj["checks"].split(",")
'\'' || exit
  done
' _ "$ROOT"; then
  ok "verification failures return nonzero structured results"
else
  not_ok "verification failures return nonzero structured results"
fi

# Pulse setup covers a fresh file, exact legacy migration, idempotence, custom
# listener refusal (even beside a secure line), and atomic write failure.
if env TERNUX_STATE_DIR="$TMP/state-pulse" HOME="$TMP/home-pulse" bash -c '
  mkdir -p "$HOME"
  . "$1/lib/phases.sh"
  old="load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 port=4713"
  new="load-module module-native-protocol-tcp listen=127.0.0.1 auth-ip-acl=127.0.0.1 auth-anonymous=1 port=4713"
  fresh="$2/fresh.pa"; newfile="$2/new.pa"; legacy="$2/legacy.pa"
  custom="$2/custom.pa"; failed="$2/failed.pa"; target="$2/target.pa"; link="$2/link.pa"

  : > "$fresh"; chmod 640 "$fresh"
  _tnx_configure_pulse_bridge "$fresh" >/dev/null && [ "$_TNX_PULSE_CHANGED" = 1 ] || exit
  [ "$(stat -c %a "$fresh")" = 640 ] &&
  [ "$(grep -cxF "$new" "$fresh")" -eq 1 ] &&
  grep -qxF "load-module module-opensles-sink sink_name=Speaker" "$fresh" &&
  grep -qxF "load-module module-sles-source source_name=Ternux_Microphone" "$fresh" &&
  grep -qxF "set-default-sink Speaker" "$fresh" || exit

  _tnx_configure_pulse_bridge "$newfile" >/dev/null &&
  [ "$_TNX_PULSE_CHANGED" = 1 ] && [ "$(stat -c %a "$newfile")" = 600 ] || exit
  before="$(sha256sum "$fresh")"
  _tnx_configure_pulse_bridge "$fresh" >/dev/null && [ "$_TNX_PULSE_CHANGED" = 0 ] &&
  [ "$(sha256sum "$fresh")" = "$before" ] || exit

  printf "%s\n%s\n" "$old" "$old" > "$legacy"
  _tnx_configure_pulse_bridge "$legacy" >/dev/null && [ "$_TNX_PULSE_CHANGED" = 1 ] &&
  [ "$(grep -cxF "$new" "$legacy")" -eq 1 ] && ! grep -qxF "$old" "$legacy" || exit

  printf "%s\n%s\n" "$new" "  load-module module-native-protocol-tcp listen=0.0.0.0 port=4713" > "$custom"
  before="$(cat "$custom")"
  set +e; _tnx_configure_pulse_bridge "$custom" >/dev/null; rc=$?; set -e
  [ "$rc" -ne 0 ] && [ "$(cat "$custom")" = "$before" ] || exit

  printf "%s\n" untouched > "$target"; ln -s "$target" "$link"
  set +e; _tnx_configure_pulse_bridge "$link" >/dev/null; rc=$?; set -e
  [ "$rc" -ne 0 ] && [ "$(cat "$target")" = untouched ] || exit

  printf "%s\n" "$old" > "$failed"; before="$(cat "$failed")"
  mv(){ return 1; }
  set +e; _tnx_configure_pulse_bridge "$failed" >/dev/null; rc=$?; set -e
  [ "$rc" -ne 0 ] && [ "$(cat "$failed")" = "$before" ] &&
  ! compgen -G "${failed}.ternux.*" >/dev/null
' _ "$ROOT" "$TMP"; then
  ok "Pulse bridge setup is secure, idempotent, guarded and atomic"
else
  not_ok "Pulse bridge setup is secure, idempotent, guarded and atomic"
fi

# CLI session cleanup must not kill unrelated D-Bus or broad PulseAudio process
# matches. If graceful PulseAudio shutdown fails, only the exact process name is
# forced, and all managed socket forms are covered.
if env TERNUX_STATE_DIR="$TMP/state-desktop-stop" HOME="$TMP/home-desktop-stop" \
  TMPDIR="$TMP/desktop-stop-tmp" bash -c '
    mkdir -p "$HOME" "$TMPDIR/.X11-unix" "$TMPDIR/.pulse-test"
    : > "$TMPDIR/.X11-unix/X0"; : > "$TMPDIR/.X0-lock"; : > "$TMPDIR/.pulse-test/native"
    log="$2/desktop-stop.log"
    . "$1/lib/desktop.sh"
    pgrep(){ return 0; }
    pkill(){ printf "pkill %s\n" "$*" >> "$log"; }
    pulseaudio(){ printf "pulseaudio %s\n" "$*" >> "$log"; return 1; }
    ps(){ printf "9709 /data/data/com.termux/files/usr/bin/pulseaudio --file /home/ternux/.local/share/ternuxx/audio/default.pa\n"; }
    kill(){ printf "kill %s\n" "$*" >> "$log"; }
    tnx_has_cmd(){ [ "$1" = proot-distro ]; }
    tnx_guest_login(){ printf "guest %s\n" "$*" >> "$log"; }
    TERNUX_JSON=1
    out="$(tnx_cmd_stop)" || exit
    JSON_OUT="$out" python3 -c '\''
import json, os
obj=json.loads(os.environ["JSON_OUT"])
assert obj["command"] == "stop" and obj["status"] == "ok"
'\'' &&
    grep -qx "guest --user root -- pkill -TERM -x xfce4-session" "$log" &&
    grep -q "ibus-daemon" "$1/lib/desktop.sh" &&
    grep -q "ibus-extension-gtk3" "$1/lib/desktop.sh" &&
    grep -qx "kill -TERM 9709" "$log" &&
    grep -qx "pulseaudio --kill" "$log" &&
    grep -qx "pkill -KILL -x pulseaudio" "$log" &&
    ! grep -qi dbus "$log" &&
    ! grep -q "pkill .*pulseaudio.*-f\|-f .*pulseaudio" "$log" &&
    [ ! -e "$TMPDIR/.X11-unix/X0" ] && [ ! -e "$TMPDIR/.X0-lock" ] &&
    [ ! -e "$TMPDIR/.pulse-test/native" ]
  ' _ "$ROOT" "$TMP"; then
  ok "desktop stop uses scoped process and socket cleanup"
else
  not_ok "desktop stop uses scoped process and socket cleanup"
fi

# Desktop detection must match Android's actual truncated Termux:X11 process
# name, not any command line containing a display-related search term.
if env TERNUX_STATE_DIR="$TMP/state-desktop-detect" HOME="$TMP/home-desktop-detect" bash -c '
    . "$1/lib/desktop.sh"
    pgrep(){
      if [ "$1" = "-f" ]; then
        case "$2" in
          ^termux-x11*) return 1 ;;
          *) return 0 ;;
        esac
      fi
      return 1
      return 1
    }
    TERNUX_JSON=1
    out="$(tnx_cmd_status)" || exit
    JSON_OUT="$out" python3 -c "import json,os; d=json.loads(os.environ[\"JSON_OUT\"]); assert d[\"status\"]==\"stopped\" and d[\"x11_running\"]==\"no\""
  ' _ "$ROOT"; then
  ok "desktop status ignores process-name false positives"
else
  not_ok "desktop status ignores process-name false positives"
fi

# Starting a managed desktop must start a new session detached from the caller, persist its PID, and
# route verbose output to a bounded session log. Stop must signal that PID.
managed_launcher="$TMP/managed-launcher.sh"
cat > "$managed_launcher" <<'LAUNCHER'
#!/usr/bin/env bash
mkdir -p "$TMPDIR/.X11-unix"
echo session-started
: > "$TMPDIR/.X11-unix/X0"
trap 'rm -f "$TMPDIR/.X11-unix/X0"; exit 0' TERM EXIT
while :; do sleep 1; done
LAUNCHER
if env TERNUX_STATE_DIR="$TMP/state-desktop-start" HOME="$TMP/home-desktop-start" \
  TMPDIR="$TMP/desktop-start-tmp" bash -c '
    mkdir -p "$HOME"
    cp "$2" "$HOME/legacy-x.sh"
    printf "#!/usr/bin/env bash\n# legacy\n" > "$HOME/x.sh"
    MOCK_LAUNCHER="$2"
    . "$1/lib/desktop.sh"
    tnx_canonical_backend(){ echo virgl; }
    tnx_state_get(){ case "$1" in backend) echo virgl;; user) echo alice;; locale) echo en_US.UTF-8;; esac; }
    tnx_phase_launcher(){
      cp "$MOCK_LAUNCHER" "$HOME/x.sh"
      sed -i "1a# TERNUX_DESKTOP_LAUNCHER=12" "$HOME/x.sh"
      chmod +x "$HOME/x.sh"
    }
    tnx_has_cmd(){ [ "$1" = setsid ]; }
    setsid(){ command setsid "$@"; }
    pgrep(){ return 1; }
    start_at=$SECONDS
    tnx_cmd_start >/dev/null || exit
    [ "$((SECONDS-start_at))" -le 5 ] || exit
    pid="$(cat "$TERNUX_STATE_DIR/session/desktop.pid")"
    [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null || exit
    grep -q session-started "$TERNUX_STATE_DIR/session/desktop.log" || exit
    grep -q "^# TERNUX_DESKTOP_LAUNCHER=12$" "$HOME/x.sh" || exit
    grep -q "util-linux zsh git curl" "$1/lib/phases.sh" || exit
    tnx_cmd_stop >/dev/null || exit
    [ ! -e "$TERNUX_STATE_DIR/session/desktop.pid" ]
  ' _ "$ROOT" "$managed_launcher"; then
  ok "desktop start detaches with session PID/log and stop cleans it"
else
  not_ok "desktop start detaches with session PID/log and stop cleans it"
fi

# Vulkan detection must not turn a missing glob into a false positive.
if env TERNUX_STATE_DIR="$TMP/state-vulkan" HOME="$TMP/home-vulkan" \
  PREFIX="$TMP/empty-prefix" TERNUX_KGSL_DEVICE="$TMP/absent-kgsl" bash -c '
    mkdir -p "$PREFIX/lib"
    . "$1/lib/detect.sh"
    tnx_has_cmd(){ return 1; }
    [ "$(tnx_detect_vulkan)" = no ]
  ' _ "$ROOT"; then
  ok "Vulkan detection does not accept a missing library glob"
else
  not_ok "Vulkan detection does not accept a missing library glob"
fi

# The standalone one-click path downloads one complete snapshot, retries a
# transient transfer, and reuses the extracted files instead of fetching raw
# modules independently.
bundle_tree="$TMP/source-bundle/ternux-main"
mkdir -p "$bundle_tree"
cp -R "$ROOT/bin" "$ROOT/lib" "$bundle_tree/"
tar -czf "$TMP/source-bundle.tar.gz" -C "$TMP/source-bundle" ternux-main
mkdir -p "$TMP/standalone-bundle" "$TMP/mock-bundle-bin" "$TMP/remote-bundle-tmp"
cp "$ROOT/install.sh" "$TMP/standalone-bundle/install.sh"
cat > "$TMP/mock-bundle-bin/curl" <<'EOF'
#!/usr/bin/env bash
set -u
url=""; dest=""
while [ $# -gt 0 ]; do
  case "$1" in
    -o) dest="$2"; shift 2 ;;
    http*) url="$1"; shift ;;
    *) shift ;;
  esac
done
count=0
[ ! -f "$MOCK_COUNT" ] || count="$(cat "$MOCK_COUNT")"
count=$((count + 1)); printf '%s\n' "$count" > "$MOCK_COUNT"
printf '%s\n' "$url" >> "$MOCK_URLS"
[ "$count" -gt 1 ] || exit 22
cp "$MOCK_ARCHIVE" "$dest"
EOF
cat > "$TMP/mock-bundle-bin/sleep" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$TMP/mock-bundle-bin/curl" "$TMP/mock-bundle-bin/sleep"
if env HOME="$TMP/home-standalone-bundle" PREFIX="$TMP/prefix-standalone-bundle" \
  TMPDIR="$TMP/remote-bundle-tmp" MOCK_ARCHIVE="$TMP/source-bundle.tar.gz" \
  MOCK_COUNT="$TMP/bundle-count" MOCK_URLS="$TMP/bundle-urls" \
  PATH="$TMP/mock-bundle-bin:$PATH" \
  bash "$TMP/standalone-bundle/install.sh" --status >/dev/null &&
  [ "$(cat "$TMP/bundle-count")" -eq 2 ] &&
  [ "$(sort -u "$TMP/bundle-urls" | wc -l)" -eq 1 ] &&
  grep -q '^https://codeload.github.com/soobujmiah/ternux/tar.gz/refs/heads/main$' "$TMP/bundle-urls" &&
  ! compgen -G "$TMP/remote-bundle-tmp/ternux-bootstrap.*" >/dev/null; then
  ok "standalone bootstrap retries and reuses one source bundle"
else
  not_ok "standalone bootstrap retries and reuses one source bundle"
fi

# The host CLI installer must prove that the exact PREFIX command can load the
# flat installed module directory; merely creating an executable is not enough.
if env TERNUX_STATE_DIR="$TMP/state-cli-layout" HOME="$TMP/home-cli-layout" \
  PREFIX="$TMP/prefix-cli-layout" bash -c '
    mkdir -p "$HOME"
    . "$1/lib/phases.sh"
    dpkg-query(){ return 1; }
    tnx_phase_cli >/dev/null &&
    [ -x "$PREFIX/bin/ternux" ] &&
    [ -f "$PREFIX/lib/ternux/core.sh" ] &&
    "$PREFIX/bin/ternux" --version | grep -q "^ternux v"
  ' _ "$ROOT"; then
  ok "CLI phase executes the installed flat-module layout"
else
  not_ok "CLI phase executes the installed flat-module layout"
fi

# A stale executable response must not pass merely because the host path exists.
if env TERNUX_STATE_DIR="$TMP/state-cli-stale" HOME="$TMP/home-cli-stale" \
  PREFIX="$TMP/prefix-cli-stale" bash -c '
    mkdir -p "$HOME"
    . "$1/lib/phases.sh"
    dpkg-query(){ return 1; }
    install(){
      local dest="${!#}"
      if [ "$dest" = "$PREFIX/bin/ternux" ]; then
        cat > "$dest" <<MOCK
#!/usr/bin/env bash
printf "ternux v${TERNUX_VERSION}0\n"
MOCK
        chmod 0755 "$dest"
      else
        command install "$@"
      fi
    }
    set +e; tnx_phase_cli >/dev/null 2>&1; rc=$?; set -e
    [ "$rc" -ne 0 ] && [ -x "$PREFIX/bin/ternux" ] &&
      [ "$(tnx_state_get cli_installed 2>/dev/null || true)" != yes ]
  ' _ "$ROOT"; then
  ok "CLI phase rejects an executable with a stale version response"
else
  not_ok "CLI phase rejects an executable with a stale version response"
fi

# The Debian entry point is a guest-aware companion, not a nested invocation of
# the Android lifecycle CLI. Load phases from an isolated installed-style module
# directory to prove _TNX_SRC supplies the guest file without another request.
mkdir -p "$TMP/guest-modules"
cp "$ROOT/lib/core.sh" "$ROOT/lib/phases.sh" "$TMP/guest-modules/"
if env TERNUX_STATE_DIR="$TMP/state-guest-cli" HOME="$TMP/home-guest-cli" \
  MOCK_GUEST="$TMP/mock-guest-cli" DOWNLOAD_MARKER="$TMP/guest-download-called" bash -c '
    mkdir -p "$HOME"
    . "$2/phases.sh"
    _TNX_SRC="$1"
    tnx_download(){ : > "$DOWNLOAD_MARKER"; return 1; }
    proot-distro(){
      if [[ "$*" == *"bash -c"* ]]; then
        cat > "$MOCK_GUEST"; chmod +x "$MOCK_GUEST"
      else
        "$MOCK_GUEST" --version
      fi
    }
    tnx_install_guest_cli alice >/dev/null &&
    "$MOCK_GUEST" --version | grep -q "ternux guest v" &&
    set +e; "$MOCK_GUEST" start >/dev/null 2>&1; rc=$?; set -e
    [ "$rc" -eq 64 ] && [ "$(tnx_state_get guest_cli_installed)" = yes ] &&
      [ ! -e "$DOWNLOAD_MARKER" ]
  ' _ "$ROOT" "$TMP/guest-modules"; then
  ok "Debian companion reuses the bootstrap snapshot and rejects nested host lifecycle"
else
  not_ok "Debian companion reuses the bootstrap snapshot and rejects nested host lifecycle"
fi

# Writing the guest file is insufficient when the command resolves to a stale
# or otherwise unexpected companion version.
if env TERNUX_STATE_DIR="$TMP/state-guest-stale" HOME="$TMP/home-guest-stale" \
  MOCK_GUEST="$TMP/mock-guest-stale" bash -c '
    mkdir -p "$HOME"
    . "$1/lib/phases.sh"
    proot-distro(){
      if [[ "$*" == *"bash -c"* ]]; then
        cat > "$MOCK_GUEST"; chmod +x "$MOCK_GUEST"
      else
        printf "ternux guest v%s0\n" "$TERNUX_VERSION"
      fi
    }
    set +e; tnx_install_guest_cli alice >/dev/null 2>&1; rc=$?; set -e
    [ "$rc" -ne 0 ] && [ -x "$MOCK_GUEST" ] &&
      [ "$(tnx_state_get guest_cli_installed 2>/dev/null || true)" != yes ]
  ' _ "$ROOT"; then
  ok "Debian companion installation rejects a stale version response"
else
  not_ok "Debian companion installation rejects a stale version response"
fi

# Reduced-capability terminals receive the same persistent identity, storage
# guidance and line-at-a-time log feed without cursor-control dependencies.
frame_out="$TMP/frame-output"
if env TERM=dumb NO_COLOR=1 TERNUX_STATE_DIR="$TMP/state-frame" \
  TERNUX_LOG_DIR="$TMP/log-frame" HOME="$TMP/home-frame" bash -c '
    mkdir -p "$HOME"
    . "$1/lib/ui.sh"
    tnx_frame_open 2 virgl ternux base
    tnx_frame_phase 1 2 "Core package installation"
    printf "Get: package-one\nSetting up package-one\nERROR: sample failure\n" | tnx_frame_stream
    tnx_frame_close failed
  ' _ "$ROOT" > "$frame_out" &&
  grep -q "Sobuj Miah" "$frame_out" &&
  grep -q "base ~4-4.5 GB" "$frame_out" &&
  grep -q "complete ~10.5-12.5 GB" "$frame_out" &&
  grep -q "Get: package-one" "$frame_out" &&
  grep -q "ERROR: sample failure" "$TMP/log-frame/ternux.log"; then
  ok "persistent install frame has a readable line-stream fallback"
else
  not_ok "persistent install frame has a readable line-stream fallback"
fi

# Closing a failed dashboard must retain the reported failure's phase index;
# only a successful close is allowed to advance the counter to the total.
failed_frame_out="$(env NO_COLOR=1 TERNUX_STATE_DIR="$TMP/state-frame-failed" \
  TERNUX_LOG_DIR="$TMP/log-frame-failed" HOME="$TMP/home-frame-failed" bash -c '
    mkdir -p "$HOME"
    . "$1/lib/ui.sh"
    _TNX_FRAME_MODE=dashboard
    _TNX_FRAME_ACTIVE=1
    _TNX_FRAME_CUR=4
    _TNX_FRAME_TOTAL=11
    _TNX_FRAME_ROWS=24
    _TNX_FRAME_TITLE="Debian container + Xfce4"
    _tnx_frame_draw_dashboard(){
      printf "%s|%s|%s|%s\n" "$1" "$_TNX_FRAME_CUR" "$_TNX_FRAME_TOTAL" "$_TNX_FRAME_TITLE"
    }
    tnx_frame_restore_terminal(){ :; }
    tnx_frame_close failed 4 "Debian container + Xfce4"
  ' _ "$ROOT")"
if printf '%s\n' "$failed_frame_out" | grep -q '^FAILED|4|11|Failed: Debian container + Xfce4$' &&
   ! printf '%s\n' "$failed_frame_out" | grep -q '^FAILED|11|11|'; then
  ok "failed dashboard retains the actual failed phase index"
else
  not_ok "failed dashboard retains the actual failed phase index"
fi

# Storage copy must distinguish installed size from temporary free-space
# headroom and must not restore the old 12 GB base-install claim.
if grep -q "base desktop ~4–4.5 GB; complete --all profile ~10.5–12.5 GB" "$ROOT/lib/phases.sh" &&
   ! grep -q "base install wants ~12 GB" "$ROOT/lib/phases.sh"; then
  ok "preflight reports corrected base and complete storage estimates"
else
  not_ok "preflight reports corrected base and complete storage estimates"
fi

# The public bootstrap must preserve literal --all so the installer selects the
# full profile instead of reducing it to a custom list of individual extras.
mock_boot="$TMP/mock-bootstrap"
mkdir -p "$mock_boot/lib"
cp "$ROOT/install.sh" "$mock_boot/install.sh"
cat > "$mock_boot/lib/core.sh" <<'EOF'
TERNUX_VERSION=1.3.0
tnx_info(){ :; }; tnx_ok(){ :; }; tnx_warn(){ :; }; tnx_fail(){ :; }
tnx_step(){ :; }; tnx_confirm(){ :; }; tnx_debug(){ :; }
tnx_state_done(){ return 1; }; tnx_state_mark(){ :; }; tnx_state_clear(){ :; }
tnx_require_termux(){ :; }
EOF
cat > "$mock_boot/lib/phases.sh" <<'EOF'
tnx_install(){ printf 'ARG=[%s]\n' "$@"; }
EOF
: > "$mock_boot/lib/ui.sh"
boot_out="$(bash "$mock_boot/install.sh" --yes --all)"
resume_boot_out="$(bash "$mock_boot/install.sh" --yes --resume)"
if [ "$(printf '%s\n' "$boot_out" | grep -cxF 'ARG=[--all]')" -eq 1 ] &&
   ! printf '%s\n' "$boot_out" | grep -q 'ARG=\[--with-' &&
   [ "$(printf '%s\n' "$resume_boot_out" | grep -cxF 'ARG=[--resume]')" -eq 1 ] &&
   ! printf '%s\n' "$resume_boot_out" | grep -Eq 'ARG=\[--(user|locale|backend)\]'; then
  ok "bootstrap preserves --all and leaves bare resume choices implicit"
else
  not_ok "bootstrap preserves --all and leaves bare resume choices implicit"
fi

# A bare resume restores the interrupted run's optional workload set instead of
# silently reducing a full installation to the base profile.
if env TERNUX_STATE_DIR="$TMP/state-resume-profile" HOME="$TMP/home-resume-profile" \
  PREFIX="$TMP/prefix-resume-profile" TERNUX_QUIET=1 bash -c '
    mkdir -p "$HOME"
    . "$1/lib/phases.sh"
    tnx_state_set user alice
    tnx_state_set locale bn_BD.UTF-8
    tnx_state_set install_backend virgl
    tnx_state_set install_shell zsh
    tnx_state_set install_profile full
    tnx_state_set install_extras dev,llm,network,media,blender
    tnx_require_termux(){ :; }
    tnx_confirm(){ return 0; }
    _tnx_execute_install_phase(){
      local phase="$1"; shift 5
      [ "$phase" != extras ] || printf "%s\n" "$*" > "$TERNUX_STATE_DIR/resumed-extras"
    }
    tnx_install --yes --resume >/dev/null &&
      [ "$(cat "$TERNUX_STATE_DIR/resumed-extras")" = "dev llm network media blender" ] &&
      [ "$(tnx_state_get user)" = alice ] &&
      [ "$(tnx_state_get locale)" = bn_BD.UTF-8 ] &&
      [ "$(tnx_state_get install_backend)" = virgl ] &&
      [ "$(tnx_state_get install_shell)" = zsh ] &&
      [ "$(tnx_state_get install_profile)" = full ]
  ' _ "$ROOT"; then
  ok "bare resume restores the saved full-profile workload set"
else
  not_ok "bare resume restores the saved full-profile workload set"
fi

# A forced update installs the same PREFIX/bin + PREFIX/lib/ternux structure as
# a fresh install and executes that installed dispatcher before recording state.
if env TERNUX_STATE_DIR="$TMP/state-update-layout" HOME="$TMP/home-update-layout" \
  PREFIX="$TMP/prefix-update-layout" TMPDIR="$TMP/tmp-update-layout" bash -c '
    mkdir -p "$HOME"
    . "$1/lib/core.sh"
    TNX_ROOT="$1"
    . "$1/lib/update.sh"
    dpkg-query(){ return 1; }
    git(){
      local dest="${!#}"
      mkdir -p "$dest"
      cp -R "$TNX_ROOT/bin" "$TNX_ROOT/lib" "$dest/"
      cp "$TNX_ROOT/install.sh" "$dest/install.sh"
    }
    tnx_has_cmd(){ [ "$1" != proot-distro ] && command -v "$1" >/dev/null 2>&1; }
    tnx_cmd_update >/dev/null &&
    [ -x "$PREFIX/bin/ternux" ] &&
    [ -f "$PREFIX/lib/ternux/core.sh" ] &&
    "$PREFIX/bin/ternux" --version | grep -q "^ternux v$TERNUX_VERSION" &&
    [ "$(tnx_state_get version)" = "$TERNUX_VERSION" ]
  ' _ "$ROOT"; then
  ok "updater installs and executes the PREFIX module layout"
else
  not_ok "updater installs and executes the PREFIX module layout"
fi

# Guest refresh remains best-effort, but a stale response must be reported as
# unverified rather than silently accepted by the updater.
if env TERNUX_STATE_DIR="$TMP/state-update-guest" HOME="$TMP/home-update-guest" \
  PREFIX="$TMP/prefix-update-guest" TMPDIR="$TMP/tmp-update-guest" \
  MOCK_GUEST="$TMP/mock-update-guest" WARN_FILE="$TMP/update-guest-warning" bash -c '
    mkdir -p "$HOME"
    . "$1/lib/core.sh"
    TNX_ROOT="$1"
    . "$1/lib/update.sh"
    dpkg-query(){ return 1; }
    git(){
      local dest="${!#}"
      mkdir -p "$dest"
      cp -R "$TNX_ROOT/bin" "$TNX_ROOT/lib" "$dest/"
      cp "$TNX_ROOT/install.sh" "$dest/install.sh"
    }
    tnx_has_cmd(){
      [ "$1" = proot-distro ] && return 0
      command -v "$1" >/dev/null 2>&1
    }
    proot-distro(){
      if [ "${1:-}" = list ]; then
        printf "debian installed\n"
      elif [[ "$*" == *"bash -c"* ]]; then
        cat > "$MOCK_GUEST"; chmod +x "$MOCK_GUEST"
      else
        printf "ternux guest v%s0\n" "$TERNUX_VERSION"
      fi
    }
    tnx_warn(){ printf "%s\n" "$1" >> "$WARN_FILE"; }
    tnx_cmd_update >/dev/null &&
      [ -x "$MOCK_GUEST" ] &&
      grep -q "could not be version-verified" "$WARN_FILE" &&
      [ "$(tnx_state_get version)" = "$TERNUX_VERSION" ]
  ' _ "$ROOT"; then
  ok "updater warns when the refreshed Debian companion version is stale"
else
  not_ok "updater warns when the refreshed Debian companion version is stale"
fi

# Optional llama.cpp builds are pinned and isolated from an existing checkout.
check "optional llama workload pins a safe llama.cpp revision" bash -c '
  grep -Fq "llama.cpp-b11582" "$1/lib/phases.sh" &&
  grep -Fq "af50f2f248b475d9760f8e67503d01c0f194f5f4" "$1/lib/phases.sh" &&
  grep -Fq "Refusing to modify existing non-pinned source" "$1/lib/phases.sh" &&
  ! grep -Fq "rm -rf ~/llama.cpp" "$1/lib/phases.sh"
' _ "$ROOT"

if env TERNUX_STATE_DIR="$TMP/state-blender-xvfb" HOME="$TMP/home-blender-xvfb" \
  MARKER="$TMP/blender-xvfb-command" bash -c '
    . "$1/lib/phases.sh"
    tnx_guest_login(){ printf "%s\n" "$*" > "$MARKER"; }
    tnx_ok(){ :; }
    tnx_warn(){ :; }
    tnx_phase_extras ternux blender && grep -Eq "apt install .*blender xvfb" "$MARKER"
  ' _ "$ROOT"; then
  ok "Blender workload installs Xvfb for headless GPU rendering"
else
  not_ok "Blender workload installs Xvfb for headless GPU rendering"
fi

# The Termux host frontend streams the installer into the selected Debian guest.
EXT_HOST_BIN="$TMP/extension-host-bin"
mkdir -p "$EXT_HOST_BIN"
cat > "$EXT_HOST_BIN/getconf" <<'EOF'
#!/bin/sh
exit 1
EOF
cat > "$EXT_HOST_BIN/proot-distro" <<'EOF'
#!/bin/sh
while [ "$#" -gt 0 ] && [ "$1" != -- ]; do shift; done
[ "${1:-}" = -- ] && shift
exec "$@"
EOF
chmod 0755 "$EXT_HOST_BIN/getconf" "$EXT_HOST_BIN/proot-distro"
if env HOME="$TMP/ext-host-home" PATH="$EXT_HOST_BIN:$PATH" \
  TERNUX_STATE_DIR="$TMP/ext-host-state" bash -c '
    . "$1/lib/core.sh"
    . "$1/lib/extension.sh"
    tnx_state_set user sbj
    tnx_state_set distro debian
    tnx_cmd_extension list
  ' _ "$ROOT" | grep -q 'llama-vulkan.*Linux ARM64' &&
  env HOME="$TMP/ext-host-home-htp" PATH="$EXT_HOST_BIN:$PATH" \
    TERNUX_STATE_DIR="$TMP/ext-host-state-htp" bash -c '
      . "$1/lib/core.sh"; . "$1/lib/extension.sh"
      tnx_state_set user sbj; tnx_state_set distro debian
      tnx_cmd_extension list
    ' _ "$ROOT" | grep -q 'llama-htp-experimental.*experimental'; then
  ok "host extension command delegates its menu into the selected guest"
else
  not_ok "host extension command delegates its menu into the selected guest"
fi

# Release extensions install from checksummed, path-validated archives and do
# not mutate an existing destination on failure.
EXT_TAG=ternux-llama-vulkan-linux-arm64-b11582
HTP_TAG=ternux-llama-htp-sm8735-b11582
EXT_FIXTURE="$TMP/extension-fixture"
EXT_BIN="$TMP/extension-bin"
mkdir -p "$EXT_FIXTURE/$EXT_TAG/bin" "$EXT_FIXTURE/$HTP_TAG/bin" \
  "$EXT_FIXTURE/$HTP_TAG/libexec" "$EXT_FIXTURE/$HTP_TAG/lib" "$EXT_BIN"
printf '#!/bin/sh\necho llama.cpp b11582\n' > "$EXT_FIXTURE/$EXT_TAG/bin/llama-cli"
chmod 0755 "$EXT_FIXTURE/$EXT_TAG/bin/llama-cli"
printf 'LLAMA_HOME=fixture\n' > "$EXT_FIXTURE/$EXT_TAG/env.sh"
printf '{"artifact": "ternux-llama-vulkan-linux-arm64-b11582"}\n' > "$EXT_FIXTURE/$EXT_TAG/build-manifest.json"
tar -czf "$EXT_FIXTURE/$EXT_TAG.tar.gz" -C "$EXT_FIXTURE" "$EXT_TAG"
(cd "$EXT_FIXTURE" && sha256sum "$EXT_TAG.tar.gz" > "$EXT_TAG.tar.gz.sha256")
printf '#!/bin/sh\necho llama.cpp b11582\n' > "$EXT_FIXTURE/$HTP_TAG/bin/llama-cli"
chmod 0755 "$EXT_FIXTURE/$HTP_TAG/bin/llama-cli"
printf '#!/bin/sh\nexit 0\n' > "$EXT_FIXTURE/$HTP_TAG/bin/htp-run"
chmod 0755 "$EXT_FIXTURE/$HTP_TAG/bin/htp-run"
printf '#!/usr/bin/env python3\n' > "$EXT_FIXTURE/$HTP_TAG/libexec/htp-broker.py"
: > "$EXT_FIXTURE/$HTP_TAG/lib/libternux-htp-broker.so"
printf '{"artifact": "ternux-llama-htp-sm8735-b11582"}\n' > "$EXT_FIXTURE/$HTP_TAG/build-manifest.json"
tar -czf "$EXT_FIXTURE/$HTP_TAG.tar.gz" -C "$EXT_FIXTURE" "$HTP_TAG"
(cd "$EXT_FIXTURE" && sha256sum "$HTP_TAG.tar.gz" > "$HTP_TAG.tar.gz.sha256")
cat > "$EXT_BIN/uname" <<'EOF'
#!/bin/sh
case "${1:-}" in -s) echo Linux ;; -m) echo aarch64 ;; *) exit 1 ;; esac
EOF
cat > "$EXT_BIN/getconf" <<'EOF'
#!/bin/sh
echo "glibc ${EXT_GLIBC_VERSION:-2.38}"
EOF
cat > "$EXT_BIN/curl" <<'EOF'
#!/bin/sh
out= url=
while [ "$#" -gt 0 ]; do
  if [ "$1" = -o ]; then shift; out="$1"; else url="$1"; fi
  shift
done
printf '%s\n' "$url" >> "$EXT_CURL_LOG"
cp "$EXT_FIXTURE/${url##*/}" "$out"
EOF
cat > "$EXT_BIN/ldconfig" <<'EOF'
#!/bin/sh
for library in libssl.so.3 libcrypto.so.3 libgomp.so.1 libvulkan.so.1 libgbinder.so.1 libglibutil.so.1 libcdsprpc.so.1 libcdsprpc.so; do
  [ "$library" = "${EXT_MISSING_LIBRARY:-}" ] || printf '%s (libc6,AArch64) => /usr/lib/%s\n' "$library" "$library"
done
EOF
chmod 0755 "$EXT_BIN/uname" "$EXT_BIN/getconf" "$EXT_BIN/curl" "$EXT_BIN/ldconfig"
if ! env HOME="$TMP/ext-home-old-glibc" EXT_GLIBC_VERSION=2.37 \
  EXT_CURL_LOG="$TMP/ext-old-glibc-downloads" EXT_FIXTURE="$EXT_FIXTURE" \
  PATH="$EXT_BIN:$PATH" TERNUX_STATE_DIR="$TMP/ext-state-old-glibc" \
  bash "$ROOT/bin/ternux" extension install llama-vulkan >/dev/null 2>&1 &&
  [ ! -e "$TMP/ext-home-old-glibc/.local/opt/ternux-extensions" ] &&
  [ ! -e "$TMP/ext-old-glibc-downloads" ]; then
  ok "extension installer rejects glibc below the package ABI baseline before download"
else
  not_ok "extension installer rejects glibc below the package ABI baseline before download"
fi
if ! env HOME="$TMP/ext-home-missing-runtime" EXT_MISSING_LIBRARY=libgomp.so.1 \
  EXT_CURL_LOG="$TMP/ext-missing-runtime-downloads" EXT_FIXTURE="$EXT_FIXTURE" \
  PATH="$EXT_BIN:$PATH" TERNUX_STATE_DIR="$TMP/ext-state-missing-runtime" \
  bash "$ROOT/bin/ternux" extension install llama-vulkan >/dev/null 2>&1 &&
  [ ! -e "$TMP/ext-home-missing-runtime/.local/opt/ternux-extensions" ] &&
  [ ! -e "$TMP/ext-missing-runtime-downloads" ]; then
  ok "extension installer reports missing runtime libraries before download"
else
  not_ok "extension installer reports missing runtime libraries before download"
fi
if env HOME="$TMP/ext-home-ok" EXT_GLIBC_VERSION=2.38 EXT_CURL_LOG="$TMP/ext-downloads" \
  EXT_FIXTURE="$EXT_FIXTURE" PATH="$EXT_BIN:$PATH" \
  TERNUX_STATE_DIR="$TMP/ext-state-ok" bash "$ROOT/bin/ternux" extension install llama-vulkan >/dev/null 2>&1 &&
  [ -x "$TMP/ext-home-ok/.local/opt/ternux-extensions/llama-vulkan/bin/llama-cli" ] &&
  [ -f "$TMP/ext-home-ok/.local/opt/ternux-extensions/llama-vulkan/env.sh" ] &&
  grep -Fq '"artifact": "ternux-llama-vulkan-linux-arm64-b11582"' \
    "$TMP/ext-home-ok/.local/opt/ternux-extensions/llama-vulkan/build-manifest.json"; then
  ok "extension installer verifies and atomically installs the selected release"
else
  not_ok "extension installer verifies and atomically installs the selected release"
fi
if ! env HOME="$TMP/ext-home-htp-missing" EXT_MISSING_LIBRARY=libcdsprpc.so.1 \
  EXT_CURL_LOG="$TMP/ext-htp-missing-downloads" EXT_FIXTURE="$EXT_FIXTURE" \
  PATH="$EXT_BIN:$PATH" TERNUX_STATE_DIR="$TMP/ext-state-htp-missing" \
  bash "$ROOT/bin/ternux" extension install llama-htp-experimental >/dev/null 2>&1 &&
  [ ! -e "$TMP/ext-home-htp-missing/.local/opt/ternux-extensions" ] &&
  [ ! -e "$TMP/ext-htp-missing-downloads" ]; then
  ok "HTP extension checks Binder/FastRPC runtime libraries before download"
else
  not_ok "HTP extension checks Binder/FastRPC runtime libraries before download"
fi
if ! env HOME="$TMP/ext-home-htp-missing-dev" EXT_MISSING_LIBRARY=libcdsprpc.so \
  EXT_CURL_LOG="$TMP/ext-htp-missing-dev-downloads" EXT_FIXTURE="$EXT_FIXTURE" \
  PATH="$EXT_BIN:$PATH" TERNUX_STATE_DIR="$TMP/ext-state-htp-missing-dev" \
  bash "$ROOT/bin/ternux" extension install llama-htp-experimental >/dev/null 2>&1 &&
  [ ! -e "$TMP/ext-home-htp-missing-dev/.local/opt/ternux-extensions" ] &&
  [ ! -e "$TMP/ext-htp-missing-dev-downloads" ]; then
  ok "HTP extension requires the unversioned FastRPC loader name before download"
else
  not_ok "HTP extension requires the unversioned FastRPC loader name before download"
fi
: > "$EXT_FIXTURE/libcdsprpc.so"
if env HOME="$TMP/ext-home-htp" EXT_GLIBC_VERSION=2.38 EXT_CURL_LOG="$TMP/ext-htp-downloads" \
  EXT_FIXTURE="$EXT_FIXTURE" PATH="$EXT_BIN:$PATH" \
  LD_LIBRARY_PATH="$EXT_FIXTURE" \
  TERNUX_STATE_DIR="$TMP/ext-state-htp" bash "$ROOT/bin/ternux" extension install llama-htp-experimental >/dev/null 2>&1 &&
  [ -x "$TMP/ext-home-htp/.local/opt/ternux-extensions/llama-htp-experimental/bin/htp-run" ] &&
  [ -f "$TMP/ext-home-htp/.local/opt/ternux-extensions/llama-htp-experimental/libexec/htp-broker.py" ] &&
  grep -Fq '"artifact": "ternux-llama-htp-sm8735-b11582"' \
    "$TMP/ext-home-htp/.local/opt/ternux-extensions/llama-htp-experimental/build-manifest.json"; then
  ok "experimental HTP extension verifies and installs the brokered package"
else
  not_ok "experimental HTP extension verifies and installs the brokered package"
fi
printf '%064d  %s.tar.gz\n' 0 "$EXT_TAG" > "$EXT_FIXTURE/$EXT_TAG.tar.gz.sha256"
if ! env HOME="$TMP/ext-home-bad" EXT_GLIBC_VERSION=2.38 EXT_CURL_LOG="$TMP/ext-bad-downloads" \
  EXT_FIXTURE="$EXT_FIXTURE" PATH="$EXT_BIN:$PATH" \
  TERNUX_STATE_DIR="$TMP/ext-state-bad" bash "$ROOT/bin/ternux" extension install llama-vulkan >/dev/null 2>&1 &&
  [ ! -e "$TMP/ext-home-bad/.local/opt/ternux-extensions/llama-vulkan" ] &&
  ! find "$TMP/ext-home-bad/.local/opt/ternux-extensions" -mindepth 1 -maxdepth 1 -name '.llama-vulkan.install.*' | grep -q .; then
  ok "extension checksum failure leaves no installed files or staging directory"
else
  not_ok "extension checksum failure leaves no installed files or staging directory"
fi

# ---------------------------------------------------------------------------
# Doctor v2: categorised checks, structured JSON, filters, --strict/--quick and
# extension health. The guest is mocked; the probe output is a fixture.
# ---------------------------------------------------------------------------
DR_HARNESS="$TMP/doctor-v2-harness.sh"
cat > "$DR_HARNESS" <<'EOF'
#!/usr/bin/env bash
ROOT="$1"; shift
mkdir -p "$HOME" "$TERNUX_STATE_DIR"
printf 'backend=virgl\n' > "$TERNUX_STATE_DIR/state"
: > "$HOME/x.sh"
. "$ROOT/lib/doctor.sh"
tnx_is_termux(){ :; }
tnx_has_cmd(){ return 0; }
proot-distro(){ [ "${1:-}" = list ] && echo "debian installed"; }
curl(){ return 0; }
tnx_detect_storage_gb(){ echo 10; }
tnx_detect_vulkan(){ echo yes; }
tnx_detect_gpu(){ echo Mali; }
tnx_detect_backend(){ echo virgl; }
tnx_detect_renderer(){ echo unknown; }
tnx_detect_phantom_killer(){ echo "${DR_PHANTOM:-disabled}"; }
tnx_detect_android_version(){ echo 14; }
tnx_detect_arch(){ echo aarch64; }
tnx_guest_login(){
  [ -n "${DR_GUEST_MARK:-}" ] && : > "$DR_GUEST_MARK"
  cat > /dev/null
  [ -n "${DR_PROBE_FILE:-}" ] && cat "$DR_PROBE_FILE"
  return 0
}
tnx_cmd_doctor "$@"
EOF
DR_PROBE_OK="$TMP/doctor-probe-ok.txt"
cat > "$DR_PROBE_OK" <<'EOF'
guest.arch=aarch64
guest.glibc=2.41
guest.os=Debian GNU/Linux 13 (trixie)
guest.sudo=yes
guest.cmd.startxfce4=yes
guest.cmd.glxinfo=yes
guest.cmd.xdpyinfo=yes
guest.cmd.pactl=yes
guest.dpkg_audit=0
guest.disk_free_gb=80
guest.turnip=managed
ext.llama-vulkan.present=yes
ext.llama-vulkan.artifact=ternux-llama-vulkan-linux-arm64-b11582
ext.llama-vulkan.missing_libs=2
EOF
dr_run() { # name, args... ; env TERNUX_JSON passed through
  local name="$1"; shift
  env TERNUX_STATE_DIR="$TMP/dr-state-$name" HOME="$TMP/dr-home-$name" "$@" 2>&1
}
DR_JSON="$(dr_run full env TERNUX_JSON=1 DR_PROBE_FILE="$DR_PROBE_OK" bash "$DR_HARNESS" "$ROOT")"
if python3 - "$DR_JSON" <<'PY'
import json, sys
x = json.loads(sys.argv[1])
assert x["command"] == "doctor" and x["schema_version"] == 2
for key in ("status", "timestamp", "version", "gpu", "backend", "renderer", "vulkan", "issues", "recommended_actions"):
    assert key in x, key
checks = x["checks"]
assert checks and all(set(c) == {"id", "category", "status", "title", "detail", "fix"} for c in checks)
assert {c["category"] for c in checks} <= {"system", "host", "guest", "graphics", "extensions"}
assert {c["status"] for c in checks} <= {"ok", "warn", "fail", "info"}
s = x["summary"]
for st in ("ok", "warn", "fail", "info"):
    assert s[st] == sum(1 for c in checks if c["status"] == st), st
assert len(x["issues"]) == len(x["recommended_actions"]) == s["warn"] + s["fail"]
by = {c["id"]: c for c in checks}
assert by["ext_llama-vulkan_libs"]["status"] == "warn" and "ext_llama-vulkan_libs" in x["issues"]
assert by["ext_llama-htp-experimental"]["status"] == "info"
assert by["glibc"]["status"] == "ok" and by["sudo"]["status"] == "ok"
assert x["backend"] == "virgl"
PY
then ok "doctor v2 JSON has the checks schema, consistent summary and extension health"
else not_ok "doctor v2 JSON has the checks schema, consistent summary and extension health"; fi

DR_EXT="$(dr_run ext env TERNUX_JSON=1 DR_PROBE_FILE="$DR_PROBE_OK" bash "$DR_HARNESS" "$ROOT" extensions)"
if python3 - "$DR_EXT" <<'PY'
import json, sys
x = json.loads(sys.argv[1])
assert x["checks"] and {c["category"] for c in x["checks"]} == {"extensions"}
PY
then ok "doctor category filter reports only the selected category"
else not_ok "doctor category filter reports only the selected category"; fi

if dr_run badcat env TERNUX_JSON=1 bash "$DR_HARNESS" "$ROOT" nonsense >/dev/null; then
  not_ok "doctor rejects an unknown category with exit 2"
else
  [ "$?" -eq 2 ] && ok "doctor rejects an unknown category with exit 2" || not_ok "doctor rejects an unknown category with exit 2"
fi

rm -f "$TMP/dr-guest-mark"
DR_QUICK="$(dr_run quick env TERNUX_JSON=1 DR_GUEST_MARK="$TMP/dr-guest-mark" DR_PROBE_FILE="$DR_PROBE_OK" bash "$DR_HARNESS" "$ROOT" --quick)"
if [ ! -e "$TMP/dr-guest-mark" ] && printf '%s' "$DR_QUICK" | python3 -c '
import json, sys
x = json.load(sys.stdin)
ids = {c["id"] for c in x["checks"]}
assert "guest_skipped" in ids and "extensions_skipped" in ids
'; then ok "doctor --quick never logs in to the guest"
else not_ok "doctor --quick never logs in to the guest"; fi

dr_run strict env TERNUX_JSON=1 DR_PHANTOM=enabled DR_PROBE_FILE="$DR_PROBE_OK" bash "$DR_HARNESS" "$ROOT" system host >/dev/null; plain_rc=$?
dr_run strict2 env TERNUX_JSON=1 DR_PHANTOM=enabled DR_PROBE_FILE="$DR_PROBE_OK" bash "$DR_HARNESS" "$ROOT" system host --strict >/dev/null; strict_rc=$?
dr_run strict3 env TERNUX_JSON=1 DR_PROBE_FILE="$DR_PROBE_OK" bash "$DR_HARNESS" "$ROOT" host --strict >/dev/null; clean_rc=$?
if [ "$plain_rc" -eq 0 ] && [ "$strict_rc" -eq 1 ] && [ "$clean_rc" -eq 0 ]; then
  ok "doctor --strict exits 1 only when a warning exists (default stays 0)"
else
  not_ok "doctor --strict exits 1 only when a warning exists (default stays 0)"
fi

DR_PROBE_BAD="$TMP/doctor-probe-bad.txt"
sed -e 's/^guest.dpkg_audit=0/guest.dpkg_audit=3/' \
    -e 's/^guest.sudo=yes/guest.sudo=no/' "$DR_PROBE_OK" > "$DR_PROBE_BAD"
DR_BAD="$(dr_run bad env TERNUX_JSON=1 DR_PROBE_FILE="$DR_PROBE_BAD" bash "$DR_HARNESS" "$ROOT" guest extensions)"
if python3 - "$DR_BAD" <<'PY'
import json, sys
x = json.loads(sys.argv[1])
assert x["status"] == "warning"
for needed in ("dpkg_broken", "sudo_missing"):
    assert needed in x["issues"], needed
PY
then ok "doctor flags broken dpkg and missing sudo"
else not_ok "doctor flags broken dpkg and missing sudo"; fi

DR_NOPROBE="$(dr_run noprobe env TERNUX_JSON=1 bash "$DR_HARNESS" "$ROOT" guest extensions)"
if python3 - "$DR_NOPROBE" <<'PY'
import json, sys
x = json.loads(sys.argv[1])
ids = {c["id"] for c in x["checks"]}
assert "guest_probe_unavailable" in ids and "extensions_probe_unavailable" in ids
assert x["issues"] == [] and x["status"] == "ok"
PY
then ok "doctor treats an unreachable guest as information, not a failure"
else not_ok "doctor treats an unreachable guest as information, not a failure"; fi

DR_HUMAN="$(dr_run human env DR_PROBE_FILE="$DR_PROBE_OK" bash "$DR_HARNESS" "$ROOT" extensions)"
if printf '%s' "$DR_HUMAN" | grep -q 'Diagnostic Summary' && printf '%s' "$DR_HUMAN" | grep -q 'llama-vulkan'; then
  ok "doctor human output groups checks and prints a summary"
else
  not_ok "doctor human output groups checks and prints a summary"
fi

# The GPU phase must install the Turnip driver where apt cannot reach it. A
# driver written over a dpkg-owned path is reverted by any mesa package
# operation, and on hardware Debian's own Mesa does not recognise that costs
# GPU support entirely rather than only speed.
gpu_phase="$(sed -n '/stage=\/tmp\/ternux-driver-stage/,/apt-mark hold/p' "$ROOT/lib/phases.sh")"
check "GPU phase pins the upstream release URL and archive checksum" bash -c '
  grep -Fq "mesa-26.3.0-devel-20260824" "$1/lib/phases.sh" &&
  grep -Fq "c014cf66bdbff96417ee30d34f006cf51df64ae04893d599711b0b6b73b52ccf" "$1/lib/phases.sh" &&
  grep -Fq "Freedreno archive SHA-256 mismatch" "$1/lib/phases.sh"
' _ "$ROOT"
check "GPU phase installs the driver outside dpkg's reach" bash -c '
  printf "%s" "$1" | grep -q "install -D -m 0755 .* /usr/local/lib/aarch64-linux-gnu/libvulkan_freedreno.so" &&
  ! printf "%s" "$1" | grep -qE "install -[Dm].* /usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so"
' _ "$gpu_phase"
check "GPU phase writes a managed ICD naming the managed driver" bash -c '
  printf "%s" "$1" | grep -q "/usr/local/share/vulkan/icd.d/ternux_freedreno_icd.json" &&
  printf "%s" "$1" | grep -q "library_path.*%s" &&
  ! printf "%s" "$1" | grep -q "install -m 0644 .* /usr/share/vulkan/icd.d/freedreno_icd.aarch64.json"
' _ "$gpu_phase"
check "GPU phase retires the distro ICD so the GPU is listed once" bash -c '
  printf "%s" "$1" | grep -q "dpkg-divert --add --rename" &&
  printf "%s" "$1" | grep -q "freedreno_icd.json.distrib"
' _ "$gpu_phase"

# The ICD the phase generates must be valid JSON and must carry the archive's
# own api_version rather than a guessed one.
icd_src="$TMP/icd-src.json"
printf '%s\n' '{"ICD":{"api_version":"1.4.359","library_path":"libvulkan_freedreno.so"},"file_format_version":"1.0.1"}' > "$icd_src"
check "generated ICD is valid JSON with the source api_version" bash -c '
  icd="$1"
  api="$(sed -n '"'"'s/.*"api_version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'"'"' "$icd" | head -n1)"
  [ -n "$api" ] || api=1.4.0
  printf "{\n    \"ICD\": {\n        \"api_version\": \"%s\",\n        \"library_arch\": \"64\",\n        \"library_path\": \"%s\"\n    },\n    \"file_format_version\": \"1.0.1\"\n}\n" \
    "$api" /usr/local/lib/aarch64-linux-gnu/libvulkan_freedreno.so > "$2"
  python3 -c '"'"'
import json, sys
d = json.load(open(sys.argv[1]))
assert d["ICD"]["api_version"] == "1.4.359", d
assert d["ICD"]["library_path"].startswith("/usr/local/"), d
'"'"' "$2"
' _ "$icd_src" "$TMP/icd-out.json"

# The launcher and the shell aliases are standalone files that never source
# ternux's libraries, so they must carry a literal `proot-distro login <distro>`
# rather than any helper of ours. Generate them and read what came out.
if env HOME="$TMP/home-launchgen" TERNUX_STATE_DIR="$TMP/state-launchgen" \
  PREFIX="$TMP/prefix-launchgen" bash -c '
    mkdir -p "$HOME" "$TERNUX_STATE_DIR" "$PREFIX/bin"
    . "$1/lib/core.sh"; . "$1/lib/ui.sh"; . "$1/lib/state.sh"
    . "$1/lib/phases.sh"
    tnx_ok(){ :; }; tnx_warn(){ :; }; tnx_info(){ :; }; tnx_fail(){ :; }
    tnx_state_set(){ :; }; tnx_state_mark(){ :; }
    tnx_phase_launcher ternux zink en_US.UTF-8 >/dev/null 2>&1
    : > "$HOME/.bashrc"
    RC_FILE="$HOME/.bashrc" tnx_phase_aliases ternux bash >/dev/null 2>&1 || true
    grep -q "proot-distro login debian" "$HOME/x.sh" &&
    ! grep -q "tnx_guest_login" "$HOME/x.sh" &&
    ! grep -rq "tnx_guest_login" "$HOME/.bashrc"
  ' _ "$ROOT"; then
  ok "generated launcher and aliases call proot-distro directly"
else
  not_ok "generated launcher and aliases call proot-distro directly"
fi

# Choosing zsh must bring a theme with it, the theme must stay optional, and a
# theme that cannot be fetched must not fail the phase or cost the aliases.
# chsh is stubbed away: one that wants a password would stall a real install.
if env HOME="$TMP/home-zsh-theme" TERNUX_STATE_DIR="$TMP/state-zsh-theme" \
  PREFIX="$TMP/prefix-zsh-theme" bash -c '
    root="$1"
    rcpath() { printf "%s/.zshrc" "$1"; }
    load() {
      . "$root/lib/core.sh"; . "$root/lib/ui.sh"; . "$root/lib/state.sh"
      . "$root/lib/phases.sh"
      tnx_ok(){ :; }; tnx_warn(){ :; }; tnx_info(){ :; }
      chsh(){ :; }
    }

    # 1. zsh with the theme already present: block written, wizard off, and the
    #    path left for the shell to expand rather than baked in at install time.
    export HOME="$2/with-theme"; export TERNUX_STATE_DIR="$2/st1"
    mkdir -p "$HOME/.local/share/ternux/powerlevel10k" "$TERNUX_STATE_DIR"
    : > "$HOME/.local/share/ternux/powerlevel10k/powerlevel10k.zsh-theme"
    ( load; tnx_phase_aliases ternux zsh ) >/dev/null 2>&1
    grep -q "TERNUX ZSH THEME" "$(rcpath "$HOME")" || exit 1
    grep -q "POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true" "$(rcpath "$HOME")" || exit 1
    grep -Fq "$HOME/.local/share" "$(rcpath "$HOME")" && exit 1   # must not be expanded
    grep -Fq "\$HOME/.local/share/ternux/powerlevel10k" "$(rcpath "$HOME")" || exit 1

    # 2. TERNUX_THEME=none keeps zsh and skips the theme.
    export HOME="$2/no-theme"; export TERNUX_STATE_DIR="$2/st2"; export TERNUX_THEME=none
    mkdir -p "$HOME" "$TERNUX_STATE_DIR"
    ( load; tnx_phase_aliases ternux zsh ) >/dev/null 2>&1
    grep -q "TERNUX ALIASES" "$(rcpath "$HOME")" || exit 1
    grep -q "TERNUX ZSH THEME" "$(rcpath "$HOME")" && exit 1
    unset TERNUX_THEME

    # 3. No git and no theme on disk: the phase still installs the aliases.
    export HOME="$2/no-git"; export TERNUX_STATE_DIR="$2/st3"
    mkdir -p "$HOME" "$TERNUX_STATE_DIR"
    ( load; tnx_has_cmd(){ [ "$1" != git ]; }; tnx_phase_aliases ternux zsh ) >/dev/null 2>&1
    grep -q "TERNUX ALIASES" "$(rcpath "$HOME")" || exit 1
    grep -q "TERNUX ZSH THEME" "$(rcpath "$HOME")" && exit 1
    exit 0
  ' _ "$ROOT" "$TMP/zsh-theme-cases"; then
  ok "zsh selection installs an optional, non-fatal powerlevel10k theme"
else
  not_ok "zsh selection installs an optional, non-fatal powerlevel10k theme"
fi

# Only Debian has a device-verified result, and nothing may claim otherwise.
# Ubuntu has a profile because its differences are known — apt and dpkg are the
# same, but snapd cannot work without systemd inside a PRoot container and must
# not be pulled in or upgraded.
check "distro profiles carry only the differences that exist" bash -c '
  . "$1/lib/core.sh"
  tnx_distro_profile debian
  [ "$TNX_DP_FAMILY" = apt ] && [ -z "$TNX_DP_EXTRA_HOLD" ] || exit 1
  tnx_distro_profile ubuntu
  [ "$TNX_DP_FAMILY" = apt ] && [ "$TNX_DP_EXTRA_HOLD" = snapd ] || exit 1
' _ "$ROOT"
check "known and verified distributions are separate claims" bash -c '
  . "$1/lib/core.sh"
  tnx_distro_known debian && tnx_distro_known ubuntu || exit 1
  tnx_distro_known arch && exit 1
  tnx_distro_verified debian || exit 1
  tnx_distro_verified ubuntu && exit 1
  exit 0
' _ "$ROOT"
check "the GPU phase holds what the profile names, not a fixed list" bash -c '
  phase="$(sed -n "/stage=\/tmp\/ternux-driver-stage/,/apt-mark hold/p" "$1/lib/phases.sh")"
  printf "%s" "$phase" | grep -q "apt-mark hold \$TNX_DP_MESA_HOLD \$TNX_DP_EXTRA_HOLD" || exit 1
  printf "%s" "$phase" | grep -q "apt-mark hold mesa-vulkan-drivers libgl1-mesa-dri" && exit 1
  exit 0
' _ "$ROOT"
check "extension install locates ldconfig outside PATH or reports it unavailable" bash -c '
  PATH=/usr/bin:/bin
  . "$1/lib/extension.sh"
  rc=0
  found="$(_tnx_extension_find_ldconfig)" || rc=$?
  if [ -x /sbin/ldconfig ]; then
    [ "$rc" -eq 0 ] && [ "$found" = /sbin/ldconfig ]
  elif [ -x /usr/sbin/ldconfig ]; then
    [ "$rc" -eq 0 ] && [ "$found" = /usr/sbin/ldconfig ]
  else
    [ "$rc" -ne 0 ]
  fi
' _ "$ROOT"

# Invariant 1 of lib/ui.sh: middle dot, bullet and braille render two cells wide
# on many Android fonts and all three sit below the CJK range, so a single
# "wide above U+2E7F" threshold counted them as one cell and the right border
# was pushed out. Over-estimating is the safe direction.
check "ambiguous-width glyphs are measured as two cells" bash -c '
  . "$1/lib/ui.sh"
  for pair in 183:2 8226:2 10303:2 8594:2 9608:2 28450:2 97:1 32:1; do
    code="${pair%%:*}"; want="${pair##*:}"
    _tnx_cellwidth "$code"
    [ "$_TNX_CW" = "$want" ] || { echo "U+$code: got $_TNX_CW want $want" >&2; exit 1; }
  done
' _ "$ROOT"
check "a clipped line never exceeds the slot it was given" bash -c '
  . "$1/lib/ui.sh"
  for text in "plain ascii line" "bullet • and dot · mixed" "⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿" "漢字 mixed with latin"; do
    for max in 8 12 20; do
      _tnx_clipv "$max" "$text"
      [ "$_TNX_CLIPW" -le "$max" ] || { echo "width $_TNX_CLIPW > max $max for: $text" >&2; exit 1; }
    done
  done
' _ "$ROOT"

printf '1..%d\n' "$((pass + fail))"
printf '# pass %d\n# fail %d\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
