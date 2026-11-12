#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

command -v docker >/dev/null 2>&1 || { echo 'Docker is required for the Firefox package matrix.' >&2; exit 2; }

profiles=(
  'debian|debian:trixie'
  'ubuntu|ubuntu:24.04'
  'alpine|alpine:3.24'
  'archlinux|archlinux:latest'
  'fedora|fedora:latest'
  'opensuse|opensuse/tumbleweed:latest'
  'void|ghcr.io/void-linux/void-glibc:latest'
)

for profile in "${profiles[@]}"; do
  distro="${profile%%|*}"
  image="${profile#*|}"
  output="$TMP/$distro"
  mkdir -p "$output"
  chmod 0777 "$output"
  echo "==> Firefox clean package route: $distro ($image)"
  docker run --rm \
    --shm-size=1g \
    --volume "$ROOT/lib/ternux-install-firefox-esr.sh:/ternux-install-firefox-esr.sh:ro" \
    --volume "$output:/out" \
    --env "TNX_BROWSER_PROFILE=$distro" \
    "$image" sh -ec '
      case "$TNX_BROWSER_PROFILE" in
        debian)
          apt-get update
          DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends dbus-daemon dbus-x11 firefox-esr passwd xvfb
          ;;
        ubuntu)
          apt-get update
          DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates curl dbus-daemon dbus-x11 desktop-file-utils libasound2t64 libdbus-glib-1-2 libgbm1 libgtk-3-0t64 libnss3 libpango-1.0-0 libx11-xcb1 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libxrender1 libxss1 libxt6 passwd xz-utils xvfb
          bash /ternux-install-firefox-esr.sh
          ;;
        alpine)
          apk add --no-cache dbus dbus-x11 firefox-esr shadow xvfb
          ;;
        archlinux)
          pacman -Sy --noconfirm archlinux-keyring
          pacman -Sy --noconfirm dbus firefox shadow xorg-server-xvfb
          ;;
        fedora)
          dnf install -y dbus-daemon firefox shadow-utils xorg-x11-server-Xvfb
          ;;
        opensuse)
          zypper --non-interactive --gpg-auto-import-keys refresh
          zypper --non-interactive --gpg-auto-import-keys install -y MozillaFirefox dbus-1 shadow xorg-x11-server-Xvfb
          ;;
        void)
          xbps-install -Suy xbps
          xbps-install -y dbus firefox shadow xorg-server-xvfb
          ;;
        *) echo "Unknown profile: $TNX_BROWSER_PROFILE" >&2; exit 2 ;;
      esac
      if [ "$TNX_BROWSER_PROFILE" = alpine ]; then
        adduser -D browser
      else
        useradd -m browser
      fi
      install -d -o browser -g browser /tmp/firefox-home /tmp/firefox-run
      chmod 0700 /tmp/firefox-run
      browser="$(command -v firefox-esr || command -v firefox || true)"
      [ -n "$browser" ] && [ -x "$browser" ] || { echo "Firefox executable missing for $TNX_BROWSER_PROFILE" >&2; exit 1; }
      cat > /tmp/ternux-firefox-probe <<'PROBE'
#!/bin/sh
set -eu
browser="$1"
Xvfb :99 -screen 0 1280x768x24 -nolisten tcp >/tmp/ternux-xvfb.log 2>&1 &
xvfb_pid=$!
trap 'kill "$xvfb_pid" 2>/dev/null || true' EXIT
for attempt in 1 2 3 4 5 6 7 8 9 10; do
  [ -S /tmp/.X11-unix/X99 ] && break
  sleep 0.2
done
[ -S /tmp/.X11-unix/X99 ] || { cat /tmp/ternux-xvfb.log >&2; exit 1; }
export DISPLAY=:99 HOME=/tmp/firefox-home XDG_RUNTIME_DIR=/tmp/firefox-run
dbus-run-session -- timeout 90 "$browser" --no-remote --screenshot /out/firefox.png about:blank
PROBE
      chmod 0755 /tmp/ternux-firefox-probe
      su -s /bin/sh browser -c "/tmp/ternux-firefox-probe '$browser'"
      test -s /out/firefox.png
    '
  python3 - "$output/firefox.png" "$distro" <<'PY'
import pathlib, struct, sys
path = pathlib.Path(sys.argv[1])
data = path.read_bytes()
assert data[:8] == b"\x89PNG\r\n\x1a\n", f"{sys.argv[2]}: Firefox output is not PNG"
width, height = struct.unpack(">II", data[16:24])
assert width > 0 and height > 0, f"{sys.argv[2]}: invalid screenshot dimensions"
print(f"PASS: {sys.argv[2]} Firefox headless launch produced {width}x{height} PNG")
PY
done
