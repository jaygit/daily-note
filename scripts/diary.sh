#!/usr/bin/env bash

# Minimal bootstrap: locate `lib.sh` and source it
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib.sh"

# Path to your Obsidian vault daily notes (relative to vault root)
DAILY_DIR="00-Journal/00-A-Daily Notes"

# --- Helper: get files for a date range ---
get_files_for_range() {
    case "$1" in
        today)
            date_str=$(date +%Y-%m-%d)
            find "$DAILY_DIR" -type f -name "$date_str.md"
            ;;
        yesterday)
            date_str=$(date -d "yesterday" +%Y-%m-%d)
            find "$DAILY_DIR" -type f -name "$date_str.md"
            ;;
        this-month)
            month_str=$(date +%Y-%m)
            find "$DAILY_DIR" -type f -name "$month_str-*.md" | sort
            ;;
        last-week)
            for i in {1..7}; do
                d=$(date -d "$i days ago" +%Y-%m-%d)
                find "$DAILY_DIR" -type f -name "$d.md"
            done | sort
            ;;
        *)
            find "$DAILY_DIR" -type f -name "*.md" | sort
            ;;
    esac
}

# --- Main ---
range="$1"    # e.g. today, yesterday, this-month, last-week
keyword="$2"  # optional search term

if [[ "$range" == "help"  || "$range" == "--help" || "$range" == "-h" ]]; then
	echo "diary.sh [today|yesterday|this-month|last-month|last-week]"
	exit 0
fi
notes=$(get_files_for_range "$range")

if [[ -z "$notes" ]]; then
    echo "No notes found for range: $range"
    exit 0
fi

if [[ -n "$keyword" ]]; then
    # Filter notes by keyword using ripgrep
    notes=$(echo "$notes" | xargs rg -l "$keyword" 2>/dev/null)
    if [[ -z "$notes" ]]; then
        echo "No notes found for range '$range' containing keyword '$keyword'"
        exit 0
    fi
fi

selected=$(printf '%s\n' "$notes" | fzf_choose_with_follow "📓 Notes ($range ${keyword:+with '$keyword'}) > " "down:50%")

printf "%s\n" "$selected"

