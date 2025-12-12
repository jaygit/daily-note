#!/usr/bin/env bash
# create_train_note.sh - create a regular/training note with frontmatter and open in editor
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib.sh" || true

# fallback vault dir if lib.sh didn't set it
if [ -z "$VAULT_DIR" ]; then
  VAULT_DIR="$(realpath "$SCRIPT_DIR/..")"
fi

# detect gum
if command -v gum >/dev/null 2>&1; then
  USE_GUM=true
else
  USE_GUM=false
fi


get_training_fields() {
  local trainer_raw organization_raw date_field_raw duration_raw format_raw tags_raw status_raw completion_date_raw \
        linked_raw certificate_raw

  trainer_raw="$(ask 'Trainer (optional)' '')"
  trainer="$(_trim "$trainer_raw")"

  organization_raw="$(ask 'Organization / Provider (optional)' '')"
  organization="$(_trim "$organization_raw")"

  date_field_raw="$(ask 'Date (YYYY-MM-DD)' "${today:-$(date +%F)}")"
  date_field="$(_trim "$date_field_raw")"

  duration_raw="$(ask 'Duration (e.g. 2h 30m) (optional)' '')"
  duration="$(_trim "$duration_raw")"

  if declare -f choose_one >/dev/null 2>&1; then
    format_raw="$(choose_one 'Format' 'Online' 'In-person' 'Workshop')"
  else
    format_raw="$(ask 'Format (Online / In-person / Workshop) (optional)' '')"
  fi
  format="$(_trim "$format_raw")"

  tags_raw="$(ask 'Tags (comma-separated, e.g. training, skill/python, projectX) (optional)' '')"
  tags="$(_fmt_tags "$tags_raw")"

  if declare -f choose_one >/dev/null 2>&1; then
    status_raw="$(choose_one 'Status' 'planned' 'in-progress' 'completed')"
  else
    status_raw="$(ask 'Status (planned / in-progress / completed)' 'planned')"
  fi
  status="$(_trim "$status_raw")"

  if [ "${status,,}" = "completed" ]; then
    completion_date_raw="$(ask 'Completion date (YYYY-MM-DD)' "${today:-$(date +%F)}")"
    completion_date="$(_trim "$completion_date_raw")"
  else
    completion_date="null"
  fi

  linked_raw="$(ask 'Linked notes (comma-separated titles or wiki-links)' '')"
  linked_notes="$(_fmt_quoted_array "$(_trim "$linked_raw")")"

  certificate_raw="$(ask 'Certificate path (optional)' '')"
  certificate="$(_trim "$certificate_raw")"

  cat <<EOF
type: training
trainer: "${trainer}"
organization: "${organization}"
date: ${date_field}
duration: "${duration}"
format: "${format}"
tags: [${tags}]

# Progress tracking
status: "${status}"
completion_date: ${completion_date}

# Metadata
linked_notes: ${linked_notes}
certificate: "${certificate}"
notes_ref: []
EOF
}

get_journal_fields() {
  # defaults
  local today time_now
  today="$(date +%F)"
  time_now="$(date +%H:%M)"

  local title date time location mood tags_raw tags focus gratitude_raw gratitude linked_raw linked_notes status

  title="$(_trim "$(ask 'Title' 'Morning Reflection')")"
  date="$(_trim "$(ask 'Date (YYYY-MM-DD)' "$today")")"
  time="$(_trim "$(ask 'Time (HH:MM)' "$time_now")")"
  location="$(_trim "$(ask 'Location (optional)' 'Howth, Ireland')")"

  # mood choices (gum choose shows options; fallback uses select)
  mood="$(choose_one 'mood' calm stressed happy tired energized)"
  mood="$(_trim "$mood")"

  tags_raw="$(_trim "$(choose_one Tag journal personal reflection)")"
  tags="$(_fmt_tags "$tags_raw")"

  focus="$(_trim "$(ask 'Focus (optional)')")"
  gratitude_raw="$(_trim "$(choose_one 'Gratitude items' family learning community)")"
  gratitude="$(_fmt_quoted_array "$gratitude_raw")"

  linked_raw="$(_trim "$(ask 'Linked notes (comma-separated titles or wiki-links)' '')")"
  linked_notes="$(_fmt_quoted_array "$linked_raw")"

  status="$(choose_one 'Status' draft finalized)"
  status="$(_trim "$status")"
  [ -z "$status" ] && status="draft"

  # escape textual fields for YAML double-quoted values
  local esc_location esc_mood esc_focus
  esc_location="$(_escape_q "$location")"
  esc_mood="$(_escape_q "$mood")"
  esc_focus="$(_escape_q "$focus")"

  # print frontmatter
  cat <<-EOF
type: journal
date: ${date}
time: "${time}"
location: "${esc_location}"
mood: "${esc_mood}"
tags: [${tags}]

# Optional metadata
focus: "${esc_focus}"
gratitude: ${gratitude}
linked_notes: ${linked_notes}
status: "${status}"
EOF
}

# Collector for generic Zettelkasten notes
get_note_fields() {
  # Use helper prompts from lib.sh (ask, _trim, _fmt_tags, _escape_q)
  local tags_raw created_raw updated_raw status_raw tags created updated esc_created esc_updated esc_status

  tags_raw="$(ask 'Tags (comma-separated, default: zettelkasten, concept/idea)' 'zettelkasten, concept/idea')"
  tags="$(_fmt_tags "$tags_raw")"

  if declare -f choose_one >/dev/null 2>&1; then
    status_raw="$(choose_one 'Status' draft published reviewed incomplete || true)"
  else
    status_raw="$(ask 'Status (draft/published/reviewed/incomplete)' 'draft')"
  fi
  status="$(_trim "$status_raw")"
  [ -z "$status" ] && status="draft"

  updated_raw="$(ask 'Updated date (YYYY-MM-DD) (optional)' "${today:-$(date +%F)}")"
  updated="$(_trim "$updated_raw")"

  esc_created="$(_escape_q "$created")"
  esc_updated="$(_escape_q "$updated")"
  esc_status="$(_escape_q "$status")"

  cat <<EOF
type: note
tags: [${tags}]
status: ${esc_status}

# OPTIONAL FIELDS
updated: ${esc_updated}
source:
related:
EOF
}

# command fields collector
get_command_fields() {
  local cmd_name_raw tech_raw tags_raw status_raw source_raw date_tested_raw platform_raw related_raw
  cmd_name_raw="$(ask 'Command name (required, e.g., Find Untagged Files)' '')"
  cmd_name="$(_trim "$cmd_name_raw")"
  # ensure non-empty; if empty, prompt until provided
  while [ -z "$cmd_name" ]; do
    cmd_name_raw="$(ask 'Command name (required, e.g., Find Untagged Files)' '')"
    cmd_name="$(_trim "$cmd_name_raw")"
  done

  if declare -f choose_one >/dev/null 2>&1; then
    tech_raw="$(choose_one 'Technology' bash docker git python kubectl aws-cli || true)"
  else
    tech_raw="$(ask 'Technology (bash/docker/git/python/kubectl/aws-cli)' 'bash')"
  fi
  technology="$(_trim "$tech_raw")"

  tags_raw="$(ask 'Tags (comma-separated, default: cli, utility, workflow)' 'cli, utility, workflow')"
  tags="$(_fmt_tags "$tags_raw")"

  if declare -f choose_one >/dev/null 2>&1; then
    status_raw="$(choose_one 'Status' active deprecated testing || true)"
  else
    status_raw="$(ask 'Status (active/deprecated/testing)' 'active')"
  fi
  status="$(_trim "$status_raw")"
  [ -z "$status" ] && status="active"

  source_raw="$(ask 'Source file (optional, path to script if stored)' '')"
  source_file="$(_trim "$source_raw")"

  date_tested_raw="$(ask 'Date tested (YYYY-MM-DD)' "${today:-$(date +%F)}")"
  date_tested="$(_trim "$date_tested_raw")"

  if declare -f choose_one >/dev/null 2>&1; then
    platform_raw="$(choose_one 'Platform' 'Linux' 'macOS' 'Windows' 'Cross-Platform' || true)"
  else
    platform_raw="$(ask 'Platform (Linux/macOS/Windows/Cross-Platform)' 'Linux')"
  fi
  platform="$(_trim "$platform_raw")"

  related_raw="$(ask 'Related topic (wikilink or comma-separated)' '')"
  related_topic="$(_trim "$related_raw")"

  # escape textual fields
  local esc_cmd esc_related
  esc_cmd="$(_escape_q "$cmd_name")"
  esc_related="$(_escape_q "$related_topic")"

  cat <<EOF
type: command
tags: [${tags}]
command-name: "${esc_cmd}"
technology: ${technology}

# ACTIONABLE FIELDS
status: ${status}
source-file: "${source_file}"
date-tested: ${date_tested}

# CONTEXTUAL FIELDS
platform: ${platform}
related-topic: "${esc_related}"
EOF
}

# Collector for book notes
get_book_fields() {
  local title_raw authors_raw authors isbn_raw year_raw status_raw rating_raw summary_raw

  if [ -n "${TITLE:-}" ]; then
    book_title="$(_trim "$TITLE")"
  else
    title_raw="$(ask 'Book title (required)' '')"
    while [ -z "${title_raw// /}" ]; do
      title_raw="$(ask 'Book title (required)' '')"
    done
    book_title="$(_trim "$title_raw")"
  fi

  authors_raw="$(ask 'Authors (comma-separated)' '')"
  authors="$(_fmt_quoted_array "$authors_raw")"

  isbn_raw="$(ask 'ISBN (optional)' '')"
  isbn="$(_trim "$isbn_raw")"

  year_raw="$(ask 'Year (YYYY)' "$(date +%Y)")"
  year="$(_trim "$year_raw")"

  if declare -f choose_one >/dev/null 2>&1; then
    status_raw="$(choose_one 'Status' finished 'in-progress' abandoned planned || true)"
  else
    status_raw="$(ask 'Status (finished/in-progress/abandoned/planned)' 'finished')"
  fi
  status="$(_trim "$status_raw")"

  rating_raw="$(ask 'Rating (1-5)' '5')"
  rating="$(_trim "$rating_raw")"

  summary_raw="$(ask 'Summary note wikilink (optional)' '')"
  summary="$(_trim "$summary_raw")"

  # escape fields
  esc_title="$(_escape_q "$book_title")"
  esc_isbn="$(_escape_q "$isbn")"
  esc_summary="$(_escape_q "$summary")"

  cat <<EOF
type: book
tags: [source/book, reading-list]
author: ${authors}

# BOOK-SPECIFIC FIELDS
isbn: "${esc_isbn}"
year: ${year}
status: ${status}
rating: ${rating}
my-summary: ${summary:+"${esc_summary}"}
EOF
}

# Collector for podcast notes
get_podcast_fields() {
  local title_raw podcast_raw host_raw episode_raw date_raw url_raw topics_raw ts_raw

  if [ -n "${TITLE:-}" ]; then
    ep_title="$(_trim "$TITLE")"
  else
    title_raw="$(ask 'Episode title (required)' '')"
    while [ -z "${title_raw// /}" ]; do
      title_raw="$(ask 'Episode title (required)' '')"
    done
    ep_title="$(_trim "$title_raw")"
  fi

  podcast_raw="$(ask 'Podcast name (required)' '')"
  while [ -z "${podcast_raw// /}" ]; do
    podcast_raw="$(ask 'Podcast name (required)' '')"
  done
  podcast_name="$(_trim "$podcast_raw")"

  host_raw="$(ask 'Host (optional)' '')"
  host="$(_trim "$host_raw")"

  episode_raw="$(ask 'Episode number (optional)' '')"
  episode="$(_trim "$episode_raw")"

  date_raw="$(ask 'Date listened (YYYY-MM-DD)' "${today:-$(date +%F)}")"
  date_listened="$(_trim "$date_raw")"

  url_raw="$(ask 'URL (optional)' '')"
  url="$(_trim "$url_raw")"

  topics_raw="$(ask 'Topics (comma-separated)' '')"
  topics="$(_fmt_tags "$topics_raw")"

  ts_raw="$(ask 'Key time stamp (HH:MM or MM:SS) (optional)' '')"
  ts="$(_trim "$ts_raw")"

  esc_title="$(_escape_q "$ep_title")"
  esc_podcast="$(_escape_q "$podcast_name")"
  esc_host="$(_escape_q "$host")"
  esc_url="$(_escape_q "$url")"
  esc_ts="$(_escape_q "$ts")"

  cat <<EOF
type: podcast
tags: [source/audio, media/podcast]
podcast-name: "${esc_podcast}"
host: "${esc_host}"
episode: ${episode}
date-listened: ${date_listened}

# OPTIONAL FIELDS
url: "${esc_url}"
topics: [${topics}]
time-stamp: "${esc_ts}"
EOF
}

# Collector for web link/clipping notes
get_link_fields() {
  local url_raw date_raw site_raw author_raw summary_raw tags_raw topics

  url_raw="$(ask 'URL (required, include https://)' '')"
  while [ -z "${url_raw// /}" ]; do
    url_raw="$(ask 'URL (required, include https://)' '')"
  done
  url="$(_trim "$url_raw")"

  date_raw="$(ask 'Date clipped (YYYY-MM-DD)' "${today:-$(date +%F)}")"
  date_clipped="$(_trim "$date_raw")"

  site_raw="$(ask 'Site (optional)' '')"
  site="$(_trim "$site_raw")"

  author_raw="$(ask 'Author (optional)' '')"
  author="$(_trim "$author_raw")"

  summary_raw="$(ask 'Summary (optional)' '')"
  summary="$(_trim "$summary_raw")"

  # default tags for link notes
  tags_raw="$(ask 'Tags (comma-separated, default: web/clipping, reference)' 'web/clipping, reference')"
  tags="$(_fmt_tags "$tags_raw")"

  esc_url="$(_escape_q "$url")"
  esc_site="$(_escape_q "$site")"
  esc_author="$(_escape_q "$author")"
  esc_summary="$(_escape_q "$summary")"

  cat <<EOF
type: link
tags: [${tags}]
url: "${esc_url}"
date-clipped: ${date_clipped}

# OPTIONAL FIELDS
site: "${esc_site}"
author: "${esc_author}"
summary: "${esc_summary}"
EOF
}

# Collector for install/installation-guide notes
get_install_fields() {
  local software_raw version_raw status_raw date_raw dependency_raw os_raw installer_raw link_raw tags_raw

  software_raw="$(ask 'Software name (required, e.g. Dataview Plugin / NodeJS / PostgreSQL)' '')"
  while [ -z "${software_raw// /}" ]; do
    software_raw="$(ask 'Software name (required, e.g. Dataview Plugin / NodeJS / PostgreSQL)' '')"
  done
  software_name="$(_trim "$software_raw")"

  version_raw="$(ask 'Version (optional, e.g. 0.5.64)' '')"
  version="$(_trim "$version_raw")"

  if declare -f choose_one >/dev/null 2>&1; then
    status_raw="$(choose_one 'Status' stable pending-upgrade broken obsolete || true)"
  else
    status_raw="$(ask 'Status (stable / pending-upgrade / broken / obsolete)' 'stable')"
  fi
  status="$(_trim "$status_raw")"

  date_raw="$(ask 'Date installed (YYYY-MM-DD)' "${today:-$(date +%F)}")"
  date_installed="$(_trim "$date_raw")"

  dependency_raw="$(ask 'Dependency of (wikilink to project note) (optional)' '')"
  dependency_of="$(_trim "$dependency_raw")"

  os_raw="$(ask 'OS (optional, e.g. macOS-Sonoma)' '')"
  os="$(_trim "$os_raw")"

  installer_raw="$(ask 'Installer (brew/apt/pip/npm/manual-download) (optional)' 'brew')"
  installer="$(_trim "$installer_raw")"

  link_raw="$(ask 'Link (documentation or download URL) (optional)' '')"
  link_val="$(_trim "$link_raw")"

  tags_raw="$(ask 'Tags (comma-separated, default: setup, environment, configuration)' 'setup, environment, configuration')"
  tags="$(_fmt_tags "$tags_raw")"

  esc_software="$(_escape_q "$software_name")"
  esc_version="$(_escape_q "$version")"
  esc_installer="$(_escape_q "$installer")"
  esc_link="$(_escape_q "$link_val")"
  esc_dependency="$(_escape_q "$dependency_of")"
  esc_os="$(_escape_q "$os")"

  cat <<EOF
type: install-guide
tags: [${tags}]
software-name: "${esc_software}"
version: "${esc_version}"

# ACTIONABLE FIELDS
status: ${status}
date-installed: ${date_installed}
dependency-of: ${esc_dependency}

# CONTEXTUAL FIELDS
os: "${esc_os}"
installer: "${esc_installer}"
link: "${esc_link}"
EOF
}

editor="${EDITOR:-vim}"
today="$(date '+%Y-%m-%d')"

CATEGORY="training"
PROJECT=""

print_usage() {
  cat <<EOF
Usage: $0 -t "Note Title" [-c Category] [-p Project] [-v /path/to/vault] [-n]

Options:
  -t    Title of the note (required)
  -c    Category (training, journal, command, note)
  -p    Project name to associate (optional)
  -v    Path to Obsidian vault (default: value from lib.sh)
  -n    No editor (do not open the created file)
  -h    Show this help message
EOF
}


# Parse options: -t title -c category -v vault -n no-editor -h help
TITLE=""
CATEGORY=""
NO_EDITOR=""
while getopts ":t:c:v:nh" opt; do
  case $opt in
    t) TITLE="$OPTARG" ;;
    c) CATEGORY="$OPTARG" ;;
    v) VAULT_DIR="$OPTARG" ;;
    n) NO_EDITOR=1 ;;
    h) echo "Usage: $0 [-t title] [-c training|journal|command|note] [-v vault_dir] [-n no-editor]"; exit 0 ;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
  esac
done
shift $((OPTIND-1))

# Ensure VAULT_DIR is set (honour -v) and place note dirs under it
: "${VAULT_DIR:=$(realpath "$SCRIPT_DIR/..")}"
NOTE_DIR="${VAULT_DIR%/}/Zettelkasten"
DAILY_NOTE_DIR="${VAULT_DIR%/}/00-Journal/00-A-Daily Notes"

# ask for category if not provided (include command)
if [ -z "$CATEGORY" ]; then
  if declare -f choose_one >/dev/null 2>&1; then
    CATEGORY="$(choose_one 'Category' training journal command note book podcast link install || true)"
  else
    CATEGORY="$(ask 'Category (training/journal/command/note/book/podcast/link/install)' 'training')"
  fi
fi
CATEGORY="${CATEGORY,,}"  # lowercase

if [ -z "$TITLE" ]; then
  if declare -f ask >/dev/null 2>&1; then
    TITLE="$(ask 'Title'  || true)"
  else
    TITLE="$(ask 'Title' 'Note')"
  fi
fi

if [ "$CATEGORY" = "training" ]; then
  FRONTMATTER="$(get_training_fields)"
elif [ "$CATEGORY" = "journal" ]; then
  FRONTMATTER="$(get_journal_fields)"
elif [ "$CATEGORY" = "command" ]; then
  FRONTMATTER="$(get_command_fields)"
elif [ "$CATEGORY" = "note" ]; then
  FRONTMATTER="$(get_note_fields)"
elif [ "$CATEGORY" = "book" ]; then
  FRONTMATTER="$(get_book_fields)"
elif [ "$CATEGORY" = "podcast" ]; then
  FRONTMATTER="$(get_podcast_fields)"
elif [ "$CATEGORY" = "link" ]; then
  FRONTMATTER="$(get_link_fields)"
elif [ "$CATEGORY" = "install" ]; then
  FRONTMATTER="$(get_install_fields)"
else
  FRONTMATTER=""
fi

sanitize_filename() {
  # replace slashes and other problematic chars with -, collapse multiple -,
  # and trim leading/trailing spaces
  local s
  s="$(printf '%s' "$1" | sed 's/[\/:\\*?"<>|]/-/g' | sed 's/  */ /g' | sed 's/^ //; s/ $//')"
  printf '%s' "$s"
}



# prepare filename
CATEGORY_CAP="${CATEGORY^}"
CATEGORY_DISPLAY=$(echo "$CATEGORY_CAP" | sed 's/[^[:alnum:] ]//g' | sed 's/  */ /g' | sed 's/ $//')
CLEAN_TITLE="$(sanitize_filename "$TITLE")"
FILENAME="${CATEGORY_DISPLAY} - ${CLEAN_TITLE}.md"
FILEPATH="${NOTE_DIR%/}/${FILENAME}"

# avoid accidental overwrite
if [ -e "$FILEPATH" ]; then
  i=1
  # This will strip .md from filepath
  base="${FILEPATH%.md}"
  while [ -e "${base} ($i).md" ]; do i=$((i + 1)); done
  FILEPATH="${base} ($i).md"
  FILENAME="$(basename "$FILEPATH")"
fi
#
# write frontmatter
DATE_YMD=$(date +"%Y-%m-%d")
mkdir -p "$(dirname "$FILEPATH")"
cat > "$FILEPATH" <<EOF
---
title: ${FILENAME%.md}
created: $(date +"%Y-%m-%d %H:%M:%S")
$( [ -n "$FRONTMATTER" ] && printf '%s\n' "$FRONTMATTER" )
---

# ${FILENAME%.md}

Created: ${DATE_YMD}

Daily: [[${DATE_YMD}]]

EOF

# Update daily note (add a wiki-link) using the shared helper
# Pass the category and the wiki link (filename without .md)
WIKILINK="${FILENAME%.md}"
update_daily_note_with_link "$CATEGORY" "$WIKILINK" "$DAILY_NOTE_DIR"

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

# Open the new note in editor (prefer $EDITOR, fallback to vim/vi)
if [ -z "${NO_EDITOR:-}" ]; then
  editor="${EDITOR:-vim}"
  if command -v "$editor" >/dev/null 2>&1; then
    "$editor" + "$FILEPATH"
  elif command -v vim >/dev/null 2>&1; then
    vim + "$FILEPATH"
  else
    vi + "$FILEPATH"
  fi
else
  echo "Skipping editor (NO_EDITOR set)."
fi
