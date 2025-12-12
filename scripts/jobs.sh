#!/bin/bash
# Minimal bootstrap: locate `lib.sh` and source it
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib.sh"

# CONFIGURATION: jobs folder relative to vault
JOBS_DIR="01-Projects/Jobs"
DAILY_DIR="00-Journal/00-A-Daily Notes"
STATUS_LABELS=("Applied" "Interviewed" "Offer" "Rejected")

usage () {
  cat <<EOF
Usage:
  $0 -a|--add [add options]
  $0 -q|--query [query options]

Modes:
  -a|--add      Add a new job note. Remaining options are for creation.
  -q|--query    Query existing job notes. Remaining options control filtering and status.

Add options:
  -j|--job "Job Title"     (required for add)
  -c|--company "Company"    (required for add)
  -l|--link "URL"
  -n|--notes "Notes text"

Query options:
  -l|--list                 List matching job notes (default for query)
  -d|--date YYYY-MM-DD      Filter by date
  -j|--job <regexp>         Filter by job title (regexp)
  -c|--company <regexp>     Filter by company (regexp)
  -s|--status [status]      If no status arg, shows application status for matching notes. If provided (comma-separated), updates status for matches.
  -h|--help                 Show this help

Examples:
  $0 -a -j "SRE" -c "ExampleCorp" -l "https://..."
  $0 -q -j "SRE" -c "ExampleCorp"
  $0 -q -s "Interviewed" -j "SRE"
EOF
}

# Function to list job notes (not used directly but kept)
list_notes() {
  find "$VAULT_DIR/$JOBS_DIR" -type f -name "*.md" | grep -E '[0-9]{4}-[0-9]{2}-[0-9]{2} - .* - .*\.md' || true
}

# Function to get status from a note (accepts filename or full path)
get_status() {
  local file="$1"
  if [[ ! "$file" =~ ^/ ]]; then
    file="$VAULT_DIR/$JOBS_DIR/$file"
  fi
  if [ ! -f "$file" ]; then
    echo "File not found: $file"
    return 1
  fi
  echo "Status for: $(basename "$file")"
  awk '
    BEGIN { in_section=0 }
    /^## Application Status/ { in_section=1; next }
    /^## / && in_section { exit }
    in_section && /^\- \[[xX]\] / { print $0 }
  ' "$file"
  echo ""
}

# Function to find files by date, job or company (returns full paths)
find_file() {
  local date="$1"
  local job_regex="$2"
  local company_regex="$3"

  job_regex="${job_regex,,}"
  company_regex="${company_regex,,}"

  while IFS= read -r -d '' file; do
    filename=$(basename "$file")
    if [[ "$filename" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})\ -\ (.+)\ -\ (.+)\.md$ ]]; then
      file_date="${BASH_REMATCH[1]}"
      file_job="${BASH_REMATCH[2]}"
      file_company="${BASH_REMATCH[3]}"
      file_job="${file_job,,}"
      file_company="${file_company,,}"

      match=true
      [[ -n "$date" && "$file_date" != "$date" ]] && match=false
      [[ -n "$job_regex" && ! "$file_job" =~ $job_regex ]] && match=false
      [[ -n "$company_regex" && ! "$file_company" =~ $company_regex ]] && match=false

      if [[ "$match" == true ]]; then
        echo "$file"
      fi
    fi
  done< <(find "$VAULT_DIR/$JOBS_DIR" -type f -name "*.md" -print0)
}

# Function to update status in a note (file path accepted)
update_status() {
  local file="$1"
  shift
  declare -A new_status
  for status in "${STATUS_LABELS[@]}"; do
    new_status["$status"]=" "
  done
  for arg in "$@"; do
    new_status["$arg"]="x"
  done

  awk -v applied="${new_status[Applied]}" \
      -v interviewed="${new_status[Interviewed]}" \
      -v offer="${new_status[Offer]}" \
      -v rejected="${new_status[Rejected]}" '
    BEGIN { in_section=0 }
    /^## Application Status/ {
      in_section=1
      print
      getline
      while ($0 ~ /^\- \[[ xX]\] /) { getline }
      print "- [" applied     "] Applied"
      print "- [" interviewed "] Interviewed"
      print "- [" offer       "] Offer"
      print "- [" rejected    "] Rejected"
      in_section=0
    }
    !in_section { print }
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  echo "Updated: $(basename "$file")"
}

# Create a job note (used for add mode)
create_job_note() {
  local JOB_TITLE=""
  local COMPANY=""
  local LINK=""
  local NOTES=""

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -j|--job) JOB_TITLE="$2"; shift 2;;
      -c|--company) COMPANY="$2"; shift 2;;
      -l|--link) LINK="$2"; shift 2;;
      -n|--notes) NOTES="$2"; shift 2;;
      *) echo "Unknown parameter for add: $1"; return 1;;
    esac
  done

 # If required CLI options weren't provided, prompt interactively using helpers from lib.sh
  while [ -z "$JOB_TITLE" ]; do
    JOB_TITLE="$(ask "Job Title (required)" "")"
    JOB_TITLE="${JOB_TITLE:-}"
  done

  while [ -z "$COMPANY" ]; do
    COMPANY="$(ask "Company (required)" "")"
    COMPANY="${COMPANY:-}"
  done

  # optional fields: prompt if not provided (allow empty)
  if [ -z "$LINK" ]; then
    LINK="$(ask "Link (optional)" "")"
  fi
  if [ -z "$NOTES" ]; then
    NOTES="$(ask "Notes (optional)" "")"
  fi

  DATE_YMD=$(date +"%Y-%m-%d")
  SAFE_JOB_TITLE=$(echo "$JOB_TITLE" | sed 's/ /_/g')
  SAFE_COMPANY=$(echo "$COMPANY" | sed 's/ /_/g')
  JOB_FILENAME="${DATE_YMD} - ${SAFE_JOB_TITLE} - ${SAFE_COMPANY}.md"
  JOB_PATH="$VAULT_DIR/$JOBS_DIR/$JOB_FILENAME"

  mkdir -p "$VAULT_DIR/$JOBS_DIR"

  cat <<EOF > "$JOB_PATH"
# $JOB_TITLE at $COMPANY
**Date:** [[${DATE_YMD}]]
**Link:** [${JOB_TITLE}](${LINK})

## Description
(Write your notes here)
${NOTES:-none}

## Application Status
- [X] Applied
- [ ] Interviewed
- [ ] Offer
- [ ] Rejected

## Contacts
- Name:
- Email:
- Notes:
EOF

  echo "Note created: $JOB_PATH"

  WIKILINK="${JOB_FILENAME%.md}"
  update_daily_note_with_link "Jobs" "$WIKILINK" "$DAILY_DIR"
}

# ----- Main: require a mode (-a or -q) -----
if [ $# -eq 0 ]; then
  usage
  exit 1
fi

MODE=""
case "$1" in
  -a|--add) MODE=add; shift;;
  -q|--query) MODE=query; shift;;
  -h|--help) usage; exit 0;;
  *) echo "Missing mode: please specify -a (add) or -q (query)" >&2; usage; exit 2;;
esac

if [ "$MODE" = "add" ]; then
  create_job_note "$@" && exit 0 || exit 1
fi

if [ "$MODE" = "query" ]; then
  # parse query options
  date=""
  job_regex=""
  company_regex=""
  status=""
  list_flag=true
  help=false

  while [ $# -gt 0 ]; do
    case "$1" in
      -d|--date) date="$2"; shift 2;;
      -j|--job) job_regex="$2"; shift 2;;
      -c|--company) company_regex="$2"; shift 2;;
      -s|--status)
          if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
            status="$2"; shift 2
          else
            status="show"; shift
          fi
          ;;
      -l|--list) list_flag=true; shift;;
      -h|--help) help=true; shift;;
      *) echo "Unknown query option: $1"; exit 3;;
    esac
  done

  if [ "$help" = true ]; then
    usage; exit 0
  fi

  # If no query options were provided on the command line, prompt interactively
  if [ -z "$date" ] && [ -z "$job_regex" ] && [ -z "$company_regex" ] && [ -z "$status" ]; then
    echo "No query filters provided — entering interactive mode."
    date="$(ask 'Date (YYYY-MM-DD) (leave empty for any)' '')"
    job_regex="$(ask 'Job title regex (leave empty for any)' '')"
    company_regex="$(ask 'Company regex (leave empty for any)' '')"

    # Ask what action to take
    if declare -f choose_one >/dev/null 2>&1; then
      action="$(choose_one 'Select action' 'List matches' 'Show status for matches' 'Update status for matches' 'Cancel')"
    else
      action="$(ask 'Action (list / show / update / cancel)' 'list')"
    fi
    case "${action,,}" in
      "list matches"|"list")
        status="";;
      "show status"|"show status for matches"|"show")
        status="show";;
      "update status"|"update")
        status="$(ask 'Enter statuses to set (comma-separated, e.g. Applied,Interviewed)')" ;;
      cancel)
        echo "Cancelled."; exit 0 ;;
      *)
        echo "Unknown action: $action"; exit 1 ;;
    esac
  fi

  # find matching files (full paths)
  mapfile -t matches < <(find_file "$date" "$job_regex" "$company_regex")

  if [ ${#matches[@]} -eq 0 ]; then
    echo "No matching job notes found."; exit 0
  fi

  if [ "$list_flag" = true ] && [ "$status" = "" ]; then
    for f in "${matches[@]}"; do
      echo "$f"
    done
    exit 0
  fi

  if [ "$status" = "show" ]; then
    for f in "${matches[@]}"; do
      get_status "$f"
    done
    exit 0
  fi

  if [ -n "$status" ]; then
    IFS=',' read -r -a status_array <<< "$status"
    for f in "${matches[@]}"; do
      update_status "$f" "${status_array[@]}"
    done
    exit 0
  fi

  usage
  exit 1
fi


