#!/bin/bash

load_dotenv() {
	local envfile
	local candidates
	# Prefer env written by the installer under XDG_DATA_HOME, then local
	# project .env, then scripts/.env and parent .env.
	candidates=("${XDG_DATA_HOME:-$HOME/.local/share}/daily-note/scripts/.env" "$PWD/.env" "$SCRIPT_DIR/.env" "$SCRIPT_DIR/../.env")
	for envfile in "${candidates[@]}"; do
		if [ -f "$envfile" ]; then
			# shellcheck disable=SC1090
			set -a
			. "$envfile"
			set +a
			return 0
		fi
	done
	return 1
}

# Attempt to load .env silently if present. This will export variables
# declared in the file so scripts can rely on them as environment variables.
load_dotenv >/dev/null 2>&1 || true
#
# --- CONFIGURATION ---
VAULT_DIR="${VAULT_DIR:-$(realpath "$SCRIPT_DIR/..")}" 
DAILY_DIR="$VAULT_DIR/Daily"
TECH_DIR="$VAULT_DIR/Technical"

# Ensure directories exist
mkdir -p "$DAILY_DIR" "$TECH_DIR"

# --- DEFAULTS ---
MODE="journal"
TIMESTAMP=$(date +"%H:%M")
FILENAME="$(date +'%Y-%m-%d').md"

# --- FLAG PARSING ---
while getopts "tj" opt; do
  case $opt in
    t) MODE="tech" ;;
    j) MODE="journal" ;;
    *) exit 1 ;;
  esac
done
shift $((OPTIND -1))

CONTENT=$*

# 1. Open Editor if content is empty
if [ -z "$CONTENT" ]; then
    TMPFILE=$(mktemp)
    $EDITOR "$TMPFILE"
fi
CONTENT=$(cat ${TMPFILE})
rm $TMPFILE

# --- ROUTING ---
if [ "$MODE" == "tech" ]; then
    TARGET_FILE="$TECH_DIR/DevLog_$(date +'%Y-%m').md"
    TAGS="#work #code"
    # Logic for Technical Log
    echo -e "\n### $TIMESTAMP $TAGS\n$CONTENT" >> "$TARGET_FILE"
    echo "Snippet saved to Technical Log."
else
    TARGET_FILE="$DAILY_DIR/$FILENAME"
    TAGS="#fleeting"
    # Ensure Daily Note exists with YAML
    # Define the metadata block
    METADATA="---\ndate: $(date +'%Y-%m-%d')\ntype: daily\n---"

    if [ ! -f "$TARGET_FILE" ]; then
        # SCENARIO 1: File does not exist. Create it with metadata.
        echo -e "$METADATA\n# Daily Note" > "$TARGET_FILE"
        echo "Created new file with metadata: $TARGET_FILE"
    elif ! grep -q "^---" "$TARGET_FILE"; then
        # SCENARIO 2: File exists, but no metadata header found.
        # We prepend the metadata to the top of the existing file.
        TEMP_FILE=$(mktemp)
        echo -e "$METADATA" > "$TEMP_FILE"
        cat "$TARGET_FILE" >> "$TEMP_FILE"
        mv "$TEMP_FILE" "$TARGET_FILE"
        echo "Added missing metadata to existing file: $TARGET_FILE"
    fi
    echo -e "\n## $TIMESTAMP $TAGS\n$CONTENT" >> "$TARGET_FILE"
    echo "Entry saved to Daily Note."
fi
