#!/usr/bin/env python3
"""Require immutable SHA pins and readable release labels for external Actions."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORKFLOWS = ROOT / ".github/workflows"
USE_LINE = re.compile(r"^\s*(?:-\s*)?uses:\s*(\S+)(?:\s+#\s*(.*))?\s*$")
FULL_SHA = re.compile(r"^[0-9a-f]{40}$")
VERSION_LABEL = re.compile(r"^v[0-9]+(?:\.[0-9]+){0,2}$")


def main() -> int:
    failures: list[str] = []
    refs = 0
    for path in sorted(WORKFLOWS.glob("*.yml")):
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if "uses:" not in line:
                continue
            match = USE_LINE.match(line)
            if not match:
                failures.append(f"{path.relative_to(ROOT)}:{number}: cannot parse uses reference")
                continue
            reference, comment = match.groups()
            if reference.startswith("./"):
                continue
            refs += 1
            if "@" not in reference:
                failures.append(f"{path.relative_to(ROOT)}:{number}: external action has no ref")
                continue
            repository, revision = reference.rsplit("@", 1)
            if "/" not in repository or not FULL_SHA.fullmatch(revision):
                failures.append(f"{path.relative_to(ROOT)}:{number}: external action must use a full lowercase 40-character commit SHA")
                continue
            if not comment or not VERSION_LABEL.fullmatch(comment.strip()):
                failures.append(f"{path.relative_to(ROOT)}:{number}: pinned action needs an inline release label such as # v5")
    if failures:
        print("Immutable GitHub Actions policy failed:")
        print("\n".join(f"- {item}" for item in failures))
        return 1
    if refs == 0:
        print("No external Actions were checked; refusing an empty policy pass.")
        return 1
    print(f"Immutable GitHub Actions policy passed: {refs} external references use full SHAs and release labels.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
