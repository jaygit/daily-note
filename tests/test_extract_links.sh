#!/usr/bin/env bash
set -euo pipefail

# Test the shell/awk link extractor: scripts/_extract_links.sh
ROOT_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")"
SCRIPTS_DIR="$ROOT_DIR/scripts"

TMPROOT="$(mktemp -d)"
NOTE="$TMPROOT/note.md"

cat > "$NOTE" <<'EOF'
Intro [[Alpha]] and [[Beta]]
Also [[Alpha]]
End with [[Gamma]] and [[Delta]] and [[Epsilon]]
Same-line [[One]][[Two]]
EOF

expected=$(cat <<'EOF'
Alpha
Beta
Gamma
Delta
Epsilon
One
Two
EOF
)

echo "Running extractor against: $NOTE"
out=$(sh "$SCRIPTS_DIR/_extract_links.sh" "$NOTE")

if [ "$out" != "$expected" ]; then
  echo "FAIL: extractor output did not match expected"
  echo "--- expected ---"
  echo "$expected"
  echo "--- got ---"
  echo "$out"
  rm -rf "$TMPROOT"
  exit 1
fi

echo "OK: extractor output matches expected"
rm -rf "$TMPROOT"
exit 0
