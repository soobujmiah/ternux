# Ternux release and architecture audit

**Audit date:** 2026-11-13 (UTC)
**Repository:** `soobujmiah/ternux`
**v2 release tag:** `v2.0.0` at `9106b04fc8627ae98b1d63c9912a28c8a4677441`
**Next phase:** complete and review v3 architecture before implementation

This page is the short current-state index. Detailed evidence is in [device verification](DEVICE-VERIFICATION.md), [repository state](REPOSITORY-STATE.md), and the [feature matrix](FEATURE-MATRIX.md). Generated `.repo/` data is created and merged only by its repository workflow.

## Current outcome

**Ternux v2.0.0 is released.** Its signed stable Termux APT repository is live, and the GitHub release includes the published `ternux_2.0.0_all.deb` and `SHA256SUMS`. The supported desktop guest scope is Debian, Ubuntu, and Alpine on the documented ARM64 Android stack. All blocking acceptance gates passed.

The release tag points to validated main commit `9106b04fc8627ae98b1d63c9912a28c8a4677441`. Exact-main Validate run `43372097795`, package artifact run `43372097797`, and repository contract run `43372097798` passed. Stable APT signature and package hash checks passed, and routine website deploy `43371001392` preserved both the stable and RC signed APT trees.

## Active device state

The owner's Debian `:0`, Ubuntu `:1`, and Alpine `:2` desktops remain READY at managed PIDs 18218, 14129, and 26946. Termux:X11 and PulseAudio routes are ready. Live runtime queries on all three guests returned the Ternux GTK, icon, and XFWM themes; titlebar layout `|HMC`; and the Ctrl+Space helper binding. The window-fit helper kept an oversized temporary client within each display. No desktop, X11, PulseAudio, or IBus session was restarted during the final release audit.

Direct calls to the IBus helper cycled engines in every guest. The newest host-generated Ctrl+Space event switched Debian and Ubuntu but not Alpine, although an earlier focused Alpine GTK/XTest probe had passed. The inconsistency is recorded in the [device report](DEVICE-VERIFICATION.md); physical Android keyboard delivery is not certified. Theme, titlebar, and viewport settings were already correct, so this audit did not rewrite them.

## Release record

- [Ternux v2.0.0 release](https://github.com/soobujmiah/ternux/releases/tag/v2.0.0)
- [Full release report](../V2-RELEASE-REPORT.md)
- [Signed Termux APT installation guide](../TERMUX-APT.md)
- [Machine-readable acceptance gates](../release-gates.json)

The package is a Termux host CLI; `tx install` provisions a guest desktop. Other named guest recipes, HTP/HMX, QNN image generation, untested Android keyboards, and arbitrary third-party toolkit behavior are outside the v2 qualification claim.

## Next phase

Complete and review the v3 product, system, component, control-center, compute, AI runtime, device bridge, workspace, security, API, and UX architecture. Add versioned acceptance criteria, ADRs, implementation roadmap, and the living project status pages before beginning v3 implementation.
