#!/bin/bash

# --- 1. Install System Dependencies ---
echo "📦 Installing system binaries (Tesseract, Potrace, ImageMagick)..."
sudo apt update
sudo apt install -y tesseract-ocr potrace imagemagick python3-pip python3-venv libgl1

# --- 2. Setup Python Virtual Environment ---
echo "🐍 Setting up Python Virtual Environment..."
SCRIPT_DIR="scripts"
mkdir -p "$SCRIPT_DIR"
cd "$SCRIPT_DIR"

# Create venv if it doesn't exist
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo "✅ Virtual environment created."
fi

# --- 3. Install Python Packages ---
echo "🛠️ Installing Python libraries (OpenCV, Pytesseract)..."
source venv/bin/activate
pip install --upgrade pip
pip install opencv-python pytesseract numpy

echo "---"
echo "🎉 Setup Complete!"
echo "📍 Venv Path: $SCRIPT_DIR/venv"
echo "🚀 You can now run your Master Script using: $SCRIPT_DIR/venv/bin/python3 master_nb.py"
