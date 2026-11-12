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
          DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends dbus-daemon dbus-x11 firefox-esr passwd
          ;;
        ubuntu)
          apt-get update
          DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates curl dbus-daemon dbus-x11 desktop-file-utils libasound2t64 libdbus-glib-1-2 libgbm1 libgtk-3-0t64 libnss3 libpango-1.0-0 libx11-xcb1 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libxrender1 libxss1 libxt6 passwd xz-utils
          bash /ternux-install-firefox-esr.sh
          ;;
        alpine)
          apk add --no-cache dbus-x11 firefox-esr shadow
          ;;
        archlinux)
          pacman -Sy --noconfirm archlinux-keyring
          pacman -Sy --noconfirm dbus firefox shadow
          ;;
        fedora)
          dnf install -y dbus-daemon firefox shadow-utils
          ;;
        opensuse)
          zypper --non-interactive --gpg-auto-import-keys refresh
          zypper --non-interactive --gpg-auto-import-keys install -y MozillaFirefox dbus-1 shadow
          ;;
        void)
          xbps-install -Suy xbps
          xbps-install -y dbus firefox shadow
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
      su -s /bin/sh browser -c "HOME=/tmp/firefox-home XDG_RUNTIME_DIR=/tmp/firefox-run MOZ_HEADLESS=1 dbus-run-session -- timeout 90 $browser --headless --no-remote --screenshot /out/firefox.png --window-size 1024,768 about:blank"
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
