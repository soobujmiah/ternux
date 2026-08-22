# SKB Knowledge Return Contract

**Status:** Active

## Purpose
This repository remains authoritative for its own implementation state. SKB is the owner's cross-project knowledge layer. When this project is explicitly placed in the SKB workflow and authenticated write access is available, relevant SKB context should be consulted before substantive work and durable knowledge should be returned after substantive work.

## Adaptive knowledge return
Do not assume a fixed template, file type, language, or project structure. Determine what information is durable and reusable from the work, then choose the best SKB destination and documentation structure according to the existing SKB organization.

Return materially useful cross-project knowledge such as important decisions and rationale, reusable solutions, verified environment/device/toolchain evidence, significant bugs and fixes, limitations and rejected alternatives, security/privacy/licensing decisions, meaningful project-state changes, and relationships to other projects.

Do not return routine noise, temporary debug output, unsupported claims, credentials, tokens, private keys, cookies, or other secrets.

## Evidence and conflicts
Preserve provenance where practical: repository, branch, commit, file, command, test, device, or other evidence. Distinguish verified facts from observations, inference, recommendations, and unknown/stale information. If new knowledge conflicts with existing SKB knowledge, do not silently overwrite it; preserve the conflict or supersession relationship.

## Security boundary
- Never store SKB or GitHub credentials in this repository.
- Forks and clones must not inherit SKB write authority.
- Verify authenticated identity and actual write permission before an SKB write.
- If access is unavailable, report the proposed knowledge return rather than attempting an unauthorized write.

## Authority boundary
This contract governs knowledge continuity only. It does not authorize unrelated code changes, publication, release, deployment, destructive actions, or credential operations. Explicit task restrictions take precedence.

## Legacy mode
Legacy mode is deferred and is not part of the current implementation.
