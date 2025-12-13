# Daily Notes Scripts

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
  - Usage: `scripts/gitnotes.sh <status|pull|commit>`
    - `status`: show local vs `gitea` remote status for vault files
    - `pull`: pull newer changes from `gitea` (fast-forward only by default)
    - `commit`: commit vault changes with a descriptive message and push to `gitea`
  - Notes: The script focuses only on changes under the vault directory (as set by `VAULT_DIR`). It includes host and timestamp information in commit messages and presents clear options when local and remote have diverged.
- `scripts/histnotes.sh` — History and archive helpers.
- `scripts/follow_links.sh` — Extracts wiki links from a note and lets you open/select them with `fzf`.

## lib.sh — helper API

`lib.sh` exports environment and provides interactive helper functions used by the scripts. Examples:

- Environment
  - `SCRIPT_DIR` — path to scripts directory
  - `VAULT_DIR` — vault root (defaults to parent of scripts/)

- Prompt helpers (gum-aware)
  - `ask "Prompt" "default"` — returns user input
  - `choose_one "Header" opt1 opt2 ...` — selection UI (`gum choose` with header if available)
  - `confirm "Prompt"` — yes/no prompt

- Formatting helpers
  - `_fmt_tags "a,b,c"` → formats `a, b, c` for YAML inline lists
  - `_fmt_quoted_array "a,b,c"` → formats `["a","b","c"]`

- Utilities
  - `sanitize_filename "Title string"`
  - `escape_yaml_string "text"`

## Tests & CI

- Tests live under `tests/` and are written as shell scripts. A non-interactive gum shim is provided so tests can exercise interactive flows in CI.
- Logs are written to `tests/logs/` for CI artifact collection.
- The workflow adds a hosts mapping step for private runners (set secret `HOST_IP`) to help resolve a private `gitea` hostname when uploading artifacts.

## Backlinks behavior

- When you select existing notes during creation, the scripts will add a `## Backlinks` section (created if missing) and avoid duplicate links.

## Tips

- Install `gum`, `fzf`, and `bat`/`batcat` for a smoother interactive experience and nicer previews.
- If you move the scripts, update `lib.sh` to set the correct `VAULT_DIR`.

## Contributing

- Changes are intended to be small and focused. Open issues or PRs for feature requests.

## License

Personal use. No license attached.
```
