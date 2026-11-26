#!/usr/bin/env bash
# Push built images. GHCR wants a classic PAT with write:packages -- a
# fine-grained one is refused with "the token provided does not match expected
# scopes" -- so the token is read from its own file rather than from gh auth.
source "$(dirname "$0")/common.sh"

TOKEN_FILE="${GHCR_TOKEN_FILE:-$HOME/.config/ghcr-token}"
if [ -f "$TOKEN_FILE" ]; then
  tr -d '\n' < "$TOKEN_FILE" | docker login ghcr.io -u "${GHCR_USER:-josef-hak}" --password-stdin
fi

components "$@" | while IFS='|' read -r dir repo image; do
  echo ">> pushing $REGISTRY/$image:$VERSION"
  docker push "$REGISTRY/$image:$VERSION"
done
