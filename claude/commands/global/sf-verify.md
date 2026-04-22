---
description: Verify a feature branch change in sf-ui-web by spinning up the dev environment, navigating to the right page, screenshotting, and autonomously fixing + retrying if the change isn't visible.
---

Verify a feature branch change end-to-end: reads the current git branch, infers what changed and how to test it, runs the appropriate dev environment process, takes a screenshot, reasons about whether the change is working correctly, and if not — reads the source, makes a targeted fix, and tries again. Max 3 attempts.

Requires: `~/codebase/agent-devenv-poc` runner + `accounts.yaml` with valid credentials.

Steps:

1. Read the current branch and infer the feature under test:
   ```bash
   git branch --show-current
   git log main..HEAD --oneline
   git diff main..HEAD --name-only
   ```
   Parse the branch name for:
   - Ticket ID (e.g. `PGL-1298`)
   - Feature description from slug (e.g. `loyalty_mweb_autopop` → "loyalty mobile web auto popup")

   Also search Glean for the ticket if a PGL ID was found:
   ```
   mcp__glean_default__search("PGL-XXXX <feature slug>")
   ```

2. Based on what you've learned, decide:
   - **Which account**: `member` or `nonmember` (member for loyalty/account features, nonmember for cart/checkout)
   - **Which URL**: the specific page most likely to show the feature
   - **What to look for**: the specific UI element, modal, popup, or behavior described by the branch/ticket

   State your reasoning before running anything.

3. **BEGIN VERIFY LOOP** (max 3 iterations, tracked as attempt 1/3, 2/3, 3/3):

   **3a. Kill any existing server on port 3000:**
   ```bash
   lsof -ti :3000 | xargs kill -9 2>/dev/null; true
   ```

   **3b. Run the dev environment process in the background:**
   ```bash
   cd ~/codebase/agent-devenv-poc
   yarn run:checkout --account <account> [--url <path>] --local-prod --skip-setup &
   RUNNER_PID=$!
   ```

   **3b.5. Wait for screenshot to appear (max 60s):**
   ```bash
   for i in $(seq 1 60); do
     [ -f ~/codebase/agent-devenv-poc/<screenshot>.png ] && break
     sleep 1
   done
   ```

   **3c. Read the screenshot:**
   ```
   Read(file_path="~/codebase/agent-devenv-poc/<screenshot>.png")
   ```

   **3d. Verify. Reason about:**
   - **Visual presence**: Is the expected element/modal/popup visible?
   - **Correct behavior**: Does it match the ticket/branch description?
   - **Regressions**: Does anything look broken that shouldn't be?
   - **Console errors**: Any JS errors or failed network requests in runner output?

   **3e. Decide: PASS, FAIL, or UNCLEAR**

   - If **PASS**: open the screenshot, notify, kill the runner and server, then go to step 4:
     ```bash
     open ~/codebase/agent-devenv-poc/<screenshot>.png
     osascript -e 'display notification "✅ Verification passed" with title "sf-verify: <branch-name>"'
     kill $RUNNER_PID 2>/dev/null; true
     lsof -ti :3000 | xargs kill -9 2>/dev/null; true
     ```
   - If **UNCLEAR**: treat as FAIL for loop purposes.
   - If **FAIL** and attempts remain:
     - Read the changed source files most likely responsible:
       ```bash
       git diff main..HEAD -- <most relevant files>
       ```
     - Identify the most likely root cause (wrong condition, missing flag, incorrect selector, feature gate not enabled, wrong URL, wrong account type)
     - Make the minimal targeted fix:
       - Code fix → edit the file in `~/codebase/sf-ui-web`
       - Wrong URL/account/flag → adjust the runner command for next attempt
       - Feature gate → add the required cookie to the process YAML or runner command
     - If a code fix was made: rebuild the changed package before retrying:
       ```bash
       cd ~/codebase/sf-ui-web
       yarn turbo run build --filter=<affected-package>
       ```
     - State what you changed and why, then loop back to 3a.
   - If **FAIL** and no attempts remain: exit loop, go to step 4.

4. Output final summary:
   ```
   ## Verification: <branch-name>

   **Ticket**: PGL-XXXX
   **Feature**: <inferred description>
   **Attempts**: N/3

   ### Result: ✅ PASS / ❌ FAIL / ⚠️ UNCLEAR

   **Attempt log**:
   - Attempt 1: <what was tried> → <what was observed> → <what was changed>
   - Attempt 2: <what was tried> → <what was observed> → <what was changed>
   - Attempt 3: <what was tried> → <what was observed>

   **Final screenshot**: <filename>

   **What I checked**:
   - [ ] <criterion>: <observed result>

   **Assessment**: <1-2 sentence conclusion>

   **If still failing — suspected root cause**:
   - <specific hypothesis for human follow-up>
   ```

What this does:
- Infers feature, process, account, URL, and flags from the branch name + Glean ticket context
- Runs the dev environment and takes a screenshot
- If verification fails: reads source files, diagnoses the issue, makes a targeted fix, and retries
- Caps at 3 attempts to avoid runaway loops
- Produces a structured attempt log so you can see exactly what it tried

Options:
- Pass a ticket or description to override branch inference: `/sf-verify PGL-1298 loyalty autopop popup`
- Pass `--account <name>` to force a specific account
- Pass `--url <path>` to force a specific URL
- Pass `--max-attempts <N>` to override the default of 3

Fix strategy (in priority order):
1. **Wrong URL or account** — adjust runner command, no rebuild needed
2. **Missing cookie or feature flag** — add to runner command or process YAML
3. **Code bug in changed files** — edit source, rebuild affected package, retry
4. **Environment issue** — check `~/codebase/agent-devenv-poc/logs/server.log` for startup errors

Error handling:
- If `accounts.yaml` is missing: stop immediately, tell user to set it up
- If server fails to start: read `~/codebase/agent-devenv-poc/logs/server.log`, report the error, and stop — do not retry the server
- If screenshot is blank: note it, treat as FAIL, read `~/codebase/agent-devenv-poc/logs/server.log` to diagnose
- If a code fix introduces a build error: report the build error and stop

Related commands:
- `repos:sf-ui-web:test-env-dev` — manual dev environment without autonomous verification
- `repos:sf-ui-web:test-env-e2e-playwright` — Playwright smoke tests
- `notes:ticket-summary` — summarize a ticket's branches and PRs

Notes:
- Always kills port 3000 before each attempt to avoid EADDRINUSE errors
- Code fixes are made in `~/codebase/sf-ui-web` — the agent can read and edit source files there
- Only rebuilds when a code fix was made — URL/account/flag changes don't need a rebuild
- On PASS: screenshot is opened in Preview, macOS notification is sent, and the server is killed
- On FAIL: kill `$RUNNER_PID` and port 3000 before each retry (3a already handles port; also `kill $RUNNER_PID`); after final failure, leave browser open for manual inspection
