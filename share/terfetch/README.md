# Terfetch

Terfetch is a standalone Bash system summary for Termux on Android and Linux
guests. It has no Ternux library dependency and can be copied into a separate
repository without changing its runtime interface.

```sh
terfetch
terfetch --json
terfetch --version
```

The human-readable output includes a compact ASCII Ternux monogram with
emerald and cyan terminal colors; it remains legible without special fonts.
`--json` is
stable machine-readable output for future terminal, TUI, GUI, and web clients.
The program detects Termux or a managed Linux guest, then reports the OS,
Android device/release when available, architecture, CPU count, visible memory,
free space at the current home directory, and Ternux version when installed.
Unavailable host properties are omitted or reported as unknown; Terfetch does
not guess GPU identity or acceleration state.

The Ternux installer places the same program in the Termux host and each managed
guest. Interactive Bash and Zsh startup hooks display it once per new shell;
Alpine's Ash login shell uses its profile hook. Set `TERFETCH_NO_AUTORUN=1` to
suppress automatic display in a shell, or invoke `terfetch` directly at any
time.

The source is `terfetch`. Future extraction into a dedicated repository should
preserve its command-line interface and JSON keys, while keeping integrations
with Ternux as optional extensions.
