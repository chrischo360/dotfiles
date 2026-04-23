/**
 * Sourcegraph Extension for Pi
 *
 * Replicates the Sourcegraph MCP server tools using the Sourcegraph GraphQL API.
 * Provides: keyword_search, nls_search, read_file, list_files, list_repos,
 * commit_search, diff_search, find_references, go_to_definition,
 * compare_revisions, get_contributor_repos.
 *
 * Requires env vars:
 *   SOURCEGRAPH_URL   - Sourcegraph instance URL (default: https://wayfair.sourcegraphcloud.com)
 *   SOURCEGRAPH_TOKEN - Sourcegraph access token
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";

const MAX_RESPONSE = 80_000;

function getUrl(): string {
	return process.env.SOURCEGRAPH_URL || "https://wayfair.sourcegraphcloud.com";
}

function getToken(): string {
	const token = process.env.SOURCEGRAPH_TOKEN;
	if (!token) throw new Error("SOURCEGRAPH_TOKEN environment variable is required");
	return token;
}

async function sgGraphQL(
	pi: ExtensionAPI,
	query: string,
	variables: Record<string, unknown>,
	signal?: AbortSignal,
): Promise<string> {
	const url = `${getUrl()}/.api/graphql`;
	const jsonBody = JSON.stringify({ query, variables });

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
			`Authorization: token ${getToken()}`,
			"--header",
			"Content-Type: application/json",
			"--data",
			jsonBody,
			url,
		],
		{ signal, timeout: 35000 },
	);

	if (result.code !== 0 && !result.stdout) {
		throw new Error(`Sourcegraph API error: ${result.stderr.slice(0, 300)}`);
	}

	let content = result.stdout;
	if (content.length > MAX_RESPONSE) {
		content = content.slice(0, MAX_RESPONSE) + `\n\n[Truncated — ${content.length} chars, showing first ${MAX_RESPONSE}]`;
	}
	return content;
}

async function sgStreamAPI(
	pi: ExtensionAPI,
	path: string,
	signal?: AbortSignal,
): Promise<string> {
	const url = `${getUrl()}${path}`;

	const result = await pi.exec(
		"curl",
		[
			"--silent",
			"--location",
			"--max-time",
			"30",
			"--header",
			`Authorization: token ${getToken()}`,
			url,
		],
		{ signal, timeout: 35000 },
	);

	if (result.code !== 0 && !result.stdout) {
		throw new Error(`Sourcegraph API error: ${result.stderr.slice(0, 300)}`);
	}

	let content = result.stdout;
	if (content.length > MAX_RESPONSE) {
		content = content.slice(0, MAX_RESPONSE) + `\n\n[Truncated — ${content.length} chars, showing first ${MAX_RESPONSE}]`;
	}
	return content;
}

function buildSearchQuery(terms: {
	patternType?: string;
	pattern?: string;
	repos?: string[];
	type?: string;
	extra?: string[];
}): string {
	const parts: string[] = [];
	if (terms.repos?.length) {
		for (const r of terms.repos) parts.push(`repo:${r}`);
	}
	if (terms.type) parts.push(`type:${terms.type}`);
	if (terms.patternType) parts.push(`patterntype:${terms.patternType}`);
	if (terms.extra) parts.push(...terms.extra);
	if (terms.pattern) parts.push(terms.pattern);
	return parts.join(" ");
}

const SEARCH_QUERY = `
query Search($query: String!) {
  search(query: $query, version: V3) {
    results {
      resultCount
      limitHit
      results {
        ... on FileMatch {
          __typename
          repository { name }
          file { path url }
          lineMatches {
            preview
            lineNumber
          }
        }
        ... on CommitSearchResult {
          __typename
          commit {
            repository { name }
            oid
            abbreviatedOID
            author { person { displayName email } date }
            message
            url
          }
          diffPreview { value }
        }
      }
    }
  }
}`;

const FILE_QUERY = `
query FileContent($repo: String!, $rev: String!, $path: String!) {
  repository(name: $repo) {
    commit(rev: $rev) {
      file(path: $path) {
        content
        totalLines
      }
    }
  }
}`;

const LIST_FILES_QUERY = `
query ListFiles($repo: String!, $rev: String!, $path: String!) {
  repository(name: $repo) {
    commit(rev: $rev) {
      path(path: $path) {
        ... on GitTree {
          entries {
            name
            isDirectory
            path
          }
        }
      }
    }
  }
}`;

const LIST_REPOS_QUERY = `
query ListRepos($query: String!, $first: Int!, $after: String) {
  repositories(query: $query, first: $first, after: $after) {
    nodes {
      name
      description
      url
    }
    pageInfo {
      endCursor
      hasNextPage
    }
    totalCount
  }
}`;

const COMPARE_QUERY = `
query CompareRevisions($repo: String!, $base: String!, $head: String!, $first: Int!) {
  repository(name: $repo) {
    comparison(base: $base, head: $head) {
      fileDiffs(first: $first) {
        nodes {
          oldPath
          newPath
          stat { added deleted }
          hunks {
            oldRange { startLine lines }
            newRange { startLine lines }
            body
          }
        }
        totalCount
      }
    }
  }
}`;

export default function (pi: ExtensionAPI) {
	// sg_keyword_search — exact keyword code search
	pi.registerTool({
		name: "sg_keyword_search",
		label: "Sourcegraph Keyword Search",
		description:
			"Keyword code search for exact string matches across repositories. " +
			"Supports filters in query: repo:, file:, rev:, lang:. " +
			"Use for finding specific function names, variable names, exact strings.",
		parameters: Type.Object({
			query: Type.String({ description: "Search query with keywords and optional filters (repo:, file:, rev:)" }),
		}),
		async execute(_id, params, signal) {
			const content = await sgGraphQL(
				pi,
				SEARCH_QUERY,
				{ query: `${params.query} patterntype:keyword count:50` },
				signal,
			);
			return {
				content: [{ type: "text", text: content }],
				details: { query: params.query },
			};
		},
	});

	// sg_nls_search — broad/fuzzy search with stemming
	pi.registerTool({
		name: "sg_nls_search",
		label: "Sourcegraph NLS Search",
		description:
			"Broad keyword search with stemming and flexible matching (OR logic). " +
			"Better for exploratory searches. Supports repo:, file:, rev: filters.",
		parameters: Type.Object({
			query: Type.String({ description: "Search query with keywords and optional filters" }),
		}),
		async execute(_id, params, signal) {
			const content = await sgGraphQL(
				pi,
				SEARCH_QUERY,
				{ query: `${params.query} patterntype:nls count:50` },
				signal,
			);
			return {
				content: [{ type: "text", text: content }],
				details: { query: params.query },
			};
		},
	});

	// sg_read_file — read file contents
	pi.registerTool({
		name: "sg_read_file",
		label: "Sourcegraph Read File",
		description: "Read the content of a file from a repository on Sourcegraph.",
		parameters: Type.Object({
			repo: Type.String({ description: "Repository name (e.g., github.com/org/repo)" }),
			path: Type.String({ description: "File path within the repository" }),
			revision: Type.Optional(Type.String({ description: "Branch, tag, or commit hash (default: HEAD)" })),
			startLine: Type.Optional(Type.Number({ description: "Start reading from this line (1-based)" })),
			endLine: Type.Optional(Type.Number({ description: "Stop reading at this line (1-based)" })),
		}),
		async execute(_id, params, signal) {
			const rev = params.revision || "HEAD";
			const result = await sgGraphQL(pi, FILE_QUERY, { repo: params.repo, rev, path: params.path }, signal);

			let content = result;
			try {
				const data = JSON.parse(result);
				const fileContent = data?.data?.repository?.commit?.file?.content;
				if (fileContent && (params.startLine || params.endLine)) {
					const lines = fileContent.split("\n");
					const start = (params.startLine || 1) - 1;
					const end = params.endLine || lines.length;
					const sliced = lines.slice(start, end);
					content = sliced.map((line: string, i: number) => `${start + i + 1}\t${line}`).join("\n");
				}
			} catch {}

			return {
				content: [{ type: "text", text: content }],
				details: { repo: params.repo, path: params.path },
			};
		},
	});

	// sg_list_files — list directory contents
	pi.registerTool({
		name: "sg_list_files",
		label: "Sourcegraph List Files",
		description: "List files and subdirectories in a repository directory.",
		parameters: Type.Object({
			repo: Type.String({ description: "Repository name (e.g., github.com/org/repo)" }),
			path: Type.Optional(Type.String({ description: "Directory path (default: root)" })),
			revision: Type.Optional(Type.String({ description: "Branch, tag, or commit hash (default: HEAD)" })),
		}),
		async execute(_id, params, signal) {
			const content = await sgGraphQL(
				pi,
				LIST_FILES_QUERY,
				{ repo: params.repo, rev: params.revision || "HEAD", path: params.path || "" },
				signal,
			);
			return {
				content: [{ type: "text", text: content }],
				details: { repo: params.repo, path: params.path },
			};
		},
	});

	// sg_list_repos — search/list repositories
	pi.registerTool({
		name: "sg_list_repos",
		label: "Sourcegraph List Repos",
		description: "List repositories matching a search query. Supports pagination.",
		parameters: Type.Object({
			query: Type.String({ description: "Search query to filter repositories" }),
			limit: Type.Optional(Type.Number({ description: "Max repos to return (default: 50)" })),
			after: Type.Optional(Type.String({ description: "Pagination cursor from previous response" })),
		}),
		async execute(_id, params, signal) {
			const content = await sgGraphQL(
				pi,
				LIST_REPOS_QUERY,
				{ query: params.query, first: params.limit || 50, after: params.after || null },
				signal,
			);
			return {
				content: [{ type: "text", text: content }],
				details: { query: params.query },
			};
		},
	});

	// sg_commit_search — search commits
	pi.registerTool({
		name: "sg_commit_search",
		label: "Sourcegraph Commit Search",
		description:
			"Search for commits across repositories. Find who made changes, when features were added, " +
			"or track code history.",
		parameters: Type.Object({
			repos: Type.Array(Type.String(), { description: "Repositories to search (e.g., github.com/org/repo)" }),
			messageTerms: Type.Optional(Type.Array(Type.String(), { description: "Terms to search in commit messages" })),
			contentTerms: Type.Optional(Type.Array(Type.String(), { description: "Terms to search in actual code changes" })),
			authors: Type.Optional(Type.Array(Type.String(), { description: "Filter by author names/emails" })),
			after: Type.Optional(Type.String({ description: "Commits after this date (YYYY-MM-DD or '1 month ago')" })),
			before: Type.Optional(Type.String({ description: "Commits before this date" })),
			count: Type.Optional(Type.Number({ description: "Max results (default: 50, max: 100)" })),
		}),
		async execute(_id, params, signal) {
			const parts: string[] = ["type:commit"];
			for (const r of params.repos) parts.push(`repo:${r}`);
			if (params.authors) for (const a of params.authors) parts.push(`author:${a}`);
			if (params.after) parts.push(`after:${params.after}`);
			if (params.before) parts.push(`before:${params.before}`);
			if (params.messageTerms) parts.push(`message:${params.messageTerms.join("|")}`);
			if (params.contentTerms) parts.push(params.contentTerms.join(" "));
			parts.push(`count:${params.count || 50}`);

			const content = await sgGraphQL(pi, SEARCH_QUERY, { query: parts.join(" ") }, signal);
			return {
				content: [{ type: "text", text: content }],
				details: { repos: params.repos },
			};
		},
	});

	// sg_diff_search — search code diffs
	pi.registerTool({
		name: "sg_diff_search",
		label: "Sourcegraph Diff Search",
		description:
			"Search for code changes (diffs) across repositories. Searches actual added/removed lines.",
		parameters: Type.Object({
			pattern: Type.String({ description: "Pattern to search for in diff content" }),
			repos: Type.Array(Type.String(), { description: "Repository patterns to search" }),
			author: Type.Optional(Type.String({ description: "Filter by author" })),
			after: Type.Optional(Type.String({ description: "Changes after this time (YYYY-MM-DD or '2 weeks ago')" })),
			before: Type.Optional(Type.String({ description: "Changes before this time" })),
			count: Type.Optional(Type.Number({ description: "Max results" })),
		}),
		async execute(_id, params, signal) {
			const parts: string[] = ["type:diff"];
			for (const r of params.repos) parts.push(`repo:${r}`);
			if (params.author) parts.push(`author:${params.author}`);
			if (params.after) parts.push(`after:${params.after}`);
			if (params.before) parts.push(`before:${params.before}`);
			if (params.count) parts.push(`count:${params.count}`);
			parts.push(params.pattern);

			const content = await sgGraphQL(pi, SEARCH_QUERY, { query: parts.join(" ") }, signal);
			return {
				content: [{ type: "text", text: content }],
				details: { pattern: params.pattern },
			};
		},
	});

	// sg_find_references — find symbol references
	pi.registerTool({
		name: "sg_find_references",
		label: "Sourcegraph Find References",
		description: "Find all references to a symbol (function, class, variable) in a repository.",
		parameters: Type.Object({
			repo: Type.String({ description: "Repository name" }),
			path: Type.String({ description: "File path containing the symbol" }),
			symbol: Type.String({ description: "Symbol name to find references for" }),
			revision: Type.Optional(Type.String({ description: "Branch or commit (default: HEAD)" })),
		}),
		async execute(_id, params, signal) {
			// Use search as a practical approach — search for the symbol in the repo
			const query = `repo:${params.repo} ${params.symbol} type:file count:50`;
			const content = await sgGraphQL(pi, SEARCH_QUERY, { query }, signal);
			return {
				content: [{ type: "text", text: content }],
				details: { repo: params.repo, symbol: params.symbol },
			};
		},
	});

	// sg_go_to_definition — find symbol definition
	pi.registerTool({
		name: "sg_go_to_definition",
		label: "Sourcegraph Go to Definition",
		description: "Find the definition of a symbol (function, class, variable) in a repository.",
		parameters: Type.Object({
			repo: Type.String({ description: "Repository name" }),
			path: Type.String({ description: "File path containing the symbol reference" }),
			symbol: Type.String({ description: "Symbol name to find the definition for" }),
			revision: Type.Optional(Type.String({ description: "Branch or commit (default: HEAD)" })),
		}),
		async execute(_id, params, signal) {
			// Search for definition patterns (function/class/const/export declarations)
			const defPatterns = [
				`function ${params.symbol}`,
				`class ${params.symbol}`,
				`const ${params.symbol}`,
				`def ${params.symbol}`,
				`interface ${params.symbol}`,
				`type ${params.symbol}`,
			];
			const query = `repo:${params.repo} (${defPatterns.join(" OR ")}) type:file count:20`;
			const content = await sgGraphQL(pi, SEARCH_QUERY, { query }, signal);
			return {
				content: [{ type: "text", text: content }],
				details: { repo: params.repo, symbol: params.symbol },
			};
		},
	});

	// sg_compare_revisions — diff between two revisions
	pi.registerTool({
		name: "sg_compare_revisions",
		label: "Sourcegraph Compare Revisions",
		description: "Compare changes between two revisions (branches, tags, commits) in a repository.",
		parameters: Type.Object({
			repo: Type.String({ description: "Repository name" }),
			base: Type.String({ description: "Base revision (older, e.g., 'main~5' or commit hash)" }),
			head: Type.String({ description: "Head revision (newer, e.g., 'main' or commit hash)" }),
			first: Type.Optional(Type.Number({ description: "Max file diffs to return (default: 50)" })),
		}),
		async execute(_id, params, signal) {
			const content = await sgGraphQL(
				pi,
				COMPARE_QUERY,
				{ repo: params.repo, base: params.base, head: params.head, first: params.first || 50 },
				signal,
			);
			return {
				content: [{ type: "text", text: content }],
				details: { repo: params.repo, base: params.base, head: params.head },
			};
		},
	});

	// sg_get_contributor_repos — find repos a person contributes to
	pi.registerTool({
		name: "sg_get_contributor_repos",
		label: "Sourcegraph Contributor Repos",
		description: "Find repositories where one or more contributors have made commits.",
		parameters: Type.Object({
			authors: Type.Array(Type.String(), { description: "Author names or emails to search (max 5)" }),
			limit: Type.Optional(Type.Number({ description: "Max repos to return (default: 20)" })),
		}),
		async execute(_id, params, signal) {
			// Search for commits by these authors across all repos
			const authorFilters = params.authors.map((a) => `author:${a}`).join(" ");
			const query = `type:commit ${authorFilters} count:${params.limit || 20}`;
			const content = await sgGraphQL(pi, SEARCH_QUERY, { query }, signal);
			return {
				content: [{ type: "text", text: content }],
				details: { authors: params.authors },
			};
		},
	});
}
