#!/usr/bin/env bash
set -euo pipefail

# Interactive vault search UI
# Prompts for a query, shows matching filenames with a preview of matches,
# and allows opening a selected file in the editor or viewing it.

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib.sh"

# Prefer ripgrep (`rg`) but fall back to `grep` when `rg` isn't available.
# `RG_HAS=true` indicates rg is present; otherwise we use `grep` fallback.
if command -v rg >/dev/null 2>&1; then
  RG_CMD=rg
  RG_HAS=true
else
  RG_CMD=grep
  RG_HAS=false
fi

# Diary support: allow `search.sh diary [range] [keyword]` to run the old diary functionality.
DAILY_SUBDIR="00-Journal/00-A-Daily Notes"

get_files_for_range() {
  local range="$1" dir="$2"
  case "$range" in
    today)
      date_str=$(date +%Y-%m-%d)
      find "$dir" -type f -name "$date_str.md"
      ;;
    yesterday)
      date_str=$(date -d "yesterday" +%Y-%m-%d)
      find "$dir" -type f -name "$date_str.md"
      ;;
    this-month)
      month_str=$(date +%Y-%m)
      find "$dir" -type f -name "$month_str-*.md" | sort
      ;;
    last-week)
      for i in {1..7}; do
        d=$(date -d "$i days ago" +%Y-%m-%d)
        find "$dir" -type f -name "$d.md"
      done | sort
      ;;
    *)
      find "$dir" -type f -name "*.md" | sort
      ;;
  esac
}

print_preview_cmd() {
  # Print a preview command suitable for fzf. Use batcat/bat when available.
  # Handle rg vs grep differences: when rg is present we use its colorized output;
  # otherwise fall back to grep with similar flags.
  if command -v batcat >/dev/null 2>&1; then
    if [ "$RG_HAS" = true ]; then
      printf 'rg -n --color=always -C 3 "%s" {} | batcat --style=plain --paging=never --language=markdown'
    else
      printf 'grep -n -C 3 "%s" {} | batcat --style=plain --paging=never --language=markdown'
    fi
  elif command -v bat >/dev/null 2>&1; then
    if [ "$RG_HAS" = true ]; then
      printf 'rg -n --color=always -C 3 "%s" {} | bat --style=plain --paging=never --language=markdown'
    else
      printf 'grep -n -C 3 "%s" {} | bat --style=plain --paging=never --language=markdown'
    fi
  else
    if [ "$RG_HAS" = true ]; then
      printf 'rg -n --color=always -C 3 "%s" {}'
    else
      printf 'grep -n -C 3 "%s" {}'
    fi
  fi
}
# detect diary mode
MODE="interactive"
if [ "${1:-}" = "diary" ]; then
  MODE="diary"
  shift || true
fi

# If diary mode and args provided, do non-interactive diary search and exit
if [ "$MODE" = "diary" ] && [ $# -gt 0 ]; then
  range="$1"; keyword="${2:-}"
  dir="$VAULT_DIR/$DAILY_SUBDIR"
  notes=$(get_files_for_range "$range" "$dir")
  if [ -z "$notes" ]; then
    echo "No notes found for range: $range"
    exit 0
  fi
  if [ -n "$keyword" ]; then
    if [ "$RG_HAS" = true ]; then
      notes=$(printf '%s\n' "$notes" | xargs rg -l --hidden --glob '!.git' "$keyword" 2>/dev/null || true)
    else
      notes=$(printf '%s\n' "$notes" | xargs -r grep -l --line-number -- "$keyword" 2>/dev/null || true)
    fi
    if [ -z "$notes" ]; then
      echo "No notes found for range '$range' containing keyword '$keyword'"
      exit 0
    fi
  fi
    # present selection with fzf (preview) — allow FZF_CMD override for tests
    preview_cmd=$(print_preview_cmd)
    FZF_CMD="${FZF_CMD:-fzf}"
    selected=$(printf '%s\n' "$notes" | sed "s#^$VAULT_DIR/##" | "$FZF_CMD" --ansi --preview "$preview_cmd" --preview-window=down:40% --prompt="Diary: $range ${keyword:+with '$keyword'} > ")
  [ -n "$selected" ] && printf '%s\n' "$selected"
  exit 0
fi

 
while true; do
  # Use gum-aware ask() from lib.sh which falls back to read -p
  query=$(ask 'Enter search query (empty to exit)' '')
  query="$(printf '%s' "$query" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  [ -n "$query" ] || break

  # Find files with matches under VAULT_DIR
  if [ "$RG_HAS" = true ]; then
    mapfile -t results < <(rg --files-with-matches --hidden --glob '!.git' -- "$query" "$VAULT_DIR" 2>/dev/null || true)
  else
    # grep fallback: list files containing the query under VAULT_DIR (exclude .git)
    mapfile -t results < <(grep -R -l --exclude-dir=.git -- "$query" "$VAULT_DIR" 2>/dev/null || true)
  fi

  if [ "${#results[@]}" -eq 0 ]; then
    echo "No matches for: $query"
    continue
  fi

  # Prepare fzf preview command
  preview_cmd=$(print_preview_cmd)

  FZF_CMD="${FZF_CMD:-fzf}"
  if command -v "$FZF_CMD" >/dev/null 2>&1 2>/dev/null || [ -x "$FZF_CMD" ]; then
    # Run fzf with a preview (relative paths are nicer). Allow multi-select.
    cd "$VAULT_DIR" || true
    selected_raw=$(printf '%s\n' "${results[@]}" | sed "s#^$VAULT_DIR/##" | "$FZF_CMD" --ansi --multi --preview "$preview_cmd" --preview-window=right:60% --prompt="Search: $query > ")
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


