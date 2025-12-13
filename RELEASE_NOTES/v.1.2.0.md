v.1.2.0 - 2025-12-13
=====================

Highlights
----------
- Merge diary functionality into the main `search` tool and add a non-interactive diary mode.
- Make `fzf` overridable via `FZF_CMD` to enable deterministic, non-interactive tests.
- Add unit test for diary search (`tests/test_search_diary.sh`).
- Improve `search.sh` preview handling (`print_preview_cmd`) and robust fzf preview support (bat/batcat fallback).
- Add dotenv loading support and tests (see `scripts/lib.sh` and `tests/test_dotenv.sh`).
- Various fixes and cleanups: `main.sh` help/syntax fix, removal of redundant scripts, and test harness updates.

Files changed (not exhaustive)
-----------------------------
- `scripts/search.sh` — diary mode, `FZF_CMD` override, preview command fixed.
- `scripts/lib.sh` — dotenv loading support.
- `scripts/gitnotes.sh` — git sync improvements and `--dry-run`.
- `README.md` — documented diary mode and `FZF_CMD` testing override.
- `tests/test_search_diary.sh`, `tests/test_dotenv.sh`, `tests/test_gitnotes.sh` — new/updated tests.

Notes
-----
Run the test suite locally:

```bash
bash tests/run_tests.sh
```

If you want this release pushed to remotes, the annotated tag `v.1.2.0` will be pushed alongside the branch.
