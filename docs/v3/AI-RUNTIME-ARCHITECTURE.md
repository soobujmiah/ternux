---
title: "Ternux v3 AI runtime architecture"
description: "Optional CPU, GPU, and NPU AI workloads integrated with LAI without duplicating its model store."
lang: "en"
---

## AI runtime architecture

**Status: DESIGNED.** AI is an optional workload area. The base Ternux install
does not download models or keep an inference service resident. LAI remains a
separate project and runtime; Ternux discovers and calls its supported
interface instead of implementing a competing model library.

## Workload manifest

Each workload declares task (`text`, `image`, or other explicitly supported
task), model architecture and format, quantization, runtime/API version,
supported CPU/GPU/NPU devices, minimum RAM/storage, required permissions,
source URL, license, cryptographic digest, correctness fixture, cancellation
behavior, and uninstall ownership. A model file's extension alone is not
proof of accelerator compatibility.

## Model discovery and ownership

Discovery may read user-authorized locations such as `/sdcard/Llms` and
`/sdcard/LAI/models`; it is read-only and reports path, size, format, and
possible runtime compatibility. It never moves or deletes discovered models
automatically. Copy/import is a separate user action with free-space and hash
checks. LAI's own model store remains LAI-owned.

## Job lifecycle

`QUEUED → VALIDATING → LOADING → RUNNING → SUCCEEDED|FAILED|CANCELLED`.
Every job records model identity/hash, backend, runtime, prompt/input hash
where privacy permits, duration, memory peak, output path, and exit condition.
Prompts and generated media stay local by default. Cancellation terminates the
job process and cleans only its temporary files.

## Correctness and performance

Text outputs are checked with task-specific evaluation, not trivial arithmetic
alone. Image outputs are checked for successful decode, dimensions, color
health, and stable workload metrics. Warm-up and first-run compilation are
reported separately. CPU, Vulkan, and NPU results use the same prompt/input,
model digest, output correctness checks, and repeat policy. Publish latency,
tokens/s or images/s, peak memory, temperature context, and failures together.
HTP/QNN/other experimental paths stay marked experimental until their named
hardware and release gates pass.
