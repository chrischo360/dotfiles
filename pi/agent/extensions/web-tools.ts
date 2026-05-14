/**
 * Web Tools Extension
 *
 * Adds web_fetch and web_search tools — equivalents of Claude Code's
 * built-in WebFetch and WebSearch tools.
 *
 * web_fetch: fetches a URL via curl, strips HTML to readable text
 * web_search: Brave Search when BRAVE_SEARCH_API_KEY is set, DuckDuckGo fallback
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { StringEnum } from "@mariozechner/pi-ai";

const MAX_BYTES = 50_000;
const BRAVE_SEARCH_URL = "https://api.search.brave.com/res/v1/web/search";
const DUCKDUCKGO_URL = "https://api.duckduckgo.com/";

type SearchResult = {
	title: string;
	url: string;
	description?: string;
	age?: string;
};

function renderSearchResults(results: SearchResult[], provider: string, query: string): string {
	if (results.length === 0) {
		return `No results found for: ${query}\nTip: Try a more specific query, or use web_fetch with a direct URL.`;
	}

	return [
		`Provider: ${provider}`,
		"",
		...results.map((result, index) => {
			const lines = [`${index + 1}. ${result.title}`, `   ${result.url}`];
			if (result.description) lines.push(`   ${result.description}`);
			if (result.age) lines.push(`   ${result.age}`);
			return lines.join("\n");
		}),
	].join("\n");
}

/** Strip HTML tags and collapse whitespace to readable plain text */
function stripHtml(html: string): string {
	return html
		.replace(/<script[\s\S]*?<\/script>/gi, "")
		.replace(/<style[\s\S]*?<\/style>/gi, "")
		.replace(/<[^>]+>/g, " ")
		.replace(/&nbsp;/g, " ")
		.replace(/&amp;/g, "&")
		.replace(/&lt;/g, "<")
		.replace(/&gt;/g, ">")
		.replace(/&quot;/g, '"')
		.replace(/&#39;/g, "'")
		.replace(/\s{2,}/g, " ")
		.replace(/\n{3,}/g, "\n\n")
		.trim();
}

export default function (pi: ExtensionAPI) {
	// web_fetch — equivalent of Claude's WebFetch
	pi.registerTool({
		name: "web_fetch",
		label: "Web Fetch",
		description: "Fetch the contents of a URL. Returns readable text (HTML stripped). Use for documentation, tickets, GitHub issues, any public URL.",
		promptSnippet: "Fetch and read a URL",
		parameters: Type.Object({
			url: Type.String({ description: "URL to fetch" }),
			format: Type.Optional(
				StringEnum(["text", "raw"] as const, {
					description: "text = strip HTML to readable (default), raw = return as-is",
				}),
			),
		}),
		async execute(_id, params, signal) {
			const result = await pi.exec(
				"curl",
				[
					"--silent",
					"--location",         // follow redirects
					"--max-time", "30",
					"--max-filesize", String(MAX_BYTES),
					"--user-agent", "Mozilla/5.0 (compatible; pi-agent/1.0)",
					"--header", "Accept: text/html,application/xhtml+xml,text/plain,*/*",
					params.url,
				],
				{ signal, timeout: 35000 },
			);

			if (result.code !== 0 && !result.stdout) {
				throw new Error(`Fetch failed: ${result.stderr.slice(0, 200)}`);
			}

			let content = result.stdout;
			if ((params.format ?? "text") === "text") {
				content = stripHtml(content);
			}

			// Truncate if needed
			if (content.length > MAX_BYTES) {
				content = content.slice(0, MAX_BYTES) + `\n\n[Truncated — fetched ${content.length} chars, showing first ${MAX_BYTES}]`;
			}

			return {
				content: [{ type: "text", text: content || "(empty response)" }],
				details: { url: params.url, length: content.length },
			};
		},
	});

	pi.registerTool({
		name: "web_search",
		label: "Web Search",
		description: "Search the web. Uses Brave Search when BRAVE_SEARCH_API_KEY is set, with DuckDuckGo as a no-key fallback. Returns titles, URLs, and snippets.",
		promptSnippet: "Search the web for information",
		parameters: Type.Object({
			query: Type.String({ description: "Search query" }),
			limit: Type.Optional(Type.Number({ description: "Max results to return (default: 8, max: 20)" })),
			provider: Type.Optional(
				StringEnum(["auto", "brave", "duckduckgo"] as const, {
					description: "Search provider (default: auto; Brave when BRAVE_SEARCH_API_KEY is set, otherwise DuckDuckGo)",
				}),
			),
		}),
		async execute(_id, params, signal) {
			const limit = Math.min(Math.max(params.limit ?? 8, 1), 20);
			const provider = params.provider ?? "auto";
			const braveKey = process.env.BRAVE_SEARCH_API_KEY;

			if ((provider === "auto" && braveKey) || provider === "brave") {
				if (!braveKey) {
					throw new Error("BRAVE_SEARCH_API_KEY is required when provider is 'brave'");
				}

				const url = `${BRAVE_SEARCH_URL}?q=${encodeURIComponent(params.query)}&count=${limit}&text_decorations=false&result_filter=web`;
				const result = await pi.exec(
					"curl",
					[
						"--silent",
						"--location",
						"--compressed",
						"--max-time", "15",
						"--header", "Accept: application/json",
						"--header", `X-Subscription-Token: ${braveKey}`,
						url,
					],
					{ signal, timeout: 20000 },
				);

				if (result.code !== 0) throw new Error(`Brave search failed: ${result.stderr.slice(0, 200)}`);

				let data: { web?: { results?: Array<Record<string, unknown>> } };
				try {
					data = JSON.parse(result.stdout);
				} catch {
					throw new Error("Failed to parse Brave search results");
				}

				const results = (data.web?.results ?? []).slice(0, limit).map((item) => ({
					title: String(item.title ?? "Untitled"),
					url: String(item.url ?? ""),
					description: item.description ? String(item.description) : undefined,
					age: item.age ? String(item.age) : undefined,
				})).filter((item) => item.url);

				return {
					content: [{ type: "text", text: renderSearchResults(results, "Brave Search", params.query) }],
					details: { query: params.query, provider: "brave", resultCount: results.length },
				};
			}

			const url = `${DUCKDUCKGO_URL}?q=${encodeURIComponent(params.query)}&format=json&no_html=1&skip_disambig=1`;
			const result = await pi.exec(
				"curl",
				["--silent", "--location", "--max-time", "15", url],
				{ signal, timeout: 20000 },
			);

			if (result.code !== 0) throw new Error(`DuckDuckGo search failed: ${result.stderr.slice(0, 200)}`);

			let data: Record<string, unknown>;
			try {
				data = JSON.parse(result.stdout);
			} catch {
				throw new Error("Failed to parse DuckDuckGo search results");
			}

			const results: SearchResult[] = [];
			const abstract = data.Abstract as string;
			const abstractUrl = data.AbstractURL as string;
			if (abstract && abstractUrl) {
				results.push({ title: abstract, url: abstractUrl });
			}

			const topics = (data.RelatedTopics as Array<Record<string, unknown>>) ?? [];
			for (const topic of topics) {
				if (results.length >= limit) break;
				if (topic.Topics) continue;

				const text = topic.Text as string;
				const firstUrl = topic.FirstURL as string;
				if (text && firstUrl) {
					results.push({ title: text, url: firstUrl });
				}
			}

			const definition = data.Definition as string;
			const definitionUrl = data.DefinitionURL as string;
			if (results.length < limit && definition && definitionUrl) {
				results.push({ title: definition, url: definitionUrl });
			}

			return {
				content: [{ type: "text", text: renderSearchResults(results.slice(0, limit), "DuckDuckGo", params.query) }],
				details: { query: params.query, provider: "duckduckgo", resultCount: Math.min(results.length, limit) },
			};
		},
	});
}
