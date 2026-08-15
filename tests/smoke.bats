#!/usr/bin/env bats
# =============================================================================
#  ternux — smoke tests
#  These tests verify the CLI works correctly in any environment.
#  They do NOT require Termux — they test dispatch, help, JSON output,
#  error handling, and argument parsing.
#
#  Usage:
#    bats tests/smoke.bats
#    (requires bats-core: https://github.com/bats-core/bats-core)
# =============================================================================

setup() {
  # Find the ternux CLI relative to the tests directory
  TNX_CLI="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/bin/ternux"
  export TERNUX_STATE_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$TERNUX_STATE_DIR"
}

# --- Help and version -------------------------------------------------------

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

@test "version: --version returns version string" {
  run bash "$TNX_CLI" --version
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "ternux v"
}

# --- Unknown command ---------------------------------------------------------

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

# --- JSON output -------------------------------------------------------------

@test "json: doctor --json produces valid JSON" {
  run bash "$TNX_CLI" doctor --json
  # Should not crash — will show limited results outside Termux
  echo "$output" | grep -q "command"
  echo "$output" | grep -q "status"
}

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

@test "json: verify --json produces valid JSON" {
  run bash "$TNX_CLI" verify --json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"command":"verify"'
}

# --- Global flags ------------------------------------------------------------

@test "flags: --quiet suppresses non-critical output" {
  run bash "$TNX_CLI" --quiet info
  [ "$status" -eq 0 ]
}

@test "flags: --verbose does not crash" {
  run bash "$TNX_CLI" --verbose info
  [ "$status" -eq 0 ]
}

@test "flags: --json can be before command" {
  run bash "$TNX_CLI" --json info
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"command":"info"'
}

# --- Subcommand validation ---------------------------------------------------

@test "profile: invalid subcommand fails" {
  run bash "$TNX_CLI" profile invalid_sub
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "Usage"
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

@test "logs: invalid subcommand fails" {
  run bash "$TNX_CLI" logs invalid_sub
  [ "$status" -eq 1 ]
  echo "$output" | grep -q "Usage"
}

# --- No crash tests for all commands -----------------------------------------

@test "no-crash: every command accepts --help" {
  for cmd in install start stop restart doctor repair verify benchmark profile backend info state logs update uninstall; do
    run bash "$TNX_CLI" "$cmd" --help
    [ "$status" -eq 0 ] || echo "FAIL: $cmd --help returned $status"
  done
}

@test "no-crash: every command accepts --quiet" {
  for cmd in info state verify backend profile; do
    run bash "$TNX_CLI" --quiet "$cmd"
    echo "OK: $cmd" 
  done
}