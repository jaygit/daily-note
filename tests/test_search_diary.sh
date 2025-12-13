#!/usr/bin/env bash
set -euo pipefail

# Test non-interactive diary search using a stubbed fzf command
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"; test_lib_cleanup 2>/dev/null || true' EXIT

REPO_ROOT="$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")"
# shellcheck source=/dev/null
source "$REPO_ROOT/tests/test_lib.sh"
test_lib_setup "$TMPDIR"

LOG_DIR="$REPO_ROOT/tests/logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/test_search_diary.log"
exec > >(tee -a "$LOG") 2>&1

# Prepare vault
VAULT="$TMPDIR/vault"
mkdir -p "$VAULT/00-Journal/00-A-Daily Notes"
DATE=$(date +%F)
NOTE_REL="00-Journal/00-A-Daily Notes/${DATE}.md"
NOTE_PATH="$VAULT/$NOTE_REL"
echo "# Diary $DATE" > "$NOTE_PATH"

# Create a stub fzf that prints the first item from stdin
FZF_STUB="$TMPDIR/fzf_stub"
cat > "$FZF_STUB" <<'FZFSH'
#!/usr/bin/env bash
# read stdin and print first non-empty line
awk 'NF{print; exit}'
FZFSH
chmod +x "$FZF_STUB"

export FZF_CMD="$FZF_STUB"
export VAULT_DIR="$VAULT"

# Run diary search non-interactively for today
out=$(bash "$REPO_ROOT/scripts/search.sh" diary today)

if [ "$out" = "$NOTE_REL" ]; then
  echo "PASS: diary search returned expected note: $out"
  exit 0
else
  echo "FAIL: unexpected search output: '$out' (expected '$NOTE_REL')"
  exit 2
fi
