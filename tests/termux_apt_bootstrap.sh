#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
prefix="$tmp/prefix"
mkdir -p "$prefix/etc/apt" "$prefix/tmp" "$tmp/bin"
cat > "$tmp/bin/curl" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
while (($#)); do
  if [[ "$1" == --output ]]; then
    printf 'mock public key\n' > "$2"
    exit 0
  fi
  shift
done
exit 2
STUB
cat > "$tmp/bin/wget" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
for arg in "$@"; do
  if [[ "$arg" == --output-document=* ]]; then
    printf 'mock public key\n' > "${arg#*=}"
    exit 0
  fi
done
exit 2
STUB
cat > "$tmp/bin/gpg" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
if [[ " $* " == *' --show-keys '* ]]; then
  printf 'pub:-:4096:1:KEY:0::::::scSC:\nfpr:::::::::%s:\n' "${MOCK_FINGERPRINT:?}"
  exit 0
fi
if [[ " $* " == *' --dearmor '* ]]; then
  while (($#)); do
    if [[ "$1" == --output ]]; then printf 'binary mock key\n' > "$2"; exit 0; fi
    shift
  done
fi
exit 2
STUB
cat > "$tmp/bin/pkg" <<'STUB'
#!/usr/bin/env bash
printf '%s|%s\n' "$*" "${LD_LIBRARY_PATH-unset}" >> "$PKG_LOG"
STUB
chmod +x "$tmp/bin/"*
no_curl_path="$tmp/no-curl-bin"
mkdir -p "$no_curl_path"
for tool in env bash awk mktemp install chmod rm mkdir; do
  ln -s "$(command -v "$tool")" "$no_curl_path/$tool"
done
ln -s "$tmp/bin/wget" "$no_curl_path/wget"
ln -s "$tmp/bin/gpg" "$no_curl_path/gpg"
ln -s "$tmp/bin/pkg" "$no_curl_path/pkg"
expected=E5527F4D5B83037FF77B65AE5E894BBB81168B1D
if env PATH="$tmp/bin:$PATH" PREFIX="$prefix" TMPDIR="$prefix/tmp" \
  MOCK_FINGERPRINT="$expected" PKG_LOG="$tmp/pkg.log" \
  bash "$root/packaging/termux/bootstrap-repository.sh" --configure-only \
  > "$tmp/pass.log"; then
  grep -Fxq "deb [signed-by=$prefix/etc/apt/keyrings/ternux.gpg] https://soobujmiah.github.io/ternux/apt stable main" \
    "$prefix/etc/apt/sources.list.d/ternux.list"
  test -s "$prefix/etc/apt/keyrings/ternux.gpg"
  test "$(stat -c '%a' "$prefix/etc/apt/keyrings/ternux.gpg")" = 600
  test ! -s "$tmp/pkg.log"
else
  echo 'valid fingerprint configure-only path failed' >&2
  exit 1
fi
mkdir -p "$tmp/prefix-wget/etc/apt" "$tmp/prefix-wget/tmp"
if env PATH="$no_curl_path" PREFIX="$tmp/prefix-wget" TMPDIR="$tmp/prefix-wget/tmp" \
  MOCK_FINGERPRINT="$expected" PKG_LOG="$tmp/pkg-wget.log" \
  bash "$root/packaging/termux/bootstrap-repository.sh" --configure-only \
  > "$tmp/wget.log"; then
  test -s "$tmp/prefix-wget/etc/apt/keyrings/ternux.gpg"
  grep -Fxq "deb [signed-by=$tmp/prefix-wget/etc/apt/keyrings/ternux.gpg] https://soobujmiah.github.io/ternux/apt stable main" \
    "$tmp/prefix-wget/etc/apt/sources.list.d/ternux.list"
else
  echo 'wget-only fingerprint configure-only path failed' >&2
  exit 1
fi
if env PATH="$tmp/bin:$PATH" PREFIX="$prefix" TMPDIR="$prefix/tmp" \
  MOCK_FINGERPRINT="$expected" PKG_LOG="$tmp/pkg.log" \
  bash "$root/packaging/termux/bootstrap-repository.sh" --channel rc --configure-only \
  > "$tmp/rc.log"; then
  grep -Fxq "deb [signed-by=$prefix/etc/apt/keyrings/ternux.gpg] https://soobujmiah.github.io/ternux/apt-rc stable main" \
    "$prefix/etc/apt/sources.list.d/ternux-rc.list"
else
  echo 'RC channel configure-only path failed' >&2
  exit 1
fi
if env PATH="$tmp/bin:$PATH" PREFIX="$prefix" TMPDIR="$prefix/tmp" \
  MOCK_FINGERPRINT="$expected" PKG_LOG="$tmp/pkg.log" \
  bash "$root/packaging/termux/bootstrap-repository.sh" --channel unknown --configure-only \
  > /dev/null 2>&1; then
  echo 'unknown APT channel was accepted' >&2
  exit 1
fi
if env PATH="$tmp/bin:$PATH" PREFIX="$prefix" TMPDIR="$prefix/tmp" \
  MOCK_FINGERPRINT=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA PKG_LOG="$tmp/pkg.log" \
  bash "$root/packaging/termux/bootstrap-repository.sh" --configure-only \
  > /dev/null 2>&1; then
  echo 'mismatched key fingerprint was accepted' >&2
  exit 1
fi
if env PATH="$tmp/bin:$PATH" PREFIX="$prefix" TMPDIR="$prefix/tmp" \
  MOCK_FINGERPRINT="$expected" PKG_LOG="$tmp/pkg.log" LD_LIBRARY_PATH=/mock/codex-runtime/lib \
  bash "$root/packaging/termux/bootstrap-repository.sh"; then
  grep -Fxq 'update|' "$tmp/pkg.log"
  grep -Fxq 'install ternux|' "$tmp/pkg.log"
else
  echo 'verified install path failed' >&2
  exit 1
fi
printf 'PASS: signed-repository bootstrap verifies fingerprint, configures APT, and installs through pkg\n'
