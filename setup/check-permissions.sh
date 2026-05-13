#!/bin/bash
# ClankWork - Check and guide macOS TCC permissions
# TCC permissions CANNOT be set via script (SIP-protected).
# This script checks what's missing and opens System Settings.

set -e

echo "=== ClankWork Permission Checker ==="
echo ""

# Ensure Homebrew is in PATH
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null)" || true

# Resolve actual Cellar paths (TCC tracks real paths, not symlinks)
BUN_PATH=$(readlink -f "$(which bun)" 2>/dev/null || echo "NOT FOUND")
NODE_PATH=$(readlink -f "$(which node)" 2>/dev/null || echo "NOT FOUND")
PEEKABOO_NATIVE=""
NPM_ROOT=$(npm root -g 2>/dev/null)
if [ -n "$NPM_ROOT" ] && [ -f "$NPM_ROOT/@steipete/peekaboo-mcp/peekaboo" ]; then
    PEEKABOO_NATIVE="$NPM_ROOT/@steipete/peekaboo-mcp/peekaboo"
fi

echo "Detected binary paths:"
echo "  bun:      $BUN_PATH"
echo "  node:     $NODE_PATH"
echo "  peekaboo: ${PEEKABOO_NATIVE:-NOT FOUND}"
echo ""

# --- Test Accessibility ---
echo "Testing Accessibility..."
ACC_OK=0
osascript -e 'tell application "System Events" to get name of every process' &>/dev/null && ACC_OK=1

if [ "$ACC_OK" -eq 1 ]; then
    echo "  Accessibility: OK (from this terminal)"
else
    echo "  Accessibility: MISSING - needs to be granted"
fi

# --- Test Screen Recording ---
echo "Testing Screen Recording..."
SCR_OK=0
screencapture -x /tmp/clankwork_test_scr.png 2>/dev/null && [ -f /tmp/clankwork_test_scr.png ] && SCR_OK=1
rm -f /tmp/clankwork_test_scr.png

if [ "$SCR_OK" -eq 1 ]; then
    echo "  Screen Recording: OK (from this terminal)"
else
    echo "  Screen Recording: MISSING or needs confirmation"
fi

echo ""
echo "NOTE: These tests check YOUR TERMINAL's permissions."
echo "The daemon runs under bun/node, which need SEPARATE permissions."
echo "Always add the binaries listed below, even if tests show OK."

echo ""

# --- Always show daemon binary paths ---
echo ""
echo "=== DAEMON BINARY PATHS ==="
echo ""
echo "The following binaries must be added to BOTH Accessibility AND Screen Recording:"
echo ""
echo "  Privacy & Security > Accessibility:"
echo "    + $BUN_PATH"
echo "    + $NODE_PATH"
[ -n "$PEEKABOO_NATIVE" ] && echo "    + $PEEKABOO_NATIVE"
echo ""
echo "  Privacy & Security > Screen Recording:"
echo "    + $BUN_PATH"
echo "    + $NODE_PATH"
[ -n "$PEEKABOO_NATIVE" ] && echo "    + $PEEKABOO_NATIVE"
echo ""
echo "IMPORTANT: After brew upgrade (node/bun), Cellar paths change."
echo "Re-run this script after brew upgrades to verify permissions."
echo ""

read -p "Open System Settings now? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Opening Accessibility settings..."
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    echo ""
    echo "Steps:"
    echo "  1. Click '+' at the bottom"
    echo "  2. Press Cmd+Shift+G in the file dialog"
    echo "  3. Paste the path shown above"
    echo "  4. Click 'Open', then enable the toggle"
    echo "  5. Repeat for each binary"
    echo ""
    read -p "Done with Accessibility? Press Enter to continue to Screen Recording..."
    echo ""
    echo "Opening Screen Recording settings..."
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
    echo ""
    echo "Repeat the same steps for Screen Recording."
    echo ""
    read -p "Done? Press Enter to verify..."
    echo ""

    # Re-test
    echo "Re-testing..."
    ACC_OK=0
    osascript -e 'tell application "System Events" to get name of every process' &>/dev/null && ACC_OK=1
    SCR_OK=0
    screencapture -x /tmp/clankwork_test_scr.png 2>/dev/null && [ -f /tmp/clankwork_test_scr.png ] && SCR_OK=1
    rm -f /tmp/clankwork_test_scr.png

    [ "$ACC_OK" -eq 1 ] && echo "  Accessibility: OK" || echo "  Accessibility: STILL MISSING"
    [ "$SCR_OK" -eq 1 ] && echo "  Screen Recording: OK" || echo "  Screen Recording: STILL MISSING"
fi
