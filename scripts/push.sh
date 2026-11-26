#!/usr/bin/env bash
# Push built images. Only CI publishes: it is logged in to GHCR by
# docker/login-action with the job's own token, which is the one credential
# that carries packages:write for this namespace.
source "$(dirname "$0")/common.sh"

components "$@" | while IFS='|' read -r dir repo image; do
  echo ">> pushing $REGISTRY/$image:$VERSION"
  docker push "$REGISTRY/$image:$VERSION"
done
