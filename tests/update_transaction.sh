#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail() { printf 'update transaction test failed: %s\n' "$1" >&2; exit 1; }

# Unit-check stable SemVer ordering and malformed input handling.
if ! env TERNUX_STATE_DIR="$TMP/state-version" HOME="$TMP/home-version" bash -c '
  . "$1/lib/core.sh"
  . "$1/lib/update.sh"
  _tnx_update_version_gt 2.0.1 2.0.0 || exit
  _tnx_update_version_gt 2.0.0 2.0.0 && exit 1
  _tnx_update_version_gt 1.4.0 2.0.0 && exit 1
  _tnx_update_version_gt 02.0.0 2.0.0 && exit 1
  :
' _ "$ROOT"; then
  fail 'SemVer comparison'
fi

FIXTURE="$TMP/fixture"
ORIGIN="$FIXTURE/origin.git"
WORK="$FIXTURE/work"
FAKEBIN="$FIXTURE/fakebin"
mkdir -p "$FIXTURE" "$WORK" "$FAKEBIN"
git init -q --bare "$ORIGIN"
git archive HEAD | tar -x -C "$WORK"
# The fixture release must exercise this worktree's uncommitted updater code.
cp "$ROOT/bin/ternux" "$WORK/bin/ternux"
cp "$ROOT/lib/update.sh" "$WORK/lib/update.sh"
git -C "$WORK" init -q
git -C "$WORK" config user.name 'Ternux updater test'
git -C "$WORK" config user.email 'ternux-updater-test@example.invalid'
git -C "$WORK" remote add origin "$ORIGIN"

make_release() {
  local version="$1" fail_installed="${2:-0}"
  python3 - "$WORK/lib/core.sh" "$version" <<'PYVERSION'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
import re
text, count = re.subn(r'^TERNUX_VERSION="[^"]+"$', f'TERNUX_VERSION="{sys.argv[2]}"', text, count=1, flags=re.M)
if count != 1:
    raise SystemExit('could not set fixture release version')
path.write_text(text)
guest = path.parent.parent / 'bin' / 'ternux-guest'
if guest.exists():
    guest_text = guest.read_text()
    guest_text, guest_count = re.subn(r'^TERNUX_GUEST_VERSION="[^"]+"$', f'TERNUX_GUEST_VERSION="{sys.argv[2]}"', guest_text, count=1, flags=re.M)
    if guest_count != 1:
        raise SystemExit('could not set fixture guest version')
    guest.write_text(guest_text)
PYVERSION
  if [ "$fail_installed" = 1 ]; then
    python3 - "$WORK/bin/ternux" <<'PYFAIL'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
needle = 'set -u\n'
injection = ('set -u\n'
             'if [ "${TERNUX_TEST_FAIL_INSTALLED:-0}" = 1 ] && [ -z "${TERNUX_LIB_DIR:-}" ] && [ "${1:-}" = "--version" ]; then\n'
             '  echo "ternux vbroken"\n'
             '  exit 0\n'
             'fi\n')
if needle not in text:
    raise SystemExit('could not add installed-verification failure')
path.write_text(text.replace(needle, injection, 1))
PYFAIL
  fi
  git -C "$WORK" add .
  git -C "$WORK" commit -qm "fixture release $version"
  git -C "$WORK" tag "v$version"
  git -C "$WORK" push -q origin "refs/tags/v$version"
}

make_release 2.0.1
make_release 2.0.2 1
cat > "$FAKEBIN/dpkg-query" <<'EOF_DPKG'
#!/bin/sh
exit 1
EOF_DPKG
cat > "$FAKEBIN/curl" <<'EOF_CURL'
#!/bin/sh
printf '{"tag_name":"%s"}\n' "${TERNUX_TEST_RELEASE_TAG:-v1.4.0}"
EOF_CURL
chmod 0755 "$FAKEBIN/dpkg-query" "$FAKEBIN/curl"

# The published stable release is older than this development build; update
# check must report no downgrade and keep the latest stable version visible.
check_output="$(env TERNUX_STATE_DIR="$TMP/state-check" HOME="$TMP/home-check" \
  PREFIX="$TMP/prefix-check" PATH="$FAKEBIN:$PATH" TERNUX_TEST_RELEASE_TAG=v1.4.0 \
  TERNUX_JSON=1 bash -c '. "$1/lib/core.sh"; . "$1/lib/update.sh"; _tnx_update_check' _ "$ROOT")" ||
  fail 'update check against the older stable release'
printf '%s\n' "$check_output" | grep -q 'latest_stable' || fail 'update check did not identify the stable release'
printf '%s\n' "$check_output" | grep -q '1.4.0' || fail 'update check omitted the stable tag version'

# Success path: fetch tag by its immutable commit ID, stage and validate the
# entire source tree, switch modules, verify the installed CLI, retain backup.
PREFIX="$TMP/prefix-success"
STATE="$TMP/state-success"
TMPDIR="$TMP/tmp-success"
mkdir -p "$PREFIX/bin" "$PREFIX/lib/ternux" "$TMPDIR"
cp "$ROOT/bin/ternux" "$PREFIX/bin/ternux"
chmod 0755 "$PREFIX/bin/ternux"
cp -R "$ROOT/lib/." "$PREFIX/lib/ternux/"
printf 'old-version-marker\n' > "$PREFIX/lib/ternux/old.marker"
env PREFIX="$PREFIX" TERNUX_STATE_DIR="$STATE" HOME="$TMP/home-success" TMPDIR="$TMPDIR" \
  PATH="$FAKEBIN:$PATH" TERNUX_TEST_RELEASE_TAG=v2.0.1 TERNUX_REPO_URL="$ORIGIN" \
  TERNUX_UPDATE_RELEASE_API=https://release.invalid/latest \
  bash "$ROOT/bin/ternux" update || fail 'installing pinned release v2.0.1'
"$PREFIX/bin/ternux" --version | grep -q '^ternux v2.0.1$' || fail 'new CLI version was not installed'
grep -q '^TERNUX_VERSION="2.0.1"$' "$PREFIX/lib/ternux/core.sh" || fail 'new library tree was not installed'
backup_marker="$(find "$PREFIX/lib/ternux-update-backups" -path '*/lib/old.marker' -print -quit)"
[ -n "$backup_marker" ] && grep -q old-version-marker "$backup_marker" || fail 'previous library tree was not retained'
[ ! -e "$PREFIX/lib/.ternux-update-journal" ] || fail 'success left an update journal'
[ ! -e "$PREFIX/lib/.ternux-update-lock" ] || fail 'success left an update lock'
grep -q '^version=2.0.1$' "$STATE/state" || fail 'state version was not committed after verification'

# Failure path: the staged binary passes its preflight but reports a wrong
# version after switch. The updater must restore the old files and clear journal.
PREFIX="$TMP/prefix-rollback"
TMPDIR="$TMP/tmp-rollback"
mkdir -p "$PREFIX/bin" "$PREFIX/lib/ternux" "$TMPDIR"
cp "$ROOT/bin/ternux" "$PREFIX/bin/ternux"
chmod 0755 "$PREFIX/bin/ternux"
cp -R "$ROOT/lib/." "$PREFIX/lib/ternux/"
printf 'rollback-marker\n' > "$PREFIX/lib/ternux/old.marker"
if env PREFIX="$PREFIX" TERNUX_STATE_DIR="$TMP/state-rollback" HOME="$TMP/home-rollback" \
  TMPDIR="$TMPDIR" PATH="$FAKEBIN:$PATH" TERNUX_TEST_RELEASE_TAG=v2.0.2 \
  TERNUX_TEST_FAIL_INSTALLED=1 TERNUX_REPO_URL="$ORIGIN" \
  TERNUX_UPDATE_RELEASE_API=https://release.invalid/latest \
  bash "$ROOT/bin/ternux" update >/dev/null 2>&1; then
  fail 'the intentionally bad installed candidate was accepted'
fi
"$PREFIX/bin/ternux" --version | grep -q '^ternux v2.0.0$' || fail 'rollback did not restore the old dispatcher'
grep -q rollback-marker "$PREFIX/lib/ternux/old.marker" || fail 'rollback did not restore old modules'
[ ! -e "$PREFIX/lib/.ternux-update-journal" ] || fail 'rollback left an update journal'
[ ! -e "$PREFIX/lib/.ternux-update-lock" ] || fail 'rollback left an update lock'

# Crash recovery path: a nonexistent owner simulates a killed updater after
# the journal was committed and the candidate module directory was switched.
PREFIX="$TMP/prefix-recovery"
backup_id=0000000000000000000000000000000000000000-1-999999999
backup="$PREFIX/lib/ternux-update-backups/$backup_id"
mkdir -p "$PREFIX/bin" "$PREFIX/lib/ternux" "$backup/bin" "$backup/lib"
cp "$ROOT/bin/ternux" "$backup/bin/ternux"
cp -R "$ROOT/lib/." "$backup/lib/"
cp "$ROOT/bin/ternux" "$PREFIX/bin/ternux"
chmod 0755 "$PREFIX/bin/ternux"
printf 'candidate-marker\n' > "$PREFIX/lib/ternux/candidate.marker"
printf '999999999 1 %s 1 1\n' "$backup_id" > "$PREFIX/lib/.ternux-update-journal"
env PREFIX="$PREFIX" "$PREFIX/bin/ternux" --version | grep -q '^ternux v2.0.0$' || fail 'dead-owner recovery did not restore the CLI'
[ -f "$PREFIX/lib/ternux/core.sh" ] || fail 'dead-owner recovery did not restore modules'
[ ! -e "$PREFIX/lib/ternux/candidate.marker" ] || fail 'dead-owner recovery left candidate modules active'
[ ! -e "$PREFIX/lib/.ternux-update-journal" ] || fail 'dead-owner recovery left a journal'

# A live owner identity must block a second dispatcher without touching files.
PREFIX="$TMP/prefix-live"
backup_id=0000000000000000000000000000000000000000-1-999999998
backup="$PREFIX/lib/ternux-update-backups/$backup_id"
mkdir -p "$PREFIX/bin" "$PREFIX/lib/ternux" "$backup/bin" "$backup/lib"
cp "$ROOT/bin/ternux" "$backup/bin/ternux"
cp -R "$ROOT/lib/." "$backup/lib/"
cp "$ROOT/bin/ternux" "$PREFIX/bin/ternux"
chmod 0755 "$PREFIX/bin/ternux"
printf 'still-running\n' > "$PREFIX/lib/ternux/live.marker"
owner_pid="$$"
owner_start="$(awk '{ sub(/^.*\) /, ""); print $20 }' "/proc/$$/stat")"
printf '%s %s %s 1 1\n' "$owner_pid" "$owner_start" "$backup_id" > "$PREFIX/lib/.ternux-update-journal"
set +e
env PREFIX="$PREFIX" TERNUX_UPDATE_FORCE_RECOVERY=1 "$PREFIX/bin/ternux" --version >/dev/null 2>&1
live_rc=$?
set -e
[ "$live_rc" -eq 75 ] || fail 'concurrent CLI was not blocked with the documented status'
[ -f "$PREFIX/lib/ternux/live.marker" ] && [ -e "$PREFIX/lib/.ternux-update-journal" ] ||
  fail 'live-owner check modified the active transaction'

# A symlinked backup root must fail closed before reading or restoring paths
# outside PREFIX, even if the journal otherwise contains valid fields.
PREFIX="$TMP/prefix-symlink-backups"
OUTSIDE="$TMP/outside-backups"
backup_id=0000000000000000000000000000000000000000-1-999999997
mkdir -p "$PREFIX/bin" "$PREFIX/lib" "$OUTSIDE/$backup_id/bin" "$OUTSIDE/$backup_id/lib"
cp "$ROOT/bin/ternux" "$PREFIX/bin/ternux"
chmod 0755 "$PREFIX/bin/ternux"
cp "$ROOT/bin/ternux" "$OUTSIDE/$backup_id/bin/ternux"
cp -R "$ROOT/lib/." "$OUTSIDE/$backup_id/lib/"
printf 'outside-marker\n' > "$OUTSIDE/$backup_id/lib/outside.marker"
ln -s "$OUTSIDE" "$PREFIX/lib/ternux-update-backups"
printf '999999997 1 %s 1 1\n' "$backup_id" > "$PREFIX/lib/.ternux-update-journal"
set +e
env PREFIX="$PREFIX" "$PREFIX/bin/ternux" --version >/dev/null 2>&1
symlink_rc=$?
set -e
[ "$symlink_rc" -eq 70 ] || fail 'symlinked backup root did not fail closed'
grep -q outside-marker "$OUTSIDE/$backup_id/lib/outside.marker" || fail 'symlinked backup check modified outside data'
[ -e "$PREFIX/lib/.ternux-update-journal" ] || fail 'symlinked backup check discarded the recovery journal'

# Migration path: exercise the actual published v1.4.0 dispatcher/core/updater
# against a local main branch containing the current v2 source. Keep the fake
# PRoot command fail-closed so this fixture cannot modify the live Debian guest.
MIGRATION_ORIGIN="$FIXTURE/v2-migration-origin.git"
MIGRATION_WORK="$FIXTURE/v2-migration-work"
MIGRATION_PREFIX="$TMP/prefix-v1.4-migration"
MIGRATION_HOME="$TMP/home-v1.4-migration"
MIGRATION_TMP="$TMP/tmp-v1.4-migration"
git init -q --bare "$MIGRATION_ORIGIN"
git --git-dir="$MIGRATION_ORIGIN" symbolic-ref HEAD refs/heads/main
mkdir -p "$MIGRATION_WORK" "$MIGRATION_PREFIX/bin" "$MIGRATION_PREFIX/lib/ternux" "$MIGRATION_TMP"
git archive HEAD | tar -x -C "$MIGRATION_WORK"
git -C "$MIGRATION_WORK" init -q
git -C "$MIGRATION_WORK" checkout -qb main
git -C "$MIGRATION_WORK" config user.name 'Ternux v1.4 migration fixture'
git -C "$MIGRATION_WORK" config user.email 'ternux-migration-test@example.invalid'
git -C "$MIGRATION_WORK" remote add origin "$MIGRATION_ORIGIN"
git -C "$MIGRATION_WORK" add .
git -C "$MIGRATION_WORK" commit -qm 'fixture Ternux v2 source'
git -C "$MIGRATION_WORK" push -q -u origin main
LEGACY_FIXTURE="$ROOT/tests/fixtures/ternux-v1.4.0"
[ -f "$LEGACY_FIXTURE/bin/ternux" ] && [ -f "$LEGACY_FIXTURE/lib/core.sh" ] &&
  [ -f "$LEGACY_FIXTURE/lib/update.sh" ] || fail 'published v1.4.0 updater fixture is incomplete'
cp "$LEGACY_FIXTURE/bin/ternux" "$MIGRATION_PREFIX/bin/ternux"
chmod 0755 "$MIGRATION_PREFIX/bin/ternux"
cp "$LEGACY_FIXTURE/lib/core.sh" "$MIGRATION_PREFIX/lib/ternux/core.sh"
cp "$LEGACY_FIXTURE/lib/update.sh" "$MIGRATION_PREFIX/lib/ternux/update.sh"
cat > "$FAKEBIN/proot-distro" <<'EOF_PROOT'
#!/bin/sh
# No installed guest exists in this test; never reach the real host command.
exit 1
EOF_PROOT
chmod 0755 "$FAKEBIN/proot-distro"
env PREFIX="$MIGRATION_PREFIX" HOME="$MIGRATION_HOME" TMPDIR="$MIGRATION_TMP" \
  PATH="$FAKEBIN:$PATH" TERNUX_REPO_URL="$MIGRATION_ORIGIN" \
  "$MIGRATION_PREFIX/bin/ternux" update || fail 'v1.4.0 to v2 source migration'
"$MIGRATION_PREFIX/bin/ternux" --version | grep -q '^ternux v2.0.0$' ||
  fail 'v1.4.0 migration did not activate the v2 CLI'
grep -q '^TERNUX_VERSION="2.0.0"$' "$MIGRATION_PREFIX/lib/ternux/core.sh" ||
  fail 'v1.4.0 migration did not install matching v2 modules'

printf 'updater transaction tests passed: version, stable no-downgrade, pinned fetch, staging, commit, rollback, crash recovery, concurrency, symlink safety, v1.4.0-to-v2 source migration\n'
