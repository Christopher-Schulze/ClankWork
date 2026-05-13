#!/bin/bash
# ClankWork - Interactive configuration and deployment
# Asks for credentials, detects paths dynamically, deploys all files

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLANKWORK_DIR="$(dirname "$SCRIPT_DIR")"
HOME_DIR="$HOME"
# Capitalize first letter of username for display
RAW_USER="$(whoami)"
USERNAME="$(echo "${RAW_USER:0:1}" | tr '[:lower:]' '[:upper:]')${RAW_USER:1}"

# Ensure Homebrew is in PATH
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null)" || true

echo "=== ClankWork Configuration ==="
echo ""
echo "Home directory: $HOME_DIR"
echo "Username: $USERNAME"
echo ""

# --- Detect binary paths ---
echo "--- Detecting paths ---"
QWEN_BIN=$(which qwen 2>/dev/null || echo "")
BUN_BIN=$(which bun 2>/dev/null || echo "")
NODE_BIN=$(which node 2>/dev/null || echo "")

if [ -z "$QWEN_BIN" ] || [ -z "$BUN_BIN" ] || [ -z "$NODE_BIN" ]; then
    echo "ERROR: Missing dependencies. Run ./setup/install-deps.sh first."
    [ -z "$QWEN_BIN" ] && echo "  qwen: NOT FOUND"
    [ -z "$BUN_BIN" ] && echo "  bun: NOT FOUND"
    [ -z "$NODE_BIN" ] && echo "  node: NOT FOUND"
    exit 1
fi

NODE_DIR=$(dirname "$NODE_BIN")
# Build PATH, avoid duplicating /opt/homebrew/bin if node is already there
if [ "$NODE_DIR" = "/opt/homebrew/bin" ]; then
    PATH_DIRS="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
else
    PATH_DIRS="$NODE_DIR:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
fi

echo "  qwen: $QWEN_BIN"
echo "  bun:  $BUN_BIN"
echo "  node: $NODE_BIN"
echo "  PATH for daemon: $PATH_DIRS"
echo ""

# --- Telegram Bot Setup ---
echo "--- Telegram Bot ---"
echo ""
echo "If you don't have a Telegram bot yet:"
echo "  1. Open Telegram, search for @BotFather"
echo "  2. Send /newbot"
echo "  3. Choose a name (e.g. 'My ClankWork')"
echo "  4. Choose a username (e.g. 'my_qwen_bot')"
echo "  5. Copy the API token BotFather gives you"
echo ""
read -p "Telegram Bot Token: " TELEGRAM_BOT_TOKEN
echo ""
echo "To get your Telegram User ID:"
echo "  1. Open Telegram, search for @userinfobot"
echo "  2. Send /start"
echo "  3. Copy the 'Id' number"
echo ""
read -p "Telegram User ID: " TELEGRAM_USER_ID
echo ""
read -p "Telegram Bot Name (e.g. @my_qwen_bot): " TELEGRAM_BOT_NAME
echo ""
echo "Recommended Qwen models for ClankWork:"
echo "  qwen3.6-plus                         DashScope / Alibaba Cloud"
echo ""
read -p "Qwen model name for the daemon (default: qwen3.6-plus): " QWEN_MODEL_NAME
QWEN_MODEL_NAME="${QWEN_MODEL_NAME:-qwen3.6-plus}"
echo ""

if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_USER_ID" ]; then
    echo "ERROR: Bot token and user ID are required."
    exit 1
fi

echo "--- Deploying files ---"
echo ""

# --- Create directories ---
mkdir -p "$HOME_DIR/.qwen/channels"
mkdir -p "$HOME_DIR/.qwen/skills"
mkdir -p "$HOME_DIR/scripts"
mkdir -p "$HOME_DIR/Library/LaunchAgents"

# --- settings.json ---
if [ -f "$HOME_DIR/.qwen/settings.json" ]; then
    echo "WARNING: $HOME_DIR/.qwen/settings.json already exists."
    read -p "Overwrite? (y/n) " -n 1 -r
    echo ""
    [[ ! $REPLY =~ ^[Yy]$ ]] && echo "Skipping settings.json" && SKIP_SETTINGS=1
fi
if [ -z "$SKIP_SETTINGS" ]; then
    sed -e "s|{{TELEGRAM_BOT_TOKEN}}|$TELEGRAM_BOT_TOKEN|g" \
        -e "s|{{TELEGRAM_USER_ID}}|$TELEGRAM_USER_ID|g" \
        -e "s|{{QWEN_MODEL_NAME}}|$QWEN_MODEL_NAME|g" \
        -e "s|{{HOME_DIR}}|$HOME_DIR|g" \
        "$CLANKWORK_DIR/config/settings.template.json" > "$HOME_DIR/.qwen/settings.json"
    chmod 600 "$HOME_DIR/.qwen/settings.json"
    echo "  settings.json -> ~/.qwen/settings.json"
fi

# --- QWEN.md (global rules) ---
if [ ! -f "$HOME_DIR/.qwen/QWEN.md" ]; then
    cp "$CLANKWORK_DIR/config/qwen-global.md" "$HOME_DIR/.qwen/QWEN.md"
    echo "  qwen-global.md -> ~/.qwen/QWEN.md"
else
    echo "  ~/.qwen/QWEN.md already exists, skipping"
fi

# --- QWEN.md (daemon agent identity) ---
if [ -f "$HOME_DIR/QWEN.md" ]; then
    echo "WARNING: $HOME_DIR/QWEN.md already exists."
    read -p "Overwrite? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "  Skipping ~/QWEN.md"
    else
        sed -e "s|{{HOME_DIR}}|$HOME_DIR|g" \
            -e "s|{{USERNAME}}|$USERNAME|g" \
            -e "s|{{TELEGRAM_BOT_NAME}}|$TELEGRAM_BOT_NAME|g" \
            "$CLANKWORK_DIR/config/qwen-agent.md" > "$HOME_DIR/QWEN.md"
        echo "  qwen-agent.md -> ~/QWEN.md"
    fi
else
    sed -e "s|{{HOME_DIR}}|$HOME_DIR|g" \
        -e "s|{{USERNAME}}|$USERNAME|g" \
        -e "s|{{TELEGRAM_BOT_NAME}}|$TELEGRAM_BOT_NAME|g" \
        "$CLANKWORK_DIR/config/qwen-agent.md" > "$HOME_DIR/QWEN.md"
    echo "  qwen-agent.md -> ~/QWEN.md"
fi

# --- daemon-wrapper.ts (replace qwen path) ---
sed -e "s|{{QWEN_BIN}}|$QWEN_BIN|g" \
    "$CLANKWORK_DIR/config/daemon-wrapper.ts" > "$HOME_DIR/.qwen/channels/daemon-wrapper.ts"
echo "  daemon-wrapper.ts -> ~/.qwen/channels/daemon-wrapper.ts (qwen=$QWEN_BIN)"

# --- LaunchAgent plist (replace all dynamic paths) ---
sed -e "s|{{HOME_DIR}}|$HOME_DIR|g" \
    -e "s|{{BUN_BIN}}|$BUN_BIN|g" \
    -e "s|{{PATH_DIRS}}|$PATH_DIRS|g" \
    "$CLANKWORK_DIR/config/com.qwen.channel.template.plist" > "$HOME_DIR/Library/LaunchAgents/com.qwen.channel.plist"
echo "  plist -> ~/Library/LaunchAgents/com.qwen.channel.plist (bun=$BUN_BIN)"

# --- Skills ---
echo "  Copying skills..."
rsync -a --exclude='__pycache__' --exclude='*.pyc' "$CLANKWORK_DIR/skills/" "$HOME_DIR/.qwen/skills/"
echo "  skills/ -> ~/.qwen/skills/ ($(find "$CLANKWORK_DIR/skills" -name 'SKILL.md' -o -name 'edit-remote.md' | wc -l | tr -d ' ') skills)"

# --- Management scripts ---
cp "$CLANKWORK_DIR/scripts/clankwork-start.sh" "$HOME_DIR/scripts/clankwork-start.sh"
cp "$CLANKWORK_DIR/scripts/clankwork-stop.sh" "$HOME_DIR/scripts/clankwork-stop.sh"
cp "$CLANKWORK_DIR/scripts/clankwork-restart.sh" "$HOME_DIR/scripts/clankwork-restart.sh"
cp "$CLANKWORK_DIR/scripts/clankwork-update.sh" "$HOME_DIR/scripts/clankwork-update.sh"
chmod +x "$HOME_DIR/scripts/clankwork-*.sh"
echo "  scripts -> ~/scripts/clankwork-*.sh (start, stop, restart, update)"

# --- clankwork dispatcher in /opt/homebrew/bin (already in PATH via brew) ---
cp "$CLANKWORK_DIR/scripts/clankwork" "/opt/homebrew/bin/clankwork"
chmod +x "/opt/homebrew/bin/clankwork"
echo "  clankwork -> /opt/homebrew/bin/clankwork"

echo ""
echo "--- Qwen Code Authentication ---"
echo ""
# Check if already authenticated
AUTH_STATUS=$(qwen auth status 2>&1 || true)
if echo "$AUTH_STATUS" | grep -qi "authenticated\|logged in\|valid"; then
    echo "Already authenticated."
    echo "$AUTH_STATUS"
else
    echo "You need a configured Qwen Code authentication/provider setup to use ClankWork."
    echo ""
    echo "Follow the Qwen Code authentication flow."
    echo ""
    echo "After authentication succeeds, come back here - the script will continue automatically."
    echo ""
    read -p "Press Enter to start Qwen Code authentication..."
    echo ""
    echo "Running: qwen auth"
    qwen auth
    echo ""
    # Verify auth worked
    AUTH_CHECK=$(qwen auth status 2>&1 || true)
    if echo "$AUTH_CHECK" | grep -qi "authenticated\|logged in\|valid"; then
        echo "Authentication successful!"
    else
        echo "WARNING: Authentication may not have completed."
        echo "You can retry later with: qwen auth"
        echo ""
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo ""
        [[ ! $REPLY =~ ^[Yy]$ ]] && echo "Setup paused. Run this script again after login." && exit 1
    fi
fi
echo ""

echo "--- Starting Daemon ---"
echo ""
launchctl bootstrap gui/$(id -u) "$HOME_DIR/Library/LaunchAgents/com.qwen.channel.plist" 2>/dev/null || true
sleep 3

# Verify
if ps aux | grep -E "qwen channel|daemon-wrapper" | grep -v grep > /dev/null 2>&1; then
    echo "ClankWork is running!"
    ps aux | grep -E "qwen (channel|--acp)|daemon-wrapper" | grep -v grep | awk '{printf "  PID %s  %s %s\n", $2, $11, $12}'
else
    echo "WARNING: ClankWork may not have started. Check log:"
    echo "  tail -20 ~/.qwen/channels/launchd.log"
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Commands:"
echo "  clankwork start    - Start daemon"
echo "  clankwork stop     - Stop daemon"
echo "  clankwork restart  - Restart daemon"
echo "  clankwork status   - Show status"
echo ""
echo "Next: Run ./setup/check-permissions.sh to verify macOS permissions."
echo "Then send a message to your bot on Telegram to test."
