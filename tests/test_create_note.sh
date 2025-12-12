#!/usr/bin/env bash
set -euo pipefail

# Test create_note.sh for categories: note, training, journal, command
TMPDIR="$(mktemp -d)"
# ensure tmpdir cleaned up and any test lib artifacts removed
trap 'test_lib_cleanup 2>/dev/null || true; rm -rf "$TMPDIR"' EXIT

REPO_ROOT="$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")"
SCRIPTS_DIR="$REPO_ROOT/scripts"
TEST_VAULT="$TMPDIR/vault"
mkdir -p "$TEST_VAULT"

# Load test helpers (creates gum shim and sets NO_LINKS)
# shellcheck source=/dev/null
source "$REPO_ROOT/tests/test_lib.sh"
test_lib_setup "$TMPDIR"

LOG_DIR="$REPO_ROOT/tests/logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/test_create_note.log"
exec > >(tee -a "$LOG") 2>&1

echo "Running create_note tests in vault: $TEST_VAULT"

run_one() {
  local title="$1"
  local category="$2"
  shift 2
  echo
  echo "=== Test: create_note - title='$title' category='$category' ==="
  "$SCRIPTS_DIR/create_note.sh" -t "$title" -c "$category" -v "$TEST_VAULT" -n "$@" || {
    echo "ERROR: create_note.sh failed for $title ($category)"
    return 1
  }

  # find any markdown file under vault that contains the title (safe with NUL -> newline)
  mapfile -t found_files < <(grep -R -lZ --exclude-dir=.git -e "$title" "$TEST_VAULT" 2>/dev/null | tr '\0' '\n')
  if [ "${#found_files[@]}" -eq 0 ]; then
    echo "FAIL: created file for '$title' not found"
    return 2
  fi
  echo "Created file(s) containing title:"
  for f in "${found_files[@]}"; do
    echo "$f"
  done
  # prefer a matched file that is not the daily note (avoid /00-Journal/), otherwise use first match
  found=""
  for f in "${found_files[@]}"; do
    if [[ "$f" != */00-Journal/* ]]; then
      found="$f"
      break
    fi
  done
  if [ -z "$found" ]; then
    found="${found_files[0]}"
  fi

  # For training/journal/command check type frontmatter
  if [ "$category" = "training" ]; then
    if grep -q "^type:[[:space:]]*training" "$found"; then
      echo "PASS: type: training present"
    else
      echo "FAIL: type: training missing in $found"
      return 3
    fi
  elif [ "$category" = "journal" ]; then
    if grep -q "^type:[[:space:]]*journal" "$found"; then
      echo "PASS: type: journal present"
    else
      echo "FAIL: type: journal missing in $found"
      return 4
    fi
  elif [ "$category" = "command" ]; then
    if grep -q "^type:[[:space:]]*command" "$found"; then
      echo "PASS: type: command present"
    else
      echo "FAIL: type: command missing in $found"
      return 5
    fi
    if grep -q "^command-name:" "$found"; then
      echo "PASS: command-name present"
    else
      echo "FAIL: command-name missing in $found"
      return 6
    fi
  else
    # note category generates explicit note frontmatter; check for type/tags/status
    if [ "$category" = "note" ]; then
      if grep -q "^type:[[:space:]]*note" "$found"; then
        echo "PASS: type: note present"
      else
        echo "FAIL: type: note missing in $found"
        return 7
      fi
      if grep -q "^tags:.*zettelkasten" "$found"; then
        echo "PASS: tags include zettelkasten"
      else
        echo "FAIL: tags do not include zettelkasten in $found"
        return 8
      fi
      if grep -q "^status:.*draft" "$found"; then
        echo "PASS: status: draft present"
      else
        echo "WARN: status draft not found; showing file head:"
        head -n 40 "$found" || true
      fi
    elif [ "$category" = "book" ]; then
      if grep -q "^type:[[:space:]]*book" "$found"; then
        echo "PASS: type: book present"
      else
        echo "FAIL: type: book missing in $found"
        return 7
      fi
      if grep -q "^author:" "$found"; then
        echo "PASS: author field present"
      else
        echo "FAIL: author field missing in $found"
        return 8
      fi
      if grep -q "^rating:" "$found"; then
        echo "PASS: rating present"
      else
        echo "WARN: rating missing; showing file head:"
        head -n 40 "$found" || true
      fi
    elif [ "$category" = "link" ]; then
      if grep -q "^type:[[:space:]]*link" "$found"; then
        echo "PASS: type: link present"
      else
        echo "FAIL: type: link missing in $found"
        return 9
      fi
      if grep -q "^url:" "$found"; then
        echo "PASS: url present"
      else
        echo "FAIL: url missing in $found"
        return 10
      fi
      if grep -q "^date-clipped:" "$found"; then
        echo "PASS: date-clipped present"
      else
        echo "FAIL: date-clipped missing in $found"
        return 11
      fi
      if grep -q "^tags:.*web/clipping" "$found"; then
        echo "PASS: tags include web/clipping"
      else
        echo "WARN: tags do not include web/clipping in $found"
      fi
    elif [ "$category" = "install" ]; then
      if grep -q "^type:[[:space:]]*install-guide" "$found"; then
        echo "PASS: type: install-guide present"
      else
        echo "FAIL: type: install-guide missing in $found"
        return 12
      fi
      if grep -q "^software-name:" "$found"; then
        echo "PASS: software-name present"
      else
        echo "FAIL: software-name missing in $found"
        return 13
      fi
      if grep -q "^installer:" "$found"; then
        echo "PASS: installer present"
      else
        echo "WARN: installer missing in $found"
      fi
      if grep -q "^link:" "$found"; then
        echo "PASS: link present"
      else
        echo "WARN: link missing in $found"
      fi
    else
      if grep -q "^title:[[:space:]]*\"${title//\"/\\\"}\"" "$found" || grep -q "^title:[[:space:]]*${title}" "$found"; then
        echo "PASS: title present in frontmatter"
      else
        echo "WARN: title not found in frontmatter, showing file head:"
        head -n 40 "$found" || true
      fi
    fi
  fi

  return 0
}

# Run tests
run_one "Test Cat" "note"
rc_note=$?
run_one "Training Test" "training"
rc_training=$?
run_one "Morning Test" "journal"
rc_journal=$?
run_one "Cmd Test" "command"
rc_command=$?
run_one "Book Test" "book"
rc_book=$?
run_one "Podcast Test" "podcast"
rc_podcast=$?

run_one "Link Test" "link"
rc_link=$?

run_one "Install Test" "install"
rc_install=$?

echo
echo "Results: note=$rc_note training=$rc_training journal=$rc_journal command=$rc_command book=$rc_book podcast=$rc_podcast link=$rc_link install=$rc_install"
if [ $rc_note -ne 0 ] || [ $rc_training -ne 0 ] || [ $rc_journal -ne 0 ] || [ $rc_command -ne 0 ] || [ $rc_book -ne 0 ] || [ $rc_podcast -ne 0 ] || [ $rc_link -ne 0 ] || [ $rc_install -ne 0 ]; then
  echo "One or more create_note tests failed. See $LOG"
  exit 5
fi

echo "All create_note tests passed. Logs: $LOG"