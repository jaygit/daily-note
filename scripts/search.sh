#!/usr/bin/env bash
set -euo pipefail

# Interactive vault search UI
# Prompts for a query, shows matching filenames with a preview of matches,
# and allows opening a selected file in the editor or viewing it.

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib.sh"

if ! command -v rg >/dev/null 2>&1; then
  echo "Error: ripgrep (rg) is required for search." >&2
  exit 2
fi

print_preview_cmd() {
  # Print a preview command suitable for fzf. Uses batcat/bat when available.
  if command -v batcat >/dev/null 2>&1; then
    printf 'rg -n --color=always -C 3 "%s" {} | batcat --style=plain --paging=never --language=markdown'
  elif command -v bat >/dev/null 2>&1; then
    printf 'rg -n --color=always -C 3 "%s" {} | bat --style=plain --paging=never --language=markdown'
  else
    printf 'rg -n --color=always -C 3 "%s" {}'
  fi
}

while true; do
  # Use gum-aware ask() from lib.sh which falls back to read -p
  query=$(ask 'Enter search query (empty to exit)' '')
  query="$(printf '%s' "$query" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  [ -n "$query" ] || break

  # Find files with matches under VAULT_DIR
  mapfile -t results < <(rg --files-with-matches --hidden --glob '!.git' -- "$query" "$VAULT_DIR" 2>/dev/null || true)

  if [ "${#results[@]}" -eq 0 ]; then
    echo "No matches for: $query"
    continue
  fi

  # Prepare fzf preview command
  preview_cmd=$(print_preview_cmd)

  if command -v fzf >/dev/null 2>&1; then
    # Run fzf with a preview (relative paths are nicer). Allow multi-select.
    cd "$VAULT_DIR" || true
    selected_raw=$(printf '%s\n' "${results[@]}" | sed "s#^$VAULT_DIR/##" | fzf --ansi --multi --preview "$preview_cmd" --preview-window=right:60% --prompt="Search: $query > ")
    # restore cwd
    cd - >/dev/null 2>&1 || true
    # convert raw selection (possibly multiline) into array
    if [ -z "$selected_raw" ]; then
      selected=""
    else
      mapfile -t sel_arr <<<"$selected_raw"
      # join with NUL-safe handling later
      selected="${sel_arr[0]}"
    fi
  else
    echo "fzf not found; printing matches:";
    printf '%s\n' "${results[@]}";
    selected=""
  fi

  [ -n "$selected" ] || continue

  # Resolve full path(s)
  if [ -z "$selected_raw" ]; then
    continue
  fi
  mapfile -t sel_arr <<<"$selected_raw"
  targets=()
  for s in "${sel_arr[@]}"; do
    targets+=("$VAULT_DIR/$s")
  done

  # Ask what to do with selected file
  if declare -f choose_one >/dev/null 2>&1; then
    action=$(choose_one "Selected: $selected - action" "Open in editor" "Show raw" "Back to search")
  else
    echo "Selected: $selected"
    echo "1) Open in editor"
    echo "2) Show raw"
    echo "3) Back to search"
    read -rp "Choose [1]: " choice
    choice=${choice:-1}
    case "$choice" in
      1) action="Open in editor" ;;
      2) action="Show raw" ;;
      *) action="Back to search" ;;
    esac
  fi

  case "$action" in
    "Open in editor")
      if [ -n "${NO_EDITOR:-}" ]; then
        echo "NO_EDITOR set; skipping open. Files: ${targets[*]}"
      else
        # Open all selected files in one editor invocation (if editor supports multiple files)
        ${EDITOR:-vi} "${targets[@]}"
      fi
      ;;
    "Show raw")
      for t in "${targets[@]}"; do
        if command -v batcat >/dev/null 2>&1; then
          batcat --style=plain --paging=never "$t" || cat "$t"
        elif command -v bat >/dev/null 2>&1; then
          bat --style=plain --paging=never "$t" || cat "$t"
        else
          cat "$t"
        fi
        echo "---"
      done
      read -rp "Press Enter to return to search..." _
      ;;
    *)
      # back to search
      ;;
  esac
done

echo "Exiting search."
#!/usr/bin/env bash

# Minimal bootstrap: locate `lib.sh` and source it
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib.sh"

if [ -z "$1" ]; then
  echo "Usage: vault-search <query>"
  exit 1
fi

QUERY="$1"

rg --files-with-matches "$QUERY" "$VAULT_DIR" | \
fzf --preview "rg -n --color=always -C 3 \"$QUERY\" {} | batcat --style=plain --language=markdown"

