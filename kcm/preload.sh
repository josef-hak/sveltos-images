#!/usr/bin/env bash
# Load the built images straight into a k0s-in-docker cluster's containerd, so
# a local run needs no registry at all. The chart sets no imagePullPolicy and
# the tag is not `latest`, so IfNotPresent applies and a preloaded image is
# never fetched.
#
#   bash kcm/preload.sh k0rdent-<KCM> [component...]
set -euo pipefail

CONTAINER="${1:?usage: preload.sh <k0s container> [component...]}"
shift || true
source "$(dirname "$0")/../scripts/common.sh"

components "$@" | while IFS='|' read -r dir repo image; do
  ref="$REGISTRY/$image:$VERSION"
  printf '>> %s ' "$ref"
  docker save "$ref" \
    | docker exec -i "$CONTAINER" k0s ctr -n k8s.io images import --platform linux/amd64 - >/dev/null
  echo ok
done
