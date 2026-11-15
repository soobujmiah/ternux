# Terfetch

Terfetch is a standalone Bash system summary for Termux on Android and Linux
guests. It has no Ternux library dependency and can be copied into a separate
repository without changing its runtime interface.

```sh
terfetch
terfetch --json
terfetch --version
```

The native Termux host randomly selects one of ten large ASCII monograms at
each login. Nine variants show a centered `Presented by @soobujmiah` credit
below the logo and system facts. The special Sobuj monogram puts `Presented by`
above its mark and has no second credit. Every managed PRoot distro uses its
own stable official ASCII logo from the built-in catalog. The creator credit
is centered below the guest logo and facts. Daily-use host commands or guest
and distro-specific package-manager commands appear in a colorful footer below.
The distro art is adapted from [Fastfetch](https://github.com/fastfetch-cli/fastfetch)
under its MIT license; the full notice is embedded in the standalone script.
Terfetch has no Fastfetch runtime dependency. The art uses emerald and cyan
terminal colors and works without special fonts. `--json` is
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
