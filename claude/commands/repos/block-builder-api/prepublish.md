---
id: repos:block-builder-api:prepublish
name: prepublish
description: Automate testing block-builder-api GraphQL schema changes in sf-ui-web
scope: repo
repo_pattern: "**/block-builder-api"
---

# block-builder-api Prepublish Skill

Automates testing GraphQL schema changes in sf-ui-web by checking Buildkite status and running feature variant codegen.

## Workflow

You are automating the block-builder-api schema testing workflow:

1. **Parse arguments** - Check for flags (--dry-run, --reset) and branch name
2. **Handle reset mode** - Clean up feature variant if requested
3. **Verify branch** - Ensure not running from main/master
4. **Validate repos** - Check block-builder-api and sf-ui-web exist
5. **Determine branch** - Get branch name from args, git, or user input
6. **Verify PR** - Ensure PR exists in block-builder-api
7. **Check Buildkite** - Monitor build status via GitHub checks
8. **Verify feature variant** - Ensure schema variant is available
9. **Run codegen** - Execute `yarn gql:codegen:feature <branch>`
10. **Integrate dev commands** - Offer to build/start dev server
11. **Display summary** - Show next steps and reminders

## Step-by-Step Implementation

### 1. Parse Command Arguments

Check for flags and extract branch name:

```bash
--dry-run: Show commands without executing
--reset: Run cleanup mode (yarn gql:codegen in sf-ui-web)
<branch-name>: Use specified branch (otherwise auto-detect)
```

### 2. Handle Reset Mode

If `--reset` flag present:

```bash
cd ~/codebase/sf-ui-web
yarn gql:codegen
```

Display: "✓ Schema reset to production. Safe to create PR."
Exit successfully.

### 3. Verify on Feature Branch

Check current branch in block-builder-api:

```bash
cd ~/codebase/block-builder-api
git branch --show-current
```

If on main or master:
- Display error: "Cannot run prepublish from main branch. Create a feature branch first."
- Exit with error code

### 4. Validate Repository Locations

Check both repos exist:

```bash
test -d ~/codebase/block-builder-api || echo "ERROR: block-builder-api not found"
test -d ~/codebase/sf-ui-web || echo "ERROR: sf-ui-web not found"
```

If either missing:
- Error: "Required repositories not found at ~/codebase/"
- Show expected paths
- Exit

### 5. Determine Branch Name

Priority order:

a. **If provided as argument:** Use that value

b. **If in block-builder-api directory:**
```bash
cd ~/codebase/block-builder-api
git branch --show-current
```

c. **If in sf-ui-web or other directory:** Ask user for block-builder-api branch name

d. **Store branch name** for all subsequent steps

### 6. Verify PR Exists

Check PR exists in block-builder-api:

```bash
cd ~/codebase/block-builder-api
gh pr view <branch-name> --json number,url,headRefName,state
```

Parse JSON response:
- Extract `number`, `url`, `state`
- If error or no PR: Display "No PR found for branch '<branch-name>'. Create PR first."
- If PR state is "MERGED" or "CLOSED": Warn and ask to continue
- Store PR number and URL for later display

### 7. Check Buildkite Build Status

**Before starting: Check MCP availability**

Detect if running in an MCP-enabled session:
- Check Claude's available tools for `mcp__buildkite__*` or `mcp__github__*`
- If not available, you're running in a non-MCP session (`claude` command)
- If available, you're running with MCP (`claude-mcp` command or specific config)

**If MCP tools NOT available:**

Display informational message with copy-pastable instructions:
```
ℹ️  MCP servers not detected in current session.

For best results, this skill works best with MCP servers enabled.
MCP provides more reliable build and schema monitoring via:
  • buildkite       (Build status and job logs)
  • github_wayfair  (PR and check monitoring)

Continuing with CLI fallbacks (Scout → gh CLI).

────────────────────────────────────────────────────────────────
To use MCP servers next time, exit this session and run:

  claude-mcp --servers "buildkite,github_wayfair" /prepublish

This starts Claude with MCP and runs the prepublish skill immediately.
────────────────────────────────────────────────────────────────
```

**Do NOT attempt to run `claude-mcp` from within Claude:**
- `claude-mcp` is a shell function, not available inside Claude sessions
- User must exit and restart with `claude-mcp --servers` manually

**Automatic fallback:**
- If MCP not available, continue automatically with CLI strategies
- No user prompt needed - inform and proceed
- Scout CLI and gh CLI are reliable fallbacks

**MCP server configuration:**
Your MCP servers are defined in `~/dotfiles/claude/mcp-servers.json`:
- `buildkite` - Buildkite API access (BEST for build monitoring)
- `github_wayfair` - Wayfair GitHub instance (BEST for PR monitoring)
- `github` - Public GitHub (alternative)

**Strategy Priority (Sequential - Try in Order):**

**1. Buildkite MCP** (BEST - Direct build access)

Check if `mcp__buildkite__*` tools available in Claude's tool list:
- If available:
  * Get build for branch: `mcp__buildkite__get_build`
  * List build jobs: `mcp__buildkite__list_jobs`
  * Monitor job status in real-time
  * Check for GraphQL validation completion
  * **If build status found:** Use it and proceed
- If not available: Skip to strategy 2

**Pros:** Most reliable, direct access, detailed job info

**2. GitHub MCP** (BEST for PR checks)

Check if `mcp__github__*` tools available in Claude's tool list:
- If available:
  * Get PR checks: `mcp__github__get_pr_checks`
  * Monitor check status: `mcp__github__get_check_run`
  * **If check status found:** Use it and proceed
- If not available: Skip to strategy 3

**Pros:** Real-time, reliable, no rate limits

**3. Scout CLI** (Good if installed)

Check if scout is installed:
```bash
command -v scout >/dev/null 2>&1
```

If available:
```bash
scout check <pr-url> --once --format json
```

Parse JSON output for build status
**If status found:** Use it and proceed

**Pros:** Rich metadata, unified view

**4. GitHub Status Checks API via gh CLI** (Fallback)

```bash
cd ~/codebase/block-builder-api
gh pr view <branch-name> --json statusCheckRollup \
  --jq '.statusCheckRollup[] | select(.context == "buildkite/block-builder-api") | {state: .state, targetUrl: .targetUrl}'
```

Parse JSON result:
- `state: "PENDING"` → Build in progress
- `state: "SUCCESS"` → Build complete
- `state: "FAILURE"` → Build failed
- Empty/no result → No build triggered
- Extract `targetUrl` for Buildkite build URL

**Pros:** Widely available

**Display build information:**
```
PR: <pr-url>
Buildkite: <build-url>
Status: <state>
```

**Implementation Flow:**

```
Try Strategy 1 (Buildkite MCP)
  → Status found? YES: Use it, continue to step 8
  → Available? NO: Try Strategy 2

Try Strategy 2 (GitHub MCP)
  → Status found? YES: Use it, continue to step 8
  → Available? NO: Try Strategy 3

Try Strategy 3 (Scout CLI)
  → Available? NO: Try Strategy 4
  → Available? YES: Run it, use status, continue to step 8

Try Strategy 4 (gh CLI)
  → Get build status and URL
  → Continue to step 8
```

**Handle build status with polling:**

**Polling configuration:**
- Poll interval: 1 minute
- Max wait: 35 minutes (35 attempts)
- On each poll, try strategies sequentially in priority order:
  1. Buildkite MCP (if available)
  2. GitHub MCP (if available)
  3. Scout CLI (if installed)
  4. gh CLI (fallback)
- Stop immediately when build status changes
- Progress indicator: "Waiting for Buildkite... (attempt X/35)"

**Notification strategy:**
- Every 5 minutes: Send notification "Still waiting for Buildkite..."
- Use terminal-notifier on macOS:
  ```bash
  terminal-notifier -title "block-builder-api prepublish" \
    -message "Still waiting for Buildkite build (X/35)" \
    -sound default
  ```

**If PENDING:**
- Display: "Buildkite build in progress. Waiting for GraphQL validation..."
- Continue polling
- When status changes to SUCCESS or FAILURE, proceed

**If SUCCESS:**
- Display: "✓ Buildkite build completed successfully"
- Proceed to feature variant verification

**If FAILURE:**
- Display: "✗ Buildkite build failed"
- Show build URL
- Ask: "Build failed but GraphQL validation may have completed. Continue? (y/n)"
- If no: Exit with build URL
- If yes: Proceed to feature variant verification

**If NO BUILD:**
- Display: "⚠️  No Buildkite build found. This usually means no GraphQL schema files changed."
- Ask: "Continue anyway? Feature variant may not exist. (y/n)"
- If no: Exit
- If yes: Proceed (will likely fail)

**Timeout (35 minutes):**
- Ask: "Build exceeded 35 minutes. Continue waiting or skip? (continue/skip)"
- If continue: Reset polling for another 20 minutes
- If skip: Proceed to feature variant check (may fail)

### 8. Verify Feature Variant Exists

**Three-Phase Polling Strategy:**

**Phase 1: Fast Polling (First 10 Minutes)**

Check if feature variant is available:

```bash
cd ~/codebase/sf-ui-web
yarn wgql schema introspect -f <branch-name> --json-file /tmp/schema-test-verify.json 2>&1
```

- Poll interval: 1 minute
- Duration: 10 attempts (10 minutes)
- Progress indicator: "Waiting for feature variant '<branch-name>'... (attempt X/10)"
- Notification at 5 minutes

**Success (exit code 0):**
- Display: "✓ Feature variant '<branch-name>' found"
- Stop polling, proceed to codegen

**Error containing "variant not found" or "404":**
- Continue polling
- If 10 attempts exhausted → Proceed to Phase 2

**Other errors:**
- Display full error output
- Ask: "Introspection error. Continue polling? (y/n)"
- If no: Exit

**Phase 2: Medium Polling (Next 25 Minutes)**

If variant still not found after Phase 1:

- Display: "⚠️  Variant not found after 10 minutes. Continuing with slower polling..."
- Poll interval: 5 minutes
- Duration: 5 attempts (25 minutes)
- Total elapsed: 35 minutes
- Progress indicator: "Waiting for feature variant... (attempt X/5, total 35min)"
- Notification on every poll
- Use terminal-notifier:
  ```bash
  terminal-notifier -title "block-builder-api prepublish" \
    -message "Still waiting for feature variant (attempt X/5)" \
    -sound default
  ```

**Success:** Proceed to codegen
**Failure after 35 minutes:** Proceed to Phase 3

**Phase 3: Extended Manual Monitoring (After 35 Minutes)**

If variant still not found:

1. **Display status:**
   ```
   ⚠️  Feature variant not found after 35 minutes of polling.

   Branch: <branch-name>
   Build URL: <buildkite-url>
   Last introspection attempt: <timestamp>

   Options:
   1. Continue polling (10-min notifications, indefinite)
   2. Try codegen anyway (will likely fail)
   3. Exit and check manually
   ```

2. **If user selects "Continue polling":**
   - Switch to 10-minute poll interval
   - Send notification on every poll
   - No timeout (manual Ctrl+C to stop)
   - Display: "Polling every 10 minutes. Press Ctrl+C to stop."

3. **If user selects "Try codegen anyway":**
   - Display warning: "Codegen will likely fail without variant"
   - Proceed to codegen step (will probably error)

4. **If user selects "Exit":**
   - Display manual check commands:
     ```
     To check manually:
     cd ~/codebase/sf-ui-web
     yarn wgql schema introspect -f <branch-name>

     To resume when ready:
     /prepublish --skip-wait
     ```

**User interrupt option:**
- Display: "Press Ctrl+C at any time to stop and choose options"
- Allow user to interrupt polling at any stage

### 9. Run Codegen with Feature Variant

Execute codegen:

```bash
cd ~/codebase/sf-ui-web
yarn gql:codegen:feature <branch-name>
```

Display: "Running codegen with feature variant: <branch-name>..."

Handle result:
- **Success:** Continue to next step
- **Failure:**
  * Display error output
  * Ask: "Codegen failed. Retry? (y/n)"
  * If yes: Re-run
  * If no: Exit with error

### 10. Integrate Dev Commands

After codegen completes:

1. **Check if `dev` command exists:**
   ```bash
   command -v dev >/dev/null 2>&1
   ```

2. **Ask about building:**
   - Prompt: "Build to verify? (dev build or yarn build:dev)"
   - If yes:
     * Try `dev build` if available
     * Fallback to `yarn build:dev` in sf-ui-web
     * Display build output

3. **Ask about dev server:**
   - Prompt: "Start dev server? (dev start or yarn dev)"
   - If yes:
     * Try `dev start` if available
     * Fallback to `yarn dev` in apps/core-funnel
     * Show how to set gql-feature-variant cookie

### 11. Show Generated Changes

Display file change summary:

```bash
cd ~/codebase/sf-ui-web
git status --short -- .graphql/ tools/graphql/src/
git diff --stat -- .graphql/ tools/graphql/src/
```

### 12. Display Completion Message

Show enhanced completion message:

```
✓ Schema codegen complete

Branch: <branch-name>
PR: <pr-url>
Build: <buildkite-url>

Changed files:
<git status output>

Next steps:
- Start dev server: dev start (or yarn dev in apps/core-funnel)
- Set cookie for runtime testing:
  document.cookie = "gql-feature-variant=<branch-name>; path=/; max-age=259200"
- Test schema changes in browser

⚠️  BEFORE CREATING PR IN sf-ui-web:

    yarn gql:codegen

This resets to production schema. Feature variant schemas CANNOT be merged to main.

Or use: /prepublish --reset
```

## Error Handling

**Repository not found:**
- "ERROR: Required repositories not found. Expected at ~/codebase/block-builder-api and ~/codebase/sf-ui-web"

**gh CLI not authenticated:**
- "ERROR: GitHub CLI not authenticated. Run: gh auth login"

**Network errors:**
- "ERROR: Network request failed. Check VPN connection."

**Buildkite timeout:**
- "Buildkite build exceeded 10 minute timeout. Check build manually: <url>"

**Yarn errors:**
- Display full output
- Ask to retry or exit

**Git errors:**
- Display error
- Suggest checking branch name

**Running from main branch:**
- "Cannot run prepublish from main branch. Create a feature branch first."
- Exit with error code

## Flags

**--dry-run:**
- Show all commands that would be executed
- Display decision points (polling, retries, user prompts)
- Don't execute any commands
- Exit with summary

**--reset:**
- Run cleanup mode (`yarn gql:codegen` in sf-ui-web)
- Resets to production schema
- Safe to create PR after reset
- Exit after cleanup

**--skip-wait:**
- Skip Buildkite monitoring and feature variant polling
- Proceed directly to codegen
- Useful for resuming after manual verification
- Assumes variant is ready

## Usage Examples

```bash
# From block-builder-api directory with schema changes
/prepublish

# Dry-run mode
/prepublish --dry-run

# Reset to production schema in sf-ui-web
/prepublish --reset

# Specify branch name explicitly
/prepublish <branch-name>

# Skip waiting and proceed directly to codegen
/prepublish --skip-wait

# Combine flags
/prepublish <branch-name> --skip-wait
```

## Implementation Notes

**Core tools:**
- Use `gh` CLI for GitHub operations (fallback)
- Use `yarn wgql` for GraphQL introspection and codegen
- Use `scout` CLI if available for enhanced build monitoring

**MCP integration (PRIMARY method):**
- Skill detects if running in MCP-enabled session
- Informs user about MCP benefits and provides copy-pastable command
- Uses existing MCP server config from `~/dotfiles/claude/mcp-servers.json`
- **Buildkite MCP (BEST):**
  * Get build for branch
  * List jobs and check logs
  * Monitor GraphQL validation job status
  * Most reliable source for build information
- **GitHub MCP (BEST for status):**
  * Get PR checks in real-time via `github_wayfair` server
  * Monitor check run status
  * No rate limits, faster than gh CLI
- Fallback to CLI methods if user chooses to continue without MCP

**Non-interactive MCP usage:**
```bash
# Start Claude with specific servers (no fzf)
claude-mcp --servers "buildkite,github_wayfair"

# Start with servers and run skill immediately
claude-mcp --servers "buildkite,github_wayfair" /prepublish
```

**Strategy execution (SEQUENTIAL - not parallel):**
- Try each strategy in priority order
- Stop at first successful result
- MCP tools preferred over CLI tools

**Polling strategy:**
- Initial poll interval: 1 minute (feature variant can take time to propagate)
- Max wait: 35 minutes (realistically matches CI/CD times)
- Notifications every 5 minutes to keep user informed
- User can interrupt at any time (Ctrl+C)

**Build command detection:**
1. Check if `dev` command exists
2. Parse sf-ui-web/CLAUDE.md for repo-specific commands
3. Use hardcoded fallbacks (yarn dev, yarn build:dev)

**Error handling:**
- Validate all file paths exist before reading
- Always check command existence before running (command -v)
- Retry introspection failures (network can be flaky)
- Provide manual continuation option if automation fails
- Never fail silently - always show error and offer alternatives
