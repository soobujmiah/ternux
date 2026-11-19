---
title: "Documentation scope inventory"
description: "Version classification and English/Bengali mirror audit for project documentation and website routes."
lang: "en"
alt_url: "/bn/docs/DOCUMENT-SCOPE.html"
---

**Reviewed:** 2026-11-18. This index classifies every Markdown document and every
Astro route under `src/pages/`, plus the shared navigation source. It includes
repository guidance, technical references, historical evidence, and research
notes so missing translations and ownership questions remain visible.

| Classification | Meaning |
|---|---|
| `V2_CURRENT` | Describes the current v2 implementation and published v2.0.1 release. |
| `V2_HISTORICAL` | Preserved record of an older release or dated state. |
| `V3_FUTURE` | Future v3 design, proposal, architecture, or acceptance work; not a v2 promise. |
| `SHARED_REFERENCE` | Governance, reusable guidance, cross-version status, or technical reference. |
| `DEPRECATED` | Superseded content retained only for historical context. |
| `NEEDS_REVIEW` | Ownership, scope, or translation status needs an explicit decision. |

The mirror column identifies an existing counterpart, not proof that the two
texts are synchronized. Rows marked `Missing ... mirror` are parity gaps for
review. Dated audit snapshots remain historical and are not silently rewritten
to match current main. Generated `.repo/STATUS.md` is marked `NEEDS_REVIEW`;
refresh it only through its supported synchronization workflow.

## Inventory

| Path | Scope | Language counterpart |
|---|---|---|
| `.github/ISSUE_TEMPLATE/bug_report.md` | SHARED_REFERENCE | Shared / no translation required |
| `.github/ISSUE_TEMPLATE/device_report.md` | SHARED_REFERENCE | Shared / no translation required |
| `.github/ISSUE_TEMPLATE/feature_request.md` | SHARED_REFERENCE | Shared / no translation required |
| `.github/PULL_REQUEST_TEMPLATE.md` | SHARED_REFERENCE | Shared / no translation required |
| `.repo/STATUS.md` | NEEDS_REVIEW | Shared / no translation required |
| `AI_ASSISTANT.md` | SHARED_REFERENCE | Shared / no translation required |
| `CHANGELOG.md` | SHARED_REFERENCE | `bn/CHANGELOG.md` |
| `CODE_OF_CONDUCT.md` | SHARED_REFERENCE | Shared / no translation required |
| `CONTRIBUTING.md` | SHARED_REFERENCE | Shared / no translation required |
| `README.md` | V2_CURRENT | `bn/README.md` |
| `SECURITY.md` | SHARED_REFERENCE | Shared / no translation required |
| `SKB_KNOWLEDGE_RETURN.md` | SHARED_REFERENCE | Shared / no translation required |
| `SKB_KNOWLEDGE_SYNC.md` | SHARED_REFERENCE | Shared / no translation required |
| `TRADEMARKS.md` | SHARED_REFERENCE | Shared / no translation required |
| `assets/fonts/LICENSES.md` | SHARED_REFERENCE | Shared / no translation required |
| `bn/CHANGELOG.md` | SHARED_REFERENCE | `CHANGELOG.md` |
| `bn/CONTRIBUTING.md` | SHARED_REFERENCE | `CONTRIBUTING.md` |
| `bn/README.md` | V2_CURRENT | `README.md` |
| `bn/docs/ACCELERATOR-RELEASE-PLAN.md` | V2_CURRENT | `docs/ACCELERATOR-RELEASE-PLAN.md` |
| `bn/docs/ARCHITECTURE.md` | V2_CURRENT | `docs/ARCHITECTURE.md` |
| `bn/docs/BENCHMARKS.md` | V2_CURRENT | `docs/BENCHMARKS.md` |
| `bn/docs/BLENDER-MCP.md` | V2_CURRENT | `docs/BLENDER-MCP.md` |
| `bn/docs/CLI.md` | V2_CURRENT | `docs/CLI.md` |
| `bn/docs/CONFIGURATION.md` | V2_CURRENT | `docs/CONFIGURATION.md` |
| `bn/docs/DOCUMENT-SCOPE.md` | V2_CURRENT | `docs/DOCUMENT-SCOPE.md` |
| `bn/docs/FAQ.md` | V2_CURRENT | `docs/FAQ.md` |
| `bn/docs/GRAPHICS-PERSISTENCE.md` | V2_CURRENT | `docs/GRAPHICS-PERSISTENCE.md` |
| `bn/docs/INSTALLATION.md` | V2_CURRENT | `docs/INSTALLATION.md` |
| `bn/docs/MANUAL.md` | V2_CURRENT | `docs/MANUAL.md` |
| `bn/docs/QUICK-START.md` | V2_CURRENT | `docs/QUICK-START.md` |
| `bn/docs/README.md` | V2_CURRENT | `docs/README.md` |
| `bn/docs/SEO.md` | V2_CURRENT | `docs/SEO.md` |
| `bn/docs/TERMUX-APT.md` | V2_HISTORICAL | `docs/TERMUX-APT.md` |
| `bn/docs/TROUBLESHOOTING.md` | V2_CURRENT | `docs/TROUBLESHOOTING.md` |
| `bn/docs/USAGE.md` | V2_CURRENT | `docs/USAGE.md` |
| `bn/docs/V2-RELEASE-READINESS.md` | SHARED_REFERENCE | `docs/V2-RELEASE-READINESS.md` |
| `bn/docs/V2-RELEASE-REPORT.md` | V2_HISTORICAL | `docs/V2-RELEASE-REPORT.md` |
| `bn/docs/V3-ARCHITECTURE.md` | V3_FUTURE | `docs/V3-ARCHITECTURE.md` |
| `bn/docs/V3-PROPOSALS.md` | V3_FUTURE | `docs/V3-PROPOSALS.md` |
| `bn/docs/WORKLOADS.md` | V2_CURRENT | `docs/WORKLOADS.md` |
| `bn/docs/index.md` | V2_CURRENT | `docs/index.md` |
| `bn/docs/project/IMPLEMENTATION-STATUS.md` | SHARED_REFERENCE | `docs/project/IMPLEMENTATION-STATUS.md` |
| `bn/docs/project/NEXT-ACTIONS.md` | SHARED_REFERENCE | `docs/project/NEXT-ACTIONS.md` |
| `bn/docs/project/PROJECT-ROADMAP.md` | SHARED_REFERENCE | `docs/project/PROJECT-ROADMAP.md` |
| `bn/docs/project/RELEASE-STATUS.md` | SHARED_REFERENCE | `docs/project/RELEASE-STATUS.md` |
| `bn/docs/release/README.md` | SHARED_REFERENCE | `docs/release/README.md` |
| `bn/docs/release/V2-RELEASE-REPORT.md` | V2_HISTORICAL | `docs/release/V2-RELEASE-REPORT.md` |
| `bn/docs/release/pages/v1.4.0-INSTALLATION.md` | V2_HISTORICAL | `docs/release/pages/v1.4.0-INSTALLATION.md` |
| `bn/docs/release/pages/v2.0.1-INSTALLATION.md` | V2_CURRENT | `docs/release/pages/v2.0.1-INSTALLATION.md` |
| `bn/docs/release/templates/RELEASE-INSTALLATION-TEMPLATE.md` | SHARED_REFERENCE | `docs/release/templates/RELEASE-INSTALLATION-TEMPLATE.md` |
| `bn/guides/device-benchmark-evidence.md` | SHARED_REFERENCE | `guides/device-benchmark-evidence.md` |
| `bn/guides/llama-htp-experimental.md` | SHARED_REFERENCE | `guides/llama-htp-experimental.md` |
| `bn/guides/llama-vulkan-extension.md` | SHARED_REFERENCE | `guides/llama-vulkan-extension.md` |
| `bn/guides/stable-diffusion-vulkan-extension.md` | SHARED_REFERENCE | `guides/stable-diffusion-vulkan-extension.md` |
| `bn/packaging/termux/README.md` | SHARED_REFERENCE | `packaging/termux/README.md` |
| `docs/ACCELERATOR-RELEASE-PLAN.md` | V2_CURRENT | `bn/docs/ACCELERATOR-RELEASE-PLAN.md` |
| `docs/ARCHITECTURE.md` | V2_CURRENT | `bn/docs/ARCHITECTURE.md` |
| `docs/BENCHMARKS.md` | V2_CURRENT | `bn/docs/BENCHMARKS.md` |
| `docs/BLENDER-MCP.md` | V2_CURRENT | `bn/docs/BLENDER-MCP.md` |
| `docs/CLI.md` | V2_CURRENT | `bn/docs/CLI.md` |
| `docs/CONFIGURATION.md` | V2_CURRENT | `bn/docs/CONFIGURATION.md` |
| `docs/DOCUMENT-SCOPE.md` | V2_CURRENT | `bn/docs/DOCUMENT-SCOPE.md` |
| `docs/FAQ.md` | V2_CURRENT | `bn/docs/FAQ.md` |
| `docs/GRAPHICS-PERSISTENCE.md` | V2_CURRENT | `bn/docs/GRAPHICS-PERSISTENCE.md` |
| `docs/INSTALLATION.md` | V2_CURRENT | `bn/docs/INSTALLATION.md` |
| `docs/MANUAL.md` | V2_CURRENT | `bn/docs/MANUAL.md` |
| `docs/QUICK-START.md` | V2_CURRENT | `bn/docs/QUICK-START.md` |
| `docs/README.md` | V2_CURRENT | `bn/docs/README.md` |
| `docs/SEO.md` | V2_CURRENT | `bn/docs/SEO.md` |
| `docs/TERMUX-APT.md` | V2_HISTORICAL | `bn/docs/TERMUX-APT.md` |
| `docs/TROUBLESHOOTING.md` | V2_CURRENT | `bn/docs/TROUBLESHOOTING.md` |
| `docs/USAGE.md` | V2_CURRENT | `bn/docs/USAGE.md` |
| `docs/V2-RELEASE-READINESS.md` | SHARED_REFERENCE | `bn/docs/V2-RELEASE-READINESS.md` |
| `docs/V2-RELEASE-REPORT.md` | V2_HISTORICAL | `bn/docs/V2-RELEASE-REPORT.md` |
| `docs/V3-ARCHITECTURE.md` | V3_FUTURE | `bn/docs/V3-ARCHITECTURE.md` |
| `docs/V3-PROPOSALS.md` | V3_FUTURE | `bn/docs/V3-PROPOSALS.md` |
| `docs/WORKLOADS.md` | V2_CURRENT | `bn/docs/WORKLOADS.md` |
| `docs/audit/CURRENT-STATE.md` | V2_HISTORICAL | Missing BN mirror |
| `docs/audit/DEVICE-VERIFICATION.md` | SHARED_REFERENCE | Missing BN mirror |
| `docs/audit/FEATURE-MATRIX.md` | SHARED_REFERENCE | Missing BN mirror |
| `docs/audit/REPOSITORY-STATE.md` | V2_HISTORICAL | Missing BN mirror |
| `docs/index.md` | V2_CURRENT | `bn/docs/index.md` |
| `docs/project/ARCHITECTURE-DECISIONS.md` | SHARED_REFERENCE | Missing BN mirror |
| `docs/project/DEVICE-VERIFICATION.md` | V2_HISTORICAL | Missing BN mirror |
| `docs/project/IMPLEMENTATION-STATUS.md` | SHARED_REFERENCE | `bn/docs/project/IMPLEMENTATION-STATUS.md` |
| `docs/project/KNOWN-LIMITATIONS.md` | SHARED_REFERENCE | Missing BN mirror |
| `docs/project/NEXT-ACTIONS.md` | SHARED_REFERENCE | `bn/docs/project/NEXT-ACTIONS.md` |
| `docs/project/PROJECT-ROADMAP.md` | SHARED_REFERENCE | `bn/docs/project/PROJECT-ROADMAP.md` |
| `docs/project/RELEASE-STATUS.md` | SHARED_REFERENCE | `bn/docs/project/RELEASE-STATUS.md` |
| `docs/project/TECHNICAL-DEBT.md` | SHARED_REFERENCE | Missing BN mirror |
| `docs/release/README.md` | SHARED_REFERENCE | `bn/docs/release/README.md` |
| `docs/release/V2-RELEASE-REPORT.md` | V2_HISTORICAL | `bn/docs/release/V2-RELEASE-REPORT.md` |
| `docs/release/pages/v1.4.0-INSTALLATION.md` | V2_HISTORICAL | `bn/docs/release/pages/v1.4.0-INSTALLATION.md` |
| `docs/release/pages/v2.0.1-INSTALLATION.md` | V2_CURRENT | `bn/docs/release/pages/v2.0.1-INSTALLATION.md` |
| `docs/release/templates/RELEASE-INSTALLATION-TEMPLATE.md` | SHARED_REFERENCE | `bn/docs/release/templates/RELEASE-INSTALLATION-TEMPLATE.md` |
| `docs/v3/ACCEPTANCE-CRITERIA.md` | V3_FUTURE | Missing BN mirror |
| `docs/v3/ADR/0001-native-manager.md` | V3_FUTURE | Missing BN mirror |
| `docs/v3/ADR/0002-guest-data-ownership.md` | V3_FUTURE | Missing BN mirror |
| `docs/v3/ADR/0003-lai-adapter.md` | V3_FUTURE | Missing BN mirror |
| `docs/v3/ADR/0004-shared-manager-contract.md` | V3_FUTURE | Missing BN mirror |
| `docs/v3/ADR/0005-native-display-allocation.md` | V3_FUTURE | Missing BN mirror |
| `docs/v3/ADR/README.md` | V3_FUTURE | Missing BN mirror |
| `docs/v3/AI-RUNTIME-ARCHITECTURE.md` | V3_FUTURE | Missing BN mirror |
| `docs/v3/API-DESIGN.md` | V3_FUTURE | Missing BN mirror |
| `docs/v3/COMPONENT-ARCHITECTURE.md` | V3_FUTURE | Missing BN mirror |
| `docs/v3/COMPUTE-ENGINE.md` | V3_FUTURE | Missing BN mirror |
| `docs/v3/CONTROL-CENTER-ARCHITECTURE.md` | V3_FUTURE | Missing BN mirror |
| `docs/v3/DEVICE-BRIDGE-ARCHITECTURE.md` | V3_FUTURE | Missing BN mirror |
| `docs/v3/IMPLEMENTATION-ROADMAP.md` | V3_FUTURE | Missing BN mirror |
| `docs/v3/PRODUCT-VISION.md` | V3_FUTURE | Missing BN mirror |
| `docs/v3/README.md` | V3_FUTURE | Missing BN mirror |
| `docs/v3/SECURITY-MODEL.md` | V3_FUTURE | Missing BN mirror |
| `docs/v3/SYSTEM-ARCHITECTURE.md` | V3_FUTURE | Missing BN mirror |
| `docs/v3/UX-AND-DESIGN-SYSTEM.md` | V3_FUTURE | Missing BN mirror |
| `docs/v3/WORKSPACE-ARCHITECTURE.md` | V3_FUTURE | Missing BN mirror |
| `engineering/MASTER-GOAL.md` | NEEDS_REVIEW | Shared / no translation required |
| `engineering/OWNER-AMENDMENTS.md` | SHARED_REFERENCE | Shared / no translation required |
| `engineering/WEBSITE-DESIGN.md` | SHARED_REFERENCE | Shared / no translation required |
| `experiments/bengali-short-film/README.md` | NEEDS_REVIEW | Shared / no translation required |
| `experiments/cartoon-pipeline/README.md` | NEEDS_REVIEW | Shared / no translation required |
| `experiments/htp-integer-hmx-candidate/README.md` | NEEDS_REVIEW | Shared / no translation required |
| `experiments/qnn-native/README.md` | NEEDS_REVIEW | Shared / no translation required |
| `guides/device-benchmark-evidence.md` | SHARED_REFERENCE | `bn/guides/device-benchmark-evidence.md` |
| `guides/llama-htp-experimental.md` | SHARED_REFERENCE | `bn/guides/llama-htp-experimental.md` |
| `guides/llama-vulkan-extension.md` | SHARED_REFERENCE | `bn/guides/llama-vulkan-extension.md` |
| `guides/stable-diffusion-vulkan-extension.md` | SHARED_REFERENCE | `bn/guides/stable-diffusion-vulkan-extension.md` |
| `handoffs/llama-htp-qualification.md` | NEEDS_REVIEW | Shared / no translation required |
| `handoffs/qnn-sd15-correctness.md` | NEEDS_REVIEW | Shared / no translation required |
| `handoffs/qnn-sd15-performance.md` | NEEDS_REVIEW | Shared / no translation required |
| `handoffs/stable-diffusion-cpu-vulkan-qualification-2026-11-07.md` | NEEDS_REVIEW | Shared / no translation required |
| `lib/licenses/mesa-27.0.0-devel-20261025/DEBIAN-RUNTIME-SNAPSHOT.md` | SHARED_REFERENCE | Shared / no translation required |
| `lib/licenses/mesa-27.0.0-devel-20261025/README.md` | SHARED_REFERENCE | Shared / no translation required |
| `packaging/termux/README.md` | SHARED_REFERENCE | Shared / no translation required |
| `share/templates/json-schema.md` | SHARED_REFERENCE | Shared / no translation required |
| `share/terfetch/README.md` | SHARED_REFERENCE | Shared / no translation required |
| `src/data/navigation.ts` | V2_CURRENT | Navigation has EN/BN labels |
| `src/pages/CHANGELOG.astro` | V2_CURRENT | `src/pages/bn/CHANGELOG.astro` |
| `src/pages/CONTRIBUTING.astro` | V2_CURRENT | `src/pages/bn/CONTRIBUTING.astro` |
| `src/pages/bn/CHANGELOG.astro` | V2_CURRENT | `src/pages/CHANGELOG.astro` |
| `src/pages/bn/CONTRIBUTING.astro` | V2_CURRENT | `src/pages/CONTRIBUTING.astro` |
| `src/pages/bn/docs/[...slug].astro` | V2_CURRENT | `src/pages/docs/[...slug].astro` |
| `src/pages/bn/docs/index.astro` | V2_CURRENT | `src/pages/docs/index.astro` |
| `src/pages/bn/index.astro` | V2_CURRENT | `src/pages/index.astro` |
| `src/pages/docs/[...slug].astro` | V2_CURRENT | `src/pages/bn/docs/[...slug].astro` |
| `src/pages/docs/index.astro` | V2_CURRENT | `src/pages/bn/docs/index.astro` |
| `src/pages/index.astro` | V2_CURRENT | `src/pages/bn/index.astro` |
| `tests/fixtures/ternux-v1.4.0/README.md` | SHARED_REFERENCE | Shared / no translation required |
| `tools/blender-gpu-mcp/README.md` | SHARED_REFERENCE | Shared / no translation required |
| `tools/llama-htp/README.md` | SHARED_REFERENCE | Shared / no translation required |
| `tools/repo_knowledge/README.md` | SHARED_REFERENCE | Shared / no translation required |

## Review gaps

- Research directories under `experiments/` and `handoffs/` need confirmation that their content belongs in the Ternux documentation set; no external projects were modified.
- `docs/v3/` has no full Bengali mirror; the existing `bn/docs/V3-ARCHITECTURE.md` and `bn/docs/V3-PROPOSALS.md` are legacy summaries and are explicitly marked for scope reconciliation in the bilingual audit.
- `docs/audit/DEVICE-VERIFICATION.md` contains the current live window-fit follow-up; its Bengali counterpart is historical and needs review before being used as a current claim.
- The generated `.repo/STATUS.md` remains unchanged because its owning workflow, not hand edits, defines the repository state.
