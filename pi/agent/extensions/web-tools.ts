/**
 * Web Tools Extension
 *
 * Adds web_fetch and web_search tools — equivalents of Claude Code's
 * built-in WebFetch and WebSearch tools.
 *
 * web_fetch: fetches a URL via curl, strips HTML to readable text
 * web_search: DuckDuckGo search (no API key required)
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { StringEnum } from "@mariozechner/pi-ai";

const MAX_BYTES = 50_000;

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

	// web_search — equivalent of Claude's WebSearch, uses DuckDuckGo
	pi.registerTool({
		name: "web_search",
		label: "Web Search",
		description: "Search the web using DuckDuckGo. Returns titles, URLs, and snippets. Use for researching libraries, error messages, documentation.",
		promptSnippet: "Search the web for information",
		parameters: Type.Object({
			query: Type.String({ description: "Search query" }),
			limit: Type.Optional(Type.Number({ description: "Max results to return (default: 8)" })),
		}),
		async execute(_id, params, signal) {
			// DuckDuckGo Instant Answer API — no key required
			const encoded = encodeURIComponent(params.query);
			const url = `https://api.duckduckgo.com/?q=${encoded}&format=json&no_html=1&skip_disambig=1`;

			const result = await pi.exec(
				"curl",
				["--silent", "--location", "--max-time", "15", url],
				{ signal, timeout: 20000 },
			);

			if (result.code !== 0) throw new Error(`Search failed: ${result.stderr.slice(0, 200)}`);

			let data: Record<string, unknown>;
			try {
				data = JSON.parse(result.stdout);
			} catch {
				throw new Error("Failed to parse search results");
			}

			const lines: string[] = [];
			const limit = Math.min(params.limit ?? 8, 20);

			// Instant answer / abstract
			const abstract = data.Abstract as string;
			const abstractUrl = data.AbstractURL as string;
			if (abstract) {
				lines.push(`**Answer:** ${abstract}`);
				if (abstractUrl) lines.push(`Source: ${abstractUrl}`);
				lines.push("");
			}

			// Related topics (main results)
			const topics = (data.RelatedTopics as Array<Record<string, unknown>>) ?? [];
			let count = 0;
			for (const topic of topics) {
				if (count >= limit) break;

				// Skip category headers
				if (topic.Topics) continue;

				const text = topic.Text as string;
				const firstUrl = topic.FirstURL as string;
				if (text && firstUrl) {
					lines.push(`${count + 1}. ${text}`);
					lines.push(`   ${firstUrl}`);
					count++;
				}
			}

			if (lines.length === 0) {
				// Fall back to showing the raw definition if no topics
				const definition = data.Definition as string;
				if (definition) {
					lines.push(definition);
					lines.push((data.DefinitionURL as string) ?? "");
				} else {
					lines.push(`No results found for: ${params.query}`);
					lines.push("Tip: Try a more specific query, or use web_fetch with a direct URL.");
				}
			}

			return {
				content: [{ type: "text", text: lines.join("\n") }],
				details: { query: params.query, resultCount: count },
			};
		},
	});
}
