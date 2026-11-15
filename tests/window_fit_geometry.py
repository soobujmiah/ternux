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
    if isinstance(node, ast.FunctionDef) and node.name in {"fitted_geometry", "root_dimensions", "zoomed_font_name"}
]
module = ast.Module(body=functions, type_ignores=[])
namespace: dict[str, object] = {"re": re}
exec(compile(module, str(source), "exec"), namespace)
fit = namespace["fitted_geometry"]
dimensions = namespace["root_dimensions"]
zoom_font = namespace["zoomed_font_name"]


def expect(label: str, actual: tuple[int, int, int, int], expected: tuple[int, int, int, int]) -> None:
    if actual != expected:
        raise SystemExit(f"{label}: expected {expected}, got {actual}")
    print(f"ok - {label}")


expect("small window centered in work area", fit(300, 400, 0, 24, 800, 576), (250, 112, 300, 400))
expect("undersized normal window expanded to usable minimum", fit(277, 181, 0, 27, 640, 1359, 4, False, False, 371, 516), (134, 448, 371, 516))
expect("usable minimum remains bounded by narrow display", fit(120, 80, 0, 24, 320, 576, 4, False, False, 500, 600), (4, 28, 312, 568))
expect("oversize window scaled and centered", fit(1200, 1000, 0, 24, 800, 576), (4, 28, 792, 568))
expect("offset display work area", fit(500, 300, 20, 40, 700, 500), (120, 140, 500, 300))
expect("maximized window fills work area", fit(790, 570, 0, 24, 800, 576, 4, True, True), (4, 28, 792, 568))


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
