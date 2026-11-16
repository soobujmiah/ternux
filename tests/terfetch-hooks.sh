#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
HOOK="$TMP/hook.sh"
awk '
  /^# TERNUX TERFETCH START BEGIN$/ { capture=1 }
  capture { print }
  /^# TERNUX TERFETCH START END$/ && capture { exit }
' "$ROOT/lib/phases.sh" > "$HOOK"
grep -q '^# TERNUX TERFETCH START END$' "$HOOK"
python3 - "$ROOT/lib/phases.sh" "$ROOT/lib/ternux-assets/bin/ternux-configure-prompt" <<'PY'
import pathlib, sys
phase_path, configurator_path = map(pathlib.Path, sys.argv[1:])
phase = phase_path.read_text()
configurator = configurator_path.read_text()
def block(source, offset=0):
    start = source.index('# TERNUX TERFETCH START BEGIN', offset)
    end = source.index('# TERNUX TERFETCH START END', start) + len('# TERNUX TERFETCH START END')
    return source[start:end]
canonical = block(phase, phase.index('cat >> "$rc_tmp"'))
generated_template = block(configurator, configurator.index('write_bash_prompt')).replace(r'\$', '$')
generated_zsh_template = block(configurator, configurator.index('write_zsh_prompt')).replace(r'\$', '$')
assert generated_template == canonical, 'guest Bash hook template differs from the host hook'
assert generated_zsh_template == canonical, 'guest Zsh hook template differs from the host hook'
assert not any(marker in configurator for marker in ('┌──(', '└─')), 'guest prompts must remain renderable in default Termux:X11 fonts'
assert '_TERNUX_TERFETCH_AUTORUN_DONE' in configurator, 'Alpine profile must share the autorun guard'
assert canonical.count('export _TERNUX_TERFETCH_AUTORUN_DONE') == 1, 'host guard must be inherited by child shells'
assert configurator.count('export _TERNUX_TERFETCH_AUTORUN_DONE') == 3, 'guest Bash, Zsh, and Alpine guards must be inherited by child shells'
assert '_ternux_terfetch_resize_check' not in canonical, 'Terfetch must not rerun automatically after a command or resize'
PY

run_shell_check() {
  local shell="$1" log
  log="$TMP/$shell.log"
  : > "$log"
  if [[ "$shell" == bash ]]; then
    LOG="$log" HOOK="$HOOK" bash --noprofile --norc -ic '
      SIZE="24 80"
      stty() { printf "%s\n" "$SIZE"; }
      terfetch() { printf "%s\n" "${TERFETCH_STARTUP_ONCE:-0}" >> "$LOG.startup"; printf "%s\n" "$*" >> "$LOG"; }
      source "$HOOK"
      source "$HOOK"
      [ "$(wc -l < "$LOG")" -eq 1 ]
      [ "$(cat "$LOG.startup")" = 1 ]
      export -f terfetch
      bash --noprofile --norc -ic "source \"\$HOOK\"" >/dev/null 2>&1
      [ "$(wc -l < "$LOG")" -eq 1 ]
      SIZE="30 100"
      [ -z "${PROMPT_COMMAND:-}" ] || [[ "$PROMPT_COMMAND" != *"_ternux_terfetch_resize_check"* ]]
      [ "$(wc -l < "$LOG")" -eq 1 ]
      terfetch
      [ "$(wc -l < "$LOG")" -eq 2 ]
      [ "$(sed -n '2p' "$LOG.startup")" = 0 ]
      terfetch
      [ "$(wc -l < "$LOG")" -eq 3 ]
      [ "$(sed -n '3p' "$LOG.startup")" = 0 ]
    '
  else
    LOG="$log" HOOK="$HOOK" zsh -fic '
      SIZE="24 80"
      stty() { print -r -- "$SIZE"; }
      terfetch() { print -r -- "${TERFETCH_STARTUP_ONCE:-0}" >> "$LOG.startup"; print -r -- "$*" >> "$LOG"; }
      source "$HOOK"
      source "$HOOK"
      [[ $(wc -l < "$LOG") -eq 1 ]]
      [[ $(cat "$LOG.startup") == 1 ]]
      [[ ${_TERNUX_TERFETCH_AUTORUN_DONE:-0} == 1 ]]
      [[ ${parameters[_TERNUX_TERFETCH_AUTORUN_DONE]} == *export* ]]
      SIZE="30 100"
      [[ ${#precmd_functions[@]} -eq 0 ]]
      [[ $(wc -l < "$LOG") -eq 1 ]]
      terfetch
      [[ $(wc -l < "$LOG") -eq 2 ]]
      [[ $(sed -n '2p' "$LOG.startup") == 0 ]]
      terfetch
      [[ $(wc -l < "$LOG") -eq 3 ]]
      [[ $(sed -n '3p' "$LOG.startup") == 0 ]]
    '
  fi
}

bash -n "$HOOK"
run_shell_check bash
if command -v zsh >/dev/null 2>&1; then
  zsh -n "$HOOK"
  run_shell_check zsh
fi

printf '%s\n' 'Terfetch one-time startup and manual rerun checks passed.'
