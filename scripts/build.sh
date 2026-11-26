#!/usr/bin/env bash
# Build one or all images straight from the vendored sources. Upstream's
# `make docker-build` also runs `go generate` and rewrites its own manifests,
# neither of which an image build needs, so we call docker directly.
source "$(dirname "$0")/common.sh"

ARCH="${ARCH:-amd64}"

components "$@" | while IFS='|' read -r dir repo image; do
  [ -f "$ROOT/src/$dir/Dockerfile" ] || { echo "!! $dir not vendored"; exit 1; }
  echo ">> building $REGISTRY/$image:$VERSION"
  docker build --load \
    --build-arg BUILDOS=linux \
    --build-arg TARGETARCH="$ARCH" \
    --build-arg GIT_VERSION="$VERSION" \
    -t "$REGISTRY/$image:$VERSION" \
    "$ROOT/src/$dir"
done
