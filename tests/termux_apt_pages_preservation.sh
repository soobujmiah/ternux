#!/usr/bin/env bash
set -Eeuo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
helper="$root/packaging/termux/preserve-pages-apt.sh"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/ternux-apt-pages-test.XXXXXX")"
server_pid=""
cleanup() {
  if [[ -n "$server_pid" ]]; then kill "$server_pid" 2>/dev/null || true; wait "$server_pid" 2>/dev/null || true; fi
  rm -rf -- "$tmp"
}
trap cleanup EXIT INT TERM

for tool in curl gpg xz gzip sha256sum python3; do
  command -v "$tool" >/dev/null 2>&1 || { printf 'Missing test tool: %s\n' "$tool" >&2; exit 127; }
done

start_server() {
  local webroot=$1 portfile=$2
  python3 - "$webroot" "$portfile" <<'PY' >/dev/null 2>&1 &
import functools
import http.server
import os
import sys

root, portfile = sys.argv[1:]
os.chdir(root)
class QuietHandler(http.server.SimpleHTTPRequestHandler):
    transient_503_seen = set()
    def log_message(self, *_args):
        pass
    def do_GET(self):
        if self.path.endswith("/dists/stable/InRelease") and self.path not in self.transient_503_seen:
            self.transient_503_seen.add(self.path)
            self.send_response(503)
            self.end_headers()
            return
        super().do_GET()
server = http.server.ThreadingHTTPServer(
    ("127.0.0.1", 0), functools.partial(QuietHandler, directory=root)
)
with open(portfile, "w", encoding="ascii") as stream:
    stream.write(str(server.server_address[1]))
server.serve_forever()
PY
  server_pid=$!
  for _ in {1..100}; do
    [[ -s "$portfile" ]] && break
    kill -0 "$server_pid" 2>/dev/null || { printf 'Fixture HTTP server exited.\n' >&2; return 1; }
    sleep 0.05
  done
  [[ -s "$portfile" ]] || { printf 'Fixture HTTP server did not become ready.\n' >&2; return 1; }
  TEST_SERVER_PORT="$(cat "$portfile")"
}

# A first website deployment has no APT yet and should remain deployable.
mkdir -p "$tmp/empty-webroot/apt" "$tmp/no-repo-dist"
start_server "$tmp/empty-webroot" "$tmp/empty-port"
TERNUX_APT_BASE_URL="http://127.0.0.1:$TEST_SERVER_PORT/apt" \
TERNUX_APT_TEST_HTTP=1 bash "$helper" "$tmp/no-repo-dist"
[[ ! -e "$tmp/no-repo-dist/apt" ]] || { printf 'Created an APT tree when no prior repository exists.\n' >&2; exit 1; }
printf 'incomplete publication\n' > "$tmp/empty-webroot/apt/bootstrap.sh"
if TERNUX_APT_BASE_URL="http://127.0.0.1:$TEST_SERVER_PORT/apt" \
  TERNUX_APT_TEST_HTTP=1 bash "$helper" "$tmp/no-repo-dist"; then
  printf 'An incomplete APT publication unexpectedly allowed a website deploy.\n' >&2
  exit 1
fi
python3 -c 'from pathlib import Path; import sys; Path(sys.argv[1]).unlink()' "$tmp/empty-webroot/apt/bootstrap.sh"
kill "$server_pid"; wait "$server_pid" 2>/dev/null || true; server_pid=""

# Serve a minimal, signed APT tree and verify signature, index, and package hashes.
export GNUPGHOME="$tmp/gnupg"
install -d -m 700 "$GNUPGHOME"
gpg --batch --passphrase '' --quick-generate-key \
  'Ternux Pages fixture <ternux-pages-fixture@example.invalid>' rsa2048 sign 0 >/dev/null 2>&1
fingerprint="$(gpg --batch --with-colons --list-secret-keys --fingerprint |
  awk -F: '$1 == "sec" {want=1; next} want && $1 == "fpr" {print toupper($10); exit}')"
[[ "$fingerprint" =~ ^[[:xdigit:]]{40,64}$ ]] || { printf 'Could not create fixture signing key.\n' >&2; exit 1; }

fixture="$tmp/webroot/apt"
repo="$fixture/dists/stable"
package_rel='dists/stable/main/binary-all/ternux-fixture_1.0_all.deb'
mkdir -p "$repo/main/binary-all" "$(dirname "$fixture/$package_rel")"
printf 'verified Ternux fixture package\n' > "$fixture/$package_rel"
package_hash="$(sha256sum "$fixture/$package_rel" | awk '{print $1}')"
package_size="$(wc -c < "$fixture/$package_rel" | tr -d '[:space:]')"
cat > "$repo/main/binary-all/Packages" <<PACKAGES
Package: ternux-fixture
Version: 1.0
Architecture: all
Filename: $package_rel
Size: $package_size
SHA256: $package_hash
PACKAGES
index_hash="$(sha256sum "$repo/main/binary-all/Packages" | awk '{print $1}')"
index_size="$(wc -c < "$repo/main/binary-all/Packages" | tr -d '[:space:]')"
cat > "$repo/Release" <<RELEASE
Origin: Ternux
Label: Ternux fixture
Suite: stable
Codename: stable
Architectures: all
Components: main
SHA256:
 $index_hash $index_size main/binary-all/Packages
RELEASE
gpg --batch --yes --armor --clearsign --output "$repo/InRelease" "$repo/Release"
gpg --batch --armor --export "$fingerprint" > "$fixture/ternux-archive-key.asc"

mkdir -p "$tmp/webroot/apt"
# The helper deliberately copies the real, versioned bootstrap from the repo.
start_server "$tmp/webroot" "$tmp/port"
mkdir -p "$tmp/dist"
TERNUX_APT_BASE_URL="http://127.0.0.1:$TEST_SERVER_PORT/apt" \
TERNUX_APT_TEST_HTTP=1 TERNUX_APT_EXPECTED_FINGERPRINT="$fingerprint" \
  bash "$helper" "$tmp/dist"
cmp "$fixture/$package_rel" "$tmp/dist/apt/$package_rel"
cmp "$repo/InRelease" "$tmp/dist/apt/dists/stable/InRelease"
cmp "$fixture/ternux-archive-key.asc" "$tmp/dist/apt/ternux-archive-key.asc"
[[ -x "$tmp/dist/apt/bootstrap.sh" ]] || { printf 'Preserved bootstrap is not executable.\n' >&2; exit 1; }

# A modified package must not be copied into the rebuilt website, even with
# the previously valid signed index still present.
printf 'tampered package\n' > "$fixture/$package_rel"
mkdir -p "$tmp/tampered-dist"
if TERNUX_APT_BASE_URL="http://127.0.0.1:$TEST_SERVER_PORT/apt" \
  TERNUX_APT_TEST_HTTP=1 TERNUX_APT_EXPECTED_FINGERPRINT="$fingerprint" \
  bash "$helper" "$tmp/tampered-dist"; then
  printf 'Tampered package unexpectedly passed APT preservation.\n' >&2
  exit 1
fi
[[ ! -e "$tmp/tampered-dist/apt" ]] || { printf 'Partial APT tree was published after verification failure.\n' >&2; exit 1; }

# Even a correctly signed Release must not be allowed to escape its repository root.
cat > "$repo/Release" <<'RELEASE'
Origin: Ternux
Label: Ternux fixture
Suite: stable
Codename: stable
Architectures: all
Components: main
SHA256:
 0000000000000000000000000000000000000000000000000000000000000000 1 ../outside
RELEASE
gpg --batch --yes --armor --clearsign --output "$repo/InRelease" "$repo/Release"
mkdir -p "$tmp/traversal-dist"
if TERNUX_APT_BASE_URL="http://127.0.0.1:$TEST_SERVER_PORT/apt" \
  TERNUX_APT_TEST_HTTP=1 TERNUX_APT_EXPECTED_FINGERPRINT="$fingerprint" \
  bash "$helper" "$tmp/traversal-dist"; then
  printf 'Signed Release path traversal unexpectedly passed APT preservation.\n' >&2
  exit 1
fi
[[ ! -e "$tmp/traversal-dist/apt" ]] || { printf 'Partial APT tree was published after path traversal rejection.\n' >&2; exit 1; }
printf 'APT Pages preservation tests passed.\n'
