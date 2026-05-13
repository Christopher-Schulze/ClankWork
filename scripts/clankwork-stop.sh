#!/bin/bash
# Stop the Qwen Telegram bot daemon and all associated processes

PLIST="$HOME/Library/LaunchAgents/com.qwen.channel.plist"

echo "[clankwork] Stopping..."

# Unload LaunchAgent (kills daemon-wrapper + qwen channel + --acp workers)
launchctl bootout gui/$(id -u) "$PLIST" 2>/dev/null

# Kill any orphaned daemon processes that survived unload
# NOTE: do NOT kill "qwen --acp" broadly - those workers also exist in manual coding sessions
pkill -f "daemon-wrapper.ts" 2>/dev/null
pkill -f "qwen channel" 2>/dev/null

# Verify - only check daemon processes, not --acp (which may belong to manual sessions)
sleep 1
REMAINING=$(ps aux | grep -E "qwen channel|daemon-wrapper" | grep -v grep | wc -l | tr -d ' ')
if [ "$REMAINING" -eq 0 ]; then
    echo "[clankwork] Stopped. All processes terminated."
else
    echo "[clankwork] Warning: $REMAINING process(es) still running:"
    ps aux | grep -E "qwen channel|daemon-wrapper" | grep -v grep | awk '{print "  PID", $2, $11, $12}'
fi
