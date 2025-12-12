#!/usr/bin/env bash

# Minimal bootstrap: locate `lib.sh` and source it
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib.sh"

if [ -z "$1" ]; then
  echo "Usage: vault-search <query>"
  exit 1
fi

QUERY="$1"

rg --files-with-matches "$QUERY" "$VAULT_DIR" | \
fzf --preview "rg -n --color=always -C 3 \"$QUERY\" {} | batcat --style=plain --language=markdown"

