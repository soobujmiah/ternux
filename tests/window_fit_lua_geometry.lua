-- Exercise lib/ternux-window-fit.lua's centering/clamping math without a
-- real X server or devilspie2, by stubbing the host-provided globals
-- devilspie2 normally injects (get_window_type, get_screen_geometry,
-- get_window_geometry, set_window_geometry) and reloading the script fresh
-- for each scenario.

local function script_dir()
  local source = debug.getinfo(1, "S").source:match("@?(.*)$")
  return source:match("(.*)/") or "."
end

local script_path = arg[1] or (script_dir() .. "/../lib/ternux-window-fit.lua")

local checks = 0
local failures = 0

local function run_case(label, kind, screen_w, screen_h, x, y, w, h, expect)
  checks = checks + 1
  local set_calls = {}
  get_window_type = function() return kind end
  get_screen_geometry = function() return screen_w, screen_h end
  get_window_geometry = function() return x, y, w, h end
  set_window_geometry = function(tx, ty, tw, th)
    table.insert(set_calls, { tx, ty, tw, th })
  end

  local chunk = assert(loadfile(script_path))
  chunk()

  if expect == nil then
    if #set_calls ~= 0 then
      failures = failures + 1
      print(string.format("not ok %d - %s (expected no geometry change, got %d calls)", checks, label, #set_calls))
    else
      print(string.format("ok %d - %s", checks, label))
    end
    return
  end

  if #set_calls ~= 1 then
    failures = failures + 1
    print(string.format("not ok %d - %s (expected exactly one set_window_geometry call, got %d)", checks, label, #set_calls))
    return
  end

  local got = set_calls[1]
  if got[1] == expect[1] and got[2] == expect[2] and got[3] == expect[3] and got[4] == expect[4] then
    print(string.format("ok %d - %s", checks, label))
  else
    failures = failures + 1
    print(string.format(
      "not ok %d - %s (expected x=%d y=%d w=%d h=%d, got x=%d y=%d w=%d h=%d)",
      checks, label, expect[1], expect[2], expect[3], expect[4], got[1], got[2], got[3], got[4]
    ))
  end
end

-- margin=3, top=24, bottom=42 are the script's own constants; every
-- expectation below is derived from those, not guessed.
run_case("small window centered in a phone-sized work area",
  "WINDOW_TYPE_NORMAL", 800, 576, 100, 50, 300, 400, { 250, 79, 300, 400 })
run_case("oversized window clamped to the work area and centered",
  "WINDOW_TYPE_NORMAL", 800, 576, 0, 0, 1200, 1000, { 3, 27, 794, 504 })
run_case("already-fitted window triggers no redundant move",
  "WINDOW_TYPE_NORMAL", 800, 576, 250, 79, 300, 400, nil)
run_case("dialog windows are fitted the same as normal windows",
  "WINDOW_TYPE_DIALOG", 800, 576, 100, 50, 300, 400, { 250, 79, 300, 400 })
run_case("non-normal, non-dialog window types are left alone",
  "WINDOW_TYPE_DESKTOP", 800, 576, 0, 0, 800, 576, nil)
run_case("a narrow phone screen still bounds an oversized window",
  "WINDOW_TYPE_NORMAL", 320, 576, 0, 0, 500, 600, { 3, 27, 314, 504 })
run_case("a tiny screen height never drives target geometry negative",
  "WINDOW_TYPE_NORMAL", 320, 50, 0, 0, 500, 600, { 3, 24, 314, 1 })

print(string.format("1..%d", checks))
print(string.format("# pass %d", checks - failures))
print(string.format("# fail %d", failures))
os.exit(failures == 0 and 0 or 1)
