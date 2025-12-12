#!/bin/bash
# Minimal bootstrap: locate `lib.sh` and source it
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib.sh"

if [ "$1" = "-h" ]; then
  echo "Usage: $0 [<number of entries>] [pattern]"
  echo "  number of entries: how many results to show (default 10)"
  echo "  pattern: optional ripgrep pattern to filter file contents"
  exit 0
fi

entries=${1:-10}
pattern=${2:-}

# Gather files ordered by modification time (newest first)
mapfile -t files < <(find . \( -path './.git' -o -path './.obsidian' \) -prune -o -type f -printf '%T@ %TY-%Tm-%Td %p\n' | sort -r | cut -d ' ' -f 3-)

filtered=()
if [ -n "$pattern" ]; then
  for f in "${files[@]}"; do
    # Use ripgrep if available for speed; fall back to grep
    if command -v rg >/dev/null 2>&1; then
      if rg -q --hidden --no-messages -- "$pattern" "$f" 2>/dev/null; then
        filtered+=("$f")
      fi
    else
      if grep -Iq -- "$pattern" "$f" 2>/dev/null; then
        filtered+=("$f")
      fi
    fi
  done
else
  filtered=("${files[@]}")
fi

# Limit to requested number of entries
selected_list=("${filtered[@]:0:${entries}}")

# Send to fzf helper (strip leading ./ and the leading date prefix)
# Input lines are like: "YYYY-MM-DD ./path/to/file.md" — we want to
# present and pass only the path portion to the preview helper.
printf '%s\n' "${selected_list[@]}" \
  | sed 's@^\./@@' \
  | sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]+//' \
  | fzf_choose_with_follow "📓 Notes > " "down:50%"
