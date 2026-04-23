/**
 * GitHub Extension for Pi
 *
 * Replicates core GitHub MCP server tools using the `gh` CLI.
 * Provides: search_code, search_repos, get_file_contents, get_pr, list_prs,
 * get_issue, list_issues, search_issues, list_pr_files, get_pr_diff,
 * list_pr_comments, list_commits, create_pr_comment.
 *
 * Requires:
 *   gh CLI installed and authenticated (gh auth login)
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";

const MAX_RESPONSE = 80_000;

async function gh(
	pi: ExtensionAPI,
	args: string[],
	signal?: AbortSignal,
): Promise<string> {
	const result = await pi.exec("gh", args, { signal, timeout: 30000 });

	if (result.code !== 0 && !result.stdout) {
		throw new Error(`gh error: ${result.stderr.slice(0, 300)}`);
	}

	let content = result.stdout;
	if (content.length > MAX_RESPONSE) {
		content = content.slice(0, MAX_RESPONSE) + `\n\n[Truncated — ${content.length} chars, showing first ${MAX_RESPONSE}]`;
	}
	return content;
}

async function ghApi(
	pi: ExtensionAPI,
	endpoint: string,
	signal?: AbortSignal,
	method?: string,
	body?: string,
): Promise<string> {
	const args = ["api", endpoint];
	if (method) args.push("--method", method);
	if (body) args.push("--input", "-");

	const result = await pi.exec("gh", args, { signal, timeout: 30000 });

	if (result.code !== 0 && !result.stdout) {
		throw new Error(`gh api error: ${result.stderr.slice(0, 300)}`);
	}

	let content = result.stdout;
	if (content.length > MAX_RESPONSE) {
		content = content.slice(0, MAX_RESPONSE) + `\n\n[Truncated — ${content.length} chars, showing first ${MAX_RESPONSE}]`;
	}
	return content;
}

export default function (pi: ExtensionAPI) {
	// gh_search_code — search code across repos
	pi.registerTool({
		name: "gh_search_code",
		label: "GitHub Code Search",
		description:
			"Search code across GitHub repositories. Uses GitHub's code search syntax. " +
			"Supports qualifiers: repo:, path:, language:, org:, extension:.",
		parameters: Type.Object({
			query: Type.String({ description: "Code search query (supports GitHub search syntax)" }),
			limit: Type.Optional(Type.Number({ description: "Max results (default: 20)" })),
		}),
		async execute(_id, params, signal) {
			const content = await gh(
				pi,
				["search", "code", params.query, "--limit", String(params.limit || 20), "--json", "path,repository,textMatches"],
				signal,
			);
			return {
				content: [{ type: "text", text: content }],
				details: { query: params.query },
			};
		},
	});

	// gh_search_repos — search repositories
	pi.registerTool({
		name: "gh_search_repos",
		label: "GitHub Search Repos",
		description: "Search GitHub repositories by name, description, or topic.",
		parameters: Type.Object({
			query: Type.String({ description: "Repository search query" }),
			limit: Type.Optional(Type.Number({ description: "Max results (default: 20)" })),
		}),
		async execute(_id, params, signal) {
			const content = await gh(
				pi,
				["search", "repos", params.query, "--limit", String(params.limit || 20), "--json", "fullName,description,url,isPrivate,updatedAt"],
				signal,
			);
			return {
				content: [{ type: "text", text: content }],
				details: { query: params.query },
			};
		},
	});

	// gh_get_file_contents — read a file from a repo
	pi.registerTool({
		name: "gh_get_file_contents",
		label: "GitHub Get File",
		description: "Read the contents of a file from a GitHub repository.",
		parameters: Type.Object({
			repo: Type.String({ description: "Repository (owner/repo)" }),
			path: Type.String({ description: "File path in the repository" }),
			ref: Type.Optional(Type.String({ description: "Branch, tag, or commit (default: default branch)" })),
		}),
		async execute(_id, params, signal) {
			const args = ["api", `repos/${params.repo}/contents/${params.path}`];
			if (params.ref) args.push("-f", `ref=${params.ref}`);
			args.push("--jq", ".content", "-H", "Accept: application/vnd.github.raw+json");

			// Use raw content endpoint instead
			let endpoint = `repos/${params.repo}/contents/${params.path}`;
			if (params.ref) endpoint += `?ref=${params.ref}`;
			const content = await gh(
				pi,
				["api", endpoint, "-H", "Accept: application/vnd.github.raw+json"],
				signal,
			);
			return {
				content: [{ type: "text", text: content }],
				details: { repo: params.repo, path: params.path },
			};
		},
	});

	// gh_get_pr — get pull request details
	pi.registerTool({
		name: "gh_get_pr",
		label: "GitHub Get PR",
		description: "Get details of a pull request including title, body, status, checks, and reviewers.",
		parameters: Type.Object({
			repo: Type.String({ description: "Repository (owner/repo)" }),
			number: Type.Number({ description: "PR number" }),
		}),
		async execute(_id, params, signal) {
			const content = await gh(
				pi,
				[
					"pr", "view", String(params.number),
					"--repo", params.repo,
					"--json", "number,title,body,state,author,baseRefName,headRefName,mergeable,reviewDecision,statusCheckRollup,additions,deletions,changedFiles,url,createdAt,updatedAt",
				],
				signal,
			);
			return {
				content: [{ type: "text", text: content }],
				details: { repo: params.repo, number: params.number },
			};
		},
	});

	// gh_list_prs — list pull requests
	pi.registerTool({
		name: "gh_list_prs",
		label: "GitHub List PRs",
		description: "List pull requests in a repository. Filter by state, author, base branch, label.",
		parameters: Type.Object({
			repo: Type.String({ description: "Repository (owner/repo)" }),
			state: Type.Optional(Type.String({ description: "Filter by state: open, closed, merged, all (default: open)" })),
			author: Type.Optional(Type.String({ description: "Filter by author username" })),
			base: Type.Optional(Type.String({ description: "Filter by base branch" })),
			label: Type.Optional(Type.String({ description: "Filter by label" })),
			limit: Type.Optional(Type.Number({ description: "Max results (default: 20)" })),
		}),
		async execute(_id, params, signal) {
			const args = [
				"pr", "list",
				"--repo", params.repo,
				"--limit", String(params.limit || 20),
				"--json", "number,title,state,author,baseRefName,headRefName,url,createdAt,updatedAt",
			];
			if (params.state) args.push("--state", params.state);
			if (params.author) args.push("--author", params.author);
			if (params.base) args.push("--base", params.base);
			if (params.label) args.push("--label", params.label);

			const content = await gh(pi, args, signal);
			return {
				content: [{ type: "text", text: content }],
				details: { repo: params.repo },
			};
		},
	});

	// gh_get_pr_diff — get PR diff
	pi.registerTool({
		name: "gh_get_pr_diff",
		label: "GitHub PR Diff",
		description: "Get the full diff of a pull request.",
		parameters: Type.Object({
			repo: Type.String({ description: "Repository (owner/repo)" }),
			number: Type.Number({ description: "PR number" }),
		}),
		async execute(_id, params, signal) {
			const content = await gh(
				pi,
				["pr", "diff", String(params.number), "--repo", params.repo],
				signal,
			);
			return {
				content: [{ type: "text", text: content }],
				details: { repo: params.repo, number: params.number },
			};
		},
	});

	// gh_list_pr_files — list files changed in a PR
	pi.registerTool({
		name: "gh_list_pr_files",
		label: "GitHub PR Files",
		description: "List files changed in a pull request with additions/deletions.",
		parameters: Type.Object({
			repo: Type.String({ description: "Repository (owner/repo)" }),
			number: Type.Number({ description: "PR number" }),
		}),
		async execute(_id, params, signal) {
			const content = await gh(
				pi,
				["api", `repos/${params.repo}/pulls/${params.number}/files`, "--jq", ".[] | {filename, status, additions, deletions, changes}"],
				signal,
			);
			return {
				content: [{ type: "text", text: content }],
				details: { repo: params.repo, number: params.number },
			};
		},
	});

	// gh_list_pr_comments — list comments on a PR
	pi.registerTool({
		name: "gh_list_pr_comments",
		label: "GitHub PR Comments",
		description: "List review comments on a pull request.",
		parameters: Type.Object({
			repo: Type.String({ description: "Repository (owner/repo)" }),
			number: Type.Number({ description: "PR number" }),
		}),
		async execute(_id, params, signal) {
			const content = await gh(
				pi,
				["api", `repos/${params.repo}/pulls/${params.number}/comments`],
				signal,
			);
			return {
				content: [{ type: "text", text: content }],
				details: { repo: params.repo, number: params.number },
			};
		},
	});

	// gh_get_issue — get issue details
	pi.registerTool({
		name: "gh_get_issue",
		label: "GitHub Get Issue",
		description: "Get details of a GitHub issue including title, body, labels, assignees.",
		parameters: Type.Object({
			repo: Type.String({ description: "Repository (owner/repo)" }),
			number: Type.Number({ description: "Issue number" }),
		}),
		async execute(_id, params, signal) {
			const content = await gh(
				pi,
				[
					"issue", "view", String(params.number),
					"--repo", params.repo,
					"--json", "number,title,body,state,author,labels,assignees,url,createdAt,updatedAt,comments",
				],
				signal,
			);
			return {
				content: [{ type: "text", text: content }],
				details: { repo: params.repo, number: params.number },
			};
		},
	});

	// gh_list_issues — list issues in a repo
	pi.registerTool({
		name: "gh_list_issues",
		label: "GitHub List Issues",
		description: "List issues in a repository. Filter by state, author, assignee, label.",
		parameters: Type.Object({
			repo: Type.String({ description: "Repository (owner/repo)" }),
			state: Type.Optional(Type.String({ description: "Filter: open, closed, all (default: open)" })),
			author: Type.Optional(Type.String({ description: "Filter by author" })),
			assignee: Type.Optional(Type.String({ description: "Filter by assignee" })),
			label: Type.Optional(Type.String({ description: "Filter by label" })),
			limit: Type.Optional(Type.Number({ description: "Max results (default: 20)" })),
		}),
		async execute(_id, params, signal) {
			const args = [
				"issue", "list",
				"--repo", params.repo,
				"--limit", String(params.limit || 20),
				"--json", "number,title,state,author,labels,assignees,url,createdAt,updatedAt",
			];
			if (params.state) args.push("--state", params.state);
			if (params.author) args.push("--author", params.author);
			if (params.assignee) args.push("--assignee", params.assignee);
			if (params.label) args.push("--label", params.label);

			const content = await gh(pi, args, signal);
			return {
				content: [{ type: "text", text: content }],
				details: { repo: params.repo },
			};
		},
	});

	// gh_search_issues — search issues/PRs
	pi.registerTool({
		name: "gh_search_issues",
		label: "GitHub Search Issues",
		description:
			"Search issues and pull requests across repositories. " +
			"Uses GitHub search syntax: is:issue, is:pr, is:open, is:closed, label:, author:, repo:.",
		parameters: Type.Object({
			query: Type.String({ description: "Search query (GitHub search syntax)" }),
			limit: Type.Optional(Type.Number({ description: "Max results (default: 20)" })),
		}),
		async execute(_id, params, signal) {
			const content = await gh(
				pi,
				["search", "issues", params.query, "--limit", String(params.limit || 20), "--json", "number,title,state,repository,author,url,createdAt,updatedAt,labels"],
				signal,
			);
			return {
				content: [{ type: "text", text: content }],
				details: { query: params.query },
			};
		},
	});

	// gh_list_commits — list commits on a branch
	pi.registerTool({
		name: "gh_list_commits",
		label: "GitHub List Commits",
		description: "List recent commits on a branch.",
		parameters: Type.Object({
			repo: Type.String({ description: "Repository (owner/repo)" }),
			branch: Type.Optional(Type.String({ description: "Branch name (default: default branch)" })),
			limit: Type.Optional(Type.Number({ description: "Max results (default: 20)" })),
		}),
		async execute(_id, params, signal) {
			let endpoint = `repos/${params.repo}/commits?per_page=${params.limit || 20}`;
			if (params.branch) endpoint += `&sha=${params.branch}`;
			const content = await gh(
				pi,
				["api", endpoint, "--jq", ".[] | {sha: .sha[0:8], message: .commit.message, author: .commit.author.name, date: .commit.author.date}"],
				signal,
			);
			return {
				content: [{ type: "text", text: content }],
				details: { repo: params.repo },
			};
		},
	});

	// gh_create_pr_comment — add a comment on a PR
	pi.registerTool({
		name: "gh_create_pr_comment",
		label: "GitHub PR Comment",
		description: "Add a comment to a pull request.",
		parameters: Type.Object({
			repo: Type.String({ description: "Repository (owner/repo)" }),
			number: Type.Number({ description: "PR number" }),
			body: Type.String({ description: "Comment text (markdown supported)" }),
		}),
		async execute(_id, params, signal) {
			const content = await gh(
				pi,
				["pr", "comment", String(params.number), "--repo", params.repo, "--body", params.body],
				signal,
			);
			return {
				content: [{ type: "text", text: content || "Comment added successfully." }],
				details: { repo: params.repo, number: params.number },
			};
		},
	});
}
