/**
 * Glean MCP Extension
 *
 * Wraps Wayfair's Glean enterprise search as a pi tool.
 * Uses Glean's REST API directly (MCP endpoint requires OAuth).
 *
 * Requires: GLEAN_API_TOKEN env var
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { StringEnum } from "@mariozechner/pi-ai";

const GLEAN_API = "https://wayfair-be.glean.com/rest/api/v1";

interface GleanResult {
	document?: {
		title?: string;
		url?: string;
		datasource?: string;
		metadata?: { datasourceInstance?: string };
	};
	snippets?: Array<{ text?: string; ranges?: unknown[] }>;
	title?: string;
}

interface GleanResponse {
	results?: GleanResult[];
	totalCount?: number;
}

async function gleanSearch(
	query: string,
	datasource?: string,
	pageSize = 10,
): Promise<string> {
	const token = process.env.GLEAN_API_TOKEN;
	if (!token) throw new Error("GLEAN_API_TOKEN not set in .env");

	const body: Record<string, unknown> = {
		query,
		pageSize,
		requestOptions: { facetFilters: [] },
	};

	if (datasource) {
		body.requestOptions = {
			facetFilters: [{ fieldName: "datasource", values: [{ value: datasource }] }],
		};
	}

	const res = await fetch(`${GLEAN_API}/search`, {
		method: "POST",
		headers: {
			Authorization: `Bearer ${token}`,
			"Content-Type": "application/json",
		},
		body: JSON.stringify(body),
	});

	if (!res.ok) {
		const text = await res.text();
		throw new Error(`Glean API error ${res.status}: ${text.slice(0, 200)}`);
	}

	const data: GleanResponse = await res.json();
	const results = data.results ?? [];

	if (results.length === 0) return "No results found.";

	const formatted = results.map((r: GleanResult, i: number) => {
		const doc = r.document ?? {};
		const title = doc.title ?? r.title ?? "Untitled";
		const url = doc.url ?? "";
		const source = doc.datasource ?? doc.metadata?.datasourceInstance ?? "";
		const snippets = (r.snippets ?? [])
			.map((s) => s.text ?? "")
			.filter(Boolean)
			.join(" ... ")
			.slice(0, 400);

		return [
			`${i + 1}. **${title}**${source ? ` [${source}]` : ""}`,
			url ? `   ${url}` : "",
			snippets ? `   ${snippets}` : "",
		]
			.filter(Boolean)
			.join("\n");
	});

	return `Found ${data.totalCount ?? results.length} results:\n\n${formatted.join("\n\n")}`;
}

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "glean_search",
		label: "Glean Search",
		description:
			"Search Wayfair's Glean enterprise knowledge base. Use for tickets, Confluence docs, Slack threads, code, people, internal tools.",
		promptSnippet: "Search Wayfair's internal knowledge base (tickets, docs, Slack, Confluence)",
		parameters: Type.Object({
			query: Type.String({ description: "Search query" }),
			datasource: Type.Optional(
				StringEnum(["jira", "confluence", "slack", "github", "gdrive"] as const, {
					description: "Filter to a specific data source (optional)",
				}),
			),
			limit: Type.Optional(
				Type.Number({ description: "Number of results to return (default: 10, max: 20)" }),
			),
		}),
		async execute(_id, params) {
			const result = await gleanSearch(
				params.query,
				params.datasource,
				Math.min(params.limit ?? 10, 20),
			);
			return { content: [{ type: "text", text: result }], details: {} };
		},
	});
}
