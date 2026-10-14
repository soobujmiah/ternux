#!/usr/bin/env python3
"""Experimental Android Binder to FastRPC launcher for Ternux llama.cpp."""
from __future__ import annotations

import ctypes as C
import os
from pathlib import Path
import signal
import subprocess
import sys
import time


SERVICE = b"vendor.qti.hardware.dsp.IDspService/default"


def bind(lib: C.CDLL, name: str, args: list[object], result: object = C.c_void_p):
    fn = getattr(lib, name)
    fn.argtypes = args
    fn.restype = result
    return fn


def run_child(lib: C.CDLL, command: list[str]) -> int:
    client_new = bind(lib, "gbinder_client_new", [C.c_void_p, C.c_char_p])
    new_request = bind(lib, "gbinder_client_new_request", [C.c_void_p])
    append_int = bind(lib, "gbinder_local_request_append_int32", [C.c_void_p, C.c_uint32])
    transact = bind(lib, "gbinder_client_transact_sync_reply",
                    [C.c_void_p, C.c_uint32, C.c_void_p, C.POINTER(C.c_int)])
    init_reader = bind(lib, "gbinder_remote_reply_init_reader", [C.c_void_p, C.c_void_p], None)
    read_int = bind(lib, "gbinder_reader_read_int32",
                    [C.c_void_p, C.POINTER(C.c_int32)], C.c_int)
    read_object = bind(lib, "gbinder_reader_read_object", [C.c_void_p])
    read_dup_fd = bind(lib, "gbinder_reader_read_dup_fd", [C.c_void_p], C.c_int)
    unref_reply = bind(lib, "gbinder_remote_reply_unref", [C.c_void_p], None)
    unref_request = bind(lib, "gbinder_local_request_unref", [C.c_void_p], None)
    unref_client = bind(lib, "gbinder_client_unref", [C.c_void_p], None)
    unref_object = bind(lib, "gbinder_remote_object_unref", [C.c_void_p], None)

    service_manager = None
    service = manager = client = request = reply = None
    manager_client = opened = None
    unref_manager = None
    inherited_fd = -1
    child: subprocess.Popen[bytes] | None = None
    result = 1
    cancel_time: float | None = None
    cancel_signal = signal.SIGINT
    previous_handlers: dict[int, object] = {}

    def close_session() -> bool:
        if manager_client is None:
            return True
        req = new_request(manager_client)
        # closeSession(DSPDomain) takes the same non-null parcelable as
        # openSession(DSPDomain): presence marker, parcelable size, CDSP ID.
        for value in (1, 8, 3):
            append_int(req, value)
        transport = C.c_int(-999)
        response = transact(manager_client, 1, req, C.byref(transport))
        values: list[int] = []
        if response:
            reader = (C.c_void_p * 6)()
            init_reader(response, C.byref(reader))
            for _ in range(3):
                value = C.c_int32()
                if not read_int(C.byref(reader), C.byref(value)):
                    break
                values.append(value.value)
            unref_reply(response)
        unref_request(req)
        print({"stage": "closeSession", "transport_status": transport.value,
               "reply_int32_prefix": values}, flush=True)
        return transport.value == 0 and values == [0, 0]

    def forward_signal(signum: int, _frame: object) -> None:
        nonlocal cancel_time, cancel_signal
        cancel_signal = signum
        if cancel_time is None:
            cancel_time = time.monotonic()
        if child is not None and child.poll() is None:
            try:
                os.killpg(child.pid, signum)
            except ProcessLookupError:
                pass

    try:
        for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
            previous_handlers[sig] = signal.signal(sig, forward_signal)

        new_manager = bind(lib, "gbinder_servicemanager_new2",
                           [C.c_char_p, C.c_char_p, C.c_char_p])
        get_service = bind(lib, "gbinder_servicemanager_get_service_sync",
                           [C.c_void_p, C.c_char_p, C.POINTER(C.c_int)])
        unref_manager = bind(lib, "gbinder_servicemanager_unref", [C.c_void_p], None)
        service_manager = new_manager(b"/dev/binder", b"aidl6", b"aidl3")
        if not service_manager:
            raise RuntimeError("Binder service manager is unavailable")
        status = C.c_int(-999)
        service = get_service(service_manager, SERVICE, C.byref(status))
        print({"stage": "service_lookup", "status": status.value,
               "service_found": bool(service)}, flush=True)
        if not service:
            raise RuntimeError("Qualcomm DSP service was not found")

        client = client_new(service, b"vendor.qti.hardware.dsp.IDspService")
        request = new_request(client)
        append_int(request, 0)
        reply = transact(client, 1, request, C.byref(status))
        if not reply:
            raise RuntimeError(f"getNewDSPSession transport failed: {status.value}")
        reader = (C.c_void_p * 6)()
        init_reader(reply, C.byref(reader))
        exception = C.c_int32(-999)
        if not read_int(C.byref(reader), C.byref(exception)) or exception.value != 0:
            raise RuntimeError(f"getNewDSPSession exception: {exception.value}")
        manager = read_object(C.byref(reader))
        if not manager:
            raise RuntimeError("getNewDSPSession returned no manager")
        manager_client = client_new(manager, b"vendor.qti.hardware.dsp.IDspManager")

        req = new_request(manager_client)
        for value in (1, 8, 3):  # present DSPDomain, size 8, CDSP domain
            append_int(req, value)
        transport = C.c_int(-999)
        opened = transact(manager_client, 2, req, C.byref(transport))
        unref_request(req)
        if not opened:
            raise RuntimeError(f"openSession transport failed: {transport.value}")
        open_reader = (C.c_void_p * 6)()
        init_reader(opened, C.byref(open_reader))
        prefix: list[int] = []
        for _ in range(6):
            value = C.c_int32()
            if not read_int(C.byref(open_reader), C.byref(value)):
                break
            prefix.append(value.value)
        if prefix != [0, 1, 56, 0, 1, 44]:
            raise RuntimeError(f"Unexpected openSession reply prefix: {prefix}")
        count = C.c_int32()
        present = C.c_int32()
        has_comm = C.c_int32()
        if not (read_int(C.byref(open_reader), C.byref(count)) and count.value == 1 and
                read_int(C.byref(open_reader), C.byref(present)) and present.value == 1 and
                read_int(C.byref(open_reader), C.byref(has_comm)) and has_comm.value == 0):
            raise RuntimeError("Unexpected FastRPC native-handle layout")
        inherited_fd = read_dup_fd(C.byref(open_reader))
        if inherited_fd < 0:
            raise RuntimeError("Binder did not transfer an authorized CDSP descriptor")
        print({"stage": "broker_device_fd", "descriptor_received": True,
               "device_path": os.readlink(f"/proc/self/fd/{inherited_fd}")}, flush=True)

        env = os.environ.copy()
        env["TERNUX_HTP_BROKER_FD"] = str(inherited_fd)
        child = subprocess.Popen(command, env=env, pass_fds=(inherited_fd,),
                                 start_new_session=True)
        while child.poll() is None:
            if cancel_time is not None:
                elapsed = time.monotonic() - cancel_time
                if elapsed > 5.0:
                    try:
                        os.killpg(child.pid, signal.SIGTERM)
                    except ProcessLookupError:
                        pass
                if elapsed > 8.0:
                    try:
                        os.killpg(child.pid, signal.SIGKILL)
                    except ProcessLookupError:
                        pass
            time.sleep(0.1)
        child_rc = child.returncode or 0
        print({"stage": "brokered_child", "exit_status": child_rc,
               "cancel_signal": cancel_signal if cancel_time is not None else None}, flush=True)
        result = (128 + cancel_signal) if cancel_time is not None else child_rc
    except Exception as exc:
        print(f"HTP broker error: {exc}", file=sys.stderr, flush=True)
        result = 1
    finally:
        if child is not None and child.poll() is None:
            try:
                os.killpg(child.pid, signal.SIGTERM)
                child.wait(timeout=3)
            except (ProcessLookupError, subprocess.TimeoutExpired):
                try:
                    os.killpg(child.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                child.wait()
        if inherited_fd >= 0:
            os.close(inherited_fd)
        session_closed = True
        if manager_client is not None:
            try:
                session_closed = close_session()
            except Exception as exc:
                print(f"HTP broker closeSession error: {exc}", file=sys.stderr, flush=True)
                session_closed = False
        if not session_closed:
            result = 1
        elif cancel_time is not None:
            result = 128 + cancel_signal
        if opened:
            unref_reply(opened)
        if manager_client:
            unref_client(manager_client)
        if manager:
            unref_object(manager)
        if reply:
            unref_reply(reply)
        if request:
            unref_request(request)
        if client:
            unref_client(client)
        # get_service_sync() returns the service object owned by the service
        # manager; releasing the manager below releases that borrowed object.
        if service_manager and unref_manager:
            unref_manager(service_manager)
        for sig, handler in previous_handlers.items():
            signal.signal(sig, handler)
    return result


def main() -> int:
    if len(sys.argv) < 3 or sys.argv[1] != "--":
        print("Usage: htp-broker.py -- COMMAND [ARG ...]", file=sys.stderr)
        return 2
    command = sys.argv[2:]
    if not command:
        print("Missing child command", file=sys.stderr)
        return 2
    package = Path(__file__).resolve().parent.parent
    libdir = package / "lib"
    os.environ["LD_LIBRARY_PATH"] = str(libdir) + (
        ":" + os.environ["LD_LIBRARY_PATH"] if os.environ.get("LD_LIBRARY_PATH") else "")
    try:
        binder_lib = C.CDLL("libgbinder.so.1")
    except OSError as exc:
        print(f"HTP broker needs libgbinder.so.1 and libglibutil.so.1: {exc}",
              file=sys.stderr)
        return 1
    return run_child(binder_lib, command)


if __name__ == "__main__":
    raise SystemExit(main())
