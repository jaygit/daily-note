# v.1.4.0

## Summary
- Improve installer: install only `scripts/`, add uninstall delegation, install manpage to system/user manpath where possible.
- Add `obs --version` support and store `VERSION` in installed `.env` during install.
- Make CI artifact upload more robust and compatible with GHES (use upload-artifact@v3).
- Make `search.sh` robust when `rg`/`bat` are missing (fallbacks to `grep`/`cat`), and tests include shims.
- Add `Install.sh` fallbacks for environments without `rsync` (tar/cp).

## Notes
- This release focuses on installer ergonomics, CI robustness, and making the tool work in minimal container environments.
