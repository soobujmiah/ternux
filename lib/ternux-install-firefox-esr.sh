#!/usr/bin/env bash
# Install the official Mozilla Firefox ESR tarball on Ubuntu guests where
# Ubuntu's `firefox` package is a Snap shim and snapd is intentionally disabled.
set -euo pipefail

arch="$(dpkg --print-architecture)"
case "$arch" in
  arm64) os=linux64-aarch64 ;;
  amd64) os=linux64 ;;
  *) echo "Mozilla Firefox ESR has no configured Linux build for $arch." >&2; exit 2 ;;
esac

work="$(mktemp -d "${TMPDIR:-/tmp}/ternux-firefox-esr.XXXXXX")"
trap 'rm -rf -- "$work"' EXIT
archive="$work/firefox-esr.tar.xz"
python3 - "$archive" "https://download.mozilla.org/?product=firefox-esr-latest&os=$os&lang=en-US" <<'PYDOWNLOAD'
import sys
from urllib.parse import urlparse
from urllib.request import urlopen

destination, url = sys.argv[1:]
maximum = 250_000_000
with urlopen(url, timeout=30) as response:
    if urlparse(response.geturl()).scheme != "https":
        raise SystemExit("Mozilla redirected the download away from HTTPS; refusing it.")
    declared = response.headers.get("Content-Length")
    if declared and int(declared) > maximum:
        raise SystemExit("Firefox ESR archive exceeds the 250 MB download limit.")
    total = 0
    with open(destination, "wb") as output:
        while True:
            chunk = response.read(1024 * 128)
            if not chunk:
                break
            total += len(chunk)
            if total > maximum:
                raise SystemExit("Firefox ESR archive exceeds the 250 MB download limit.")
            output.write(chunk)
PYDOWNLOAD
tar -tJf "$archive" | grep -F -x 'firefox/firefox' >/dev/null

install -d -m 0755 /opt/ternux
stage="$(mktemp -d /opt/ternux/.firefox-esr-stage.XXXXXX)"
backup="/opt/ternux/.firefox-esr-backup.$$"
trap 'rm -rf -- "$work" "$stage"' EXIT
tar -xJf "$archive" -C "$stage" --no-same-owner
test -x "$stage/firefox/firefox"
destination=/opt/ternux/firefox-esr
if [ -e "$destination" ]; then mv "$destination" "$backup"; fi
if mv "$stage/firefox" "$destination"; then
  rm -rf -- "$stage" "$backup"
else
  [ ! -e "$backup" ] || mv "$backup" "$destination"
  exit 1
fi

cat > /usr/local/bin/firefox-esr <<'WRAPPER'
#!/bin/sh
exec /opt/ternux/firefox-esr/firefox --no-remote "$@"
WRAPPER
ln -sfn firefox-esr /usr/local/bin/firefox
chmod 0755 /usr/local/bin/firefox-esr
install -d -m 0755 /usr/local/share/applications
cat > /usr/local/share/applications/firefox-esr.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Firefox ESR
Comment=Browse the web with Mozilla Firefox Extended Support Release
Exec=/usr/local/bin/firefox-esr %u
Icon=firefox-esr
Terminal=false
Categories=Network;WebBrowser;
StartupNotify=true
DESKTOP
chmod 0644 /usr/local/share/applications/firefox-esr.desktop
update-desktop-database /usr/local/share/applications >/dev/null 2>&1 || true
desktop-file-validate /usr/local/share/applications/firefox-esr.desktop
