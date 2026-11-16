# Terfetch

Terfetch is a standalone Bash system summary for Termux on Android and Linux
guests. It has no Ternux library dependency and can be copied into a separate
repository without changing its runtime interface.

```sh
terfetch
terfetch --json
terfetch --version
```

The native Termux host randomly selects Android, Ternux Workstation, one of all
15 managed distro logos, or Sobuj's monogram at each login. Other variants show
a centered `Presented by @soobujmiah` credit below the logo and system facts.
The special Sobuj mark puts `Presented by` above a large SOBUJ monogram and has no second
credit. The Workstation mark depicts a compact desk and display. Narrow terminals
keep the logo and information side by side; fields that do not fit are hidden
until the terminal is widened or Terfetch is run again. Every managed PRoot
distro uses its own stable official ASCII logo from the built-in catalog. The
creator credit is centered below the guest logo and facts. Daily-use host commands or guest
and distro-specific package-manager commands appear in a colorful footer below.
Logo rows never continue below the information panel, and long values are
shortened to fit the terminal width.
The distro art is adapted from [Fastfetch](https://github.com/fastfetch-cli/fastfetch)
under its MIT license; the full notice is embedded in the standalone script.
Terfetch has no Fastfetch runtime dependency. The art uses emerald and cyan
terminal colors and works without special fonts. `--json` is
stable machine-readable output for future terminal, TUI, GUI, and web clients.
The program detects Termux or a managed Linux guest, then reports the OS,
Android device/release when available, architecture, CPU count, user, locale,
init process, privilege level, package manager and count, visible memory, free
space at the current home directory, and Ternux version when installed. It also
reports kernel, uptime, shell, terminal, CPU/GPU model, display and desktop
details when available.
Unavailable host properties are
omitted or reported as unknown; Terfetch does not guess graphics acceleration
state.

The Ternux installer places the same program in the Termux host and each managed
guest. Interactive Bash and Zsh startup hooks display it once when a terminal
shell starts, then export a guard so child shells and terminal integrations do
not display it again. Alpine's Ash login shell uses its profile hook. Set
`TERFETCH_NO_AUTORUN=1` to suppress automatic display in a shell. Running
`terfetch` manually always prints the summary, including after the startup
display. The installer syncs
the same standalone program to the Termux host and each managed guest.

The source is `terfetch`. Future extraction into a dedicated repository should
preserve its command-line interface and JSON keys, while keeping integrations
with Ternux as optional extensions.
