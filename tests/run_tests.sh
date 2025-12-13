#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")"
LOG_DIR="$ROOT_DIR/tests/logs"
mkdir -p "$LOG_DIR"

# Prepare test helpers (gum shim, NO_LINKS) so CI runs non-interactively
# shellcheck source=/dev/null
if [ -f "$ROOT_DIR/tests/test_lib.sh" ]; then
  source "$ROOT_DIR/tests/test_lib.sh"
  test_lib_setup "$ROOT_DIR/tests/.test_tmp"
fi

echo "Starting test runner. Logs: $LOG_DIR"

failed=0

run_test() {
  local script="$1"
  local name="$(basename "$script" .sh)"
  local out="$LOG_DIR/${name}.log"

  if [ ! -f "$script" ]; then
    echo "Skipping $name: $script not found" | tee -a "$out"
    return 0
  fi

  echo "=== Running $name ===" | tee "$out"
  if bash "$script" >>"$out" 2>&1; then
    echo "=== $name PASSED ===" | tee -a "$out"
    return 0
  else
    echo "=== $name FAILED (see $out) ===" | tee -a "$out"
    failed=1
    return 1
  fi
}

# Run tests located in $ROOT_DIR/tests
run_test "$ROOT_DIR/tests/test_jobs.sh"
run_test "$ROOT_DIR/tests/test_create_note.sh"
run_test "$ROOT_DIR/tests/test_dotenv.sh"

# cleanup test helpers
if declare -f test_lib_cleanup >/dev/null 2>&1; then
  test_lib_cleanup || true
fi

echo
if [ "$failed" -ne 0 ]; then
  echo "One or more tests failed. Check logs in: $LOG_DIR"
else
  echo "All tests passed. Logs in: $LOG_DIR"
fi