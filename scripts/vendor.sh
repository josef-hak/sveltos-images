#!/usr/bin/env bash
# Vendor upstream sources into src/<dir> at the tag in VERSION.
# The working tree is copied without .git so this repo stays the only history
# and a build never needs the upstream to still be there.
source "$(dirname "$0")/common.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

components "$@" | while IFS='|' read -r dir repo image; do
  echo ">> $dir @ $VERSION"
  git clone -q --depth 1 --branch "$VERSION" "$repo" "$tmp/$dir"
  sha="$(git -C "$tmp/$dir" rev-parse HEAD)"
  rm -rf "$tmp/$dir/.git"
  # Upstream docs are screenshots, not a build input: addon-controller's doc/
  # alone is 19M and would land in the repo again on every version bump.
  rm -rf "$tmp/$dir/doc"
  rm -rf "${ROOT:?}/src/$dir"
  mkdir -p "$ROOT/src"
  mv "$tmp/$dir" "$ROOT/src/$dir"
  cat > "$ROOT/src/$dir/SOURCE" <<EOM
upstream: $repo
tag: $VERSION
commit: $sha
vendored: $(date -u +%Y-%m-%dT%H:%M:%SZ)
pruned: .git doc/
EOM
  echo "   $sha"
done
