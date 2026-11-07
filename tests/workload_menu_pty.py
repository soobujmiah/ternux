#!/usr/bin/env python3
"""Drive the real optional-workload selector in an isolated pseudo-terminal."""
from __future__ import annotations

import shutil
import shlex
import subprocess
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
script = shutil.which("script")
if script is None:
    raise SystemExit("util-linux script command is required for the PTY integration test")

index_program = r'''
source "$1/lib/phases.sh"
for i in "${!TNX_OPTIONAL_ITEMS[@]}"; do
  if [ "${TNX_OPTIONAL_ITEMS[$i]}" = stable-diffusion ]; then
    printf '%s' "$i"
    exit 0
  fi
done
exit 1
'''
index_result = subprocess.run(
    ["bash", "-c", index_program, "workload-menu-test", str(root)],
    check=True,
    capture_output=True,
    text=True,
)
index = int(index_result.stdout)

menu_program = 'stty rows 30 cols 100; source "$1/lib/phases.sh"; tnx_prompt_workloads virgl'
command = f"bash -c {shlex.quote(menu_program)} workload-menu-test {shlex.quote(str(root))}"
keys = b"j" * index + b" \r"
result = subprocess.run(
    [script, "-qec", command, "/dev/null"],
    input=keys,
    capture_output=True,
    timeout=15,
)
output = result.stdout + result.stderr
if result.returncode != 0:
    raise SystemExit(f"workload selector exited with status {result.returncode}")
if not output.rstrip().endswith(b"stable-diffusion"):
    raise SystemExit("selector did not return the stable-diffusion workload ID")
if b"Stable Diffusion CPU + Vulkan" not in output:
    raise SystemExit("selector did not render the selected Stable Diffusion label")
print("interactive workload menu PTY selection passed: stable-diffusion")
