#!/bin/bash
# Minimal bootstrap: locate `lib.sh` and source it
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib.sh"

node=`uname -n`
timestamp=$(date +"%Y%m%d%H%M")
git add .
git commit -m "$node-$timestamp"
git push
