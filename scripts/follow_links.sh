#!/usr/bin/env bash
# Thin wrapper: source library and call the `follow_links` function.
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib.sh"

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <note-file>" >&2
  exit 2
fi

follow_links "$1"
