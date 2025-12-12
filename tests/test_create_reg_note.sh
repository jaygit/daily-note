#!/usr/bin/env bash
set -euo pipefail

# Test the create_reg_note.sh script in a temporary vault.
# This test will:
# - create a temp vault with a scripts/ copy
# - create an existing note to backlink to
# - run create_reg_note.sh non-interactively (using TEST_CONTENT_FILE and SELECTED_NOTES)
# - assert that the new note exists, project index updated, and backlinks inserted

ROOT=$(pwd)
TMP=$(mktemp -d)
cleanup() {
  rm -rf "$TMP"
}
trap cleanup EXIT

echo "Running tests in $TMP"

# Copy scripts into temp vault
mkdir -p "$TMP/scripts"
cp -a "$ROOT/scripts"/* "$TMP/scripts/"

# Ensure Zettelkasten exists and create an existing note
mkdir -p "$TMP/Zettelkasten"
EXISTING="NOTE - Existing.md"
cat > "$TMP/Zettelkasten/$EXISTING" <<'EOF'
---
title: Existing
created: 2025-12-05 12:00:00
---

# Existing

Some content
EOF

# Prepare test content for the new note
TEST_CONTENT_FILE="$TMP/new_note_content.md"
cat > "$TEST_CONTENT_FILE" <<'EOF'
---
title: Test Note
created: 2025-12-05 12:01:00
tags: []
---

# Test Note

This is a test note created by the harness.
EOF

# Run create_reg_note.sh non-interactively
export TEST_CONTENT_FILE
export PROJECT_NAME="Demo Project"
# SELECTED_NOTES expects filenames (as produced by find -printf '%f\n')
export SELECTED_NOTES="$EXISTING"

# Execute the script from within the temp vault so lib.sh computes VAULT_DIR correctly
pushd "$TMP" >/dev/null
bash "scripts/create_reg_note.sh" -t "Test Note"
popd >/dev/null

# Assertions
NEW_NOTE="Zettelkasten/NOTE - Test_Note.md"
if [ ! -f "$TMP/$NEW_NOTE" ]; then
  echo "FAIL: New note not created: $NEW_NOTE"
  exit 2
fi

# Check project index
INDEX="Zettelkasten/Project - Demo Project.md"
if [ ! -f "$TMP/$INDEX" ]; then
  echo "FAIL: Project index not created: $INDEX"
  exit 2
fi
if ! grep -F "[[NOTE - Test_Note]]" "$TMP/$INDEX" >/dev/null 2>&1; then
  echo "FAIL: Project index does not contain link to new note"
  exit 2
fi

# Check backlink inserted into existing note under ## Backlinks
if ! grep -q "## Backlinks" "$TMP/Zettelkasten/$EXISTING"; then
  echo "FAIL: Existing note missing '## Backlinks' header"
  exit 2
fi
if ! grep -F "[[NOTE - Test_Note]]" "$TMP/Zettelkasten/$EXISTING" >/dev/null 2>&1; then
  echo "FAIL: Existing note missing backlink to new note"
  exit 2
fi

# Check frontmatter project field in new note
if ! grep -q "project: \"Demo Project\"" "$TMP/$NEW_NOTE"; then
  echo "FAIL: New note missing project frontmatter"
  exit 2
fi

# Success
echo "All tests passed."

exit 0
