#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib.sh"

# Print discovered version. Lookup order:
# 1. env var VERSION
# 2. RELEASE_NOTES/v.*.md files (pick highest via sort -V)
# 3. git tag (closest annotated/tag)
# 4. fallback 'unknown'
get_version() {
  if [ -n "${VERSION:-}" ]; then
    printf '%s\n' "$VERSION"
    return 0
  fi
  # check RELEASE_NOTES directory relative to repo root
  if compgen -G "$SCRIPT_DIR/../RELEASE_NOTES/v.*.md" >/dev/null 2>&1; then
    ver=$(ls "$SCRIPT_DIR/../RELEASE_NOTES"/v.*.md 2>/dev/null | xargs -n1 basename | sed 's/\.md$//' | sort -V | tail -n1)
    if [ -n "$ver" ]; then
      printf '%s\n' "$ver"
      return 0
    fi
  fi
  # try git tag
  if git -C "$SCRIPT_DIR/.." rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git describe --tags --abbrev=0 2>/dev/null && return 0
  fi
  printf 'unknown\n'
}

# Support -v / --version early so `obs -v` or `obs --version` works.
for a in "$@"; do
  case "$a" in
    -v|--version)
      get_version
      exit 0
      ;;
  esac
done

usage() {
  local exit_code=${1:-1}
  cat <<EOF
Usage: $0 -o <operation> [--] [args...]

Options:
  -o <op>      Operation to run. One of: job, note, git, hist, search, diary
  -h, --help   Show this help and exit

Any remaining args after the options are passed to the chosen script.
Examples:
  $0 -o job -- -c "Bearing" -s
  $0 -o note -- -t "My Note"
EOF
  exit "$exit_code"
}

# No args -> show help (successful)
if [ $# -eq 0 ]; then
  usage 0
fi

OP=""

# support short options via getopts and a simple --help long option
# note: getopts with -: allows simple handling of --long
while getopts ":o:h-:" opt; do
  if [ "$opt" = "-" ]; then
    case "$OPTARG" in
      help) usage 0 ;;
      *) echo "Unknown option: --$OPTARG" >&2; usage ;;
    esac
  else
    case "$opt" in
      o) OP="$OPTARG" ;;
      h) usage 0 ;;
      \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
      :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
    esac
  fi
done
shift $((OPTIND - 1))

if [ -z "$OP" ]; then
  echo "Error: -o <operation> is required." >&2
  usage
fi

case "${OP}" in
  job)
    exec "$SCRIPT_DIR/jobs.sh" "$@"
    ;;
  note)
    exec "$SCRIPT_DIR/create_note.sh" "$@"
    ;;
  git)
    exec "$SCRIPT_DIR/gitnotes.sh" "$@"
    ;;
  search)
    exec "$SCRIPT_DIR/search.sh" "$@"
    ;;
  diary)
    exec "$SCRIPT_DIR/search.sh" diary "$@"
    ;;
  hist)
    exec "$SCRIPT_DIR/histnotes.sh" "$@"
    ;;
  *)
    echo "Unknown operation: ${OP}" >&2
    usage
    ;;
esac
