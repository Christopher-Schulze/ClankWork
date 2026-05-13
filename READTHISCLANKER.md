# ClankWork - Setup Instructions

> Set up ClankWork for the user.
>
> Walk the user through every step. Make it smooth, make it painless, make it work.
> If something breaks, read the error, verify the current documentation, and fix the actual issue.
> If the user needs to do something manually, you explain exactly WHY, WHERE, and HOW.
> You do as much as possible automatically. You ask the user only when you absolutely must.
>
> Now get to work.

---

## Step Zero: Get the Files

Before anything else, clone this repo so all config files, scripts, and skills are available locally:

```bash
git clone https://github.com/Christopher-Schulze/ClankWork.git
cd ClankWork
```

---

## What You're Building

A fully autonomous AI agent that runs 24/7 on the user's Mac as a background daemon, reachable via Telegram. It can administrate the Mac, automate desktop apps, work with Office files (DOCX/XLSX/PPTX/PDF), control browsers, and execute tasks while the user is away.

## Architecture

```
Telegram <-> qwen channel start <-> daemon-wrapper.ts <-> LaunchAgent (launchd)
                  |
                  +-- qwen --acp workers (background processing)
                  |
                  +-- MCP Servers: Peekaboo (desktop), Playwright (browser)
                  |
                  +-- Skills: Office, Computer Use, Browser, Design, ...
```

The daemon runs as a macOS LaunchAgent via `launchd`. A TypeScript wrapper (`daemon-wrapper.ts`) preserves Telegram session context across reboots by backing up `sessions.json` before the process shuts down.

## Requirements

Before you start, verify the user has:

- **macOS on Apple Silicon** (M1/M2/M3/M4) - Sequoia 15+ recommended, Ventura 13+ minimum
- **Telegram** installed on their phone or desktop
- **Internet connection** for downloads and Qwen Code authentication
- **Admin access** to their Mac (for Homebrew and System Settings)

The user needs a working Qwen Code authentication/provider setup or must configure one during setup.

---

## Quick Start (Automated)

If the setup scripts are available, run them in order. Each one is interactive and will guide the user:

```bash
# 1. Install all system dependencies (Homebrew, Node, Bun, Python, Qwen Code, MCP servers)
./setup/install-deps.sh

# 2. Configure everything (Telegram bot, Qwen Code auth, deploy all config files)
./setup/configure.sh

# 3. Set macOS permissions (checks what's missing, opens System Settings, guides the user)
./setup/check-permissions.sh
```

If any step fails, fall back to the manual installation below. Read the error, think about it, fix it.

---

## Manual Installation (Step by Step)

> If the scripts above didn't work or the user wants manual control, walk them through each phase below. Execute each step, verify each result. Don't skip verification. Don't assume anything worked - check it.

### Phase 1: System Dependencies

Homebrew is the package manager for macOS. Everything else installs through it.

**Step 1 - Homebrew:**
```bash
# Check if Homebrew is installed
which brew

# If NOT found, install it:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# After install, load Homebrew into the current shell:
eval "$(/opt/homebrew/bin/brew shellenv)"
```

**Step 2 - Core packages:**
```bash
brew install node bun python3 ripgrep
```
This gives us: Node.js (JavaScript runtime), Bun (TypeScript runtime for the daemon wrapper), Python 3 (for Office file skills), ripgrep (fast search, used by Qwen Code internally).

**Step 3 - Qwen Code CLI:**
```bash
bash -c "$(curl -fsSL https://qwen-code-assets.oss-cn-hangzhou.aliyuncs.com/installation/install-qwen.sh)"
```
Alternative if the official script fails: `brew install qwen-code`

Source: https://github.com/QwenLM/qwen-code

**Step 4 - Peekaboo MCP** (desktop screenshot + window management server):
```bash
npm install -g @steipete/peekaboo-mcp
```

**Verify ALL of the above** - every single one must return a valid path:
```bash
which qwen          # Expected: /opt/homebrew/bin/qwen
which bun           # Expected: /opt/homebrew/bin/bun
which node          # Expected: /opt/homebrew/bin/node
which python3       # Expected: /opt/homebrew/bin/python3
which peekaboo-mcp  # Expected: /opt/homebrew/bin/peekaboo-mcp
which rg            # Expected: /opt/homebrew/bin/rg
```

> If ANY of these returns "not found", stop and fix it before continuing. Do not proceed with missing dependencies.

### Phase 2: Python Packages

These power the Office file skills (DOCX, XLSX, PPTX, PDF) and data analysis. The `--break-system-packages` flag is required because Homebrew's Python is "externally managed".

```bash
pip3 install --break-system-packages \
    python-docx openpyxl xlsxwriter python-pptx \
    PyMuPDF pymupdf4llm pdfplumber pypdf pikepdf reportlab \
    markitdown pandas numpy pillow lxml beautifulsoup4
```

**Verify** - this must print "All OK":
```bash
/opt/homebrew/bin/python3 -c "import docx, openpyxl, pptx, fitz, pdfplumber, pypdf, pikepdf, reportlab, markitdown; print('All OK')"
```

> If any import fails, re-run the pip install for that specific package and check the error. Don't move on until ALL imports work.

### Phase 3: Playwright (Browser Automation)

Playwright gives the agent full browser control - clicking, typing, scraping, reading network traffic. It uses Chromium (bundled, ~500MB download).

```bash
npx playwright install chromium
```

Playwright MCP runs on demand via `npx @playwright/mcp@latest` - no global install needed. It's configured in `settings.json` and launches automatically when the agent needs a browser.

**Verify:**
```bash
ls ~/Library/Caches/ms-playwright/chromium-*/   # Should show chrome-mac-arm64 directory
```

### Phase 4: Create Telegram Bot

> You can't do this part yourself. The user has to do it on their phone or Telegram desktop app. Your job is to guide them through it step by step, explain what's happening, and collect the two values you need: the **bot token** and the **user ID**.

**Tell the user to create the bot:**

1. Open Telegram on your phone or desktop
2. Search for **@BotFather** and start a chat
3. Send `/newbot`
4. BotFather asks for a display name - pick anything (e.g. "My ClankWork Agent")
5. BotFather asks for a username - must end in `bot` (e.g. `my_clankwork_bot`)
6. BotFather responds with an **API token** - it looks like `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`
7. **Copy that token and paste it here in the terminal**

**Tell the user to get their Telegram ID:**

This is needed for the allowlist - it ensures ONLY the user's Telegram account can talk to the agent. Nobody else.

1. In Telegram, search for **@userinfobot** and start a chat
2. Send `/start`
3. The bot responds with user info - look for the **Id** field (a number like `987654321`)
4. **Copy that number and paste it here in the terminal**

> You MUST have both values before continuing. The bot token goes into `settings.json` as the Telegram API key. The user ID goes into the `allowedUsers` array as the only account permitted to interact. Ask the user directly: "Please paste your Telegram bot token" and then "Please paste your Telegram user ID". Store both for Phase 6. Do NOT proceed without them.

### Phase 5: Qwen Code Authentication

The agent uses the user's configured Qwen Code model/provider. Verify authentication before continuing.

For ClankWork, prefer a Qwen model route that supports images and video, because the desktop automation stack uses screenshots, screen recordings, charts, browser captures, and Office/PDF visual checks.

Recommended routes:

| Provider route | Model ID | Setup |
|----------------|----------|-------|
| Alibaba Cloud DashScope OpenAI-compatible API | `qwen3.6-plus` | `DASHSCOPE_API_KEY`, base URL `https://dashscope.aliyuncs.com/compatible-mode/v1` |
| Alibaba Cloud Coding Plan | Qwen models exposed by the plan | `qwen auth coding-plan` |

```bash
# Check if already authenticated
qwen auth status
```

If not authenticated:
```bash
# Start Qwen Code's authentication flow
qwen auth
```

Tell the user: "Follow the Qwen Code authentication flow. After it completes, come back here."

**Verify** - must show "authenticated":
```bash
qwen auth status
```

> If auth fails, check if `qwen` is in PATH (`which qwen`). If the user already has a working Qwen Code setup, `qwen auth status` will show it and you can skip this step.

### Phase 6: Deploy Configuration Files

> This is the critical phase. Every placeholder must be replaced with real values. Every file must land in the exact right location. Miss one and the whole thing breaks. Focus.

#### 6.1 - settings.json

This is the main config. It tells Qwen Code which MCP servers to use, which Telegram bot to connect, and how to behave. Copy the template and replace all `{{placeholders}}` with real values:

```bash
mkdir -p ~/.qwen/channels ~/.qwen/skills ~/scripts

sed -e "s|{{TELEGRAM_BOT_TOKEN}}|YOUR_TOKEN_HERE|g" \
    -e "s|{{TELEGRAM_USER_ID}}|YOUR_USER_ID_HERE|g" \
    -e "s|{{QWEN_MODEL_NAME}}|qwen3.6-plus|g" \
    -e "s|{{HOME_DIR}}|$HOME|g" \
    config/settings.template.json > ~/.qwen/settings.json

chmod 600 ~/.qwen/settings.json
```

For the full workstation workflow, set `{{QWEN_MODEL_NAME}}` to `qwen3.6-plus`.

#### 6.2 - Agent Rules (QWEN.md files)

Two rule files control the agent's behavior:

| File | Purpose | Target |
|------|---------|--------|
| `config/qwen-global.md` | Global coding/behavior rules for all sessions | `~/.qwen/QWEN.md` |
| `config/qwen-agent.md` | Daemon identity, skills, environment (Telegram-specific) | `~/QWEN.md` |

```bash
# Global rules (shared by daemon AND manual terminal sessions)
cp config/qwen-global.md ~/.qwen/QWEN.md

# Daemon-specific identity (loaded only when cwd = ~)
sed -e "s|{{HOME_DIR}}|$HOME|g" \
    -e "s|{{USERNAME}}|$(whoami)|g" \
    -e "s|{{TELEGRAM_BOT_NAME}}|@your_bot_username|g" \
    config/qwen-agent.md > ~/QWEN.md
```

#### 6.3 - Daemon Wrapper

The daemon-wrapper.ts contains a `{{QWEN_BIN}}` placeholder that must be replaced with the actual path to the qwen binary:

```bash
QWEN_PATH=$(which qwen)
sed -e "s|{{QWEN_BIN}}|$QWEN_PATH|g" \
    config/daemon-wrapper.ts > ~/.qwen/channels/daemon-wrapper.ts
```

> Do NOT just `cp` this file - the `{{QWEN_BIN}}` placeholder must be replaced or the daemon won't find qwen.

This TypeScript file (executed by Bun) wraps `qwen channel start` to preserve session context across reboots. It:
- Backs up `sessions.json` to `sessions.backup.json` on every write
- Restores from backup on startup if `sessions.json` was deleted
- Intercepts SIGTERM from launchd, backs up, then forwards to qwen

#### 6.4 - LaunchAgent

The plist template has three dynamic placeholders: `{{HOME_DIR}}`, `{{BUN_BIN}}` (path to bun binary), and `{{PATH_DIRS}}` (PATH for the daemon environment). All must be replaced:

```bash
BUN_BIN=$(which bun)
PATH_DIRS="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

sed -e "s|{{HOME_DIR}}|$HOME|g" \
    -e "s|{{BUN_BIN}}|$BUN_BIN|g" \
    -e "s|{{PATH_DIRS}}|$PATH_DIRS|g" \
    config/com.qwen.channel.template.plist > ~/Library/LaunchAgents/com.qwen.channel.plist
```

> If bun is NOT at `/opt/homebrew/bin/bun`, adjust PATH_DIRS to include the directory where bun actually lives.

LaunchAgent settings:
- `RunAtLoad: true` - starts at login
- `KeepAlive: true` - auto-restart on crash
- `ThrottleInterval: 10` - minimum 10 seconds between restarts
- `Nice: 5` - lower CPU priority than interactive apps
- `LowPriorityIO: true` - reduced disk I/O priority

#### 6.5 - Skills

```bash
rsync -a --exclude='__pycache__' --exclude='*.pyc' skills/ ~/.qwen/skills/
```

16 skills included:

| Skill | Purpose |
|-------|---------|
| docx | Word document creation/editing via python-docx |
| xlsx | Spreadsheet operations via openpyxl/xlsxwriter |
| pptx | Presentation creation/editing via python-pptx |
| pdf | Full PDF stack (PyMuPDF, pdfplumber, pypdf, pikepdf, reportlab) |
| computer-use | macOS desktop automation (Accessibility API, screencapture, Peekaboo) |
| playwright | Browser automation via Playwright MCP |
| edit-remote | Safe SSH file editing protocol |
| frontend-design | Production UI with SvelteKit + shadcn + Tailwind |
| webapp-testing | Test local web apps with Playwright |
| doc-coauthoring | Structured documentation co-authoring |
| theme-factory | Apply visual themes to any artifact |
| canvas-design | Create visual art/posters as PNG/PDF |
| algorithmic-art | Generative art with p5.js |
| slack-gif-creator | Animated GIFs optimized for Slack |
| mcp-builder | Build MCP servers |
| skill-creator | Create and optimize skills |

### Phase 7: Management Scripts

```bash
# Copy management scripts
cp scripts/clankwork-start.sh ~/scripts/
cp scripts/clankwork-stop.sh ~/scripts/
cp scripts/clankwork-restart.sh ~/scripts/
chmod +x ~/scripts/clankwork-*.sh

# Install CLI dispatcher (makes 'clankwork' available from anywhere)
cp scripts/clankwork /opt/homebrew/bin/clankwork
chmod +x /opt/homebrew/bin/clankwork
```

Usage:
```bash
clankwork start     # Start daemon
clankwork stop      # Stop daemon (safe - won't kill manual qwen sessions)
clankwork restart   # Restart daemon
clankwork status    # Show running processes
clankwork update    # Update all dependencies to latest versions
```

### Phase 8: macOS Permissions

> Pay close attention. This is the one part that CANNOT be automated. macOS System Integrity Protection (SIP) prevents any script from granting TCC permissions. You must guide the user through this manually. Explain WHY each permission is needed and exactly HOW to add it.

**WHY these permissions are needed:**
- **Accessibility**: Allows the agent to read UI elements (buttons, text fields, menus) and click them via osascript. Without this, computer-use and desktop automation won't work.
- **Screen Recording**: Allows the agent to take screenshots via `screencapture`. Without this, the agent can't see the screen for vision tasks.

**First, detect the exact binary paths** the user needs to add:
```bash
echo "=== Add these binaries to BOTH Accessibility AND Screen Recording ==="
echo ""
echo "1. bun:      $(readlink -f $(which bun))"
echo "2. node:     $(readlink -f $(which node))"
echo "3. peekaboo: $(npm root -g)/@steipete/peekaboo-mcp/peekaboo"
```

These are the REAL Cellar paths (not symlinks). macOS TCC tracks the real binary, not the symlink.

**Walk the user through adding Accessibility permissions:**

1. Open the correct System Settings page:
```bash
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
```

2. Tell the user:
   - Click the `+` button at the bottom of the list
   - In the file dialog that opens, press `Cmd+Shift+G` (Go to Folder)
   - Paste the FULL path of the binary (get it from `readlink -f $(which bun)` - e.g. `/opt/homebrew/Cellar/bun/<version>/bin/bun`)
   - Click "Open"
   - Make sure the toggle next to the entry is ON (blue)
   - Repeat for all 3 binaries (bun, node, peekaboo)

3. **Then do the same for Screen Recording:**
```bash
open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
```
   Same steps: `+` button, `Cmd+Shift+G`, paste path, Open, toggle ON. All 3 binaries again.

**Optional - Microphone** (only if the user wants audio capture):
```bash
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
```
Add `node` and `peekaboo` only.

**Verify permissions work:**
```bash
# Test Accessibility
osascript -e 'tell application "System Events" to get name of every process' && echo "Accessibility: OK" || echo "Accessibility: FAILED"

# Test Screen Recording
screencapture -x /tmp/clankwork_test.png && echo "Screen Recording: OK" || echo "Screen Recording: FAILED"
rm -f /tmp/clankwork_test.png
```

> If verification fails, the user likely added the symlink path instead of the Cellar path, or forgot to toggle ON. Check the paths again with `readlink -f $(which bun)`.

#### Important: Homebrew Upgrade Warning

Tell the user: Homebrew stores binaries in versioned paths like `/opt/homebrew/Cellar/node/<version>/bin/node`. When you run `brew upgrade node` or `brew upgrade bun`, the version number in the path changes and macOS no longer recognizes the permission. You'll need to re-add the new binary paths in System Settings after every Homebrew upgrade. Run `./setup/check-permissions.sh` to check.

### Phase 9: Start and Verify

> Almost there. Start the daemon and verify it.

**Start the daemon:**
```bash
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.qwen.channel.plist
```

**Wait 3 seconds**, then check:
```bash
sleep 3
clankwork status
```

This should show running processes (bun daemon-wrapper, node qwen channel, node --acp workers).

**Check the log:**
```bash
tail -20 ~/.qwen/channels/launchd.log
```

Expected output - all 4 lines must be present:
```
[daemon-wrapper] Sessions restored from backup - context from last run available
[Channel] Starting 1 channel(s): qwen
[Channel] "qwen" connected.
[Channel] Running 1 channel(s). Press Ctrl+C to stop.
```

**Final test - tell the user to send a message to their bot on Telegram.** Any message works. The bot should respond within a few seconds.

> If the bot doesn't respond: check `clankwork status` (running?), check the log for errors, verify the bot token and user ID in `~/.qwen/settings.json` are correct. If it says "Session not found", restart with `clankwork restart`.

**The daemon auto-starts at login and auto-restarts on crash.** The user doesn't need to do anything after a reboot - ClankWork comes back on its own.

> NOTE: The user's normal `qwen` terminal sessions are completely independent. ClankWork runs as a separate background daemon. Both can run simultaneously without interfering.

---

## File Reference

| File | Location | Purpose |
|------|----------|---------|
| `settings.json` | `~/.qwen/settings.json` | MCP servers, Telegram channel config, model settings |
| `QWEN.md` (global) | `~/.qwen/QWEN.md` | Coding rules, behavior guidelines (all sessions) |
| `QWEN.md` (daemon) | `~/QWEN.md` | Daemon identity, skills catalog, system environment |
| `daemon-wrapper.ts` | `~/.qwen/channels/daemon-wrapper.ts` | Session backup wrapper (Bun script) |
| `com.qwen.channel.plist` | `~/Library/LaunchAgents/` | macOS LaunchAgent definition |
| `clankwork-start.sh` | `~/scripts/` | Start daemon via launchctl bootstrap |
| `clankwork-stop.sh` | `~/scripts/` | Stop daemon (safe, won't kill manual sessions) |
| `clankwork-restart.sh` | `~/scripts/` | Stop + start |
| `clankwork` | `/opt/homebrew/bin/` | CLI dispatcher for start/stop/restart/status |
| Qwen auth files | `~/.qwen/` | Credentials/config created by Qwen Code authentication |
| `sessions.json` | `~/.qwen/channels/` | Telegram user-to-session mapping (runtime) |
| `sessions.backup.json` | `~/.qwen/channels/` | Session backup (survives reboots) |
| `launchd.log` | `~/.qwen/channels/` | Daemon log output |
| Skills (16) | `~/.qwen/skills/` | Task-specific knowledge and patterns |

## Symlink Chain Reference

Homebrew installs binaries to `/opt/homebrew/bin/` as symlinks to versioned Cellar paths:

```
/opt/homebrew/bin/qwen         -> ../Cellar/qwen-code/<version>/bin/qwen
/opt/homebrew/bin/node         -> ../Cellar/node/<version>/bin/node
/opt/homebrew/bin/bun          -> ../Cellar/bun/<version>/bin/bun
/opt/homebrew/bin/python3      -> ../Cellar/python@<version>/libexec/bin/python3
/opt/homebrew/bin/peekaboo-mcp -> ../lib/node_modules/@steipete/peekaboo-mcp/dist/index.js
/opt/homebrew/bin/clankwork      standalone script (not a symlink)
```

TCC permissions are granted to the **Cellar path** (with version number). After `brew upgrade`, paths change and permissions must be re-added.

The `qwen` binary is a Node.js script. The `--acp` workers spawned by `qwen channel` always run on Node (not Bun).

## MCP Servers

| Server | Install | Config | Purpose |
|--------|---------|--------|---------|
| **Peekaboo** | `npm install -g @steipete/peekaboo-mcp` | `settings.json` mcpServers.peekaboo | Desktop screenshots, app window list, bounds |
| **Playwright** | via `npx @playwright/mcp@latest` (no install) | `settings.json` mcpServers.playwright | Full browser automation (ARIA-based, no screenshots needed) |

Optional (configured but excluded by default):
| Server | Install | Purpose |
|--------|---------|---------|
| Sequential Thinking | via npx | Step-by-step reasoning |
| DuckDuckGo Search | via npx | Web search |

To enable optional servers: remove them from `mcp.excluded` array in `settings.json`.

## Troubleshooting

### Bot not responding
```bash
clankwork status                              # Is it running?
tail -50 ~/.qwen/channels/launchd.log       # Check for errors
clankwork restart                             # Try restarting
```

### "Session lost" after reboot
The daemon-wrapper should prevent this. Check:
```bash
ls -la ~/.qwen/channels/sessions*.json      # Both files should exist
```
If only backup exists, the restore worked. If neither exists, check the log.

### Permissions stopped working after brew upgrade
```bash
readlink -f $(which node)    # Check new path
readlink -f $(which bun)
./setup/check-permissions.sh  # Re-check and re-add
```

### High CPU usage
```bash
ps aux | grep -E "qwen|daemon-wrapper" | grep -v grep
```
Normal idle: 0.0% CPU per process, ~50MB each. If CPU is high, restart:
```bash
clankwork restart
```

### Daemon won't start
```bash
# Check if plist is valid
plutil ~/Library/LaunchAgents/com.qwen.channel.plist

# Check if already loaded
launchctl list | grep qwen

# If loaded but not running, unload and reload
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.qwen.channel.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.qwen.channel.plist
```

## Uninstall

```bash
# Stop daemon
clankwork stop

# Remove LaunchAgent
rm ~/Library/LaunchAgents/com.qwen.channel.plist

# Remove scripts
rm ~/scripts/clankwork-start.sh ~/scripts/clankwork-stop.sh ~/scripts/clankwork-restart.sh
rm /opt/homebrew/bin/clankwork

# Remove daemon files
rm ~/QWEN.md
rm ~/.qwen/channels/daemon-wrapper.ts
rm ~/.qwen/channels/sessions*.json
rm ~/.qwen/channels/launchd.log

# Optional: remove all qwen config (includes ALL settings, skills, history)
# rm -rf ~/.qwen

## Customization

### Change the agent's language
Edit `~/QWEN.md`, section "Language". Default is German.

### Change the agent's personality
Edit `~/QWEN.md`, section "Identity & Context".

### Add/remove skills
Copy skill folders to `~/.qwen/skills/` or remove them. Update the skills table in `~/QWEN.md`.

### Add MCP servers
Add entries to `mcpServers` in `~/.qwen/settings.json`. Set `trust: true` for auto-approval.

### Change approval mode
In `settings.json`, change `channels.qwen.approvalMode`:
- `"yolo"` - full autonomy, no approval needed (default)
- `"auto"` - auto-approve safe actions, ask for risky ones
- `"manual"` - ask for approval on everything

---

> Setup complete. The user's Mac now has a persistent local AI agent running in the background, reachable through Telegram, with Office workflows, browser automation, desktop control, vision-capable workflows, and 16 skills.

---

> One more thing: if something doesn't match, a version changed, or a command fails, read the current docs, understand the mismatch, and fix the actual issue. The structure of this guide is your rail - follow it. Deviate only when you must, return immediately when you can.

## DONE - Welcome to the Gang!

ClankWork 🔫🔫
