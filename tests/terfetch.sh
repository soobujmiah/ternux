#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
TERFETCH="$ROOT/share/terfetch/terfetch"

test -x "$TERFETCH"
bash -n "$TERFETCH"
[ "$("$TERFETCH" --version)" = 'terfetch 0.1.0' ]
"$TERFETCH" --help | grep -Fq 'Usage: terfetch [--json|--version|--help]'
human_output="$(NO_COLOR=1 "$TERFETCH")"
grep -Fq '>_ TERNUX' <<< "$human_output"
grep -Fq 'Presented by [SM]' <<< "$human_output"
grep -Fq '[ANDR]' <<< "$human_output"
grep -Fq '[LINUX]' <<< "$human_output"
grep -Fq 'Kernel' <<< "$human_output"
grep -Fq 'Uptime' <<< "$human_output"
grep -Fq 'Packages' <<< "$human_output"
grep -Fq 'GPU' <<< "$human_output"
badge_count="$(grep -oE '\[[A-Z0-9]+\]' <<< "$human_output" | wc -l | tr -d ' ')"
[ "$badge_count" = 11 ]
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
