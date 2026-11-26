#!/usr/bin/env bash
# Report which registry every projectsveltos workload in a cluster is running
# from, so a KCM install can be checked against the overlay in this directory.
#
#   KUBECONFIG=... bash kcm/verify.sh [namespace]
#
# Exits non-zero if a pod is not Running. sveltos-agent and
# drift-detection-manager are expected on docker.io -- nothing here builds them.
set -euo pipefail

NS="${1:-projectsveltos}"
REGISTRY="${REGISTRY:-ghcr.io/josef-hak}"

printf '%-42s %-12s %s\n' POD STATUS IMAGE
rc=0
while read -r name phase images; do
    printf '%-42s %-12s %s\n' "$name" "$phase" "$images"
    [ "$phase" = Running ] || [ "$phase" = Succeeded ] || rc=1
done < <(kubectl get pods -n "$NS" \
    -o 'custom-columns=:.metadata.name,:.status.phase,:.spec.containers[*].image' \
    --no-headers)

echo
echo "from $REGISTRY: $(kubectl get pods -n "$NS" -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n' | grep -c "^$REGISTRY/" || true)"
echo "from elsewhere: $(kubectl get pods -n "$NS" -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n' | grep -vc "^$REGISTRY/" || true)"
exit $rc
