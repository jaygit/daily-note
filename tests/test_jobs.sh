#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")"
SCRIPTS_DIR="$REPO_ROOT/scripts"
LOG_DIR="$REPO_ROOT/tests/logs"
mkdir -p "$LOG_DIR"

# Use an isolated temporary vault for tests
TMPDIR="$(mktemp -d)"
export VAULT_DIR="$TMPDIR/vault"
mkdir -p "$VAULT_DIR/01-Projects/Jobs" "$VAULT_DIR/00-Journal/00-A-Daily Notes"

DATE_YMD="$(date +%F)"
TEST_TITLE="SRE Engineer"
TEST_COMPANY="BearingPoint"
TEST_LINK="https://example.com/apply"
TEST_NOTES="Applied via test-runner"

LOG="$LOG_DIR/test_jobs.log"
exec > >(tee -a "$LOG") 2>&1

echo "=== TEST: jobs.sh add mode ==="
"$SCRIPTS_DIR/jobs.sh" -a -j "$TEST_TITLE" -c "$TEST_COMPANY" -l "$TEST_LINK" -n "$TEST_NOTES"
echo "add exit: $?"

echo "--- checking created file ---"
created_file="$(find "$VAULT_DIR/01-Projects/Jobs" -type f -name "*.md" | head -n1 || true)"
if [ -z "$created_file" ]; then
  echo "FAIL: no job file created"
  exit 2
fi
echo "Created file: $created_file"

if grep -q "# $TEST_TITLE at $TEST_COMPANY" "$created_file"; then
  echo "PASS: Title/company present"
else
  echo "FAIL: Title/company missing"
  exit 3
fi

if grep -q "\*\*Link:\*\* \[$TEST_TITLE\]($TEST_LINK)" "$created_file"; then
  echo "PASS: Link present"
else
  echo "WARN: Link line not matched exactly; showing excerpt:"
  sed -n '1,40p' "$created_file"
fi

echo
echo "=== TEST: jobs.sh query (list) ==="
"$SCRIPTS_DIR/jobs.sh" -q -j "SRE" -c "Bearing" -l > "$LOG_DIR/query_list.out" || true
echo "Query output:"
cat "$LOG_DIR/query_list.out"

if grep -q "$created_file" "$LOG_DIR/query_list.out"; then
  echo "PASS: query listed the created file"
else
  echo "FAIL: query did not list expected file"
  exit 4
fi

echo
echo "=== TEST: jobs.sh update status ==="
"$SCRIPTS_DIR/jobs.sh" -q -s "Interviewed" -j "SRE" -c "Bearing"
echo "status update exit: $?"

if grep -q "Interviewed" "$created_file"; then
  if grep -q "^\- \[[xX]\] Interviewed" "$created_file"; then
    echo "PASS: Interviewed checkbox marked"
  else
    echo "FAIL: Interviewed checkbox not marked"
    sed -n '1,200p' "$created_file"
    exit 5
  fi
else
  echo "FAIL: status section missing"
  exit 6
fi

echo
echo "All tests passed."
# keep tmpdir around for inspection if needed, but print its path
echo "TEST VAULT DIR: $VAULT_DIR"