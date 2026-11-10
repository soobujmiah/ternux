#!/usr/bin/env bash
# Verify a prior successful, same-repository build artifact before release reuse.
set -euo pipefail

if [ "$#" -lt 4 ]; then
  echo "Usage: $0 RUN_ID WORKFLOW_PATH ARTIFACT_NAME SOURCE_PATH..." >&2
  exit 2
fi
run_id="$1"; shift
workflow_path="$1"; shift
artifact_name="$1"; shift
[[ "$run_id" =~ ^[0-9]+$ ]] || { echo "Invalid Actions run ID." >&2; exit 2; }
[ "$#" -gt 0 ] || { echo "At least one artifact input path is required." >&2; exit 2; }
repo="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
release_sha="${GITHUB_SHA:?GITHUB_SHA is required}"
[[ "$release_sha" =~ ^[0-9a-f]{40}$ ]] || { echo "Invalid release commit SHA." >&2; exit 2; }

run_json="$(gh api "repos/$repo/actions/runs/$run_id")"
source_metadata="$(python3 - "$run_json" "$repo" "$workflow_path" <<'PY'
import json, re, sys
run = json.loads(sys.argv[1])
repo, path = sys.argv[2:]
if run.get("status") != "completed" or run.get("conclusion") != "success":
    raise SystemExit("Source Actions run is not completed successfully.")
if run.get("path") != path:
    raise SystemExit("Source Actions run used a different workflow file.")
if run.get("repository", {}).get("full_name", "").lower() != repo.lower():
    raise SystemExit("Source Actions run belongs to a different repository.")
if run.get("head_repository", {}).get("full_name", "").lower() != repo.lower():
    raise SystemExit("Fork-originated build artifacts cannot be reused.")
sha = run.get("head_sha", "")
if not re.fullmatch(r"[0-9a-f]{40}", sha):
    raise SystemExit("Source Actions run has no valid commit SHA.")
repository_id = run.get("repository", {}).get("id")
if not isinstance(repository_id, int):
    raise SystemExit("Source Actions run has no repository ID.")
print(sha)
print(repository_id)
PY
)"
source_sha="${source_metadata%%$'\n'*}"
repository_id="${source_metadata#*$'\n'}"

artifact_json="$(gh api "repos/$repo/actions/runs/$run_id/artifacts?per_page=100")"
python3 - "$artifact_json" "$run_id" "$artifact_name" "$source_sha" "$repository_id" <<'PY'
import json, sys
payload = json.loads(sys.argv[1])
run_id, expected_name, source_sha, repository_id = sys.argv[2:]
artifacts = [a for a in payload.get("artifacts", []) if a.get("name") == expected_name]
if len(artifacts) != 1:
    raise SystemExit("Source run must contain exactly one artifact with the expected name.")
artifact = artifacts[0]
if artifact.get("expired") is not False:
    raise SystemExit("Source artifact is expired or its expiry state is unknown.")
origin = artifact.get("workflow_run", {})
if str(origin.get("id")) != run_id or origin.get("head_sha") != source_sha:
    raise SystemExit("Artifact provenance does not match the selected workflow run.")
if str(origin.get("repository_id")) != repository_id:
    raise SystemExit("Artifact belongs to a different repository.")
PY

git cat-file -e "$source_sha^{commit}"
git cat-file -e "$release_sha^{commit}"
git merge-base --is-ancestor "$source_sha" "$release_sha" || {
  echo "Source build commit is not an ancestor of the release commit." >&2
  exit 1
}
python3 - "$source_sha" "$release_sha" "$workflow_path" <<'PY_BUILD_JOB'
import difflib
import re
import subprocess
import sys

source_sha, release_sha, workflow_path = sys.argv[1:]

def build_job(revision: str) -> str:
    content = subprocess.run(
        ["git", "show", f"{revision}:{workflow_path}"],
        check=True, capture_output=True, text=True,
    ).stdout
    lines = content.splitlines()
    try:
        jobs = lines.index("jobs:")
        start = lines.index("  build:", jobs)
    except ValueError as error:
        raise SystemExit(f"Cannot locate build job in {workflow_path} at {revision}.") from error
    end = next((i for i in range(start + 1, len(lines))
                if re.fullmatch(r"  [A-Za-z0-9_-]+:", lines[i])), len(lines))
    normalized = []
    for line in lines[start:end]:
        if line.strip().startswith("retention-days:"):
            continue
        if line.strip() == "if: github.event_name != 'workflow_dispatch' || inputs.source_run_id == ''":
            continue
        normalized.append(line)
    return "\n".join(normalized).rstrip()

before, after = build_job(source_sha), build_job(release_sha)
if before != after:
    print("Pinned build-job definition changed after the selected artifact run:", file=sys.stderr)
    print("\n".join(difflib.unified_diff(before.splitlines(), after.splitlines(),
                                         fromfile="artifact-build", tofile="release-build")), file=sys.stderr)
    raise SystemExit(1)
PY_BUILD_JOB

build_inputs=()
for input_path in "$@"; do
  # The workflow's build job is compared structurally above; allow safe
  # provenance, publication, and retention-job changes without invalidating
  # an already verified package build.
  [ "$input_path" = "$workflow_path" ] && continue
  build_inputs+=("$input_path")
done
[ "${#build_inputs[@]}" -gt 0 ] || {
  echo "No package build inputs remain to verify." >&2
  exit 2
}
git diff --quiet "$source_sha" "$release_sha" -- "${build_inputs[@]}" || {
  echo "Artifact build inputs changed after the selected build; rebuild the package." >&2
  exit 1
}
printf 'Verified reusable artifact: workflow=%s run=%s source=%s artifact=%s\n' \
  "$workflow_path" "$run_id" "$source_sha" "$artifact_name"
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  printf 'source_sha=%s\n' "$source_sha" >> "$GITHUB_OUTPUT"
fi
if [ -n "${GITHUB_ENV:-}" ]; then
  printf 'SOURCE_ARTIFACT_SHA=%s\n' "$source_sha" >> "$GITHUB_ENV"
fi
