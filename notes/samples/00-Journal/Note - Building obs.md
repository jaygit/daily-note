---
title: Building obs — CLI Obsidian Companion
created: 2025-12-13
tags: [journal,blog,obs]
---

![obs logo](../assets/obs.jpg)

I wanted a lightweight, platform-agnostic way to create and manage notes from the shell — a command-line companion for Obsidian vaults that favors openness and composability. Because Obsidian stores plain Markdown in a folder, it’s naturally extensible: any CLI tool can create, edit, and link notes. This project, packaged as the `obs` helper scripts, grew from that idea.

## Motivation
- Why CLI-first: Quick capture, scripted workflows, and easy automation — the terminal remains the fastest way for me to create structured notes while I’m already in a shell environment.
- Why Obsidian-friendly: Obsidian’s vault is just a directory of Markdown; staying compatible keeps the data portable and editable by many tools. This openness allowed me to iterate on tooling without locking content into a closed format.

## Design Goals
- Small, composable scripts: Keep functions focused and testable under `scripts/` (e.g., `create_note.sh`, `search.sh`, `gitnotes.sh`).
- Platform-agnostic installer: Use XDG defaults where possible, fall back gracefully, and install only the `scripts/` tree plus a tiny `obs` shim.
- Durable config: Persist runtime settings into `scripts/.env` so installed scripts pick up `VAULT_DIR`, `GIT_REMOTE_*`, and `VERSION`.
- Pragmatic fallbacks: Prefer `rg`, `fzf`, and `bat`, but support `grep`, `cat`, and test stubs for minimal/container environments.
- Testable CI: Make every feature verifiable in CI with deterministic stubs and artifact logging.

## Step-by-step journey
### 1) Basic capture and templating
- Implemented `scripts/create_note.sh` to generate Markdown with category-aware frontmatter (journal, training, note, command, etc.), filename sanitation, and optional editor integration.

### 2) Helpers & shared utilities
- Added `scripts/lib.sh` with helpers: `ask`, `choose_one`, `confirm`, filename sanitizers, YAML formatters, and most importantly a `load_dotenv()` routine that finds and exports `.env` files so scripts work both in-tree and when installed.

### 3) Interactive search and previews
- Built `scripts/search.sh` to wire `rg` + `fzf` + `bat` into a snappy fuzzy-search UI with previews, plus a diary mode for daily notes. Added `rg`/`grep` and `bat`/`cat` fallbacks.

### 4) Git integration for vaults
- Wrote `scripts/gitnotes.sh` to manage pushes, pulls and status against a configured remote. The installer can record `GIT_REMOTE_NAME`/`GIT_REMOTE_URL` into `scripts/.env` to keep remote info available after install.

### 5) Tests and deterministic interaction
- Created shell tests under `tests/`. For CI determinism, tests include stubs for interactive tools (e.g., a fake `fzf`) and write logs to `tests/logs/` for artifact collection.

### 6) Platform-agnostic installer
- Built `install.sh` to install to XDG-aware paths, persist `VERSION` in `scripts/.env`, create an `obs` shim, and provide `--uninstall` delegation. Uses `rsync` when available or tar/cp fallbacks otherwise.

Notes:
- The installer and the `obs` shim accept both `--uninstall` and `--remove` (the latter is an alias for discoverability).
- As a small easter-egg the shim supports `-L|--logo` to print the packaged ASCII logo (try `obs -L`).
- There's an interactive easter-egg `-E|--easter`: run `obs -E` from a TTY and type the sequence
	`o b s` (3s timeout per key) to trigger a falling-block animation of the packaged ASCII logo.

### 7) CI and workflow hardening
- Iterated on CI workflow YAML to add host-resolution fallbacks for private runners, ensure artifact uploads are compatible with GHES/private environments, and add deterministic debugging output.

### 8) Release/version handling
- Packaging discovers `VERSION` from `RELEASE_NOTES/v.*.md` or annotated git tags and the installer persists it so `obs --version` works after install.

## Future directions
- Richer templates for frontmatter and community-shared templates.
- Smarter merge/conflict helpers for `gitnotes.sh` to improve collaboration.
- Graph/metadata export (JSON/SQLite) to enable local indices and graphs without depending on Obsidian internals.
- GUI bridge for users who prefer a mouse-driven workflow.

## How to reuse
- Override `FZF_CMD` for deterministic tests.
