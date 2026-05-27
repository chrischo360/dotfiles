#!/usr/bin/env node
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const mcpUrl = process.env.GLEAN_MCP_URL || "https://wayfair-be.glean.com/mcp/default";
const credentialsPath = path.join(os.homedir(), ".claude", ".credentials.json");

if (!fs.existsSync(credentialsPath)) {
	throw new Error("Missing ~/.claude/.credentials.json. Run: claude-mcp --servers glean_default");
}

const credentials = JSON.parse(fs.readFileSync(credentialsPath, "utf8"));
const oauth = credentials.mcpOAuth ?? {};
const key = Object.keys(oauth).find((entryKey) => {
	const entry = oauth[entryKey];
	return entry?.serverName === "glean_default" || entry?.serverUrl === mcpUrl;
});

if (!key) {
	throw new Error("Missing Claude glean_default OAuth credentials. Run: claude-mcp --servers glean_default");
}

const entry = oauth[key];
if (!entry.refreshToken || !entry.clientId) {
	throw new Error("Claude Glean OAuth credentials are missing refreshToken/clientId. Re-auth with: claude-mcp --servers glean_default");
}

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

const toolsList = execFileSync(
	"curl",
	[
		"--silent",
		"--show-error",
		"--fail",
		"--location",
		"--max-time",
		"10",
		"--request",
		"POST",
		"--header",
		"Content-Type: application/json",
		"--header",
		"Accept: application/json, text/event-stream",
		"--header",
		"MCP-Protocol-Version: 2024-11-05",
		"--header",
		`Authorization: Bearer ${entry.accessToken}`,
		"--data",
		JSON.stringify({ jsonrpc: "2.0", id: 1, method: "tools/list" }),
		mcpUrl,
	],
	{ encoding: "utf8" },
);

const parsed = JSON.parse(toolsList);
const count = parsed?.result?.tools?.length ?? 0;
console.log(`Refreshed Claude Glean OAuth token. MCP tools available: ${count}`);
