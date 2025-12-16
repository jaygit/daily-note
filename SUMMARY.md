# Repository Summary

## Daily Notes Scripts - Obsidian Vault Management Tools

A collection of shell scripts for managing and navigating Obsidian-style vaults with features for note creation, search, and git integration.

### Key Features

- **Note Creation**: Interactive and non-interactive note creation with multiple categories (journal, training, command, book, podcast, link, install guides)
- **Search & Navigation**: Fuzzy search with previews using `fzf` and `ripgrep`, including diary mode for daily notes
- **Git Integration**: Vault-focused git helpers for status, pull, and commit operations
- **XDG-Compliant Installer**: Installs scripts to XDG-aware directories with persistent configuration
- **YAML Frontmatter**: Automatic generation of structured metadata for all note types
- **Backlinks Management**: Automatic backlink creation and duplicate prevention

### Main Scripts

- `scripts/main.sh` - Entry point and dispatcher with version and environment commands
- `scripts/create_note.sh` - Create notes with various categories and templates
- `scripts/search.sh` - Interactive search with fuzzy matching and preview
- `scripts/gitnotes.sh` - Git operations scoped to vault directory
- `scripts/jobs.sh` - Job notes and status updates
- `install.sh` - XDG-compliant installer with `obs` shim

### Installation

```bash
./install.sh              # Interactive install
./install.sh --yes        # Non-interactive with sample vault
obs --version            # Check installed version
obs --env                # View configuration
```

### Tool Requirements

- **Required**: Standard Unix tools (`bash`, `git`)
- **Recommended**: `gum` (interactive prompts), `fzf` (fuzzy finder), `rg` (ripgrep), `bat` (pretty previews)
- **Fallbacks**: Scripts gracefully degrade to `grep` and `cat` when advanced tools are unavailable

### Configuration

- Runtime settings stored in `scripts/.env` after installation
- Configurable `VAULT_DIR`, `GIT_REMOTE_NAME`, `GIT_REMOTE_URL`, and `VERSION`
- Override `FZF_CMD` for deterministic testing

### Use Cases

- Personal knowledge management with Obsidian vaults
- Command documentation and training note management
- Book, podcast, and web clipping organization
- Daily journaling with mood tracking
- Install guide documentation for software dependencies
