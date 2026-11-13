#!/usr/bin/env bash
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
pass=0; fail=0
ok(){ printf 'ok %d - %s\n' "$((pass+fail+1))" "$1"; pass=$((pass+1)); }
not_ok(){ printf 'not ok %d - %s\n' "$((pass+fail+1))" "$1"; fail=$((fail+1)); }
printf 'TAP version 13\n'

if env TERNUX_STATE_DIR="$TMP/state" HOME="$TMP/home" bash -c '
  . "$1/lib/manager.sh"
  tnx_has_cmd(){ [ "$1" = proot-distro ]; }
  proot-distro(){ printf "ubuntu\ndebian\ndebian\nunsafe/name\nalpine\nimage_1\n"; }
  _tnx_running_guest_sessions(){ printf "debian\nalpine\n"; }
  guests="$(TERNUX_JSON=1 tnx_cmd_manager guests)" || exit 1
  status="$(TERNUX_JSON=1 tnx_cmd_manager status)" || exit 1
  printf "%s\n---STATUS---\n%s\n" "$guests" "$status"
' _ "$ROOT" > "$TMP/output" 2>/dev/null && python3 - "$TMP/output" "$ROOT" <<'PY'
import datetime,json,re,sys
text=open(sys.argv[1]).read(); guests,status=text.split('\n---STATUS---\n')
g=json.loads(guests); s=json.loads(status); root=sys.argv[2]
status_schema=json.load(open(root+'/docs/v3/schemas/manager-status-v1.schema.json'))
guests_schema=json.load(open(root+'/docs/v3/schemas/manager-guests-v1.schema.json'))
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
assert g['schema_version']=='1.0.0' and g['command']=='manager.guests' and g['status']=='ok'
assert g['count']==4 and [x['name'] for x in g['guests']]==['alpine','debian','image_1','ubuntu']
generic=next(x for x in g['guests'] if x['name']=='image_1')
assert generic['desktop_profile'] is False and generic['display'] is None
assert generic['qualification']=='no-desktop-profile'
assert all(x['state']=='installed' for x in g['guests'])
assert s['management_mode']=='direct-cli' and s['guest_manager_available'] is True
assert s['installed_guest_count']==4 and s['running_desktops']==['debian','alpine']
PY
then ok 'v1 manager outputs validate against JSON Schemas, including generic guests and timestamps'; else not_ok 'v1 manager outputs validate against JSON Schemas, including generic guests and timestamps'; fi

if env TERNUX_STATE_DIR="$TMP/state-empty" HOME="$TMP/home-empty" bash -c '
  . "$1/lib/manager.sh"; tnx_has_cmd(){ return 0; }; proot-distro(){ :; }; _tnx_running_guest_sessions(){ :; }
  output="$(TERNUX_JSON=1 tnx_cmd_manager status)" || exit
  python3 -c '\''import json,sys; x=json.loads(sys.argv[1]); assert x["installed_guest_count"]==0 and x["running_desktops"]==[]'\'' "$output"
  output="$(TERNUX_JSON=1 tnx_cmd_manager guests)" || exit
  python3 -c '\''import json,sys; x=json.loads(sys.argv[1]); assert x["count"]==0 and x["guests"]==[]'\'' "$output"
' _ "$ROOT"; then ok 'status and guest list represent a healthy zero-guest host as empty, not failed'; else not_ok 'status and guest list represent a healthy zero-guest host as empty, not failed'; fi

if env TERNUX_STATE_DIR="$TMP/state-no-manager" HOME="$TMP/home-no-manager" bash -c '
  . "$1/lib/manager.sh"; tnx_has_cmd(){ return 1; }
  output="$(TERNUX_JSON=1 tnx_cmd_manager status)" || exit
  python3 -c '\''import json,sys; x=json.loads(sys.argv[1]); assert x["guest_manager_available"] is False and x["installed_guest_count"] is None'\'' "$output"
  if TERNUX_JSON=1 tnx_cmd_manager guests >"$2/error"; then exit 1; fi
  python3 -c '\''import json,sys; x=json.load(open(sys.argv[1])); assert x["code"]=="GUEST_MANAGER_UNAVAILABLE" and x["status"]=="error" and "timestamp" in x'\'' "$2/error"
' _ "$ROOT" "$TMP"; then ok 'missing proot-distro is distinguished from an empty guest list'; else not_ok 'missing proot-distro is distinguished from an empty guest list'; fi

printf '1..%d\n# pass %d\n# fail %d\n' "$((pass+fail))" "$pass" "$fail"
[ "$fail" -eq 0 ]
