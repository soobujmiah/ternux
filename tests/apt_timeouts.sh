#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PHASES="$ROOT/lib/phases.sh"

# APT transactions in guest setup must have both network limits and a hard
# process deadline. In particular, Firefox's package candidate install is part
# of the same base phase that previously could remain stuck for a long time.
grep -Fq 'timeout --signal=TERM --kill-after=10 300 apt update' "$PHASES"
grep -Fq 'timeout --signal=TERM --kill-after=10 900 apt install -y' "$PHASES"
grep -Fq 'Acquire::http::Timeout=30 -o Acquire::https::Timeout=30' "$PHASES"
grep -Fq 'timeout --signal=TERM --kill-after=10 900 apt install -y \$DPKG_FORCE -o Acquire::Retries=2 -o Acquire::http::Timeout=30 -o Acquire::https::Timeout=30 "\$browser_package"' "$PHASES"

echo 'base and optional guest APT calls have network and wall-clock limits'
