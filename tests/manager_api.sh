#!/usr/bin/env bash
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
pass=0; fail=0
ok(){ printf 'ok %d - %s\n' "$((pass+fail+1))" "$1"; pass=$((pass+1)); }
not_ok(){ printf 'not ok %d - %s\n' "$((pass+fail+1))" "$1"; fail=$((fail+1)); }
printf 'TAP version 13\n'

if env TERNUX_STATE_DIR="$TMP/state" HOME="$TMP/home" TMPDIR="$TMP/tmp" bash -c '
  . "$1/lib/manager.sh"
  tnx_has_cmd(){ [ "$1" = proot-distro ]; }
  pgrep(){ return 1; }
  proot-distro(){ printf "ubuntu\ndebian\ndebian\nunsafe/name\nalpine\nimage_1\n"; }
  _tnx_running_guest_sessions(){ printf "debian\nalpine\n"; }
  tnx_distro_state_set debian display 0 || exit 1
  tnx_workspace_registry_update debian READY 0 || exit 1
  guests="$(TERNUX_JSON=1 tnx_cmd_manager guests)" || exit 1
  displays="$(TERNUX_JSON=1 tnx_cmd_manager displays)" || exit 1
  status="$(TERNUX_JSON=1 tnx_cmd_manager status)" || exit 1
  capabilities="$(TERNUX_JSON=1 tnx_cmd_manager capabilities)" || exit 1
  printf "%s\n---DISPLAYS---\n%s\n---STATUS---\n%s\n---CAPS---\n%s\n" "$guests" "$displays" "$status" "$capabilities"
' _ "$ROOT" > "$TMP/output" 2>/dev/null && python3 - "$TMP/output" "$ROOT" <<'PY'
import datetime,json,re,sys
text=open(sys.argv[1]).read(); guests,rest=text.split('\n---DISPLAYS---\n')
display_part,rest=rest.split('\n---STATUS---\n'); status_part,capabilities=rest.split('\n---CAPS---\n')
g=json.loads(guests); d=json.loads(display_part); s=json.loads(status_part); c=json.loads(capabilities); root=sys.argv[2]
status_schema=json.load(open(root+'/docs/v3/schemas/manager-status-v1.schema.json'))
guests_schema=json.load(open(root+'/docs/v3/schemas/manager-guests-v1.schema.json'))
capabilities_schema=json.load(open(root+'/docs/v3/schemas/manager-capabilities-v1.schema.json'))
displays_schema=json.load(open(root+'/docs/v3/schemas/manager-displays-v1.schema.json'))
def validate(value,schema,document):
    if '$ref' in schema:
        return validate(value,document['$defs'][schema['$ref'].split('/')[-1]],document)
    if 'oneOf' in schema:
        matches=0
        for option in schema['oneOf']:
            try: validate(value,option,document); matches+=1
            except AssertionError: pass
        assert matches==1
    if 'type' in schema:
        types=[schema['type']] if isinstance(schema['type'],str) else schema['type']
        matches={'object':lambda x:isinstance(x,dict),'array':lambda x:isinstance(x,list),
                 'string':lambda x:isinstance(x,str),'boolean':lambda x:isinstance(x,bool),
                 'integer':lambda x:isinstance(x,int) and not isinstance(x,bool),
                 'null':lambda x:x is None}
        assert any(matches[t](value) for t in types)
    if 'const' in schema: assert value==schema['const']
    if 'enum' in schema: assert value in schema['enum']
    if 'pattern' in schema: assert re.search(schema['pattern'],value)
    if isinstance(value,int) and not isinstance(value,bool):
        assert value>=schema.get('minimum',value) and value<=schema.get('maximum',value)
    if isinstance(value,dict):
        assert set(schema.get('required',[]))<=value.keys()
        if schema.get('additionalProperties') is False: assert value.keys()<=schema.get('properties',{}).keys()
        for key,item in value.items():
            if key in schema.get('properties',{}): validate(item,schema['properties'][key],document)
    if isinstance(value,list) and 'items' in schema:
        for item in value: validate(item,schema['items'],document)
    if schema.get('format')=='date-time': datetime.datetime.fromisoformat(value.replace('Z','+00:00'))
    for condition in schema.get('allOf',[]):
        if 'if' in condition:
            try: validate(value,condition['if'],document); matched=True
            except AssertionError: matched=False
            validate(value,condition.get('then' if matched else 'else',{}),document)
        else: validate(value,condition,document)
    return True
validate(g,guests_schema,guests_schema); validate(s,status_schema,status_schema)
validate(d,displays_schema,displays_schema)
validate(c,capabilities_schema,capabilities_schema)
assert g['schema_version']=='1.0.0' and g['command']=='manager.guests' and g['status']=='ok'
assert g['count']==4 and [x['name'] for x in g['guests']]==['alpine','debian','image_1','ubuntu']
generic=next(x for x in g['guests'] if x['name']=='image_1')
assert generic['desktop_profile'] is False and generic['display'] is None
assert generic['qualification']=='no-desktop-profile'
assert all(x['state']=='installed' for x in g['guests'])
assert d['command']=='manager.displays' and d['native_display']==0 and d['native_occupied'] is False
assert d['count']==3 and [x['name'] for x in d['guests']]==['alpine','debian','ubuntu']
assert [(x['name'],x['target_display']) for x in d['guests']]==[('alpine',3),('debian',1),('ubuntu',2)]
assert all(x['current_display'] is None and x['migration_required'] is False for x in d['guests'] if x['name']!='debian')
assert all(x['target_owner'] is None and x['target_owner_kind']=='unoccupied' for x in d['guests'])
debian=next(x for x in d['guests'] if x['name']=='debian')
assert debian['registry_display']==0 and debian['registry_lifecycle']=='READY'
assert debian['current_display']==0 and debian['migration_required'] is True
assert all(x['registry_display'] is None and x['registry_lifecycle']=='unregistered' for x in d['guests'] if x['name']!='debian')
assert s['management_mode']=='direct-cli' and s['guest_manager_available'] is True
assert s['installed_guest_count']==4 and s['running_desktops']==['debian','alpine']
assert c['command']=='manager.capabilities'
assert [x['id'] for x in c['operations']]==['manager.capabilities','manager.displays','manager.guests','manager.status']
assert c['count']==len(c['operations']) and len({x['id'] for x in c['operations']})==c['count']
assert all(x['access']=='read-only' and x['argument_count']==0 for x in c['operations'])
PY
then ok 'manager snapshots validate against schemas; capability list matches dispatch allowlist'; else not_ok 'v1 manager outputs validate against schemas; capability list matches dispatch allowlist'; fi

if env TERNUX_STATE_DIR="$TMP/state-collisions" HOME="$TMP/home-collisions" TMPDIR="$TMP/collision-tmp" bash -c '
  mkdir -p "$TMPDIR/.X11-unix"
  : > "$TMPDIR/.X11-unix/X0"; : > "$TMPDIR/.X11-unix/X1"; : > "$TMPDIR/.X3-lock"
  . "$1/lib/manager.sh"
  tnx_has_cmd(){ [ "$1" = proot-distro ]; }
  proot-distro(){ printf "debian\nubuntu\nalpine\n"; }
  _tnx_running_guest_sessions(){ printf "debian\nubuntu\nalpine\n"; }
  pgrep(){ [[ "${2:-}" == *" :2("* ]]; }
  tnx_distro_state_set debian display 0 || exit
  tnx_distro_state_set ubuntu display 1 || exit
  tnx_distro_state_set alpine display 2 || exit
  TERNUX_JSON=1 tnx_cmd_manager displays
' _ "$ROOT" > "$TMP/displays-collisions" 2>/dev/null && python3 - "$TMP/displays-collisions" <<'PY'
import json,sys
obj=json.load(open(sys.argv[1])); guests={item['name']:item for item in obj['guests']}
assert obj['native_display']==0 and obj['native_occupied'] is True
assert obj['native_lock_present'] is False
assert guests['debian']['current_display']==0 and guests['debian']['target_display']==1
assert guests['debian']['target_socket_present'] is True and guests['debian']['target_conflict'] is True
assert guests['debian']['target_owner'] == 'ubuntu' and guests['debian']['target_owner_kind'] == 'active-guest-assignment'
assert guests['ubuntu']['target_display']==2 and guests['ubuntu']['target_server_running'] is True
assert guests['ubuntu']['target_conflict'] is True
assert guests['ubuntu']['target_owner'] == 'alpine' and guests['ubuntu']['target_owner_kind'] == 'active-guest-assignment'
assert guests['alpine']['current_display']==2 and guests['alpine']['target_display']==3
assert guests['alpine']['target_lock_present'] is True
assert guests['alpine']['migration_required'] is True and guests['alpine']['target_conflict'] is True
assert guests['alpine']['target_owner'] is None and guests['alpine']['target_owner_kind'] == 'unidentified'
PY
then ok 'display snapshot identifies occupied targets and required migration without changing assignments'; else not_ok 'display snapshot identifies occupied targets and required migration without changing assignments'; fi

if env TERNUX_STATE_DIR="$TMP/state-owner-ambiguous" HOME="$TMP/home-owner-ambiguous" TMPDIR="$TMP/tmp-owner-ambiguous" bash -c '
  mkdir -p "$TMPDIR/.X11-unix"; : > "$TMPDIR/.X11-unix/X1"
  . "$1/lib/manager.sh"
  tnx_has_cmd(){ [ "$1" = proot-distro ]; }
  proot-distro(){ printf "debian\nubuntu\nalpine\n"; }
  _tnx_running_guest_sessions(){ printf "ubuntu\nalpine\n"; }
  pgrep(){ return 1; }
  tnx_distro_state_set debian display 0 || exit
  tnx_distro_state_set ubuntu display 1 || exit
  tnx_distro_state_set alpine display 1 || exit
  TERNUX_JSON=1 tnx_cmd_manager displays
' _ "$ROOT" > "$TMP/displays-owner-ambiguous" 2>/dev/null && python3 - "$TMP/displays-owner-ambiguous" <<'PY'
import json,sys
obj=json.load(open(sys.argv[1])); debian=next(x for x in obj['guests'] if x['name']=='debian')
assert debian['target_conflict'] is True
assert debian['target_owner'] is None and debian['target_owner_kind']=='unidentified'
PY
then ok 'ambiguous display ownership is reported without selecting a guest'; else not_ok 'ambiguous display ownership is reported without selecting a guest'; fi

if env TERNUX_STATE_DIR="$TMP/state-errors" HOME="$TMP/home-errors" bash -c '
  . "$1/lib/manager.sh"
  run_error(){
    local output="" rc=0
    output="$(TERNUX_JSON=1 tnx_manager_dispatch "$1" "${@:2}")" || rc=$?
    [ "$rc" -eq 2 ] || return 1
    printf "%s\n" "$output"
  }
  run_error manager.unknown >"$2/unknown"
  run_error manager.status unexpected >"$2/arguments"
' _ "$ROOT" "$TMP" && python3 - "$TMP/unknown" "$TMP/arguments" <<'PY'
import json,sys
unknown=json.load(open(sys.argv[1])); arguments=json.load(open(sys.argv[2]))
assert unknown['code']=='UNKNOWN_OPERATION' and unknown['command']=='manager.error'
assert arguments['code']=='INVALID_ARGUMENTS' and arguments['status']=='error'
PY
then ok 'manager dispatch denies unknown operations and extra arguments with typed errors'; else not_ok 'manager dispatch denies unknown operations and extra arguments with typed errors'; fi

if env TERNUX_STATE_DIR="$TMP/state-empty" HOME="$TMP/home-empty" TMPDIR="$TMP/empty-tmp" bash -c '
  . "$1/lib/manager.sh"; tnx_has_cmd(){ return 0; }; proot-distro(){ :; }; _tnx_running_guest_sessions(){ :; }; pgrep(){ return 1; }
  output="$(TERNUX_JSON=1 tnx_cmd_manager status)" || exit
  python3 -c '\''import json,sys; x=json.loads(sys.argv[1]); assert x["installed_guest_count"]==0 and x["running_desktops"]==[]'\'' "$output"
  output="$(TERNUX_JSON=1 tnx_cmd_manager guests)" || exit
  python3 -c '\''import json,sys; x=json.loads(sys.argv[1]); assert x["count"]==0 and x["guests"]==[]'\'' "$output"
  output="$(TERNUX_JSON=1 tnx_cmd_manager displays)" || exit
  python3 -c '\''import json,sys; x=json.loads(sys.argv[1]); assert x["count"]==0 and x["guests"]==[] and x["native_display"]==0'\'' "$output"
' _ "$ROOT"; then ok 'status and guest list represent a healthy zero-guest host as empty, not failed'; else not_ok 'status and guest list represent a healthy zero-guest host as empty, not failed'; fi

if env TERNUX_STATE_DIR="$TMP/state-no-manager" HOME="$TMP/home-no-manager" bash -c '
  . "$1/lib/manager.sh"; tnx_has_cmd(){ return 1; }
  output="$(TERNUX_JSON=1 tnx_cmd_manager status)" || exit
  python3 -c '\''import json,sys; x=json.loads(sys.argv[1]); assert x["guest_manager_available"] is False and x["installed_guest_count"] is None'\'' "$output"
  if TERNUX_JSON=1 tnx_cmd_manager guests >"$2/error"; then exit 1; fi
  python3 -c '\''import json,sys; x=json.load(open(sys.argv[1])); assert x["code"]=="GUEST_MANAGER_UNAVAILABLE" and x["status"]=="error" and "timestamp" in x'\'' "$2/error"
  if TERNUX_JSON=1 tnx_cmd_manager displays >"$2/displays-error"; then exit 1; fi
  python3 -c '\''import json,sys; x=json.load(open(sys.argv[1])); assert x["command"]=="manager.displays" and x["code"]=="GUEST_MANAGER_UNAVAILABLE"'\'' "$2/displays-error"
' _ "$ROOT" "$TMP"; then ok 'missing proot-distro is distinguished from an empty guest list'; else not_ok 'missing proot-distro is distinguished from an empty guest list'; fi

printf '1..%d\n# pass %d\n# fail %d\n' "$((pass+fail))" "$pass" "$fail"
[ "$fail" -eq 0 ]
