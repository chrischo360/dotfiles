---
id: repos:sf-js-libraries:prepublish
name: prepublish
description: Automate testing pre-published libraries in consuming repos
scope: repo
repo_pattern: "**/sf-js-libraries"
---

# sf-js-libraries Prepublish Skill

Automates the workflow for testing pre-published libraries in consuming repos (sf-ui-web, sf-ui-checkout, sf-ui-cart-and-checkout).

## Workflow

You are automating the sf-js-libraries pre-release testing workflow:

1. **Verify on feature branch** - Ensure not running from main/master
2. **Detect library** - Determine which library changed using git diff
3. **Validate state** - Check formatting, version bump, changelog
4. **Create/verify PR** - Ensure PR exists for Buildkite to run
5. **Monitor Buildkite** - Wait for pre-release publish step
6. **Prompt for test location** - Ask where to test (sf-ui-web, sf-ui-checkout, etc.)
7. **Update consuming repo** - Install pre-release version
8. **Run build commands** - Build consuming repo with new version
9. **Display summary** - Show next steps

## Step-by-Step Implementation

### 1. Verify on Feature Branch

Check current branch:
```bash
git branch --show-current
```

If on main or master:
- Display error: "Cannot run prepublish from main branch. Create a feature branch first."
- Exit with error code

### 2. Detect Changed Libraries

Find all package.json files with version changes:

```bash
cd ~/codebase/sf-js-libraries
git diff main...HEAD --name-only | grep 'package.json$' | grep -v '^package.json$' | grep -v node_modules
```

For each package.json found:
1. Extract directory path (e.g., `packages/sf-pricing/sf-pricing/`)
2. Read package.json to get library name and version:
   ```bash
   cat <package-path>/package.json | jq -r '.name, .version'
   ```

Store results as:
- Library name: `@wayfair/sf-pricing`
- Library version: `10.2.0`
- Package directory: `packages/sf-pricing/sf-pricing/`

**If multiple packages changed:**
- Display list with names and versions
- Ask user: "Multiple libraries changed. Which one to test?"
  ```
  1. @wayfair/sf-pricing (10.2.0)
  2. @wayfair/sf-loyalty-enrollment (5.1.3)
  ```
- Allow selection by number or name

**If no packages changed:**
- Error: "No package.json changes detected. Version must be bumped first."
- Offer to auto-bump: "Auto-bump patch version? (y/n)"

### 3. Validate Library State

**Check formatting:**
```bash
cd <package-directory>
yarn format:check
```

If formatting issues detected:
- Run `yarn format` automatically
- Notify user: "Auto-formatting code..."

**Check version bump:**
```bash
git diff main...HEAD -- package.json | grep '"version"'
```

If no version bump detected:
- Auto-bump patch version: `npm version patch --no-git-tag-version`
- Notify user: "Auto-bumping patch version to X.Y.Z"

**Check changelog:**
```bash
git diff main...HEAD -- CHANGELOG.md
```

If no changelog update:
- Auto-generate from commits:
  ```bash
  git log main..HEAD --oneline --pretty=format:"- %s" > /tmp/changelog-entry.txt
  ```
- Read current version from package.json
- Prepend to CHANGELOG.md with format:
  ```
  ## [X.Y.Z] - YYYY-MM-DD

  <commits from /tmp/changelog-entry.txt>
  ```
- Notify user: "Auto-generated changelog entry"

### 4. Create/Verify PR Exists

Check if PR exists for current branch:
```bash
gh pr view --json number,url,headRefName
```

If no PR exists:
- Use existing `global:pr-template` skill to generate PR description
- Create PR: `gh pr create --title "<title>" --body "<body>"`
- Display PR URL

If PR exists:
- Extract PR number and URL
- Display: "Using existing PR #<number>"

### 5. Monitor Buildkite for Pre-Release Publish

**Two-Phase Approach:**
- **Phase 1:** Monitor build completion (delegate to buildkite-watch)
- **Phase 2:** Extract pre-release version from build (library-specific logic)

---

#### Phase 1: Build Status Monitoring

**Delegate to buildkite-watch command.**

Use the Skill tool to invoke the global buildkite-watch command:

```
Skill tool invocation:
- skill: "buildkite-watch"
- args: "--timeout 15" (libraries build faster than backend services)
```

**What buildkite-watch does:**
- Auto-detects PR number from current branch
- Auto-detects context as "buildkite/sf-js-libraries"
- Monitors build with live progress bar (15 minute timeout)
- Sends desktop notifications every 5 minutes
- Handles MCP detection and strategy selection automatically

**Handle build completion:**

**Exit 0 (SUCCESS):**
```
✓ Build completed successfully
```
→ Proceed to Phase 2 (version extraction)

**Exit 1 (FAILURE):**
```
✗ Build failed
```
Ask user to continue:
```
Build failed. Pre-release publish job may have succeeded even if other jobs failed.
Continue to version extraction? (y/n)
```
- If `y`: Proceed to Phase 2 (publish job might have completed)
- If `n`: Exit with build URL for manual inspection

**Exit 2 (TIMEOUT):**
```
⏱️  Build exceeded 15 minutes
```
Proceed to Phase 2 anyway - pre-release publish typically completes in 5-10 minutes, so version may already be available.

**Exit 3 (NO BUILD):**
```
⚠️  No Buildkite build found
```
Warn user:
```
No build triggered. This may mean:
- No package.json changes
- PR not created yet

Continue to version extraction anyway? (y/n)
```
- If `y`: Proceed to Phase 2 (will likely fail)
- If `n`: Exit

---

#### Phase 2: Extract Pre-Release Version

**Version extraction is library-specific and requires checking build job logs.**

Try multiple strategies to extract the published pre-release version.

**Strategy Priority (Sequential - Try in Order):**

**1. Buildkite MCP** (BEST - Direct access to job logs)

Check if `mcp__buildkite__*` tools available:
- Get build for branch: `mcp__buildkite__get_build`
- List build jobs: `mcp__buildkite__list_jobs`
- Find "Publish Pre-Release" job
- Check job logs for published version pattern: `\d+\.\d+\.\d+-[a-f0-9]+`
- **If version found:** Use it immediately and proceed to step 6

**2. GitHub MCP** (For build metadata)

Check if `mcp__github__*` tools available:
- Get PR checks: `mcp__github__get_pr_checks`
- May not include version directly but can confirm build completion

**3. Scout CLI** (If installed)

```bash
scout check <pr-url> --once --format json
```
- Parse for version information in build metadata
- **If version found:** Use it and proceed to step 6

**4. gh CLI + Buildkite URL** (Manual extraction fallback)

```bash
gh pr view <branch> --json statusCheckRollup \
  --jq '.statusCheckRollup[] | select(.context == "buildkite/sf-js-libraries") | .targetUrl'
```
- Display Buildkite URL to user
- Ask user to check build logs manually and provide version

**Initial attempt:**

Try all strategies once. If version found, proceed to step 6.

**Polling Loop (If Version Not Found)**

If initial pass finds build status but not version, or build is still pending:

**Polling configuration:**
- Poll interval: 1 minute
- Max automated polling: 15 minutes (15 attempts)
- On each poll, try strategies sequentially in priority order:
  1. **Buildkite MCP** (if available) - Check job logs for version
  2. **GitHub MCP** (if available) - Monitor check status
  3. **Scout CLI** (if installed) - Unified build status
  4. **gh CLI** - Fallback status checks
- Stop immediately when version found
- Progress indicator: "Waiting for pre-release publish... (attempt X/15)"
- Display Buildkite URL on each poll

**Notification strategy:**
- Every 5 minutes: Send notification
  ```bash
  terminal-notifier -title "sf-js-libraries prepublish" \
    -message "Still waiting for pre-release publish (X/15)" \
    -sound default
  ```

**Phase 3: Extended Manual Monitoring (After 15 Minutes)**

If automated strategies haven't found the version after 15 minutes:

1. **Display status:**
   ```
   ⚠️  Pre-release version not found after 15 minutes of automated polling.

   Build URL: <buildkite-url>
   Last known state: <SUCCESS/PENDING/FAILURE>

   Options:
   1. Continue automated polling (5-min notifications, indefinite)
   2. Enter version manually
   3. Exit
   ```

2. **If user selects "Continue automated polling":**
   - Switch to 5-minute poll interval
   - Send notification on every poll
   - No timeout (manual Ctrl+C to stop)
   - Display: "Polling every 5 minutes. Press Ctrl+C to stop and enter manually."

3. **If user selects "Enter manually":**
   - Prompt: "Enter pre-release version (e.g., 10.2.0-abc1234):"
   - Validate format: `^\d+\.\d+\.\d+-[a-f0-9]+$`
   - Proceed with provided version

4. **If user selects "Exit":**
   - Display manual commands:
     ```
     To check manually:
     gh release list --repo wayfair/sf-js-libraries --limit 20

     To resume when ready:
     /prepublish --version <version>
     ```

**Why this approach:**
- **Fast path:** Concurrent checks (0-30 seconds) for immediate results
- **Medium path:** 1-minute polling (up to 15 minutes) for normal CI times
- **Slow path:** 5-minute notifications (indefinite) for abnormal delays
- **Always available:** Manual override at any stage

### 6. Prompt for Test Location

Always prompt user to select where to test:

```
Where would you like to test @wayfair/sf-pricing@10.2.0-abc1234?

[ ] sf-ui-web
[ ] sf-ui-checkout
[ ] sf-ui-cart-and-checkout
[ ] Other (specify path)
```

Allow multiple selections.

If "Other" selected:
- Prompt for absolute path: "Enter repo path:"
- Validate path exists and has package.json

### 7. Update Consuming Repo(s)

For each selected repo:

1. **Navigate to repo directory:**
   ```bash
   cd ~/codebase/<repo-name>
   ```

2. **Update package.json with pre-release version:**
   ```bash
   yarn upgrade <library-name>@<pre-release-version>
   ```

   Example: `yarn upgrade @wayfair/sf-pricing@10.2.0-abc1234`

3. **Verify it appears in yarn.lock:**
   ```bash
   grep '<library-name>@<pre-release-version>' yarn.lock
   ```

4. **Display:** "✓ Updated <repo-name> to <library-name>@<pre-release-version>"

### 8. Run Build/Dev Commands

For each updated repo:

1. **Check if `dev` command exists:**
   ```bash
   command -v dev >/dev/null 2>&1
   ```

2. **If `dev` exists:**
   - Run: `dev build`
   - Display output

3. **If `dev` doesn't exist, check CLAUDE.md:**
   - Read: `/Users/cc446g/codebase/<repo-name>/CLAUDE.md`
   - Parse for "Build:" or "build" command patterns
   - Extract repo-specific build command (e.g., `yarn lib:build`, `yarn build:dev`)

4. **Fallback commands if CLAUDE.md doesn't exist:**
   - sf-ui-web: `yarn lib:build && yarn build:dev`
   - sf-ui-checkout: `yarn build`
   - sf-ui-cart-and-checkout: `yarn build:dev`

5. **After build completes:**
   - Ask: "Start dev server? (dev start or yarn dev)"
   - If yes:
     - Try `dev start` first
     - Fallback to `yarn dev`

### 9. Display Summary

Show completion message:

```
✓ Pre-release testing ready

Library: <library-name>@<pre-release-version>
PR: <pr-url>
Build: <buildkite-url>

Updated in:
- ~/codebase/<repo-name-1>
- ~/codebase/<repo-name-2>

Next steps:
- Test functionality in dev environment
- When ready to merge: Merge PR to publish stable version
- After stable publish: Update consuming repos to stable version

⚠️  REMINDER: This is a pre-release version. Do not merge to main in consuming repos.
```

## Error Handling

**Repository not found:**
- List available repos in ~/codebase
- Ask: "Repo not found. Enter path manually:"

**No version bump detected:**
- Auto-bump patch version
- Notify user
- Continue workflow

**Buildkite timeout:**
- Show build URL
- Ask: "Continue waiting or exit?"
- Provide manual override option

**Pre-release not published:**
- Wait longer (up to 10 minutes total)
- If still not published: Show error and build URL

**Yarn upgrade fails:**
- Display error message
- Suggest manual intervention:
  ```
  Try manually:
  cd ~/codebase/<repo-name>
  yarn upgrade <library-name>@<pre-release-version>
  ```

**Build fails:**
- Display build output
- Ask: "Build failed. Continue to next repo? (y/n)"
- Do not exit workflow

## Flags

**--dry-run:**
- Show what would happen without executing
- Display all detected values (library name, version, PR, etc.)
- Skip actual modifications

**--skip-build:**
- Skip running build commands
- Only update package.json and yarn.lock

**--repo <path>:**
- Specify test repo directly (skip prompt)
- Can be used multiple times: `--repo sf-ui-web --repo sf-ui-checkout`

**--version <version>:**
- Skip Buildkite monitoring and use provided pre-release version
- Useful for resuming after manual check or timeout
- Format: `10.2.0-abc1234` (semver with commit hash)
- Validates format before proceeding

## Usage Examples

```bash
# From sf-js-libraries directory after making changes
/prepublish

# Dry-run to see what would happen
/prepublish --dry-run

# Skip build step
/prepublish --skip-build

# Test in specific repo without prompt
/prepublish --repo sf-ui-web

# Test in multiple repos
/prepublish --repo sf-ui-web --repo sf-ui-checkout

# Resume with known version (skip Buildkite monitoring)
/prepublish --version 10.2.0-abc1234

# Combine flags
/prepublish --version 10.2.0-abc1234 --repo sf-ui-web --skip-build
```

## Implementation Notes

**Core tools:**
- Use `gh` CLI for all GitHub operations (PR creation, status checks)
- Use `yarn` for package management (not npm)
- Use `jq` for JSON parsing (library name/version from package.json)
- Use `scout` CLI if available for enhanced PR monitoring
- Poll Buildkite via GitHub status checks API (not Buildkite API directly)

**MCP integration (PRIMARY method):**
- Skill detects if running in MCP-enabled session
- Informs user about MCP benefits and provides copy-pastable command
- Uses existing MCP server config from `~/dotfiles/claude/mcp-servers.json`
- **Buildkite MCP (BEST):**
  * Get build for branch
  * List jobs and check logs
  * Extract pre-release version from job logs
  * Most reliable source for version information
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

**Version extraction priority (SEQUENTIAL - not parallel):**
1. **Buildkite MCP** - Job logs contain published version (BEST)
2. **GitHub MCP** - Real-time check status (GOOD for status)
3. **Scout CLI** - Rich metadata if installed (GOOD)
4. **GitHub Status Checks via gh CLI** - Build status only, no version (FALLBACK)
5. **Manual user input** - Always available (LAST RESORT)

**Important Notes:**
- Strategies run sequentially in priority order (not parallel)
- Stop at first successful result
- GitHub Releases API does NOT work for wayfair/sf-js-libraries (returns 404)
- MCP servers preferred over CLI tools

**Multiple package support:**
- Detect all changed package.json files via git diff
- Parse each with `jq` to extract name and version
- Present user with selection menu if multiple packages changed
- Track selected package throughout workflow

**Build command detection:**
1. Check if `dev` command exists
2. Parse CLAUDE.md in consuming repo
3. Use hardcoded fallbacks per repo

**Error handling:**
- Validate all file paths exist before reading
- Always check command existence before running (command -v)
- Provide manual override for all automated extractions
- Never fail silently - always show error and offer alternatives
