# Daily Notes Scripts

```
  ██████╗ ██████╗ ███████╗
 ██╔═══██╗██╔══██╗██╔════╝
 ██║   ██║██████╔╝███████╗
 ██║   ██║██╔══██╗╚════██║
 ╚██████╔╝██████╔╝███████║
  ╚═════╝ ╚═════╝ ╚══════╝

```
This repository contains helper shell scripts to manage and navigate an Obsidian-style vault. The scripts live in the `scripts/` directory and assume the vault root is the parent directory.

## Key scripts

- `scripts/create_note.sh` — Create notes interactively (journal, training, command, or generic note).
  - Usage (interactive):
    ```
    scripts/create_note.sh
    ```
  - Usage (non-interactive):
    ```bash
    scripts/create_note.sh -t "Title" -c book -v /path/to/vault -n
    ```
  - Common options:
    - `-t, --title`       Title (required for non-interactive runs)
    - `-c, --category`    Category: `training`, `journal`, `command`, `note`, `book`, `podcast`, `link`, `install` (defaults to `training`)
      - `install`: `type: install-guide`, `software-name`, `version`, `installer`, `date-installed`, `dependency-of`, `os`, `link`
    - `-p, --project`     Project name (optional)
    - `-v, --vault`       Path to vault root (optional; defaults to parent of `scripts/`)
    - `-n, --no-editor`   Do not open the created file in `$EDITOR`
    - `-h, --help`        Show help and exit

  - Frontmatter examples by category:
    - `training`: `type: training`, `tags`, `status`, `created`, `updated`, `project`
    - `journal`: `type: journal`, `mood`, `tags`, `created`
    - `command`: `type: command`, `command-name`, `technology`, `status`, `source-file`
    - `note` (zettelkasten-style): `type: note`, `tags` (includes `zettelkasten`), `status` (defaults to `draft`)
    - `book`: `type: book`, `author`, `isbn`, `year`, `rating`, `my-summary`
    - `podcast`: `type: podcast`, `podcast-name`, `episode`, `host`, `date-listened`, `url`
    - `link`: `type: link`, `url`, `date-clipped`, `site`, `author`, `summary`, `tags` (defaults to `web/clipping`)


Behavior:
- Prompts (uses `gum` when available) for required frontmatter fields depending on category.
- Produces YAML frontmatter for `type: journal`, `type: training`, and `type: command`.
- Sanitizes filenames, avoids accidental overwrites (appends numeric suffix), and opens the note in $EDITOR (unless -n).
- When a project is specified the script can update or create project index files and add backlinks.


## Other scripts
- `scripts/jobs.sh` — Helpers for job notes and quick status updates.
- `scripts/gitnotes.sh` — Git helpers for the vault.
- `scripts/search.sh` — Interactive search UI for the vault.
  - Usage: `scripts/search.sh` or via `scripts/main.sh -o search`
  - Diary mode: `scripts/search.sh diary [range] [keyword]` or via `scripts/main.sh -o diary`
    - Non-interactive: `range` choices: `today`, `yesterday`, `this-month`, `last-week`, or omit for all daily notes.
    - Optional `keyword` filters matches within the chosen range.
  - Features: prompt for search terms, fuzzy-select matching files with preview (uses `fzf`), open selection in `$EDITOR` (supports multi-select), or view raw contents.
  - Requirements: `rg` (ripgrep) and `fzf` recommended; `bat`/`batcat` optional for nicer previews.
  - Testing: set environment variable `FZF_CMD` to a path to a stub executable to override `fzf` (useful for tests that need deterministic non-interactive selection).

Installation
------------
This project includes a simple installer `install.sh` that copies the package under your XDG data directory and creates a small `obs` shim in your XDG bin directory.

- Default locations:
  - Data: `${XDG_DATA_HOME:-$HOME/.local/share}/daily-note`
  - Bin: `${XDG_BIN_HOME:-$HOME/.local/bin}`

- The installer writes its runtime env to `scripts/.env` inside the installed tree. This file will contain `VAULT_DIR` and (optionally) `GIT_REMOTE_NAME`/`GIT_REMOTE_URL` so `scripts/lib.sh` can load them.

- Interactive install (choose sample or point at existing vault):

```bash
./install.sh
```

- Non-interactive examples:

Install with bundled sample vault:

```bash
./install.sh --yes
# or explicit flag
./install.sh --sample-vault
```

Install and set an existing vault path:

```bash
./install.sh --vault-path /path/to/your/vault
```

- Override XDG paths for testing or CI:

```bash
XDG_DATA_HOME=/tmp/mydata XDG_BIN_HOME=/tmp/mybin ./install.sh --yes
```

- After installation the `obs` shim will be placed in your XDG bin directory. Ensure that `XDG_BIN_HOME` (usually `~/.local/bin`) is in your `PATH` so `obs` is available from the shell.

Notes
-----
- The installer will write `VAULT_DIR` into the installed `scripts/.env`. `scripts/lib.sh` sources the first `.env` it finds (it prefers the `scripts/` location in the installed tree), so you can edit that file to change the configured vault or remote settings.
- If you want the installer to configure a remote for pushes/pulls, run the installer pointing at a vault that is a git repo; the installer will list remotes and can add/alias one as `gitea`, storing `GIT_REMOTE_NAME` and `GIT_REMOTE_URL` in the `.env`.
  - Usage: `scripts/gitnotes.sh <status|pull|commit> [--dry-run]`
    - `status`: show local vs `gitea` remote status for vault files
    - `pull`: pull newer changes from `gitea` (fast-forward only by default). Use `--dry-run` to preview remote commits affecting the vault.
    - `commit`: commit vault changes with a descriptive message and push to `gitea`. Use `--dry-run` to print the commit message and staged changes without creating a commit or pushing.
  - Notes: The script focuses only on changes under the vault directory (as set by `VAULT_DIR`). It includes host and timestamp information in commit messages and presents clear options when local and remote have diverged.
# Daily Notes Scripts

Helper shell scripts to manage and navigate an Obsidian-style vault. The executable scripts live in the `scripts/` directory and assume the vault root is the parent directory (unless configured by the installer).

## What's new

- Canvas workflow: see `README_CANVAS.md` for canvas-style note tooling, scanned-note ingestion, and OCR examples.

- Installer (`install.sh`) now installs only the `scripts/` tree under an XDG-aware prefix, creates a small `obs` shim in your XDG bin dir, and persists runtime settings in `scripts/.env` (includes `VAULT_DIR` and `VERSION`).
- `scripts/lib.sh` loads and exports `.env` files (first one found) so installed scripts pick up `VAULT_DIR`, `GIT_REMOTE_*`, and `VERSION` automatically.
- `scripts/search.sh` and other scripts provide fallbacks when tools are missing: `rg` → `grep`, `bat` → `cat`, `fzf` can be overridden with `FZF_CMD` (useful for tests).
- A manpage `man/obs.1` is included and the installer will try to install it to a writable manpath when available.

## Quick start

Install locally (interactive):

```bash
./install.sh
```

Non-interactive install (sample vault):

```bash
./install.sh --yes
```

Install into custom XDG paths (useful for CI/testing):

```bash
XDG_DATA_HOME=/tmp/mydata XDG_BIN_HOME=/tmp/mybin ./install.sh --yes
```

After installation the `obs` shim will be placed in your XDG bin directory (defaults to `${XDG_BIN_HOME:-$HOME/.local/bin}`). Ensure that directory is in your `PATH`.

To uninstall use the shim or the installer directly:

```bash
obs --uninstall
# or
./install.sh --uninstall --yes
```

Both `--uninstall` and `--remove` are accepted; `--remove` is an alias for `--uninstall` provided for discoverability.

## Key scripts

- `scripts/main.sh` — entry point and dispatcher; supports `-v|--version` which reads `VERSION` from `scripts/.env` (installed tree) or detects it from `RELEASE_NOTES`/git tags.
- `scripts/main.sh` — entry point and dispatcher; supports `-v|--version` which reads `VERSION` from `scripts/.env` (installed tree) or detects it from `RELEASE_NOTES`/git tags.

Version
-------

- Show the installed `obs` version:

```bash
obs -v
# or
obs --version
```

This prints the value persisted by the installer into `scripts/.env` (the installer writes `VERSION=<tag>` when available). When running from source the tools will attempt to determine the version from `RELEASE_NOTES/v.*.md` or an annotated git tag.

Environment
-----------

Inspect the environment `obs` is using (useful for debugging installed configuration):

```bash
obs --env
# or
obs -e
```

This prints common runtime variables such as `VAULT_DIR`, `VERSION`, any configured `GIT_REMOTE_*`, and availability flags for `fzf`, `rg`, and `bat`.
- `scripts/create_note.sh` — create notes (interactive or non-interactive via flags).
- `scripts/search.sh` — fuzzy search with previews; diary mode available (`diary` subcommand or `main.sh -o diary`).
- `scripts/gitnotes.sh` — vault-focused git helpers (`status`, `pull`, `commit`) that use the configured `GIT_REMOTE_*` settings.
- `scripts/jobs.sh`, `scripts/histnotes.sh`, `scripts/follow_links.sh` — utility helpers.

Usage examples:

```bash
scripts/create_note.sh
scripts/create_note.sh -t "My Note" -c note -v /path/to/vault -n
scripts/search.sh
scripts/main.sh -o search
```

## Environment & configuration

- The installer writes `scripts/.env` into the installed tree with `VAULT_DIR`, optionally `GIT_REMOTE_NAME`/`GIT_REMOTE_URL`, and `VERSION`.
- During development the scripts look for a `.env` under `scripts/` or walk up common locations; `scripts/lib.sh` will export the variables it finds.
- Override `FZF_CMD` to point to a deterministic `fzf` stub in tests.

## Tool fallbacks

- `rg` (ripgrep) is preferred; scripts will fall back to `grep` when `rg` is not available.
- `bat` or `batcat` is used for pretty previews; falls back to `cat` when missing.
- `fzf` is used for interactive selection; tests override it via `FZF_CMD`.

## Tests & CI

- Tests are shell scripts under `tests/`. A gum/fzf shim is provided for CI so interactive flows can run deterministically.
- Logs are written to `tests/logs/` for artifact collection.
- The CI workflow includes a host-resolution helper for private runners (set secret `HOST_IP`) and the artifact upload step uses a compatible uploader for GHES/private environments.

## Development notes

- Release packaging discovers `VERSION` from `RELEASE_NOTES/v.*.md` or from an annotated git tag and the installer persists that `VERSION` into `scripts/.env` so `obs --version` continues to work after install.
- The `obs` shim delegates `--uninstall` to the installer so the installed tree can cleanly remove files it created.
 - The `obs` shim delegates `--uninstall`/`--remove` to the installer so the installed tree can cleanly remove files it created.

Easter egg:
- The `-L|--logo` flag prints the packaged ASCII logo to stdout (try `obs -L`).
 - The `-L|--logo` flag prints the packaged ASCII logo to stdout (try `obs -L`).
 - The `-E|--easter` flag is a small interactive easter-egg: run `obs -E` and type the
   sequence `o b s` (3s timeout per key) to trigger a falling-block animation of the
   packaged ASCII logo. Requires a TTY.

## Backlinks behavior

- When creating notes the scripts will add a `## Backlinks` section when linking to existing notes and will avoid duplicate backlinks.

## Tips

- Install `gum`, `fzf`, and `bat`/`batcat` for the best interactive experience.
- For CI or minimal containers the scripts handle missing tools with fallbacks; set `FZF_CMD` for deterministic tests.

## Contributing

- Keep changes small and focused. Open issues or PRs for feature requests.

## License

Personal use. No license attached.
