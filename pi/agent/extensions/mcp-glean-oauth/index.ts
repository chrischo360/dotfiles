/**
 * Glean Remote MCP Server Extension for Pi (OAuth version)
 *
 * Uses Glean's remote MCP server (https://wayfair-be.glean.com/mcp/default) with OAuth authentication.
 * Follows the same approach as Claude Code - stores OAuth tokens and auto-refreshes them.
 *
 * Requires env var:
 *   GLEAN_INSTANCE or GLEAN_SUBDOMAIN - Your Glean instance name (e.g., "wayfair")
 *
 * On first use, it will initiate OAuth device flow and store tokens in ~/.pi/agent/glean-oauth.json
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";

const MAX_RESPONSE = 80_000;
const TOKEN_FILE = path.join(os.homedir(), ".pi", "agent", "glean-oauth.json");

interface OAuthTokens {
	accessToken: string;
	refreshToken: string;
	expiresAt: number;
	serverUrl: string;
	clientId: string;
}

function getMcpUrl(): string {
	const instance = process.env.GLEAN_INSTANCE || process.env.GLEAN_SUBDOMAIN;
	if (!instance) {
		throw new Error("GLEAN_INSTANCE or GLEAN_SUBDOMAIN environment variable is required");
	}
	return `https://${instance}-be.glean.com/mcp/default`;
}

function loadTokens(): OAuthTokens | null {
	try {
		if (fs.existsSync(TOKEN_FILE)) {
			const data = fs.readFileSync(TOKEN_FILE, "utf-8");
			return JSON.parse(data);
		}
	} catch (err) {
		// Ignore errors, will do OAuth flow
	}
	return null;
}

function saveTokens(tokens: OAuthTokens): void {
	const dir = path.dirname(TOKEN_FILE);
	if (!fs.existsSync(dir)) {
		fs.mkdirSync(dir, { recursive: true });
	}
	fs.writeFileSync(TOKEN_FILE, JSON.stringify(tokens, null, 2));
}

async function initiateOAuthDeviceFlow(pi: ExtensionAPI, serverUrl: string): Promise<OAuthTokens> {
	pi.log("=== Glean OAuth Device Flow ===");
	pi.log("Initiating OAuth device flow for Glean MCP...");

	// Step 1: Get device code
	const deviceAuthUrl = `${serverUrl}/oauth/device/code`;
	const deviceResult = await pi.exec(
		"curl",
		[
			"--silent",
			"--show-error",
			"--request",
			"POST",
			"--header",
			"Content-Type: application/json",
			"--data",
			JSON.stringify({
				client_name: "Pi Coding Agent (glean_default)",
				scope: [
					"activity",
					"agents",
					"announcements",
					"answers",
					"chat",
					"collections",
					"documents",
					"email",
					"entities",
					"feed",
					"feedback",
					"insights",
					"mcp",
					"offline_access",
					"openid",
					"people",
					"pins",
					"search",
					"shortcuts",
					"summarize",
					"tools",
				],
			}),
			deviceAuthUrl,
		],
		{ timeout: 15000 },
	);

	if (deviceResult.code !== 0) {
		throw new Error(`Failed to initiate device flow: ${deviceResult.stderr}`);
	}

	const deviceData = JSON.parse(deviceResult.stdout);

	pi.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
	pi.log(`Please visit: ${deviceData.verification_uri}`);
	pi.log(`Enter code: ${deviceData.user_code}`);
	pi.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
	pi.log("Waiting for you to authorize...");

	// Step 2: Poll for token
	const tokenUrl = `${serverUrl}/oauth/token`;
	const pollInterval = deviceData.interval || 5;
	const expiresIn = deviceData.expires_in || 600;
	const deadline = Date.now() + expiresIn * 1000;

	while (Date.now() < deadline) {
		await new Promise((resolve) => setTimeout(resolve, pollInterval * 1000));

		const tokenResult = await pi.exec(
			"curl",
			[
				"--silent",
				"--show-error",
				"--request",
				"POST",
				"--header",
				"Content-Type: application/json",
				"--data",
				JSON.stringify({
					grant_type: "urn:ietf:params:oauth:grant-type:device_code",
					device_code: deviceData.device_code,
					client_id: deviceData.client_id,
				}),
				tokenUrl,
			],
			{ timeout: 15000 },
		);

		if (tokenResult.code !== 0) {
			throw new Error(`Token polling failed: ${tokenResult.stderr}`);
		}

		const tokenData = JSON.parse(tokenResult.stdout);

		if (tokenData.error) {
			if (tokenData.error === "authorization_pending") {
				// Still waiting
				continue;
			} else if (tokenData.error === "slow_down") {
				// Increase interval
				await new Promise((resolve) => setTimeout(resolve, 5000));
				continue;
			} else {
				throw new Error(`OAuth error: ${tokenData.error} - ${tokenData.error_description}`);
			}
		}

		// Success!
		if (tokenData.access_token) {
			pi.log("✓ OAuth authorization successful!");

			const tokens: OAuthTokens = {
				accessToken: tokenData.access_token,
				refreshToken: tokenData.refresh_token,
				expiresAt: Date.now() + (tokenData.expires_in || 3600) * 1000,
				serverUrl,
				clientId: deviceData.client_id,
			};

			saveTokens(tokens);
			return tokens;
		}
	}

	throw new Error("OAuth device flow timed out");
}

async function refreshAccessToken(pi: ExtensionAPI, tokens: OAuthTokens): Promise<OAuthTokens> {
	pi.log("Refreshing Glean OAuth token...");

	const tokenUrl = `${tokens.serverUrl}/oauth/token`;
	const refreshResult = await pi.exec(
		"curl",
		[
			"--silent",
			"--show-error",
			"--request",
			"POST",
			"--header",
			"Content-Type: application/json",
			"--data",
			JSON.stringify({
				grant_type: "refresh_token",
				refresh_token: tokens.refreshToken,
				client_id: tokens.clientId,
			}),
			tokenUrl,
		],
		{ timeout: 15000 },
	);

	if (refreshResult.code !== 0) {
		throw new Error(`Token refresh failed: ${refreshResult.stderr}`);
	}

	const tokenData = JSON.parse(refreshResult.stdout);

	if (tokenData.error) {
		throw new Error(`Token refresh error: ${tokenData.error} - ${tokenData.error_description}`);
	}

	const newTokens: OAuthTokens = {
		accessToken: tokenData.access_token,
		refreshToken: tokenData.refresh_token || tokens.refreshToken,
		expiresAt: Date.now() + (tokenData.expires_in || 3600) * 1000,
		serverUrl: tokens.serverUrl,
		clientId: tokens.clientId,
	};

	saveTokens(newTokens);
	pi.log("✓ Token refreshed successfully");
	return newTokens;
}

async function getValidAccessToken(pi: ExtensionAPI): Promise<string> {
	const serverUrl = getMcpUrl();
	let tokens = loadTokens();

	// If no tokens or server URL changed, do OAuth flow
	if (!tokens || tokens.serverUrl !== serverUrl) {
		tokens = await initiateOAuthDeviceFlow(pi, serverUrl);
	}

	// If token is expired or expiring soon (within 5 minutes), refresh it
	if (tokens.expiresAt < Date.now() + 5 * 60 * 1000) {
		tokens = await refreshAccessToken(pi, tokens);
	}

	return tokens.accessToken;
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
	const accessToken = await getValidAccessToken(pi);

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
		"--header",
		`Authorization: Bearer ${accessToken}`,
		"--data",
		JSON.stringify({
			jsonrpc: "2.0",
			id: Date.now(),
			method: "tools/call",
			params: { name, arguments: args },
		}),
		getMcpUrl(),
	];

	const result = await pi.exec("curl", curlArgs, { signal, timeout: 35000 });

	if (result.code !== 0 && !result.stdout) {
		throw new Error(`Glean MCP error: ${result.stderr.slice(0, 300)}`);
	}

	const content = extractMcpText(result.stdout || result.stderr);
	if (
		content.includes('"error":"invalid_token"') ||
		content.includes("Authentication required") ||
		content.includes("Invalid Secret")
	) {
		// Token might be invalid, try to refresh once
		pi.log("Token appears invalid, attempting refresh...");
		const tokens = loadTokens();
		if (tokens) {
			const newTokens = await refreshAccessToken(pi, tokens);
			// Retry the call with new token
			const authHeaderIndex = curlArgs.findIndex((arg) => arg.startsWith("Authorization:"));
			curlArgs[authHeaderIndex] = `Authorization: Bearer ${newTokens.accessToken}`;
			const retryResult = await pi.exec("curl", curlArgs, { signal, timeout: 35000 });
			return truncate(extractMcpText(retryResult.stdout || retryResult.stderr));
		}
		throw new Error("Glean MCP authentication failed. Please delete ~/.pi/agent/glean-oauth.json and try again.");
	}
	return truncate(content);
}

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "glean_search",
		label: "Glean Search (OAuth)",
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
		label: "Glean Chat (OAuth)",
		description:
			"AI-powered company knowledge assistant. Use for complex questions requiring analysis and synthesis across multiple sources.",
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
		label: "Glean Code Search (OAuth)",
		description: "Search internal company code repositories and commits.",
		parameters: Type.Object({ query: Type.String({ description: "Code search query with keywords and optional filters" }) }),
		async execute(_id, params, signal) {
			return { content: [{ type: "text", text: await mcpCall(pi, "code_search", params, signal) }], details: { query: params.query } };
		},
	});

	pi.registerTool({
		name: "glean_employee_search",
		label: "Glean Employee Search (OAuth)",
		description: "Find company employees and their information.",
		parameters: Type.Object({ query: Type.String({ description: "Search query for people" }) }),
		async execute(_id, params, signal) {
			return {
				content: [{ type: "text", text: await mcpCall(pi, "employee_search", params, signal) }],
				details: { query: params.query },
			};
		},
	});

	pi.registerTool({
		name: "glean_read_document",
		label: "Glean Read Document (OAuth)",
		description: "Retrieve the full content of one or more URLs from company internal resources.",
		parameters: Type.Object({ urls: Type.Array(Type.String(), { description: "URLs to read" }) }),
		async execute(_id, params, signal) {
			return { content: [{ type: "text", text: await mcpCall(pi, "read_document", params, signal) }], details: { urls: params.urls } };
		},
	});

	pi.registerTool({
		name: "glean_user_activity",
		label: "Glean User Activity (OAuth)",
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
		label: "Glean Gmail Search (OAuth)",
		description: "Search Gmail inbox for emails, conversations, attachments.",
		parameters: Type.Object({ query: Type.String({ description: "Email search query with optional filters" }) }),
		async execute(_id, params, signal) {
			return { content: [{ type: "text", text: await mcpCall(pi, "gmail_search", params, signal) }], details: { query: params.query } };
		},
	});

	pi.registerTool({
		name: "glean_meeting_lookup",
		label: "Glean Meeting Lookup (OAuth)",
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
		label: "Glean Read Memory (OAuth)",
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
