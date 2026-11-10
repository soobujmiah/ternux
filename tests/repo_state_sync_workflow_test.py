#!/usr/bin/env python3
"""Guard the generated-state PR workflow against a too-short check wait."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
workflow = (ROOT / ".github/workflows/repo-knowledge-sync.yml").read_text(encoding="utf-8")
marker = "      - name: Approve checks for generated state pull request"
assert marker in workflow, "generated-state check approval job is missing"
section = workflow.split(marker, 1)[1].split("      - name:", 1)[0]
match = re.search(r"for attempt in \$\(seq 1 (\d+)\); do", section)
assert match, "generated-state approval loop is missing its bounded retry limit"
attempts = int(match.group(1))
sleep_match = re.search(r"^\s+sleep (\d+)\s*$", section, re.MULTILINE)
assert sleep_match, "generated-state approval loop must have a bounded polling interval"
interval = int(sleep_match.group(1))
window = attempts * interval
assert 180 <= window <= 600, f"check registration window is {window}s; expected 180–600s"
assert "gh api --paginate --slurp \"repos/$GITHUB_REPOSITORY/actions/runs?per_page=100\" | jq '{workflow_runs: [.[].workflow_runs[]]}'" in section
assert 'select(.head_sha == $sha and .head_branch == $branch and .conclusion == "action_required"' in section
assert 'gh api -X POST "repos/$GITHUB_REPOSITORY/actions/runs/$run_id/approve"' in section
for expected_workflow in (
    "Validate",
    "Repository State Contract",
    "Termux APT package artifact",
    "Repo Knowledge Sync",
):
    assert f'"{expected_workflow}"' in section

print(f"generated-state check wait contract passed: {window}s bounded window for exact-head checks")
