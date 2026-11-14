#!/usr/bin/env python3
"""Keep the source-map CI candidate safe and publish behind an explicit main gate."""
from pathlib import Path
import sys

root = Path(sys.argv[1]) if len(sys.argv) == 2 else Path(__file__).resolve().parents[1]
workflow = (root / ".github/workflows/llama-vulkan-artifact.yml").read_text(encoding="utf-8")
header, jobs = workflow.split("jobs:", 1)
assert "pull_request:" not in header
assert '"tools/generate_llama_vulkan_component_manifest.py"' in workflow
assert "contents: read" in header and "contents: write" not in header
assert "workflow_dispatch:" in header and "default: false" in header
assert "source_run_id:" in header and "source_run_id" in workflow
build, publisher = jobs.split("  publish-preview:", 1)
assert 'python3 tools/generate_llama_vulkan_component_manifest.py "$package" llama.cpp .' in build
assert 'python3 tests/llama_vulkan_abi_audit.py "$package"' in build
assert "Upload inspected candidate artifact" in build
assert "actions/upload-artifact@v6" in build
assert "gh release upload" not in build and "gh release create" not in build
assert "github.event_name == 'workflow_dispatch'" in publisher
assert "inputs.publish_preview == true" in publisher
assert "github.ref == 'refs/heads/main'" in publisher
assert "contents: write" in publisher and "actions: read" in publisher
assert "actions/download-artifact@v8" in publisher
assert "sha256sum --check" in publisher
assert "gh release upload" in publisher and "gh release create" in publisher
print("llama.cpp manually dispatched source-map candidate, reusable artifact, and explicit main-only publisher contract passed")
