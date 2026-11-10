#!/usr/bin/env python3
"""Validate Ternux's machine-readable release gate inventory without dependencies."""
from __future__ import annotations

import copy
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GATES_FILE = ROOT / "docs" / "release-gates.json"
GATE_FIELDS = {
    "phase", "issue_id", "severity", "owner", "status", "source_status",
    "ci_status", "device_status", "evidence", "required_tests",
    "acceptance_criteria", "release_blocking", "release_exclusion",
}
STATUSES = {"COMPLETE", "PARTIAL", "BLOCKED", "NOT_STARTED", "REGRESSION"}
SOURCE = {"PASS", "PARTIAL", "BLOCKED", "NOT_STARTED"}
CI = {"PASS", "PENDING", "FAIL", "NOT_RUN", "N_A"}
DEVICE = {"VERIFIED_ON_DEVICE", "CI_ONLY", "NOT_TESTED", "BLOCKED", "N_A"}
SEVERITIES = {"P0", "P1", "P2"}


def validate(data: object) -> list[str]:
    errors: list[str] = []
    if not isinstance(data, dict):
        return ["root must be an object"]
    if data.get("schema_version") != 1:
        errors.append("schema_version must be 1")
    if data.get("project") != "Ternux" or data.get("target_release") != "2.0.0":
        errors.append("project and target_release must identify Ternux 2.0.0")
    if not isinstance(data.get("audit_date"), str) or not data["audit_date"]:
        errors.append("audit_date must be a non-empty string")
    if not isinstance(data.get("observed_head_commit"), str) or len(data["observed_head_commit"]) != 40:
        errors.append("observed_head_commit must be a full 40-character Git object ID")
    gates = data.get("gates")
    if not isinstance(gates, list) or not gates:
        return errors + ["gates must be a non-empty array"]

    seen: set[str] = set()
    blocking_incomplete: list[str] = []
    for index, gate in enumerate(gates):
        label = f"gates[{index}]"
        if not isinstance(gate, dict):
            errors.append(f"{label} must be an object")
            continue
        missing = GATE_FIELDS - gate.keys()
        extra = gate.keys() - GATE_FIELDS
        if missing:
            errors.append(f"{label} missing fields: {', '.join(sorted(missing))}")
        if extra:
            errors.append(f"{label} unknown fields: {', '.join(sorted(extra))}")
        issue_id = gate.get("issue_id")
        if not isinstance(issue_id, str) or not issue_id:
            errors.append(f"{label}.issue_id must be non-empty")
            issue_id = label
        if issue_id in seen:
            errors.append(f"duplicate issue_id: {issue_id}")
        seen.add(issue_id)
        for field, allowed in (("phase", {f"Stage {n}" for n in range(7)}),
                               ("severity", SEVERITIES), ("status", STATUSES),
                               ("source_status", SOURCE), ("ci_status", CI),
                               ("device_status", DEVICE)):
            if gate.get(field) not in allowed:
                errors.append(f"{issue_id}.{field} has invalid value {gate.get(field)!r}")
        if not isinstance(gate.get("owner"), str) or not gate["owner"].strip():
            errors.append(f"{issue_id}.owner must be non-empty")
        for field in ("evidence", "required_tests", "acceptance_criteria"):
            value = gate.get(field)
            if not isinstance(value, list) or not value or any(not isinstance(x, str) or not x.strip() for x in value):
                errors.append(f"{issue_id}.{field} must be a non-empty array of strings")
        for evidence in gate.get("evidence", []) if isinstance(gate.get("evidence"), list) else []:
            match = re.match(r"^((?:docs|tests|lib|bin|packaging)/[^ :]+)", evidence)
            if match:
                evidence_path = match.group(1).split("#", 1)[0]
                if not (ROOT / evidence_path).is_file():
                    errors.append(f"{issue_id} references missing evidence file {evidence_path}")
        blocking = gate.get("release_blocking")
        if not isinstance(blocking, bool):
            errors.append(f"{issue_id}.release_blocking must be boolean")
        exclusion = gate.get("release_exclusion")
        if exclusion is not None and (not isinstance(exclusion, str) or not exclusion.strip()):
            errors.append(f"{issue_id}.release_exclusion must be null or a non-empty string")
        status = gate.get("status")
        source_ok = gate.get("source_status") == "PASS" and bool(gate.get("evidence"))
        ci_ok = gate.get("ci_status") in {"PASS", "N_A"}
        device_ok = gate.get("device_status") not in {"NOT_TESTED", "BLOCKED"}
        gate_complete = status == "COMPLETE" and source_ok and ci_ok and device_ok
        if status == "COMPLETE" and not gate_complete:
            errors.append(f"{issue_id} cannot be COMPLETE without passing source, CI, and required device evidence")
        if blocking is True and not gate_complete:
            blocking_incomplete.append(str(issue_id))
        if blocking is False and status not in ("COMPLETE",) and not exclusion:
            errors.append(f"{issue_id} is non-blocking but incomplete without a release_exclusion")
        if gate.get("ci_status") == "FAIL" and status == "COMPLETE":
            errors.append(f"{issue_id} cannot be COMPLETE with failing CI")
        if gate.get("device_status") == "NOT_TESTED" and status == "COMPLETE" and gate.get("severity") in {"P0", "P1"}:
            errors.append(f"{issue_id} cannot be COMPLETE for P0/P1 without device evidence")

    expected = "NOT_READY" if blocking_incomplete else "READY_FOR_OWNER_APPROVAL"
    if data.get("derived_readiness") != expected:
        errors.append(f"derived_readiness must be {expected}; incomplete blocking gates: {', '.join(blocking_incomplete) or 'none'}")
    if data.get("release_approved") is not False:
        errors.append("release_approved must remain false until owner authorization")
    return errors


def self_test(data: object) -> list[str]:
    errors = validate(data)
    if errors:
        return ["real gate inventory is invalid: " + "; ".join(errors)]
    ready = copy.deepcopy(data)
    ready["derived_readiness"] = "READY_FOR_OWNER_APPROVAL"
    for gate in ready["gates"]:
        gate["status"] = "COMPLETE"
        gate["source_status"] = "PASS"
        gate["ci_status"] = "PASS"
        if gate["device_status"] in {"NOT_TESTED", "BLOCKED"}:
            gate["device_status"] = "VERIFIED_ON_DEVICE"
    if validate(ready):
        errors.append("validator rejected a fully evidenced owner-approval-ready fixture")
    ready["gates"][0]["ci_status"] = "PENDING"
    if not any("derived_readiness must be NOT_READY" in issue for issue in validate(ready)):
        errors.append("validator allowed pending CI to produce a READY_FOR_OWNER_APPROVAL verdict")
    ready["gates"][0]["ci_status"] = "PASS"
    ready["gates"][0]["device_status"] = "NOT_TESTED"
    if not any("derived_readiness must be NOT_READY" in issue for issue in validate(ready)):
        errors.append("validator allowed untested device requirements to produce a READY_FOR_OWNER_APPROVAL verdict")
    bad = copy.deepcopy(data)
    bad["gates"][0]["evidence"] = ["docs/not-a-real-file.md"]
    if not any("references missing evidence file" in issue for issue in validate(bad)):
        errors.append("validator failed missing evidence-file regression fixture")
    bad = copy.deepcopy(data)
    bad["gates"][0]["issue_id"] = bad["gates"][1]["issue_id"]
    if not any("duplicate issue_id" in issue for issue in validate(bad)):
        errors.append("validator failed duplicate-ID regression fixture")
    bad = copy.deepcopy(data)
    bad["gates"][0]["status"] = "COMPLETE"
    bad["gates"][0]["source_status"] = "PASS"
    bad["gates"][0]["ci_status"] = "FAIL"
    if not any("failing CI" in issue for issue in validate(bad)):
        errors.append("validator failed failed-CI regression fixture")
    bad = copy.deepcopy(data)
    bad["gates"][0]["status"] = "PARTIAL"
    bad["gates"][0]["release_blocking"] = False
    bad["gates"][0]["release_exclusion"] = None
    if not any("release_exclusion" in issue for issue in validate(bad)):
        errors.append("validator failed exclusion regression fixture")
    return errors


def main() -> int:
    try:
        data = json.loads(GATES_FILE.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"release gate inventory: {exc}", file=sys.stderr)
        return 1
    errors = self_test(data) if "--self-test" in sys.argv else validate(data)
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    incomplete = [g["issue_id"] for g in data["gates"] if g["release_blocking"] and g["status"] != "COMPLETE"]
    print(f"Release gates valid: {len(data['gates'])} gates; readiness={data['derived_readiness']}; incomplete blocking={len(incomplete)}")
    if incomplete:
        print("Incomplete blockers: " + ", ".join(incomplete))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
