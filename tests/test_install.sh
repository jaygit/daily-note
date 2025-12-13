#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG_ROOT="$ROOT"

echo "Running install.sh non-interactive tests"

TMP_DATA=$(mktemp -d)
TMP_BIN=$(mktemp -d)
TMP_PREFIX="$TMP_DATA/daily-note"

export XDG_DATA_HOME="$TMP_DATA"
export XDG_BIN_HOME="$TMP_BIN"

# Run installer with --yes (install sample vault)
bash "$PKG_ROOT/install.sh" --yes

# Verify obs shim created
if [ ! -x "$TMP_BIN/obs" ]; then
  echo "obs shim missing: $TMP_BIN/obs" >&2
  exit 2
fi

SCRIPTS_DIR="$TMP_PREFIX/scripts"
ENV_FILE="$SCRIPTS_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo ".env not found at $ENV_FILE" >&2
  exit 2
fi

# VAULT_DIR should point to sample vault
VAULT_DIR_VAL=$(sed -n 's/^VAULT_DIR=//p' "$ENV_FILE" | tr -d '"')
if [ -z "$VAULT_DIR_VAL" ]; then
  echo "VAULT_DIR not written to .env" >&2
  exit 2
fi

if [ ! -d "$VAULT_DIR_VAL" ]; then
  echo "Sample vault directory not present: $VAULT_DIR_VAL" >&2
  exit 2
fi

echo "Sample vault install test passed."

# Now test --vault-path with an existing vault
TMP_VAULT=$(mktemp -d)
bash "$PKG_ROOT/install.sh" --vault-path "$TMP_VAULT"

ENV_FILE="$SCRIPTS_DIR/.env"
VAULT_DIR_VAL2=$(sed -n 's/^VAULT_DIR=//p' "$ENV_FILE" | tr -d '"' || true)
if [ "$VAULT_DIR_VAL2" != "$TMP_VAULT" ]; then
  echo "Expected VAULT_DIR=$TMP_VAULT, got: $VAULT_DIR_VAL2" >&2
  exit 2
fi

echo "Existing vault path test passed."

rm -rf "$TMP_DATA" "$TMP_BIN" "$TMP_VAULT"

echo "install.sh tests completed successfully"
