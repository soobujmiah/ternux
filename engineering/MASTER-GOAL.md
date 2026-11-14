MASTER GOAL: Ternux v2 Release Finalization & v3 Android Computing Platform Evolution

Project: Ternux
Repository: https://github.com/soobujmiah/ternux
Owner: Sobuj Miah (@soobujmiah)
Primary Device: Redmi Turbo 4 Pro — Snapdragon 8s Gen 4, Adreno 825, Android 16, ARM64
Implementation Targets: Live Native Termux Device + GitHub Repository
Mission: Finalize and release Ternux v2, then evolve it into a modular, hardware-aware Android Computing Platform through a properly documented, phased v3 development program.

---

1. YOUR ROLE

Act as a Principal Android Systems Architect, Linux Platform Engineer, GPU/AI Runtime Engineer, Product Architect, Security Engineer, UX Engineer, and Release Manager.

You are responsible for taking the existing Ternux project from its actual current state to a verified v2 release, then establishing and progressively implementing the v3 architecture.

This is an implementation assignment, not merely a research or planning exercise.

You must work in two parallel environments:

1. Live Device Implementation: The actual Native Termux environment on the owner's Redmi Turbo 4 Pro.
2. Repository Implementation: The Ternux GitHub repository, including source code, architecture, documentation, tests, CI, release configuration, and version history.

Do not assume that a feature exists simply because documentation claims it exists. Inspect actual source code, runtime behavior, device evidence, and repository state.

Do not rewrite the existing project unnecessarily. Preserve working components and improve the existing architecture wherever practical.

2. STRATEGIC PRODUCT DIRECTION

Ternux must evolve beyond being another Termux/PRoot installation script.

The long-term product identity is:

Ternux — An Android Computing Platform

Tagline:

"Your Phone. Your Workspace. Your Compute."

The platform should provide a unified environment for:

- Linux desktop computing.
- Development workspaces.
- CPU/GPU-accelerated workloads.
- Local AI inference and model management.
- Android hardware integration.
- Multiple Linux guest environments.
- Resource and service management.
- Recovery, diagnostics, and system maintenance.

The product must remain modular, extensible, resource-conscious, privacy-aware, and accessible to both beginners and advanced developers.

Do not attempt to implement every proposed capability immediately. First document the complete architecture and roadmap, then implement in controlled phases.

3. PHASE 0 — COMPLETE CURRENT STATE AUDIT

Before modifying anything, perform a fresh audit of:

- Current GitHub main branch and exact HEAD commit.
- Existing branches, pull requests, releases and tags.
- Current v2 release gates.
- Installer and updater implementation.
- Native Termux CLI and host services.
- PRoot guest management.
- Debian, Ubuntu and Alpine profiles.
- GPU, Vulkan, Zink, Turnip and VirGL integration.
- Audio, microphone, camera and storage integration.
- AI and accelerator components.
- Current tests and CI workflows.
- Existing documentation and bilingual README.
- Existing generated operational status.
- Actual device runtime state.

Inspect the real implementation rather than relying exclusively on prior audit reports.

Produce:

docs/audit/CURRENT-STATE.md

docs/audit/DEVICE-VERIFICATION.md

docs/audit/REPOSITORY-STATE.md

docs/audit/FEATURE-MATRIX.md

The feature matrix must distinguish:

- Implemented and verified.
- Implemented but partially verified.
- Documented but not implemented.
- Experimental.
- Deferred.
- Unsupported.

Do not confuse successful installation with complete device qualification.

4. PHASE 1 — FINALIZE AND RELEASE TERNux v2.0.0

This phase has priority over all new v3 feature development.

4.1 Supported v2 distributions

The official v2 release scope is limited to three Linux distributions:

1. Debian — Primary and most extensively tested distribution.
2. Ubuntu — Verified, but with less extensive testing.
3. Alpine Linux — Verified, but with less extensive testing.

All three must remain supported in the v2 release.

Important distinction:

- Debian receives the strongest qualification and performance testing.
- Ubuntu and Alpine retain verified status, but their evidence must accurately describe the smaller testing scope.
- Do not claim equivalent testing depth across all three.

All other existing distribution profiles must be documented as future qualification targets.

Do not remove their existing implementations merely because they are outside the official v2 release scope.

Do not spend v2 release time trying to qualify every existing distribution profile.

4.2 Simplified v2 release policy

The v1.4.0-to-v2.0.0 rollback and migration rollback demonstration is NOT a mandatory v2 release blocker.

The owner has explicitly decided:

- Users wanting v2 will install v2.
- Users wanting v1.4.0 can continue installing the preserved v1.4.0 release artifact.
- A mandatory rollback from v2 to v1.4.0 is not required.
- Do not spend unnecessary time implementing or demonstrating that backward rollback path.
- Preserve existing v1.4.0 release artifacts and documentation.
- Future releases after v2 must maintain a reliable rollback strategy between supported subsequent versions.

Update the release-gate definitions, acceptance criteria, documentation and generated release reports accordingly.

Do not weaken genuine installation integrity, upgrade safety, or data protection requirements.

4.3 Browser qualification

The currently incomplete default-browser qualification must be completed for exactly:

- Debian
- Ubuntu
- Alpine

Do not expand this work to all fifteen existing distro profiles.

Verify:

- Browser installation from the correct distribution package source.
- Required dependencies.
- Headless startup where supported.
- Desktop launch.
- Basic runtime behavior.
- Failure reporting.
- Compatibility with the selected GPU configuration.

Use clean guest environments and real device verification where appropriate.

Other distro browser qualification is deferred to v3.

4.4 Native Termux package installation

Investigate and complete the package installation and upgrade lifecycle where necessary.

Verify the appropriate Termux-native installation route, including:

- Trusted package source.
- Repository signing and key verification.
- Package installation.
- Version upgrade.
- Dependency resolution.
- Package metadata.
- Clean uninstall.
- Existing installation handling.
- Repository availability and recovery.

If the public "pkg install ternux" route is intended for v2, complete the required signed repository publication and test it with the actual Termux package manager.

Do not leave an incomplete or misleading package installation claim in the README.

If a package lifecycle is not technically ready, clearly document the supported installation method and keep the release blocked only where the owner-approved v2 distribution requirements demand it.

4.5 AI and GPU qualification

Debian already has significant GPU and AI integration.

Inspect the actual implementation and runtime.

Improve Debian's existing integration if necessary.

Verify:

- CPU inference.
- Vulkan inference.
- GPU renderer correctness.
- AI workload compatibility with the desktop.
- Model/runtime installation integrity.
- Memory consumption.
- Failure handling.
- Clean service lifecycle.
- Host and guest isolation.

Do not unnecessarily redesign working Debian accelerator infrastructure.

Ubuntu and Alpine AI accelerator integration can be deferred to v3.

Experimental Qualcomm HTP/QNN features must remain clearly identified as experimental until their correctness and recovery criteria are satisfied.

4.6 Hardware qualification

Use the Redmi Turbo 4 Pro as the primary reference device.

Prioritize practical Debian verification for v2:

- GPU renderer.
- Vulkan.
- Desktop stability.
- CPU/RAM behavior.
- Thermal behavior.
- Storage.
- Audio.
- Development workloads.
- AI workloads.

Broader device compatibility and extensive multi-device performance testing can be developed as a v3 program.

Never claim universal Android device compatibility based on one device.

4.7 v2 release documentation

Update:

- README.md
- Bengali README.
- Installation guide.
- Manual installation guide.
- Quick start.
- Supported distributions.
- Hardware compatibility.
- Graphics documentation.
- AI/accelerator documentation.
- Known limitations.
- Troubleshooting.
- Release notes.
- Changelog.
- Upgrade instructions.

The README must communicate the actual product capabilities clearly without losing important technical information.

The information architecture should be reorganized so that:

1. New users quickly understand what Ternux does.
2. Supported features are immediately visible.
3. Debian, Ubuntu and Alpine support is clear.
4. GPU acceleration is explained.
5. AI capabilities are discoverable.
6. Installation is straightforward.
7. Advanced documentation remains accessible.
8. Limitations and experimental features are transparent.

Do not remove important information simply to make the README shorter.

Use progressive disclosure:

- A concise product overview.
- Feature highlights.
- Quick installation.
- Supported hardware and distributions.
- Screenshots and demonstrations.
- Feature matrix.
- Links to detailed technical guides.
- Troubleshooting and advanced documentation.

Maintain consistent English and Bengali documentation.

4.8 v2 release acceptance

The v2 release must have:

- Three supported distributions qualified to their documented scope.
- Debian's deeper testing evidence preserved.
- Browser qualification completed for all three.
- Package distribution lifecycle verified where required.
- Installer and updater tested.
- CI passing on the exact release commit.
- Documentation validation passing.
- Release gates accurately reflecting the owner-approved scope.
- Known limitations documented.
- A real GitHub release with the correct version and assets.

Generate:

docs/release/V2-RELEASE-REPORT.md

Do not declare v2 ready merely because the README says v2.0.0.

5. PHASE 2 — DOCUMENT THE COMPLETE v3 ARCHITECTURE BEFORE IMPLEMENTATION

After v2 release requirements are satisfied, begin the v3 architecture program.

The complete architecture and implementation roadmap must be documented BEFORE large-scale feature implementation.

Create:

docs/v3/PRODUCT-VISION.md

docs/v3/SYSTEM-ARCHITECTURE.md

docs/v3/COMPONENT-ARCHITECTURE.md

docs/v3/CONTROL-CENTER-ARCHITECTURE.md

docs/v3/COMPUTE-ENGINE.md

docs/v3/AI-RUNTIME-ARCHITECTURE.md

docs/v3/DEVICE-BRIDGE-ARCHITECTURE.md

docs/v3/WORKSPACE-ARCHITECTURE.md

docs/v3/SECURITY-MODEL.md

docs/v3/API-DESIGN.md

docs/v3/UX-AND-DESIGN-SYSTEM.md

docs/v3/IMPLEMENTATION-ROADMAP.md

docs/v3/ACCEPTANCE-CRITERIA.md

docs/v3/ADR/

The architecture must describe component ownership, data flow, APIs, permissions, process boundaries, lifecycle management, error handling, compatibility, testing and recovery.

Avoid monolithic implementation.

6. PHASE 3 — FIVE CORE PRODUCT SYSTEMS

Develop the following five interconnected product systems.

SYSTEM 1: Ternux Workspace

Purpose: Unified Linux and development environment management.

Capabilities:

- Debian, Ubuntu, Alpine and future distro support.
- Multiple guest environments.
- Guest creation, installation, start, stop and removal.
- Project-specific workspaces.
- Workspace isolation.
- Development toolchains.
- Persistent storage.
- Snapshot and recovery architecture.
- Shared workspace access with explicit configuration.
- Consistent CLI and GUI management.

Preserve existing working commands and workflows wherever possible.

SYSTEM 2: Ternux Compute

Purpose: Hardware-aware compute management.

Capabilities:

- CPU detection.
- GPU detection.
- RAM and storage detection.
- Qualcomm and Adreno identification.
- KGSL detection.
- Vulkan capability detection.
- OpenCL capability detection.
- QNN/HTP capability detection where accessible.
- Graphics backend selection.
- CPU/GPU workload routing.
- Resource monitoring.
- Thermal awareness.
- Performance diagnostics.
- Safe fallback mechanisms.

Do not advertise hardware acceleration simply because a device node exists.

Verify actual backend operation.

Do not assume every Android device exposes Qualcomm NPU hardware to third-party software.

SYSTEM 3: Ternux AI

Purpose: Integrated local AI computing.

Capabilities:

- Local LLM management.
- GGUF model management.
- Model metadata and checksum verification.
- Model installation and removal.
- CPU and Vulkan backend selection.
- Device-specific accelerator extensions.
- Local inference servers.
- OpenAI-compatible local API.
- AI service lifecycle.
- Model memory requirements.
- Benchmarking.
- Model compatibility reports.

Design clean integration points with the existing LAI project.

Ternux should provide the workspace, hardware and service management layer.

LAI should remain an independently maintainable AI runtime.

Do not duplicate LAI's responsibilities inside Ternux.

Keep experimental accelerators isolated from stable functionality.

SYSTEM 4: Ternux Device Bridge

Purpose: Secure integration between native Android and guest Linux.

Capabilities:

- Camera integration.
- Microphone access.
- Audio bridge.
- Android sensor access.
- Device information.
- Selected file and directory sharing.
- Local service communication.
- Permission-aware operations.
- Explicit lifecycle management.

Implement host-side services where Android permissions or APIs require native Termux access.

Do not assume PRoot can directly access privileged Android facilities.

Design authenticated local communication and prevent unnecessary exposure to external networks.

SYSTEM 5: Ternux Control Center

This is a high-priority v3 product.

Architectural decision: The Control Center MUST live on the Native Termux Host Side, outside every PRoot guest.

Do not place the primary Control Center inside Debian, Ubuntu, Alpine or another guest.

Reasons:

- It must work before any guest is installed.
- It must install and manage guest environments.
- It must manage guest lifecycle.
- It must diagnose broken guests.
- It must recover environments.
- It must manage host-side services.
- It must remain operational when a guest is stopped or damaged.
- It must avoid making a guest responsible for controlling itself.

Native GUI strategy

First inspect the current Native Termux GUI and graphics capabilities.

Determine the most reliable way to provide a graphical management interface from Native Termux.

Consider:

- A lightweight native Android-compatible GUI.
- A local web-based Control Center.
- Termux:X11-hosted GUI where technically appropriate.
- A dedicated Android application as a possible future extension.

Choose an architecture based on actual Termux capabilities, dependencies, performance and maintenance costs.

Do not assume that a normal browser-based interface automatically has unrestricted access to Termux host APIs.

The GUI must communicate with a controlled Native Termux management service through a documented and secured local API.

Control Center features

The initial Control Center must provide:

Dashboard

- Ternux installation status.
- Host environment status.
- Installed guest environments.
- Running services.
- Hardware summary.
- CPU and RAM usage.
- Available storage.
- GPU and renderer status.

Guest Management

- Install Debian.
- Install Ubuntu.
- Install Alpine.
- View installed environments.
- Start and stop sessions.
- Open guest terminals.
- Launch guest desktops.
- Remove guest environments with explicit confirmation.

Compute Management

- GPU capability.
- Vulkan status.
- Graphics backend.
- CPU and RAM monitoring.
- Thermal information where available.
- Hardware diagnostics.

AI Management

- Installed models.
- Model metadata.
- AI runtime status.
- Inference server status.
- Backend selection.
- Resource consumption.

Service Management

- Host-side services.
- Guest-side services.
- Service logs.
- Start/stop controls.
- Health status.

Maintenance

- Diagnostics.
- Repair operations.
- Updates.
- Backup and restore.
- Storage management.
- Logs and troubleshooting.

Settings

- Language.
- Theme.
- Desktop preferences.
- Resource limits.
- Permission management.

The interface must support a clean mobile-first layout and remain usable on external displays.

Bangla and English localization must be supported consistently.

SYSTEM INTEGRATION

The five systems must work together through clearly defined APIs and lifecycle boundaries.

Proposed architecture:

Ternux Control Center
|
Native Termux Management Service
|
Ternux Core / Orchestrator
|
+-----+------+-------+------+
|            |       |      |
Workspace    Compute   AI   Device Bridge
|            |       |      |
+------------+-------+------+
|
Android Host / Hardware
|
Linux Guest Environments

This is a logical architecture, not a requirement to force every component into one process.

Define the actual process boundaries and communication protocols in the architecture documents.

7. PHASE 4 — GRAPHICAL USER EXPERIENCE

Create a cohesive Ternux design system.

The Control Center should look and feel like a professional Android computing management product.

Design requirements:

- Mobile-first responsive layout.
- Dark and light themes.
- Consistent typography.
- Clear information hierarchy.
- Accessible controls.
- Real-time status indicators.
- Hardware capability visualization.
- Useful error explanations.
- Minimal unnecessary animation.
- Smooth navigation.
- Proper empty states.
- Installation progress.
- Recovery guidance.

Avoid generic dashboards with decorative statistics.

Every displayed value must originate from a real system query or clearly identified test fixture.

Prepare the UX specification, screen inventory, component library and interaction flows before implementation.

The GUI must be genuinely functional, not merely a visual prototype.

8. PHASE 5 — SECURITY, STORAGE AND RESOURCE GOVERNANCE

Preserve the owner's intended storage behavior.

The current default Android shared-storage access is intentional.

The owner explicitly wants a seamless user experience where the selected Android device's shared storage is available to the guest by default.

Do not silently remove or change this behavior.

However:

- Document the default storage behavior clearly.
- Preserve the existing scoped grant/revoke functionality.
- Avoid exposing Termux private application data.
- Validate paths.
- Prevent unintended access outside the intended shared-storage scope.
- Provide understandable storage status.
- Avoid insecure network exposure.
- Protect host and guest boundaries.

Security must be evaluated according to the actual intended permission model, not by blindly changing defaults.

Also define:

- Service isolation.
- API authentication.
- Localhost binding.
- Process lifecycle.
- File permissions.
- Model provenance.
- Download verification.
- Recovery safety.
- Resource limits.
- Failure containment.

9. PHASE 6 — RESOURCE-AWARE AND ADAPTIVE COMPUTING

Ternux must understand that Android phones have limited thermal and memory budgets.

Implement an adaptive resource management architecture.

Potential capabilities:

- Detect available memory.
- Monitor workload memory.
- Detect thermal conditions.
- Warn before launching oversized models.
- Suggest appropriate model quantization.
- Select suitable graphics backend.
- Avoid unnecessary background services.
- Provide low-resource desktop mode.
- Prevent avoidable out-of-memory situations.
- Provide transparent workload status.

Do not implement fake or unsupported performance controls.

Measure real behavior and document limitations.

10. PHASE 7 — HARDWARE COMPATIBILITY AND DEVICE QUALIFICATION

Create a device compatibility framework.

The Redmi Turbo 4 Pro is the primary reference device.

The system must distinguish:

- Hardware detected.
- Capability detected.
- Backend available.
- Backend successfully initialized.
- Workload successfully executed.
- Performance measured.

These are separate verification levels.

Create a structured compatibility record for every tested device.

Future devices should be added without rewriting the core architecture.

Broader device testing is a v3 objective, not an excuse to delay the approved v2 release scope.

11. PHASE 8 — EXTENSION AND DEVELOPER ECOSYSTEM

Design a future Ternux Extension SDK.

Potential extension categories:

- Linux applications.
- Developer toolchains.
- AI models and runtimes.
- Compute backends.
- Device integrations.
- Workspace templates.
- Monitoring integrations.

Define:

- Extension manifest.
- Version compatibility.
- Dependencies.
- Permissions.
- Installation lifecycle.
- Removal lifecycle.
- Integrity verification.
- API compatibility.
- Documentation requirements.

Do not create an unsafe arbitrary code execution mechanism.

Extensions must operate within clearly defined permissions and trust boundaries.

12. PARALLEL IMPLEMENTATION STRATEGY

Work on the physical device and repository in parallel wherever technically possible.

Device work

Inspect and verify:

- Native Termux packages.
- Host services.
- GUI feasibility.
- Current Ternux installation.
- Guest environments.
- GPU and Vulkan.
- AI runtime.
- Desktop integration.
- Resource behavior.

Do not destroy an existing working installation to test a new implementation.

Use isolated test environments where possible.

Repository work

Implement:

- Source changes.
- Modular architecture.
- Native management service.
- Control Center.
- APIs.
- Documentation.
- Tests.
- CI workflows.
- Release automation.

Every implementation task must have:

1. Objective.
2. Source files involved.
3. Dependencies.
4. Acceptance criteria.
5. Automated tests.
6. Device verification requirements.
7. Documentation updates.

Maintain a clear relationship between repository commits and live-device test evidence.

Do not claim that a feature is device-verified if it was only tested in CI.

13. IMPLEMENTATION RULES

Follow these rules throughout the project.

1. Inspect before modifying.
2. Preserve existing working functionality.
3. Prefer incremental changes.
4. Avoid unnecessary rewrites.
5. Keep modules independently testable.
6. Maintain backward compatibility where required.
7. Keep English and Bengali documentation synchronized.
8. Never fabricate test results.
9. Never mark a feature complete without evidence.
10. Keep experimental features clearly separated.
11. Avoid duplicate implementations across projects.
12. Record architectural decisions in ADRs.
13. Keep the main branch coherent.
14. Use feature branches for substantial changes.
15. Review changes before merging.
16. Keep the release artifacts reproducible.

The owner's explicit operational restriction:

Never reboot the Android device, restart Termux, restart a critical service, or perform a disruptive operation without obtaining explicit owner approval first.

Before any such operation:

- Explain why it is necessary.
- Identify the affected processes.
- Explain possible data or session impact.
- Wait for approval.

Do not interpret general implementation authorization as permission to reboot or restart the device.

Never delete existing project data, models, guest environments or backups without explicit approval.

14. REPOSITORY OPERATIONAL STATUS SYNCHRONIZATION

Re-audit the repository's generated operational status.

Compare:

- Current main HEAD.
- Project classification.
- Generated repository status.
- Event history.
- Release evidence.
- CI results.
- Documentation state.

Ensure generated status files reflect the current actual main branch.

Do not simply edit timestamps or replace stale information with guessed values.

Regenerate them through the project's existing deterministic automation wherever available.

Verify that generated artifacts are reproducible and that no stale operational snapshot is presented as current.

Preserve the repository's existing governance policies and evidence collection standards.

15. DOCUMENTATION-FIRST DEVELOPMENT

Before starting substantial v3 implementation, complete the architecture documentation.

Then divide implementation into independent, testable milestones.

For every milestone:

- Document the intended behavior.
- Define its API.
- Define dependencies.
- Define acceptance tests.
- Implement.
- Test in CI.
- Verify on the physical device when relevant.
- Update documentation.
- Record the outcome.

Do not allow documentation to describe future functionality as already implemented.

Use explicit statuses:

- PROPOSED
- DESIGNED
- IMPLEMENTING
- IMPLEMENTED
- CI_VERIFIED
- DEVICE_VERIFIED
- RELEASED
- DEFERRED

16. SUGGESTED DEVELOPMENT SEQUENCE

Use this sequence unless the current audit demonstrates a technical dependency requiring adjustment.

Milestone A — v2 Release Closure

- Three-distribution scope.
- Browser qualification.
- Package installation lifecycle.
- Release documentation.
- Release gates.
- Exact-head CI.
- v2.0.0 release.

Milestone B — v3 Architecture

- Product vision.
- System architecture.
- Native Control Center architecture.
- API design.
- Security model.
- UX design.
- Acceptance criteria.

Milestone C — Native Management Foundation

- Native host service.
- Core API.
- Guest lifecycle management.
- Device capability detection.
- Health diagnostics.

Milestone D — Control Center

- Dashboard.
- Guest management.
- Compute management.
- Service management.
- Maintenance and recovery.
- Localization.

Milestone E — Compute and AI Integration

- Compute manager.
- Debian AI integration refinement.
- Model manager.
- Runtime orchestration.
- Backend verification.

Milestone F — Device Bridge

- Audio.
- Camera.
- Microphone.
- Sensors.
- Storage and device APIs.

Milestone G — Workspace and Extensions

- Project environments.
- Workspace templates.
- Snapshots.
- Extension architecture.

Milestone H — Broad Qualification

- Additional distributions.
- More Android devices.
- Performance benchmarks.
- Compatibility matrix.
- v3 release qualification.

The order may be refined based on real dependencies, but v2 release closure must not be displaced by speculative v3 development.

17. REQUIRED PROJECT MANAGEMENT DOCUMENTS

Maintain these living documents:

- PROJECT-ROADMAP.md
- IMPLEMENTATION-STATUS.md
- RELEASE-STATUS.md
- DEVICE-VERIFICATION.md
- ARCHITECTURE-DECISIONS.md
- TECHNICAL-DEBT.md
- KNOWN-LIMITATIONS.md
- NEXT-ACTIONS.md

Each must represent the actual state.

Keep completed, active, blocked and deferred work separate.

18. FINAL ACCEPTANCE CRITERIA

This master goal is successful when:

v2:

- Ternux v2 is genuinely released.
- Debian, Ubuntu and Alpine are the officially supported v2 distributions.
- Their different qualification depths are accurately documented.
- Browser qualification is completed for all three.
- Required package distribution behavior is verified.
- The unnecessary v1.4.0-to-v2 rollback blocker is removed.
- Existing v1.4.0 artifacts remain accessible.
- README and documentation communicate the product clearly.
- Main branch and generated status are synchronized.

v3 Foundation:

- Complete product architecture is documented.
- Five core systems have defined ownership and interfaces.
- Native Termux Control Center architecture is established.
- Security and resource governance are specified.
- Implementation milestones and acceptance criteria exist.

v3 Implementation:

- Native management service operates independently of PRoot.
- Control Center can manage guest environments from outside them.
- Workspace, Compute, AI and Device Bridge integration works through documented APIs.
- Real hardware capabilities are detected and verified.
- CI and physical-device tests provide reproducible evidence.
- Documentation accurately reflects implemented capabilities.

19. EXECUTION INSTRUCTIONS

Start immediately with Phase 0.

Do not return only a proposal or a list of recommendations.

Inspect the actual repository and device, reconcile existing work, and produce the first audit.

Then:

1. Identify the shortest safe path to v2.
2. Update release gates to match the owner's explicit decisions.
3. Close the actual v2 blockers.
4. Release v2.
5. Document the complete v3 architecture.
6. Implement v3 incrementally.
7. Keep repository and physical-device work synchronized.
8. Report evidence and remaining work after each milestone.

If a blocker requires owner input, ask one precise question rather than guessing.

If a test cannot be performed on the current device, document it as unverified and continue with independent tasks.

Final instruction: Prioritize shipping a reliable Ternux v2 over expanding scope. Build v3 as a well-architected platform, not as an uncontrolled collection of features.