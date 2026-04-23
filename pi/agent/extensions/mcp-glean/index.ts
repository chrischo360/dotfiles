/**
 * Glean Extension for Pi
 *
 * Replicates the Glean MCP server tools using the Glean REST API.
 * Provides: search, chat, code_search, employee_search, read_document,
 * user_activity, gmail_search, meeting_lookup, read_memory.
 *
 * Requires env vars:
 *   GLEAN_API_TOKEN  - Glean API bearer token
 *   GLEAN_INSTANCE   - Glean instance name (default: wayfair)
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";

const MAX_RESPONSE = 80_000;

function getBaseUrl(): string {
	const instance = process.env.GLEAN_INSTANCE || "wayfair";
	return `https://${instance}-be.glean.com`;
}

function getToken(): string {
	const token = process.env.GLEAN_API_TOKEN;
	if (!token) throw new Error("GLEAN_API_TOKEN environment variable is required");
	return token;
}

async function gleanFetch(
	pi: ExtensionAPI,
	path: string,
	body: Record<string, unknown>,
	signal?: AbortSignal,
): Promise<string> {
	const url = `${getBaseUrl()}${path}`;
	const jsonBody = JSON.stringify(body);

	const result = await pi.exec(
		"curl",
		[
			"--silent",
			"--location",
			"--max-time",
			"30",
			"--request",
			"POST",
			"--header",
			`Authorization: Bearer ${getToken()}`,
			"--header",
			"Content-Type: application/json",
			"--data",
			jsonBody,
			url,
		],
		{ signal, timeout: 35000 },
	);

	if (result.code !== 0 && !result.stdout) {
		throw new Error(`Glean API error: ${result.stderr.slice(0, 300)}`);
	}

	let content = result.stdout;
	if (content.length > MAX_RESPONSE) {
		content = content.slice(0, MAX_RESPONSE) + `\n\n[Truncated — ${content.length} chars, showing first ${MAX_RESPONSE}]`;
	}
	return content;
}

async function gleanGet(
	pi: ExtensionAPI,
	path: string,
	signal?: AbortSignal,
): Promise<string> {
	const url = `${getBaseUrl()}${path}`;

	const result = await pi.exec(
		"curl",
		[
			"--silent",
			"--location",
			"--max-time",
			"30",
			"--header",
			`Authorization: Bearer ${getToken()}`,
			"--header",
			"Content-Type: application/json",
			url,
		],
		{ signal, timeout: 35000 },
	);

	if (result.code !== 0 && !result.stdout) {
		throw new Error(`Glean API error: ${result.stderr.slice(0, 300)}`);
	}

	let content = result.stdout;
	if (content.length > MAX_RESPONSE) {
		content = content.slice(0, MAX_RESPONSE) + `\n\n[Truncated — ${content.length} chars, showing first ${MAX_RESPONSE}]`;
	}
	return content;
}

export default function (pi: ExtensionAPI) {
	// glean_search — primary document search
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
			const body: Record<string, unknown> = {
				query: params.query,
				pageSize: 10,
			};

			const filters: Array<{ fieldName: string; values: string[] }> = [];
			if (params.app) filters.push({ fieldName: "app", values: [params.app] });
			if (params.from) filters.push({ fieldName: "from", values: [params.from] });
			if (params.owner) filters.push({ fieldName: "owner", values: [params.owner] });
			if (params.type) filters.push({ fieldName: "type", values: [params.type] });
			if (params.after) filters.push({ fieldName: "after", values: [params.after] });
			if (params.before) filters.push({ fieldName: "before", values: [params.before] });
			if (filters.length > 0) body.filters = filters;
			if (params.sort_by_recency) body.sort = "recency";

			const content = await gleanFetch(pi, "/api/v1/search", body, signal);
			return {
				content: [{ type: "text", text: content }],
				details: { query: params.query },
			};
		},
	});

	// glean_chat — AI-powered analysis
	pi.registerTool({
		name: "glean_chat",
		label: "Glean Chat",
		description:
			"AI-powered company knowledge assistant. Use for complex questions requiring analysis, " +
			"synthesis across multiple sources, or reasoning. Better than search when you need contextual " +
			"understanding rather than raw document results.",
		parameters: Type.Object({
			message: Type.String({ description: "Question or message to send to Glean Assistant" }),
			context: Type.Optional(Type.Array(Type.String(), { description: "Previous messages for context" })),
		}),
		async execute(_id, params, signal) {
			const messages = [];
			if (params.context) {
				for (const msg of params.context) {
					messages.push({ author: "USER", fragments: [{ text: msg }] });
				}
			}
			messages.push({ author: "USER", fragments: [{ text: params.message }] });

			const content = await gleanFetch(pi, "/api/v1/chat", { messages }, signal);
			return {
				content: [{ type: "text", text: content }],
				details: { message: params.message },
			};
		},
	});

	// glean_code_search — search internal code repos
	pi.registerTool({
		name: "glean_code_search",
		label: "Glean Code Search",
		description:
			"Search internal company code repositories and commits. " +
			"Supports filters: owner/from (person), updated (today, past_week), after/before (YYYY-MM-DD).",
		parameters: Type.Object({
			query: Type.String({ description: "Code search query with keywords and optional filters" }),
		}),
		async execute(_id, params, signal) {
			const body = {
				query: params.query,
				pageSize: 10,
				filters: [{ fieldName: "app", values: ["github"] }],
			};
			const content = await gleanFetch(pi, "/api/v1/search", body, signal);
			return {
				content: [{ type: "text", text: content }],
				details: { query: params.query },
			};
		},
	});

	// glean_employee_search — find people
	pi.registerTool({
		name: "glean_employee_search",
		label: "Glean Employee Search",
		description:
			"Find company employees and their information. Use for 'who is', 'who works on', org chart, " +
			"contact info, team composition. Supports filters: roletype (individual contributor, manager), " +
			"reportsto (manager name), sortby (hire_date_ascending, most_reports).",
		parameters: Type.Object({
			query: Type.String({ description: "Search query for people" }),
		}),
		async execute(_id, params, signal) {
			const content = await gleanFetch(
				pi,
				"/api/v1/search",
				{ query: params.query, filters: [{ fieldName: "type", values: ["people"] }], pageSize: 10 },
				signal,
			);
			return {
				content: [{ type: "text", text: content }],
				details: { query: params.query },
			};
		},
	});

	// glean_read_document — fetch full document content
	pi.registerTool({
		name: "glean_read_document",
		label: "Glean Read Document",
		description: "Retrieve the full content of one or more URLs from company internal resources.",
		parameters: Type.Object({
			urls: Type.Array(Type.String(), { description: "URLs to read" }),
		}),
		async execute(_id, params, signal) {
			const content = await gleanFetch(
				pi,
				"/api/v1/getdocumentcontent",
				{ urls: params.urls },
				signal,
			);
			return {
				content: [{ type: "text", text: content }],
				details: { urls: params.urls },
			};
		},
	});

	// glean_user_activity — recent activity logs
	pi.registerTool({
		name: "glean_user_activity",
		label: "Glean User Activity",
		description:
			"Retrieve your recent activity logs. Use for standup notes, weekly summaries, " +
			"'what did I work on' questions, performance reviews.",
		parameters: Type.Object({
			start_date: Type.String({ description: "Start date (YYYY-MM-DD, inclusive)" }),
			end_date: Type.String({ description: "End date (YYYY-MM-DD, exclusive)" }),
		}),
		async execute(_id, params, signal) {
			const content = await gleanFetch(
				pi,
				"/api/v1/activity",
				{ startDate: params.start_date, endDate: params.end_date },
				signal,
			);
			return {
				content: [{ type: "text", text: content }],
				details: { start_date: params.start_date, end_date: params.end_date },
			};
		},
	});

	// glean_gmail_search — search emails
	pi.registerTool({
		name: "glean_gmail_search",
		label: "Glean Gmail Search",
		description:
			"Search Gmail inbox for emails, conversations, attachments. " +
			"Supports filters in query: from/to (person or email), subject, has:attachment, " +
			"is:important/starred/read/unread, label:INBOX/SENT, after/before (YYYY-MM-DD).",
		parameters: Type.Object({
			query: Type.String({ description: "Email search query with optional filters" }),
		}),
		async execute(_id, params, signal) {
			const content = await gleanFetch(
				pi,
				"/api/v1/search",
				{ query: params.query, filters: [{ fieldName: "app", values: ["gmail"] }], pageSize: 10 },
				signal,
			);
			return {
				content: [{ type: "text", text: content }],
				details: { query: params.query },
			};
		},
	});

	// glean_meeting_lookup — search calendar meetings
	pi.registerTool({
		name: "glean_meeting_lookup",
		label: "Glean Meeting Lookup",
		description:
			"Search company calendar meetings by participants, topic, or date range. " +
			"Can extract transcripts.",
		parameters: Type.Object({
			query: Type.Optional(Type.String({ description: "Topic or keywords for meeting search" })),
			participants: Type.Optional(Type.Array(Type.String(), { description: "Names or emails of participants" })),
			after: Type.Optional(Type.String({ description: "Meetings after this date (YYYY-MM-DD or 'today', 'yesterday')" })),
			before: Type.Optional(Type.String({ description: "Meetings before this date" })),
		}),
		async execute(_id, params, signal) {
			const searchQuery = [
				params.query || "",
				...(params.participants || []).map((p) => `participant:${p}`),
				params.after ? `after:${params.after}` : "",
				params.before ? `before:${params.before}` : "",
			]
				.filter(Boolean)
				.join(" ");

			const content = await gleanFetch(
				pi,
				"/api/v1/search",
				{
					query: searchQuery || "*",
					filters: [{ fieldName: "app", values: ["gcalendar"] }],
					pageSize: 10,
				},
				signal,
			);
			return {
				content: [{ type: "text", text: content }],
				details: { query: searchQuery },
			};
		},
	});

	// glean_read_memory — user personalization data
	pi.registerTool({
		name: "glean_read_memory",
		label: "Glean Read Memory",
		description:
			"Access your long-term work memories from Glean: writing style, role, active projects, " +
			"recent topics, preferences. Categories: WritingStyle, RolesAndResponsibilities, " +
			"ActiveProjects, ExplicitMemories, RecentTopics, Preferences.",
		parameters: Type.Object({
			category: Type.Optional(
				Type.String({ description: "Memory category to read (omit for all)" }),
			),
			query: Type.Optional(
				Type.String({ description: "Semantic search query for specific memories" }),
			),
			limit: Type.Optional(
				Type.Number({ description: "Max memories to return (default: 10)" }),
			),
		}),
		async execute(_id, params, signal) {
			const body: Record<string, unknown> = {
				action: "read",
			};
			if (params.category) body.category = params.category;
			if (params.query) body.query = params.query;
			if (params.limit) body.limit = params.limit;

			const content = await gleanFetch(pi, "/api/v1/chat/memory", body, signal);
			return {
				content: [{ type: "text", text: content }],
				details: { category: params.category },
			};
		},
	});
}
