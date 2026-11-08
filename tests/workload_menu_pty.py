#!/usr/bin/env python3
"""Drive the real optional-workload selector in an isolated pseudo-terminal."""
from __future__ import annotations

import shutil
import shlex
import subprocess
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
target = sys.argv[2] if len(sys.argv) > 2 else "stable-diffusion"
labels = {
    "llama-vulkan": "llama.cpp Vulkan",
    "stable-diffusion": "Stable Diffusion CPU + Vulkan",
    "llama-htp-experimental": "llama.cpp HTP (experimental)",
    "evolution": "Evolution Mail",
    "celestia": "Celestia astronomy simulator",
}
if target not in labels:
    raise SystemExit(f"unsupported test workload: {target}")
script = shutil.which("script")
if script is None:
    raise SystemExit("util-linux script command is required for the PTY integration test")

index_program = r'''
source "$1/lib/phases.sh"
for i in "${!TNX_OPTIONAL_ITEMS[@]}"; do
  if [ "${TNX_OPTIONAL_ITEMS[$i]}" = "$2" ]; then
    printf '%s' "$i"
    exit 0
  fi
done
exit 1
'''
index_result = subprocess.run(
    ["bash", "-c", index_program, "workload-menu-test", str(root), target],
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
if not output.rstrip().endswith(target.encode()):
    raise SystemExit(f"selector did not return the {target} workload ID")
if labels[target].encode() not in output:
    raise SystemExit(f"selector did not render the selected {target} label")
print(f"interactive workload menu PTY selection passed: {target}")
