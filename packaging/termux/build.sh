#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
manifest_template="$repo_root/packaging/termux/manifest.json"
artifact_dir="$repo_root/artifacts/ternux-apt"
output_dir="$artifact_dir/debs"
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

if [[ -L "$repo_root/artifacts" || -L "$artifact_dir" || -L "$output_dir" ]]; then
  printf 'Refusing to build through a symlinked artifacts directory.\n' >&2
  exit 1
fi
mkdir -p "$output_dir"
expected_output_dir="$(cd -- "$repo_root" && pwd -P)/artifacts/ternux-apt/debs"
actual_output_dir="$(cd -- "$output_dir" && pwd -P)"
if [[ "$actual_output_dir" != "$expected_output_dir" ]]; then
  printf 'Refusing package output outside the project artifacts directory.\n' >&2
  exit 1
fi
manifest="$(mktemp "${TMPDIR:-/tmp}/ternux-manifest.XXXXXX.json")"
trap 'rm -f "$manifest"' EXIT
sed "s/@VERSION@/$version/g" "$manifest_template" > "$manifest"

cd "$repo_root"
"$tool" "$manifest"
package_file="$output_dir/ternux_${version}_all.deb"
if [[ ! -s "$package_file" ]]; then
  printf 'Package builder did not create the expected artifact: %s\n' "$package_file" >&2
  exit 1
fi
find "$output_dir" -maxdepth 1 -type f -name 'ternux_*_all.deb' \
  ! -name "${package_file##*/}" -delete
printf 'Built Ternux %s package in %s\n' "$version" "$output_dir"
