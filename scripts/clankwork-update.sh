#!/bin/bash
# ClankWork - Update all dependencies to latest versions

echo "=== ClankWork Updater ==="
echo ""

UPDATED=""
FAILED=""

# --- Homebrew ---
echo "[1/6] Updating Homebrew..."
brew update 2>/dev/null && echo "  Homebrew updated." || FAILED="$FAILED brew-update"

# --- Core packages ---
echo "[2/6] Upgrading node, bun, python3, ripgrep..."
for pkg in node bun python3 ripgrep; do
    BEFORE=$(brew info --json=v2 $pkg 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['formulae'][0]['installed'][0]['version'])" 2>/dev/null || echo "?")
    brew upgrade $pkg 2>/dev/null
    AFTER=$(brew info --json=v2 $pkg 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['formulae'][0]['installed'][0]['version'])" 2>/dev/null || echo "?")
    if [ "$BEFORE" != "$AFTER" ]; then
        echo "  $pkg: $BEFORE -> $AFTER"
        UPDATED="$UPDATED $pkg"
    else
        echo "  $pkg: $BEFORE (already latest)"
    fi
done

# --- Qwen Code ---
echo "[3/6] Upgrading Qwen Code..."
if brew list qwen-code &>/dev/null; then
    brew upgrade qwen-code 2>/dev/null && echo "  Qwen Code upgraded." || echo "  Qwen Code already latest."
else
    echo "  Qwen Code not installed via brew, skipping."
fi

# --- Peekaboo MCP ---
echo "[4/6] Updating Peekaboo MCP..."
PEEK_BEFORE=$(npm list -g @steipete/peekaboo-mcp 2>/dev/null | grep peekaboo | awk -F@ '{print $NF}' || echo "?")
npm update -g @steipete/peekaboo-mcp 2>/dev/null
PEEK_AFTER=$(npm list -g @steipete/peekaboo-mcp 2>/dev/null | grep peekaboo | awk -F@ '{print $NF}' || echo "?")
if [ "$PEEK_BEFORE" != "$PEEK_AFTER" ]; then
    echo "  peekaboo-mcp: $PEEK_BEFORE -> $PEEK_AFTER"
    UPDATED="$UPDATED peekaboo-mcp"
else
    echo "  peekaboo-mcp: $PEEK_BEFORE (already latest)"
fi

# --- Python packages ---
echo "[5/6] Updating Python packages..."
pip3 install --break-system-packages --upgrade \
    python-docx openpyxl xlsxwriter python-pptx \
    PyMuPDF pymupdf4llm pdfplumber pypdf pikepdf reportlab \
    markitdown pandas numpy pillow lxml beautifulsoup4 \
    2>/dev/null && echo "  Python packages updated." || FAILED="$FAILED pip3"

# --- Playwright ---
echo "[6/6] Updating Playwright Chromium..."
npx playwright install chromium 2>/dev/null && echo "  Chromium updated." || FAILED="$FAILED playwright"

# --- Verification ---
echo ""
echo "=== Current Versions ==="
echo "  qwen:        $(qwen --version 2>/dev/null || echo 'NOT FOUND')"
echo "  node:        $(node --version 2>/dev/null || echo 'NOT FOUND')"
echo "  bun:         $(bun --version 2>/dev/null || echo 'NOT FOUND')"
echo "  python3:     $(python3 --version 2>/dev/null || echo 'NOT FOUND')"
echo "  peekaboo:    $(npm list -g @steipete/peekaboo-mcp 2>/dev/null | grep peekaboo || echo 'NOT FOUND')"

# --- TCC Warning ---
if [ -n "$UPDATED" ]; then
    echo ""
    echo "=== WARNING ==="
    echo "The following packages were upgraded:$UPDATED"
    echo ""
    echo "If node or bun was upgraded, their Cellar paths changed."
    echo "macOS TCC permissions (Accessibility, Screen Recording) must be re-added."
    echo ""
    echo "Run: check-permissions.sh or clankwork check-permissions"
    echo "  New bun path:  $(readlink -f $(which bun) 2>/dev/null)"
    echo "  New node path: $(readlink -f $(which node) 2>/dev/null)"
fi

if [ -n "$FAILED" ]; then
    echo ""
    echo "=== ERRORS ==="
    echo "Failed updates:$FAILED"
fi

echo ""
echo "=== Update Complete ==="
