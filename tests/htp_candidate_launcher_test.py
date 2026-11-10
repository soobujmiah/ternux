#!/usr/bin/env python3
"""Verify the disposable HTP candidate operator launcher path and environment."""
from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LAUNCHER = ROOT / "experiments/htp-integer-hmx-candidate/htp-backend-ops"


def package(root: Path) -> tuple[Path, Path, Path, Path, Path]:
    binary = root / "bin/test-backend-ops"
    broker = root / "libexec/htp-broker.py"
    shim = root / "lib/libternux-htp-broker.so"
    launcher = root / "bin/htp-backend-ops"
    launcher.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(LAUNCHER, launcher)
    fake_bin = root / "fake-bin"
    for path in (binary, broker):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("fixture\n", encoding="utf-8")
    shim.parent.mkdir(parents=True, exist_ok=True)
    compiler = shutil.which("cc") or shutil.which("clang")
    if compiler is None:
        raise SystemExit("HTP candidate launcher test requires cc or clang")
    c_source = root / "noop.c"
    c_source.write_text("int ternux_htp_test_noop(void) { return 0; }\n", encoding="utf-8")
    subprocess.run([compiler, "-shared", "-fPIC", str(c_source), "-o", str(shim)], check=True)
    binary.chmod(0o755)
    fake_bin.mkdir(parents=True, exist_ok=True)
    fake_python = fake_bin / "python3"
    fake_python.write_text(
        "#!/bin/sh\n"
        "printf 'ARG\\t%s\\n' \"$@\"\n"
        "printf 'LD_LIBRARY_PATH\\t%s\\n' \"${LD_LIBRARY_PATH-}\"\n"
        "printf 'ADSP_LIBRARY_PATH\\t%s\\n' \"${ADSP_LIBRARY_PATH-}\"\n"
        "printf 'LD_PRELOAD\\t%s\\n' \"${LD_PRELOAD-}\"\n"
        "printf 'GGML_HEXAGON_MM_SELECT\\t%s\\n' \"${GGML_HEXAGON_MM_SELECT-}\"\n",
        encoding="utf-8",
    )
    fake_python.chmod(0o755)
    return binary, broker, shim, fake_bin, launcher


def run(root: Path, fake_bin: Path, launcher: Path, override: bool = False) -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    env["PATH"] = f"{fake_bin}:{env.get('PATH', '')}"
    env.pop("LD_PRELOAD", None)
    env.pop("LD_LIBRARY_PATH", None)
    env.pop("ADSP_LIBRARY_PATH", None)
    env.pop("GGML_HEXAGON_MM_SELECT", None)
    if override:
        env["LLAMA_HTP_HOME"] = str(root)
    else:
        env.pop("LLAMA_HTP_HOME", None)
    return subprocess.run(
        [str(launcher), "-o", "MUL_MAT"],
        env=env,
        text=True,
        capture_output=True,
        check=False,
    )


def verify(root: Path, fake_bin: Path, override: bool) -> None:
    binary, broker, shim, _, launcher = package(root)
    result = run(root, fake_bin, launcher, override)
    assert result.returncode == 0, result.stderr
    rows = [line.split("\t", 1) for line in result.stdout.splitlines()]
    args = [value for key, value in rows if key == "ARG"]
    assert args == [str(broker), "--", str(binary), "-b", "HTP0", "-o", "MUL_MAT"], args
    values = {key: value for key, value in rows if key != "ARG"}
    assert values["LD_LIBRARY_PATH"].split(":", 1)[0] == str(root / "lib")
    assert values["ADSP_LIBRARY_PATH"] == str(root / "lib")
    assert values["LD_PRELOAD"].split(":", 1)[0] == str(shim)
    assert values["GGML_HEXAGON_MM_SELECT"] == "2"


with tempfile.TemporaryDirectory(prefix="ternux-htp-launcher-") as temporary:
    base = Path(temporary)
    default_root = base / "default-package"
    _, _, _, fake_default, _ = package(default_root)
    verify(default_root, fake_default, override=False)

    override_root = base / "override-package"
    _, _, _, fake_override, _ = package(override_root)
    verify(override_root, fake_override, override=True)

print("HTP candidate operator launcher tests passed")
