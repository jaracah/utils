#!/usr/bin/env bash
#
# set-file-associations.sh - associate programming-language file extensions
# with an app on macos, using github linguist's language database
#
# usage:
#   ./set-file-associations.sh [-n] [bundle_id]
#   ./set-file-associations.sh                      # default: vscode
#   ./set-file-associations.sh com.sublimetext.4
#   ./set-file-associations.sh -n                   # dry run, list extensions
#
# requires: duti, yq (brew install duti yq)

set -euo pipefail

LANGUAGES_URL="https://raw.githubusercontent.com/github/linguist/master/lib/linguist/languages.yml"
ROLE="${ROLE:-all}"
DRY_RUN=0

usage() {
    echo "usage: $(basename "$0") [-n] [bundle_id]" >&2
    echo "  -n    dry run, print extensions without setting anything" >&2
    exit 1
}

while getopts ":nh" opt; do
    case "$opt" in
        n) DRY_RUN=1 ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))
BUNDLE_ID="${1:-${BUNDLE_ID:-com.microsoft.VSCode}}"

[[ "$(uname)" == "Darwin" ]] || { echo "error: this script is for macos" >&2; exit 1; }
for cmd in duti yq; do
    command -v "$cmd" >/dev/null || { echo "error: $cmd not installed (brew install $cmd)" >&2; exit 1; }
done

extensions=$(curl -fsSL "$LANGUAGES_URL" \
    | yq -r 'to_entries | (map(.value.extensions) | flatten) - [null] | unique | .[]')

if (( DRY_RUN )); then
    echo "$extensions"
    echo "would associate $(echo "$extensions" | wc -l | tr -d ' ') extensions with $BUNDLE_ID (role: $ROLE)" >&2
    exit 0
fi

count=0
while IFS= read -r ext; do
    if duti -s "$BUNDLE_ID" "$ext" "$ROLE" 2>/dev/null; then
        count=$((count + 1))
    else
        echo "skipped $ext" >&2
    fi
done <<< "$extensions"
echo "associated $count extensions with $BUNDLE_ID"
