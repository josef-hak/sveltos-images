#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"

components "$@" | while IFS='|' read -r dir repo image; do
  echo ">> pushing $REGISTRY/$image:$VERSION"
  docker push "$REGISTRY/$image:$VERSION"
done
