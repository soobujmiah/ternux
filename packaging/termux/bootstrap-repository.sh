#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

readonly stable_repo_url='https://soobujmiah.github.io/ternux/apt'
readonly rc_repo_url='https://soobujmiah.github.io/ternux/apt-rc'
readonly expected_fingerprint='E5527F4D5B83037FF77B65AE5E894BBB81168B1D'

# A caller's toolchain LD_LIBRARY_PATH can shadow Termux's Bionic libraries.
termux_pkg() { LD_LIBRARY_PATH= pkg "$@"; }
termux_apt_get() { LD_LIBRARY_PATH= apt-get "$@"; }
curl_usable() { command -v curl >/dev/null 2>&1 && curl --version >/dev/null 2>&1; }

usage() {
  cat <<'HELP'
Configure the signed Ternux Termux APT repository and install its CLI.

Usage:
  bash bootstrap-repository.sh [--channel stable|rc] [--configure-only]

Requires a working curl or wget, gpg, pkg, apt-get, and a native Termux PREFIX.
The downloaded primary key is checked against the embedded full fingerprint
before APT trusts it.
The default channel is stable. The rc channel is for pre-release qualification.
HELP
}

configure_only=0
channel=stable
while (($#)); do
  case "$1" in
    --channel)
      (($# >= 2)) || { printf '%s\n' 'Missing value for --channel.' >&2; usage >&2; exit 2; }
      channel=$2; shift 2 ;;
    --configure-only) configure_only=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done
case "$channel" in
  stable) repo_url=$stable_repo_url; source_name=ternux.list ;;
  rc) repo_url=$rc_repo_url; source_name=ternux-rc.list ;;
  *) printf 'Unsupported APT channel: %s\n' "$channel" >&2; exit 2 ;;
esac
key_url="$repo_url/ternux-archive-key.asc"

if [[ -z "${PREFIX:-}" || ! -d "$PREFIX/etc/apt" ]]; then
  printf 'Run this script in native Termux; PREFIX/etc/apt was not found.\n' >&2
  exit 1
fi
for tool in gpg pkg; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'Missing %s. Run apt update && apt full-upgrade -y first, then install the prerequisite with apt.\n' "$tool" >&2
    exit 127
  fi
done
if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
  printf 'Missing curl and wget. Run apt update && apt full-upgrade -y, then apt install curl (or wget).\n' >&2
  exit 127
fi

keyring_dir="$PREFIX/etc/apt/keyrings"
source_dir="$PREFIX/etc/apt/sources.list.d"
keyring="$keyring_dir/ternux.gpg"
source_file="$source_dir/$source_name"
if [[ -L "$keyring_dir" || -L "$source_dir" || -L "$keyring" || -L "$source_file" ]]; then
  printf 'Refusing symlinked APT configuration paths.\n' >&2
  exit 1
fi
install -d -m 700 "$keyring_dir" "$source_dir"
work_dir="$(mktemp -d "${TMPDIR:-$PREFIX/tmp}/ternux-apt-bootstrap.XXXXXX")"
cleanup() { rm -rf -- "$work_dir"; }
trap cleanup EXIT

download_key() {
  local tool
  for tool in curl wget; do
    command -v "$tool" >/dev/null 2>&1 || continue
    if ! "$tool" --version >/dev/null 2>&1; then
      printf 'Warning: %s is installed but cannot start; trying the other downloader.\n' "$tool" >&2
      continue
    fi

    case "$tool" in
      curl)
        if curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 \
          --output "$work_dir/ternux-archive-key.asc" "$key_url"; then
          return 0
        fi
        ;;
      wget)
        if wget --https-only --quiet --timeout=30 --tries=3 \
          --output-document="$work_dir/ternux-archive-key.asc" "$key_url"; then
          return 0
        fi
        ;;
    esac
    rm -f -- "$work_dir/ternux-archive-key.asc"
    printf 'Warning: %s could not download the repository key; trying the other downloader.\n' "$tool" >&2
  done
  printf 'Could not download the Ternux signing key: neither curl nor wget is usable.\n' >&2
  return 1
}

download_key
primary_fingerprints="$(gpg --batch --with-colons --show-keys --fingerprint \
  "$work_dir/ternux-archive-key.asc" |
  awk -F: '$1 == "pub" {want=1; next} want && $1 == "fpr" {print toupper($10); want=0}')"
if [[ "$primary_fingerprints" != "$expected_fingerprint" ]]; then
  printf 'Ternux signing key fingerprint mismatch; repository was not configured.\n' >&2
  exit 1
fi

gpg --batch --dearmor --output "$work_dir/ternux.gpg" \
  "$work_dir/ternux-archive-key.asc"
chmod 600 "$work_dir/ternux.gpg"
printf 'deb [signed-by=%s] %s stable main\n' "$keyring" "$repo_url" \
  > "$work_dir/ternux.list"
chmod 600 "$work_dir/ternux.list"
install -m 600 "$work_dir/ternux.gpg" "$keyring"
install -m 600 "$work_dir/ternux.list" "$source_file"
printf 'Verified and configured the Ternux APT signing key.\n'

if ((configure_only)); then
  printf 'Next: apt update && apt full-upgrade -y && apt install ternux\n'
  exit 0
fi
if termux_pkg update; then
  termux_pkg install ternux
else
  if curl_usable; then
    printf 'pkg update failed while curl is runnable; check the configured Termux repository and retry.\n' >&2
    exit 1
  fi
  printf 'pkg update failed and curl cannot start; repairing the rolling Termux package set with apt-get.\n' >&2
  apt_options=(
    -o Dpkg::Options::=--force-confold
    -o Dpkg::Options::=--force-confdef
  )
  termux_apt_get update || exit 1
  termux_apt_get full-upgrade -y "${apt_options[@]}" || exit 1
  if ! curl_usable; then
    termux_apt_get install -y "${apt_options[@]}" curl || exit 1
  fi
  curl_usable || {
    printf 'curl is still unusable after apt-get recovery; Ternux was not installed.\n' >&2
    exit 1
  }
  termux_apt_get install -y "${apt_options[@]}" ternux
fi
