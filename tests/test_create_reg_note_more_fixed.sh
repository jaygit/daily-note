#!/usr/bin/env bash
set -euo pipefail

# Additional tests for create_reg_note.sh (fixed copy)

ROOT=$(pwd)
TMP=$(mktemp -d)
cleanup() { rm -rf "$TMP" }
trap cleanup EXIT

echo "Running extra tests in $TMP"
mkdir -p "$TMP/scripts"
cp -a "$ROOT/scripts"/* "$TMP/scripts/"
mkdir -p "$TMP/Zettelkasten"

# Create two existing notes
cat > "$TMP/Zettelkasten/NOTE - A.md" <<'EOF'
---
title: A
created: 2025-12-05 12:00:00
---

# A
EOF
cat > "$TMP/Zettelkasten/NOTE - B.md" <<'EOF'
---
title: B
created: 2025-12-05 12:00:00
---

# B
EOF

# Test 1: create new note selecting both existing notes, with no project
TEST_CONTENT_FILE="$TMP/new_note2.md"
cat > "$TEST_CONTENT_FILE" <<'EOF'
---
title: Test2
created: 2025-12-05 12:02:00
---

# Test2

Content
EOF

export TEST_CONTENT_FILE
export SELECTED_NOTES="$(printf '%s\n' 'NOTE - A.md' 'NOTE - B.md')"

pushd "$TMP" >/dev/null
bash "scripts/create_reg_note.sh" -t "Test2"
popd >/dev/null

NEW_NOTE="Zettelkasten/NOTE - Test2.md"
if [ ! -f "$TMP/$NEW_NOTE" ]; then echo "FAIL: New note missing"; exit 2; fi
# Ensure project not added
if grep -q "project:" "$TMP/$NEW_NOTE"; then echo "FAIL: project present unexpectedly"; exit 2; fi
# Ensure both existing notes have backlinks
for f in "NOTE - A.md" "NOTE - B.md"; do
  if ! grep -q "## Backlinks" "$TMP/Zettelkasten/$f"; then echo "FAIL: $f missing Backlinks"; exit 2; fi
  if ! grep -F "[[NOTE - Test2]]" "$TMP/Zettelkasten/$f" >/dev/null 2>&1; then echo "FAIL: $f missing backlink"; exit 2; fi
done

# Test 2: create a note with a project and ensure tags merged
TEST_CONTENT_FILE="$TMP/new_note3.md"
cat > "$TEST_CONTENT_FILE" <<'EOF'
---
title: Test3
created: 2025-12-05 12:03:00
---

# Test3
EOF
export TEST_CONTENT_FILE
export PROJECT_NAME="ProjX"
export SELECTED_NOTES=""
pushd "$TMP" >/dev/null
bash "scripts/create_reg_note.sh" -t "Test3"
popd >/dev/null

NEW_NOTE2="Zettelkasten/NOTE - Test3.md"
if ! grep -q 'project: "ProjX"' "$TMP/$NEW_NOTE2"; then echo "FAIL: project missing in Test3"; exit 2; fi
if ! grep -q 'tags:' "$TMP/$NEW_NOTE2"; then echo "FAIL: tags missing in Test3"; exit 2; fi

# Success
echo "Extra tests (fixed) passed."
exit 0
