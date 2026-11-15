-- Keep windows inside the live X11 work area, including small phone viewports.
local kind = get_window_type()
if kind == "WINDOW_TYPE_NORMAL" or kind == "WINDOW_TYPE_DIALOG" then
    local screen_width, screen_height = get_screen_geometry()
    local x, y, width, height = get_window_geometry()
    local margin = 3
    local top = 24
    local bottom = 42
    local max_width = math.max(1, screen_width - margin * 2)
    local work_height = math.max(1, screen_height - top - bottom)
    local max_height = math.max(1, work_height - margin * 2)
    local target_width = math.min(width, max_width)
    local target_height = math.min(height, max_height)
    local target_x = math.floor((screen_width - target_width) / 2)
    local target_y = top + math.floor((work_height - target_height) / 2)

    -- Fit every new app window and place it in the center of the visible
    -- work area. Avoid relying on the window manager's initial placement,
    -- which can put tall windows above the phone's viewport.
    if x ~= target_x or y ~= target_y or width ~= target_width or height ~= target_height then
        set_window_geometry(target_x, target_y, target_width, target_height)
    end
end
