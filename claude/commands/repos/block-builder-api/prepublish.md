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
5a. **Match or create sf-ui-web branch** - Find matching PGL ticket branch or create from main
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

### 5a. Match or Create sf-ui-web Branch

After determining the block-builder-api branch name, ensure sf-ui-web has a matching branch:

1. **Extract PGL ticket from branch name:**
```bash
# Example: ccho_hfc_ui_gem_content_ph_PGL-947 → PGL-947
ticket=$(echo "<branch-name>" | grep -o 'PGL-[0-9]\+')
```

2. **Check if matching branch exists in sf-ui-web:**
```bash
cd ~/codebase/sf-ui-web
git fetch origin
git branch -r | grep "origin/.*${ticket}" || echo "No matching branch"
```

3. **Handle uncommitted changes:**
   - Check for uncommitted changes: `git status --short`
   - If changes exist:
     ```bash
     git stash push -m "Prepublish: temp stash for branch switch to ${ticket}"
     ```
   - **Store stash info** (stash message, files, timestamp) for display in final summary

4. **If matching branch found:**
   - Display: "Found matching branch in sf-ui-web: <branch-name>"
   - Checkout the branch:
     ```bash
     cd ~/codebase/sf-ui-web
     git checkout <matching-branch>
     git pull origin <matching-branch>
     ```

5. **If NO matching branch found:**
   - Display: "No matching branch found in sf-ui-web with ticket ${ticket}"
   - Display: "Creating new branch from main..."
   - Create branch from latest main:
     ```bash
     cd ~/codebase/sf-ui-web
     git checkout main
     git pull origin main
     git checkout -b <branch-name>
     ```
   - Display: "✓ Created branch '<branch-name>' in sf-ui-web"

6. **Verify working directory:**
   - Ensure you're on the correct branch before running codegen
   - Display current branch: `git branch --show-current`

**Error Handling:**
- If git fetch fails: Check VPN connection, retry once
- If multiple matching branches found: Display list and ask user to select
- If branch creation fails: Display error and exit

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

**Delegate to buildkite-watch command for monitoring.**

Use the Skill tool to invoke the global buildkite-watch command:

```
Skill tool invocation:
- skill: "buildkite-watch"
- args: "" (auto-detect PR and context)
```

**What buildkite-watch does:**
- Auto-detects PR number from current branch
- Auto-detects context as "buildkite/block-builder-api"
- Monitors build with live progress bar (35 minute timeout)
- Sends desktop notifications every 5 minutes
- Displays timestamps and build URL on completion
- Handles MCP detection and strategy selection automatically

**Handle build results based on exit codes:**

**Exit 0 (SUCCESS):**
```
✓ Build completed successfully
```
→ Proceed to step 8 (feature variant verification)

**Exit 1 (FAILURE):**
```
✗ Build failed
```
Ask user to continue or exit:
```
Build failed. GraphQL validation may have completed anyway.
Continue to feature variant check? (y/n)
```
- If `y`: Proceed to step 8 (validation job may have succeeded even if other jobs failed)
- If `n`: Exit with build URL for manual inspection

**Exit 2 (TIMEOUT):**
```
⏱️  Build exceeded 35 minutes
```
Ask user what to do:
```
Build exceeded timeout. Options:
1. wait   - Continue waiting (extend timeout by 20 minutes)
2. skip   - Proceed to variant check (may fail if not ready)
3. exit   - Stop and inspect manually

Choice (wait/skip/exit):
```
- If `wait`: Re-invoke buildkite-watch with extended timeout: `--timeout 55`
- If `skip`: Proceed to step 8 (may fail if feature variant not ready)
- If `exit`: Exit cleanly with build URL

**Exit 3 (NO BUILD):**
```
⚠️  No Buildkite build found
```
This usually means no GraphQL schema files changed. Ask:
```
No Buildkite build detected. This may mean:
- No schema/code changes that trigger builds
- PR created before build started

Continue anyway? Feature variant may not exist. (y/n)
```
- If `y`: Proceed to step 8 (will likely fail at variant check)
- If `n`: Exit

**Fallback (if buildkite-watch unavailable):**

If Skill tool fails or buildkite-watch doesn't exist, use direct gh CLI:

```bash
cd ~/codebase/block-builder-api
gh pr view --json statusCheckRollup \
  --jq '.statusCheckRollup[] | select(.context == "buildkite/block-builder-api") | {state: .state, targetUrl: .targetUrl}'
```

Parse result and handle states manually (PENDING/SUCCESS/FAILURE).

**Why delegation approach:**
- Eliminates ~130 lines of duplicate monitoring logic
- Consistent UX across all Buildkite monitoring (progress bars, notifications, timestamps)
- Single source of truth for monitoring improvements
- buildkite-watch handles MCP detection and strategy selection automatically
- Prepublish focuses on workflow orchestration, not polling mechanics

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

Branch (block-builder-api): <branch-name>
Branch (sf-ui-web): <sf-ui-web-branch-name>
PR: <pr-url>
Build: <buildkite-url>

Changed files:
<git status output>

[If stash was created:]
⚠️  Stashed changes from previous branch:

    Stash: <stash-message>
    Files: <list of stashed files>

    To recover these changes:
    cd ~/codebase/sf-ui-web
    git stash list    # View all stashes
    git stash pop     # Apply and remove latest stash
    # or
    git stash apply   # Apply without removing stash

Next steps:
- Start dev server: dev start (or yarn dev in apps/core-funnel)
- Set cookie for runtime testing:
  document.cookie = "gql-feature-variant=<branch-name>; path=/; max-age=259200"
- Test schema changes in browser

⚠️  BEFORE CREATING PR IN sf-ui-web:

    yarn gql:codegen

This resets to production schema. Feature variant schemas CANNOT be merged to main.

Or use: /prepublish --reset

────────────────────────────────────────────────────────────────

Note: /prepublish does NOT automatically create PRs.
      Use /pr-create when ready to create PR in sf-ui-web.
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
