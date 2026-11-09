#!/usr/bin/env python3
"""Build a deterministic notice bundle for the Stable Diffusion extension."""
from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path, PurePosixPath
import shutil

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


def collect_files(trees: list[tuple[str, Path]], extras: list[tuple[Path, str]]) -> dict[str, bytes]:
    result: dict[str, bytes] = {}
    for label, root in trees:
        label_path = _relative(label)
        root = root.resolve(strict=True)
        if not root.is_dir():
            raise ValueError(f"license source tree is not a directory: {root}")
        for current, dirs, files in os.walk(root, followlinks=False):
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
    for source, destination in extras:
        source = source.resolve(strict=True)
        if not source.is_file():
            raise ValueError(f"additional notice is not a regular file: {source}")
        relative = _relative(destination).as_posix()
        if relative in result:
            raise ValueError(f"duplicate bundle path: {relative}")
        result[relative] = source.read_bytes()
    return result


def build_bundle(trees: list[tuple[str, Path]], extras: list[tuple[Path, str]],
                 output: Path, required: list[str]) -> list[str]:
    output = output.absolute()
    if output.is_symlink():
        raise ValueError(f"refusing symlinked output directory: {output}")
    if output.exists() and any(output.iterdir()):
        raise ValueError(f"refusing non-empty output directory: {output}")
    files = collect_files(trees, extras)
    missing = sorted(set(required) - files.keys())
    if missing:
        raise ValueError(f"required license files were not collected: {', '.join(missing)}")
    if not files:
        raise ValueError("no upstream or project license files found")
    output.mkdir(parents=True, exist_ok=True)
    for relative, content in sorted(files.items()):
        target = output.joinpath(*_relative(relative).parts)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(content)
    index = sorted(files)
    (output / "INDEX.txt").write_text("\n".join(index) + "\n", encoding="utf-8")
    checksums = [f"{hashlib.sha256(files[name]).hexdigest()}  {name}" for name in index]
    (output / "SHA256SUMS").write_text("\n".join(checksums) + "\n", encoding="utf-8")
    (output / "README.md").write_text(
        "Upstream license and notice files copied from the exact Stable Diffusion "
        "source checkout and CMake dependency trees used by this build. Paths in "
        "INDEX.txt preserve their source-tree roots. Ternux's project LICENSE and "
        "NOTICE are included at the bundle root. SHA256SUMS covers every indexed "
        "license/notice file.\n",
        encoding="utf-8",
    )
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
    parser.add_argument("--extra", action="append", type=_extra, default=[], metavar="SOURCE=ARCHIVE_PATH")
    parser.add_argument("--require", action="append", default=[], metavar="ARCHIVE_PATH")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    try:
        index = build_bundle(args.tree, args.extra, args.output, args.require)
    except (OSError, ValueError) as exc:
        parser.error(str(exc))
    print(f"Bundled {len(index)} license/notice files in {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
