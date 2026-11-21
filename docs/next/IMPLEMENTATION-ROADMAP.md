---
title: "Next Version Implementation Roadmap"
description: "Evidence-led sequencing for proposed future work."
lang: "en"
alt_url: "/bn/docs/next/IMPLEMENTATION-ROADMAP.html"
---

This roadmap is a planning aid, not a delivery schedule or release promise. Keep
current support and historical release evidence distinct from future proposals.
Do not describe a package channel as usable while the repository is unavailable.

## Sequence and exit evidence

1. **Document the baseline.** Keep English and Bengali status aligned; preserve
   the dated source and device evidence, and make each uncertainty explicit.
2. **Close reliability work.** Complete update-lock and recovery-journal
   regression coverage; retain APT timeout and dpkg recovery tests. Changes must
   pass focused tests without regressing recovery behavior.
3. **Assess distribution options.** Define signing, key rotation, repository
   availability, install/upgrade/removal, and rollback requirements. No channel
   is considered available until a clean-device install and upgrade are verified.
4. **Qualify desktop profiles.** Continue device-specific checks for Debian,
   Ubuntu, Kali Linux, and Alpine. Report setup recipes separately from tested
   support and publish limits by device and workload.
5. **Prototype optional extensions.** Keep CPU, Vulkan/GPU, and device-specific
   NPU work opt-in. Record artifact provenance, hashes, licenses, resource use,
   correctness, cleanup, and recovery evidence.
6. **Review privacy-sensitive integrations.** Treat camera and microphone access
   as permission-gated, on-demand work; verify lifecycle and data handling on
   target devices before proposing general availability.

Each stage requires a named owner, a reviewable change, bilingual documentation,
reproducible checks, and explicit go/no-go evidence. There are no release dates
or implied commitments in this plan.
