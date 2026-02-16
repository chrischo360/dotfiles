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

**Execution Strategy: Hybrid (Concurrent Check + Polling Loop)**

The implementation uses a two-phase approach:

**Phase 1: Concurrent Strategy Check (First Attempt)**

Run all available strategies in parallel and use the first successful result:

1. **GitHub Releases API** (Most reliable for version)
   ```bash
   gh release list --repo wayfair/sf-js-libraries --limit 20 --json tagName,isPrerelease,createdAt \
     --jq '.[] | select(.isPrerelease == true) | select(.tagName | contains("<library-name>")) | .tagName'
   ```
   - Parse tag: `@wayfair/sf-pricing@10.2.0-abc1234` → Extract: `10.2.0-abc1234`
   - **Pros:** Authoritative source, includes version
   - **Cons:** May lag behind build completion

2. **GitHub Status Checks API** (Most reliable for build status)
   ```bash
   gh pr view <branch> --json statusCheckRollup \
     --jq '.statusCheckRollup[] | select(.context == "buildkite/sf-js-libraries") | {state: .state, targetUrl: .targetUrl}'
   ```
   - **Pros:** Real-time build status, includes Buildkite URL
   - **Cons:** Doesn't include pre-release version

3. **Scout CLI** (If available - rich information)
   ```bash
   command -v scout >/dev/null 2>&1 && scout check <pr-url> --once --format json
   ```
   - **Pros:** Rich metadata, unified view
   - **Cons:** Requires scout installed

4. **Buildkite API Direct** (If `$BUILDKITE_TOKEN` set)
   ```bash
   curl -H "Authorization: Bearer $BUILDKITE_TOKEN" \
     "https://api.buildkite.com/v2/organizations/wayfair/pipelines/sf-js-libraries/builds?branch=<branch-name>&per_page=1" | \
     jq -r '.[0].jobs[] | select(.name | contains("Publish Pre-Release")) | .state'
   ```
   - **Pros:** Direct source, detailed job info
   - **Cons:** Requires API token, can be slow

**Implementation:**
```bash
# Run all strategies in parallel using background jobs
gh release list ... & pid1=$!
gh pr view ... & pid2=$!
scout check ... & pid3=$!
curl buildkite ... & pid4=$!

# Wait for first successful result (up to 30 seconds)
wait -n $pid1 $pid2 $pid3 $pid4
```

**Phase 2: Polling Loop (If Phase 1 Incomplete)**

If Phase 1 finds build status but not version, or version but build is still pending:

**Polling configuration:**
- Poll interval: 1 minute
- Max automated polling: 15 minutes (15 attempts)
- Strategy per poll:
  1. GitHub Releases (version) - priority 1
  2. GitHub Status Checks (build status) - priority 2
  3. Scout (if available) - priority 3
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

**GitHub MCP integration (if available):**
- Check if `mcp__github` tools are available in Claude's tool list
- If available, use MCP tools for:
  * Getting PR status and checks
  * Listing releases
  * Getting build status
- Fallback to `gh` CLI if MCP not available

**Version extraction priority:**
1. GitHub Releases API (most reliable for pre-release versions)
2. Scout CLI JSON output
3. Buildkite API
4. Manual user input

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
