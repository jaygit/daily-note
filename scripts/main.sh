#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib.sh"

usage() {
  cat <<EOF
Usage: $0 -o <operation> [--] [args...]

Options:
  -o <op>      Operation to run. One of: job, note, git, hist
  -h, --help   Show this help and exit

Any remaining args after the options are passed to the chosen script.
Examples:
  $0 -o job -- -c "Bearing" -s
  $0 -o note -- -t "My Note"
EOF
  exit 1
}

# No args -> help
if [ $# -eq 0 ]; then
  usage
fi

OP=""

# support short options via getopts and a simple --help long option
# note: getopts with -: allows simple handling of --long
while getopts ":o:h-:" opt; do
  if [ "$opt" = "-" ]; then
    case "$OPTARG" in
      help) usage ;;
      *) echo "Unknown option: --$OPTARG" >&2; usage ;;
    esac
  else
    case "$opt" in
      o) OP="$OPTARG" ;;
      h) usage ;;
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
  hist)
    exec "$SCRIPT_DIR/histnotes.sh" "$@"
    ;;
  *)
    echo "Unknown operation: ${OP}" >&2
    usage
    ;;
esac
