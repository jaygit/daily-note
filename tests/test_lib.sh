#!/usr/bin/env bash
set -euo pipefail

# test_lib.sh - test helpers for non-interactive CI tests
# Provides:
#   test_lib_setup <tmpdir>   - create gum stub in <tmpdir>/bin and export PATH, set NO_LINKS
#   test_lib_cleanup         - remove created test bin dir (if created)

test_lib_setup() {
  local td="${1:-$(mktemp -d)}"
  export TEST_LIB_DIR="$td"
  local gum_bin="$TEST_LIB_DIR/bin"
  mkdir -p "$gum_bin"

  cat > "$gum_bin/gum" <<'GUMSH'
#!/usr/bin/env bash
# Minimal non-interactive gum shim for tests
# Accepts common subcommands: input, choose, confirm
cmd="$1"; shift || true

# helper: extract next arg (may be empty)
next_arg() {
  local a="$1"; shift
  printf '%s' "$a"
}

case "$cmd" in
  input)
    # parse options: support --value <val> and --placeholder <text>
    val=""
    placeholder=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --value)
          shift
          val="${1:-}"
          shift || true
          ;;
        --placeholder)
          shift
          placeholder="${1:-}"
          shift || true
          ;;
        --*)
          # skip unknown option and its possible arg
          shift || true
          ;;
        *)
          # positional, ignore
          shift || true
          ;;
      esac
    done
    # Prefer explicit value if non-empty, else use placeholder, else a generic token
    if [ -n "$val" ]; then
      printf '%s' "$val"
    elif [ -n "$placeholder" ]; then
      # return placeholder as a sensible default for tests
      printf '%s' "$placeholder"
    else
      printf 'test-input'
    fi
    ;;
  choose)
    # choose: print the first non-option argument (skip flags like --header/--limit)
    for a in "$@"; do
      case "$a" in
        --*) continue ;;
        *) printf '%s' "$a"; exit 0 ;;
      esac
    done
    # if nothing left, return empty
    printf ''
    ;;
  confirm)
    # default to yes in tests
    exit 0
    ;;
  *)
    # noop / unknown subcommand: succeed silently
    exit 0
    ;;
esac
GUMSH
  chmod +x "$gum_bin/gum"

  export PATH="$gum_bin:$PATH"
  export NO_LINKS=1
}

test_lib_cleanup() {
  if [ -n "${TEST_LIB_DIR:-}" ] && [ -d "${TEST_LIB_DIR}" ]; then
    rm -rf "${TEST_LIB_DIR}"
    unset TEST_LIB_DIR
  fi
}