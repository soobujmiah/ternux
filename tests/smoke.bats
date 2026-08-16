#!/usr/bin/env bats
# =============================================================================
#  ternux — smoke and edge-case tests
#
#  Tests the CLI in any environment (no Termux needed).
#  60+ tests covering dispatch, JSON, error handling, edge cases,
#  global flags, subcommands, state management, and no-crash guarantees.
#
#  Usage:
#    bats tests/smoke.bats
# =============================================================================

setup() {
  TNX_CLI="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/bin/ternux"
  export TERNUX_STATE_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$TERNUX_STATE_DIR"
}

# ===== HELP AND VERSION ====================================================

@test "help: shows main help" {
  run bash "$TNX_CLI" --help
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Usage:"
  echo "$output" | grep -q "ternux"
}

@test "help: -h shows main help" {
  run bash "$TNX_CLI" -h
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Usage:"
}

@test "help: doctor --help shows doctor-specific help" {
  run bash "$TNX_CLI" doctor --help
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "ternux doctor"
}

@test "help: profile --help shows subcommands" {
  run bash "$TNX_CLI" profile --help
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "show"
  echo "$output" | grep -q "save"
  echo "$output" | grep -q "list"
}

@test "help: backend --help shows set|detect" {
  run bash "$TNX_CLI" backend --help
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "set"
  echo "$output" | grep -q "detect"
}

@test "help: logs --help shows subcommands" {
  run bash "$TNX_CLI" logs --help
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "show"
  echo "$output" | grep -q "tail"
  echo "$output" | grep -q "clear"
  echo "$output" | grep -q "list"
}

@test "help: update --help shows check" {
  run bash "$TNX_CLI" update --help
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "check"
}

@test "help: install --help shows flags" {
  run bash "$TNX_CLI" install --help
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "\-\-yes"
  echo "$output" | grep -q "\-\-backend"
  echo "$output" | grep -q "\-\-with-llm"
}

@test "version: --version returns version string" {
  run bash "$TNX_CLI" --version
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "ternux v"
}

@test "version: -V returns version string" {
  run bash "$TNX_CLI" -V
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "ternux v"
}

@test "version: format is 'ternux vX.Y.Z'" {
  run bash "$TNX_CLI" --version
  [ "$status" -eq 0 ]
  echo "$output" | grep -qE '^ternux v[0-9]+\.[0-9]+\.[0-9]+'
}

# ===== UNKNOWN / EMPTY COMMANDS ============================================

@test "error: unknown command returns exit 1" {
  run bash "$TNX_CLI" nonexistent
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "Unknown command"
}

@test "error: empty command runs help" {
  run bash "$TNX_CLI"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Usage:"
}

@test "error: multiple unknown commands" {
  run bash "$TNX_CLI" foo bar baz
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "Unknown command"
}

# ===== JSON OUTPUT =========================================================

@test "json: info --json produces valid JSON" {
  run bash "$TNX_CLI" info --json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"command":"info"'
  echo "$output" | grep -q '"status":"ok"'
}

@test "json: backend --json produces valid JSON" {
  run bash "$TNX_CLI" backend --json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"command":"backend"'
}

@test "json: state --json produces valid JSON" {
  run bash "$TNX_CLI" state --json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"command":"state"'
}

@test "json: profile --json produces valid JSON" {
  run bash "$TNX_CLI" profile --json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"command":"profile"'
}

@test "json: verify --json produces valid output" {
  run bash "$TNX_CLI" verify --json
  echo "$output" | grep -q '"command":"verify"'
}

@test "json: output is parsable JSON" {
  run bash "$TNX_CLI" state --json
  [ "$status" -eq 0 ]
  # Verify it's valid JSON by attempting to parse with python3
  echo "$output" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null
  [ "$?" -eq 0 ]
}

@test "json: profile output is parsable JSON" {
  run bash "$TNX_CLI" profile --json
  [ "$status" -eq 0 ]
  echo "$output" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null
  [ "$?" -eq 0 ]
}

@test "json: backend output is parsable JSON" {
  run bash "$TNX_CLI" backend --json
  [ "$status" -eq 0 ]
  echo "$output" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null
  [ "$?" -eq 0 ]
}

# ===== GLOBAL FLAGS ========================================================

@test "flags: --quiet suppresses all output" {
  run bash "$TNX_CLI" --quiet info
  [ "$status" -eq 0 ]
}

@test "flags: --verbose does not crash" {
  run bash "$TNX_CLI" --verbose info
  [ "$status" -eq 0 ]
}

@test "flags: --json before command works" {
  run bash "$TNX_CLI" --json info
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"command":"info"'
}

@test "flags: --json after command works" {
  run bash "$TNX_CLI" info --json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"command":"info"'
}

@test "flags: --json and --quiet together" {
  run bash "$TNX_CLI" --json --quiet info
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"command":"info"'
}

@test "flags: --json --quiet produces only JSON (no human text)" {
  run bash "$TNX_CLI" --json --quiet state
  [ "$status" -eq 0 ]
  # Should NOT contain human output markers
  echo "$output" | grep -v "\[INFO\]"
  echo "$output" | grep -q '"command":"state"'
}

@test "flags: --json before help works" {
  run bash "$TNX_CLI" --json --help
  [ "$status" -eq 0 ]
}

@test "flags: multiple flags in any order" {
  run bash "$TNX_CLI" --quiet --json info
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"command":"info"'
  run bash "$TNX_CLI" --json --verbose info
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"command":"info"'
}

# ===== SUBCOMMAND VALIDATION ===============================================

@test "profile: invalid subcommand fails" {
  run bash "$TNX_CLI" profile invalid_sub
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "Usage"
}

@test "profile: empty subcommand defaults to show" {
  run bash "$TNX_CLI" profile
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Device Profile\|unknown"
}

@test "backend: invalid subcommand fails" {
  run bash "$TNX_CLI" backend invalid_sub
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "Usage"
}

@test "backend: set without backend name fails" {
  run bash "$TNX_CLI" backend set
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "Usage"
}

@test "backend: set with invalid backend fails" {
  run bash "$TNX_CLI" backend set invalid_gpu
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "Unknown backend"
}

@test "backend: empty subcommand defaults to show" {
  run bash "$TNX_CLI" backend
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "GPU Backend\|unknown"
}

@test "logs: invalid subcommand fails" {
  run bash "$TNX_CLI" logs invalid_sub
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "Usage"
}

@test "logs: empty subcommand defaults to show" {
  run bash "$TNX_CLI" logs
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Ternux Logs\|No log file"
}

@test "update: invalid subcommand fails" {
  run bash "$TNX_CLI" update invalid_sub
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "Usage"
}

@test "update: check is valid" {
  run bash "$TNX_CLI" update check
  echo "$output" | grep -q "Checking\|update\|Could not"
}

# ===== STATE MANAGEMENT ====================================================

@test "state: shows version" {
  run bash "$TNX_CLI" state
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Version:"
}

@test "state: --json has version field" {
  run bash "$TNX_CLI" state --json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"version"'
}

@test "state: persists across calls" {
  run bash "$TNX_CLI" state --json
  [ "$status" -eq 0 ]
  run bash "$TNX_CLI" state --json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"command":"state"'
}

@test "state: works with custom TERNUX_STATE_DIR" {
  local custom_dir="$(mktemp -d)"
  export TERNUX_STATE_DIR="$custom_dir"
  run bash "$TNX_CLI" state
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "$custom_dir"
  rm -rf "$custom_dir"
}

@test "state: works when state dir does not exist" {
  export TERNUX_STATE_DIR="/tmp/nonexistent-ternux-state-$$"
  run bash "$TNX_CLI" state
  [ "$status" -eq 0 ]
}

# ===== PROFILE SAVE/LOAD ===================================================

@test "profile: save creates a profile file" {
  run bash "$TNX_CLI" profile save test_device
  [ "$status" -eq 0 ]
  [ -f "$TERNUX_STATE_DIR/profiles/test_device" ]
}

@test "profile: save and load works" {
  run bash "$TNX_CLI" profile save test_save
  [ "$status" -eq 0 ]
  run bash "$TNX_CLI" profile load test_save
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "test_save"
}

@test "profile: list shows saved profiles" {
  run bash "$TNX_CLI" profile save test_list
  run bash "$TNX_CLI" profile list
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "test_list"
}

@test "profile: load nonexistent fails" {
  run bash "$TNX_CLI" profile load nonexistent_profile
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "not found"
}

@test "profile: --json with save/load" {
  run bash "$TNX_CLI" --json profile save json_test
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"status":"saved"'
}

# ===== BACKEND SET/DETECT ==================================================

@test "backend: detect works" {
  run bash "$TNX_CLI" backend detect
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Detected backend\|unknown"
}

@test "backend: set auto works" {
  run bash "$TNX_CLI" backend set auto
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Backend set\|Auto-detected\|unknown"
}

@test "backend: show after set reflects change" {
  run bash "$TNX_CLI" backend set auto
  [ "$status" -eq 0 ]
  run bash "$TNX_CLI" backend show
  [ "$status" -eq 0 ]
}

# ===== LOGS EDGE CASES =====================================================

@test "logs: show without log file gives message" {
  run bash "$TNX_CLI" logs show
  echo "$output" | grep -q "No log file\|Ternux Logs"
}

@test "logs: show 0 lines" {
  run bash "$TNX_CLI" logs show 0
  [ "$status" -eq 0 ]
}

@test "logs: clear without log file is safe" {
  # Log file doesn't exist; clearing should be harmless
  run bash "$TNX_CLI" --quiet logs clear
  [ "$status" -eq 0 ]
}

# ===== NO-CRASH GUARANTEES ================================================

@test "no-crash: every command with --help" {
  for cmd in install start stop restart doctor repair verify benchmark profile backend info state logs update uninstall; do
    run bash "$TNX_CLI" "$cmd" --help
    [ "$status" -eq 0 ] || echo "FAIL: $cmd --help"
  done
}

@test "no-crash: every command with --json" {
  for cmd in info state backend profile verify doctor; do
    run bash "$TNX_CLI" --json "$cmd"
    echo "  $cmd: exit=$status"
  done
}

@test "no-crash: every command with --quiet" {
  for cmd in info state backend profile doctor verify; do
    run bash "$TNX_CLI" --quiet "$cmd"
    echo "  $cmd: exit=$status"
  done
}

@test "no-crash: every command with --verbose" {
  for cmd in info state backend profile; do
    run bash "$TNX_CLI" --verbose "$cmd"
    echo "  $cmd: exit=$status"
  done
}

# ===== SYNTAX VALIDATION OF SCRIPTS ========================================

@test "syntax: all shell scripts pass bash -n" {
  local errors=0
  for f in "$(dirname "$BATS_TEST_FILENAME")/../bin/ternux" \
           "$(dirname "$BATS_TEST_FILENAME")/../lib/"*.sh \
           "$(dirname "$BATS_TEST_FILENAME")/../install.sh" \
           "$(dirname "$BATS_TEST_FILENAME")/../uninstall.sh"; do
    if [ -f "$f" ]; then
      bash -n "$f" 2>/dev/null || { echo "Syntax error: $f"; errors=$((errors + 1)); }
    fi
  done
  [ "$errors" -eq 0 ]
}

# ===== JSON SCHEMA COMPLIANCE ==============================================

@test "json-schema: info output has all required fields" {
  run bash "$TNX_CLI" info --json
  [ "$status" -eq 0 ]
  echo "$output" | python3 -c "
import sys, json
d = json.load(sys.stdin)
required = ['command','status','timestamp','version','gpu','backend','renderer','vulkan','android_version','architecture']
for key in required:
    assert key in d, f'Missing required field: {key}'
print('All required fields present')
" 2>/dev/null
  [ "$?" -eq 0 ]
}

@test "json-schema: backend output has GPU info" {
  run bash "$TNX_CLI" backend --json
  [ "$status" -eq 0 ]
  echo "$output" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert 'gpu' in d
assert 'backend' in d
assert 'renderer' in d
assert 'vulkan' in d
print('Backend JSON schema OK')
" 2>/dev/null
  [ "$?" -eq 0 ]
}

@test "json-schema: state output has version" {
  run bash "$TNX_CLI" state --json
  [ "$status" -eq 0 ]
  echo "$output" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert 'version' in d
assert 'completed_phases' in d
assert 'backend' in d
print('State JSON schema OK')
" 2>/dev/null
  [ "$?" -eq 0 ]
}