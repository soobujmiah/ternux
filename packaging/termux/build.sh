#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
manifest_template="$repo_root/packaging/termux/manifest.json"
output_dir="$repo_root/artifacts/ternux-apt/debs"
tool="${TERMUX_CREATE_PACKAGE:-termux-create-package}"

if ! command -v "$tool" >/dev/null 2>&1; then
  printf 'Missing %s. In Termux, install it with: pkg install termux-create-package\n' "$tool" >&2
  exit 127
fi

version="$(sed -n 's/^TERNUX_VERSION="\([^"]*\)"$/\1/p' "$repo_root/lib/core.sh" | head -n 1)"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.+~-][A-Za-z0-9.+~-]+)?$ ]]; then
  printf 'Could not read a valid Ternux version from lib/core.sh.\n' >&2
  exit 1
fi

mkdir -p "$output_dir"
manifest="$(mktemp "${TMPDIR:-/tmp}/ternux-manifest.XXXXXX.json")"
trap 'rm -f "$manifest"' EXIT
sed "s/@VERSION@/$version/g" "$manifest_template" > "$manifest"

cd "$repo_root"
"$tool" "$manifest"
printf 'Built Ternux %s package in %s\n' "$version" "$output_dir"
