#!/usr/bin/env bash
# Pull GitHub and run Pip iOS tests on the cloud Mac.

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

echo "Testing Pip on $UDID ..."
xcodebuild \
  -project Pip.xcodeproj \
  -scheme Pip \
  -destination "id=$UDID" \
  -derivedDataPath "$ROOT/build/DerivedData" \
  test
