/**
 * Sourcegraph MCP Extension
 *
 * Wraps Wayfair's Sourcegraph MCP HTTP server as pi tools.
 * All 11 sg_* tools from https://wayfair.sourcegraphcloud.com/.api/mcp/v1
 *
 * Requires: SOURCEGRAPH_TOKEN env var
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";

const SG_ENDPOINT = "https://wayfair.sourcegraphcloud.com/.api/mcp/v1";

async function callSgTool(toolName: string, args: Record<string, unknown>): Promise<string> {
	const token = process.env.SOURCEGRAPH_TOKEN;
	if (!token) throw new Error("SOURCEGRAPH_TOKEN not set");

	const res = await fetch(SG_ENDPOINT, {
		method: "POST",
		headers: {
			Authorization: `token ${token}`,
			"Content-Type": "application/json",
			Accept: "application/json, text/event-stream",
		},
		body: JSON.stringify({
			jsonrpc: "2.0",
			id: Date.now(),
			method: "tools/call",
			params: { name: toolName, arguments: args },
		}),
	});

	const text = await res.text();
	const results: string[] = [];

	for (const line of text.split("\n")) {
		const trimmed = line.trim();
		if (!trimmed.startsWith("data:")) continue;
		try {
			const data = JSON.parse(trimmed.slice(5));
			if (data.error) throw new Error(data.error.message ?? JSON.stringify(data.error));
			const content = data.result?.content ?? [];
			for (const c of content) {
				if (c.text) results.push(c.text);
			}
		} catch (e) {
			if (e instanceof Error && e.message !== "Unexpected end of JSON input") throw e;
		}
	}

	return results.join("\n\n") || "No results.";
}

export default function (pi: ExtensionAPI) {
	// Keyword search — most used, broad code search
	pi.registerTool({
		name: "sg_search",
		label: "Sourcegraph Search",
		description: "Search code across Wayfair's Sourcegraph. Use for finding files, usages, patterns across all repos.",
		promptSnippet: "Search Wayfair's Sourcegraph codebase",
		parameters: Type.Object({
			query: Type.String({ description: "Search query (supports regex and Sourcegraph syntax)" }),
			repo: Type.Optional(Type.String({ description: "Limit to repo, e.g. github.com/Wayfair/sf-ui-web" })),
		}),
		async execute(_id, params, _signal, _onUpdate, _ctx) {
			const args: Record<string, unknown> = { query: params.query };
			if (params.repo) args.repos = [params.repo];
			const result = await callSgTool("sg_keyword_search", args);
			return { content: [{ type: "text", text: result }], details: {} };
		},
	});

	// NLS (natural language) search
	pi.registerTool({
		name: "sg_nls_search",
		label: "Sourcegraph NL Search",
		description: "Natural language code search across Wayfair repos. Use when you're not sure of exact syntax.",
		parameters: Type.Object({
			query: Type.String({ description: "Natural language description of what you're looking for" }),
			repo: Type.Optional(Type.String({ description: "Limit to specific repo" })),
		}),
		async execute(_id, params) {
			const args: Record<string, unknown> = { query: params.query };
			if (params.repo) args.repos = [params.repo];
			const result = await callSgTool("sg_nls_search", args);
			return { content: [{ type: "text", text: result }], details: {} };
		},
	});

	// Read file from a repo
	pi.registerTool({
		name: "sg_read_file",
		label: "Sourcegraph Read File",
		description: "Read a file from any Wayfair repo via Sourcegraph. Use for reading files you don't have locally.",
		parameters: Type.Object({
			repo: Type.String({ description: "Repository, e.g. github.com/Wayfair/sf-ui-web" }),
			path: Type.String({ description: "File path within the repo" }),
			branch: Type.Optional(Type.String({ description: "Branch name (default: main)" })),
		}),
		async execute(_id, params) {
			const args: Record<string, unknown> = { repo: params.repo, path: params.path };
			if (params.branch) args.rev = params.branch;
			const result = await callSgTool("sg_read_file", args);
			return { content: [{ type: "text", text: result }], details: {} };
		},
	});

	// List files in a repo directory
	pi.registerTool({
		name: "sg_list_files",
		label: "Sourcegraph List Files",
		description: "List files in a directory of any Wayfair repo via Sourcegraph.",
		parameters: Type.Object({
			repo: Type.String({ description: "Repository, e.g. github.com/Wayfair/sf-ui-web" }),
			path: Type.Optional(Type.String({ description: "Directory path (default: root)" })),
		}),
		async execute(_id, params) {
			const args: Record<string, unknown> = { repo: params.repo };
			if (params.path) args.path = params.path;
			const result = await callSgTool("sg_list_files", args);
			return { content: [{ type: "text", text: result }], details: {} };
		},
	});

	// Find references to a symbol
	pi.registerTool({
		name: "sg_find_references",
		label: "Sourcegraph Find References",
		description: "Find all references to a symbol (function, class, variable) across Wayfair repos.",
		parameters: Type.Object({
			repo: Type.String({ description: "Repository containing the symbol" }),
			path: Type.String({ description: "File path containing the symbol" }),
			symbol: Type.String({ description: "Symbol name to find references for" }),
		}),
		async execute(_id, params) {
			const result = await callSgTool("sg_find_references", {
				repo: params.repo,
				path: params.path,
				symbol: params.symbol,
			});
			return { content: [{ type: "text", text: result }], details: {} };
		},
	});

	// Go to definition
	pi.registerTool({
		name: "sg_go_to_definition",
		label: "Sourcegraph Go To Definition",
		description: "Find where a symbol is defined across Wayfair repos.",
		parameters: Type.Object({
			repo: Type.String({ description: "Repository" }),
			path: Type.String({ description: "File path" }),
			symbol: Type.String({ description: "Symbol name" }),
		}),
		async execute(_id, params) {
			const result = await callSgTool("sg_go_to_definition", {
				repo: params.repo,
				path: params.path,
				symbol: params.symbol,
			});
			return { content: [{ type: "text", text: result }], details: {} };
		},
	});

	// List repos
	pi.registerTool({
		name: "sg_list_repos",
		label: "Sourcegraph List Repos",
		description: "List Wayfair repos matching a search query on Sourcegraph.",
		parameters: Type.Object({
			query: Type.String({ description: "Repo name or pattern to search for" }),
		}),
		async execute(_id, params) {
			const result = await callSgTool("sg_list_repos", { query: params.query });
			return { content: [{ type: "text", text: result }], details: {} };
		},
	});

	// Diff search
	pi.registerTool({
		name: "sg_diff_search",
		label: "Sourcegraph Diff Search",
		description: "Search code changes (diffs) across Wayfair repos. Find when something was added/removed.",
		parameters: Type.Object({
			query: Type.String({ description: "Pattern to search for in diffs" }),
			repo: Type.Optional(Type.String({ description: "Limit to specific repo" })),
		}),
		async execute(_id, params) {
			const args: Record<string, unknown> = { query: params.query };
			if (params.repo) args.repos = [params.repo];
			const result = await callSgTool("sg_diff_search", args);
			return { content: [{ type: "text", text: result }], details: {} };
		},
	});
}
