#!/usr/bin/env bash
# Pull GitHub, build Pip, boot Simulator, install, launch.
# Run on the cloud Mac:  bash scripts/sim-run.sh
# Skip pull:             PIP_SKIP_PULL=1 bash scripts/sim-run.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

ROOT="$(pip_repo_root)"
pip_require_xcode

if [[ "${PIP_SKIP_PULL:-}" != "1" ]]; then
  pip_pull "$ROOT"
else
  cd "$ROOT"
fi

UDID="$(pip_pick_udid)"
pip_boot_simulator "$UDID"
pip_build_simulator "$ROOT" "$UDID"
pip_install_and_launch "$UDID" "$(pip_app_path "$ROOT")"

echo
echo "Simulator is running on the Mac desktop."
echo "View it with Screen Sharing / VNC, or capture: bash scripts/sim-shot.sh"
