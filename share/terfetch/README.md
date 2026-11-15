# Terfetch

Terfetch is a standalone Bash system summary for Termux on Android and Linux
guests. It has no Ternux library dependency and can be copied into a separate
repository without changing its runtime interface.

```sh
terfetch
terfetch --json
terfetch --version
```

The native Termux host chooses one of ten original ASCII monograms at random
for each login. Nine variants show a small `Presented by @soobujmiah` credit
below the logo. The special Sobuj monogram instead puts `Presented by` above
the mark and has no credit below it. Each PRoot guest uses a stable mark for
its distro and shows a small creator credit below. Host output includes useful
`tx` commands; guest output includes companion `ternux` commands. The art uses
emerald and cyan terminal colors and works without special fonts. `--json` is
stable machine-readable output for future terminal, TUI, GUI, and web clients.
The program detects Termux or a managed Linux guest, then reports the OS,
Android device/release when available, architecture, CPU count, visible memory,
free space at the current home directory, and Ternux version when installed.
It also reports kernel, uptime, package count, shell, terminal, CPU/GPU model,
display and desktop details when available. Unavailable host properties are
omitted or reported as unknown; Terfetch does not guess graphics acceleration
state.

The Ternux installer places the same program in the Termux host and each managed
guest. Interactive Bash and Zsh startup hooks display it once per new shell;
Alpine's Ash login shell uses its profile hook. Set `TERFETCH_NO_AUTORUN=1` to
suppress automatic display in a shell, or invoke `terfetch` directly at any
time. The installer syncs the same standalone program to the Termux host and
each managed guest.

The source is `terfetch`. Future extraction into a dedicated repository should
preserve its command-line interface and JSON keys, while keeping integrations
with Ternux as optional extensions.
