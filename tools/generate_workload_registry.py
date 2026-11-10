#!/usr/bin/env python3
"""Validate Ternux workload metadata and render its Bash runtime registry."""

from __future__ import annotations

import argparse
import json
import re
import shlex
import sys
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
SCHEMA_PATH = ROOT / "packaging/workloads.schema.json"
MANIFEST_PATH = ROOT / "packaging/workloads.json"
OUTPUT_PATH = ROOT / "lib/workload-registry.sh"
WORKLOAD_REQUIRED = {
    "id", "display_name", "version", "architecture", "backends", "dependencies",
    "installation_source", "checksums", "license_metadata", "required_permissions",
    "hardware_requirements", "verification_commands", "cleanup_behavior",
    "support_status", "availability", "availability_note", "installer",
}


def fail(message: str) -> None:
    raise ValueError(message)


def exact_keys(obj: object, required: set[str], context: str) -> dict:
    if not isinstance(obj, dict):
        fail(f"{context} must be an object")
    missing = required - obj.keys()
    extra = obj.keys() - required
    if missing or extra:
        fail(f"{context} keys mismatch; missing={sorted(missing)}, extra={sorted(extra)}")
    return obj


def string(value: object, context: str, *, allow_empty: bool = False) -> str:
    if not isinstance(value, str) or (not allow_empty and not value.strip()):
        fail(f"{context} must be a {'possibly empty ' if allow_empty else ''}string")
    return value


def string_list(value: object, context: str, *, allow_empty: bool = False) -> list[str]:
    if not isinstance(value, list) or (not allow_empty and not value):
        fail(f"{context} must be a {'possibly empty ' if allow_empty else 'non-empty '}array")
    if any(not isinstance(item, str) or not item.strip() for item in value):
        fail(f"{context} entries must be non-empty strings")
    if len(value) != len(set(value)):
        fail(f"{context} contains duplicates")
    return value


def safe_relative_paths(paths: list[str], context: str) -> None:
    for path in paths:
        if path.startswith("/") or "\\" in path or any(part in ("", ".", "..") for part in path.split("/")):
            fail(f"{context} contains an unsafe path: {path!r}")


def validate_schema_shape(schema: dict) -> None:
    try:
        required = set(schema["properties"]["workloads"]["items"]["required"])
        item_props = schema["properties"]["workloads"]["items"]["properties"]
    except (KeyError, TypeError) as exc:
        fail(f"workload schema has no supported structure: {exc}")
    if required != WORKLOAD_REQUIRED or set(item_props) != WORKLOAD_REQUIRED:
        fail("schema workload fields do not match the registry generator's contract")
    if schema.get("additionalProperties") is not False or schema.get("schema_version"):
        fail("unsupported schema structure")


def validate(manifest: dict, schema: dict) -> list[dict]:
    validate_schema_shape(schema)
    exact_keys(manifest, {"schema_version", "workloads"}, "manifest")
    if manifest["schema_version"] != 1:
        fail("schema_version must equal 1")
    workloads = manifest["workloads"]
    if not isinstance(workloads, list) or not workloads:
        fail("workloads must be a non-empty array")
    seen: set[str] = set()
    for index, raw in enumerate(workloads):
        context = f"workloads[{index}]"
        w = exact_keys(raw, WORKLOAD_REQUIRED, context)
        wid = string(w["id"], f"{context}.id")
        if not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", wid):
            fail(f"{context}.id is not a safe workload identifier")
        if wid in seen:
            fail(f"duplicate workload id: {wid}")
        seen.add(wid)
        string(w["display_name"], f"{context}.display_name")
        string(w["version"], f"{context}.version")
        if w["architecture"] != "aarch64":
            fail(f"{context}.architecture must be aarch64")
        string_list(w["backends"], f"{context}.backends")
        deps = exact_keys(w["dependencies"], {"debian_packages", "runtime_libraries"}, f"{context}.dependencies")
        for field in deps:
            string_list(deps[field], f"{context}.dependencies.{field}", allow_empty=(field == "debian_packages"))
        src = exact_keys(w["installation_source"], {"type", "repository", "release_tag", "asset", "source_repository", "source_version", "source_commit", "manifest_path"}, f"{context}.installation_source")
        if src["type"] != "github_release":
            fail(f"{context} source must be a GitHub release")
        for field in ("repository", "source_repository"):
            url = string(src[field], f"{context}.installation_source.{field}")
            parsed = urlparse(url)
            if parsed.scheme != "https" or not parsed.netloc:
                fail(f"{context}.installation_source.{field} must be HTTPS")
        for field in ("release_tag", "asset", "source_version", "manifest_path"):
            string(src[field], f"{context}.installation_source.{field}")
        if not re.fullmatch(r"[A-Za-z0-9._-]+", src["release_tag"]):
            fail(f"{context}.installation_source.release_tag is not a safe tag")
        safe_relative_paths([src["manifest_path"]], f"{context}.installation_source.manifest_path")
        if src["asset"] != f"{src['release_tag']}.tar.gz":
            fail(f"{context}.asset must be the release tag's .tar.gz asset")
        if not re.fullmatch(r"[0-9a-f]{40}", src["source_commit"]):
            fail(f"{context}.source_commit must be a full lowercase Git SHA")
        checks = exact_keys(w["checksums"], {"algorithm", "archive_sha256", "sidecar_sha256"}, f"{context}.checksums")
        if checks["algorithm"] != "sha256":
            fail(f"{context}.checksums.algorithm must be sha256")
        for field in ("archive_sha256", "sidecar_sha256"):
            if not re.fullmatch(r"[0-9a-f]{64}", str(checks[field])):
                fail(f"{context}.checksums.{field} must be 64 lowercase hex characters")
        lic = exact_keys(w["license_metadata"], {"status", "inventory_path", "checksum_path", "license_expressions", "limitations"}, f"{context}.license_metadata")
        if lic["status"] not in ("audited", "incomplete"):
            fail(f"{context}.license_metadata.status is invalid")
        for field in ("inventory_path", "checksum_path"):
            if lic[field] is not None:
                string(lic[field], f"{context}.license_metadata.{field}")
        string_list(lic["license_expressions"], f"{context}.license_metadata.license_expressions")
        string_list(lic["limitations"], f"{context}.license_metadata.limitations", allow_empty=True)
        if lic["status"] == "incomplete" and w["support_status"] != "experimental":
            fail(f"{context} incomplete license metadata must remain experimental")
        for field in ("required_permissions", "hardware_requirements", "verification_commands"):
            string_list(w[field], f"{context}.{field}", allow_empty=(field == "required_permissions"))
        string(w["cleanup_behavior"], f"{context}.cleanup_behavior")
        if w["support_status"] not in ("supported", "experimental"):
            fail(f"{context}.support_status is invalid")
        if w["availability"] not in ("available", "blocked"):
            fail(f"{context}.availability is invalid")
        string(w["availability_note"], f"{context}.availability_note", allow_empty=True)
        if w["availability"] == "blocked" and not w["availability_note"].strip():
            fail(f"{context} blocked availability needs an explanation")
        inst = exact_keys(w["installer"], {"minimum_glibc", "primary_binary", "required_executables", "required_files", "required_directories", "environment_file", "host_dependency_profile", "dependency_hint", "post_install_notes"}, f"{context}.installer")
        if not re.fullmatch(r"2\.[0-9]+", str(inst["minimum_glibc"])):
            fail(f"{context}.installer.minimum_glibc is invalid")
        string(inst["primary_binary"], f"{context}.installer.primary_binary")
        for field in ("required_executables", "required_files", "required_directories"):
            values = string_list(inst[field], f"{context}.installer.{field}", allow_empty=True)
            safe_relative_paths(values, f"{context}.installer.{field}")
        if inst["environment_file"] is not None:
            safe_relative_paths([string(inst["environment_file"], f"{context}.installer.environment_file")], f"{context}.installer.environment_file")
        for field in ("host_dependency_profile", "dependency_hint"):
            string(inst[field], f"{context}.installer.{field}", allow_empty=(field == "host_dependency_profile"))
        string_list(inst["post_install_notes"], f"{context}.installer.post_install_notes", allow_empty=True)
    return workloads


def shell_quote(value: object) -> str:
    return shlex.quote("" if value is None else str(value))


def flattened(workload: dict) -> dict[str, str]:
    src, deps, checks = workload["installation_source"], workload["dependencies"], workload["checksums"]
    lic, inst = workload["license_metadata"], workload["installer"]
    return {
        "display_name": workload["display_name"],
        "version": workload["version"],
        "architecture": workload["architecture"],
        "backends": " ".join(workload["backends"]),
        "debian_packages": " ".join(deps["debian_packages"]),
        "runtime_libraries": "\n".join(deps["runtime_libraries"]),
        "release_repository": src["repository"],
        "release_tag": src["release_tag"],
        "asset": src["asset"],
        "source_repository": src["source_repository"],
        "source_version": src["source_version"],
        "source_commit": src["source_commit"],
        "manifest_path": src["manifest_path"],
        "archive_sha256": checks["archive_sha256"],
        "sidecar_sha256": checks["sidecar_sha256"],
        "license_status": lic["status"],
        "license_inventory_path": lic["inventory_path"],
        "license_checksum_path": lic["checksum_path"],
        "license_expressions": "\n".join(lic["license_expressions"]),
        "license_limitations": "\n".join(lic["limitations"]),
        "required_permissions": "\n".join(workload["required_permissions"]),
        "hardware_requirements": "\n".join(workload["hardware_requirements"]),
        "verification_commands": "\n".join(workload["verification_commands"]),
        "cleanup_behavior": workload["cleanup_behavior"],
        "support_status": workload["support_status"],
        "availability": workload["availability"],
        "availability_note": workload["availability_note"],
        "minimum_glibc": inst["minimum_glibc"],
        "primary_binary": inst["primary_binary"],
        "required_executables": "\n".join(inst["required_executables"]),
        "required_files": "\n".join(inst["required_files"]),
        "required_directories": "\n".join(inst["required_directories"]),
        "environment_file": inst["environment_file"],
        "host_dependency_profile": inst["host_dependency_profile"],
        "dependency_hint": inst["dependency_hint"],
        "post_install_notes": "\n".join(inst["post_install_notes"]),
    }


def render(workloads: list[dict]) -> str:
    ids = " ".join(shell_quote(w["id"]) for w in workloads)
    lines = [
        "#!/usr/bin/env bash",
        "# Generated by tools/generate_workload_registry.py from packaging/workloads.json.",
        "# Do not edit this file by hand; run the generator and commit its output.",
        f"declare -ag TNX_WORKLOAD_IDS=({ids})",
        "declare -Ag TNX_WORKLOAD=()",
    ]
    for workload in workloads:
        wid = workload["id"]
        for field, value in flattened(workload).items():
            lines.append(f"TNX_WORKLOAD[{shell_quote(wid + '|' + field)}]={shell_quote(value)}")
    lines.extend([
        "",
        "tnx_workload_get() {",
        "  local key=\"${1:?workload id required}|${2:?field required}\"",
        "  [[ ${TNX_WORKLOAD[\"$key\"]+present} ]] || return 1",
        "  printf '%s' \"${TNX_WORKLOAD[\"$key\"]}\"",
        "}",
        "",
    ])
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=MANIFEST_PATH)
    parser.add_argument("--schema", type=Path, default=SCHEMA_PATH)
    parser.add_argument("--output", type=Path, default=OUTPUT_PATH)
    parser.add_argument("--check", action="store_true", help="fail if the checked-in generated file differs")
    args = parser.parse_args()
    try:
        schema = json.loads(args.schema.read_text(encoding="utf-8"))
        manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
        output = render(validate(manifest, schema))
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        print(f"workload registry: {exc}", file=sys.stderr)
        return 1
    if args.check:
        try:
            current = args.output.read_text(encoding="utf-8")
        except OSError as exc:
            print(f"workload registry output unavailable: {exc}", file=sys.stderr)
            return 1
        if current != output:
            print(f"{args.output} is stale; run python3 tools/generate_workload_registry.py", file=sys.stderr)
            return 1
        print(f"workload registry valid: {len(manifest['workloads'])} workloads")
        return 0
    args.output.write_text(output, encoding="utf-8")
    print(f"generated {args.output} ({len(manifest['workloads'])} workloads)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
