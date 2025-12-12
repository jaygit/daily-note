#!/bin/bash
# Create a regular (Zettelkasten) note with optional project and category
# Usage: create_reg_note.sh -t "Title" [-c Category] [-p Project] [-v /path/to/vault]
 
# Minimal bootstrap: locate `lib.sh` and source it
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib.sh"

NOTE_DIR="Zettelkasten"
DAILY_NOTE_DIR="00-Journal/00-A-Daily Notes"

# Defaults
CATEGORY="Note"
PROJECT=""

print_usage() {
  cat <<EOF
Usage: $0 -t "Note Title" [-c Category] [-p Project] [-v /path/to/vault]

Options:
  -t    Title of the note (required)
  -c    Category for the note (default: Note)
  -p    Project name to associate (optional)
  -v    Path to Obsidian vault (default: value from lib.sh)
  -h    Show this help message
EOF
}

# Parse options
while getopts ":t:c:p:v:h" opt; do
  case $opt in
    t) TITLE="$OPTARG" ;;
    c) CATEGORY="$OPTARG" ;;
    p) PROJECT="$OPTARG" ;;
    v) # Allow overriding vault dir (rare)
       VAULT_DIR="$OPTARG" ;;
    h) print_usage; exit 0 ;;
    :) echo "Missing argument for -$OPTARG" >&2; print_usage; exit 1 ;;
    \?) echo "Invalid option: -$OPTARG" >&2; print_usage; exit 1 ;;
  esac
done

if [ -z "$TITLE" ]; then
  echo "Error: Title is required (use -t)" >&2
  print_usage
  exit 1
fi

# Clean and prepare filename
CLEAN_TITLE=$(echo "$TITLE" | sed 's/[^a-zA-Z0-9 ]//g' | sed 's/  */ /g' | sed 's/ /_/g')
# Capitalize category first letter
CATEGORY_CAP="${CATEGORY^}"
# Display-safe category for filename (remove punctuation)
CATEGORY_DISPLAY=$(echo "$CATEGORY_CAP" | sed 's/[^[:alnum:] ]//g' | sed 's/  */ /g' | sed 's/ $//')
FILENAME="${CATEGORY_DISPLAY} - ${CLEAN_TITLE}.md"

mkdir -p "$NOTE_DIR"
FILEPATH="${NOTE_DIR}/${FILENAME}"

if [ -f "$FILEPATH" ]; then
  echo "Warning: File already exists: $FILEPATH"
  read -p "Do you want to overwrite it? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
  fi
fi

# Compute tags: replace non-alnum with underscores, collapse runs, trim leading/trailing underscores
sanitize_tag() {
  echo "$1" | sed 's/[^[:alnum:] ]/_/g' | sed 's/  */ /g' | sed 's/ /_/g' | sed 's/_\+/_/g' | sed 's/^_//' | sed 's/_$//' | tr '[:upper:]' '[:lower:]'
}

CATEGORY_TAG=$(sanitize_tag "$CATEGORY")
PROJECT_TAG=""
if [ -n "$PROJECT" ]; then
  PROJECT_TAG=$(sanitize_tag "$PROJECT")
fi

# Create base file with minimal frontmatter
DATE_YMD=$(date +"%Y-%m-%d")
mkdir -p "$(dirname "$FILEPATH")"
cat > "$FILEPATH" <<EOF
---
title: ${CATEGORY_CAP} - ${TITLE}
created: $(date +"%Y-%m-%d %H:%M:%S")
tags: []
---

# ${CATEGORY_CAP} - ${TITLE}

Created: ${DATE_YMD}

Daily: [[${DATE_YMD}]]

EOF

# Merge frontmatter: call Python helper if available; pass project and tags
MERGE_SCRIPT="$SCRIPT_DIR/_merge_frontmatter.py"
if command -v python3 >/dev/null 2>&1 && [ -f "$MERGE_SCRIPT" ]; then
  # Ensure we always provide project and project_tag (empty string allowed)
  python3 "$MERGE_SCRIPT" "$FILEPATH" "$PROJECT" "$PROJECT_TAG" "$CATEGORY_TAG" || {
    echo "Warning: frontmatter merge failed (python)" >&2
  }
else
  # Fallback: attempt a simple YAML append (best-effort)
  echo "Warning: Python merge helper not available; doing a best-effort tag merge" >&2
  # Append category tag if not present
  if ! grep -q "tags:" "$FILEPATH"; then
    sed -i '1s|---|---\ntags: []|' "$FILEPATH"
  fi
  # crude insertion: replace tags: [] with tags: [category]
  sed -i "s/^tags: \[\]/tags: [${CATEGORY_TAG}]/" "$FILEPATH"
  if [ -n "$PROJECT" ]; then
    # add project key if missing
    if ! grep -q "^project:" "$FILEPATH"; then
      sed -i "1s|---|---\nproject: ${PROJECT}|" "$FILEPATH"
    fi
  fi
fi

echo "Created note: $FILEPATH"

# Update daily note (add a wiki-link) using the shared helper
# Pass the category and the wiki link (filename without .md)
WIKILINK="$(basename ${FILENAME} .md)"
update_daily_note_with_link "$CATEGORY" "$WIKILINK" "$DAILY_NOTE_DIR"

# If a project was provided, ensure the project index exists and link this note into it.
if [ -n "$PROJECT" ]; then
  update_project_index "$PROJECT" "$WIKILINK"
fi

# Interactive backlinking: allow user to select related notes and add reciprocal backlinks.
# Skip if NO_LINKS is set (useful for non-interactive tests).
if [ -z "${NO_LINKS:-}" ]; then
  # Ask interactively (skip in automated runs where stdin is not a tty)
  if [ -t 0 ]; then
    read -p "Add links to related notes? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      # Offer multi-select via fzf; list all markdown files relative to vault
      selected=$(find "$VAULT_DIR" -type f -name '*.md' -print | sed "s#^$VAULT_DIR/##" | grep -v "${NOTE_DIR}/${FILENAME}" | fzf_choose_with_follow_multi "Select related notes (TAB to multiselect) > " down:50%)
    fi
  else
    # Non-interactive tty: skip
    selected=""
  fi
  if [ -n "$selected" ]; then
    # Add backlinks between this new note and the selected notes
    add_backlinks_between "$WIKILINK" "$selected"
  fi
fi

# Open the new note in vi for editing (skip if NO_EDITOR is set)
if [ -z "${NO_EDITOR:-}" ]; then
  if command -v vi >/dev/null 2>&1; then
    vi "$FILEPATH"
  elif command -v vim >/dev/null 2>&1; then
    vim "$FILEPATH"
  else
    ${EDITOR:-vi} "$FILEPATH"
  fi
else
  echo "Skipping editor (NO_EDITOR set)."
fi

