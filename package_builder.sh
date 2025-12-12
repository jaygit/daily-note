#!/usr/bin/env bash
set -euo pipefail

# Build a tar.gz package containing scripts, tests, README, release notes, install.sh and samples/
VERSION="v.1.0.0"
DIST_DIR="dist"
STAGING="$DIST_DIR/daily-notes-$VERSION"

rm -rf "$STAGING"
mkdir -p "$STAGING"

# copy core files
cp -a scripts "$STAGING/"
cp -a tests "$STAGING/"
cp README.md "$STAGING/"
mkdir -p "$STAGING/RELEASE_NOTES"
cp RELEASE_NOTES/v.1.0.0.md "$STAGING/RELEASE_NOTES/"
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
