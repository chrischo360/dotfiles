import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";

const MAX_RESPONSE = 80_000;
const DEFAULT_DOMAIN = "mcp.datadoghq.com";
const DEFAULT_PATH = "/api/unstable/mcp-server/mcp";

type Json = null | boolean | number | string | Json[] | { [key: string]: Json };

function getMcpUrl(): string {
	const explicitUrl = process.env.DD_MCP_URL || process.env.DATADOG_MCP_URL;
	if (explicitUrl) return withToolsets(explicitUrl);

	const domain = process.env.DD_MCP_DOMAIN || DEFAULT_DOMAIN;
	return withToolsets(`https://${domain}${DEFAULT_PATH}`);
}

function withToolsets(url: string): string {
	const toolsets = process.env.DD_MCP_TOOLSETS;
	if (!toolsets) return url;
	const separator = url.includes("?") ? "&" : "?";
	return `${url}${separator}toolsets=${encodeURIComponent(toolsets)}`;
}

function truncate(content: string): string {
	if (content.length <= MAX_RESPONSE) return content;
	return content.slice(0, MAX_RESPONSE) + `\n\n[Truncated — ${content.length} chars, showing first ${MAX_RESPONSE}]`;
}

function extractSsePayload(raw: string): string {
	const data = raw
		.split("\n")
		.map((line) => line.trim())
		.filter((line) => line.startsWith("data:"))
		.map((line) => line.slice(5).trim())
		.filter((line) => line && line !== "[DONE]")
		.join("\n");
	return data || raw;
}

function renderMcpResponse(raw: string): string {
	const payload = extractSsePayload(raw);

	try {
		const parsed = JSON.parse(payload);
		if (parsed?.error) {
			throw new Error(JSON.stringify(parsed.error));
		}

		const content = parsed?.result?.content;
		if (Array.isArray(content)) {
			const parts = content
				.map((item) => item?.text ?? item?.json ?? item)
				.map((item) => (typeof item === "string" ? item : JSON.stringify(item, null, 2)))
				.filter(Boolean);
			if (parts.length > 0) return truncate(parts.join("\n"));
		}

		return truncate(JSON.stringify(parsed?.result ?? parsed, null, 2));
	} catch (error) {
		if (error instanceof Error && payload.trim().startsWith("{")) throw error;
		return truncate(payload);
	}
}

function addAuthHeaders(args: string[]): void {
	const authHeader = process.env.DD_MCP_AUTH_HEADER || process.env.DATADOG_MCP_AUTH_HEADER;
	if (authHeader) {
		args.push("--header", `Authorization: ${authHeader}`);
		return;
	}

	const apiKey = process.env.DD_API_KEY || process.env.DATADOG_API_KEY;
	const appKey = process.env.DD_APPLICATION_KEY || process.env.DD_APP_KEY || process.env.DATADOG_APPLICATION_KEY || process.env.DATADOG_APP_KEY;

	if (!apiKey || !appKey) {
		throw new Error("Datadog MCP requires DD_API_KEY and DD_APPLICATION_KEY, or DD_MCP_AUTH_HEADER for OAuth.");
	}

	args.push("--header", `DD_API_KEY: ${apiKey}`);
	args.push("--header", `DD_APPLICATION_KEY: ${appKey}`);
}

async function mcpRequest(
	pi: ExtensionAPI,
	method: string,
	params?: Record<string, unknown>,
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

	addAuthHeaders(curlArgs);
	curlArgs.push(
		"--data",
		JSON.stringify({ jsonrpc: "2.0", id: Date.now(), method, ...(params ? { params } : {}) }),
		getMcpUrl(),
	);

	const result = await pi.exec("curl", curlArgs, { signal, timeout: 35000 });
	if (result.code !== 0 && !result.stdout) {
		throw new Error(`Datadog MCP error: ${result.stderr.slice(0, 300)}`);
	}

	return renderMcpResponse(result.stdout || result.stderr);
}

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "datadog_list_tools",
		label: "Datadog List Tools",
		description: "List tools exposed by the Datadog MCP server. Use this before calling a Datadog tool when the exact tool name or arguments are unknown.",
		parameters: Type.Object({}),
		async execute(_id, _params, signal) {
			return { content: [{ type: "text", text: await mcpRequest(pi, "tools/list", undefined, signal) }], details: { url: getMcpUrl() } };
		},
	});

	pi.registerTool({
		name: "datadog_call_tool",
		label: "Datadog Call Tool",
		description: "Call a Datadog MCP tool by name with JSON arguments. Use datadog_list_tools first to discover supported tools and schemas.",
		parameters: Type.Object({
			name: Type.String({ description: "Datadog MCP tool name" }),
			arguments: Type.Optional(Type.Record(Type.String(), Type.Any(), { description: "Tool arguments as a JSON object" })),
		}),
		async execute(_id, params, signal) {
			const args = (params.arguments ?? {}) as Record<string, Json>;
			return {
				content: [{ type: "text", text: await mcpRequest(pi, "tools/call", { name: params.name, arguments: args }, signal) }],
				details: { name: params.name },
			};
		},
	});
}
