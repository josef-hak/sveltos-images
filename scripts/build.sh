#!/usr/bin/env bash
# Build one or all images straight from the vendored sources. Upstream's
# `make docker-build` also runs `go generate` and rewrites its own manifests,
# neither of which an image build needs, so we call docker directly.
source "$(dirname "$0")/common.sh"

ARCH="${ARCH:-amd64}"

# -ldflags for the one Dockerfile that takes them (sveltosctl's, for its
# `version` command). Upstream builds its own published image with the
# buildx target, which passes no LDFLAGS at all, so that image reports an
# empty version; the values here come from src/<dir>/SOURCE rather than from
# a .git we do not vendor.
ldflags() {
  local dir="$1" src="$ROOT/src/$1" mod key
  grep -q 'ARG LDFLAGS' "$src/Dockerfile" || return 0
  mod="$(awk '/^module /{print $2; exit}' "$src/go.mod")"
  key="$mod/internal/commands"
  local commit ver="$VERSION"
  commit="$(awk '/^commit:/{print $2}' "$src/SOURCE")"
  echo "-X '$key.gitCommit=$commit' -X '$key.gitTreeState=clean'" \
       "-X '$key.gitVersion=$ver'" \
       "-X '$key.gitMajor=$(echo "$ver" | sed 's/^v\([0-9]*\).*/\1/')'" \
       "-X '$key.gitMinor=$(echo "$ver" | sed 's/^v[0-9]*\.\([0-9]*\).*/\1/')'" \
       "-X '$key.gitReleaseCommit=$commit'" \
       "-X '$key.buildDate=$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
}

components "$@" | while IFS='|' read -r dir repo image; do
  [ -f "$ROOT/src/$dir/Dockerfile" ] || { echo "!! $dir not vendored"; exit 1; }
  echo ">> building $REGISTRY/$image:$VERSION"
  docker build --load \
    --build-arg BUILDOS=linux \
    --build-arg TARGETARCH="$ARCH" \
    --build-arg GIT_VERSION="$VERSION" \
    --build-arg GIT_COMMIT="$(awk '/^commit:/{print $2}' "$ROOT/src/$dir/SOURCE")" \
    --build-arg LDFLAGS="$(ldflags "$dir")" \
    -t "$REGISTRY/$image:$VERSION" \
    "$ROOT/src/$dir"
done
