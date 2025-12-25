Here is a comprehensive `README.md` for your project. This is designed to be clear for other users (or your future self) and looks professional on a GitHub repository.

---

# 📚 Obsidian Notebook Ingestor

A high-performance Python automation tool that transforms folders of scanned images into a structured, visual archiving system within **Obsidian**.

## 🌟 Key Features

* **Spatial Layouts**: Automatically generates Obsidian `.canvas` files with scans arranged in a clean, multi-column grid.
* **Sidecar Architecture**: Creates a Markdown "sidecar" for every page, allowing for granular tagging and linking.
* **Natural Sequencing**: Uses human-friendly sorting (e.g., Page 2 comes before Page 10).
* **Master Indices**: Builds a "Table of Contents" with image thumbnails for every notebook.
* **Flexible Modes**: Support for single notebook processing (`-f`) or batch processing entire directories (`-d`).

---

## 🏗️ The Architecture

The script transforms a flat folder of images into a three-tiered vault structure:

1. **`Canvas/`**: Stores visual dashboards.
2. **`Notebooks/`** (or your designated parent): Stores sidecar `.md` notes and indices.
3. **`01-scanned/`**: Your source of truth (images remain untouched).

---

## 🚀 Getting Started

### 1. Prerequisites

* Python 3.8+
* `python-dotenv` library:
```bash
pip install python-dotenv

```



### 2. Configuration

The script looks for your Obsidian Vault path in a `.env` file. Create a file named `.env` in your `$HOME` directory or the script's directory:

```text
VAULT_DIR="~/documents/Daily Notes"

```

### 3. Installation

Clone this repository and make the script executable:

```bash
chmod +x mknb_canvas.py

```

Add an alias to your `~/.bashrc` or `~/.zshrc` for easy access:

```bash
alias nb='python3 /path/to/your/script/mknb_canvas.py'

```

---

## 🛠️ Usage

### Process a Single Notebook

Use the `-f` flag for a specific folder containing images.

```bash
nb -f "01-scanned/Archive/Biology-Notes"

```

### Batch Process a Directory

Use the `-d` flag to process every subdirectory within a folder as an individual notebook.

```bash
nb -d "01-scanned/Archive"

```

---

## 📊 The "Dashboard" View

To view your library in Obsidian, create a note called `Notebook Dashboard` and paste the following **Dataview** query:

```dataview
TABLE 
    length(rows) + " pages" as "Total Pages", 
    min(date) as "Date Created",
    "[[Canvas/" + notebook + ".canvas|📂 Open Canvas]]" as "Canvas"
FROM "Notebooks"
WHERE type = "notebook-page"
GROUP BY notebook
SORT min(date) DESC

```

---

## 🛠️ Customization

You can easily adjust the following variables at the top of the script:

* `WIDTH / HEIGHT`: Change the size of the cards in the Canvas.
* `COLUMNS`: Change how many pages appear side-by-side (default is 2).
* `PADDING`: Adjust the space between cards.

---

## 📜 License

MIT License - Feel free to use and modify for your own workflow!

---

