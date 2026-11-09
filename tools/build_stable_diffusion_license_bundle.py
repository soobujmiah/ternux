#!/usr/bin/env python3
"""Build a deterministic upstream and transitive notice bundle for sd-cli."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath

PREFIXES = (
    "license", "licence", "copying", "notice", "copyright", "author",
    "patent", "unlicense", "credit",
)


def _relative(value: str) -> PurePosixPath:
    path = PurePosixPath(value)
    if path.is_absolute() or not path.parts or any(part in ("", ".", "..") for part in path.parts):
        raise ValueError(f"unsafe bundle path: {value}")
    return path


def is_license_file(name: str) -> bool:
    return name.casefold().startswith(PREFIXES)


def _read_tree(label: str, path: Path, *, optional: bool) -> tuple[Path | None, bool]:
    if not path.exists():
        if optional:
            return None, False
        raise FileNotFoundError(f"required source tree is missing: {label}={path}")
    root = path.resolve(strict=True)
    if not root.is_dir():
        raise ValueError(f"license source tree is not a directory: {root}")
    return root, True


def _collect_tree(result: dict[str, bytes], label: str, root: Path) -> int:
    label_path = _relative(label)
    count = 0
    for current, dirs, files in os.walk(root, followlinks=False):
        if any(Path(current, directory).is_symlink() for directory in dirs):
            raise ValueError(f"symlinked directory in license source tree: {current}")
        dirs[:] = sorted(d for d in dirs if d != ".git")
        for filename in sorted(files):
            if not is_license_file(filename):
                continue
            candidate = Path(current, filename)
            resolved = candidate.resolve(strict=True)
            if not resolved.is_file() or not resolved.is_relative_to(root):
                raise ValueError(f"license candidate escapes source tree: {candidate}")
            relative = candidate.relative_to(root).as_posix()
            destination = (label_path / _relative(relative)).as_posix()
            if destination in result:
                raise ValueError(f"duplicate bundle path: {destination}")
            result[destination] = resolved.read_bytes()
            count += 1
    return count


def _load_components(path: Path) -> dict:
    manifest = json.loads(path.read_text(encoding="utf-8"))
    if manifest.get("schema_version") != 1:
        raise ValueError("unsupported Stable Diffusion component manifest schema")
    components = manifest.get("components")
    if not isinstance(components, list) or not components:
        raise ValueError("component manifest must contain a non-empty components list")
    ids = [component.get("id") for component in components]
    if any(not isinstance(item, str) or not item for item in ids) or len(ids) != len(set(ids)):
        raise ValueError("component IDs must be non-empty and unique")
    for component in components:
        if not component.get("license"):
            raise ValueError(f"component has no declared license: {component.get('id')}")
        if not component.get("source_tree") and not component.get("archive_license_files"):
            raise ValueError(f"component has no source tree or archive license paths: {component.get('id')}")
        if not component.get("license_files") and not component.get("embedded_notice_sources") and not component.get("archive_license_files"):
            raise ValueError(f"component has no bundled license evidence: {component.get('id')}")
    return manifest


def collect_files(trees: list[tuple[str, Path]], optional_trees: list[tuple[str, Path]],
                  extras: list[tuple[Path, str]], components: dict) -> tuple[dict[str, bytes], list[dict]]:
    result: dict[str, bytes] = {}
    roots: dict[str, Path] = {}
    metadata: list[dict] = []
    for label, path in trees:
        if label in roots:
            raise ValueError(f"duplicate source tree label: {label}")
        root, present = _read_tree(label, path, optional=False)
        assert root is not None
        roots[label] = root
        metadata.append({"label": label, "present": present,
                         "notice_files": _collect_tree(result, label, root)})
    for label, path in optional_trees:
        if label in roots:
            raise ValueError(f"duplicate source tree label: {label}")
        root, present = _read_tree(label, path, optional=True)
        if root is not None:
            roots[label] = root
            notice_count = _collect_tree(result, label, root)
        else:
            notice_count = 0
        metadata.append({"label": label, "present": present,
                         "notice_files": notice_count})

    for component in components["components"]:
        label = component.get("source_tree")
        if label is None:
            continue
        if label not in roots:
            raise ValueError(f"component source tree is missing: {component['id']}: {label}")
        tree_root = roots[label]
        for relative in component.get("embedded_notice_sources", []):
            rel = _relative(relative)
            source = tree_root.joinpath(*rel.parts)
            resolved = source.resolve(strict=True)
            if not resolved.is_file() or not resolved.is_relative_to(tree_root):
                raise ValueError(f"embedded notice source escapes source tree: {source}")
            destination = (_relative("source-notices") / _relative(label) / rel).as_posix()
            if destination in result:
                raise ValueError(f"duplicate bundle path: {destination}")
            result[destination] = resolved.read_bytes()

    for source, destination in extras:
        source = source.resolve(strict=True)
        if not source.is_file():
            raise ValueError(f"additional notice is not a regular file: {source}")
        relative = _relative(destination).as_posix()
        if relative in result:
            raise ValueError(f"duplicate bundle path: {relative}")
        result[relative] = source.read_bytes()

    for component in components["components"]:
        label = component.get("source_tree")
        if label is not None:
            label_path = _relative(label)
            for path in component.get("license_files", []):
                archive_path = (label_path / _relative(path)).as_posix()
                if archive_path not in result:
                    raise ValueError(f"required component license missing: {component['id']}: {archive_path}")
            for path in component.get("embedded_notice_sources", []):
                archive_path = (_relative("source-notices") / label_path / _relative(path)).as_posix()
                if archive_path not in result:
                    raise ValueError(f"embedded component notice source missing: {component['id']}: {archive_path}")
        for path in component.get("archive_license_files", []):
            archive_path = _relative(path).as_posix()
            if archive_path not in result:
                raise ValueError(f"required archive license missing: {component['id']}: {archive_path}")
    return result, metadata


def build_bundle(trees: list[tuple[str, Path]], optional_trees: list[tuple[str, Path]],
                 extras: list[tuple[Path, str]], components_path: Path, output: Path,
                 required: list[str]) -> list[str]:
    output = output.absolute()
    if output.is_symlink():
        raise ValueError(f"refusing symlinked output directory: {output}")
    if output.exists() and any(output.iterdir()):
        raise ValueError(f"refusing non-empty output directory: {output}")
    components = _load_components(components_path)
    files, tree_metadata = collect_files(trees, optional_trees, extras, components)
    missing = sorted(set(required) - files.keys())
    if missing:
        raise ValueError(f"required license files were not collected: {', '.join(missing)}")
    if not files:
        raise ValueError("no upstream or project license files found")

    files["COMPONENTS.json"] = (json.dumps(components, indent=2, sort_keys=True) + "\n").encode()
    metadata = {"schema_version": 1, "source_trees": sorted(tree_metadata, key=lambda item: item["label"]),
                "inventory_note": "A missing optional source tree is recorded explicitly; it is not treated as an empty existing tree."}
    files["BUNDLE-METADATA.json"] = (json.dumps(metadata, indent=2, sort_keys=True) + "\n").encode()
    files["README.md"] = (
        "This bundle contains license and attribution files for the exact pinned "
        "Stable Diffusion build components listed in COMPONENTS.json. License "
        "files from source trees are preserved under their tree paths. For "
        "components whose notices are embedded in source headers, the exact "
        "upstream headers are copied under source-notices/. BUNDLE-METADATA.json "
        "records which required and optional source trees were scanned. The Ternux "
        "LICENSE and NOTICE are also included. SHA256SUMS covers every payload "
        "file listed in INDEX.txt.\n"
    ).encode()
    index = sorted(files)
    output.mkdir(parents=True, exist_ok=True)
    for relative, content in sorted(files.items()):
        target = output.joinpath(*_relative(relative).parts)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(content)
    (output / "INDEX.txt").write_text("\n".join(index) + "\n", encoding="utf-8")
    checksums = [f"{hashlib.sha256(files[name]).hexdigest()}  {name}" for name in index]
    (output / "SHA256SUMS").write_text("\n".join(checksums) + "\n", encoding="utf-8")
    return index


def _tree(value: str) -> tuple[str, Path]:
    if "=" not in value:
        raise argparse.ArgumentTypeError("tree must be LABEL=PATH")
    label, path = value.split("=", 1)
    try:
        _relative(label)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(str(exc)) from exc
    return label, Path(path)


def _extra(value: str) -> tuple[Path, str]:
    if "=" not in value:
        raise argparse.ArgumentTypeError("extra must be SOURCE=ARCHIVE_PATH")
    source, destination = value.split("=", 1)
    try:
        _relative(destination)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(str(exc)) from exc
    return Path(source), destination


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tree", action="append", type=_tree, default=[], metavar="LABEL=PATH")
    parser.add_argument("--optional-tree", action="append", type=_tree, default=[], metavar="LABEL=PATH")
    parser.add_argument("--extra", action="append", type=_extra, default=[], metavar="SOURCE=ARCHIVE_PATH")
    parser.add_argument("--components", type=Path, required=True)
    parser.add_argument("--require", action="append", default=[], metavar="ARCHIVE_PATH")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    try:
        index = build_bundle(args.tree, args.optional_tree, args.extra, args.components,
                             args.output, args.require)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        parser.error(str(exc))
    print(f"Bundled {len(index)} license/notice items in {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
