---
name: harness-onboarding
description: Orient an engineer or agent to a repo that already has the AGENTS-first harness baseline, including first-pass review, task intake, shared harness commands, optional user-global skills and MCP, cross-tool synchronization, and where transient versus durable state belongs.
metadata:
  source: local://ct-agentic-sdlc-harness/harness-onboarding
---
# Harness Onboarding

Use this skill when you are starting the first session in a freshly adopted repo or when a new engineer or agent needs to re-orient to the AGENTS-first baseline.

## Entry

- If `AGENTS.md` or `.agents/` is missing, stop and bootstrap the repo first with the shared launcher or `harness bootstrap`.
- Read `AGENTS.md` first.
- Keep `.agents/policies/*` in context for the session.
- Review the generated first-pass files linked from `AGENTS.md`, especially:
  - `.agents/context/tech-stack.md`
  - `.agents/context/architecture.md`
  - the app-specific context file for the repo
- Treat `.agents/skills/*` as the canonical shared skill path. Tool-native mirrors such as `.claude/skills/*`, `.github/skills/*`, or `.junie/skills/*` are adapters only.

## Shared Harness Commands

Use the global `harness` CLI for shared runtime upkeep:

```bash
harness enrich
harness verify --strict
harness update
harness sync-adapters
harness setup-mcp --tool <cursor|claude|codex|copilot>
harness install-user-skills
```

- `harness enrich` refreshes factual managed signals plus the checklist in `.agents/context/README.md`.
- `harness verify --strict` validates the committed runtime contract before review or handoff.
- `harness update` refreshes the broader shared baseline.
- `harness sync-adapters` refreshes native command, skill, and hook adapters after canonical manifest changes.
- `harness setup-mcp` generates tool-specific MCP config from `.agents/mcps/mcp-manifest.json` (repo scope) or the harness catalog manifest (user scope with `--scope user`).
- `harness install-user-skills` installs optional user-global skills from the curated manifest (`catalogs/user-skills.manifest.json`).

## Optional User-Global Skills

The harness ships a curated manifest of audited, open-source skills that can be installed globally across all supported agents.

All curated skills default to enabled. Run `harness install-user-skills` to install them. Disable individual entries by setting `"enabled": false` in the manifest first.

Available curated skills:

| Skill | What it does |
|-------|--------------|
| harness-onboarding | First-session repo orientation after harness bootstrap |
| k8s-debug | Kubernetes pod diagnostics and failure remediation |
| agent-skills | Datadog monitoring, logging, tracing, and observability |
| fix-buildkite-ci | Buildkite CI failure triage and fixes |
| docker-expert | Docker containerization, security hardening, and multi-stage builds |
| gh-cli | GitHub CLI workflows and automation |
| gcp-development | Google Cloud Platform development |
| superpowers | Agent superpowers collection |

Installation covers Claude Code, Codex, Cursor, GitHub Copilot, and Junie in one pass. Run with `--dry-run` first to preview.

## Optional MCP Setup

If the repo defines MCP servers in `.agents/mcps/mcp-manifest.json`, generate your tool's config:

```bash
harness setup-mcp --tool cursor          # repo-scoped
harness setup-mcp --tool claude --dry-run # preview first
harness setup-mcp --scope user --tool all # user-global for all tools
```

## Cross-Tool Synchronization

The harness keeps all agents in sync automatically:

- **Repo-scoped skills**: `harness sync-adapters` creates symlink mirrors from `.agents/skills/*` into `.claude/skills/*`, `.github/skills/*`, and `.junie/skills/*`. Codex and Cursor read `.agents/skills/*` directly.
- **User-global skills**: `harness install-user-skills` installs to all agent home paths via `npx skills --agent` flags, creates the canonical `~/.agents/skills/` path, and mirrors to agents not yet supported by `npx skills` (e.g., Junie) from there.
- **After any skill change**: run `harness sync-adapters` then `harness verify --strict`.

## Task Intake Before Planning

- Resolve the source ticket, issue, PR, or incident before planning.
- Prefer repo-declared MCP access from `.agents/mcps/mcp-manifest.json` when it exists.
- Keep raw fetched notes, draft plans, risks, and verification scratch in `.wf-task/task-packet.md`.
- Move only durable constraints, verification evidence, rollout notes, and review-ready summaries into the PR description or shared review assets.

## After Material Changes

- Re-run `harness enrich` after material runtime or architecture changes.
- Re-run `harness verify --strict` before review or handoff.
- If canonical `.agents/commands/*`, `.agents/hooks/*`, or `.agents/skills/*` change, run `harness sync-adapters`.

## Guardrails

- Do not treat generated tool adapters as the authored repo contract.
- Do not put transient task notes into `.agents/context/*`.
- Use repo-native lint, test, and build commands for implementation; use `harness` for shared runtime upkeep and verification.
