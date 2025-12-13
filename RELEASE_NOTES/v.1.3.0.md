v.1.3.0 - 2025-12-13
=====================

Highlights
----------
- Installer: added scripted install flags (`--yes`, `--sample-vault`, `--vault-path`) and XDG-aware installation to `${XDG_DATA_HOME:-$HOME/.local/share}` with `obs` shim in `${XDG_BIN_HOME:-$HOME/.local/bin}`.
- `install.sh` now writes `VAULT_DIR` into the installed `scripts/.env` and can detect/configure a `gitea` remote for convenient sync.
- `search.sh` diary mode merged and made testable via `FZF_CMD` override; preview command properly handled and tested.
- Packaging: `package_builder.sh` and `scripts/make_release_payload.py` now determine `VERSION` dynamically from `RELEASE_NOTES`, environment `VERSION`, or git tags.
- Tests: added `tests/test_install.sh` to verify non-interactive installer behavior; full test suite passes.

Notes
-----
This release focuses on installer ergonomics and making interactive tools testable in CI. The package builder was updated so CI can set `VERSION` and create release artifacts consistently.
