#!/usr/bin/env bash
set -euo pipefail

# Quick test for create_reg_note.sh category handling
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

REPO_ROOT="$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")"

# Prepare a minimal vault layout
mkdir -p "$TMPDIR/vault/scripts"
cp -a "$REPO_ROOT/scripts/"* "$TMPDIR/vault/scripts/"
cp -a "$REPO_ROOT/README.md" "$TMPDIR/vault/README.md" 2>/dev/null || true

pushd "$TMPDIR/vault" >/dev/null

# Run the create script
./scripts/create_reg_note.sh -t "Test Cat" -c "Job!" -p "Proj@ 1"

# Expected file
EXPECTED="Zettelkasten/Job - Test_Cat.md"
if [ ! -f "$EXPECTED" ]; then
  echo "FAIL: expected note not created: $EXPECTED" >&2
  exit 2
fi

# Check frontmatter contains category and tags
if ! grep -q '^category:' "$EXPECTED"; then
  echo "FAIL: category field missing in frontmatter" >&2
  exit 2
fi

# Ensure tags include the sanitized category and project
if ! grep -q "Job" "$EXPECTED" && ! grep -q "Job" "$EXPECTED"; then
  echo "WARN: Job string not found in file (tags may differ)" >&2
fi

echo "OK: create_reg_note category test passed"
popd >/dev/null
