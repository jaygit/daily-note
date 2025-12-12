#!/usr/bin/env bash
set -euo pipefail


usage() {
  cat <<EOF
Usage: $0 <install_dir> [DEST_DIR]

Creates a sample vault at DEST_DIR (defaults to ./Daily-Notes-Vault) by copying sample notes included in the package.

This installer expects to be run from the package root (where this script and the `samples/` directory live).

Examples:
  ./install.sh ~/daily-notes MyDailyVault
  ./install.sh  ~/daily-notes      # creates ./Daily-Notes-Vault
EOF
}

PKG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${1:-/tmp/notes}"
VAULT_NAME="${2:-Daily-Notes-Vault}"


# find tarball (prefer dist/)
TARBALL=""
for p in "$PKG_ROOT"/dist/daily-notes-*.tar.gz "$PKG_ROOT"/daily-notes-*.tar.gz; do
  for f in "$p"; do
    if [ -f "$f" ]; then
      TARBALL="$f"
      break 2
    fi
  done
done

if [ -z "$TARBALL" ]; then
  echo "Error: package tarball not found (looked for dist/daily-notes-*.tar.gz)." >&2
  echo "Place the package tar.gz next to this script or in dist/ and retry." >&2
  exit 1
fi

echo "Using package: $TARBALL"

mkdir -p "$INSTALL_DIR"
DEST="${INSTALL_DIR%/}/$VAULT_NAME"
echo "Creating vault at: $DEST"
mkdir -p "$DEST"

# extract package into a temporary directory, stripping top-level directory from tar
TMP_EXTRACT_DIR="$(mktemp -d)"
echo "Extracting package to dir: $TMP_EXTRACT_DIR"
tar -xzf "$TARBALL" -C "$INSTALL_DIR" --strip-components=1
mv "${INSTALL_DIR%/}"/samples "$DEST"

# write an internal README explaining what was installed
cat > "$DEST/README-vault.md" <<'EOF'
This vault was created by the Daily Notes package installer.

Included sample notes (if present):
- 00-Journal/00-A-Daily Notes/2025-12-12.md (daily note example)
- Zettelkasten/Note - Sample.md
- Zettelkasten/sample-podcast-episode.md
- Zettelkasten/sample-link.md
- Zettelkasten/sample-training.md
- Jobs/sample-jobnote.md

Feel free to move these files into your real Obsidian vault or use as templates.
EOF

chmod -R u+rwX,go+rX "$DEST"

echo "Cleaning temporary files..."
rm -rf "$TMP_EXTRACT_DIR"

cat <<EOF
Installation complete.
Vault root: $DEST

Open the vault in your editor or Obsidian.
EOF
