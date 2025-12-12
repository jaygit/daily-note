#!/usr/bin/env sh
# Small extractor that prints wiki-style [[inner]] labels, one per line.
# Uses awk to find multiple occurrences per line and preserves first-seen order.
if [ "$#" -lt 1 ]; then
  exit 0
fi
src="$1"
awk '
{
  s = $0
  while (match(s, /\[\[([^\]]+)\]\]/, m)) {
    if (!seen[m[1]]++) print m[1]
    s = substr(s, RSTART + RLENGTH)
  }
}
' "$src"
