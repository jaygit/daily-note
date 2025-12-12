#!/usr/bin/env bash
# Preview helper for fzf to display linked note content
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib.sh"

link="$1"
if [ -z "$link" ]; then
  echo "No link provided"
  exit 1
fi

# Determine preview command (batcat, bat, or cat)
show_file() {
  if command -v batcat >/dev/null 2>&1; then
    batcat --style=plain --color=always "$1"
  elif command -v bat >/dev/null 2>&1; then
    bat --style=plain --color=always "$1"
  else
    cat "$1"
  fi
}

# If the selection is already a file path (absolute or relative to vault),
# show it directly. This fixes cases where fzf supplies a file path
# (e.g. from `diary.sh`) instead of a link label.
if [ -f "$link" ]; then
  show_file "$link" 2>/dev/null || true
  exit 0
fi

if [ -f "$VAULT_DIR/$link" ]; then
  show_file "$VAULT_DIR/$link" 2>/dev/null || true
  exit 0
fi

if printf "%s" "$link" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}\s*-\s*'; then
  base_dir="$VAULT_DIR/01-Projects/Jobs"
  # Use find to handle filenames with spaces and glob-like prefix matching
  found_file=$(find "$base_dir" -maxdepth 1 -type f \( -name "$link" -o -name "${link}.md" -o -name "${link}*" \) -print -quit)
  if [ -n "$found_file" ]; then
    show_file "$found_file" 2>/dev/null || true
  else
    echo "Preview: not available for $link"
  fi
elif printf "%s" "$link" | grep -qE '^NOTE\s*-\s*'; then
  base_dir="$VAULT_DIR/Zettelkasten"
  found_file=$(find "$base_dir" -maxdepth 1 -type f \( -name "$link" -o -name "${link}.md" -o -name "${link}*" \) -print -quit)
  if [ -n "$found_file" ]; then
    show_file "$found_file" 2>/dev/null || true
  else
    echo "Preview: not available for $link"
  fi
else
  echo "Preview not currently available for: $link"
fi
