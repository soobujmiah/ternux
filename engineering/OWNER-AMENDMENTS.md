# Owner amendments to the Ternux master assignment

**Last updated:** 2026-11-21
**Authority:** Owner instructions in this work session.

## Documentation naming and release boundaries

- Keep future architecture, capability, and implementation planning under **Next Version / পরবর্তী সংস্করণ**. Do not label future work as a numbered Ternux major version or imply it has shipped.
- Preserve the historical release record and immutable tag provenance where needed for audit. Keep the v1.4.0 release artifacts and documentation unchanged.
- The v2.0.1 GitHub Release entry was removed; its source tag remains only as provenance. Do not describe the Termux package channel as usable: the repository is unavailable and `pkg install ternux` is not an installation route.
- Keep the four maintained desktop setups explicit: Debian, Ubuntu, Kali Linux, and Alpine. Distinguish recipes from device-verified support and document evidence limits.
- Preserve APT timeout/dpkg recovery implementation and regression tests; do not remove or reverse existing recovery work.

The bilingual [Next Version index](../docs/next/README.md) is the entry point for future planning. The historical release and audit documents are not current installation instructions.
