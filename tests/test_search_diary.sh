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

# If ripgrep (`rg`) is not available in the test container, provide a minimal
# shim that maps common `rg` calls used by the scripts to `grep`. This keeps
# tests runnable in lightweight containers.
if ! command -v rg >/dev/null 2>&1; then
  RG_SHIM_DIR="$TMPDIR/bin"
  mkdir -p "$RG_SHIM_DIR"
  cat > "$RG_SHIM_DIR/rg" <<'RGSH'
#!/usr/bin/env bash
# Minimal rg shim: handle --files-with-matches, --hidden, --glob '!.git', -n
mode="normal"
args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --files-with-matches)
      mode="files"
      shift
      ;;
    --hidden)
      shift
      ;;
    --glob)
      # skip the glob pattern argument
      shift; shift || true
      ;;
    --line-number|-n)
      args+=("-n"); shift ;;
    --)
      shift; break ;;
    *)
      args+=("$1"); shift ;;
  esac
done
# Remaining args: pattern [files...]
pattern="$1"; shift || true
if [ "$mode" = "files" ]; then
  dir="${1:-.}"
  # Use grep -R -l excluding .git
  grep -R -l --exclude-dir=.git -- "$pattern" "$dir" || true
else
  # Generic grep fallback
  grep "${args[@]}" -- "$pattern" "$@" || true
fi
RGSH
  chmod +x "$RG_SHIM_DIR/rg"
  export PATH="$RG_SHIM_DIR:$PATH"
fi

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
