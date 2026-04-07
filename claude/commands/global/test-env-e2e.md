Set up the E2E test environment (services, tunnels, browsers, file sync).

Covers everything needed to run end-to-end tests: external services, SSH connections, browser drivers, and real-time sync. Assumes code environment (deps/build) is already set up.

Steps:

1. Check for repo-specific command:
   ```bash
   REPO_NAME=$(basename $(git rev-parse --show-toplevel 2>/dev/null))

   if [[ -f "~/dotfiles/claude/commands/repos/${REPO_NAME}/test-env-e2e.md" ]]; then
     Skill(skill="repos:${REPO_NAME}:test-env-e2e")
     exit 0
   fi
   ```

2. Spawn Explore agent to research E2E environment requirements:
   - docker-compose.yml for required services (postgres, redis, etc.)
   - playwright.config.ts / cypress.config.ts for browser setup
   - .env.e2e / .env.test for E2E-specific env vars
   - README / CONTRIBUTING for E2E setup instructions
   - CI configs (.github/workflows/, .buildkite/) for E2E job setup
   - Returns: required services, browsers, external connections, startup commands

3. Present findings and offer options via AskUserQuestion:
   "Set up E2E environment for ${REPO_NAME}?"
   Options:
     - Yes, run now - Execute setup based on findings
     - Create command - Spawn Plan agent to write repos/${REPO_NAME}/test-env-e2e.md
     - No - Exit

What this does:
- Starts required backing services (docker-compose, databases, etc.)
- Establishes SSH tunnels or remote connections if needed
- Installs/verifies browser drivers (Playwright, Puppeteer, Cypress)
- Starts file sync (realsync or equivalent) if needed
- Does NOT install deps or compile code (use test-env-code for that)
