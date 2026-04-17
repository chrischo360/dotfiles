/**
 * GitHub Extension
 *
 * Wraps the `gh` CLI as pi tools. Covers the most useful operations
 * from the github/github_wayfair MCP servers without needing Docker.
 *
 * Requires: gh CLI authenticated (`gh auth status`)
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { StringEnum } from "@mariozechner/pi-ai";

export default function (pi: ExtensionAPI) {
	// View PR details
	pi.registerTool({
		name: "gh_pr_view",
		label: "GitHub PR View",
		description: "View details of a GitHub PR (status, checks, reviews, description). Pass a PR URL or number, or omit for current branch.",
		parameters: Type.Object({
			pr: Type.Optional(Type.String({ description: "PR number, URL, or branch name. Omit to use current branch." })),
			repo: Type.Optional(Type.String({ description: "Repo in owner/name format (omit to use current repo)" })),
		}),
		async execute(_id, params, signal, _onUpdate, ctx) {
			const args = ["pr", "view", "--json",
				"number,title,state,url,body,author,labels,reviewDecision,statusCheckRollup,baseRefName,headRefName,createdAt,mergeable",
				"--jq",
				`{
					number,title,state,url,
					author: .author.login,
					base: .baseRefName,
					head: .headRefName,
					reviewDecision,
					mergeable,
					labels: [.labels[].name],
					checks: [.statusCheckRollup[]? | {name:.name, state:.state, conclusion:.conclusion}],
					body: (.body // "" | .[0:1000])
				}`
			];
			if (params.pr) args.push(params.pr);
			if (params.repo) args.push("--repo", params.repo);

			const result = await pi.exec("gh", args, { signal, timeout: 15000 });
			if (result.code !== 0) throw new Error(result.stderr || "gh pr view failed");
			return { content: [{ type: "text", text: result.stdout }], details: {} };
		},
	});

	// List PRs
	pi.registerTool({
		name: "gh_pr_list",
		label: "GitHub PR List",
		description: "List open PRs in a repo, optionally filtered by author or label.",
		parameters: Type.Object({
			repo: Type.Optional(Type.String({ description: "Repo in owner/name format (omit for current repo)" })),
			author: Type.Optional(Type.String({ description: "Filter by PR author (use @me for yourself)" })),
			label: Type.Optional(Type.String({ description: "Filter by label" })),
			limit: Type.Optional(Type.Number({ description: "Max results (default: 20)" })),
		}),
		async execute(_id, params, signal) {
			const args = ["pr", "list", "--json", "number,title,state,author,url,labels,createdAt",
				"--jq", "[.[] | {number,title,url,author:.author.login,labels:[.labels[].name]}]",
				"--limit", String(params.limit ?? 20),
			];
			if (params.repo) args.push("--repo", params.repo);
			if (params.author) args.push("--author", params.author);
			if (params.label) args.push("--label", params.label);

			const result = await pi.exec("gh", args, { signal, timeout: 15000 });
			if (result.code !== 0) throw new Error(result.stderr || "gh pr list failed");
			return { content: [{ type: "text", text: result.stdout }], details: {} };
		},
	});

	// PR checks / CI status
	pi.registerTool({
		name: "gh_pr_checks",
		label: "GitHub PR Checks",
		description: "View CI check statuses for a PR. Use to monitor build/test progress.",
		parameters: Type.Object({
			pr: Type.Optional(Type.String({ description: "PR number or URL (omit for current branch)" })),
			repo: Type.Optional(Type.String({ description: "Repo in owner/name format" })),
			watch: Type.Optional(Type.Boolean({ description: "Watch until all checks finish (default: false)" })),
		}),
		async execute(_id, params, signal) {
			const args = ["pr", "checks"];
			if (params.pr) args.push(params.pr);
			if (params.repo) args.push("--repo", params.repo);
			if (params.watch) args.push("--watch");

			const result = await pi.exec("gh", args, { signal, timeout: params.watch ? 600000 : 30000 });
			if (result.code !== 0 && !result.stdout) throw new Error(result.stderr || "gh pr checks failed");
			return { content: [{ type: "text", text: result.stdout || result.stderr }], details: {} };
		},
	});

	// Search issues/PRs
	pi.registerTool({
		name: "gh_search",
		label: "GitHub Search",
		description: "Search GitHub issues and PRs by text query.",
		parameters: Type.Object({
			query: Type.String({ description: "Search query (supports GitHub search syntax)" }),
			type: Type.Optional(
				StringEnum(["issues", "prs"] as const, { description: "Search issues or PRs (default: issues)" }),
			),
			repo: Type.Optional(Type.String({ description: "Limit to repo in owner/name format" })),
			limit: Type.Optional(Type.Number({ description: "Max results (default: 10)" })),
		}),
		async execute(_id, params, signal) {
			const args = [
				"search",
				params.type === "prs" ? "prs" : "issues",
				params.query,
				"--json", "number,title,url,state,author,labels",
				"--jq", "[.[] | {number,title,url,state,author:.author.login}]",
				"--limit", String(params.limit ?? 10),
			];
			if (params.repo) args.push("--repo", params.repo);

			const result = await pi.exec("gh", args, { signal, timeout: 15000 });
			if (result.code !== 0) throw new Error(result.stderr || "gh search failed");
			return { content: [{ type: "text", text: result.stdout }], details: {} };
		},
	});

	// View repo info
	pi.registerTool({
		name: "gh_repo_view",
		label: "GitHub Repo View",
		description: "View GitHub repository details (description, topics, default branch, open issues/PRs count).",
		parameters: Type.Object({
			repo: Type.Optional(Type.String({ description: "Repo in owner/name format (omit for current repo)" })),
		}),
		async execute(_id, params, signal) {
			const args = ["repo", "view", "--json",
				"name,description,url,defaultBranchRef,isPrivate,stargazerCount,openIssues,openPullRequests",
			];
			if (params.repo) args.push(params.repo);

			const result = await pi.exec("gh", args, { signal, timeout: 10000 });
			if (result.code !== 0) throw new Error(result.stderr || "gh repo view failed");
			return { content: [{ type: "text", text: result.stdout }], details: {} };
		},
	});

	// Add PR comment
	pi.registerTool({
		name: "gh_pr_comment",
		label: "GitHub PR Comment",
		description: "Add a comment to a GitHub PR.",
		parameters: Type.Object({
			body: Type.String({ description: "Comment text (markdown supported)" }),
			pr: Type.Optional(Type.String({ description: "PR number or URL (omit for current branch)" })),
			repo: Type.Optional(Type.String({ description: "Repo in owner/name format" })),
		}),
		async execute(_id, params, signal) {
			const args = ["pr", "comment", "--body", params.body];
			if (params.pr) args.push(params.pr);
			if (params.repo) args.push("--repo", params.repo);

			const result = await pi.exec("gh", args, { signal, timeout: 15000 });
			if (result.code !== 0) throw new Error(result.stderr || "gh pr comment failed");
			return { content: [{ type: "text", text: result.stdout || "Comment added." }], details: {} };
		},
	});
}
