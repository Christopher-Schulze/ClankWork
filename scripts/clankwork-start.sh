#!/bin/bash
# Start the Qwen Telegram bot daemon via LaunchAgent

PLIST="$HOME/Library/LaunchAgents/com.qwen.channel.plist"

echo "[clankwork] Starting..."

# Check if already running
if pgrep -f "qwen channel" > /dev/null 2>&1; then
    echo "[clankwork] Already running:"
    ps aux | grep -E "qwen (channel|--acp)|daemon-wrapper" | grep -v grep | awk '{printf "  PID %s  %s%%  %s %s\n", $2, $3, $11, $12}'
    exit 0
fi

# Load LaunchAgent
launchctl bootstrap gui/$(id -u) "$PLIST" 2>/dev/null

# Wait for startup
sleep 3

# Verify
if pgrep -f "qwen channel" > /dev/null 2>&1; then
    echo "[clankwork] Running:"
    ps aux | grep -E "qwen (channel|--acp)|daemon-wrapper" | grep -v grep | awk '{printf "  PID %s  %s%%  %s %s\n", $2, $3, $11, $12}'
    echo "[clankwork] Log: $HOME/.qwen/channels/launchd.log"
else
    echo "[clankwork] Error: failed to start. Check log:"
    tail -10 "$HOME/.qwen/channels/launchd.log"
    exit 1
fi
