
#!/usr/bin/env bash
set -euo pipefail

# gitnotes.sh
# Sync only the Obsidian vault directory with the git repo + gitea remote.
# Features:
# - Commit only files under the vault with a descriptive message listing added/modified/deleted files
# - Include timestamp and originating hostname in commit message
# - Check remote `gitea` for newer commits, present conflicts and offer actions
# - Pull remote if behind; push to `gitea` when local is ahead

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib.sh"

usage() {
  cat <<EOF
Usage: $0 [commit|pull|status]

Commands:
  status   Show vault vs remote/gitea status
  pull     Pull newer changes from remote/gitea for the vault
  commit   Commit local vault changes and push to remote/gitea
  Options for commit/pull:
    --dry-run   Show what would be done without making changes
EOF
}

if [ $# -lt 1 ]; then
  usage
  exit 1
fi

cmd=$1
shift

# parse optional flags (supports --dry-run)
DRY_RUN=0
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1; shift ;;
    --)
      shift; break ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

# ensure vault dir exists
if [ -z "${VAULT_DIR:-}" ] || [ ! -d "$VAULT_DIR" ]; then
  echo "Error: VAULT_DIR not found or unset (lib.sh should set it)." >&2
  exit 2
fi

# determine git repo root (vault must be inside a git repo)
pushd "$VAULT_DIR" >/dev/null || { echo "Cannot enter VAULT_DIR" >&2; exit 2; }
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "$REPO_ROOT" ]; then
  echo "Error: $VAULT_DIR is not inside a git repository." >&2
  popd >/dev/null
  exit 2
fi
# path of vault relative to repo root
VAULT_REL=$(realpath --relative-to="$REPO_ROOT" "$VAULT_DIR")
popd >/dev/null

# helper: interactive choice (use gum if available)
choose() {
  local prompt="$1"; shift
  if command -v gum >/dev/null 2>&1; then
    gum choose --header "$prompt" "$@"
  else
    echo "$prompt"
    local i=1 opt
    for opt in "$@"; do
      printf "%3d) %s\n" "$i" "$opt"
      i=$((i+1))
    done
    local sel
    read -rp "Select an option [1]: " sel
    sel=${sel:-1}
    echo "${@:sel:1}"
  fi
}

ensure_remote() {
  # ensure remote named gitea exists
  if ! git remote | grep -qx gitea; then
    echo "Error: remote 'gitea' not found in repository. Remotes: $(git remote)" >&2
    exit 3
  fi
}

fetch_remote() {
  ensure_remote
  git fetch --prune gitea
}

current_branch() {
  git rev-parse --abbrev-ref HEAD
}

status_vs_remote() {
  pushd "$REPO_ROOT" >/dev/null
  fetch_remote
  local branch remote_ref local revs
  branch=$(current_branch)
  remote_ref="gitea/$branch"

  # If remote branch doesn't exist, treat as no-remote
  if ! git show-ref --quiet --verify "refs/remotes/$remote_ref"; then
    echo "Remote '$remote_ref' does not exist. Local branch: $branch"
    popd >/dev/null
    return
  fi

  local behind ahead
  read -r ahead behind < <(git rev-list --left-right --count "$branch"..."$remote_ref") || true
  echo "Branch: $branch  (ahead: $ahead, behind: $behind)"

  if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
    echo "Branches have diverged. Files differing in the vault:" 
    git diff --name-only "$branch" "$remote_ref" -- "$VAULT_REL" || true
  elif [ "$behind" -gt 0 ]; then
    echo "Remote has new commits (you are behind)."
  elif [ "$ahead" -gt 0 ]; then
    echo "Local has new commits (you are ahead)."
  else
    echo "Local and remote are in sync for branch $branch." 
  fi
  popd >/dev/null
}

show_conflicts_and_options() {
  local branch remote_ref
  branch=$(current_branch)
  remote_ref="gitea/$branch"
  echo "The local and remote branches have diverged. Files under the vault that differ:" 
  git diff --name-only "$branch" "$remote_ref" -- "$VAULT_REL" || true

  echo
  choice=$(choose "How do you want to proceed?" "Show diffs" "Pull remote and attempt merge (may require conflict resolution)" "Abort")
  case "$choice" in
    "Show diffs")
      echo "Showing diffs (local...remote) for vault files:"
      git --no-pager diff --color "$branch"..."$remote_ref" -- "$VAULT_REL" || true
      ;;
    "Pull remote and attempt merge (may require conflict resolution)")
      echo "Attempting to pull from gitea/$branch..."
      if git pull gitea "$branch"; then
        echo "Pulled and merged successfully. Resolve any remaining conflicts if present.";
      else
        echo "Merge produced conflicts. Please resolve them in the vault and re-run this script." >&2
        git status --porcelain
        exit 4
      fi
      ;;
    *)
      echo "Aborting."; exit 1;
      ;;
  esac
}

perform_pull() {
  pushd "$REPO_ROOT" >/dev/null
  fetch_remote
  branch=$(current_branch)
  remote_ref="gitea/$branch"

  # If remote branch missing, nothing to pull
  if ! git show-ref --quiet --verify "refs/remotes/$remote_ref"; then
    echo "No remote branch $remote_ref to pull."; popd >/dev/null; return
  fi

  # try fast-forward only
  if git merge-base --is-ancestor "$branch" "$remote_ref"; then
    # remote is descendant of local -> nothing to do
    echo "Local branch is up-to-date or ahead; no pull necessary."; popd >/dev/null; return
  fi

  echo "Pulling changes from gitea/$branch..."
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY RUN: would attempt fast-forward pull. Remote commits ahead:"
    git --no-pager log --oneline "$branch".."$remote_ref" -- "$VAULT_REL" || true
    popd >/dev/null
    return
  fi

  if git pull --ff-only gitea "$branch" 2>/dev/null; then
    echo "Fast-forwarded to remote."; popd >/dev/null; return
  fi

  # cannot fast-forward -> present options
  echo "Non-fast-forward pull required. Presenting options to resolve." 
  show_conflicts_and_options
  popd >/dev/null
}

collect_vault_changes() {
  pushd "$REPO_ROOT" >/dev/null
  # get porcelain status for vault relative path
  git status --porcelain --untracked-files=all -- "$VAULT_REL"
  popd >/dev/null
}

make_commit_message() {
  local added modified deleted host now
  host=$(uname -n)
  now=$(date --iso-8601=seconds)

  # categorize changes
  added=$(collect_vault_changes | awk '/^\?\?/ {print substr($0,4)}' || true)
  modified=$(collect_vault_changes | awk '/^[ MARC]M|^ M|^[AMDRC] / { if ($1 != "??") print substr($0,4)}' || true)
  deleted=$(collect_vault_changes | awk '/^ D/ {print substr($0,4)}' || true)

  cat <<EOF
Vault update from ${host}
Date: ${now}

Changes:
EOF
  if [ -n "$added" ]; then
    echo "Added:"
    echo "$added" | sed 's/^/  - /'
  fi
  if [ -n "$modified" ]; then
    echo "Modified:"
    echo "$modified" | sed 's/^/  - /'
  fi
  if [ -n "$deleted" ]; then
    echo "Deleted:"
    echo "$deleted" | sed 's/^/  - /'
  fi
}

do_commit() {
  pushd "$REPO_ROOT" >/dev/null
  ensure_remote
  branch=$(current_branch)

  # fetch remote and detect divergence
  fetch_remote
  remote_ref="gitea/$branch"
  ahead=0; behind=0
  if git show-ref --quiet --verify "refs/remotes/$remote_ref"; then
    read -r ahead behind < <(git rev-list --left-right --count "$branch"..."$remote_ref") || true
  fi

  if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
    echo "Local and remote have diverged."
    show_conflicts_and_options
  elif [ "$behind" -gt 0 ]; then
    echo "Remote has new commits. Attempting to pull..."
    perform_pull
  fi

  # Stage only vault changes
  echo "Staging vault changes..."
  git add -- "$VAULT_REL"

  # if nothing to commit, exit
  if git diff --cached --quiet -- "$VAULT_REL"; then
    echo "No changes to commit in vault."; popd >/dev/null; return
  fi

  # Create commit message
  msg=$(make_commit_message)
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY RUN: would create commit with message:"
    echo "-----------------"
    echo "$msg"
    echo "-----------------"
    echo "DRY RUN: staged changes (name-status):"
    git --no-pager diff --cached --name-status -- "$VAULT_REL" || true
    popd >/dev/null
    return
  fi

  git commit -m "$msg"

  echo "Pushing to gitea/$branch..."
  if git push gitea "$branch"; then
    echo "Push successful."; popd >/dev/null; return
  else
    echo "Push failed. Remote may have new commits. Fetching and advising resolution." >&2
    fetch_remote
    git status --porcelain
    popd >/dev/null
    exit 5
  fi
}

case "$cmd" in
  status)
    pushd "$REPO_ROOT" >/dev/null
    status_vs_remote
    popd >/dev/null
    ;;
  pull)
    pushd "$REPO_ROOT" >/dev/null
    perform_pull
    popd >/dev/null
    ;;
  commit)
    pushd "$REPO_ROOT" >/dev/null
    do_commit
    popd >/dev/null
    ;;
  *)
    echo "Unknown command: $cmd" >&2
    usage
    exit 1
    ;;
esac

