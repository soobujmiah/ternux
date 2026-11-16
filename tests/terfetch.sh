#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
TERFETCH="$ROOT/share/terfetch/terfetch"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
export LINES=50

test -x "$TERFETCH"
bash -n "$TERFETCH"
[ "$("$TERFETCH" --version)" = 'terfetch 0.1.0' ]
"$TERFETCH" --help | grep -Fq 'Usage: terfetch [--json|--refresh|--version|--help]'

# Native Termux selects Android, Ternux Workstation, all managed distro logos,
# or Sobuj's special monogram.
declare -A logo_heads=()
for index in {0..17}; do
  output="$(TERFETCH_TEST_HOST=termux TERFETCH_LOGO_INDEX="$index" COLUMNS=160 NO_COLOR=1 "$TERFETCH")"
  logo_signature="$output"
  [ -n "$logo_signature" ]
  [ -z "${logo_heads[$logo_signature]:-}" ] || { echo "Duplicate native logo for index $index" >&2; exit 1; }
  logo_heads[$logo_signature]=1
  grep -Fq 'DAILY COMMANDS' <<< "$output"
  grep -Fq '$ tx guide' <<< "$output"
  grep -Fq '$ tx start <distro>' <<< "$output"
  ! grep -Eq 'Commands +tx ' <<< "$output"
  ! grep -Eq '\[(XFCE|ANDR|TMX|TERMUX|SM|LINUX|PROOT|GPU|X11)\]' <<< "$output"
  [ "$(awk 'length($0) > 160 { count++ } END { print count + 0 }' <<< "$output")" -eq 0 ]
  if [ "$index" -eq 17 ]; then
    grep -q 'Presented by' <<< "$output"
    ! grep -Fq '@soobujmiah' <<< "$output"
    grep -Fq 'SSSS  OOO  BBB  U   U JJJ' <<< "$output"
    ! grep -Eq 'M I A H|M     M' <<< "$output"
  else
    grep -Fq 'Presented by @soobujmiah' <<< "$output"
  fi
  credit_line="$(grep -n -m1 'Presented by @soobujmiah' <<< "$output" | cut -d: -f1 || true)"
  commands_line="$(grep -n -m1 'DAILY COMMANDS' <<< "$output" | cut -d: -f1)"
  if [ -n "$credit_line" ]; then [ "$credit_line" -lt "$commands_line" ]; fi
  panel_end="$commands_line"
  [ -z "$credit_line" ] || panel_end="$credit_line"
  panel_rows="$(sed -n "2,${panel_end}p" <<< "$output" | grep -Ec 'System +|Distro +|Environment +|Kernel +|Uptime +|Packages +|Package manager +|Architecture +|CPU +|CPU cores +|GPU +|Memory +|Storage +|Shell +|Terminal +|Terminal size +|Ternux +|User +|Locale +|Init +|Privilege +|Device +|Android +|Display +|Desktop +|Battery +')"
  [ "$panel_rows" -ge 20 ]
done
[ "${#logo_heads[@]}" -eq 18 ]
# Logo and facts stay side by side at every width. A fact is shown only when
# its complete label and value fit on the same row; widening after font zoom
# restores facts on the next prompt render.
small_output="$(TERFETCH_TEST_HOST=termux TERFETCH_LOGO_INDEX=1 COLUMNS=60 NO_COLOR=1 "$TERFETCH")"
grep -Eq 'System +Termux$' <<< "$small_output"
grep -Fq 'DAILY COMMANDS' <<< "$small_output"
wide_output="$(TERFETCH_TEST_DISTRO=alpine COLUMNS=160 LINES=50 NO_COLOR=1 "$TERFETCH")"
for width in 24 27 32 36 40 48 60 100 160; do
  output="$(TERFETCH_TEST_DISTRO=alpine COLUMNS="$width" LINES=24 NO_COLOR=1 "$TERFETCH")"
  grep -Eq 'Distro +alpine$' <<< "$output"
  [ "$(awk -v width="$width" 'length($0) > width { count++ } END { print count + 0 }' <<< "$output")" -eq 0 ]
  grep -Fq 'DAILY COMMANDS' <<< "$output"
done
[ "$(grep -Ec 'System +alpine|Distro +alpine|Environment +|Kernel +|Uptime +|Packages +' <<< "$small_output")" -lt "$(grep -Ec 'System +alpine|Distro +alpine|Environment +|Kernel +|Uptime +|Packages +' <<< "$wide_output")" ]
! grep -Eq '\.\.\.' <<< "$small_output"
short_height_output="$(TERFETCH_TEST_DISTRO=debian COLUMNS=80 LINES=12 NO_COLOR=1 "$TERFETCH")"
[ "$(( $(wc -l <<< "$short_height_output") + 2 ))" -le 11 ]
grep -Eq 'System +|Distro +debian$|Environment +' <<< "$short_height_output"
! grep -Eq 'Privilege +|Battery +' <<< "$short_height_output"
tall_height_output="$(TERFETCH_TEST_DISTRO=debian COLUMNS=80 LINES=48 NO_COLOR=1 "$TERFETCH")"
grep -Fq 'Privilege' <<< "$tall_height_output"
grep -Fq 'DAILY COMMANDS' <<< "$tall_height_output"
refreshed="$(TERFETCH_TEST_DISTRO=alpine COLUMNS=100 LINES=50 NO_COLOR=1 "$TERFETCH" --refresh)"
grep -Fq 'Distro          alpine' <<< "$refreshed"

# Startup presentation is one per TTY session, while manual runs always show.
mkdir -p "$TMP/startup-runtime"
startup_env=(TERFETCH_STARTUP_ONCE=1 TERFETCH_TEST_TTY=/dev/pts/ternux-test TERFETCH_TEST_SESSION=4242 TMPDIR="$TMP/startup-runtime" TERFETCH_TEST_HOST=termux COLUMNS=100 LINES=24 NO_COLOR=1)
startup_first="$(env "${startup_env[@]}" "$TERFETCH")"
startup_second="$(env "${startup_env[@]}" "$TERFETCH")"
[ -n "$startup_first" ]
[ -z "$startup_second" ]
manual_after_startup="$(TERFETCH_TEST_HOST=termux COLUMNS=100 LINES=24 NO_COLOR=1 "$TERFETCH")"
grep -Fq 'System          Termux' <<< "$manual_after_startup"

# Every managed distro has a stable distro-specific mark and usable commands.
for distro in adelie alpine archlinux artix chimera debian deepin fedora kali manjaro opensuse pardus rockylinux ubuntu void; do
  output="$(TERFETCH_TEST_DISTRO="$distro" COLUMNS=160 NO_COLOR=1 "$TERFETCH")"
  grep -Eq "Distro +$distro$" <<< "$output"
  grep -Fq 'Presented by @soobujmiah' <<< "$output"
  grep -Fq 'DAILY COMMANDS' <<< "$output"
  grep -Fq '$ ternux info' <<< "$output"
  case "$distro" in
    adelie) logo_mark=',-^-___'; grep -Fq '$ sudo apk update' <<< "$output" ;;
    alpine) logo_mark='.hdddddddd'; grep -Fq '$ sudo apk update' <<< "$output" ;;
    chimera) logo_mark='dddddddddddc'; grep -Fq '$ sudo apk update' <<< "$output" ;;
    archlinux) logo_mark='-+oooooo+:'; grep -Fq '$ sudo pacman -Syu' <<< "$output" ;;
    artix) logo_mark='ooxxxoo'; grep -Fq '$ sudo pacman -Syu' <<< "$output" ;;
    manjaro) logo_mark='#######'; grep -Fq '$ sudo pacman -Syu' <<< "$output" ;;
    debian) logo_mark='_,met$$$$$gg.'; grep -Fq '$ sudo apt update' <<< "$output" ;;
    deepin) logo_mark=':lllc'; grep -Fq '$ sudo apt update' <<< "$output" ;;
    fedora) logo_mark=";ccccccccccccccc"; grep -Fq '$ sudo dnf check-update' <<< "$output" ;;
    kali) logo_mark='..,;:ccc,.'; grep -Fq '$ sudo apt update' <<< "$output" ;;
    opensuse) logo_mark=';ldkO0000Okdl;.'; grep -Fq '$ sudo zypper refresh' <<< "$output" ;;
    pardus) logo_mark='.smNdy+-'; grep -Fq '$ sudo apt update' <<< "$output" ;;
    rockylinux) logo_mark='__wgliliiligw_'; grep -Fq '$ sudo dnf check-update' <<< "$output" ;;
    ubuntu) logo_mark='clooo:'; grep -Fq '$ sudo apt update' <<< "$output" ;;
    void) logo_mark='__.;=====;.__'; grep -Fq '$ sudo xbps-install -Syu' <<< "$output" ;;
  esac
  grep -Fq -- "$logo_mark" <<< "$output"
  panel_rows="$(grep -Ec 'System +|Distro +|Environment +|Kernel +|Uptime +|Packages +|Package manager +|Architecture +|CPU +|CPU cores +|GPU +|Memory +|Storage +|Shell +|Terminal +|Terminal size +|Ternux +|User +|Locale +|Init +|Privilege +|Device +|Android +|Display +|Desktop +|Battery +' <<< "$output")"
  [ "$panel_rows" -ge 20 ]
  [ "$(awk 'length($0) > 160 { count++ } END { print count + 0 }' <<< "$output")" -eq 0 ]
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
