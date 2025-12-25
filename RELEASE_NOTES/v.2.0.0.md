# v2.0.0 — Scanned Notes & OCR Recognition

Release date: 2025-12-25

Highlights
- Scanned notes ingestion: add scanned pages and images to your vault and convert them into searchable notes.
- OCR recognition: integrated OCR installation and workflow to extract text from scans.
- Canvas & notebook tooling: new `mknb_canvas.py` and `master_nb.py` helpers (see README_CANVAS.md).
- Quick capture with `scripts/jot.sh`: capture scans and wire them into the OCR + notebook pipeline.

What's new

- Add scanned documents and images to your notes folder. The project now includes OCR helper scripts and an installer to set up OCR dependencies (see `ocr-install.sh`).
- `mknb_canvas.py` and `master_nb.py` provide utilities for building canvas-style notes and stitching scanned pages into master notebooks.
- `README_CANVAS.md` documents the canvas workflow and examples for producing HTML/PDF output from scanned material.
- The `jot.sh` script in `scripts/` now integrates with the scanned-note flow so you can quickly capture a page and run OCR in one step.

Usage examples

- Install OCR dependencies (system-dependent). Example (root):

  ```bash
  ./ocr-install.sh
  ```

- Capture a quick scan and OCR it with `jot`:

  ```bash
  scripts/jot.sh --scan path/to/image.jpg --ocr
  ```

- Build a canvas notebook from scanned pages:

  ```bash
  python3 mknb_canvas.py --input notes/scans/ --output notes/notebooks/Canvas-2025-12-25.md
  python3 master_nb.py notes/notebooks/Canvas-2025-12-25.md
  ```

Notes for maintainers

- The OCR installer and runtime assume common tools (tesseract, imagemagick). Refer to `ocr-install.sh` for supported platforms and steps.
- If you prefer a different OCR engine, `mknb_canvas.py` and `master_nb.py` accept plain-text input so you can substitute your own text-extraction step.

Thanks

Thanks to the contributors who added scanned-note ingestion and the OCR integration. This release makes scanned content first-class in the daily-note toolset.
