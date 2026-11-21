# Ternux project goal and current scope

**Last reviewed:** 2026-11-21
**Repository:** <https://github.com/soobujmiah/ternux>

## Mission

Maintain Ternux as a reliable Android/Termux Linux-workspace project. Keep release
history and current installation/support claims evidence-based. Treat future
architecture and feature ideas as proposals under **Next Version / পরবর্তী
সংস্করণ**, not as shipped features or a numbered future release.

## Current public facts

- The v1.4.0 release and its installation documentation are historical records
  and must remain unchanged.
- The v2.0.1 GitHub Release entry was removed. Its Git source tag is retained
  solely for provenance; do not imply that it is a published or supported
  GitHub Release.
- The stable APT/package channel is unavailable. Do not recommend `pkg install
  ternux` or imply that it currently works. Keep current installation guidance
  pinned to the verified source route and its evidence.
- Preserve the maintained desktop setup references to Debian, Ubuntu, Kali
  Linux, and Alpine. A maintained recipe is not the same as verified support on
  a physical device; state evidence and limitations precisely.
- Preserve APT timeout/dpkg recovery behavior and its regression coverage.

## Change and evidence requirements

1. Audit current source, tests, release evidence, and documentation before
   changing behavior or support claims.
2. Keep future ideas in the bilingual Next Version planning area and clearly
   identify proposals, partial implementation, and acceptance gates.
3. Do not remove existing implementations merely because documentation or
   distribution qualification changes. Preserve recovery paths and regression
   tests unless an explicit owner decision supersedes them.
4. Validate relevant tests, documentation links, formatting, and production
   build after edits. Report any hardware or hosted-service checks that were
   not possible instead of implying they passed.
5. Preserve provenance and historical records without presenting them as
   current installation instructions or release availability.

## Planning entry points

- [Next Version (English)](../docs/next/README.md)
- [পরবর্তী সংস্করণ (বাংলা)](../bn/docs/next/README.md)
- [Release status](../docs/project/RELEASE-STATUS.md)
- [APT/package channel status](../docs/TERMUX-APT.md)
