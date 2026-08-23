#!/usr/bin/env bash
# Capture the booted simulator screen. Copies nothing off the Mac.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

pip_require_xcode

OUT="${1:-/tmp/pip-sim.png}"
UDID="$(xcrun simctl list devices | awk '/Booted/{print}' | sed -n 's/.*(\([A-Fa-f0-9-]\{36\}\)).*/\1/p' | head -n 1)"
if [[ -z "$UDID" ]]; then
  UDID="$(pip_pick_udid)"
  pip_boot_simulator "$UDID"
fi

xcrun simctl io "$UDID" screenshot "$OUT"
echo "Wrote $OUT"
echo "Copy to this PC: scp USER@MAC:$OUT ."
