# Release v1.0.0

Date: 2025-12-12

Highlights
- Added comprehensive interactive note creator: `scripts/create_note.sh`.
- New collectors: `book`, `podcast`, and `link` (web clipping).
- `note` collector implements zettelkasten-friendly defaults (tags include `zettelkasten`, status `draft`).
- Gum-aware prompts with non-interactive shim for tests/CI.
- Improved `lib.sh` helper API for prompts, formatting, and filename sanitization.
- Tests under `tests/` now run non-interactively and write logs to `tests/logs/`.
- CI workflow updated to upload logs unconditionally and add hosts mapping for private runners (set `HOST_IP`).

Changelog (selected)
- scripts/create_note.sh: added `get_book_fields()`, `get_podcast_fields()`, `get_link_fields()`, and `get_note_fields()` collectors.
- scripts/lib.sh: added gum-aware `choose_one` header, `_fmt_tags`, and other helpers used across collectors.
- tests/test_create_note.sh: expanded to assert frontmatter for note, book, podcast, and link notes; uses a gum shim.
- .gitea/workflows/ci.yml: create logs directory, ensure host resolution for `gitea` via secret `HOST_IP`, use compatible artifact uploader.

Notes
- For private runners using a hostname like `gitea`, set the repository secret `HOST_IP` to the server IP so CI can append an `/etc/hosts` entry before artifact upload.

Acknowledgements
- Built incrementally to make interactive workflows testable in CI and to expand note categories for richer metadata capture.
