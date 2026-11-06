-- Keep windows inside the live X11 work area, including small phone viewports.
local kind = get_window_type()
if kind == "WINDOW_TYPE_NORMAL" or kind == "WINDOW_TYPE_DIALOG" then
    local screen_width, screen_height = get_screen_geometry()
    local x, y, width, height = get_window_geometry()
    local margin = 8
    local top = 28
    local bottom = 48
    local max_width = math.max(1, screen_width - margin * 2)
    local max_height = math.max(1, screen_height - top - bottom - margin * 2)

    if width > max_width or height > max_height then
        local target_width = math.min(width, max_width)
        local target_height = math.min(height, max_height)
        set_window_geometry(margin, top + margin, target_width, target_height)
    elseif x < margin or y < top or x + width > screen_width - margin or y + height > screen_height - bottom then
        center()
    end
end
