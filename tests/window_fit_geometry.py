#!/usr/bin/env python3
"""Exercise the X11 window fitter's display geometry without an X server."""

import ast
import re
from pathlib import Path


root = Path(__file__).resolve().parents[1]
source = root / "lib/ternux-assets/bin/ternux-window-fit-x11"
tree = ast.parse(source.read_text())
functions = [
    node for node in tree.body
    if isinstance(node, ast.FunctionDef)
    and node.name in {
        "fitted_geometry", "root_dimensions", "zoomed_font_name",
        "replay_zoom_key", "moveresize_flags",
    }
]
module = ast.Module(body=functions, type_ignores=[])
namespace: dict[str, object] = {
    "re": re,
    "X": type("X", (), {"ReplayKeyboard": 10}),
}
exec(compile(module, str(source), "exec"), namespace)
fit = namespace["fitted_geometry"]
dimensions = namespace["root_dimensions"]
zoom_font = namespace["zoomed_font_name"]
replay_key = namespace["replay_zoom_key"]
move_resize_flags = namespace["moveresize_flags"]


def expect(label: str, actual: tuple[int, int, int, int], expected: tuple[int, int, int, int]) -> None:
    if actual != expected:
        raise SystemExit(f"{label}: expected {expected}, got {actual}")
    print(f"ok - {label}")


expect("small window centered in work area", fit(300, 400, 0, 24, 800, 576), (250, 112, 300, 400))
expect("undersized normal window expanded to usable minimum", fit(277, 181, 0, 27, 640, 1359, 4, False, False, 371, 516), (134, 448, 371, 516))
expect(
    "interactive resize may choose a size below the launch minimum",
    fit(260, 180, 0, 27, 640, 1359, 4, False, False, 371, 516, preserve_position=True, current_x=40, current_y=100),
    (40, 100, 260, 180),
)
expect("usable minimum remains bounded by narrow display", fit(120, 80, 0, 24, 320, 576, 4, False, False, 500, 600), (4, 28, 312, 568))
expect("oversize window scaled and centered", fit(1200, 1000, 0, 24, 800, 576), (4, 28, 792, 568))
expect("offset display work area", fit(500, 300, 20, 40, 700, 500), (120, 140, 500, 300))
expect("maximized window fills work area", fit(790, 570, 0, 24, 800, 576, 4, True, True), (4, 28, 792, 568))
expect(
    "resize keeps a user-moved window in place",
    fit(420, 320, 0, 24, 800, 576, preserve_position=True, current_x=37, current_y=81),
    (37, 81, 420, 320),
)
expect(
    "resized window position clamps only when it would leave the work area",
    fit(600, 500, 0, 24, 800, 576, preserve_position=True, current_x=500, current_y=300),
    (196, 96, 600, 500),
)


class MutableRoot:
    def __init__(self) -> None:
        self.width, self.height = 312, 640

    def get_geometry(self):
        return self


live_root = MutableRoot()
assert dimensions(live_root) == (312, 640)
live_root.width, live_root.height = 640, 1386
assert dimensions(live_root) == (640, 1386)
print("ok - root resize is read live instead of using cached display dimensions")
assert zoom_font("Noto Sans Mono 10", 1) == "Noto Sans Mono 12"
assert zoom_font("Noto Sans Mono 12", -1) == "Noto Sans Mono 10"
assert zoom_font("Noto Sans Mono 10", -1) == "Noto Sans Mono 8.33"
assert zoom_font("not-a-sized-font", 1) is None
print("ok - terminal zoom updates a persistent Xfce font size")


class ReplayProbe:
    def __init__(self) -> None:
        self.calls: list[tuple[object, ...]] = []

    def allow_events(self, *args: object) -> None:
        self.calls.append(("allow_events", *args))

    def flush(self) -> None:
        self.calls.append(("flush",))


probe = ReplayProbe()
event = type("Event", (), {"time": 42})()
replay_key(probe, event)
assert probe.calls == [("allow_events", 10, 42), ("flush",)]
main = next(
    node for node in tree.body
    if isinstance(node, ast.FunctionDef) and node.name == "main"
)
hotkey = next(
    node for node in ast.walk(main)
    if isinstance(node, ast.If)
    and "event.type == X.KeyPress" in ast.unparse(node.test)
    and "event.detail in zoom_key_steps" in ast.unparse(node.test)
)
assert any(
    isinstance(node, ast.Expr)
    and isinstance(node.value, ast.Call)
    and ast.unparse(node.value.func) == "replay_zoom_key"
    for node in hotkey.body
), "the key replay must run for terminal and non-terminal zoom shortcuts"
grab = next(
    node for node in ast.walk(main)
    if isinstance(node, ast.Call)
    and isinstance(node.func, ast.Attribute)
    and node.func.attr == "grab_key"
)
assert ast.unparse(grab.args[4]) == "X.GrabModeSync", (
    "ReplayKeyboard requires a synchronous keyboard grab"
)
print("ok - intercepted zoom shortcuts replay to the focused application")
assert move_resize_flags(1) == (1 | (0xF << 8) | (1 << 12))
print("ok - EWMH move/resize requests use frame-based NorthWestGravity")
