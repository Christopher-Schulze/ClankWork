#!/bin/bash
# ClankWork - Install all system dependencies
# Uses Homebrew for node, bun, python3 + official script for Qwen Code

set -e

echo "=== ClankWork Dependency Installer ==="
echo ""

# --- Homebrew ---
if ! command -v brew &>/dev/null; then
    echo "[1/6] Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "[1/6] Homebrew already installed: $(brew --version | head -1)"
fi

# --- Core packages via brew ---
echo "[2/6] Installing node, bun, python3, ripgrep via Homebrew..."
brew install node bun python3 ripgrep 2>/dev/null || true

# --- Qwen Code CLI ---
if ! command -v qwen &>/dev/null; then
    echo "[3/6] Installing Qwen Code CLI..."
    bash -c "$(curl -fsSL https://qwen-code-assets.oss-cn-hangzhou.aliyuncs.com/installation/install-qwen.sh)"
    # Alternative: brew install qwen-code
else
    echo "[3/6] Qwen Code already installed: $(which qwen)"
fi

# --- Peekaboo MCP (desktop screenshots) ---
echo "[4/6] Installing Peekaboo MCP..."
npm install -g @steipete/peekaboo-mcp 2>/dev/null || true

# --- Python packages ---
echo "[5/6] Installing Python packages..."
pip3 install --break-system-packages \
    python-docx openpyxl xlsxwriter python-pptx \
    PyMuPDF pymupdf4llm pdfplumber pypdf pikepdf reportlab \
    markitdown pandas numpy pillow lxml beautifulsoup4 \
    2>/dev/null || true

# --- Playwright Chromium ---
echo "[6/6] Installing Playwright Chromium browser..."
npx playwright install chromium 2>/dev/null || true

echo ""
echo "=== Verification ==="
echo "qwen:        $(which qwen 2>/dev/null || echo 'NOT FOUND')"
echo "bun:         $(which bun 2>/dev/null || echo 'NOT FOUND') ($(bun --version 2>/dev/null || echo '?'))"
echo "node:        $(which node 2>/dev/null || echo 'NOT FOUND') ($(node --version 2>/dev/null || echo '?'))"
echo "python3:     $(which python3 2>/dev/null || echo 'NOT FOUND') ($(python3 --version 2>/dev/null || echo '?'))"
echo "peekaboo:    $(which peekaboo-mcp 2>/dev/null || echo 'NOT FOUND')"
echo ""

MISSING=0
for cmd in qwen bun node python3 peekaboo-mcp; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "ERROR: $cmd not found!"
        MISSING=1
    fi
done

if [ "$MISSING" -eq 0 ]; then
    echo "All dependencies installed successfully."
else
    echo "Some dependencies are missing. Check errors above."
    exit 1
fi
