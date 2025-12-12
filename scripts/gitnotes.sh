
#!/bin/bash
# Minimal bootstrap: locate `lib.sh` and source it
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib.sh"

# Helper function to show usage
usage() {
  echo "Usage: $0 <command>"
  echo "   commit        commit notes"
  echo "   pull          pull notes"
}
if [ $# -lt 1 ]; then
  usage
  exit 1
fi

COMMAND=$1
shift

case "$COMMAND" in 
  commit)
    cd $VAULT_DIR || { echo "Vault directory not found!"; exit 1; }
    node=`uname -n`
    timestamp=$(date +"%Y%m%d%H%M")
    git add .
    git commit -m "$node-$timestamp"
    git push
    ;;
  pull)
    cd $VAULT_DIR || { echo "Vault directory not found!"; exit 1; }
    git pull
    ;;
  *)
    echo "Unknown command: $COMMAND"
    usage
    ;;
esac
