#!/usr/bin/env bash
#
# migrate-repos.sh - rewrite the origin remote across all git repos in a directory
#
# usage:
#   ./migrate-repos.sh [-n] [-d repos_dir] <old> <new>
#   ./migrate-repos.sh -n teaguejk jaracah          # dry run
#   ./migrate-repos.sh -d ~/work olduser newuser
#
# replaces every occurrence of <old> with <new> in each repo's origin URL.

set -euo pipefail

REPOS_DIR="${REPOS_DIR:-$HOME/repos}"
DRY_RUN=0

usage() {
    echo "usage: $(basename "$0") [-n] [-d repos_dir] <old> <new>" >&2
    echo "  -n    dry run, show what would change" >&2
    echo "  -d    directory containing repos (default: \$REPOS_DIR or ~/repos)" >&2
    exit 1
}

while getopts ":nd:h" opt; do
    case "$opt" in
        n) DRY_RUN=1 ;;
        d) REPOS_DIR="$OPTARG" ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))
[[ $# -eq 2 ]] || usage
OLD="$1" NEW="$2"

[[ -d "$REPOS_DIR" ]] || { echo "error: no such directory: $REPOS_DIR" >&2; exit 1; }

for d in "$REPOS_DIR"/*/; do
    url=$(git -C "$d" remote get-url origin 2>/dev/null) || continue
    [[ "$url" == *"$OLD"* ]] || continue
    new_url="${url//"$OLD"/$NEW}"
    if (( DRY_RUN )); then
        echo "would update $(basename "$d"): $url -> $new_url"
    else
        git -C "$d" remote set-url origin "$new_url"
        echo "updated $(basename "$d"): $url -> $new_url"
    fi
done
