# Common script header for Obsidian vault scripts
# Sets and exports `SCRIPT_DIR` (location of scripts/) and `VAULT_DIR` (parent of scripts/)

# Resolve the directory containing this file (works when sourced)
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

export SCRIPT_DIR VAULT_DIR
# Load .env if present and export any variables it defines.
# Search order: current working dir, script dir, script parent, vault dir.
load_dotenv() {
	local envfile
	local candidates
	candidates=("$PWD/.env" "$SCRIPT_DIR/.env" "$SCRIPT_DIR/../.env" )
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
# Allow callers (tests/CI) to override VAULT_DIR via env; otherwise default to parent of scripts/
VAULT_DIR="${VAULT_DIR:-$(realpath "$SCRIPT_DIR/..")}" 


# detect gum
if command -v gum >/dev/null 2>&1; then
  USE_GUM=true
else
  USE_GUM=false
fi

# Detect availability of common tools and expose variables so other scripts/tests
# can decide to use fallbacks instead of failing. Do NOT mask or replace these
# commands; just advertise availability via exported vars.
if command -v fzf >/dev/null 2>&1; then
	FZF_AVAILABLE=true
else
	FZF_AVAILABLE=false
fi

if command -v rg >/dev/null 2>&1; then
	RG_AVAILABLE=true
else
	RG_AVAILABLE=false
fi

if command -v batcat >/dev/null 2>&1 || command -v bat >/dev/null 2>&1; then
	BAT_AVAILABLE=true
else
	BAT_AVAILABLE=false
fi

export FZF_AVAILABLE RG_AVAILABLE BAT_AVAILABLE

# If the vault directory exists, change into it; otherwise do not exit (helps tests create the directory)
if [ -n "$VAULT_DIR" ] && [ -d "$VAULT_DIR" ]; then
	cd "$VAULT_DIR" || exit 1
fi

# helper prompt functions that prefer gum if available
if [ "$USE_GUM" = true ]; then
  ask() { local v; v="$(gum input --value "${2:-}" --placeholder "$1")"; printf '%s' "$v"; }
  choose_one() { gum choose --header "$1" "${@:2}"; }
else
  ask() {
    local prompt="$1" default="$2" res
    if [ -n "$default" ]; then
      read -rp "$prompt [$default]: " res
      res="${res:-$default}"
    else
      read -rp "$prompt: " res
    fi
    printf '%s' "$res"
  }
  choose_one() {
    local prompt="$1"; shift
    PS3="$prompt: "
    select opt in "$@"; do
      [ -n "$opt" ] && { printf '%s' "$opt"; break; }
    done
  }
fi

confirm() {
  # confirm "Prompt" -> returns 0 for yes, 1 for no
  local prompt="$1"
  if [ "$USE_GUM" = true ]; then
    if gum confirm "$prompt"; then
      return 0
    else
      return 1
    fi
  else
    read -rp "$prompt (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      return 0
    else
      return 1
    fi
  fi
}

  # trim leading/trailing whitespace
  _trim() { printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }

  # escape quotes for YAML quoting
  _escape_q() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

# format comma-separated -> unquoted list: a, b, c
_fmt_tags() {
	local raw="$1"
	[ -z "$raw" ] && { printf '%s' ""; return; }
	IFS=',' read -ra parts <<<"$raw"
	local out=""
	for p in "${parts[@]}"; do
		p="$(_trim "$p")"
		[ -n "$p" ] || continue
		out+="${out:+, }${p}"
	done
	printf '%s' "$out"
}

# format comma-separated -> YAML quoted array: ["a","b"]
_fmt_quoted_array() {
	local raw="$1"
	[ -z "$raw" ] && { printf '[]'; return; }
	IFS=',' read -ra parts <<<"$raw"
	local out=""
	for p in "${parts[@]}"; do
		p="$(_trim "$p")"
		[ -n "$p" ] || continue
		p="$(_escape_q "$p")"
		out+="${out:+, }\"${p}\""
	done
	printf '[%s]' "$out"
}

# fzf + follow-links helpers
# - `fzf_choose_with_follow` reads newline-separated choices from stdin
#   and runs `fzf` with a preview command that delegates to
#   `scripts/_preview_link.sh`. It also binds `ctrl-l` to the
#   follow-links action (keeps backward-compatible behavior).
fzf_choose_with_follow() {
	local prompt="${1:-Select > }"
	local preview_window="${2:-down:50%}"

	# Use a wrapped preview helper so fzf runs a POSIX sh command and
	# the selection is passed safely as an argument (preserves spaces).
	local preview_cmd
	# Use a wrapped preview helper. The preview will try to show a file
	# if the selection is a path (or path.md), otherwise delegate to
	# the link preview helper. We still bind ctrl-l to follow_links.
	preview_cmd="sh -c 'p=\"\$1\"; if [ -f \"$VAULT_DIR/\$p\" ]; then f=\"$VAULT_DIR/\$p\"; elif [ -f \"$VAULT_DIR/\$p.md\" ]; then f=\"$VAULT_DIR/\$p.md\"; elif [ -f \"\$p\" ]; then f=\"\$p\"; elif [ -f \"\$p.md\" ]; then f=\"\$p.md\"; fi; if [ -n \"\$f\" ]; then if command -v batcat >/dev/null 2>&1; then batcat --style=plain --color=always \"\$f\" 2>/dev/null; elif command -v bat >/dev/null 2>&1; then bat --style=plain --color=always \"\$f\" 2>/dev/null; else cat \"\$f\"; fi; else \"$SCRIPT_DIR/_preview_link.sh\" \"\$1\"; fi' sh {}"

	# Read items from stdin and run fzf. The function returns the
	# selected item on stdout.
	# Bindings:
	#  - ctrl-j / ctrl-k : move down/up
	#  - alt-j / alt-k   : alternative move keys (if terminal supports Alt)
	#  - ctrl-u / ctrl-d : preview page up / page down
	#  - ctrl-l          : follow-links (execute follow_links)
	fzf --ansi --no-multi \
		--preview "$preview_cmd" \
		--preview-window="$preview_window" \
		--prompt "$prompt" \
		--bind "ctrl-j:down,ctrl-k:up,alt-j:down,alt-k:up,ctrl-u:preview-page-up,ctrl-d:preview-page-down,ctrl-l:execute(\"$SCRIPT_DIR/follow_links.sh\" {})+abort"
}

# Variant that allows multi-select and returns newline-separated selections
fzf_choose_with_follow_multi() {
	local prompt="${1:-Select > }"
	local preview_window="${2:-down:50%}"

	local preview_cmd
	preview_cmd="sh -c 'p=\"\$1\"; if [ -f \"$VAULT_DIR/\$p\" ]; then f=\"$VAULT_DIR/\$p\"; elif [ -f \"$VAULT_DIR/\$p.md\" ]; then f=\"$VAULT_DIR/\$p.md\"; elif [ -f \"\$p\" ]; then f=\"\$p\"; elif [ -f \"\$p.md\" ]; then f=\"\$p.md\"; fi; if [ -n \"\$f\" ]; then if command -v batcat >/dev/null 2>&1; then batcat --style=plain --color=always \"\$f\" 2>/dev/null; elif command -v bat >/dev/null 2>&1; then bat --style=plain --color=always \"\$f\" 2>/dev/null; else cat \"\$f\"; fi; else \"$SCRIPT_DIR/_preview_link.sh\" \"\$1\"; fi' sh {}"

	fzf --ansi --multi \
		--preview "$preview_cmd" \
		--preview-window="$preview_window" \
		--prompt "$prompt" \
		--bind "ctrl-j:down,ctrl-k:up,alt-j:down,alt-k:up,ctrl-u:preview-page-up,ctrl-d:preview-page-down,ctrl-l:execute(\"$SCRIPT_DIR/follow_links.sh\" {})+abort"
}


# Ensure a project index exists and add a wiki-link to it if missing.
# Project index path: 01-Projects/Project - <Project>.md
update_project_index() {
	local project="$1"
	local wikilink="$2" # wikilink without .md
	if [ -z "$project" ] || [ -z "$wikilink" ]; then
		echo "Usage: update_project_index <Project> <Wikilink>" >&2
		return 2
	fi

	local sanitized project_dir project_file project_title
	sanitized=$(echo "$project" | sed 's/[^[:alnum:] _-]/_/g' | sed 's/  */ /g' | sed 's/ /_/g')
	project_dir="$VAULT_DIR/01-Projects/${sanitized}"
	project_title="$project"
	project_file="$project_dir/Project - ${project_title}.md"

	mkdir -p "$project_dir"
	if [ ! -f "$project_file" ]; then
		cat > "$project_file" <<EOF
# Project - ${project_title}

## Overview

Project index for ${project_title}.

## Notes
- [[${wikilink}]]

## Backlinks

EOF
		echo "Created project index: ${project_file}"
		return 0
	fi

	# Ensure Notes section exists
	if ! grep -q "^## Notes" "$project_file"; then
		echo "" >> "$project_file"
		echo "## Notes" >> "$project_file"
	fi

	# Add the wikilink to the Notes section if not present
	if ! grep -qF "[[${wikilink}]]" "$project_file"; then
		sed -i "/^## Notes/a - [[${wikilink}]]" "$project_file"
		echo "Added link to project index: ${project_file} -> [[${wikilink}]]"
	else
		echo "Project index already contains link: [[${wikilink}]]"
	fi
}


# Add backlink entries between notes. Given a source wikilink and target note paths (newline-separated),
# add `- [[<target>]]` to source under '## Backlinks' and add `- [[<source>]]` to each target under '## Backlinks'.
add_backlinks_between() {
	local source_wikilink="$1"
	shift
	local targets="$@"
	# source file path
	local src_file
	src_file_find() {
		find "$VAULT_DIR" -type f -iname "${source_wikilink}.md" -print -quit
	}
	src_file=$(src_file_find)
	if [ -z "$src_file" ]; then
		echo "Warning: source note file not found for [[${source_wikilink}]]" >&2
		return 1
	fi

	# ensure Backlinks section in source
	if ! grep -q "^## Backlinks" "$src_file"; then
		echo "" >> "$src_file"
		echo "## Backlinks" >> "$src_file"
	fi

	# iterate targets; each target may be a path or a wikilabel; resolve to title-like label
	while IFS= read -r t; do
		[ -z "$t" ] && continue
		# normalize: if t is a path inside VAULT_DIR, strip prefix and extension
		relt=$(realpath --relative-to="$VAULT_DIR" "$t" 2>/dev/null || true)
		if [ -n "$relt" ]; then
			label=$(basename "$relt" .md)
		else
			label="$t"
		fi
		# add to source if missing
		if ! grep -qF "[[${label}]]" "$src_file"; then
			sed -i "/^## Backlinks/a - [[${label}]]" "$src_file"
			echo "Added backlink in $src_file -> [[${label}]]"
		fi

		# add reciprocal backlink in target file
		# attempt to find target file path
		tfile=$(find "$VAULT_DIR" -type f -iname "${label}.md" -print -quit)
		if [ -n "$tfile" ]; then
			if ! grep -q "^## Backlinks" "$tfile"; then
				echo "" >> "$tfile"
				echo "## Backlinks" >> "$tfile"
			fi
			if ! grep -qF "[[${source_wikilink}]]" "$tfile"; then
				sed -i "/^## Backlinks/a - [[${source_wikilink}]]" "$tfile"
				echo "Added reciprocal backlink in $tfile -> [[${source_wikilink}]]"
			fi
		else
			echo "Warning: target note not found for label ${label}; skipped reciprocal backlink" >&2
		fi
	done <<EOF
${targets}
EOF
}

# follow_links: extract wiki-links from a note and allow selection
# Usage: follow_links /path/to/note.md
follow_links() {
	local src="$1"
	if [ -z "$src" ] || [ ! -f "$src" ]; then
		echo "Usage: follow_links <note-file>" >&2
		return 2
	fi

	# Extract [[inner]] links using the AWK-based shell extractor.
	local links
	if [ -f "$SCRIPT_DIR/_extract_links.sh" ]; then
		links=$(sh "$SCRIPT_DIR/_extract_links.sh" "$src" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sort -u)
	else
		echo "Error: no link extractor found. Expected $SCRIPT_DIR/_extract_links.sh" >&2
		return 2
	fi
	if [ -z "$links" ]; then
		echo "No links found in $src"
		return 0
	fi

	# Let the user select a linked label (the preview will show file contents)
	local selected
	selected=$(printf '%s\n' "$links" | fzf_choose_with_follow "🔗 Linked Notes > ")
	if [ -z "$selected" ]; then
		return 0
	fi

	# Normalize and detect kind of target (Jobs vs Zettelkasten)
	selected=$(echo "$selected" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

	local base_dir target_file
	if printf '%s' "$selected" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}\s*-\s*'; then
		base_dir="$VAULT_DIR/01-Projects/Jobs"
	elif printf '%s' "$selected" | grep -qE '^NOTE\s*-\s*'; then
		base_dir="$VAULT_DIR/Zettelkasten"
	else
		echo "Preview not available for: $selected" >&2
		return 1
	fi

	target_file=$(find "$base_dir" -maxdepth 1 -type f \( -name "$selected" -o -name "${selected}.md" -o -name "${selected}*" \) -print -quit)
	if [ -z "$target_file" ]; then
		echo "Linked note not found: attempted patterns: $base_dir/$selected, $base_dir/${selected}.md, $base_dir/${selected}*" >&2
		return 1
	fi

	if command -v batcat >/dev/null 2>&1; then
		batcat --style=plain --color=always "$target_file" | less -R
	elif command -v bat >/dev/null 2>&1; then
		bat --style=plain --color=always "$target_file" | less -R
	else
		cat "$target_file" | less -R
	fi
}

# Update daily note with a wiki-link
# Usage: update_daily_note_with_link "Category" "Wikilink" [daily_dir]
update_daily_note_with_link() {
    local category="$1"
    local wikilink="$2"
    local daily_dir="${3:-00-Journal/00-A-Daily Notes}"

	if [ -z "$category" ] || [ -z "$wikilink" ]; then
		echo "Usage: update_daily_note_with_link <Category> <Wikilink> [daily_dir]" >&2
		return 2
	fi

	# Normalize category to title-case (e.g. "my project" -> "My Project")
	local raw_cat
	raw_cat="${category,,}"
	local words
	IFS=' ' read -r -a words <<< "$raw_cat"
	for i in "${!words[@]}"; do
		words[$i]="${words[$i]^}"
	done
	local category_title
	category_title="${words[*]}"

	local date_ymd
	date_ymd=$(date +"%Y-%m-%d")
	local daily_path="$daily_dir/${date_ymd}.md"

    mkdir -p "$daily_dir"

    # If daily note doesn't exist, create header and category section with the link
	if [ ! -f "$daily_path" ]; then
		echo "# ${date_ymd}" > "$daily_path"
		echo "" >> "$daily_path"
		echo "## ${category_title}" >> "$daily_path"
		echo "- [[${wikilink}]]" >> "$daily_path"
		echo "📅 Daily note created and ${category_title} link added."
        return 0
    fi

    # Ensure the Category section exists
	if ! grep -q "^## ${category_title}" "$daily_path"; then
		echo "" >> "$daily_path"
		echo "## ${category_title}" >> "$daily_path"
    fi

    # Add the wiki link if not already present
	if ! grep -qF "[[${wikilink}]]" "$daily_path"; then
		sed -i "/^## ${category_title}/a - [[${wikilink}]]" "$daily_path"
		echo "🔗 ${category_title} link added to existing daily note."
    else
		echo "ℹ️ ${category_title} link already exists in daily note."
    fi
}

# End of lib.sh
