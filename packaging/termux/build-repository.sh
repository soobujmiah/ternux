#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
artifact_dir="$repo_root/artifacts/ternux-apt"
deb_dir="$artifact_dir/debs"
repository_dir="$artifact_dir/repository"
distribution=stable
component=main
sign=0
status_file=""
release_tmp=""
tool_log=""
fingerprint="${TERNUX_APT_SIGNING_FINGERPRINT:-}"
tool="${TERMUX_APT_REPO_TOOL:-termux-apt-repo}"
gpg_tool="${GPG:-gpg}"

cleanup() {
  [[ -z "$status_file" ]] || rm -f -- "$status_file"
  [[ -z "$release_tmp" ]] || rm -f -- "$release_tmp"
  [[ -z "$tool_log" ]] || rm -f -- "$tool_log"
}
trap cleanup EXIT

usage() {
  cat <<'HELP'
Build a local Termux APT repository from the package artifacts.

Usage:
  bash packaging/termux/build-repository.sh [--sign]

Unsigned output is for local testing only. Public distribution must be signed.
Signing uses an existing key in the current GnuPG home; this script never
creates, imports, copies, or exports a private key. Set
TERNUX_APT_SIGNING_FINGERPRINT to the full expected signing-key fingerprint.
The repository contains only the exported public key. A protected-key
passphrase can be supplied through TERNUX_APT_SIGNING_PASSPHRASE; it is passed
to GnuPG over stdin and is never written to a file or command argument.
HELP
}

while (($#)); do
  case "$1" in
    --sign) sign=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [[ -L "$repo_root/artifacts" || -L "$artifact_dir" ]]; then
  printf 'Refusing to build through a symlinked artifacts directory.\n' >&2
  exit 1
fi
mkdir -p "$artifact_dir"
expected_artifact_dir="$(cd -- "$repo_root" && pwd -P)/artifacts/ternux-apt"
actual_artifact_dir="$(cd -- "$artifact_dir" && pwd -P)"
if [[ "$actual_artifact_dir" != "$expected_artifact_dir" ]]; then
  printf 'Refusing repository output outside the project artifacts directory.\n' >&2
  exit 1
fi
version="$(sed -n 's/^TERNUX_VERSION="\([^"]*\)"$/\1/p' "$repo_root/lib/core.sh" | head -n 1)"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.+~-][A-Za-z0-9.+~-]+)?$ ]]; then
  printf 'Could not read a valid Ternux version from lib/core.sh.\n' >&2
  exit 1
fi
if [[ ! -d "$deb_dir" ]]; then
  printf 'Package artifacts were not found in %s. Build one first.\n' "$deb_dir" >&2
  exit 1
fi
shopt -s nullglob
deb_files=("$deb_dir"/*.deb)
shopt -u nullglob
if (( ${#deb_files[@]} != 1 )) || [[ ! -f "${deb_files[0]:-}" || "${deb_files[0]##*/}" != "ternux_${version}_all.deb" ]]; then
  printf 'Expected exactly one current Ternux package (%s); refusing stale or unrelated .deb files.\n' \
    "ternux_${version}_all.deb" >&2
  exit 1
fi
if ! command -v "$tool" >/dev/null 2>&1; then
  printf 'Missing %s. In Termux, install it with: pkg install termux-apt-repo\n' "$tool" >&2
  exit 127
fi

if ((sign)); then
  if [[ ! "$fingerprint" =~ ^[[:xdigit:]]{40,64}$ ]]; then
    printf 'Set TERNUX_APT_SIGNING_FINGERPRINT to the full expected fingerprint before signing.\n' >&2
    exit 2
  fi
  fingerprint="${fingerprint^^}"
  if ! command -v "$gpg_tool" >/dev/null 2>&1; then
    printf 'Missing GnuPG command: %s\n' "$gpg_tool" >&2
    exit 127
  fi
fi

# This path is a generated, ignored build artifact. Recreate it from scratch
# so a previous InRelease file can never survive an unsigned rebuild.
rm -rf -- "$repository_dir"
mkdir -p "$(dirname -- "$repository_dir")"
tool_log="$(mktemp "${TMPDIR:-/tmp}/ternux-apt-repo.XXXXXX")"
if "$tool" "$deb_dir" "$repository_dir" "$distribution" "$component" >"$tool_log" 2>&1; then
  printf 'APT index generated for %s/%s.\n' "$distribution" "$component"
else
  tool_rc=$?
  cat "$tool_log" >&2
  exit "$tool_rc"
fi
rm -f -- "$tool_log"
tool_log=""

release_dir="$repository_dir/dists/$distribution"
packages_file="$release_dir/$component/binary-all/Packages"
if [[ ! -s "$packages_file" || ! -s "$release_dir/Release" ]]; then
  printf 'Repository generator did not produce the expected stable/all index.\n' >&2
  exit 1
fi
deb_name="ternux_${version}_all.deb"
deb_path="$deb_dir/$deb_name"
if [[ ! -s "$deb_path" ]]; then
  printf 'Expected package artifact is missing: %s\n' "$deb_path" >&2
  exit 1
fi
deb_sha256="$(sha256sum "$deb_path" | awk '{print $1}')"
if ! grep -Fxq 'Package: ternux' "$packages_file" ||
   ! grep -Fxq "Version: $version" "$packages_file" ||
   ! grep -Fxq 'Architecture: all' "$packages_file" ||
   ! grep -Fxq "Filename: dists/$distribution/$component/binary-all/$deb_name" "$packages_file" ||
   ! grep -Fxq "SHA256: $deb_sha256" "$packages_file"; then
  printf 'APT index identity or package checksum does not match the current artifact.\n' >&2
  exit 1
fi

if ((sign)); then
  release_file="$release_dir/Release"
  inrelease="$release_dir/InRelease"
  release_tmp="$(mktemp "$release_dir/.Release.XXXXXX")"
  {
    printf 'Origin: Ternux\nLabel: Ternux Termux package repository\n'
    awk '
      /^Origin:/ || /^Label:/ {next}
      /^Codename:/ {$0 = "Codename: stable"}
      {print}
    ' "$release_file"
  } > "$release_tmp"
  mv -- "$release_tmp" "$release_file"
  release_tmp=""
  if [[ -n "${TERNUX_APT_SIGNING_PASSPHRASE+x}" ]]; then
    "$gpg_tool" --batch --yes --pinentry-mode loopback --passphrase-fd 0 \
      --local-user "$fingerprint" --digest-algo SHA256 --clearsign \
      --output "$inrelease" "$release_file" \
      <<< "$TERNUX_APT_SIGNING_PASSPHRASE"
  else
    "$gpg_tool" --batch --yes --local-user "$fingerprint" \
      --digest-algo SHA256 --clearsign --output "$inrelease" "$release_file"
  fi
  status_file="$(mktemp "${TMPDIR:-/tmp}/ternux-gpg-status.XXXXXX")"
  if ! "$gpg_tool" --batch --status-fd=1 --verify "$inrelease" >"$status_file" 2>/dev/null; then
    printf 'GnuPG could not verify the generated InRelease signature.\n' >&2
    exit 1
  fi
  valid_fingerprints="$(awk '$1 == "[GNUPG:]" && $2 == "VALIDSIG" {print toupper($3); if ($12 != "") print toupper($12)}' "$status_file")"
  if ! grep -Fxq "$fingerprint" <<< "$valid_fingerprints"; then
    printf 'InRelease signature fingerprint did not match the configured full fingerprint.\n' >&2
    exit 1
  fi
  public_key="$repository_dir/ternux-archive-key.asc"
  "$gpg_tool" --batch --armor --export "$fingerprint" > "$public_key"
  if [[ ! -s "$public_key" ]]; then
    printf 'Could not export the public signing key.\n' >&2
    exit 1
  fi
  exported_fingerprints="$("$gpg_tool" --batch --with-colons --show-keys --fingerprint "$public_key" | awk -F: '$1 == "fpr" {print toupper($10)}')"
  if ! grep -Fxq "$fingerprint" <<< "$exported_fingerprints"; then
    printf 'Exported public key fingerprint does not match the signing key.\n' >&2
    exit 1
  fi
  printf 'Verified signed repository with fingerprint %s.\n' "$fingerprint"
else
  if [[ -e "$release_dir/InRelease" || -e "$release_dir/Release.gpg" ]]; then
    printf 'Unsigned repository unexpectedly contains signature metadata.\n' >&2
    exit 1
  fi
  printf 'Built unsigned local repository. Do not publish it for client use.\n'
fi

install -m 755 "$repo_root/packaging/termux/bootstrap-repository.sh" "$repository_dir/bootstrap.sh"

printf 'Repository tree: %s\n' "$repository_dir"
printf 'APT source: deb [signed-by=$PREFIX/etc/apt/keyrings/ternux.gpg] https://<host>/<path> %s %s\n' "$distribution" "$component"
