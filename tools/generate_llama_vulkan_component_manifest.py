#!/usr/bin/env python3
"""Write a file-by-file source map for the pinned llama.cpp install tree."""

from __future__ import annotations

import hashlib
import json
import subprocess
import sys
from pathlib import Path

ARTIFACT = "ternux-llama-vulkan-linux-arm64-b11582"
WORKFLOW_SOURCE = ".github/workflows/llama-vulkan-artifact.yml"

BINARY_MODULES = {
    "llama": "app",
    "llama-batched": "examples/batched",
    "llama-batched-bench": "tools/batched-bench",
    "llama-bench": "tools/llama-bench",
    "llama-cli": "tools/cli",
    "llama-completion": "tools/completion",
    "llama-convert-llama2c-to-ggml": "examples/convert-llama2c-to-ggml",
    "llama-cvector-generator": "tools/cvector-generator",
    "llama-debug": "examples/debug",
    "llama-diffusion-cli": "examples/diffusion",
    "llama-embedding": "examples/embedding",
    "llama-eval-callback": "examples/eval-callback",
    "llama-export-lora": "tools/export-lora",
    "llama-finetune": "examples/training",
    "llama-fit-params": "tools/fit-params",
    "llama-gen-docs": "examples/gen-docs",
    "llama-gguf": "examples/gguf",
    "llama-gguf-hash": "examples/gguf-hash",
    "llama-gguf-split": "tools/gguf-split",
    "llama-idle": "examples/idle",
    "llama-imatrix": "tools/imatrix",
    "llama-lookahead": "examples/lookahead",
    "llama-lookup": "examples/lookup",
    "llama-lookup-create": "examples/lookup",
    "llama-lookup-merge": "examples/lookup",
    "llama-lookup-stats": "examples/lookup",
    "llama-mtmd-cli": "tools/mtmd",
    "llama-parallel": "examples/parallel",
    "llama-passkey": "examples/passkey",
    "llama-perplexity": "tools/perplexity",
    "llama-quantize": "tools/quantize",
    "llama-results": "tools/results",
    "llama-retrieval": "examples/retrieval",
    "llama-server": "tools/server",
    "llama-simple": "examples/simple",
    "llama-simple-chat": "examples/simple-chat",
    "llama-speculative": "examples/speculative",
    "llama-speculative-simple": "examples/speculative-simple",
    "llama-tokenize": "tools/tokenize",
    "llama-tts": "tools/tts",
}

LIBRARY_MODULES = {
    "libggml-base": "ggml/src",
    "libggml-cpu": "ggml/src/ggml-cpu",
    "libggml-vulkan": "ggml/src/ggml-vulkan",
    "libggml": "ggml/src",
    "libllama-common": "common",
    "libllama-batched-bench-impl": "tools/batched-bench",
    "libllama-bench-impl": "tools/llama-bench",
    "libllama-cli-impl": "tools/cli",
    "libllama-completion-impl": "tools/completion",
    "libllama-fit-params-impl": "tools/fit-params",
    "libllama-perplexity-impl": "tools/perplexity",
    "libllama-quantize-impl": "tools/quantize",
    "libllama-server-impl": "tools/server",
    "libllama": "src",
    "libmtmd": "tools/mtmd",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        while chunk := stream.read(1024 * 1024):
            digest.update(chunk)
    return digest.hexdigest()


def source_for(relative: str, source_root: Path, project_root: Path, license_index: set[str]) -> tuple[str, list[str]]:
    path = Path(relative)
    if relative == "COMPONENTS.json":
        raise ValueError("component manifest must not map itself")
    if path.parts[0] == "bin":
        module = BINARY_MODULES.get(path.name)
        if not module:
            raise ValueError(f"no upstream module mapping for executable {path.name}")
        return module, [module]
    if path.parts[0] == "lib" and path.name.endswith((".so", ".so.0", ".so.0.6.0", ".so.0.26.0")):
        for prefix, module in sorted(LIBRARY_MODULES.items(), key=lambda item: -len(item[0])):
            if path.name.startswith(prefix):
                return module, [module]
        if relative.startswith("lib/cmake/llama/"):
            return "upstream CMake package metadata", ["cmake"]
        if relative.startswith("lib/cmake/ggml/"):
            return "ggml CMake package metadata", ["ggml/cmake"]
    if relative.startswith("lib/cmake/llama/"):
        return "upstream CMake package metadata", ["cmake"]
    if relative.startswith("lib/cmake/ggml/"):
        return "ggml CMake package metadata", ["ggml/cmake"]
    if relative.startswith("lib/pkgconfig/"):
        return "upstream pkg-config metadata", ["cmake"]
    if relative.startswith("include/ggml") or relative.startswith("include/gguf"):
        return "ggml public headers", ["ggml/include"]
    if relative.startswith("include/llama"):
        return "llama.cpp public headers", ["include"]
    if relative.startswith("include/mtmd"):
        return "multimodal public headers", ["tools/mtmd"]
    if relative == "LLAMA-CPP-LICENSE":
        return "upstream root license copy", ["LICENSE"]
    if relative.startswith("share/licenses/upstream/"):
        item = relative.removeprefix("share/licenses/upstream/")
        if item in license_index:
            return "upstream notice copied from the pinned source tree", [item]
        return "Ternux-generated license index/checksum/readme", [WORKFLOW_SOURCE]
    if relative in {"README.txt", "build-manifest.json", "env.sh"}:
        return "Ternux artifact metadata/runtime wrapper", [WORKFLOW_SOURCE]
    raise ValueError(f"no source component mapping for packaged file {relative}")


def main() -> int:
    if len(sys.argv) not in {3, 4}:
        print(f"usage: {Path(sys.argv[0]).name} PACKAGE_ROOT UPSTREAM_SOURCE [TERNUX_SOURCE]", file=sys.stderr)
        return 2
    package = Path(sys.argv[1]).resolve()
    source = Path(sys.argv[2]).resolve()
    try:
        manifest_path = package / "build-manifest.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        actual_commit = subprocess.check_output(
            ["git", "-C", str(source), "rev-parse", "HEAD"], text=True
        ).strip()
        project_root = Path(sys.argv[3]).resolve() if len(sys.argv) == 4 else Path(__file__).resolve().parents[1]
        project_commit = subprocess.check_output(
            ["git", "-C", str(project_root), "rev-parse", "HEAD"], text=True
        ).strip()
        if manifest.get("ternux_commit") and manifest["ternux_commit"] != project_commit:
            raise ValueError("package and checked-out Ternux commits do not match")
        if manifest.get("artifact") != ARTIFACT:
            raise ValueError("unexpected artifact name")
        if manifest.get("upstream_commit") != actual_commit:
            raise ValueError("package and checked-out upstream commits do not match")
        license_index = set(
            (package / "share/licenses/upstream/INDEX.txt")
            .read_text(encoding="utf-8").splitlines()
        )
        records = []
        for path in sorted(package.rglob("*")):
            if path.is_dir() or path.name == "COMPONENTS.json":
                continue
            relative = path.relative_to(package).as_posix()
            component, sources = source_for(relative, source, project_root, license_index)
            project_sources = [item for item in sources if item == WORKFLOW_SOURCE]
            source_base = project_root if project_sources else source
            missing = [item for item in sources if not (source_base / item).exists()]
            if missing:
                raise ValueError(f"{relative}: mapped source path is absent: {missing}")
            records.append({
                "path": relative,
                "sha256": sha256(path),
                "component": component,
                "source_repository": "https://github.com/soobujmiah/ternux" if project_sources else manifest["upstream"],
                "source_commit": project_commit if project_sources else actual_commit,
                "source_paths": sources,
                "license_inventory": manifest["upstream_license_bundle"],
            })
        if not records:
            raise ValueError("package install tree is empty")
        document = {
            "schema_version": 1,
            "artifact": ARTIFACT,
            "target": manifest["target"],
            "upstream": manifest["upstream"],
            "upstream_tag": manifest["upstream_tag"],
            "upstream_commit": actual_commit,
            "ternux_commit": project_commit,
            "build_configuration": manifest["cmake_options"],
            "runtime_dependencies": manifest["system_runtime_dependencies"],
            "license_scope": "The pinned upstream source's complete tracked license/notice inventory is shipped at the referenced path. This map identifies build components; it does not assign a single license to every generated binary.",
            "files": records,
        }
        output = package / "COMPONENTS.json"
        output.write_text(json.dumps(document, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"Wrote {len(records)} source-mapped package files to {output}")
        return 0
    except (OSError, ValueError, KeyError, json.JSONDecodeError, subprocess.CalledProcessError) as error:
        print(f"llama.cpp component-map generation failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
