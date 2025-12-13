#!/usr/bin/env bash
set -euo pipefail

# Build a tar.gz package containing scripts, tests, README, release notes, install.sh and samples/
# VERSION is taken from $VERSION env or the latest RELEASE_NOTES/v.*.md file or git tag
DIST_DIR="dist"

if [ -n "${VERSION:-}" ]; then
	echo "Using VERSION from environment: $VERSION"
else
	if ls RELEASE_NOTES/v.*.md >/dev/null 2>&1; then
		# pick the highest semantic version by numeric sort
		VERSION=$(ls RELEASE_NOTES/v.*.md | sed -E 's#.*/(v[0-9]+\.[0-9]+\.[0-9]+)\.md#\1#' | sort -V | tail -n1)
		echo "Discovered VERSION from RELEASE_NOTES: $VERSION"
	else
		# fallback to latest git tag, or default
		VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "v.0.0.0")
		echo "Using VERSION from git or fallback: $VERSION"
	fi
fi

STAGING="$DIST_DIR/daily-notes-$VERSION"

rm -rf "$STAGING"
mkdir -p "$STAGING"

# copy core files
cp -a scripts "$STAGING/"
cp -a tests "$STAGING/"
cp README.md "$STAGING/"
mkdir -p "$STAGING/RELEASE_NOTES"
if [ -f "RELEASE_NOTES/${VERSION}.md" ]; then
	cp "RELEASE_NOTES/${VERSION}.md" "$STAGING/RELEASE_NOTES/"
else
	# if exact release note missing, copy all release notes as fallback
	cp -a RELEASE_NOTES/* "$STAGING/RELEASE_NOTES/" || true
fi
cp install.sh "$STAGING/"

# create samples
mkdir -p "$STAGING/samples/00-Journal/00-A-Daily Notes"
mkdir -p "$STAGING/samples/Zettelkasten"
mkdir -p "$STAGING/samples/Jobs"

cat > "$STAGING/samples/00-Journal/00-A-Daily Notes/2025-12-12.md" <<'EOF'
---
title: Daily - 2025-12-12
created: 2025-12-12
mood: productive
tags: [daily]
---

# Morning

Started the day with a small scripting task.
EOF

cat > "$STAGING/samples/Zettelkasten/Note - Sample.md" <<'EOF'
---
title: Note - Sample
created: 2025-12-12
type: note
tags: [zettelkasten, sample]
status: draft
---

A sample zettelkasten note.
EOF

cat > "$STAGING/samples/Zettelkasten/sample-podcast-episode.md" <<'EOF'
---
type: podcast
podcast-name: Sample Cast
episode: 42
host: Host Name
date-listened: 2025-12-11
url: https://example.org/episode/42
topics: [scripting, devops]
---

Notes from the episode.
EOF

cat > "$STAGING/samples/Zettelkasten/sample-link.md" <<'EOF'
---
type: link
url: "https://example.org/some-article"
date-clipped: 2025-12-10
site: example.org
author: Jane Doe
summary: "Short summary of article"
tags: [web/clipping, reference]
---

Saved link for later reading.
EOF

cat > "$STAGING/samples/Zettelkasten/sample-training.md" <<'EOF'
---
type: training
title: Sample Training
project: Demo
status: in-progress
created: 2025-12-10
---

Training notes and exercises.
EOF

cat > "$STAGING/samples/Jobs/sample-jobnote.md" <<'EOF'
---
title: Job - Sample
status: open
---

Sample job note content.
EOF

# create the tar.gz
mkdir -p "$DIST_DIR"
TARFILE="$DIST_DIR/daily-notes-$VERSION.tar.gz"

echo "Creating package $TARFILE"

tar -C "$DIST_DIR" -czf "$TARFILE" "daily-notes-$VERSION"

echo "Package created: $TARFILE"
