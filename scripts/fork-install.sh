#!/usr/bin/env bash
# Build Ghostty from this checkout and install it to /Applications.
#
#   scripts/fork-install.sh             build ReleaseFast, sign, install
#   scripts/fork-install.sh --no-build  sign and install the last build
#
# The build is re-signed with the Apple Development identity so the
# designated requirement stays stable across rebuilds and privacy grants
# (Accessibility for the global quick-terminal hotkey) survive reinstalls.
set -euo pipefail
cd "$(dirname "$0")/.."

# Select by hash: a revoked identity in the keychain shares the same name, and
# find-identity -v still lists it, with a CSSMERR note.
IDENTITY="${GHOSTTY_SIGNING_IDENTITY:-$(security find-identity -v -p codesigning |
  awk '/Apple Development/ && !/CSSMERR/ { print $2; exit }')}"
if [[ -z "$IDENTITY" ]]; then
  echo "No valid Apple Development signing identity found." >&2
  exit 1
fi
BUILT=macos/build/ReleaseLocal/Ghostty.app
DEST=/Applications/Ghostty.app

if [[ "${1:-}" != --no-build ]]; then
  zig build -Doptimize=ReleaseFast
fi

codesign --force --deep --preserve-metadata=entitlements \
  --sign "$IDENTITY" "$BUILT"
codesign --verify --deep --strict "$BUILT"

if pgrep -xq ghostty; then
  echo "note: Ghostty is running; restart it to use the new build (tmux sessions survive)."
fi

rm -rf "$DEST"
ditto "$BUILT" "$DEST"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$DEST"

echo "installed $(git rev-parse --short HEAD) ($(git branch --show-current)) to $DEST"
