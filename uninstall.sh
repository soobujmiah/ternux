#!/data/data/com.termux/files/usr/bin/bash
# =============================================================================
#  ternux — clean removal script
#
#  Usage
#    curl -fsSL https://soobujmiah.github.io/ternux/uninstall.sh | bash
#    bash uninstall.sh [1|2|3|4]
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
#  https://github.com/soobujmiah/ternux
# =============================================================================
set -u

# Detect and delegate to ternux CLI if available
for _try in \
  "/data/data/com.termux/files/usr/bin/ternux" \
  "${PREFIX:-}/bin/ternux" \
  "$HOME/.local/bin/ternux" \
  "$(cd "$(dirname "$0")" && pwd)/bin/ternux"; do
  if [ -x "$_try" ]; then
    exec "$_try" uninstall "$@"
  fi
done

# Fallback: use install.sh --uninstall
_installer="$(cd "$(dirname "$0")" && pwd)/install.sh"
if [ -f "$_installer" ]; then
  exec bash "$_installer" --uninstall "$@"
fi

# Last resort: manual instructions
cat << 'EOF'

ternux uninstall

If you have the ternux CLI installed, run:
  ternux uninstall

Otherwise, to manually remove:
  1. pkill -9 -f termux-x11
  2. pkill -9 -f pulseaudio
  3. proot-distro remove debian
  4. rm -f ~/x.sh
  5. rm -rf ~/.local/share/ternux/
  6. rm -f ~/.ternux-state
EOF