# Shared by the other scripts. Source it, do not run it.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${VERSION:-$(cat "$ROOT/VERSION")}"
REGISTRY="${REGISTRY:-ghcr.io/josef-hak/projectsveltos}"

# components [name...] -> prints "dir|repo|image" lines, all of them when no
# name is given.
components() {
  local filter=" $* "
  while IFS='|' read -r dir repo image; do
    case "$dir" in ''|'#'*) continue ;; esac
    if [ $# -eq 0 ] || [[ "$filter" == *" $dir "* ]]; then
      echo "$dir|$repo|$image"
    fi
  done < "$ROOT/components.env"
}
