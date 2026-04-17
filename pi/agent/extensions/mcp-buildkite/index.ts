/**
 * Buildkite Extension
 *
 * Wraps Buildkite API as pi tools. Covers the most useful operations
 * from the Wayfair Buildkite MCP server without needing Docker.
 *
 * Requires: BUILDKITE_TOKEN env var
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { StringEnum } from "@mariozechner/pi-ai";

const BK_API = "https://api.buildkite.com/v2";
const BK_ORG = "wayfair";

async function bkFetch(path: string): Promise<unknown> {
	const token = process.env.BUILDKITE_TOKEN ?? process.env.BUILDKITE_API_TOKEN;
	if (!token) throw new Error("BUILDKITE_TOKEN not set in .env");

	const res = await fetch(`${BK_API}${path}`, {
		headers: { Authorization: `Bearer ${token}` },
	});

	if (!res.ok) throw new Error(`Buildkite API ${res.status}: ${await res.text().then(t => t.slice(0, 200))}`);
	return res.json();
}

function formatBuild(b: Record<string, unknown>): string {
	const state = b.state as string;
	const icon = state === "passed" ? "✅" : state === "failed" ? "❌" : state === "running" ? "🔄" : "⏳";
	const pipeline = (b.pipeline as Record<string, string>)?.name ?? "?";
	const branch = b.branch as string;
	const num = b.number as number;
	const url = b.web_url as string;
	const msg = ((b.message as string) ?? "").split("\n")[0].slice(0, 60);
	const created = new Date(b.created_at as string).toLocaleString();
	return `${icon} #${num} ${pipeline} [${branch}] — ${msg}\n   ${created}\n   ${url}`;
}

export default function (pi: ExtensionAPI) {
	// Get build by URL or number
	pi.registerTool({
		name: "bk_build",
		label: "Buildkite Build",
		description: "Get status and details of a Buildkite build. Pass a build URL or pipeline+number.",
		parameters: Type.Object({
			url: Type.Optional(Type.String({ description: "Buildkite build URL (e.g. https://buildkite.com/wayfair/pipeline/builds/123)" })),
			pipeline: Type.Optional(Type.String({ description: "Pipeline slug (e.g. sf-ui-web-dev)" })),
			number: Type.Optional(Type.Number({ description: "Build number" })),
		}),
		async execute(_id, params) {
			let pipeline = params.pipeline;
			let number = params.number;

			if (params.url) {
				const m = params.url.match(/buildkite\.com\/[^/]+\/([^/]+)\/builds\/(\d+)/);
				if (!m) throw new Error("Could not parse build URL");
				pipeline = m[1];
				number = Number(m[2]);
			}

			if (!pipeline || !number) throw new Error("Provide either a build URL or pipeline+number");

			const build = await bkFetch(`/organizations/${BK_ORG}/pipelines/${pipeline}/builds/${number}`) as Record<string, unknown>;

			// Format jobs
			const jobs = (build.jobs as Record<string, unknown>[]) ?? [];
			const jobLines = jobs.map((j: Record<string, unknown>) => {
				const state = j.state as string;
				const icon = state === "passed" ? "✅" : state === "failed" ? "❌" : state === "running" ? "🔄" : "⏳";
				return `  ${icon} ${j.name ?? j.step_key ?? "step"} [${state}]`;
			});

			const text = [
				formatBuild(build),
				"",
				`Jobs (${jobs.length}):`,
				...jobLines.slice(0, 30),
				jobs.length > 30 ? `  ... and ${jobs.length - 30} more` : "",
			].filter(line => line !== undefined).join("\n");

			return { content: [{ type: "text", text: text }], details: {} };
		},
	});

	// List recent builds for a pipeline
	pi.registerTool({
		name: "bk_builds",
		label: "Buildkite Builds",
		description: "List recent Buildkite builds for a pipeline, optionally filtered by branch.",
		parameters: Type.Object({
			pipeline: Type.String({ description: "Pipeline slug (e.g. sf-ui-web-dev, sf-ui-web-ci)" }),
			branch: Type.Optional(Type.String({ description: "Filter by branch name" })),
			state: Type.Optional(
				StringEnum(["running", "passed", "failed", "canceled"] as const, {
					description: "Filter by build state",
				}),
			),
			limit: Type.Optional(Type.Number({ description: "Max results (default: 10)" })),
		}),
		async execute(_id, params) {
			const qs = new URLSearchParams({ per_page: String(params.limit ?? 10) });
			if (params.branch) qs.set("branch", params.branch);
			if (params.state) qs.set("state", params.state);

			const builds = await bkFetch(
				`/organizations/${BK_ORG}/pipelines/${params.pipeline}/builds?${qs}`,
			) as Record<string, unknown>[];

			if (!builds.length) return { content: [{ type: "text", text: "No builds found." }], details: {} };

			const text = builds.map(formatBuild).join("\n\n");
			return { content: [{ type: "text", text: text }], details: {} };
		},
	});

	// Get build log for a failed job
	pi.registerTool({
		name: "bk_job_log",
		label: "Buildkite Job Log",
		description: "Get the log output of a specific Buildkite job. Use to diagnose build failures.",
		parameters: Type.Object({
			pipeline: Type.String({ description: "Pipeline slug" }),
			build_number: Type.Number({ description: "Build number" }),
			job_id: Type.String({ description: "Job ID (from bk_build output)" }),
		}),
		async execute(_id, params) {
			const log = await bkFetch(
				`/organizations/${BK_ORG}/pipelines/${params.pipeline}/builds/${params.build_number}/jobs/${params.job_id}/log`,
			) as Record<string, unknown>;

			const content = ((log.content as string) ?? "").slice(-8000); // last 8k chars
			return { content: [{ type: "text", text: content || "No log output." }], details: {} };
		},
	});

	// List pipelines
	pi.registerTool({
		name: "bk_pipelines",
		label: "Buildkite Pipelines",
		description: "List Buildkite pipelines in the Wayfair org, optionally filtered by name.",
		parameters: Type.Object({
			filter: Type.Optional(Type.String({ description: "Filter pipelines by name" })),
		}),
		async execute(_id, params) {
			const pipelines = await bkFetch(`/organizations/${BK_ORG}/pipelines?per_page=50`) as Record<string, unknown>[];

			let filtered = pipelines;
			if (params.filter) {
				const q = params.filter.toLowerCase();
				filtered = pipelines.filter((p) => (p.name as string).toLowerCase().includes(q) || (p.slug as string).toLowerCase().includes(q));
			}

			const text = filtered
				.map((p: Record<string, unknown>) => `${p.name} (${p.slug}) — ${p.url}`)
				.join("\n");

			return { content: [{ type: "text", text: text || "No pipelines found." }], details: {} };
		},
	});
}
