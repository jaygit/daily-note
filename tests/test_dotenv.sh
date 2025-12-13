#!/usr/bin/env bash
set -euo pipefail

# Test that scripts/lib.sh loads a .env file from the current working
# directory and exports variables defined within it.

TMPDIR="$(mktemp -d)"
trap 'test_lib_cleanup 2>/dev/null || true; rm -rf "$TMPDIR"' EXIT

REPO_ROOT="$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")"
SCRIPTS_DIR="$REPO_ROOT/scripts"

# Load test helpers (creates gum shim and sets NO_LINKS)
# shellcheck source=/dev/null
source "$REPO_ROOT/tests/test_lib.sh"
test_lib_setup "$TMPDIR"

LOG_DIR="$REPO_ROOT/tests/logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/test_dotenv.log"
exec > >(tee -a "$LOG") 2>&1

echo "Running dotenv loader test"

# create a .env in the temporary working dir
cat > "$TMPDIR/.env" <<'ENV'
TEST_DOTENV_VAR="from-dotenv"
ENV

# Run a subshell that cds into TMPDIR (so $PWD/.env is found), sources lib.sh,
# and verifies the variable is exported into the environment.
(
  cd "$TMPDIR"
  if bash -c '. "'$SCRIPTS_DIR'/lib.sh"; env | grep -q "^TEST_DOTENV_VAR=from-dotenv$"'; then
    echo "PASS: TEST_DOTENV_VAR exported from .env"
    exit 0
  else
    echo "FAIL: TEST_DOTENV_VAR not exported"
    env | grep TEST_DOTENV_VAR || true
    exit 2
  fi
)

echo "Dotenv loader test completed"
