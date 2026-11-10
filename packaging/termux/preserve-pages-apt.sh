#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  printf 'Usage: %s <built-site-dist-directory>\n' "${0##*/}" >&2
}

if (($# != 1)); then usage; exit 2; fi
dist_input=$1
if [[ ! -d "$dist_input" || -L "$dist_input" ]]; then
  printf 'Refusing missing or symlinked website output directory: %s\n' "$dist_input" >&2
  exit 1
fi
dist="$(cd -- "$dist_input" && pwd -P)"
if [[ -e "$dist/apt" || -L "$dist/apt" ]]; then
  printf 'Refusing to overwrite an existing website apt/ path.\n' >&2
  exit 1
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
bootstrap="$script_dir/bootstrap-repository.sh"
if [[ ! -f "$bootstrap" || -L "$bootstrap" ]]; then
  printf 'Missing regular repository bootstrap source: %s\n' "$bootstrap" >&2
  exit 1
fi

default_base_url='https://soobujmiah.github.io/ternux/apt'
base_url="${TERNUX_APT_BASE_URL:-$default_base_url}"
while [[ "$base_url" == */ ]]; do base_url="${base_url%/}"; done
if [[ "$base_url" == "$default_base_url" ]]; then
  curl_proto=(--proto '=https' --proto-redir '=https' --tlsv1.2)
elif [[ "${TERNUX_APT_TEST_HTTP:-0}" == 1 && "$base_url" =~ ^http://(127\.0\.0\.1|localhost):[0-9]+(/|$) ]]; then
  curl_proto=(--proto '=http' --proto-redir '=http')
else
  printf 'APT preservation only accepts the official Pages URL (HTTP is allowed only for loopback tests).\n' >&2
  exit 2
fi

tmp="$(mktemp -d "${TMPDIR:-/tmp}/ternux-pages-apt.XXXXXX")"
cleanup() { rm -rf -- "$tmp"; }
trap cleanup EXIT INT TERM

# Pages may briefly return 5xx responses while its edge is updating. Retry
# transient network/server errors, while still treating 4xx and repository
# verification failures as final errors.
curl_retry=(--retry 4 --retry-all-errors --retry-delay 2 --retry-max-time 30)

fetch() {
  local path=$1 output=$2 max_size=${3:-10485760} code
  code="$(curl "${curl_retry[@]}" --silent --show-error --location --connect-timeout 15 --max-time 120 \
    --max-filesize "$max_size" "${curl_proto[@]}" \
    --output "$output" --write-out '%{http_code}' "$base_url/$path")" || {
    printf 'Network error while retrieving published APT path: %s\n' "$path" >&2
    return 1
  }
  if [[ "$code" != 200 ]]; then
    printf 'Expected HTTP 200 for published APT path %s; received %s.\n' "$path" "$code" >&2
    return 1
  fi
}

# A 404 is the expected state before the first signed repository publication.
code="$(curl "${curl_retry[@]}" --silent --show-error --location --connect-timeout 15 --max-time 120 \
  --max-filesize 10485760 "${curl_proto[@]}" \
  --output "$tmp/InRelease" --write-out '%{http_code}' \
  "$base_url/dists/stable/InRelease")" || {
  printf 'Could not check the currently published APT repository.\n' >&2
  exit 1
}
if [[ "$code" == 404 ]]; then
  for companion in ternux-archive-key.asc bootstrap.sh; do
    companion_code="$(curl "${curl_retry[@]}" --silent --show-error --location --connect-timeout 15 --max-time 120 \
      --max-filesize 1048576 "${curl_proto[@]}" \
      --output /dev/null --write-out '%{http_code}' "$base_url/$companion")" || {
      printf 'Could not confirm that no prior APT repository is published.\n' >&2
      exit 1
    }
    if [[ "$companion_code" != 404 ]]; then
      printf 'Published APT paths are inconsistent (InRelease=404, %s=%s); refusing website deploy.\n' \
        "$companion" "$companion_code" >&2
      exit 1
    fi
  done
  printf 'No published signed APT repository exists yet; website deploy has nothing to preserve.\n'
  exit 0
fi
if [[ "$code" != 200 ]]; then
  printf 'Expected HTTP 200 or 404 for published InRelease; received %s.\n' "$code" >&2
  exit 1
fi

key="$tmp/ternux-archive-key.asc"
fetch ternux-archive-key.asc "$key" 1048576
expected_fingerprint="${TERNUX_APT_EXPECTED_FINGERPRINT:-$(sed -n "s/^readonly expected_fingerprint='\([[:xdigit:]]*\)'$/\1/p" "$bootstrap" | head -n 1)}"
expected_fingerprint="${expected_fingerprint^^}"
if [[ ! "$expected_fingerprint" =~ ^[[:xdigit:]]{40,64}$ ]]; then
  printf 'Could not determine a valid pinned APT signing fingerprint.\n' >&2
  exit 1
fi
key_fingerprint="$(gpg --batch --with-colons --show-keys --fingerprint "$key" |
  awk -F: '$1 == "pub" {want=1; next} want && $1 == "fpr" {print toupper($10); exit}')"
if [[ "$key_fingerprint" != "$expected_fingerprint" ]]; then
  printf 'Published APT key fingerprint mismatch; refusing to preserve repository.\n' >&2
  exit 1
fi
gpg --batch --dearmor --output "$tmp/keyring.gpg" "$key"

mkdir -p "$tmp/repo/dists/stable"
status_file="$tmp/gpg-status"
if ! gpg --batch --no-default-keyring --keyring "$tmp/keyring.gpg" \
  --status-fd 1 --output "$tmp/Release" --decrypt "$tmp/InRelease" > "$status_file"; then
  printf 'Published APT InRelease signature is invalid.\n' >&2
  exit 1
fi
if ! awk -v expected="$expected_fingerprint" \
  '$1 == "[GNUPG:]" && $2 == "VALIDSIG" && (toupper($3) == expected || toupper($12) == expected) {ok=1} END {exit !ok}' \
  "$status_file"; then
  printf 'Published APT InRelease was not signed by the pinned primary key.\n' >&2
  exit 1
fi

awk '
  /^SHA256:$/ {in_sha=1; next}
  /^[A-Za-z0-9-]+:/ {if (in_sha) exit}
  in_sha && NF == 3 {print $1 "\t" $2 "\t" $3}
' "$tmp/Release" > "$tmp/release-files.tsv"
if [[ ! -s "$tmp/release-files.tsv" ]]; then
  printf 'Signed APT Release has no SHA256 file inventory.\n' >&2
  exit 1
fi

safe_relative_path() {
  local value=$1
  [[ -n "$value" && "$value" != /* && "$value" =~ ^[A-Za-z0-9._/+~-]+$ ]] || return 1
  case "/$value/" in */../*|*/./*|*//* ) return 1 ;; esac
}

while IFS=$'\t' read -r expected_hash expected_size relative_path; do
  [[ "$expected_hash" =~ ^[[:xdigit:]]{64}$ && "$expected_size" =~ ^[0-9]+$ ]] || {
    printf 'Malformed SHA256 entry in signed Release.\n' >&2
    exit 1
  }
  safe_relative_path "$relative_path" || {
    printf 'Unsafe path in signed Release: %s\n' "$relative_path" >&2
    exit 1
  }
  destination="$tmp/repo/dists/stable/$relative_path"
  mkdir -p "$(dirname -- "$destination")"
  fetch "dists/stable/$relative_path" "$destination" "$expected_size"
  actual_size="$(wc -c < "$destination" | tr -d '[:space:]')"
  actual_hash="$(sha256sum "$destination" | awk '{print $1}')"
  if [[ "$actual_size" != "$expected_size" || "${actual_hash,,}" != "${expected_hash,,}" ]]; then
    printf 'Published APT index checksum/size mismatch: %s\n' "$relative_path" >&2
    exit 1
  fi
done < "$tmp/release-files.tsv"

: > "$tmp/packages.all"
packages_found=0
while IFS= read -r -d '' index; do
  case "$index" in
    *.xz) xz -dc -- "$index" >> "$tmp/packages.all" ;;
    *.gz) gzip -dc -- "$index" >> "$tmp/packages.all" ;;
    *) cat -- "$index" >> "$tmp/packages.all" ;;
  esac
  printf '\n' >> "$tmp/packages.all"
  packages_found=$((packages_found + 1))
done < <(find "$tmp/repo/dists/stable" -type f \
  \( -name Packages -o -name Packages.xz -o -name Packages.gz \) -print0)
if ((packages_found == 0)); then
  printf 'Signed APT Release contains no usable Packages index.\n' >&2
  exit 1
fi

awk 'BEGIN { RS=""; FS="\n" }
  {
    filename=""; hash=""; size=""
    for (i=1; i<=NF; i++) {
      if ($i ~ /^Filename: /) {sub(/^Filename: /, "", $i); filename=$i}
      else if ($i ~ /^SHA256: /) {sub(/^SHA256: /, "", $i); hash=$i}
      else if ($i ~ /^Size: /) {sub(/^Size: /, "", $i); size=$i}
    }
    if (filename != "" || hash != "" || size != "") {
      if (filename == "" || hash == "" || size == "") exit 2
      print filename "\t" hash "\t" size
    }
  }' "$tmp/packages.all" > "$tmp/packages.tsv" || {
    printf 'Published APT Packages index has an incomplete package record.\n' >&2
    exit 1
  }
if [[ ! -s "$tmp/packages.tsv" ]]; then
  printf 'Published APT Packages index is empty.\n' >&2
  exit 1
fi

while IFS=$'\t' read -r relative_path expected_hash expected_size; do
  safe_relative_path "$relative_path" || {
    printf 'Unsafe package path in signed APT index: %s\n' "$relative_path" >&2
    exit 1
  }
  [[ "$expected_hash" =~ ^[[:xdigit:]]{64}$ && "$expected_size" =~ ^[0-9]+$ ]] || {
    printf 'Malformed package checksum/size in signed APT index.\n' >&2
    exit 1
  }
  destination="$tmp/repo/$relative_path"
  mkdir -p "$(dirname -- "$destination")"
  fetch "$relative_path" "$destination" "$expected_size"
  actual_size="$(wc -c < "$destination" | tr -d '[:space:]')"
  actual_hash="$(sha256sum "$destination" | awk '{print $1}')"
  if [[ "$actual_size" != "$expected_size" || "${actual_hash,,}" != "${expected_hash,,}" ]]; then
    printf 'Published APT package checksum/size mismatch: %s\n' "$relative_path" >&2
    exit 1
  fi
done < "$tmp/packages.tsv"

mkdir -p "$tmp/repo/apt-root"
install -m 0644 "$tmp/InRelease" "$tmp/repo/dists/stable/InRelease"
install -m 0644 "$key" "$tmp/repo/apt-root/ternux-archive-key.asc"
install -m 0755 "$bootstrap" "$tmp/repo/apt-root/bootstrap.sh"
mkdir -p "$dist/apt"
cp -a "$tmp/repo/dists" "$dist/apt/"
cp -a "$tmp/repo/apt-root/." "$dist/apt/"
printf 'Verified and preserved signed APT repository (%s package record(s)).\n' \
  "$(wc -l < "$tmp/packages.tsv" | tr -d '[:space:]')"
