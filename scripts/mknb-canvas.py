#!/usr/bin/env python3
import os
import json
import hashlib
import sys
import re
import argparse
from pathlib import Path
from datetime import datetime
from dotenv import load_dotenv

def get_vault_dir():
    """Checks $HOME/.env first, then script_dir/.env for VAULT_DIR."""
    home_env = Path.home() / ".env"
    script_env = Path(__file__).parent / ".env"
    
    for env_path in [home_env, script_env]:
        if env_path.exists():
            load_dotenv(dotenv_path=env_path, override=True)
            val = os.getenv("VAULT_DIR")
            if val:
                return Path(os.path.expanduser(val))
    return None

# --- INITIALIZATION ---
VAULT_PATH = get_vault_dir()
if not VAULT_PATH:
    print("❌ Error: VAULT_DIR not found in .env files.")
    sys.exit(1)

WIDTH, HEIGHT, PADDING, COLUMNS = 700, 950, 50, 2

def natural_sort_key(s):
    return [int(text) if text.isdigit() else text.lower()
            for text in re.split(r'(\d+)', str(s))]

def process_notebook(scanned_path_rel):
    """
    scanned_path_rel: e.g., '01-scanned/Notebooks/MyScan'
    """
    full_input_path = VAULT_PATH / scanned_path_rel
    if not full_input_path.is_dir():
        print(f"⚠️ Skipping: {full_input_path} is not a directory.")
        return

    # Extract naming parts
    # parts: ['01-scanned', 'Notebooks', 'MyScan']
    parts = list(full_input_path.relative_to(VAULT_PATH).parts)
    if len(parts) < 2:
        print(f"❌ Error: Path {scanned_path_rel} too shallow. Need root/parent/folder.")
        return

    parent_name = parts[-2]
    folder_name = parts[-1]

    # Define Output Paths
    # Sidecars: $VAULT_ROOT/parent/scanned-directory
    sidecar_dir = VAULT_PATH / parent_name / folder_name
    sidecar_dir.mkdir(parents=True, exist_ok=True)

    # Canvas: $VAULT_ROOT/Canvas/parent/scanned-directory.canvas
    canvas_parent_dir = VAULT_PATH / "Canvas" / parent_name
    canvas_parent_dir.mkdir(parents=True, exist_ok=True)
    canvas_file = canvas_parent_dir / f"{folder_name}.canvas"

    print(f"📖 Processing: {folder_name} into {parent_name}")

    # Gather images
    exts = {'.jpg', '.jpeg', '.png', '.JPG', '.JPEG', '.PNG'}
    images = sorted([f for f in full_input_path.iterdir() if f.suffix in exts], key=natural_sort_key)
    
    if not images:
        print(f"   ⚠️ No images found in {folder_name}.")
        return

    nodes = []
    current_date = datetime.now().strftime("%Y-%m-%d")
    index_lines = [
        "---", "type: notebook-index", f"notebook: \"{folder_name}\"", "---",
        f"# Index: {folder_name}\n",
        f"[[Canvas/{parent_name}/{folder_name}.canvas|📂 Open Visual Canvas]]\n",
        "| Page | Link | Preview |", "| --- | --- | --- |"
    ]

    for count, img_file in enumerate(images):
        md_filename = f"{img_file.stem}.md"
        full_md_path = sidecar_dir / md_filename
        # Path relative to vault for Obsidian
        rel_md_path = f"{parent_name}/{folder_name}/{md_filename}"
        
        if not full_md_path.exists():
            content = f"---\ntype: notebook-page\nnotebook: \"{folder_name}\"\ndate: {current_date}\ncssclasses: [clean-embed]\n---\n\n![[{img_file.name}]]"
            full_md_path.write_text(content)

        index_lines.append(f"| {count + 1} | [[{md_filename}]] | ![[{img_file.name}|100]] |")

        row, col = count // COLUMNS, count % COLUMNS
        x, y = col * (WIDTH + PADDING), row * (HEIGHT + PADDING)

        nodes.append({
            "id": hashlib.md5(rel_md_path.encode()).hexdigest(),
            "type": "file",
            "file": rel_md_path,
            "x": int(x), "y": int(y), "width": int(WIDTH), "height": int(HEIGHT)
        })

    with open(canvas_file, "w") as f:
        json.dump({"nodes": nodes, "edges": []}, f, indent=4)
    
    (sidecar_dir / f"_Index_{folder_name}.md").write_text("\n".join(index_lines))
    print(f"   ✅ Done.")

def main():
    parser = argparse.ArgumentParser(description="Generate Obsidian Canvas from scanned notebooks.")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("-d", "--dir", help="Root/Parent directory to batch scan subfolders.")
    group.add_argument("-f", "--folder", help="Root/Parent/Folder path for a specific notebook.")

    args = parser.parse_args()

    if args.dir:
        target_path = VAULT_PATH / args.dir
        if not target_path.is_dir():
            print(f"❌ Error: {target_path} is not a directory.")
            sys.exit(1)
        
        subdirs = [d for d in target_path.iterdir() if d.is_dir()]
        print(f"📂 Batch processing {len(subdirs)} folders in {args.dir}...")
        for subdir in sorted(subdirs, key=natural_sort_key):
            process_notebook(str(subdir.relative_to(VAULT_PATH)))

    elif args.folder:
        process_notebook(args.folder)

if __name__ == "__main__":
    main()
