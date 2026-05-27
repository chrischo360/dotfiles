import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";

const MAX_RESPONSE = 80_000;

function getMcpUrl(): string {
	return process.env.GLEAN_MCP_URL || "https://wayfair-be.glean.com/mcp/default";
}

function getClaudeGleanAuthHeader(): string | undefined {
	const credentialsPath = path.join(os.homedir(), ".claude", ".credentials.json");
	if (!fs.existsSync(credentialsPath)) return undefined;

	try {
		const credentials = JSON.parse(fs.readFileSync(credentialsPath, "utf8"));
		const oauth = credentials?.mcpOAuth ?? {};
		const key = Object.keys(oauth).find((entryKey) => {
			const entry = oauth[entryKey];
			return entry?.serverName === "glean_default" || entry?.serverUrl === "https://wayfair-be.glean.com/mcp/default";
		});
		if (!key) return undefined;

		const entry = oauth[key] as {
			accessToken?: string;
			refreshToken?: string;
			clientId?: string;
			expiresAt?: number;
			scope?: string;
		};

		if (entry.accessToken && entry.expiresAt && entry.expiresAt > Date.now() + 60_000) {
			return `Bearer ${entry.accessToken}`;
		}

		if (!entry.refreshToken || !entry.clientId) return entry.accessToken ? `Bearer ${entry.accessToken}` : undefined;

		const tokenResponse = JSON.parse(
			execFileSync(
				"curl",
				[
					"--silent",
					"--show-error",
					"--fail",
					"--max-time",
					"15",
					"--request",
					"POST",
					"--header",
					"Content-Type: application/x-www-form-urlencoded",
					"--data",
					new URLSearchParams({
						grant_type: "refresh_token",
						refresh_token: entry.refreshToken,
						client_id: entry.clientId,
					}).toString(),
					"https://wayfair-be.glean.com/oauth/token",
				],
				{ encoding: "utf8" },
			),
		);

		entry.accessToken = tokenResponse.access_token;
		entry.refreshToken = tokenResponse.refresh_token ?? entry.refreshToken;
		entry.expiresAt = Date.now() + Number(tokenResponse.expires_in ?? 0) * 1000;
		entry.scope = tokenResponse.scope ?? entry.scope;
		fs.writeFileSync(credentialsPath, JSON.stringify(credentials));

		return entry.accessToken ? `Bearer ${entry.accessToken}` : undefined;
	} catch {
		return undefined;
	}
}

function getAuthHeader(): string {
	if (process.env.GLEAN_MCP_AUTH_HEADER) return process.env.GLEAN_MCP_AUTH_HEADER;
	const claudeAuth = getClaudeGleanAuthHeader();
	if (claudeAuth) return claudeAuth;
	if (process.env.GLEAN_MCP_TOKEN) return `Bearer ${process.env.GLEAN_MCP_TOKEN}`;
	throw new Error(
		"Glean MCP auth missing. Run Claude with glean_default once, or set GLEAN_MCP_AUTH_HEADER / GLEAN_MCP_TOKEN before starting Pi.",
	);
}

function truncate(content: string): string {
	if (content.length <= MAX_RESPONSE) return content;
	return content.slice(0, MAX_RESPONSE) + `\n\n[Truncated — ${content.length} chars, showing first ${MAX_RESPONSE}]`;
}

function extractMcpText(raw: string): string {
	const text = raw
		.split("\n")
		.map((line) => line.trim())
		.filter((line) => line.startsWith("data:"))
		.map((line) => line.slice(5).trim())
		.filter((line) => line && line !== "[DONE]")
		.join("\n");

	const payload = text || raw;

	try {
		const parsed = JSON.parse(payload);
		const content = parsed?.result?.content;
		if (Array.isArray(content)) {
			const parts = content
				.map((item) => item?.text ?? item?.json ?? item)
				.map((item) => (typeof item === "string" ? item : JSON.stringify(item)))
				.filter(Boolean);
			if (parts.length > 0) return parts.join("\n");
		}
		return JSON.stringify(parsed, null, 2);
	} catch {
		return payload;
	}
}

async function mcpCall(
	pi: ExtensionAPI,
	name: string,
	args: Record<string, unknown>,
	signal?: AbortSignal,
): Promise<string> {
	const curlArgs = [
		"--silent",
		"--show-error",
		"--location",
		"--max-time",
		"30",
		"--request",
		"POST",
		"--header",
		"Content-Type: application/json",
		"--header",
		"Accept: application/json, text/event-stream",
		"--header",
		"MCP-Protocol-Version: 2024-11-05",
	];

	const auth = getAuthHeader();
	if (auth) curlArgs.push("--header", `Authorization: ${auth}`);

	curlArgs.push(
		"--data",
		JSON.stringify({
			jsonrpc: "2.0",
			id: Date.now(),
			method: "tools/call",
			params: { name, arguments: args },
		}),
		getMcpUrl(),
	);

	const result = await pi.exec("curl", curlArgs, { signal, timeout: 35000 });

	if (result.code !== 0 && !result.stdout) {
		throw new Error(`Glean MCP error: ${result.stderr.slice(0, 300)}`);
	}

	const content = extractMcpText(result.stdout || result.stderr);
	if (content.includes('"error":"invalid_token"') || content.includes("Authentication required") || content.includes("Invalid Secret")) {
		throw new Error(
			"Glean MCP authentication failed. Refresh Claude's glean_default MCP login, or set GLEAN_MCP_AUTH_HEADER / GLEAN_MCP_TOKEN for https://wayfair-be.glean.com/mcp/default.",
		);
	}
	return truncate(content);
}

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "glean_search",
		label: "Glean Search",
		description:
			"Search all company knowledge — documents, Slack, Confluence, Jira, GitHub, GDrive, etc. " +
			"Use short, targeted keywords. Supports filters: app (slack, confluence, gdrive, github, jira), " +
			"from/owner (person name or 'me'), updated (today, past_week, past_month), after/before (YYYY-MM-DD), " +
			"type (pull, spreadsheet, email), sort_by_recency.",
		parameters: Type.Object({
			query: Type.String({ description: "Short targeted keywords. Use * with filters to match all." }),
			app: Type.Optional(Type.String({ description: "Filter by app: slack, confluence, gdrive, github, jira, gmail, etc." })),
			from: Type.Optional(Type.String({ description: "Documents updated/commented/created by person. Use 'me' for self." })),
			owner: Type.Optional(Type.String({ description: "Documents created by person. Use 'me' for self." })),
			after: Type.Optional(Type.String({ description: "Updated after date (YYYY-MM-DD, exclusive)" })),
			before: Type.Optional(Type.String({ description: "Updated before date (YYYY-MM-DD, exclusive)" })),
			type: Type.Optional(Type.String({ description: "Document type: pull, spreadsheet, slides, email, folder" })),
			sort_by_recency: Type.Optional(Type.Boolean({ description: "Sort by newest first (default: relevance)" })),
		}),
		async execute(_id, params, signal) {
			return { content: [{ type: "text", text: await mcpCall(pi, "search", params, signal) }], details: { query: params.query } };
		},
	});

	pi.registerTool({
		name: "glean_chat",
		label: "Glean Chat",
		description: "AI-powered company knowledge assistant. Use for complex questions requiring analysis and synthesis across multiple sources.",
		parameters: Type.Object({
			message: Type.String({ description: "Question or message to send to Glean Assistant" }),
			context: Type.Optional(Type.Array(Type.String(), { description: "Previous messages for context" })),
		}),
		async execute(_id, params, signal) {
			return { content: [{ type: "text", text: await mcpCall(pi, "chat", params, signal) }], details: { message: params.message } };
		},
	});

	pi.registerTool({
		name: "glean_code_search",
		label: "Glean Code Search",
		description: "Search internal company code repositories and commits.",
		parameters: Type.Object({ query: Type.String({ description: "Code search query with keywords and optional filters" }) }),
		async execute(_id, params, signal) {
			return { content: [{ type: "text", text: await mcpCall(pi, "code_search", params, signal) }], details: { query: params.query } };
		},
	});

	pi.registerTool({
		name: "glean_employee_search",
		label: "Glean Employee Search",
		description: "Find company employees and their information.",
		parameters: Type.Object({ query: Type.String({ description: "Search query for people" }) }),
		async execute(_id, params, signal) {
			return { content: [{ type: "text", text: await mcpCall(pi, "employee_search", params, signal) }], details: { query: params.query } };
		},
	});

	pi.registerTool({
		name: "glean_read_document",
		label: "Glean Read Document",
		description: "Retrieve the full content of one or more URLs from company internal resources.",
		parameters: Type.Object({ urls: Type.Array(Type.String(), { description: "URLs to read" }) }),
		async execute(_id, params, signal) {
			return { content: [{ type: "text", text: await mcpCall(pi, "read_document", params, signal) }], details: { urls: params.urls } };
		},
	});

	pi.registerTool({
		name: "glean_user_activity",
		label: "Glean User Activity",
		description: "Retrieve your recent activity logs.",
		parameters: Type.Object({
			start_date: Type.String({ description: "Start date (YYYY-MM-DD, inclusive)" }),
			end_date: Type.String({ description: "End date (YYYY-MM-DD, exclusive)" }),
		}),
		async execute(_id, params, signal) {
			return { content: [{ type: "text", text: await mcpCall(pi, "user_activity", params, signal) }], details: params };
		},
	});

	pi.registerTool({
		name: "glean_gmail_search",
		label: "Glean Gmail Search",
		description: "Search Gmail inbox for emails, conversations, attachments.",
		parameters: Type.Object({ query: Type.String({ description: "Email search query with optional filters" }) }),
		async execute(_id, params, signal) {
			return { content: [{ type: "text", text: await mcpCall(pi, "gmail_search", params, signal) }], details: { query: params.query } };
		},
	});

	pi.registerTool({
		name: "glean_meeting_lookup",
		label: "Glean Meeting Lookup",
		description: "Search company calendar meetings by participants, topic, or date range.",
		parameters: Type.Object({
			query: Type.Optional(Type.String({ description: "Topic or keywords for meeting search" })),
			participants: Type.Optional(Type.Array(Type.String(), { description: "Names or emails of participants" })),
			after: Type.Optional(Type.String({ description: "Meetings after this date (YYYY-MM-DD or 'today', 'yesterday')" })),
			before: Type.Optional(Type.String({ description: "Meetings before this date" })),
		}),
		async execute(_id, params, signal) {
			return { content: [{ type: "text", text: await mcpCall(pi, "meeting_lookup", params, signal) }], details: params };
		},
	});

	pi.registerTool({
		name: "glean_read_memory",
		label: "Glean Read Memory",
		description: "Access your long-term work memories from Glean.",
		parameters: Type.Object({
			category: Type.Optional(Type.String({ description: "Memory category to read (omit for all)" })),
			query: Type.Optional(Type.String({ description: "Semantic search query for specific memories" })),
			limit: Type.Optional(Type.Number({ description: "Max memories to return (default: 10)" })),
		}),
		async execute(_id, params, signal) {
			return { content: [{ type: "text", text: await mcpCall(pi, "read_memory", params, signal) }], details: params };
		},
	});
}
