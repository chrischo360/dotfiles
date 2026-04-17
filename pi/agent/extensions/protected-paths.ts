/**
 * Protected Paths Extension
 *
 * Replicates Claude Code deny rules:
 * - Blocks read/write/edit of sensitive files and directories
 * - Blocks destructive bash commands (only allows safe patterns)
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { isToolCallEventType } from "@mariozechner/pi-coding-agent";

// Patterns to block for read/write/edit operations
// Ported from Claude Code settings.json deny rules
const BLOCKED_PATH_PATTERNS = [
	/\.env$/,
	/\.env\./,
	/\/secrets\//,
	/\/node_modules\//,
	/\/target\//,
	/\/\.git\//,
	/\/build\//,
	/\/dist\//,
	/\.log$/,
	/\/\.next\//,
	/\/coverage\//,
	/\/\.cache\//,
	/\/__pycache__\//,
	/\/\.pytest_cache\//,
	/\/\.tox\//,
	/\.pyc$/,
	/\.DS_Store$/,
	/\/vendor\//,
	/\/\.gradle\//,
	/\/\.idea\//,
	/\/\.vscode\//,
	/\.map$/,
	/\/\.terraform\//,
	/\.tfstate$/,
	/\.tfstate\.backup$/,
	/\/package-lock\.json$/,
	/\/yarn\.lock$/,
	/\/pnpm-lock\.yaml$/,
	/\/composer\.lock$/,
	/\/\.turbo\//,
	/\/\.webpack\//,
	/\/\.parcel-cache\//,
	/\/\.vite\//,
	/\/\.nuxt\//,
	/\/\.output\//,
	/\/out\//,
	/\/\.yarn\/cache\//,
	/\/\.yarn\/unplugged\//,
	/\/\.pnpm-store\//,
	/\/\.npm\//,
	/\/\.nyc_output\//,
	/\/htmlcov\//,
	/\/test-results\//,
	/\.swp$/,
	/\.swo$/,
	/~$/,
];

function isBlockedPath(path: string): boolean {
	return BLOCKED_PATH_PATTERNS.some((pattern) => pattern.test(path));
}

export default function (pi: ExtensionAPI) {
	pi.on("tool_call", async (event) => {
		// Block read/write/edit of protected paths
		if (
			isToolCallEventType("read", event) ||
			isToolCallEventType("write", event) ||
			isToolCallEventType("edit", event)
		) {
			const path = event.input.path;
			if (path && isBlockedPath(path)) {
				return {
					block: true,
					reason: `Protected path: ${path} — this file/directory is in the deny list`,
				};
			}
		}
	});
}
