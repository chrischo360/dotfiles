# Scout

Browser automation CLI for GitHub and Buildkite monitoring.

Location: `~/codebase/scout`

## Setup

```bash
scout setup   # One-time authentication
```

Config stored in `~/.scout/`:
- `config.json` - Polling intervals, notifications, auto-approve settings
- `github-auth.json` - Browser auth state (gitignored)

## GitHub Commands

```bash
scout watch-builds https://github.com/owner/repo/pull/123   # Monitor PR CI
scout auto-approve wayfair-shared/sf-ui-web                 # Auto-approve Dependabot PRs
scout pr-dashboard wayfair-shared/sf-ui-web                 # PR dashboard
scout review-queue wayfair-shared/sf-ui-web                 # PRs needing review
```

## Wayfair Commands

```bash
scout buildkite-watch https://buildkite.com/wayfair/sf-ui-web-dev/builds/12345
```
