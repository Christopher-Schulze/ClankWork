#!/usr/bin/env bun

/**
 * Qwen Channel Daemon Wrapper
 *
 * Wraps `qwen channel start` so that session context survives Mac reboots.
 *
 * Problem: on clean shutdown (SIGTERM from launchd), qwen deletes sessions.json
 * which maps Telegram user IDs to session UUIDs. The actual chat history (.jsonl)
 * files remain on disk - only the ID mapping is lost.
 *
 * Solution:
 * - Mirror sessions.json to sessions.backup.json on every write
 * - On startup: restore from backup if sessions.json is missing
 * - On shutdown: final backup before forwarding SIGTERM to qwen child
 * - qwen child runs in its own process group so it only gets signals we forward
 *
 * Normal `qwen` terminal usage is completely unaffected - this wrapper is only
 * used by the launchd daemon.
 */

import { existsSync, copyFileSync } from "fs";
import { watch } from "fs";
import { join } from "path";
import { homedir } from "os";
import { spawn } from "child_process";

const QWEN_BIN = "{{QWEN_BIN}}";  // replaced by configure.sh with actual path (e.g. /opt/homebrew/bin/qwen)
const channelsDir = join(homedir(), ".qwen", "channels");
const sessionsPath = join(channelsDir, "sessions.json");
const backupPath = join(channelsDir, "sessions.backup.json");

function log(msg: string) {
  process.stdout.write(`[daemon-wrapper] ${msg}\n`);
}

function backup() {
  if (existsSync(sessionsPath)) {
    try {
      copyFileSync(sessionsPath, backupPath);
    } catch {}
  }
}

// On startup: restore sessions.json from backup if qwen deleted it on last shutdown
if (!existsSync(sessionsPath) && existsSync(backupPath)) {
  copyFileSync(backupPath, sessionsPath);
  log("Sessions restored from backup - context from last run available");
}

// Mirror sessions.json to backup on every write
const watcher = watch(channelsDir, { persistent: false }, (_event, filename) => {
  if (filename === "sessions.json") backup();
});

// Run qwen in a new process group so launchd's SIGTERM only hits this wrapper,
// not qwen directly - giving us time to backup before forwarding the signal
const child = spawn(QWEN_BIN, ["channel", "start"], {
  stdio: "inherit",
  detached: true,
});

let shuttingDown = false;

function shutdown(sig: NodeJS.Signals) {
  if (shuttingDown) return;
  shuttingDown = true;
  watcher.close();
  backup(); // final backup before qwen's SIGTERM handler deletes sessions.json
  log(`Shutdown (${sig}) - session backed up`);
  if (child.pid) {
    try {
      process.kill(child.pid, sig);
    } catch {}
  }
}

process.on("SIGTERM", () => shutdown("SIGTERM"));
process.on("SIGINT", () => shutdown("SIGINT"));

child.on("exit", (code) => {
  watcher.close();
  process.exit(code ?? 0);
});
