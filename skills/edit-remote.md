---
name: edit-remote
description: Safe editing protocol for files on remote/external systems via SSH. Always download first, edit locally with Edit tool, upload back, verify, cleanup. Prevents data loss on remote servers.
trigger: Automatically invoked whenever editing any file on a remote/external system (SSH, SCP, or any non-local access method). No manual trigger needed.
---

# Remote File Editing Protocol (edit-remote)

## When this applies
Any time you need to modify a file that lives on a remote/external system - accessed via SSH, SCP, or any other remote method. This includes config files, scripts, service files, or any other file on a server you connect to.

## The Protocol (strict, no exceptions)

### Step 1: Check if file exists
```bash
ssh <host> 'test -f <remote-path> && echo "EXISTS" || echo "NEW"'
```
- If `NEW`: You may write the file directly via SSH (cat, heredoc, scp). Skip to Step 6.
- If `EXISTS`: Continue with Step 2. NEVER overwrite directly.

### Step 2: Download to local temp
```bash
scp <host>:<remote-path> /tmp/<descriptive-name>.json
```
- Always use a descriptive temp filename so you know what it is.

### Step 3: Read the file locally
- Use the `Read` tool to read `/tmp/<descriptive-name>.json` fully.
- Understand the complete structure before making any changes.

### Step 4: Edit locally with Edit tool
- Use the `Edit` tool for surgical, targeted changes.
- NEVER use Write on the temp file - it was downloaded from an existing file.
- Make only the changes needed. Preserve everything else.

### Step 5: Upload back to remote
```bash
scp /tmp/<descriptive-name>.json <host>:<remote-path>
```

### Step 6: Verify the upload
```bash
ssh <host> 'cat <remote-path> | head -20'  # or grep for your specific change
```
- Confirm the edit landed correctly on the remote system.

### Step 7: Cleanup local temp
```bash
rm -f /tmp/<descriptive-name>.json
```

## Rules

- **NEVER** use `cat > file << EOF`, heredoc, echo redirect, or any full-file-write method on existing remote files.
- **NEVER** use `sed -i`, `awk`, or inline editing commands on remote files - these can corrupt on failure.
- **NEVER** skip the read step. You must understand what you are editing before you edit it.
- **NEVER** skip the verify step. Confirm your change actually landed.
- If the file is a config (JSON, YAML, TOML): validate it locally before uploading (e.g. `python3 -c "import json; json.load(open('...'))"`)
- If the edit is high-risk: make a backup first: `ssh <host> 'cp <file> <file>.bak-$(date +%Y%m%d-%H%M%S)'`
- Multiple edits to the same file: do them ALL locally in one pass, then upload once. Don't upload-download-upload repeatedly.
