#!/usr/bin/env python3
"""Drive the real optional-workload selector in an isolated pseudo-terminal."""
from __future__ import annotations

import shutil
import shlex
import subprocess
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
targets = (sys.argv[2] if len(sys.argv) > 2 else "stable-diffusion").split(",")
distro = sys.argv[3] if len(sys.argv) > 3 else "debian"
labels = {
    "jq": "jq",
    "llama-vulkan": "llama.cpp Vulkan",
    "stable-diffusion": "Stable Diffusion CPU + Vulkan",
    "llama-htp-experimental": "llama.cpp HTP (experimental)",
    "evolution": "Evolution Mail",
    "celestia": "Celestia astronomy simulator",
    "blender": "Blender",
    "adt-build-tools": "ADT Build Tools",
}
if not targets or any(target not in labels for target in targets):
    raise SystemExit(f"unsupported test workload(s): {','.join(targets)}")
script = shutil.which("script")
if script is None:
    raise SystemExit("util-linux script command is required for the PTY integration test")

index_program = r'''
source "$1/lib/phases.sh"
shift
for target in "$@"; do
  if [ "${WORKLOAD_DISTRO:-debian}" = alpine ]; then
    case "$target" in blender) printf '0\n';; *) exit 1;; esac
    continue
  fi
  found=0
  for i in "${!TNX_OPTIONAL_ITEMS[@]}"; do
    if [ "${TNX_OPTIONAL_ITEMS[$i]}" = "$target" ]; then
      printf '%s\n' "$i"
      found=1
      break
    fi
  done
  [ "$found" -eq 1 ] || exit 1
done
'''
index_result = subprocess.run(
    ["bash", "-c", index_program, "workload-menu-test", str(root), *targets],
    env={**__import__("os").environ, "WORKLOAD_DISTRO": distro},
    check=True,
    capture_output=True,
    text=True,
)
indexes = [int(value) for value in index_result.stdout.splitlines()]

menu_program = 'stty rows 30 cols 100; source "$1/lib/phases.sh"; export TERNUX_DISTRO="$2"; tnx_distro_profile "$2"; tnx_prompt_workloads virgl'
command = f"bash -c {shlex.quote(menu_program)} workload-menu-test {shlex.quote(str(root))} {shlex.quote(distro)}"
expected = ",".join(targets).encode()
if len(targets) == 1:
    keys = b"j" * indexes[0] + b" \r"
    result = subprocess.run(
        [script, "-qec", command, "/dev/null"],
        input=keys,
        capture_output=True,
        timeout=30,
    )
    output = result.stdout + result.stderr
    if result.returncode != 0:
        raise SystemExit(f"workload selector exited with status {result.returncode}")
    if not output.rstrip().endswith(expected):
        raise SystemExit(f"selector did not return {expected.decode()}: {output[-300:]!r}")
    for target in targets:
        if labels[target].encode() not in output:
            raise SystemExit(f"selector did not render the selected {target} label")
# Number selection must work for both single and multi-digit catalog indices.
numeric = subprocess.run(
    [script, "-qec", command, "/dev/null"],
    input=(" ".join(str(index + 1) for index in indexes) + "\r").encode(),
    capture_output=True,
    timeout=30,
)
numeric_output = numeric.stdout + numeric.stderr
if numeric.returncode != 0 or not numeric_output.rstrip().endswith(expected):
    raise SystemExit(f"numeric selector did not return {expected.decode()}: {numeric_output[-300:]!r}")
mode = "navigation and number toggle" if len(targets) == 1 else "multi-item number toggle"
print(f"interactive workload menu PTY selection passed: {expected.decode()} ({mode})")
