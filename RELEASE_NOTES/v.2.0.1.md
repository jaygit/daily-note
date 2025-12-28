v.2.0.1 - 2025-12-28

Bugfix: Avoid "Argument list too long" on large commits

- Updated `scripts/gitnotes.sh` to write the generated commit message
  to a temporary file and pass it to `git commit -F` rather than using
  `git commit -m "..."`. This prevents failures when the generated
  commit message becomes extremely large (many filenames listed).

Notes:
- This is a small, backwards-compatible fix that improves reliability
  when committing many files from the Obsidian vault.

Files changed:
- `scripts/gitnotes.sh` (commit message now uses a temp file)
