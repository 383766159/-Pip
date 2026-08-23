#!/usr/bin/env bash
# Shared helpers for cloud-Mac simulator scripts.

set -euo pipefail

pip_repo_root() {
  local here
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  printf '%s\n' "$here"
}

pip_require_xcode() {
  export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
  if [[ ! -x "$DEVELOPER_DIR/usr/bin/xcodebuild" ]]; then
    echo "Xcode not found at $DEVELOPER_DIR" >&2
    echo "Install Xcode and run: xcode-select --switch /Applications/Xcode.app" >&2
    exit 1
  fi
  export PATH="$DEVELOPER_DIR/usr/bin:/usr/bin:/bin:$PATH"
}

pip_pull() {
  local root="$1"
  cd "$root"

  if [[ ! -d .git ]]; then
    echo "Not a git checkout: $root" >&2
    echo "First clone: git clone git@github.com:383766159/-Pip.git" >&2
    exit 1
  fi

  if [[ -n "$(git status --porcelain)" ]]; then
    echo "Cloud Mac working tree is dirty. Commit, stash, or reset before pulling." >&2
    git status --short >&2
    exit 1
  fi

  local branch
  branch="$(git rev-parse --abbrev-ref HEAD)"
  echo "Pulling origin/$branch ..."
  git fetch origin
  git pull --ff-only origin "$branch"
  git log -1 --oneline
}

pip_pick_udid() {
  if [[ -n "${PIP_SIM_UDID:-}" ]]; then
    printf '%s\n' "$PIP_SIM_UDID"
    return 0
  fi

  local list line udid want
  list="$(xcrun simctl list devices available)"
  want="${PIP_SIM_DEVICE:-}"

  if [[ -n "$want" ]]; then
    line="$(printf '%s\n' "$list" | grep -F "$want" | grep -v unavailable | tail -n 1 || true)"
  fi
  if [[ -z "${line:-}" ]]; then
    line="$(printf '%s\n' "$list" | grep -E 'iPhone 1[5-9]' | grep -v unavailable | tail -n 1 || true)"
  fi
  if [[ -z "${line:-}" ]]; then
    line="$(printf '%s\n' "$list" | grep iPhone | grep -v unavailable | tail -n 1 || true)"
  fi
  if [[ -z "${line:-}" ]]; then
    echo "No available iPhone simulator. Open Xcode → Settings → Platforms and install iOS." >&2
    xcrun simctl list devices available >&2 || true
    exit 1
  fi

  udid="$(printf '%s\n' "$line" | sed -n 's/.*(\([A-Fa-f0-9-]\{36\}\)).*/\1/p' | head -n 1)"
  if [[ -z "$udid" ]]; then
    echo "Could not parse simulator UDID from: $line" >&2
    exit 1
  fi
  echo "Using simulator: $line" >&2
  printf '%s\n' "$udid"
}

pip_boot_simulator() {
  local udid="$1"
  xcrun simctl boot "$udid" >/dev/null 2>&1 || true
  open -a Simulator >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$udid" -b
}

pip_app_path() {
  local root="$1"
  printf '%s\n' "$root/build/DerivedData/Build/Products/Debug-iphonesimulator/Pip.app"
}

pip_build_simulator() {
  local root="$1"
  local udid="$2"
  cd "$root"
  echo "Building Pip for simulator $udid ..."
  xcodebuild \
    -project Pip.xcodeproj \
    -scheme Pip \
    -configuration Debug \
    -destination "id=$udid" \
    -derivedDataPath "$root/build/DerivedData" \
    CODE_SIGNING_ALLOWED=YES \
    build
}

pip_install_and_launch() {
  local udid="$1"
  local app="$2"
  if [[ ! -d "$app" ]]; then
    echo "Built app missing: $app" >&2
    exit 1
  fi
  xcrun simctl install "$udid" "$app"
  xcrun simctl launch "$udid" com.pip.app
  echo "Launched com.pip.app on $udid"
}
