# Contributing to ternux

Thank you for considering contributing to ternux! This project aims to be a
world-class open-source Linux-on-Android platform, and every contribution helps.

## Code of conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md).
By participating, you agree to uphold its standards.

## How to contribute

### Reporting bugs

1. Check the [FAQ](docs/FAQ.md) and [Troubleshooting](docs/TROUBLESHOOTING.md) guide
2. Search [existing issues](https://github.com/soobujmiah/ternux/issues)
3. Use the **Bug report** template — include device info, terminal output, and
   steps to reproduce

### Requesting features

Open an issue using the **Feature request** template. Explain the problem you
are solving, not just the solution you want.

### Device reports

If ternux works on your phone, share your device configuration! Use the
**Device report** template. This helps us track compatibility.

### Pull requests

1. Fork the repository
2. Create a branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Run `bash -n` on any shell scripts to verify syntax
5. Update documentation and CHANGELOG
6. Open a pull request with the **PR template**

### Development setup

```bash
git clone https://github.com/soobujmiah/ternux.git
cd ternux
bash -n bin/ternux          # syntax check CLI
(set -e; for f in lib/*.sh; do bash -n "$f"; done)  # check each library
bash -n install.sh          # syntax check installer
```

### Coding standards

- **Bash scripts**: use `set -u`, `local` variables, avoid backtick execution
- **Documentation**: write in English (Bangla translations welcome too)
- **JSON output**: every major CLI command must support `--json`
- **Tests**: test idempotency — running a phase twice should be safe
- **Commits**: use conventional commits (`feat:`, `fix:`, `docs:`, `refactor:`)

### Documentation

All documentation lives in `docs/` (English) and `bn/docs/` (Bangla).
Both must stay synchronized. When adding a feature:

1. Update the English doc
2. Update the Bangla mirror
3. Reference the doc from README.md and the nav

The JSON output schema is documented in `share/templates/json-schema.md`.

## Project structure

```
bin/ternux        CLI entry point
lib/*.sh          Modular shell libraries
install.sh        Thin bootstrapper (standalone install)
uninstall.sh      Clean removal script
docs/             English documentation
bn/               Bangla documentation
share/templates/  Schemas and templates
.github/          Issue and PR templates
```

## Getting help

- Open a GitHub issue for bugs and questions
- Read the [Architecture](docs/ARCHITECTURE.md) document to understand the stack
- Read the [Manual installation](docs/MANUAL.md) for step-by-step setup

Thank you for making ternux better!