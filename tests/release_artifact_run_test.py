#!/usr/bin/env python3
"""Exercise prior-run artifact provenance checks without contacting GitHub."""
from __future__ import annotations

import json
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "tools" / "verify_release_artifact_run.sh"
WORKFLOW = "workflow.yml"
ARTIFACT = "example-arm64-candidate"
RUN_ID = "123456"
REPO_ID = 998877


def run(*args: str, cwd: Path, env: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, cwd=cwd, env=env, text=True, capture_output=True, check=False)


def git(*args: str, cwd: Path) -> str:
    result = run("git", *args, cwd=cwd)
    if result.returncode:
        raise AssertionError(result.stderr)
    return result.stdout.strip()


def main() -> None:
    with tempfile.TemporaryDirectory(prefix="ternux-artifact-provenance-") as temp:
        base = Path(temp)
        repo = base / "repo"
        repo.mkdir()
        git("init", "-q", "-b", "main", cwd=repo)
        git("config", "user.name", "Ternux test", cwd=repo)
        git("config", "user.email", "test@example.invalid", cwd=repo)
        workflow_source = "jobs:\n  build:\n    runs-on: ubuntu-24.04\n    steps:\n      - run: compile-pinned-package\n  publish:\n    steps: []\n"
        (repo / "workflow.yml").write_text(workflow_source)
        (repo / "package-source.txt").write_text("package input v1\n")
        (repo / "docs.md").write_text("initial docs\n")
        git("add", ".", cwd=repo)
        git("commit", "-qm", "build input baseline", cwd=repo)
        source_sha = git("rev-parse", "HEAD", cwd=repo)
        (repo / "docs.md").write_text("docs-only follow-up\n")
        git("add", "docs.md", cwd=repo)
        git("commit", "-qm", "docs-only update", cwd=repo)
        release_sha = git("rev-parse", "HEAD", cwd=repo)

        bin_dir = base / "bin"
        bin_dir.mkdir()
        mock_gh = bin_dir / "gh"
        mock_gh.write_text("""#!/bin/sh
case "$2" in
  */actions/runs/*/artifacts?*) cat "$MOCK_ARTIFACTS" ;;
  */actions/runs/*) cat "$MOCK_RUN" ;;
  *) exit 90 ;;
esac
""")
        mock_gh.chmod(0o755)

        run_payload = {
            "id": int(RUN_ID), "status": "completed", "conclusion": "success",
            "path": WORKFLOW, "head_sha": source_sha,
            "repository": {"id": REPO_ID, "full_name": "soobujmiah/ternux"},
            "head_repository": {"id": REPO_ID, "full_name": "soobujmiah/ternux"},
        }
        artifact_payload = {
            "artifacts": [{
                "id": 5678, "name": ARTIFACT, "expired": False,
                "workflow_run": {"id": int(RUN_ID), "head_sha": source_sha, "repository_id": REPO_ID},
            }]
        }
        run_file = base / "run.json"
        artifact_file = base / "artifacts.json"
        run_file.write_text(json.dumps(run_payload))
        artifact_file.write_text(json.dumps(artifact_payload))
        env = os.environ.copy()
        env.update({
            "PATH": f"{bin_dir}:{env['PATH']}",
            "GITHUB_REPOSITORY": "soobujmiah/ternux",
            "GITHUB_SHA": release_sha,
            "GITHUB_ENV": str(base / "github-env"),
            "GITHUB_OUTPUT": str(base / "github-output"),
            "MOCK_RUN": str(run_file),
            "MOCK_ARTIFACTS": str(artifact_file),
        })
        good = run(str(SCRIPT), RUN_ID, WORKFLOW, ARTIFACT, WORKFLOW, "package-source.txt", cwd=repo, env=env)
        assert good.returncode == 0, good.stderr
        assert source_sha in good.stdout
        assert (base / "github-env").read_text().strip() == f"SOURCE_ARTIFACT_SHA={source_sha}"
        assert (base / "github-output").read_text().strip() == f"source_sha={source_sha}"

        # Safe publisher/retention edits leave the pinned build job unchanged,
        # so an inspected package can be retained without rebuilding it.
        workflow_retention = workflow_source.replace(
            "  publish:\n    steps: []\n",
            "  refresh_artifact:\n    steps: [reupload-exact-archive]\n  publish:\n    steps: []\n",
        )
        (repo / "workflow.yml").write_text(workflow_retention)
        git("add", "workflow.yml", cwd=repo)
        git("commit", "-qm", "add artifact retention job", cwd=repo)
        env["GITHUB_SHA"] = git("rev-parse", "HEAD", cwd=repo)
        safe_workflow_edit = run(
            str(SCRIPT), RUN_ID, WORKFLOW, ARTIFACT, WORKFLOW,
            "package-source.txt", cwd=repo, env=env,
        )
        assert safe_workflow_edit.returncode == 0, safe_workflow_edit.stderr

        wrong_workflow = dict(run_payload, path=".github/workflows/other.yml")
        run_file.write_text(json.dumps(wrong_workflow))
        bad = run(str(SCRIPT), RUN_ID, WORKFLOW, ARTIFACT, WORKFLOW, "package-source.txt", cwd=repo, env=env)
        assert bad.returncode != 0 and "different workflow" in bad.stderr
        run_file.write_text(json.dumps(run_payload))

        expired_payload = json.loads(artifact_file.read_text())
        expired_payload["artifacts"][0]["expired"] = True
        artifact_file.write_text(json.dumps(expired_payload))
        bad = run(str(SCRIPT), RUN_ID, WORKFLOW, ARTIFACT, WORKFLOW, "package-source.txt", cwd=repo, env=env)
        assert bad.returncode != 0 and "expired" in bad.stderr
        artifact_file.write_text(json.dumps(artifact_payload))

        (repo / "package-source.txt").write_text("package input v2\n")
        git("add", "package-source.txt", cwd=repo)
        git("commit", "-qm", "changed package input", cwd=repo)
        env["GITHUB_SHA"] = git("rev-parse", "HEAD", cwd=repo)
        bad = run(str(SCRIPT), RUN_ID, WORKFLOW, ARTIFACT, WORKFLOW, "package-source.txt", cwd=repo, env=env)
        assert bad.returncode != 0 and "build inputs changed" in bad.stderr

        workflow_changed = workflow_source.replace("compile-pinned-package", "compile-different-package")
        (repo / "workflow.yml").write_text(workflow_changed)
        git("add", "workflow.yml", cwd=repo)
        git("commit", "-qm", "changed build job", cwd=repo)
        env["GITHUB_SHA"] = git("rev-parse", "HEAD", cwd=repo)
        bad = run(str(SCRIPT), RUN_ID, WORKFLOW, ARTIFACT, WORKFLOW, "package-source.txt", cwd=repo, env=env)
        assert bad.returncode != 0 and "build-job definition changed" in bad.stderr

    print("release artifact provenance checks passed: success, safe retention edit, wrong workflow, expired artifact, changed package input, changed build job")


if __name__ == "__main__":
    main()
