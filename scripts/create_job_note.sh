#!/bin/bash
# Minimal bootstrap: locate `lib.sh` and source it
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib.sh"

# Usage: ./create_job_note.sh --job "Job Title" --company "Company Name" [--link URL] [--notes "...]

JOBS_DIR="01-Projects/Jobs"
DAILY_DIR="00-Journal/00-A-Daily Notes"

# Get job title and company from arguments
JOB_TITLE=""
COMPANY=""
LINK=""
NOTES=""

while [[ "$#" -gt 0 ]]; do
  case $1 in 
    -j|--job) JOB_TITLE="$2"; shift;;
    -c|--company) COMPANY="$2"; shift;;
    -l|--link) LINK="$2"; shift ;;
    -n|--notes) NOTES="$2"; shift ;;
    *) echo "Unknown parameter: $1"; exit 1;;
  esac
  shift
done

if [[ -z "$JOB_TITLE" || -z "$COMPANY" ]]; then
  echo "Error: --job and --company are required."
  exit 1
fi


DATE_YMD=$(date +"%Y-%m-%d")


# Sanitize filename (replace spaces with underscores)
SAFE_JOB_TITLE=$(echo "$JOB_TITLE" | sed 's/ /_/g')
SAFE_COMPANY=$(echo "$COMPANY" | sed 's/ /_/g')
JOB_FILENAME="${DATE_YMD} - ${SAFE_JOB_TITLE} - ${SAFE_COMPANY}.md"
JOB_PATH="${JOBS_DIR}/${JOB_FILENAME}"
DAILY_PATH="${DAILY_DIR}/${DATE_YMD}.md"


mkdir -p "$JOBS_DIR"
mkdir -p "$DAILY_DIR"

# Create the file with a basic template
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


# Update Daily Note: use central helper (pass category and wikilink without .md)
WIKILINK="${JOB_FILENAME%.md}"
update_daily_note_with_link "Jobs" "$WIKILINK" "$DAILY_DIR"
## Contacts
