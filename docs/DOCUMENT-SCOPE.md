---
title: "Documentation scope inventory"
description: "Scope classification and English/Bengali mirror audit for project documentation and website routes."
lang: "en"
alt_url: "/bn/docs/DOCUMENT-SCOPE.html"
---

**Reviewed:** 2026-11-20. This index classifies every Markdown document and every
Astro route under `src/pages/`, plus the shared navigation source. It includes
repository guidance, technical references, historical evidence, and research
notes so missing translations and ownership questions remain visible.

| Classification | Meaning |
|---|---|
| `PUBLISHED_SOURCE` | Describes the current source implementation and its evidence boundaries. |
| `HISTORICAL_RELEASE` | Preserved record of an older release or dated state. |
| `NEXT_FUTURE` | Future Next Version design, proposal, architecture, or acceptance work; not a release promise. |
| `NEXT_ACTIVE` | Active Next Version foundation planning or implementation; not automatically a shipped capability. |
| `SHARED_REFERENCE` | Governance, reusable guidance, cross-version status, or technical reference. |
| `DEPRECATED` | Superseded content retained only for historical context. |
| `REPOSITORY_AUDIT` | Dated full-repository audit snapshot with findings and evidence boundaries. |
| `NEEDS_REVIEW` | Ownership, scope, or translation status needs an explicit decision. |

The mirror column identifies an existing counterpart, not proof that the two
texts are synchronized. Rows marked `Missing ... mirror` are parity gaps for
review. The Next Version technical and ADR pages have Bengali counterparts;
these translations still need parity review as English sources evolve. Dated audit snapshots remain historical and are not silently rewritten
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
| `README.md` | PUBLISHED_SOURCE | `bn/README.md` |
| `SECURITY.md` | SHARED_REFERENCE | Shared / no translation required |
| `SKB_KNOWLEDGE_RETURN.md` | SHARED_REFERENCE | Shared / no translation required |
| `SKB_KNOWLEDGE_SYNC.md` | SHARED_REFERENCE | Shared / no translation required |
| `TRADEMARKS.md` | SHARED_REFERENCE | Shared / no translation required |
| `assets/fonts/LICENSES.md` | SHARED_REFERENCE | Shared / no translation required |
| `bn/CHANGELOG.md` | SHARED_REFERENCE | `CHANGELOG.md` |
| `bn/CONTRIBUTING.md` | SHARED_REFERENCE | `CONTRIBUTING.md` |
| `bn/README.md` | PUBLISHED_SOURCE | `README.md` |
| `bn/docs/ACCELERATOR-RELEASE-PLAN.md` | PUBLISHED_SOURCE | `docs/ACCELERATOR-RELEASE-PLAN.md` |
| `bn/docs/ANDROID-PHANTOM-PROCESS.md` | PUBLISHED_SOURCE | `docs/ANDROID-PHANTOM-PROCESS.md` |
| `bn/docs/ARCHITECTURE.md` | PUBLISHED_SOURCE | `docs/ARCHITECTURE.md` |
| `bn/docs/BENCHMARKS.md` | PUBLISHED_SOURCE | `docs/BENCHMARKS.md` |
| `bn/docs/BLENDER-MCP.md` | PUBLISHED_SOURCE | `docs/BLENDER-MCP.md` |
| `bn/docs/CLI.md` | PUBLISHED_SOURCE | `docs/CLI.md` |
| `bn/docs/CONFIGURATION.md` | PUBLISHED_SOURCE | `docs/CONFIGURATION.md` |
| `bn/docs/DOCUMENT-SCOPE.md` | PUBLISHED_SOURCE | `docs/DOCUMENT-SCOPE.md` |
| `bn/docs/FAQ.md` | PUBLISHED_SOURCE | `docs/FAQ.md` |
| `bn/docs/GRAPHICS-PERSISTENCE.md` | PUBLISHED_SOURCE | `docs/GRAPHICS-PERSISTENCE.md` |
| `bn/docs/INSTALLATION.md` | PUBLISHED_SOURCE | `docs/INSTALLATION.md` |
| `bn/docs/MANUAL.md` | PUBLISHED_SOURCE | `docs/MANUAL.md` |
| `bn/docs/QUICK-START.md` | PUBLISHED_SOURCE | `docs/QUICK-START.md` |
| `bn/docs/README.md` | PUBLISHED_SOURCE | `docs/README.md` |
| `bn/docs/SEO.md` | PUBLISHED_SOURCE | `docs/SEO.md` |
| `bn/docs/TERMUX-APT.md` | HISTORICAL_RELEASE | `docs/TERMUX-APT.md` |
| `bn/docs/TROUBLESHOOTING.md` | PUBLISHED_SOURCE | `docs/TROUBLESHOOTING.md` |
| `bn/docs/USAGE.md` | PUBLISHED_SOURCE | `docs/USAGE.md` |
| `bn/docs/V2-RELEASE-READINESS.md` | SHARED_REFERENCE | `docs/V2-RELEASE-READINESS.md` |
| `bn/docs/V2-RELEASE-REPORT.md` | HISTORICAL_RELEASE | `docs/V2-RELEASE-REPORT.md` |
| `bn/docs/V3-ARCHITECTURE.md` | NEXT_ACTIVE | `docs/V3-ARCHITECTURE.md` |
| `bn/docs/V3-PROPOSALS.md` | NEXT_FUTURE | `docs/V3-PROPOSALS.md` |
| `bn/docs/WORKLOADS.md` | PUBLISHED_SOURCE | `docs/WORKLOADS.md` |
| `bn/docs/index.md` | PUBLISHED_SOURCE | `docs/index.md` |
| `bn/docs/project/IMPLEMENTATION-STATUS.md` | SHARED_REFERENCE | `docs/project/IMPLEMENTATION-STATUS.md` |
| `bn/docs/project/NEXT-ACTIONS.md` | SHARED_REFERENCE | `docs/project/NEXT-ACTIONS.md` |
| `bn/docs/project/PROJECT-ROADMAP.md` | SHARED_REFERENCE | `docs/project/PROJECT-ROADMAP.md` |
| `bn/docs/project/RELEASE-STATUS.md` | SHARED_REFERENCE | `docs/project/RELEASE-STATUS.md` |
| `bn/docs/release/README.md` | SHARED_REFERENCE | `docs/release/README.md` |
| `bn/docs/release/V2-RELEASE-RECONCILIATION.md` | SHARED_REFERENCE | `docs/release/V2-RELEASE-RECONCILIATION.md` |
| `bn/docs/release/V2-RELEASE-REPORT.md` | HISTORICAL_RELEASE | `docs/release/V2-RELEASE-REPORT.md` |
| `bn/docs/release/pages/v1.4.0-INSTALLATION.md` | HISTORICAL_RELEASE | `docs/release/pages/v1.4.0-INSTALLATION.md` |
| `bn/docs/release/pages/v2.0.1-INSTALLATION.md` | PUBLISHED_SOURCE | `docs/release/pages/v2.0.1-INSTALLATION.md` |
| `bn/docs/release/templates/RELEASE-INSTALLATION-TEMPLATE.md` | SHARED_REFERENCE | `docs/release/templates/RELEASE-INSTALLATION-TEMPLATE.md` |
| `bn/docs/next/architecture/ACCEPTANCE-CRITERIA.md` | NEXT_ACTIVE | `docs/next/architecture/ACCEPTANCE-CRITERIA.md` |
| `bn/docs/next/architecture/ADR/0001-native-manager.md` | NEXT_FUTURE | `docs/next/architecture/ADR/0001-native-manager.md` |
| `bn/docs/next/architecture/ADR/0002-guest-data-ownership.md` | NEXT_FUTURE | `docs/next/architecture/ADR/0002-guest-data-ownership.md` |
| `bn/docs/next/architecture/ADR/0003-lai-adapter.md` | DEPRECATED | `docs/next/architecture/ADR/0003-lai-adapter.md` |
| `bn/docs/next/architecture/ADR/0004-shared-manager-contract.md` | NEXT_FUTURE | `docs/next/architecture/ADR/0004-shared-manager-contract.md` |
| `bn/docs/next/architecture/ADR/0005-native-display-allocation.md` | NEXT_FUTURE | `docs/next/architecture/ADR/0005-native-display-allocation.md` |
| `bn/docs/next/architecture/ADR/README.md` | NEXT_FUTURE | `docs/next/architecture/ADR/README.md` |
| `bn/docs/next/architecture/AI-RUNTIME-ARCHITECTURE.md` | NEXT_FUTURE | `docs/next/architecture/AI-RUNTIME-ARCHITECTURE.md` |
| `bn/docs/next/architecture/API-DESIGN.md` | NEXT_FUTURE | `docs/next/architecture/API-DESIGN.md` |
| `bn/docs/next/architecture/APT-DISTRIBUTION-FEASIBILITY.md` | NEXT_ACTIVE | `docs/next/architecture/APT-DISTRIBUTION-FEASIBILITY.md` |
| `bn/docs/next/architecture/COMPONENT-ARCHITECTURE.md` | NEXT_FUTURE | `docs/next/architecture/COMPONENT-ARCHITECTURE.md` |
| `bn/docs/next/architecture/COMPUTE-ENGINE.md` | NEXT_FUTURE | `docs/next/architecture/COMPUTE-ENGINE.md` |
| `bn/docs/next/architecture/CONTROL-CENTER-ARCHITECTURE.md` | NEXT_FUTURE | `docs/next/architecture/CONTROL-CENTER-ARCHITECTURE.md` |
| `bn/docs/next/architecture/DEVICE-BRIDGE-ARCHITECTURE.md` | NEXT_FUTURE | `docs/next/architecture/DEVICE-BRIDGE-ARCHITECTURE.md` |
| `bn/docs/next/architecture/DISTRIBUTION-ROADMAP.md` | NEXT_ACTIVE | `docs/next/architecture/DISTRIBUTION-ROADMAP.md` |
| `bn/docs/next/architecture/EXTENSION-SDK.md` | NEXT_FUTURE | `docs/next/architecture/EXTENSION-SDK.md` |
| `bn/docs/next/architecture/IMPLEMENTATION-ROADMAP.md` | NEXT_ACTIVE | `docs/next/architecture/IMPLEMENTATION-ROADMAP.md` |
| `bn/docs/next/architecture/PRODUCT-VISION.md` | NEXT_FUTURE | `docs/next/architecture/PRODUCT-VISION.md` |
| `bn/docs/next/architecture/README.md` | NEXT_ACTIVE | `docs/next/architecture/README.md` |
| `bn/docs/next/architecture/SECURITY-MODEL.md` | NEXT_FUTURE | `docs/next/architecture/SECURITY-MODEL.md` |
| `bn/docs/next/architecture/SECURITY-ROADMAP.md` | NEXT_ACTIVE | `docs/next/architecture/SECURITY-ROADMAP.md` |
| `bn/docs/next/architecture/SYSTEM-ARCHITECTURE.md` | NEXT_FUTURE | `docs/next/architecture/SYSTEM-ARCHITECTURE.md` |
| `bn/docs/next/architecture/TESTING-STRATEGY.md` | NEXT_ACTIVE | `docs/next/architecture/TESTING-STRATEGY.md` |
| `bn/docs/next/architecture/UX-AND-DESIGN-SYSTEM.md` | NEXT_FUTURE | `docs/next/architecture/UX-AND-DESIGN-SYSTEM.md` |
| `bn/docs/next/architecture/WORKSPACE-ARCHITECTURE.md` | NEXT_FUTURE | `docs/next/architecture/WORKSPACE-ARCHITECTURE.md` |
| `bn/guides/device-benchmark-evidence.md` | SHARED_REFERENCE | `guides/device-benchmark-evidence.md` |
| `bn/guides/llama-htp-experimental.md` | SHARED_REFERENCE | `guides/llama-htp-experimental.md` |
| `bn/guides/llama-vulkan-extension.md` | SHARED_REFERENCE | `guides/llama-vulkan-extension.md` |
| `bn/guides/stable-diffusion-vulkan-extension.md` | SHARED_REFERENCE | `guides/stable-diffusion-vulkan-extension.md` |
| `bn/packaging/termux/README.md` | SHARED_REFERENCE | `packaging/termux/README.md` |
| `docs/ACCELERATOR-RELEASE-PLAN.md` | PUBLISHED_SOURCE | `bn/docs/ACCELERATOR-RELEASE-PLAN.md` |
| `docs/ANDROID-PHANTOM-PROCESS.md` | PUBLISHED_SOURCE | `bn/docs/ANDROID-PHANTOM-PROCESS.md` |
| `docs/ARCHITECTURE.md` | PUBLISHED_SOURCE | `bn/docs/ARCHITECTURE.md` |
| `docs/BENCHMARKS.md` | PUBLISHED_SOURCE | `bn/docs/BENCHMARKS.md` |
| `docs/BLENDER-MCP.md` | PUBLISHED_SOURCE | `bn/docs/BLENDER-MCP.md` |
| `docs/CLI.md` | PUBLISHED_SOURCE | `bn/docs/CLI.md` |
| `docs/CONFIGURATION.md` | PUBLISHED_SOURCE | `bn/docs/CONFIGURATION.md` |
| `docs/DOCUMENT-SCOPE.md` | PUBLISHED_SOURCE | `bn/docs/DOCUMENT-SCOPE.md` |
| `docs/FAQ.md` | PUBLISHED_SOURCE | `bn/docs/FAQ.md` |
| `docs/GRAPHICS-PERSISTENCE.md` | PUBLISHED_SOURCE | `bn/docs/GRAPHICS-PERSISTENCE.md` |
| `docs/INSTALLATION.md` | PUBLISHED_SOURCE | `bn/docs/INSTALLATION.md` |
| `docs/MANUAL.md` | PUBLISHED_SOURCE | `bn/docs/MANUAL.md` |
| `docs/QUICK-START.md` | PUBLISHED_SOURCE | `bn/docs/QUICK-START.md` |
| `docs/README.md` | PUBLISHED_SOURCE | `bn/docs/README.md` |
| `docs/SEO.md` | PUBLISHED_SOURCE | `bn/docs/SEO.md` |
| `docs/TERMUX-APT.md` | HISTORICAL_RELEASE | `bn/docs/TERMUX-APT.md` |
| `docs/TROUBLESHOOTING.md` | PUBLISHED_SOURCE | `bn/docs/TROUBLESHOOTING.md` |
| `docs/USAGE.md` | PUBLISHED_SOURCE | `bn/docs/USAGE.md` |
| `docs/V2-RELEASE-READINESS.md` | SHARED_REFERENCE | `bn/docs/V2-RELEASE-READINESS.md` |
| `docs/V2-RELEASE-REPORT.md` | HISTORICAL_RELEASE | `bn/docs/V2-RELEASE-REPORT.md` |
| `docs/V3-ARCHITECTURE.md` | NEXT_ACTIVE | `bn/docs/V3-ARCHITECTURE.md` |
| `docs/V3-PROPOSALS.md` | NEXT_FUTURE | `bn/docs/V3-PROPOSALS.md` |
| `docs/WORKLOADS.md` | PUBLISHED_SOURCE | `bn/docs/WORKLOADS.md` |
| `docs/audit/CURRENT-STATE.md` | HISTORICAL_RELEASE | Missing BN mirror |
| `docs/audit/DEVICE-VERIFICATION.md` | SHARED_REFERENCE | Missing BN mirror |
| `docs/audit/FEATURE-MATRIX.md` | SHARED_REFERENCE | Missing BN mirror |
| `docs/audit/REPOSITORY-FULL-AUDIT-2026-11-20.md` | REPOSITORY_AUDIT | Missing BN mirror |
| `docs/audit/REPOSITORY-STATE.md` | HISTORICAL_RELEASE | Missing BN mirror |
| `docs/index.md` | PUBLISHED_SOURCE | `bn/docs/index.md` |
| `docs/project/ARCHITECTURE-DECISIONS.md` | SHARED_REFERENCE | Missing BN mirror |
| `docs/project/DEVICE-VERIFICATION.md` | HISTORICAL_RELEASE | Missing BN mirror |
| `docs/project/IMPLEMENTATION-STATUS.md` | SHARED_REFERENCE | `bn/docs/project/IMPLEMENTATION-STATUS.md` |
| `docs/project/KNOWN-LIMITATIONS.md` | SHARED_REFERENCE | Missing BN mirror |
| `docs/project/NEXT-ACTIONS.md` | SHARED_REFERENCE | `bn/docs/project/NEXT-ACTIONS.md` |
| `docs/project/PROJECT-ROADMAP.md` | SHARED_REFERENCE | `bn/docs/project/PROJECT-ROADMAP.md` |
| `docs/project/RELEASE-STATUS.md` | SHARED_REFERENCE | `bn/docs/project/RELEASE-STATUS.md` |
| `docs/project/TECHNICAL-DEBT.md` | SHARED_REFERENCE | Missing BN mirror |
| `docs/release/README.md` | SHARED_REFERENCE | `bn/docs/release/README.md` |
| `docs/release/V2-RELEASE-RECONCILIATION.md` | SHARED_REFERENCE | `bn/docs/release/V2-RELEASE-RECONCILIATION.md` |
| `docs/release/V2-RELEASE-REPORT.md` | HISTORICAL_RELEASE | `bn/docs/release/V2-RELEASE-REPORT.md` |
| `docs/release/pages/v1.4.0-INSTALLATION.md` | HISTORICAL_RELEASE | `bn/docs/release/pages/v1.4.0-INSTALLATION.md` |
| `docs/release/pages/v2.0.1-INSTALLATION.md` | PUBLISHED_SOURCE | `bn/docs/release/pages/v2.0.1-INSTALLATION.md` |
| `docs/release/templates/RELEASE-INSTALLATION-TEMPLATE.md` | SHARED_REFERENCE | `bn/docs/release/templates/RELEASE-INSTALLATION-TEMPLATE.md` |
| `docs/next/architecture/ACCEPTANCE-CRITERIA.md` | NEXT_ACTIVE | `bn/docs/next/architecture/ACCEPTANCE-CRITERIA.md` |
| `docs/next/architecture/ADR/0001-native-manager.md` | NEXT_FUTURE | `bn/docs/next/architecture/ADR/0001-native-manager.md` |
| `docs/next/architecture/ADR/0002-guest-data-ownership.md` | NEXT_FUTURE | `bn/docs/next/architecture/ADR/0002-guest-data-ownership.md` |
| `docs/next/architecture/ADR/0003-lai-adapter.md` | DEPRECATED | `bn/docs/next/architecture/ADR/0003-lai-adapter.md` |
| `docs/next/architecture/ADR/0004-shared-manager-contract.md` | NEXT_FUTURE | `bn/docs/next/architecture/ADR/0004-shared-manager-contract.md` |
| `docs/next/architecture/ADR/0005-native-display-allocation.md` | NEXT_FUTURE | `bn/docs/next/architecture/ADR/0005-native-display-allocation.md` |
| `docs/next/architecture/ADR/README.md` | NEXT_FUTURE | `bn/docs/next/architecture/ADR/README.md` |
| `docs/next/architecture/AI-RUNTIME-ARCHITECTURE.md` | NEXT_FUTURE | `bn/docs/next/architecture/AI-RUNTIME-ARCHITECTURE.md` |
| `docs/next/architecture/API-DESIGN.md` | NEXT_FUTURE | `bn/docs/next/architecture/API-DESIGN.md` |
| `docs/next/architecture/APT-DISTRIBUTION-FEASIBILITY.md` | NEXT_ACTIVE | `bn/docs/next/architecture/APT-DISTRIBUTION-FEASIBILITY.md` |
| `docs/next/architecture/COMPONENT-ARCHITECTURE.md` | NEXT_FUTURE | `bn/docs/next/architecture/COMPONENT-ARCHITECTURE.md` |
| `docs/next/architecture/COMPUTE-ENGINE.md` | NEXT_FUTURE | `bn/docs/next/architecture/COMPUTE-ENGINE.md` |
| `docs/next/architecture/CONTROL-CENTER-ARCHITECTURE.md` | NEXT_FUTURE | `bn/docs/next/architecture/CONTROL-CENTER-ARCHITECTURE.md` |
| `docs/next/architecture/DEVICE-BRIDGE-ARCHITECTURE.md` | NEXT_FUTURE | `bn/docs/next/architecture/DEVICE-BRIDGE-ARCHITECTURE.md` |
| `docs/next/architecture/DISTRIBUTION-ROADMAP.md` | NEXT_ACTIVE | `bn/docs/next/architecture/DISTRIBUTION-ROADMAP.md` |
| `docs/next/architecture/EXTENSION-SDK.md` | NEXT_FUTURE | `bn/docs/next/architecture/EXTENSION-SDK.md` |
| `docs/next/architecture/IMPLEMENTATION-ROADMAP.md` | NEXT_ACTIVE | `bn/docs/next/architecture/IMPLEMENTATION-ROADMAP.md` |
| `docs/next/architecture/PRODUCT-VISION.md` | NEXT_FUTURE | `bn/docs/next/architecture/PRODUCT-VISION.md` |
| `docs/next/architecture/README.md` | NEXT_ACTIVE | `bn/docs/next/architecture/README.md` |
| `docs/next/architecture/SECURITY-MODEL.md` | NEXT_FUTURE | `bn/docs/next/architecture/SECURITY-MODEL.md` |
| `docs/next/architecture/SECURITY-ROADMAP.md` | NEXT_ACTIVE | `bn/docs/next/architecture/SECURITY-ROADMAP.md` |
| `docs/next/architecture/SYSTEM-ARCHITECTURE.md` | NEXT_FUTURE | `bn/docs/next/architecture/SYSTEM-ARCHITECTURE.md` |
| `docs/next/architecture/TESTING-STRATEGY.md` | NEXT_ACTIVE | `bn/docs/next/architecture/TESTING-STRATEGY.md` |
| `docs/next/architecture/UX-AND-DESIGN-SYSTEM.md` | NEXT_FUTURE | `bn/docs/next/architecture/UX-AND-DESIGN-SYSTEM.md` |
| `docs/next/architecture/WORKSPACE-ARCHITECTURE.md` | NEXT_FUTURE | `bn/docs/next/architecture/WORKSPACE-ARCHITECTURE.md` |
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
| `tests/fixtures/ternux-v1.4.0/README.md` | SHARED_REFERENCE | Shared / no translation required |
| `tools/blender-gpu-mcp/README.md` | SHARED_REFERENCE | Shared / no translation required |
| `tools/llama-htp/README.md` | SHARED_REFERENCE | Shared / no translation required |
| `tools/repo_knowledge/README.md` | SHARED_REFERENCE | Shared / no translation required |
| `src/data/navigation.ts` | PUBLISHED_SOURCE | Navigation has EN/BN labels |
| `src/pages/CHANGELOG.astro` | PUBLISHED_SOURCE | `src/pages/bn/CHANGELOG.astro` |
| `src/pages/CONTRIBUTING.astro` | PUBLISHED_SOURCE | `src/pages/bn/CONTRIBUTING.astro` |
| `src/pages/bn/CHANGELOG.astro` | PUBLISHED_SOURCE | `src/pages/CHANGELOG.astro` |
| `src/pages/bn/CONTRIBUTING.astro` | PUBLISHED_SOURCE | `src/pages/CONTRIBUTING.astro` |
| `src/pages/bn/docs/[...slug].astro` | PUBLISHED_SOURCE | `src/pages/docs/[...slug].astro` |
| `src/pages/bn/docs/index.astro` | PUBLISHED_SOURCE | `src/pages/docs/index.astro` |
| `src/pages/bn/index.astro` | PUBLISHED_SOURCE | `src/pages/index.astro` |
| `src/pages/docs/[...slug].astro` | PUBLISHED_SOURCE | `src/pages/bn/docs/[...slug].astro` |
| `src/pages/docs/index.astro` | PUBLISHED_SOURCE | `src/pages/bn/docs/index.astro` |
| `src/pages/index.astro` | PUBLISHED_SOURCE | `src/pages/bn/index.astro` |
## Review gaps

- Research directories under `experiments/` and `handoffs/` need confirmation that their content belongs in the Ternux documentation set; no external projects were modified.
- `docs/next/architecture/` now has Bengali counterparts for all technical and ADR Markdown pages. The translations have not yet received an independent semantic parity review; retain that review as follow-up when source changes occur.
- `docs/audit/DEVICE-VERIFICATION.md` contains the current live window-fit follow-up; its Bengali counterpart is historical and needs review before being used as a current claim.
- The generated `.repo/STATUS.md` remains unchanged because its owning workflow, not hand edits, defines the repository state.
