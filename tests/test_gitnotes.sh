#!/usr/bin/env bash
set -euo pipefail

# Test gitnotes.sh commit & push flow using a local bare repo as 'gitea' remote

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
LOG="$LOG_DIR/test_gitnotes.log"
exec > >(tee -a "$LOG") 2>&1

echo "Running gitnotes test"

# Prepare a bare remote repo to act as 'gitea'
REMOTE_BARE="$TMPDIR/remote.git"
git init --bare "$REMOTE_BARE" >/dev/null

# Prepare local repo with vault inside
LOCAL_REPO="$TMPDIR/local"
mkdir -p "$LOCAL_REPO"
git init -b main "$LOCAL_REPO" >/dev/null
git -C "$LOCAL_REPO" config user.name "Test User"
git -C "$LOCAL_REPO" config user.email "test@example.com"

VAULT_DIR_LOCAL="$LOCAL_REPO/vault"
mkdir -p "$VAULT_DIR_LOCAL"
echo "initial note" > "$VAULT_DIR_LOCAL/note1.md"
git -C "$LOCAL_REPO" add "$VAULT_DIR_LOCAL"
git -C "$LOCAL_REPO" commit -m "init vault" >/dev/null

# add bare remote and push initial commit
git -C "$LOCAL_REPO" remote add gitea "$REMOTE_BARE"
git -C "$LOCAL_REPO" push -u gitea main >/dev/null

# make a local change (new file) under vault
echo "new content" > "$VAULT_DIR_LOCAL/new-note.md"

# Run gitnotes.sh commit with VAULT_DIR pointing to the local vault
VAULT_DIR="$VAULT_DIR_LOCAL" bash "$SCRIPTS_DIR/gitnotes.sh" commit || {
  echo "FAIL: gitnotes.sh commit failed";
  git -C "$LOCAL_REPO" status --porcelain || true;
  exit 2;
}

# Verify local HEAD equals remote HEAD
local_head=$(git -C "$LOCAL_REPO" rev-parse main)
remote_head=$(git --git-dir="$REMOTE_BARE" rev-parse refs/heads/main)
if [ "$local_head" != "$remote_head" ]; then
  echo "FAIL: remote head does not match local head";
  echo "local: $local_head";
  echo "remote: $remote_head";
  exit 3
fi

# Verify commit message contains our Vault update marker
if git -C "$LOCAL_REPO" log -1 --pretty=%B | grep -q "Vault update from"; then
  echo "PASS: commit message contains Vault update marker"
else
  echo "FAIL: commit message missing Vault update marker"
  git -C "$LOCAL_REPO" log -1 --pretty=%B
  exit 4
fi

echo "gitnotes test completed successfully"
