/**
 * Session Status & Notifications Extension
 *
 * Replicates Claude Code hooks:
 * - macOS notifications on session end (terminal-notifier)
 * - Session state tracking for tmux statusline
 * - Tool activity tracking (reading, editing, running, etc.)
 * - Context usage warnings at 80%+
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { readFileSync, writeFileSync, existsSync, appendFileSync } from "node:fs";
import { basename } from "node:path";
import { execSync, spawn } from "node:child_process";

const STATE_FILE = `${process.env.HOME}/.pi/agent/session-state.json`;
const HOOK_LOG = `${process.env.HOME}/.pi/agent/hook-debug.log`;

// Maps Pi tool names → Claude-compatible action strings (used by tmux pi_status.sh)
const TOOL_ACTION: Record<string, string> = {
	read: "reading",
	find: "reading",
	ls: "reading",
	grep: "searching",
	edit: "editing",
	write: "editing",
	bash: "running",
};

// Action → display icon (mirrors Claude STATE_FLOW.md)
const ACTION_ICONS: Record<string, string> = {
	reading: "📖",
	searching: "🔍",
	editing: "✏️",
	running: "⚙️",
};

function log(msg: string): void {
	try {
		appendFileSync(HOOK_LOG, `[${new Date().toTimeString().slice(0, 8)}] ${msg}\n`);
	} catch {}
}

interface SessionContext {
	dir: string;
	repo: string;
	branch: string;
	tmux_session: string;
	tmux_pane: string;
}

function getContext(cwd?: string): SessionContext {
	const dir = cwd || process.cwd();
	const paneId = process.env.TMUX_PANE || "";
	let repo = basename(dir);
	let branch = "";
	let tmux_session = "unknown";

	try {
		const root = execSync("git rev-parse --show-toplevel", {
			cwd: dir,
			encoding: "utf-8",
			stdio: ["pipe", "pipe", "pipe"],
		}).trim();
		repo = basename(root);
		branch = execSync("git branch --show-current", {
			cwd: dir,
			encoding: "utf-8",
			stdio: ["pipe", "pipe", "pipe"],
		}).trim();
	} catch {}

	try {
		if (process.env.TMUX) {
			tmux_session = execSync("tmux display-message -p '#S'", { encoding: "utf-8" }).trim();
		}
	} catch {}

	return { dir, repo, branch, tmux_session, tmux_pane: paneId };
}

function readState(): Record<string, unknown> {
	try {
		if (existsSync(STATE_FILE)) return JSON.parse(readFileSync(STATE_FILE, "utf-8"));
	} catch {}
	return { sessions: {} };
}

function writeState(state: Record<string, unknown>): void {
	try {
		writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
	} catch {}
}

function updateSession(status: string, action?: string, context?: SessionContext): void {
	const paneId = process.env.TMUX_PANE;
	if (!paneId) return;

	const state = readState();
	const sessions = (state.sessions as Record<string, Record<string, unknown>>) || {};
	const existing = sessions[paneId] || {};

	// Lazily capture context if this pane doesn't have it yet (heals old-format entries)
	const effectiveContext = context ?? (!existing.context ? getContext() : undefined);

	sessions[paneId] = {
		...existing,
		status,
		last_update: new Date().toISOString(),
		...(effectiveContext ? { context: effectiveContext } : {}),
	};

	if (action) {
		sessions[paneId].action = action;
	} else {
		delete sessions[paneId].action;
	}

	state.sessions = sessions;
	writeState(state);
}

function removeSession(): void {
	const paneId = process.env.TMUX_PANE;
	if (!paneId) return;

	const state = readState();
	const sessions = state.sessions as Record<string, unknown>;
	if (sessions) {
		delete sessions[paneId];
		state.sessions = sessions;
		writeState(state);
	}
}

function notify(args: string[]): void {
	try {
		const proc = spawn("terminal-notifier", args, { detached: true, stdio: "ignore" });
		proc.unref();
	} catch {}
}

// Shared agent notification hook (also used by Claude and Devin).
// Handles repo/tmux context + click-to-focus internally.
const SHARED_NOTIFY = `${process.env.HOME}/dotfiles/agent/hooks/notify.sh`;

function notifyShared(agent: string): void {
	try {
		const proc = spawn(SHARED_NOTIFY, [agent], { detached: true, stdio: "ignore" });
		proc.unref();
	} catch {}
}

function getProjectName(cwd?: string): string {
	const dir = cwd || process.cwd();
	try {
		const root = execSync("git rev-parse --show-toplevel", {
			cwd: dir,
			encoding: "utf-8",
			stdio: ["pipe", "pipe", "pipe"],
		}).trim();
		return basename(root);
	} catch {
		return basename(dir);
	}
}

export default function (pi: ExtensionAPI) {
	// Session start → active, capture context for tmux statusline
	pi.on("session_start", async (_event, ctx) => {
		log("session_start fired");
		const context = getContext((ctx as { cwd?: string }).cwd);
		updateSession("active", undefined, context);
		ctx.ui.setStatus("session", ctx.ui.theme.fg("success", "● active"));
	});

	// User submits input → active
	pi.on("input", async (_event, ctx) => {
		updateSession("active");
		ctx.ui.setStatus("session", ctx.ui.theme.fg("accent", "⚡ working"));
	});

	// Tool starts → active with tool-specific action icon
	pi.on("tool_execution_start", async (event, ctx) => {
		const toolName = ((event as { toolName: string }).toolName || "").toLowerCase();
		const action = TOOL_ACTION[toolName] || "running";
		const icon = ACTION_ICONS[action] || "⚙️";
		updateSession("active", action);
		ctx.ui.setStatus("session", ctx.ui.theme.fg("accent", `${icon} ${toolName}`));
	});

	// Agent finished responding → idle + macOS notification
	pi.on("agent_end", async (_event, ctx) => {
		updateSession("idle");
		ctx.ui.setStatus("session", ctx.ui.theme.fg("success", "✅ ready"));
		log("agent_end fired");

		notifyShared("Pi");
	});

	// Session ends → remove from state file (prevents stale accumulation)
	pi.on("session_shutdown", async () => {
		log("session_shutdown fired");
		removeSession();
	});

	// After each turn → check context usage, warn at 80%+
	pi.on("turn_end", async (_event, ctx) => {
		try {
			const usage = (ctx as { getContextUsage?: () => { tokens: number; maxTokens: number } | null }).getContextUsage?.();
			if (!usage) return;

			const percentage = (usage.tokens / usage.maxTokens) * 100;
			if (percentage >= 80) {
				ctx.ui.setStatus("context-warn", ctx.ui.theme.fg("warning", `⚠️ ${Math.round(percentage)}% context`));
				const cwd = (ctx as { cwd?: string }).cwd;
				const project = getProjectName(cwd);
				notify([
					"-title", "Pi: Context Warning",
					"-message", `${Math.round(percentage)}% context used — consider /compact or /new`,
					"-sound", "default",
					"-group", `pi-context-${project}`,
				]);
			} else {
				ctx.ui.setStatus("context-warn", undefined);
			}
		} catch {}
	});
}
