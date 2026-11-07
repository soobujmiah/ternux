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
printf '%s\n' "$*" >> "$PKG_LOG"
STUB
chmod +x "$tmp/bin/"*
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
if env PATH="$tmp/bin:$PATH" PREFIX="$prefix" TMPDIR="$prefix/tmp" \
  MOCK_FINGERPRINT=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA PKG_LOG="$tmp/pkg.log" \
  bash "$root/packaging/termux/bootstrap-repository.sh" --configure-only \
  > /dev/null 2>&1; then
  echo 'mismatched key fingerprint was accepted' >&2
  exit 1
fi
if env PATH="$tmp/bin:$PATH" PREFIX="$prefix" TMPDIR="$prefix/tmp" \
  MOCK_FINGERPRINT="$expected" PKG_LOG="$tmp/pkg.log" \
  bash "$root/packaging/termux/bootstrap-repository.sh"; then
  grep -Fxq 'update' "$tmp/pkg.log"
  grep -Fxq 'install ternux' "$tmp/pkg.log"
else
  echo 'verified install path failed' >&2
  exit 1
fi
printf 'PASS: signed-repository bootstrap verifies fingerprint, configures APT, and installs through pkg\n'
