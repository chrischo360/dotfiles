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
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { basename, resolve } from "node:path";

const STATE_FILE = `${process.env.HOME}/.pi/agent/session-state.json`;
const HOOK_LOG = `${process.env.HOME}/.pi/agent/hook-debug.log`;

// Tool → emoji mapping (matches your Claude setup)
const TOOL_ICONS: Record<string, string> = {
	read: "📖",
	grep: "🔍",
	find: "🔍",
	ls: "🔍",
	edit: "✏️",
	write: "✏️",
	bash: "⚙️",
};

function log(msg: string): void {
	try {
		const line = `[${new Date().toTimeString().slice(0, 8)}] ${msg}\n`;
		const { appendFileSync } = require("node:fs");
		appendFileSync(HOOK_LOG, line);
	} catch {}
}

function updateState(status: string, toolName?: string): void {
	const paneId = process.env.TMUX_PANE;
	if (!paneId) return;

	try {
		let state: Record<string, unknown> = {};
		if (existsSync(STATE_FILE)) {
			state = JSON.parse(readFileSync(STATE_FILE, "utf-8"));
		}
		const sessions = (state.sessions as Record<string, Record<string, unknown>>) || {};
		sessions[paneId] = {
			...(sessions[paneId] || {}),
			status,
			tool: toolName || null,
			last_updated: new Date().toISOString(),
		};
		state.sessions = sessions;
		writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
	} catch {}
}

function getProjectName(cwd: string): string {
	try {
		const { execSync } = require("node:child_process");
		const root = execSync("git rev-parse --show-toplevel", { cwd, encoding: "utf-8" }).trim();
		return basename(root);
	} catch {
		return basename(cwd);
	}
}

export default function (pi: ExtensionAPI) {
	// Session start → active
	pi.on("session_start", async (_event, ctx) => {
		log("SessionStart hook fired");
		updateState("active");
		ctx.ui.setStatus("session", ctx.ui.theme.fg("success", "● active"));
	});

	// User submits input → active
	pi.on("input", async (_event, ctx) => {
		updateState("active");
		ctx.ui.setStatus("session", ctx.ui.theme.fg("accent", "🔄 working"));
	});

	// Tool activity tracking
	pi.on("tool_execution_start", async (event, ctx) => {
		const icon = TOOL_ICONS[event.toolName] || "⚙️";
		updateState("active", event.toolName);
		ctx.ui.setStatus("session", ctx.ui.theme.fg("accent", `${icon} ${event.toolName}`));
	});

	// Agent finished → idle + notification
	pi.on("agent_end", async (_event, ctx) => {
		updateState("idle");
		ctx.ui.setStatus("session", ctx.ui.theme.fg("success", "✅ ready"));
		log("Agent ended, sending notification");

		// macOS notification via terminal-notifier
		const project = getProjectName(ctx.cwd);
		try {
			const args = [
				"-title", "🤖 Pi Complete",
				"-message", `Repository: ${project}`,
				"-sound", "default",
			];

			// Add tmux context if available
			if (process.env.TMUX) {
				const { execSync } = require("node:child_process");
				const tmuxInfo = execSync("tmux display-message -p '#S:#I.#P [#W]'", { encoding: "utf-8" }).trim();
				args.push("-subtitle", tmuxInfo);
			}

			await pi.exec("terminal-notifier", args, { timeout: 5000 });
		} catch {
			// terminal-notifier not available, silently skip
		}
	});

	// Session shutdown
	pi.on("session_shutdown", async () => {
		log("Session shutdown");
		updateState("stopped");
	});

	// Context usage warning (check after each turn)
	pi.on("turn_end", async (_event, ctx) => {
		const usage = ctx.getContextUsage();
		if (!usage) return;

		const percentage = (usage.tokens / usage.maxTokens) * 100;
		if (percentage >= 80) {
			ctx.ui.setStatus(
				"context-warn",
				ctx.ui.theme.fg("warning", `⚠️ ${Math.round(percentage)}% context`)
			);

			// Notify once when crossing 80%
			const project = getProjectName(ctx.cwd);
			try {
				await pi.exec("terminal-notifier", [
					"-title", "Pi: Context Warning",
					"-message", `${Math.round(percentage)}% context used — consider /compact or /new`,
					"-sound", "default",
					"-group", `pi-context-${project}`,
				], { timeout: 5000 });
			} catch {}
		} else {
			ctx.ui.setStatus("context-warn", undefined);
		}
	});
}
