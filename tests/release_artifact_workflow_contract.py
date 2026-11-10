#!/usr/bin/env python3
"""Contract checks for reuse, retention, and non-redundant artifact build triggers."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

workflows = {
    ".github/workflows/llama-vulkan-artifact.yml": (
        ".github/workflows/llama-vulkan-artifact.yml",
        "ternux-llama-vulkan-linux-arm64-b11582-candidate",
        "publish-preview",
    ),
    ".github/workflows/stable-diffusion-vulkan-artifact.yml": (
        ".github/workflows/stable-diffusion-vulkan-artifact.yml",
        "ternux-stable-diffusion-vulkan-linux-arm64-master-1053-candidate",
        "publish",
    ),
    ".github/workflows/llama-htp-artifact.yml": (
        ".github/workflows/llama-htp-artifact.yml",
        "ternux-llama-htp-sm8735-b11582",
        "publish",
    ),
}
for filename, (workflow, artifact, publisher) in workflows.items():
    text = (ROOT / filename).read_text(encoding="utf-8")
    assert "pull_request:" not in text, filename
    assert "source_run_id:" in text and "default: ''" in text, filename
    assert "if: github.event_name != 'workflow_dispatch' || inputs.source_run_id == ''" in text, filename
    assert "retention-days: 90" in text, filename
    assert "tools/verify_release_artifact_run.sh \"$SOURCE_RUN_ID\"" in text, filename
    assert "github.ref == 'refs/heads/main'" in text, filename
    assert "needs.build.result == 'skipped'" in text, filename
    assert "run-id: ${{ inputs.source_run_id || github.run_id }}" in text, filename
    assert "github-token: ${{ github.token }}" in text, filename
    assert "name: " + artifact in text, filename
    assert "  refresh_artifact:" in text, filename
    assert "needs: verify_source" in text, filename
    assert "Re-upload the exact inspected artifact with extended retention" in text, filename
    assert "actions/download-artifact@v7" in text, filename
    assert "actions/upload-artifact@v6" in text, filename
    assert "  " + publisher + ":" in text, filename

package_artifact = (ROOT / ".github/workflows/termux-apt-package.yml").read_text(encoding="utf-8")
assert "name: ternux-apt-unsigned-ci-${{ github.sha }}" in package_artifact
assert "retention-days: 90" in package_artifact, "unsigned Termux package artifact must remain available for release qualification"

deploy = (ROOT / ".github/workflows/deploy.yml").read_text(encoding="utf-8")
deploy_triggers = deploy.split("permissions:", 1)[0]
assert "workflow_dispatch:" in deploy_triggers
assert "push:" not in deploy_triggers, "production Pages deployment must not run on source pushes"
assert "uses: actions/deploy-pages@v5" in deploy

hmx = (ROOT / ".github/workflows/llama-htp-hmx-probe.yml").read_text(encoding="utf-8")
assert "pull_request:" not in hmx
assert "source_run_id:" in hmx
assert "if: github.event_name != 'workflow_dispatch' || inputs.source_run_id == ''" in hmx
assert "tools/verify_release_artifact_run.sh \"$SOURCE_RUN_ID\"" in hmx
assert "run-id: ${{ inputs.source_run_id }}" in hmx
assert "actions/download-artifact@v7" in hmx
assert "actions/upload-artifact@v6" in hmx
assert "retention-days: 90" in hmx

print("release artifact workflow contract passed: prior-run reuse, provenance, 90-day retention, manual-only heavy builds and production Pages deploy with reuse")
