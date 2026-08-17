#!/usr/bin/env bash
# Focused dependency-free tests for installer safety and state semantics.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0
ok() { printf 'ok %d - %s\n' "$((pass + fail + 1))" "$1"; pass=$((pass + 1)); }
not_ok() { printf 'not ok %d - %s\n' "$((pass + fail + 1))" "$1"; fail=$((fail + 1)); }
check() {
  local name="$1"; shift
  if "$@"; then ok "$name"; else not_ok "$name"; fi
}

printf 'TAP version 13\n'

# Persisted custom user is the default for later CLI modules.
state="$TMP/state-user"
mkdir -p "$state"
printf 'user=alice\n' > "$state/state"
check "core loads persisted Debian user" env -u TERNUX_USER \
  TERNUX_STATE_DIR="$state" HOME="$TMP/home-user" bash -c \
  '. "$1/lib/core.sh"; test "$TERNUX_USER" = alice' _ "$ROOT"

# Build archives that exercise target-only validation. An unrelated symlink is
# legitimate; a symlink at either selected target is not.
fixture="$TMP/archive"
mkdir -p "$fixture/wrap/usr/lib/aarch64-linux-gnu" \
         "$fixture/wrap/usr/share/vulkan/icd.d" "$fixture/wrap/usr/lib/extra"
printf driver > "$fixture/wrap/usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so"
printf '{}' > "$fixture/wrap/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json"
ln -s ../libvulkan_freedreno.so "$fixture/wrap/usr/lib/extra/legitimate-link.so"
tar -czf "$TMP/good.tar.gz" -C "$fixture" wrap

check "Turnip validator accepts exact regular targets plus unrelated symlinks" \
  env TERNUX_STATE_DIR="$TMP/state-archive" HOME="$TMP/home-archive" bash -c \
  '. "$1/lib/phases.sh"; tnx_validate_turnip_archive "$2"' _ "$ROOT" "$TMP/good.tar.gz"

rm -f "$fixture/wrap/usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so"
ln -s libvulkan_other.so "$fixture/wrap/usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so"
tar -czf "$TMP/bad-link.tar.gz" -C "$fixture" wrap
if env TERNUX_STATE_DIR="$TMP/state-archive-bad" HOME="$TMP/home-archive-bad" bash -c \
  '. "$1/lib/phases.sh"; tnx_validate_turnip_archive "$2"' _ "$ROOT" "$TMP/bad-link.tar.gz"; then
  not_ok "Turnip validator rejects a selected symlink"
else
  ok "Turnip validator rejects a selected symlink"
fi

# Generated launchers must target the chosen account, use repeatable --env
# correctly, and start VirGL only on the VirGL route.
launcher_home="$TMP/home-launcher"
mkdir -p "$launcher_home"
if env TERNUX_STATE_DIR="$TMP/state-launcher" HOME="$launcher_home" bash -c '
  . "$1/lib/phases.sh"
  tnx_phase_launcher alice zink en_US.UTF-8 >/dev/null
  tnx_phase_aliases alice bash >/dev/null
  bash -n "$HOME/x.sh" &&
  grep -q -- "--user alice" "$HOME/x.sh" &&
  grep -q -- "--env DISPLAY=:0" "$HOME/x.sh" &&
  grep -q -- "--env LC_ALL=en_US.UTF-8" "$HOME/x.sh" &&
  grep -q "^trap cleanup EXIT$" "$HOME/x.sh" &&
  grep -qF '\''/run/user/$(id -u)'\'' "$HOME/x.sh" &&
  grep -qF '\''rm -f "$TMPDIR"/.X11-unix/X*'\'' "$HOME/x.sh" &&
  grep -q "pulseaudio --kill.*pkill -KILL -x pulseaudio" "$HOME/x.sh" &&
  ! grep -q "pkill.*dbus" "$HOME/x.sh" &&
  grep -q "chmod 700 ~/.runtime /tmp/mesa_cache" "$HOME/x.sh" &&
  ! grep -q "^virgl_test_server_android " "$HOME/x.sh" &&
  ! grep -q "pkill.*dbus" "$HOME/.bashrc" &&
  grep -q "login debian --shared-tmp --user alice" "$HOME/.bashrc" &&
  grep -q "droot=.*login debian --shared-tmp" "$HOME/.bashrc"
' _ "$ROOT"; then
  ok "Zink launcher and aliases preserve user and backend boundaries"
else
  not_ok "Zink launcher and aliases preserve user and backend boundaries"
fi

if env TERNUX_STATE_DIR="$TMP/state-virgl" HOME="$TMP/home-virgl" bash -c '
  mkdir -p "$HOME"
  . "$1/lib/phases.sh"
  tnx_phase_launcher bob virgl bn_BD.UTF-8 >/dev/null
  bash -n "$HOME/x.sh" &&
  grep -q "^virgl_test_server_android " "$HOME/x.sh" &&
  ! grep -q "MESA_LOADER_DRIVER_OVERRIDE=zink" "$HOME/x.sh"
' _ "$ROOT"; then
  ok "VirGL launcher starts only the fallback renderer"
else
  not_ok "VirGL launcher starts only the fallback renderer"
fi

# English and Bengali manual launchers must stay executable and preserve the
# generated Zink launcher's cleanup, runtime-UID, environment and permission
# invariants.
manual_en="$TMP/manual-en-launcher.sh"
manual_bn="$TMP/manual-bn-launcher.sh"
if python3 - "$ROOT/docs/MANUAL.md" "$manual_en" "$ROOT/bn/docs/MANUAL.md" "$manual_bn" <<'PY'
from pathlib import Path
import re, sys
for source, output in ((sys.argv[1], sys.argv[2]), (sys.argv[3], sys.argv[4])):
    blocks = re.findall(r'^```bash\n(.*?)^```[ \t]*$', Path(source).read_text(), re.M | re.S)
    hits = [block for block in blocks if block.startswith('#!/data/data/com.termux/files/usr/bin/bash')]
    if len(hits) != 1:
        raise SystemExit(f'{source}: expected one launcher, found {len(hits)}')
    Path(output).write_text(hits[0])
PY
then
  if bash -n "$manual_en" && bash -n "$manual_bn" && cmp -s "$manual_en" "$manual_bn" &&
     grep -q '^trap cleanup EXIT$' "$manual_en" &&
     grep -qF '/run/user/$(id -u)' "$manual_en" &&
     grep -qF 'rm -f "$TMPDIR"/.X11-unix/X*' "$manual_en" &&
     grep -q 'pulseaudio --kill.*pkill -KILL -x pulseaudio' "$manual_en" &&
     ! grep -q 'pkill.*dbus' "$manual_en" &&
     grep -q -- '--env MESA_LOADER_DRIVER_OVERRIDE=zink' "$manual_en" &&
     grep -q 'chmod 700 ~/.runtime /tmp/mesa_cache' "$manual_en" &&
     ! grep -q '^virgl_test_server_android ' "$manual_en"; then
    ok "manual Zink launchers match generated launcher invariants"
  else
    not_ok "manual Zink launchers match generated launcher invariants"
  fi
else
  not_ok "manual Zink launchers match generated launcher invariants"
fi

# Required failure must stop dependants and only successful phases are marked.
if env TERNUX_STATE_DIR="$TMP/state-required" HOME="$TMP/home-required" bash -c '
  . "$1/lib/phases.sh"
  order="$2/order-required"
  tnx_require_termux(){ :; }; tnx_confirm(){ :; }
  tnx_banner(){ :; }; tnx_phase_header(){ :; }; tnx_celebrate(){ :; }
  tnx_summary_box(){ :; }; tnx_next_steps(){ :; }; tnx_log_error(){ :; }
  tnx_phase_preflight(){ echo preflight >> "$order"; }
  tnx_phase_packages(){ echo packages >> "$order"; return 7; }
  tnx_phase_cli(){ echo cli >> "$order"; }
  set +e
  tnx_install --yes >/dev/null 2>&1
  rc=$?
  set -e
  test "$rc" -eq 7 &&
  test "$(tr "\n" " " < "$order")" = "preflight packages " &&
  tnx_state_done phase_preflight &&
  ! tnx_state_done phase_packages
' _ "$ROOT" "$TMP"; then
  ok "required phase failure stops dependants and is not marked complete"
else
  not_ok "required phase failure stops dependants and is not marked complete"
fi

# Optional failure is retained as final nonzero status but verification runs.
if env TERNUX_STATE_DIR="$TMP/state-optional" HOME="$TMP/home-optional" bash -c '
  . "$1/lib/phases.sh"
  order="$2/order-optional"
  tnx_require_termux(){ :; }; tnx_confirm(){ :; }
  tnx_banner(){ :; }; tnx_phase_header(){ :; }; tnx_celebrate(){ :; }
  tnx_summary_box(){ :; }; tnx_next_steps(){ :; }; tnx_log_error(){ :; }
  for name in preflight packages cli debian gpu audio_fonts launcher aliases phantom verify; do
    eval "tnx_phase_${name}(){ echo ${name} >> \"\$order\"; }"
  done
  tnx_phase_extras(){ echo extras >> "$order"; return 9; }
  set +e
  tnx_install --yes --with-dev >/dev/null 2>&1
  rc=$?
  set -e
  test "$rc" -eq 9 &&
  grep -qx verify "$order" &&
  ! tnx_state_done phase_extras &&
  tnx_state_done phase_verify
' _ "$ROOT" "$TMP"; then
  ok "optional failure continues to verification and remains nonzero"
else
  not_ok "optional failure continues to verification and remains nonzero"
fi

# The wrapper must not silently force --yes for local invocation.
if grep -q 'tnx_install --yes' "$ROOT/install.sh"; then
  not_ok "install wrapper passes --yes only when requested"
else
  ok "install wrapper passes --yes only when requested"
fi

# Direct CLI installation rejects malformed options before any phase starts.
if env TERNUX_STATE_DIR="$TMP/state-install-args" HOME="$TMP/home-install-args" bash -c '
  . "$1/lib/phases.sh"
  reached=0; tnx_require_termux(){ reached=1; }
  set +e
  tnx_install --user >/dev/null 2>&1; missing=$?
  tnx_install --not-an-option >/dev/null 2>&1; unknown=$?
  set -e
  [ "$missing" -eq 2 ] && [ "$unknown" -eq 2 ] && [ "$reached" -eq 0 ]
' _ "$ROOT"; then
  ok "install rejects missing values and unknown options before phases"
else
  not_ok "install rejects missing values and unknown options before phases"
fi

# Android child-process reporting distinguishes enabled, disabled and unknown
# instead of treating every unreadable value as enabled.
for phantom_case in enabled disabled unknown; do
  if env TERNUX_STATE_DIR="$TMP/state-phantom-$phantom_case" \
    HOME="$TMP/home-phantom-$phantom_case" bash -c '
      . "$1/lib/phases.sh"
      phantom_case="$2"
      getprop(){ echo 34; }
      tnx_detect_phantom_killer(){ echo "$phantom_case"; }
      out="$(tnx_phase_phantom)"
      case "$phantom_case" in
        enabled)  grep -q "reported as enabled" <<<"$out" && grep -q "Signal 9 can also mean memory pressure" <<<"$out" ;;
        disabled) grep -q "reported as disabled" <<<"$out" && ! grep -q "Could not read" <<<"$out" ;;
        unknown)  grep -q "Could not read.*do not assume" <<<"$out" && ! grep -q "reported as enabled" <<<"$out" ;;
      esac
    ' _ "$ROOT" "$phantom_case"; then
    ok "phantom setting reports $phantom_case conservatively"
  else
    not_ok "phantom setting reports $phantom_case conservatively"
  fi
done

# Doctor must recommend differential diagnosis, not a categorical system-wide
# safeguard change, when the readable monitor state is enabled.
if env TERNUX_STATE_DIR="$TMP/state-doctor" HOME="$TMP/home-doctor" bash -c '
  mkdir -p "$HOME" "$TERNUX_STATE_DIR"
  printf "backend=virgl\n" > "$TERNUX_STATE_DIR/state"
  : > "$HOME/x.sh"
  . "$1/lib/doctor.sh"
  TERNUX_JSON=1
  tnx_is_termux(){ :; }
  tnx_has_cmd(){ return 0; }
  proot-distro(){ [ "${1:-}" = list ] && echo "debian installed"; }
  tnx_detect_storage_gb(){ echo 10; }
  tnx_detect_vulkan(){ echo yes; }
  tnx_detect_gpu(){ echo Mali; }
  tnx_detect_backend(){ echo virgl; }
  tnx_detect_renderer(){ echo unknown; }
  tnx_detect_phantom_killer(){ echo enabled; }
  tnx_detect_android_version(){ echo 14; }
  tnx_detect_arch(){ echo aarch64; }
  out="$(tnx_cmd_doctor)" || exit
  python3 -c '\''import json,sys
x=json.loads(sys.argv[1])
a=" ".join(x["recommended_actions"])
assert "Review Android process restrictions and other Signal 9 causes" in a
assert "Disable" not in a
assert x["backend"] == "virgl"'\'' "$out"
' _ "$ROOT"; then
  ok "doctor emits a qualified Android process action"
else
  not_ok "doctor emits a qualified Android process action"
fi

# Matching stored target hashes are treated as healthy; a changed target
# invokes the validated GPU phase instead of trusting file presence alone.
for hash_case in matching changed; do
  if env TERNUX_STATE_DIR="$TMP/state-hash-$hash_case" \
    HOME="$TMP/home-hash-$hash_case" bash -c '
      mkdir -p "$HOME" "$TERNUX_STATE_DIR"
      cat > "$HOME/x.sh" <<"EOF"
#!/usr/bin/env bash
# --user alice
export MESA_LOADER_DRIVER_OVERRIDE=zink
EOF
      chmod +x "$HOME/x.sh"
      . "$1/lib/repair.sh"
      hash_case="$2"
      scratch="$3"
      _tnx_repair_kgsl_available(){ :; }
      tnx_has_cmd(){ [ "$1" = proot-distro ]; }
      tnx_state_get(){
        case "$1" in
          backend) echo zink ;;
          freedreno_driver_sha) echo expected-driver ;;
          freedreno_icd_sha) echo expected-icd ;;
          user) echo alice ;;
          locale) echo en_US.UTF-8 ;;
        esac
      }
      tnx_state_set(){ :; }
      proot-distro(){
        case "$*" in
          *libvulkan_freedreno.so*) [ "$hash_case" = matching ] && echo "expected-driver  file" || echo "changed-driver  file" ;;
          *freedreno_icd.aarch64.json*) echo "expected-icd  file" ;;
        esac
      }
      tnx_phase_gpu(){ echo gpu > "$scratch/gpu-called"; }
      _TNX_REPAIR_CHANGED=0
      _tnx_repair_backend >/dev/null || exit
      if [ "$hash_case" = matching ]; then
        [ ! -e "$scratch/gpu-called" ] && [ "$_TNX_REPAIR_CHANGED" = 0 ]
      else
        [ -e "$scratch/gpu-called" ] && [ "$_TNX_REPAIR_CHANGED" = 1 ]
      fi
    ' _ "$ROOT" "$hash_case" "$TMP"; then
    ok "repair handles $hash_case validated Turnip target hashes"
  else
    not_ok "repair handles $hash_case validated Turnip target hashes"
  fi
done

# Backend repair installs a missing VirGL host component, applies canonical
# state, and regenerates a launcher whose backend does not match.
if env TERNUX_STATE_DIR="$TMP/state-backend" HOME="$TMP/home-backend" bash -c '
  mkdir -p "$HOME" "$TERNUX_STATE_DIR"
  . "$1/lib/repair.sh"
  scratch="$2"
  state_log="$scratch/state-log"
  tnx_state_get(){ case "$1" in backend) echo virgl;; user) echo bob;; locale) echo bn_BD.UTF-8;; esac; }
  tnx_state_set(){ printf "%s=%s\n" "$1" "$2" >> "$state_log"; }
  tnx_has_cmd(){
    case "$1" in
      virgl_test_server_android) [ -e "$scratch/virgl-installed" ] ;;
      *) return 1 ;;
    esac
  }
  pkg(){ [ "$*" = "install -y virglrenderer-android" ] && : > "$scratch/virgl-installed"; }
  tnx_phase_launcher(){ printf "%s|%s|%s\n" "$1" "$2" "$3" > "$scratch/launcher-args"; }
  _TNX_REPAIR_CHANGED=0
  _tnx_repair_backend >/dev/null &&
  grep -qx "backend=virgl" "$scratch/state-log" &&
  grep -qx "bob|virgl|bn_BD.UTF-8" "$scratch/launcher-args" &&
  [ "$_TNX_REPAIR_CHANGED" = 1 ]
' _ "$ROOT" "$TMP"; then
  ok "repair applies VirGL and regenerates the backend launcher"
else
  not_ok "repair applies VirGL and regenerates the backend launcher"
fi

# The legacy doctor/repair route may call the GPU phase with `auto`. On a
# non-KGSL device that must resolve to VirGL instead of entering the Turnip
# download path.
if env TERNUX_STATE_DIR="$TMP/state-auto-virgl" HOME="$TMP/home-auto-virgl" bash -c '
  [ ! -e /dev/kgsl-3d0 ] || exit 77
  . "$1/lib/phases.sh"
  marker="$2/turnip-auto-called"
  tnx_has_cmd(){ [ "$1" = virgl_test_server_android ]; }
  tnx_resolve_freedreno_asset(){ : > "$marker"; return 1; }
  tnx_phase_gpu auto >/dev/null && [ ! -e "$marker" ]
' _ "$ROOT" "$TMP"; then
  ok "auto GPU repair resolves a non-KGSL device to VirGL"
else
  not_ok "auto GPU repair resolves a non-KGSL device to VirGL"
fi

# Exercise the legacy install.sh doctor dispatcher with isolated local library
# mocks. On this non-KGSL test host, both GPU repair and verification must
# receive the resolved VirGL backend rather than the literal `auto` value.
doctor_wrapper="$TMP/doctor-wrapper"
mkdir -p "$doctor_wrapper/lib"
cp "$ROOT/install.sh" "$doctor_wrapper/install.sh"
cat > "$doctor_wrapper/lib/core.sh" <<'EOF'
TERNUX_VERSION=1.3.0
tnx_info(){ :; }; tnx_ok(){ :; }; tnx_warn(){ :; }; tnx_fail(){ :; }
tnx_debug(){ :; }; tnx_step(){ :; }; tnx_confirm(){ :; }
tnx_state_done(){ [ "$1" != phase_gpu ]; }
tnx_state_mark(){ printf '%s\n' "$1" >> "$DOCTOR_MARKS"; }
tnx_state_clear(){ :; }; tnx_require_termux(){ :; }
EOF
cat > "$doctor_wrapper/lib/phases.sh" <<'EOF'
tnx_phase_preflight(){ [ "${FAIL_PREFLIGHT:-0}" != 1 ] || return 9; }
tnx_phase_packages(){ :; }; tnx_phase_debian(){ :; }
tnx_phase_audio_fonts(){ :; }; tnx_phase_launcher(){ :; }; tnx_phase_aliases(){ :; }
tnx_phase_gpu(){ [ "${FAIL_GPU:-0}" != 1 ] || return 7; printf '%s\n' "$1" > "$DOCTOR_GPU"; }
tnx_phase_verify(){ printf '%s\n' "$2" > "$DOCTOR_VERIFY"; }
EOF
: > "$doctor_wrapper/lib/ui.sh"
if [ ! -e /dev/kgsl-3d0 ] && env DOCTOR_GPU="$TMP/doctor-gpu" \
  DOCTOR_VERIFY="$TMP/doctor-verify" DOCTOR_MARKS="$TMP/doctor-marks" \
  HOME="$TMP/home-doctor-wrapper" bash "$doctor_wrapper/install.sh" --doctor --fix --backend auto >/dev/null &&
  grep -qx virgl "$TMP/doctor-gpu" && grep -qx virgl "$TMP/doctor-verify" &&
  grep -qx phase_gpu "$TMP/doctor-marks"; then
  ok "legacy doctor fix propagates the resolved backend"
else
  not_ok "legacy doctor fix propagates the resolved backend"
fi

# The standalone parser returns usage status 2 for missing values, including
# when the following token is another option. Doctor repair must stop before
# every mutation when preflight fails.
bash "$doctor_wrapper/install.sh" --user >/dev/null 2>&1; user_rc=$?
bash "$doctor_wrapper/install.sh" --locale --status >/dev/null 2>&1; locale_rc=$?
bash "$doctor_wrapper/install.sh" --backend --doctor >/dev/null 2>&1; backend_rc=$?
if [ "$user_rc" -eq 2 ] && [ "$locale_rc" -eq 2 ] && [ "$backend_rc" -eq 2 ]; then
  ok "standalone installer reports missing option values as usage errors"
else
  not_ok "standalone installer reports missing option values as usage errors"
fi

rm -f "$TMP/doctor-gpu" "$TMP/doctor-verify" "$TMP/doctor-marks"
env FAIL_PREFLIGHT=1 DOCTOR_GPU="$TMP/doctor-gpu" DOCTOR_VERIFY="$TMP/doctor-verify" \
  DOCTOR_MARKS="$TMP/doctor-marks" HOME="$TMP/home-doctor-wrapper" \
  bash "$doctor_wrapper/install.sh" --doctor --fix --backend auto >/dev/null 2>&1
preflight_rc=$?
if [ "$preflight_rc" -eq 9 ] && [ ! -e "$TMP/doctor-gpu" ] &&
   [ ! -e "$TMP/doctor-verify" ] && [ ! -e "$TMP/doctor-marks" ]; then
  ok "doctor fix aborts before repair phases when preflight fails"
else
  not_ok "doctor fix aborts before repair phases when preflight fails"
fi

rm -f "$TMP/doctor-gpu" "$TMP/doctor-verify" "$TMP/doctor-marks"
env FAIL_GPU=1 DOCTOR_GPU="$TMP/doctor-gpu" DOCTOR_VERIFY="$TMP/doctor-verify" \
  DOCTOR_MARKS="$TMP/doctor-marks" HOME="$TMP/home-doctor-wrapper" \
  bash "$doctor_wrapper/install.sh" --doctor --fix --backend virgl >/dev/null 2>&1
doctor_phase_rc=$?
if [ "$doctor_phase_rc" -eq 7 ] && [ ! -e "$TMP/doctor-gpu" ] &&
   grep -qx virgl "$TMP/doctor-verify" && [ ! -e "$TMP/doctor-marks" ]; then
  ok "doctor fix preserves a failed repair phase status after verification"
else
  not_ok "doctor fix preserves a failed repair phase status after verification"
fi

# Profile names are filenames and must not traverse outside the state profile
# directory. Valid conservative names must continue to save and load.
if env TERNUX_STATE_DIR="$TMP/state-profile-names" HOME="$TMP/home-profile-names" bash -c '
  mkdir -p "$HOME" "$TERNUX_STATE_DIR"
  . "$1/lib/profile.sh"
  tnx_detect_android_version(){ echo 14; }; tnx_detect_arch(){ echo aarch64; }
  tnx_detect_model(){ echo phone; }; tnx_detect_manufacturer(){ echo vendor; }
  tnx_detect_ram_gb(){ echo 8; }; tnx_detect_storage_gb(){ echo 10; }
  tnx_detect_termux_version(){ echo current; }; tnx_detect_gpu(){ echo Adreno; }
  tnx_detect_vulkan(){ echo yes; }; tnx_detect_backend(){ echo zink; }
  tnx_detect_phantom_killer(){ echo unknown; }
  for op in save load compare; do
    set +e; tnx_cmd_profile "$op" ../../escaped >/dev/null 2>&1; rc=$?; set -e
    [ "$rc" -eq 2 ] || exit
  done
  [ ! -e "$2/escaped" ] && [ ! -e "$TERNUX_STATE_DIR/escaped" ] &&
  tnx_cmd_profile save phone-1 >/dev/null &&
  [ -f "$TERNUX_STATE_DIR/profiles/phone-1" ] &&
  tnx_cmd_profile load phone-1 >/dev/null
' _ "$ROOT" "$TMP"; then
  ok "profile names cannot traverse outside the profiles directory"
else
  not_ok "profile names cannot traverse outside the profiles directory"
fi

# A failure in one repair step does not suppress later steps, but the aggregate
# command remains nonzero and its JSON reports a partial result.
if env TERNUX_STATE_DIR="$TMP/state-repair-aggregate" HOME="$TMP/home-repair-aggregate" bash -c '
  mkdir -p "$HOME" "$TERNUX_STATE_DIR"
  . "$1/lib/repair.sh"
  tnx_require_termux(){ :; }
  marker="$2/repair-order"
  _tnx_repair_curl(){ echo curl >> "$marker"; return 9; }
  _tnx_repair_x11(){ echo x11 >> "$marker"; }
  _tnx_repair_backend(){ echo backend >> "$marker"; }
  _tnx_repair_launcher(){ echo launcher >> "$marker"; }
  _tnx_repair_mesa_cache(){ echo cache >> "$marker"; }
  _tnx_repair_pulseaudio(){ echo audio >> "$marker"; }
  TERNUX_JSON=1
  set +e
  out="$(tnx_cmd_repair)"; rc=$?
  set -e
  [ "$rc" -eq 1 ] && [ "$(wc -l < "$marker")" -eq 6 ] &&
  python3 -c '\''import json,sys; x=json.loads(sys.argv[1]); assert x["status"] == "partial"'\'' "$out"
' _ "$ROOT" "$TMP"; then
  ok "repair aggregates step failures and keeps running"
else
  not_ok "repair aggregates step failures and keeps running"
fi

# Scoped uninstall is validated only in a temporary home with mocked container
# operations: cancellation preserves data, and explicit --yes removes only the
# requested mocked container.
if env TERNUX_STATE_DIR="$TMP/state-uninstall" HOME="$TMP/home-uninstall" bash -c '
  mkdir -p "$HOME" "$TERNUX_STATE_DIR" "$2"
  : > "$HOME/x.sh"
  . "$1/lib/uninstall.sh"
  scratch="$2"
  _tnx_uninstall_stop(){ echo stopped >> "$scratch/uninstall-log"; }
  tnx_has_cmd(){ [ "$1" = proot-distro ]; }
  proot-distro(){
    [ "$1" = list ] && { echo "debian installed"; return; }
    [ "$1" = remove ] && echo removed >> "$scratch/uninstall-log"
  }
  _tnx_uninstall_confirm(){ [ "${TERNUX_YES:-0}" = 1 ]; }
  set +e
  tnx_cmd_uninstall container >/dev/null; cancelled=$?
  set -e
  [ "$cancelled" -eq 1 ] && grep -qx stopped "$scratch/uninstall-log" &&
  ! grep -q removed "$scratch/uninstall-log" || exit
  : > "$scratch/uninstall-log"
  tnx_cmd_uninstall container --yes >/dev/null &&
  grep -qx stopped "$scratch/uninstall-log" && grep -qx removed "$scratch/uninstall-log" &&
  [ -e "$HOME/x.sh" ] && [ -d "$TERNUX_STATE_DIR" ]
' _ "$ROOT" "$TMP"; then
  ok "scoped uninstall confirms container deletion and preserves other scopes"
else
  not_ok "scoped uninstall confirms container deletion and preserves other scopes"
fi

# Alias removal uses a same-directory replacement, preserves file mode, and
# refuses malformed marker order or symlink targets without truncation.
if env TERNUX_STATE_DIR="$TMP/state-uninstall-alias" HOME="$TMP/home-uninstall-alias" bash -c '
  mkdir -p "$HOME" "$TERNUX_STATE_DIR"
  . "$1/lib/uninstall.sh"
  cat > "$HOME/.bashrc" <<"EOF"
before
# ==== TERNUX ALIASES ====
alias x="~/x.sh"
# ==== END TERNUX ALIASES ====
after
EOF
  chmod 640 "$HOME/.bashrc"; : > "$HOME/x.sh"
  tnx_cmd_uninstall launcher >/dev/null &&
  [ ! -e "$HOME/x.sh" ] && [ "$(stat -c %a "$HOME/.bashrc")" = 640 ] &&
  [ "$(cat "$HOME/.bashrc")" = $'\''before\nafter'\'' ] || exit

  printf "%s\n%s\n%s\n" "# ==== END TERNUX ALIASES ====" keep "# ==== TERNUX ALIASES ====" > "$HOME/.zshrc"
  printf "%s\n" managed-elsewhere > "$HOME/bashrc-target"
  rm -f "$HOME/.bashrc"; ln -s "$HOME/bashrc-target" "$HOME/.bashrc"
  before_zsh="$(sha256sum "$HOME/.zshrc")"
  before_target="$(sha256sum "$HOME/bashrc-target")"
  set +e; tnx_cmd_uninstall launcher >/dev/null; rc=$?; set -e
  [ "$rc" -ne 0 ] && [ -L "$HOME/.bashrc" ] &&
  [ "$(sha256sum "$HOME/.zshrc")" = "$before_zsh" ] &&
  [ "$(sha256sum "$HOME/bashrc-target")" = "$before_target" ] &&
  ! compgen -G "$HOME/.zshrc.ternux-uninstall.*" >/dev/null
' _ "$ROOT"; then
  ok "scoped alias uninstall is atomic and preserves malformed files"
else
  not_ok "scoped alias uninstall is atomic and preserves malformed files"
fi

# The published standalone route must fetch and syntax-check the same scoped
# implementation when neither a CLI nor a local checkout is available. Use a
# mock downloader and temporary home; the state scope is non-destructive.
if env HOME="$TMP/home-uninstall-remote" PREFIX="$TMP/empty-prefix" \
       MOCK_REPO="$ROOT" MOCK_LOG="$TMP/remote-downloads" bash -c '
  set -e
  mkdir -p "$HOME" "$2/mockbin" "$PREFIX/bin" "$2/standalone"
  cp "$1/uninstall.sh" "$2/standalone/uninstall.sh"
  cat > "$2/mockbin/curl" <<"EOF"
#!/usr/bin/env bash
set -e
url=""; dest=""
while [ $# -gt 0 ]; do
  case "$1" in
    -o) dest="$2"; shift 2 ;;
    http*) url="$1"; shift ;;
    *) shift ;;
  esac
done
case "$url" in
  */lib/core.sh) src="$MOCK_REPO/lib/core.sh" ;;
  */lib/uninstall.sh) src="$MOCK_REPO/lib/uninstall.sh" ;;
  *) exit 22 ;;
esac
printf "%s\n" "$url" >> "$MOCK_LOG"
cp "$src" "$dest"
EOF
  chmod +x "$2/mockbin/curl"
  PATH="$2/mockbin:$PATH" bash "$2/standalone/uninstall.sh" state --yes >/dev/null
  [ "$(wc -l < "$MOCK_LOG")" -eq 2 ] &&
  grep -q "/lib/core.sh$" "$MOCK_LOG" && grep -q "/lib/uninstall.sh$" "$MOCK_LOG" &&
  grep -q "pkill -KILL -x pulseaudio" "$1/lib/uninstall.sh" &&
  ! grep -q "pkill.*dbus" "$1/lib/uninstall.sh"
' _ "$ROOT" "$TMP"; then
  ok "standalone uninstall loads the scoped implementation safely"
else
  not_ok "standalone uninstall loads the scoped implementation safely"
fi

# Public structured-output paths must emit exactly one parseable object and
# canonicalize legacy backend state. This is an executable parse probe, not a
# grep for JSON-looking text.
if env TERNUX_STATE_DIR="$TMP/state-json" HOME="$TMP/home-json" bash -c '
  mkdir -p "$HOME" "$TERNUX_STATE_DIR"
  printf "backend=zink-turnip\n" > "$TERNUX_STATE_DIR/state"
  for cmd in info backend state profile verify; do
    out="$(bash "$1/bin/ternux" "$cmd" --json 2>/dev/null)" || [ "$cmd" = verify ] || exit
    CMD="$cmd" JSON_OUT="$out" python3 -c '\''
import json, os
raw=os.environ["JSON_OUT"]
dec=json.JSONDecoder()
obj,end=dec.raw_decode(raw)
assert not raw[end:].strip(), "trailing non-JSON output"
assert obj["command"] == os.environ["CMD"]
for key in ("status", "timestamp", "version"):
    assert key in obj
if "backend" in obj:
    assert obj["backend"] != "zink-turnip"
'\'' || exit
  done
  out="$(bash "$1/bin/ternux" verify --json 2>/dev/null)"; rc=$?
  [ "$rc" -ne 0 ] && JSON_OUT="$out" python3 -c '\''
import json, os
obj=json.loads(os.environ["JSON_OUT"])
assert obj["command"] == "verify"
assert obj["status"] == "failed"
'\''
' _ "$ROOT"; then
  ok "documented JSON paths are clean, parseable and canonical"
else
  not_ok "documented JSON paths are clean, parseable and canonical"
fi

# Verification must fail—not merely warn—when Debian is absent or when its
# desktop-service/passwordless-sudo probe fails. Both paths must still emit one
# valid structured object.
if env TERNUX_STATE_DIR="$TMP/state-verify-failures" HOME="$TMP/home-verify-failures" bash -c '
  mkdir -p "$HOME" "$TERNUX_STATE_DIR"
  : > "$HOME/x.sh"; chmod +x "$HOME/x.sh"
  . "$1/lib/doctor.sh"
  tnx_has_cmd(){ return 0; }
  tnx_state_get(){ [ "$1" = backend ] && echo virgl; }
  for mode in absent services; do
    proot-distro(){
      if [ "$1" = list ]; then
        [ "$mode" = services ] && echo "debian installed"
        return 0
      fi
      return 1
    }
    TERNUX_JSON=1
    set +e; out="$(tnx_cmd_verify 2>/dev/null)"; rc=$?; set -e
    [ "$rc" -eq 1 ] || exit
    MODE="$mode" JSON_OUT="$out" python3 -c '\''
import json, os
obj=json.loads(os.environ["JSON_OUT"])
assert obj["command"] == "verify" and obj["status"] == "failed"
needle = "debian:not_installed" if os.environ["MODE"] == "absent" else "debian_services:failed"
assert needle in obj["checks"].split(",")
'\'' || exit
  done
' _ "$ROOT"; then
  ok "verification failures return nonzero structured results"
else
  not_ok "verification failures return nonzero structured results"
fi

# Pulse setup covers a fresh file, exact legacy migration, idempotence, custom
# listener refusal (even beside a secure line), and atomic write failure.
if env TERNUX_STATE_DIR="$TMP/state-pulse" HOME="$TMP/home-pulse" bash -c '
  mkdir -p "$HOME"
  . "$1/lib/phases.sh"
  old="load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 port=4713"
  new="load-module module-native-protocol-tcp listen=127.0.0.1 auth-ip-acl=127.0.0.1 auth-anonymous=1 port=4713"
  fresh="$2/fresh.pa"; newfile="$2/new.pa"; legacy="$2/legacy.pa"
  custom="$2/custom.pa"; failed="$2/failed.pa"; target="$2/target.pa"; link="$2/link.pa"

  : > "$fresh"; chmod 640 "$fresh"
  _tnx_configure_pulse_bridge "$fresh" >/dev/null && [ "$_TNX_PULSE_CHANGED" = 1 ] || exit
  [ "$(stat -c %a "$fresh")" = 640 ] &&
  [ "$(grep -cxF "$new" "$fresh")" -eq 1 ] &&
  grep -qxF "load-module module-opensles-sink sink_name=Speaker" "$fresh" &&
  grep -qxF "set-default-sink Speaker" "$fresh" || exit

  _tnx_configure_pulse_bridge "$newfile" >/dev/null &&
  [ "$_TNX_PULSE_CHANGED" = 1 ] && [ "$(stat -c %a "$newfile")" = 600 ] || exit
  before="$(sha256sum "$fresh")"
  _tnx_configure_pulse_bridge "$fresh" >/dev/null && [ "$_TNX_PULSE_CHANGED" = 0 ] &&
  [ "$(sha256sum "$fresh")" = "$before" ] || exit

  printf "%s\n%s\n" "$old" "$old" > "$legacy"
  _tnx_configure_pulse_bridge "$legacy" >/dev/null && [ "$_TNX_PULSE_CHANGED" = 1 ] &&
  [ "$(grep -cxF "$new" "$legacy")" -eq 1 ] && ! grep -qxF "$old" "$legacy" || exit

  printf "%s\n%s\n" "$new" "  load-module module-native-protocol-tcp listen=0.0.0.0 port=4713" > "$custom"
  before="$(cat "$custom")"
  set +e; _tnx_configure_pulse_bridge "$custom" >/dev/null; rc=$?; set -e
  [ "$rc" -ne 0 ] && [ "$(cat "$custom")" = "$before" ] || exit

  printf "%s\n" untouched > "$target"; ln -s "$target" "$link"
  set +e; _tnx_configure_pulse_bridge "$link" >/dev/null; rc=$?; set -e
  [ "$rc" -ne 0 ] && [ "$(cat "$target")" = untouched ] || exit

  printf "%s\n" "$old" > "$failed"; before="$(cat "$failed")"
  mv(){ return 1; }
  set +e; _tnx_configure_pulse_bridge "$failed" >/dev/null; rc=$?; set -e
  [ "$rc" -ne 0 ] && [ "$(cat "$failed")" = "$before" ] &&
  ! compgen -G "${failed}.ternux.*" >/dev/null
' _ "$ROOT" "$TMP"; then
  ok "Pulse bridge setup is secure, idempotent, guarded and atomic"
else
  not_ok "Pulse bridge setup is secure, idempotent, guarded and atomic"
fi

# CLI session cleanup must not kill unrelated D-Bus or broad PulseAudio process
# matches. If graceful PulseAudio shutdown fails, only the exact process name is
# forced, and all managed socket forms are covered.
if env TERNUX_STATE_DIR="$TMP/state-desktop-stop" HOME="$TMP/home-desktop-stop" \
  TMPDIR="$TMP/desktop-stop-tmp" bash -c '
    mkdir -p "$HOME" "$TMPDIR/.X11-unix" "$TMPDIR/.pulse-test"
    : > "$TMPDIR/.X11-unix/X0"; : > "$TMPDIR/.X0-lock"; : > "$TMPDIR/.pulse-test/native"
    log="$2/desktop-stop.log"
    . "$1/lib/desktop.sh"
    pgrep(){ return 0; }
    pkill(){ printf "pkill %s\n" "$*" >> "$log"; }
    pulseaudio(){ printf "pulseaudio %s\n" "$*" >> "$log"; return 1; }
    tnx_has_cmd(){ return 1; }
    TERNUX_JSON=1
    out="$(tnx_cmd_stop)" || exit
    JSON_OUT="$out" python3 -c '\''
import json, os
obj=json.loads(os.environ["JSON_OUT"])
assert obj["command"] == "stop" and obj["status"] == "ok"
'\'' &&
    grep -qx "pulseaudio --kill" "$log" &&
    grep -qx "pkill -KILL -x pulseaudio" "$log" &&
    ! grep -qi dbus "$log" &&
    ! grep -q "pkill .*pulseaudio.*-f\|-f .*pulseaudio" "$log" &&
    [ ! -e "$TMPDIR/.X11-unix/X0" ] && [ ! -e "$TMPDIR/.X0-lock" ] &&
    [ ! -e "$TMPDIR/.pulse-test/native" ]
  ' _ "$ROOT" "$TMP"; then
  ok "desktop stop uses scoped process and socket cleanup"
else
  not_ok "desktop stop uses scoped process and socket cleanup"
fi

# Vulkan detection must not turn a missing glob into a false positive.
if env TERNUX_STATE_DIR="$TMP/state-vulkan" HOME="$TMP/home-vulkan" \
  PREFIX="$TMP/empty-prefix" bash -c '
    mkdir -p "$PREFIX/lib"
    . "$1/lib/detect.sh"
    tnx_has_cmd(){ return 1; }
    [ "$(tnx_detect_vulkan)" = no ]
  ' _ "$ROOT"; then
  ok "Vulkan detection does not accept a missing library glob"
else
  not_ok "Vulkan detection does not accept a missing library glob"
fi

printf '1..%d\n' "$((pass + fail))"
printf '# pass %d\n# fail %d\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
