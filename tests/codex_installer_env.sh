#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/guest"
printf '# existing profile\n' > "$TMP/guest/.profile"
printf '# existing bashrc\n' > "$TMP/guest/.bashrc"

# shellcheck source=../lib/phases.sh
. "$ROOT/lib/phases.sh"

tnx_guest_login() {
  while (($#)); do
    if [[ "$1" == -- ]]; then shift; break; fi
    shift
  done
  [[ "$1" == bash && "$2" == -lc ]]
  local script="$3"
  HOME="$TMP/guest" bash -c "$script"
}

_tnx_configure_guest_codex_installer_default alice
_tnx_configure_guest_codex_installer_default alice
for rc in "$TMP/guest/.profile" "$TMP/guest/.bashrc" "$TMP/guest/.zshenv" "$TMP/guest/.zshrc"; do
  [[ "$(grep -Fc '# TERNUX CODEX INSTALLER DEFAULT BEGIN' "$rc")" -eq 1 ]]
  [[ "$(grep -Fc 'export CODEX_NON_INTERACTIVE="${CODEX_NON_INTERACTIVE:-1}"' "$rc")" -eq 1 ]]
  [[ "$(grep -Fc '# TERNUX CODEX INSTALLER DEFAULT END' "$rc")" -eq 1 ]]
done

value="$(HOME="$TMP/guest" bash -c 'unset CODEX_NON_INTERACTIVE; . "$HOME/.bashrc"; printf "%s" "$CODEX_NON_INTERACTIVE"')"
[[ "$value" == 1 ]]
value="$(HOME="$TMP/guest" bash -c 'CODEX_NON_INTERACTIVE=0; export CODEX_NON_INTERACTIVE; . "$HOME/.bashrc"; printf "%s" "$CODEX_NON_INTERACTIVE"')"
[[ "$value" == 0 ]]

printf 'ok - managed guest Bash, Zsh, and login configs default Codex installer safely and allow overrides\n'
