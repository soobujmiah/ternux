#!/usr/bin/env python3
"""
ternux — installer UI render test.

Runs the installer frame inside a real pseudo-terminal, replays every byte it
writes through a small VT100 emulator, and asserts the invariants that keep the
dashboard readable on an Android terminal:

  * the frame borders stay intact (no row overflows the terminal width and no
    log line overwrites a border);
  * the screen is cleared only when it should be (open, resize, close) instead
    of on a timer, which is what makes a log impossible to read;
  * carriage-return progress output (apt/dpkg/curl) collapses onto one row
    instead of flooding the log window;
  * a terminal resize re-fits the frame exactly once;
  * every produced line still reaches the log file.

Usage:
    python3 tests/ui_render.py             # test the working tree, print TAP
    python3 tests/ui_render.py --dump      # also print the final screen
    python3 tests/ui_render.py --lib DIR   # test an alternative lib/ directory
"""

from __future__ import annotations

import argparse
import fcntl
import os
import pty
import re
import select
import shutil
import struct
import subprocess
import sys
import tempfile
import termios
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


# ---------------------------------------------------------------------------
# Minimal VT100 screen
# ---------------------------------------------------------------------------
class Screen:
    def __init__(self, rows: int, cols: int) -> None:
        self.rows = rows
        self.cols = cols
        self.buf = [[" "] * cols for _ in range(rows)]
        self.attr = [[""] * cols for _ in range(rows)]
        self.sgr = ""
        self.r = 0
        self.c = 0
        self.top = 0
        self.bot = rows - 1
        self.saved = (0, 0)
        self.pending_wrap = False
        self.clears = 0          # full-screen erases (CSI 2 J)
        self.region_sets = 0     # DECSTBM with parameters
        self.printed = 0
        self.snapshots: list[tuple[float, str]] = []

    # -- helpers ------------------------------------------------------------
    def resize(self, rows: int, cols: int) -> None:
        self.rows, self.cols = rows, cols
        self.buf = [[" "] * cols for _ in range(rows)]
        self.attr = [[""] * cols for _ in range(rows)]
        self.r = self.c = 0
        self.top, self.bot = 0, rows - 1

    def line(self, r: int) -> str:
        return "".join(self.buf[r]).rstrip()

    def text(self) -> str:
        return "\n".join(self.line(r) for r in range(self.rows))

    def scroll_up(self) -> None:
        del self.buf[self.top]
        self.buf.insert(self.bot, [" "] * self.cols)
        del self.attr[self.top]
        self.attr.insert(self.bot, [""] * self.cols)

    def lf(self) -> None:
        if self.r == self.bot:
            self.scroll_up()
        elif self.r < self.rows - 1:
            self.r += 1

    def put(self, ch: str) -> None:
        if self.pending_wrap:
            self.c = 0
            self.lf()
            self.pending_wrap = False
        if 0 <= self.r < self.rows and 0 <= self.c < self.cols:
            self.buf[self.r][self.c] = ch
            self.attr[self.r][self.c] = self.sgr
            self.printed += 1
        if self.c >= self.cols - 1:
            self.pending_wrap = True
        else:
            self.c += 1

    def html(self, title: str) -> str:
        """Render the current screen as a standalone HTML terminal mock."""
        palette = {
            "1;30": "#6b7280", "1;31": "#ff6b6b", "1;32": "#7ee787",
            "1;33": "#f2cc60", "1;34": "#79c0ff", "1;35": "#d2a8ff",
            "1;36": "#56d4dd", "1;37": "#f0f6fc", "2": "#8b949e",
        }
        out = []
        for r in range(self.rows):
            row = self.line(r)
            if not row and r > 0 and not any(self.line(x) for x in range(r, self.rows)):
                break
            parts = []
            run, run_attr = "", None
            for c in range(len(row)):
                a = self.attr[r][c]
                if a != run_attr:
                    if run:
                        parts.append((run_attr, run))
                    run, run_attr = "", a
                run += self.buf[r][c]
            if run:
                parts.append((run_attr, run))
            line_html = ""
            for attr, txt in parts:
                esc = txt.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                colour = palette.get(attr or "")
                bold = ";font-weight:600" if (attr or "").startswith("1;") else ""
                line_html += f'<span style="color:{colour}{bold}">{esc}</span>' if colour else esc
            out.append(line_html or "&nbsp;")
        body = "\n".join(out)
        return (
            "<div style=\"background:#0d1117;color:#c9d1d9;padding:18px;"
            "font:13px/1.35 ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;"
            "white-space:pre;overflow:auto;border-radius:10px\">"
            f"{body}</div>"
        )

    # -- parser -------------------------------------------------------------
    CSI = re.compile(r"\[([0-9;?]*)([ -/]*)([@-~])")

    def feed(self, data: str) -> None:
        i = 0
        n = len(data)
        while i < n:
            ch = data[i]
            if ch == "\x1b":
                if i + 1 >= n:
                    return
                nxt = data[i + 1]
                if nxt == "7":
                    self.saved = (self.r, self.c)
                    i += 2
                    continue
                if nxt == "8":
                    self.r, self.c = self.saved
                    self.pending_wrap = False
                    i += 2
                    continue
                m = self.CSI.match(data, i + 1)
                if not m:
                    i += 2
                    continue
                params, _inter, final = m.groups()
                i = m.end()
                self.csi(params, final)
                continue
            if ch == "\r":
                self.c = 0
                self.pending_wrap = False
            elif ch == "\n":
                self.lf()
                self.pending_wrap = False
            elif ch == "\b":
                self.c = max(0, self.c - 1)
            elif ch == "\a":
                pass
            elif ch == "\t":
                self.c = min(self.cols - 1, (self.c // 8 + 1) * 8)
            elif ch >= " ":
                self.put(ch)
            i += 1

    def csi(self, params: str, final: str) -> None:
        priv = params.startswith("?")
        raw = params[1:] if priv else params
        nums = [int(p) if p else 0 for p in raw.split(";")] if raw else []

        def arg(idx: int, default: int = 0) -> int:
            return nums[idx] if idx < len(nums) and nums[idx] else default

        if priv:
            return  # ?25l / ?25h etc.
        if final == "m":
            self.sgr = "" if not raw or raw == "0" else raw
            return
        if final in "Hf":
            self.r = min(self.rows - 1, max(0, arg(0, 1) - 1))
            self.c = min(self.cols - 1, max(0, arg(1, 1) - 1))
            self.pending_wrap = False
        elif final == "J":
            mode = arg(0, 0) if nums else 0
            if mode == 2:
                self.clears += 1
                self.buf = [[" "] * self.cols for _ in range(self.rows)]
                self.attr = [[""] * self.cols for _ in range(self.rows)]
            elif mode == 0:
                for c in range(self.c, self.cols):
                    self.buf[self.r][c] = " "
                for r in range(self.r + 1, self.rows):
                    self.buf[r] = [" "] * self.cols
        elif final == "K":
            mode = arg(0, 0) if nums else 0
            if mode == 0:
                for c in range(self.c, self.cols):
                    self.buf[self.r][c] = " "
            elif mode == 1:
                for c in range(0, self.c + 1):
                    self.buf[self.r][c] = " "
            else:
                self.buf[self.r] = [" "] * self.cols
        elif final == "r":
            if nums:
                self.region_sets += 1
                self.top = max(0, arg(0, 1) - 1)
                self.bot = min(self.rows - 1, arg(1, self.rows) - 1)
            else:
                self.top, self.bot = 0, self.rows - 1
            self.r, self.c = self.top, 0
        elif final == "A":
            self.r = max(self.top, self.r - arg(0, 1))
        elif final == "B":
            self.r = min(self.bot, self.r + arg(0, 1))
        elif final == "C":
            self.c = min(self.cols - 1, self.c + arg(0, 1))
        elif final == "D":
            self.c = max(0, self.c - arg(0, 1))


# ---------------------------------------------------------------------------
# Scenario
# ---------------------------------------------------------------------------
SCRIPT = r"""
set -u
. "$LIBDIR/ui.sh"

feed_phase_one() {
  echo "[TASK] Refreshing Termux package index"
  echo "Hit:1 https://packages.termux.dev/apt/termux-main stable InRelease"
  echo "Get:2 https://packages.termux.dev/apt/termux-x11 x11 InRelease [8,000 B]"
  # Carriage-return download progress: one row, updated in place.
  for p in 4 11 19 28 37 46 55 63 72 81 90 97; do
    printf '\rProgress: [%3d%%] downloading base packages...' "$p"
    sleep 0.06
  done
  printf '\rProgress: [100%%] downloading base packages... done\n'
  echo "[ OK ] Package index refreshed"
}

feed_phase_two() {
  echo "[TASK] Unpacking Debian rootfs"
  # A burst: 240 lines as fast as the shell can emit them.
  i=0
  while [ "$i" -lt 240 ]; do
    printf 'Unpacking component-%03d (1.2 MB) into ./usr/share/component-%03d\n' "$i" "$i"
    i=$((i + 1))
  done
  echo "W: Some index files failed to download"
  sleep 0.5
  echo "[ OK ] Rootfs unpacked"
}

feed_phase_three() {
  echo "[TASK] Configuring the graphics stack"
  sleep 0.9
  echo "E: mesa-vulkan-icd-wrapper has no installation candidate"
  echo "[FAIL] GPU driver setup (status 100)"
}

tnx_frame_open 3 zink ternux base
tnx_frame_phase 1 3 "Base packages (X11, PulseAudio, PRoot)"
feed_phase_one 2>&1 | tnx_frame_stream
tnx_frame_phase 2 3 "Debian container + Xfce4"
feed_phase_two 2>&1 | tnx_frame_stream
tnx_frame_phase 3 3 "GPU driver setup"
feed_phase_three 2>&1 | tnx_frame_stream
tnx_frame_close failed 3 "GPU driver setup"
"""


def run(libdir: str, rows: int, cols: int, resize_to=None):
    """Run the scenario in a PTY; return (Screen, log_text, raw_bytes)."""
    tmp = tempfile.mkdtemp(prefix="ternux-ui-")
    env = dict(os.environ)
    env.update(
        {
            "LIBDIR": libdir,
            "HOME": os.path.join(tmp, "home"),
            "TERNUX_STATE_DIR": os.path.join(tmp, "state"),
            "TERNUX_LOG_DIR": os.path.join(tmp, "log"),
            "TERM": "xterm-256color",
            "LANG": "en_US.UTF-8",
        }
    )
    for stale in ("COLUMNS", "LINES"):
        env.pop(stale, None)
    os.makedirs(env["HOME"], exist_ok=True)

    def child_setup() -> None:
        # Give the child a controlling terminal, exactly like Termux does, so
        # /dev/tty and SIGWINCH behave the way they do on a real device.
        os.setsid()
        fcntl.ioctl(0, termios.TIOCSCTTY, 0)

    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", rows, cols, 0, 0))
    proc = subprocess.Popen(
        ["bash", "-c", SCRIPT],
        stdin=slave,
        stdout=slave,
        stderr=slave,
        env=env,
        close_fds=True,
        preexec_fn=child_setup,
    )
    os.close(slave)

    screen = Screen(rows, cols)
    chunks: list[str] = []
    snaps: list[tuple[float, str]] = []
    resized = False
    started = time.time()
    while True:
        r, _, _ = select.select([master], [], [], 0.2)
        if r:
            try:
                data = os.read(master, 65536)
            except OSError:
                break
            if not data:
                break
            text = data.decode("utf-8", "replace")
            chunks.append(text)
            screen.feed(text)
            snaps.append((time.time() - started, screen.text(), screen.html("live")))
        if resize_to and not resized and time.time() - started > 1.6:
            resized = True
            nrows, ncols = resize_to
            fcntl.ioctl(master, termios.TIOCSWINSZ, struct.pack("HHHH", nrows, ncols, 0, 0))
            screen.resize(nrows, ncols)
            os.killpg(os.getpgid(proc.pid), 28)  # SIGWINCH
        if proc.poll() is not None and not r:
            break
        if time.time() - started > 60:
            break
    try:
        os.close(master)
    except OSError:
        pass
    proc.wait(timeout=10)

    logfile = os.path.join(env["TERNUX_LOG_DIR"], "ternux.log")
    log = open(logfile, encoding="utf-8", errors="replace").read() if os.path.exists(logfile) else ""
    shutil.rmtree(tmp, ignore_errors=True)
    screen.snapshots = snaps
    return screen, log, "".join(chunks)


# ---------------------------------------------------------------------------
# Assertions
# ---------------------------------------------------------------------------
class Tap:
    def __init__(self) -> None:
        self.n = 0
        self.bad = 0

    def check(self, cond: bool, name: str, detail: str = "") -> None:
        self.n += 1
        if cond:
            print(f"ok {self.n} - {name}")
        else:
            self.bad += 1
            print(f"not ok {self.n} - {name}")
            if detail:
                for ln in detail.splitlines():
                    print(f"#   {ln}")

    def done(self) -> int:
        print(f"1..{self.n}")
        print(f"# pass {self.n - self.bad}")
        print(f"# fail {self.bad}")
        return 1 if self.bad else 0


def frame_columns(screen: Screen):
    """Return (left, right) border columns of the drawn frame, or None."""
    for r in range(screen.rows):
        row = screen.line(r)
        if row.startswith("+") and row.endswith("+") and len(row) > 8:
            return 0, len(row) - 1
    return None


def analyse(tap: Tap, screen: Screen, log: str, raw: str, label: str, expect_clears: int,
            expect_width: int | None = None) -> None:
    cols = frame_columns(screen)
    tap.check(cols is not None, f"{label}: frame has a top rule", screen.text())
    if cols:
        left, right = cols
        bottom = max(
            (r for r in range(screen.rows) if screen.line(r).startswith("+")),
            default=screen.rows - 1,
        )
        top_rule = min(
            (r for r in range(screen.rows) if screen.line(r).startswith("+")),
            default=0,
        )
        bad_rows = []
        for r in range(top_rule, bottom + 1):
            row = screen.line(r)
            if not row:
                continue
            if len(row) > screen.cols:
                bad_rows.append(f"row {r + 1} overflows: {len(row)} > {screen.cols}")
                continue
            first = screen.buf[r][left]
            last = screen.buf[r][right]
            if first not in "+|" or last not in "+|":
                bad_rows.append(f"row {r + 1} border broken: {row!r}")
        tap.check(not bad_rows, f"{label}: every framed row keeps its borders", "\n".join(bad_rows))

    if expect_width is not None:
        widths = {len(screen.line(r)) for r in range(screen.rows) if screen.line(r).startswith("+")}
        tap.check(
            widths == {expect_width},
            f"{label}: the frame is redrawn at the current terminal width",
            f"rule widths {sorted(widths)}, expected {expect_width}",
        )
    tap.check(
        screen.clears <= expect_clears,
        f"{label}: full-screen repaints stay bounded ({screen.clears} <= {expect_clears})",
        f"observed {screen.clears} screen clears",
    )
    tap.check(
        "Unpacking component-239" in log,
        f"{label}: the complete stream reaches the log file",
    )
    tap.check(
        "downloading base packages" in log,
        f"{label}: progress output is recorded once the line completes",
    )
    progress_rows = sum(1 for r in range(screen.rows) if "downloading base packages" in screen.line(r))
    tap.check(
        progress_rows <= 1,
        f"{label}: carriage-return progress never floods the window",
        f"{progress_rows} rows still show the progress line",
    )


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--lib", default=os.path.join(ROOT, "lib"))
    ap.add_argument("--dump", action="store_true")
    ap.add_argument("--html", metavar="FILE", help="write an HTML mock of the rendered screens")
    args = ap.parse_args()

    tap = Tap()

    # 1. Phone-sized portrait terminal.
    screen, log, raw = run(args.lib, 34, 58)
    analyse(tap, screen, log, raw, "portrait 58x34", expect_clears=3, expect_width=57)
    tap.check(
        any("[FAIL] " in screen.line(r) or "Stopped at phase" in screen.line(r) for r in range(screen.rows)),
        "portrait 58x34: the failure is visible after close",
        screen.text(),
    )
    if args.dump:
        mid = min(screen.snapshots, key=lambda s: abs(s[0] - 1.0), default=None)
        if mid:
            print(f"\n--- screen during phase 1, t={mid[0]:.2f}s (58x34) ---")
            print(mid[1])
            print("--- end ---")
        print("\n--- final screen (58x34) ---")
        print(screen.text())
        print("--- end ---\n")

    # 2. Small landscape terminal that still fits a dashboard.
    screen2, log2, _ = run(args.lib, 16, 92)
    analyse(tap, screen2, log2, "", "landscape 92x16", expect_clears=3)

    # 3. Live resize in the middle of a phase.
    screen3, log3, _ = run(args.lib, 30, 64, resize_to=(22, 46))
    analyse(tap, screen3, log3, "", "resize 64x30 -> 46x22", expect_clears=5, expect_width=45)

    if args.dump:
        print("--- final screen after resize (46x22) ---")
        print(screen3.text())
        print("--- end ---")

    if args.html:
        mid = min(screen.snapshots, key=lambda s: abs(s[0] - 1.1), default=None)
        parts = ["<!doctype html><meta charset='utf-8'><title>ternux installer UI</title>",
                 "<body style=\"background:#010409;color:#c9d1d9;margin:0;padding:24px;"
                 "font-family:ui-sans-serif,system-ui,sans-serif\">"]
        if mid:
            parts.append(f"<h3 style='color:#f0f6fc'>Live, {mid[0]:.1f}s into the install (58x34)</h3>")
            parts.append(mid[2])
        parts.append("<h3 style='color:#f0f6fc'>Final screen after a failed phase (58x34)</h3>")
        parts.append(screen.html("final"))
        parts.append("</body>")
        with open(args.html, "w", encoding="utf-8") as fh:
            fh.write("\n".join(parts))
        print(f"# wrote {args.html}")

    return tap.done()


if __name__ == "__main__":
    sys.exit(main())
