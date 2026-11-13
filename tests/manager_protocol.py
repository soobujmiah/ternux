#!/usr/bin/env python3
"""Exercise the documented v1 manager envelope schemas with stdlib only."""
import datetime
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCHEMAS = ROOT / "docs/v3/schemas"
passed = 0
failed = 0


def validate(value, schema, root_schema=None):
    root_schema = root_schema or schema
    if "$ref" in schema:
        name = schema["$ref"].split("/")[-1]
        referenced = json.loads((SCHEMAS / name).read_text())
        return validate(value, referenced, referenced)
    if "oneOf" in schema:
        matches = 0
        for option in schema["oneOf"]:
            try:
                validate(value, option, root_schema)
                matches += 1
            except AssertionError:
                pass
        assert matches == 1, f"expected one schema branch, found {matches}"
    if "not" in schema:
        try:
            validate(value, schema["not"], root_schema)
        except AssertionError:
            pass
        else:
            raise AssertionError("forbidden schema matched")
    if "type" in schema:
        types = [schema["type"]] if isinstance(schema["type"], str) else schema["type"]
        checks = {
            "object": lambda x: isinstance(x, dict),
            "array": lambda x: isinstance(x, list),
            "string": lambda x: isinstance(x, str),
            "boolean": lambda x: isinstance(x, bool),
            "integer": lambda x: isinstance(x, int) and not isinstance(x, bool),
            "null": lambda x: x is None,
        }
        assert any(checks[item](value) for item in types), f"expected {types}"
    if "const" in schema:
        assert value == schema["const"]
    if "enum" in schema:
        assert value in schema["enum"]
    if "pattern" in schema:
        assert isinstance(value, str) and re.fullmatch(schema["pattern"], value)
    if isinstance(value, str):
        assert len(value) >= schema.get("minLength", 0)
        assert len(value) <= schema.get("maxLength", len(value))
        if schema.get("format") == "date-time":
            datetime.datetime.fromisoformat(value.replace("Z", "+00:00"))
    if isinstance(value, int) and not isinstance(value, bool):
        assert value >= schema.get("minimum", value)
        assert value <= schema.get("maximum", value)
    if isinstance(value, dict):
        assert set(schema.get("required", [])) <= value.keys()
        assert len(value) <= schema.get("maxProperties", len(value))
        if schema.get("additionalProperties") is False:
            assert value.keys() <= schema.get("properties", {}).keys()
        for key, item in value.items():
            if key in schema.get("properties", {}):
                validate(item, schema["properties"][key], root_schema)
    if isinstance(value, list):
        if schema.get("uniqueItems"):
            assert len(value) == len({json.dumps(item, sort_keys=True) for item in value})
        if "items" in schema:
            for item in value:
                validate(item, schema["items"], root_schema)
    for condition in schema.get("allOf", []):
        if "if" in condition:
            try:
                validate(value, condition["if"], root_schema)
                matched = True
            except AssertionError:
                matched = False
            validate(value, condition.get("then" if matched else "else", {}), root_schema)
        else:
            validate(value, condition, root_schema)


def check(label, fn, expected=True):
    global passed, failed
    try:
        fn()
        result = True
    except (AssertionError, KeyError, TypeError, ValueError):
        result = False
    if result == expected:
        passed += 1
        print(f"ok {passed + failed} - {label}")
    else:
        failed += 1
        print(f"not ok {passed + failed} - {label}")


def load(name):
    return json.loads((SCHEMAS / name).read_text())


status = load("manager-status-v1.schema.json")
guests = load("manager-guests-v1.schema.json")
capabilities = load("manager-capabilities-v1.schema.json")
request_schema = load("manager-request-v1.schema.json")
response_schema = load("manager-response-v1.schema.json")
error_schema = load("manager-error-v1.schema.json")
request_id = "a4b1dd90-2a51-4bde-97d1-7d67f47c5021"
status_result = {
    "schema_version": "1.0.0", "command": "manager.status", "status": "available",
    "timestamp": "2026-11-13T09:00:00Z", "version": "2.0.0", "runtime": "termux",
    "management_mode": "direct-cli", "guest_manager_available": True,
    "installed_guest_count": 0, "running_desktops": [],
}
base_request = {
    "schema_version": "1.0.0", "request_id": request_id,
    "operation": "manager.status", "arguments": {},
}

check("valid read-only request envelope", lambda: validate(base_request, request_schema))
check("request ID is required", lambda: validate({k: v for k, v in base_request.items() if k != "request_id"}, request_schema), False)
check("unsupported major/minor schema versions are rejected", lambda: validate({**base_request, "schema_version": "2.0.0"}, request_schema), False)
check("operation must exist in v1 catalog", lambda: validate({**base_request, "operation": "guest.remove"}, request_schema), False)
check("unknown request envelope fields are rejected", lambda: validate({**base_request, "shell": "rm -rf /"}, request_schema), False)
check("v1 read-only operations reject untyped arguments", lambda: validate({**base_request, "arguments": {"name": "debian"}}, request_schema), False)

error = {"code": "UNSUPPORTED_VERSION", "message": "Request version is unsupported.", "retryable": False}
check("valid stable error object", lambda: validate(error, error_schema))
check("error message is required", lambda: validate({"code": "FAILED", "retryable": False}, error_schema), False)
check("error code must be a stable uppercase identifier", lambda: validate({**error, "code": "bad code"}, error_schema), False)

success = {"schema_version": "1.0.0", "request_id": request_id, "status": "ok", "result": status_result}
failure = {"schema_version": "1.0.0", "request_id": request_id, "status": "error", "error": error}
check("successful response echoes request ID and typed result", lambda: validate(success, response_schema))
check("error response echoes request ID and stable error", lambda: validate(failure, response_schema))
check("response requires request ID for correlation", lambda: validate({k: v for k, v in success.items() if k != "request_id"}, response_schema), False)
check("response cannot contain both result and error", lambda: validate({**success, "error": error}, response_schema), False)
check("response rejects unknown fields", lambda: validate({**success, "debug": "secret"}, response_schema), False)

print(f"1..{passed + failed}\n# pass {passed}\n# fail {failed}")
sys.exit(0 if failed == 0 else 1)
