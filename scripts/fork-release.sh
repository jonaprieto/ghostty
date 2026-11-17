#!/usr/bin/env bash
# Publishes the tagged commit as a GitHub release and points Casks/ghostty.rb at it. homebrew-tap copies that cask, so
# this also asks it to sync. Tag the commit first, as fork-<version>, which keeps it apart from upstream's v<version>.
#
# Ad-hoc signed on purpose: a public build must not carry the personal identity fork-install.sh signs with.
#
#   scripts/fork-release.sh 1.4.1-1
set -euo pipefail
cd "$(dirname "$0")/.."

version="${1:?Usage: $0 <version>}"
tag="fork-$version"
repo=jonaprieto/ghostty
if [[ -n "$(git status --porcelain)" ]]; then echo "Commit your changes first." >&2; exit 1; fi
if [[ "$(git branch --show-current)" != fork ]]; then echo "Run this from the fork branch." >&2; exit 1; fi
if [[ "$(git rev-parse HEAD)" != "$(git rev-parse "$tag^{commit}")" ]]; then echo "$tag must point at HEAD." >&2; exit 1; fi

# An explicit version: the build refuses tags other than vX.Y.Z on HEAD, and it stamps the app.
zig build -Doptimize=ReleaseFast -Dversion-string="$version"

# fork-install.sh re-signs the build in place, so sign a copy ad hoc.
out=macos/build/release
rm -rf "$out"
mkdir -p "$out"
app="$out/Ghostty.app"
ditto macos/build/ReleaseLocal/Ghostty.app "$app"
codesign --force --deep --preserve-metadata=entitlements --sign - "$app"
codesign --verify --deep --strict "$app"
signature=$(codesign -dvv "$app" 2>&1)
if [[ "$signature" != *$'\nSignature=adhoc\n'* ]]; then
  echo "Refusing to publish a build that isn't ad-hoc signed." >&2; exit 1
fi
zip="$out/Ghostty-$version.zip"
ditto -c -k --keepParent "$app" "$zip"
sha=$(shasum -a 256 "$zip" | cut -d' ' -f1)

git push origin HEAD "$tag"
# gh won't read tag notes together with -R, and -R keeps this from ever reaching upstream.
gh release create "$tag" "$zip" -R "$repo" --title "Ghostty fork $version" --verify-tag \
  --notes "$(git tag -l --format='%(contents:body)' "$tag")"

perl -pi -e "s/^  version .*/  version \"$version\"/; s/^  sha256 .*/  sha256 \"$sha\"/" Casks/ghostty.rb
git commit -q -m "Fork: point the cask at release $version" Casks/ghostty.rb
git push origin HEAD
gh workflow run sync.yml -R jonaprieto/homebrew-tap
