#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"

cat > "$TMP/payload.sh" <<'PAYLOAD'
printf '%s\n' "$@" > "$CAPTURE"
PAYLOAD
cat > "$TMP/bin/curl" <<'CURL'
#!/usr/bin/env bash
set -euo pipefail
output=""
while (($#)); do
  case "$1" in
    --output) output="$2"; shift 2 ;;
    *) shift ;;
  esac
done
[[ -n "$output" ]]
cp -- "$PAYLOAD" "$output"
CURL
chmod 0755 "$TMP/bin/curl"

export PATH="$TMP/bin:$PATH" PAYLOAD="$TMP/payload.sh" CAPTURE="$TMP/installer-args"
export TERNUX_STATE_DIR="$TMP/state" HOME="$TMP/home"
# shellcheck source=../lib/phases.sh
. "$ROOT/lib/phases.sh"

tnx_guest_login() {
  while (($#)); do
    if [[ "$1" == -- ]]; then shift; break; fi
    shift
  done
  [[ "$1" == bash && "$2" == -lc ]]
  local script="$3"
  shift 3
  bash -c "$script" "$@"
}

# Static pins are refreshed only with a reviewed upstream release and matching
# hosted-installer digest; direct shell pipelines are forbidden.
grep -Fq 'abf338605dae6dd28d101673ac6aed7995c955745db46d47676bc591a7957209' "$ROOT/lib/phases.sh"
grep -Fq '5b46a876404005229ee62fc2615ddeb1c3f510a434ced47dbbed06b93849c704' "$ROOT/lib/phases.sh"
grep -Fq -- '--commit 3b421578588243f920886e6fe79a6faa87ea026e --non-interactive' "$ROOT/lib/phases.sh"
grep -Fq -- '--version v2026.11.2 --no-onboard --verify' "$ROOT/lib/phases.sh"
if rg -n 'curl[^\n]*\|[^\n]*bash' "$ROOT/lib/phases.sh"; then
  echo 'directly executing a remote shell pipeline is forbidden' >&2
  exit 1
fi

valid_sha256="$(sha256sum "$PAYLOAD" | awk '{print $1}')"
tnx_run_pinned_optional_installer alice https://hermes-agent.nousresearch.com/install.sh \
  "$valid_sha256" --commit abcdef1234567890 --non-interactive
printf '%s\n' --commit abcdef1234567890 --non-interactive > "$TMP/expected"
cmp -s "$CAPTURE" "$TMP/expected"
[[ -z "$(find "$TMP" -maxdepth 1 -name 'ternux-optional-installer.*' -print -quit)" ]]
printf 'ok - pinned installer is verified, receives fixed arguments, and cleans its staging file\n'

rm -f "$CAPTURE"
if tnx_run_pinned_optional_installer alice https://hermes-agent.nousresearch.com/install.sh \
  0000000000000000000000000000000000000000000000000000000000000000 --non-interactive; then
  echo 'checksum mismatch unexpectedly executed the installer' >&2
  exit 1
fi
[[ ! -e "$CAPTURE" ]]
[[ -z "$(find "$TMP" -maxdepth 1 -name 'ternux-optional-installer.*' -print -quit)" ]]
printf 'ok - checksum mismatch stops before script execution and cleans staging\n'

if tnx_run_pinned_optional_installer alice https://attacker.invalid/install.sh "$valid_sha256"; then
  echo 'unapproved installer source unexpectedly ran' >&2
  exit 1
fi
[[ ! -e "$CAPTURE" ]]
printf 'ok - installer URLs outside the two first-party hosts are rejected\n'
