#!/bin/bash
# Restart the Qwen Telegram bot daemon

SCRIPT_DIR="$(dirname "$0")"

echo "[clankwork] Restarting..."
"$SCRIPT_DIR/clankwork-stop.sh"
sleep 2
"$SCRIPT_DIR/clankwork-start.sh"
