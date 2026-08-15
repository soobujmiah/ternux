# Security Policy

## Supported versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | ✅ Active development |
| < 1.0   | ❌ Pre-release      |

## Reporting a vulnerability

Ternux runs entirely in userspace via Termux and PRoot. It never requests root
access and never modifies Android system files. However, if you discover a
security issue:

1. **Do not open a public GitHub issue.**
2. Email the maintainer directly (see GitHub profile for contact).
3. Include a clear description, steps to reproduce, and the potential impact.

We will respond within 5 business days and coordinate a fix and disclosure
timeline.

## Scope

The following are **in scope**:
- Code execution vulnerabilities in the installer or CLI
- Path traversal in archive extraction
- Injection via untrusted input
- Unsafe handling of credentials

The following are **out of scope**:
- Android kernel or driver vulnerabilities
- Termux app vulnerabilities
- PRoot vulnerabilities
- Social engineering of termux users