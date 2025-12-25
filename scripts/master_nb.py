import os
import cv2
import json
import hashlib
import subprocess
import pytesseract
import urllib.parse  # Added for URL encoding
from pathlib import Path

# --- CONFIGURATION ---
VAULT_ROOT = Path("/home/vincent/documents/Daily Notes")
VAULT_NAME = "Daily Notes" # Needed for the Obsidian URI
TARGET_DIR = "01-scanned/Notebook-30jul25"
CANVAS_NAME = "Notebook-30jul25"

WIDTH, HEIGHT = 400, 600
PADDING = 50
COLUMNS = 2

def process_image(img_path):
    img = cv2.imread(str(img_path))
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    clean_img = cv2.adaptiveThreshold(gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, 
                                      cv2.THRESH_BINARY, 11, 2)
    
    temp_bmp = img_path.with_suffix('.bmp')
    cv2.imwrite(str(temp_bmp), clean_img)
    ocr_text = pytesseract.image_to_string(clean_img).strip()

    svg_path = img_path.with_suffix('.svg')
    subprocess.run(["potrace", str(temp_bmp), "-s", "-o", str(svg_path)], check=True)
    
    if temp_bmp.exists(): temp_bmp.unlink()
    return ocr_text, svg_path.name

def create_interactive_notebook():
    full_path = VAULT_ROOT / TARGET_DIR
    images = sorted([f for f in full_path.iterdir() if f.suffix.lower() in ['.jpg', '.jpeg', '.png']])
    
    nodes = []
    global_index_text = [f"# Search Index for [[{CANVAS_NAME}.canvas|{CANVAS_NAME}]]\n"]
    
    # URL encode the vault name for the URI
    encoded_vault = urllib.parse.quote(VAULT_NAME)
    encoded_canvas = urllib.parse.quote(f"{CANVAS_NAME}.canvas")

    for i, img_path in enumerate(images):
        print(f"Processing: {img_path.name}...")
        ocr_text, svg_name = process_image(img_path)
        rel_svg_path = f"{TARGET_DIR}/{svg_name}"
        
        # Calculate Grid
        row, col = divmod(i, COLUMNS)
        x, y = col * (WIDTH + PADDING), row * (HEIGHT + PADDING)
        node_id = hashlib.md5(rel_svg_path.encode()).hexdigest()

        # --- NEW: Create a Deep Link URI ---
        # Format: obsidian://advanced-uri?vault=VAULT&canvas=PATH&node=ID
        # Note: Requires "Advanced URI" plugin for node-specific focus
        deep_link = f"obsidian://advanced-uri?vault={encoded_vault}&filepath={encoded_canvas}&node={node_id}"
        
        global_index_text.append(f"## [Page {i+1}]({deep_link})\n**Source:** `{img_path.name}`\n\n{ocr_text}\n\n---")
        
        nodes.append({
            "id": node_id,
            "type": "file",
            "file": rel_svg_path,
            "x": x, "y": y, "width": WIDTH, "height": HEIGHT
        })

    # Save Files
    with open(VAULT_ROOT / f"{CANVAS_NAME}.canvas", 'w') as f:
        json.dump({"nodes": nodes, "edges": []}, f, indent=4)
    
    with open(VAULT_ROOT / TARGET_DIR / f"{CANVAS_NAME}-INDEX.md", 'w') as f:
        f.write("\n".join(global_index_text))
    
    print(f"\n🚀 Done! Links in the INDEX.md will now jump to specific Canvas nodes.")

if __name__ == "__main__":
    create_interactive_notebook()
