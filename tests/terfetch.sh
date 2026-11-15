#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
TERFETCH="$ROOT/share/terfetch/terfetch"

test -x "$TERFETCH"
bash -n "$TERFETCH"
[ "$("$TERFETCH" --version)" = 'terfetch 0.1.0' ]
"$TERFETCH" --help | grep -Fq 'Usage: terfetch [--json|--version|--help]'

# Exercise all ten native designs deterministically. Exactly one contains the
# Sobuj monogram; the other nine carry the small creator credit below.
special_count=0
expected_marks=('ANDROID' 'TUX' 'termux' 'TNX' '|o_o |' '|<>|' 'ARM64' 'TERNux' 'Linux' 'SOBUJ')
for index in {0..9}; do
  output="$(TERFETCH_TEST_HOST=termux TERFETCH_LOGO_INDEX="$index" NO_COLOR=1 "$TERFETCH")"
  grep -Fq "${expected_marks[index]}" <<< "$output"
  grep -Fq 'Commands' <<< "$output"
  grep -Fq 'tx guide | tx status' <<< "$output"
  if [ "$index" -eq 9 ]; then
    grep -Fq 'Presented by' <<< "$output"
    grep -Fq 'SOBUJ' <<< "$output"
    ! grep -Fq '@soobujmiah' <<< "$output"
    special_count=$((special_count + 1))
  else
    grep -Fq 'Presented by @soobujmiah' <<< "$output"
    ! grep -Fq 'SOBUJ' <<< "$output"
  fi
  ! grep -Eq '\[(XFCE|ANDR|TMX|TERMUX|SM|LINUX|PROOT|GPU|X11)\]' <<< "$output"
done
[ "$special_count" -eq 1 ]

# PRoot guests use stable distro art and guest-valid companion commands.
for distro in debian ubuntu kali alpine archlinux; do
  output="$(TERFETCH_TEST_DISTRO="$distro" NO_COLOR=1 "$TERFETCH")"
  grep -Eq "Distro +$distro$" <<< "$output"
  grep -Fq 'ternux info | ternux status' <<< "$output"
  grep -Fq 'Presented by @soobujmiah' <<< "$output"
  ! grep -Fq 'tx guide | tx status' <<< "$output"
  ! grep -Fq 'SOBUJ' <<< "$output"
done

"$TERFETCH" --json | python3 -c '
import json,sys
x=json.load(sys.stdin)
required={"name","environment","distro","host","android","architecture","cpu_cores","memory","storage","ternux","kernel","uptime","packages","shell","terminal","terminal_size","display_size","cpu","gpu","desktop","battery"}
assert required <= x.keys(), x
assert x["name"] == "Ternux", x
'
if "$TERFETCH" --bad >/dev/null 2>&1; then
  echo 'Unknown Terfetch option unexpectedly succeeded.' >&2
  exit 1
fi

printf '%s\n' 'Terfetch checks passed.'
