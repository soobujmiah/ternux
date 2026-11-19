---
title: "Android phantom-process controls"
description: "Optional, system-wide Android controls for PRoot workloads, with Termux ADB, Shizuku rish, computer ADB, verification and rollback steps."
lang: "en"
alt_url: "/bn/docs/ANDROID-PHANTOM-PROCESS.html"
---

This is an advanced, optional Android host setting for cases where Android's
phantom-process policy is confirmed to terminate a Ternux/PRoot workload. It is
not a general fix for every `SIGKILL`, X11 stall, memory-pressure event, or OEM
battery restriction. Ternux's [`doctor`](CLI.md#tx-doctor) is diagnostic; it
does not change Android settings.

Android 14 and later may expose **Disable child process restrictions** in
Developer options. Prefer that supported UI control when it exists. The shell
commands below are device-wide and OEM/version behavior can differ. Raising the
phantom-process ceiling and disabling its monitor weakens Android's protection
against excessive background child processes; use them only when needed and
keep an eye on memory and battery use.

## Choose a shell route

The commands must run as Android's `shell` user (UID 2000), not as the ordinary
Termux app UID. Check the identity before changing anything:

```sh
id
```

The output must include `uid=2000(shell)`. If it shows a Termux app UID such as
`uid=10490(u0_a490)`, stop; the shell route is not elevated enough.

### Shizuku from Termux

If Shizuku is already running, open its **Use Shizuku in terminal apps** screen
and follow its export/setup instructions for Termux. This provides `rish`, a
Shizuku shell; it does not create an ADB transport or make `adb devices` show a
device. Check it with:

```sh
rish -c 'id'
```

Proceed only when it reports `uid=2000(shell)`. Then run the commands in the
next section through `rish -c '...'` (examples are provided below). Shizuku
must be running and Termux must be authorized. Shizuku may need to be started
again after reboot. Ternux does not require or install Shizuku, and does not
configure it automatically.

### ADB from a computer

With USB debugging, authorize that computer on the phone and confirm the device
state is `device`:

```sh
adb devices -l
```

For wireless ADB, enable **Wireless debugging** in Developer options. On Android
11+, pair once using the displayed pairing address, port, and code, then connect
to the separate ADB address and port shown on the Wireless debugging screen:

```sh
adb pair PHONE_IP:PAIRING_PORT
adb connect PHONE_IP:ADB_PORT
adb devices -l
```

Do not expose the wireless debugging port to an untrusted network. On a computer,
prefix each command in the next section with `adb shell`.

### ADB client inside native Termux

The Termux package is `android-tools`:

```sh
pkg install android-tools
adb devices -l
```

An installed ADB client alone does not grant device shell access. A connected,
authorized ADB transport is still required. An existing Shizuku session may
provide a `rish` shell without pairing; use the Shizuku route above when that is
how the device is managed. A computer connection can instead use `adb pair` and
`adb connect` as described above.

## Record current values and apply

Before changing anything, record the current values so you can restore them:

```sh
adb shell /system/bin/device_config get_sync_disabled_for_tests
adb shell /system/bin/device_config get activity_manager max_phantom_processes
adb shell settings get global settings_enable_monitor_phantom_procs
```

Using the computer ADB route, run the requested commands:

```sh
adb shell /system/bin/device_config set_sync_disabled_for_tests persistent
adb shell /system/bin/device_config put activity_manager max_phantom_processes 2147483647
adb shell settings put global settings_enable_monitor_phantom_procs false
```

`persistent` disables DeviceConfig synchronization across reboots. That mode is
intended for tests and prevents remotely synced DeviceConfig values from
overwriting local changes. It is broader than the phantom-process setting and
may affect unrelated Android DeviceConfig namespaces. Record its prior value;
do not set it blindly on a device where preserving normal DeviceConfig sync is
important. Android's accepted modes include `none`, `until_reboot`, and
`persistent`.

With Shizuku `rish`, run the same system commands, omitting the `adb shell`
prefix. For example:

```sh
rish -c '/system/bin/device_config set_sync_disabled_for_tests persistent'
rish -c '/system/bin/device_config put activity_manager max_phantom_processes 2147483647'
rish -c 'settings put global settings_enable_monitor_phantom_procs false'
```

## Verify

Run all three checks. The first two should show `2147483647`; the last should
show `false`:

```sh
adb shell /system/bin/dumpsys activity settings | grep max_phantom_processes
adb shell /system/bin/device_config get activity_manager max_phantom_processes
adb shell settings get global settings_enable_monitor_phantom_procs
adb shell /system/bin/device_config get_sync_disabled_for_tests
```

For `rish`, omit `adb shell` and run the commands via `rish -c`. A successful
write command is not proof that the effective ActivityManager value changed;
check both `dumpsys` and `device_config`. If a setting is denied, missing, or
immediately reverted, stop and use the Android-version-specific Developer
options control or vendor guidance. Do not try to bypass OEM protections.

## Restore

Restore the exact values recorded before the change. If the phantom-process
DeviceConfig key did not exist before, delete the override instead of leaving a
new value:

```sh
adb shell /system/bin/device_config delete activity_manager max_phantom_processes
```

If it previously had a value, put that original value back:

```sh
adb shell /system/bin/device_config put activity_manager max_phantom_processes ORIGINAL_VALUE
```

Restore the global monitor setting to its recorded value. If it was absent,
remove the override:

```sh
adb shell settings delete global settings_enable_monitor_phantom_procs
```

Restore DeviceConfig sync to its exact prior mode, commonly `none`:

```sh
adb shell /system/bin/device_config set_sync_disabled_for_tests none
```

Use the same authorized shell route used to apply the changes. Reboot only if
Android or the device vendor requires it, then verify the restored values.

## Ternux live-device observation

On the maintainer's Android 16 (SDK 36) device, a Termux-native ADB transport
was available through the existing Shizuku/watchdog setup. `adb shell id`
reported UID 2000 (`shell`). The requested values were already present before
this check:

- DeviceConfig sync mode: `persistent`
- `activity_manager/max_phantom_processes`: `2147483647`
- `settings_enable_monitor_phantom_procs`: `false`
- The `rish` executable was not present in this Termux home; the working device
  route during this check was the existing ADB transport.

No device value was rewritten. This confirms the values on that device at the
time checked; it does not prove that phantom-process killing or X11 stalls are
eliminated under every workload.

Related: [Troubleshooting](TROUBLESHOOTING.md#the-desktop-dies-silently) ·
[Ternux CLI](CLI.md)
