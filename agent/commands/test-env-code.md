---
description: Set up code test environment (dependencies, compilation, build artifacts)
---
Set up the code test environment (dependencies, compilation, build artifacts).

Covers everything needed to run unit and integration tests locally. Does NOT start services, SSH tunnels, or browsers.

Steps:

1. Check for repo-specific command:
   ```bash
   REPO_NAME=$(basename $(git rev-parse --show-toplevel 2>/dev/null))

   if [[ -f "~/dotfiles/claude/commands/repos/${REPO_NAME}/test-env-code.md" ]]; then
     Skill(skill="repos:${REPO_NAME}:test-env-code")
     exit 0
   fi
   ```

2. Spawn Explore agent to research code environment requirements:
   - package.json scripts (install, build, codegen, pretest)
   - Makefile targets (install, build, compile)
   - Requirements files (requirements.txt, Gemfile, pom.xml, build.gradle)
   - .env.example / .env.test for required env vars
   - Returns: install command, build steps, required env vars

3. Present findings and offer options via AskUserQuestion:
   "Set up code test environment for ${REPO_NAME}?"
   Options:
     - Yes, run now - Execute setup based on findings
     - Create command - Spawn Plan agent to write repos/${REPO_NAME}/test-env-code.md
     - No - Exit

What this does:
- Installs dependencies
- Compiles source / builds artifacts needed by tests
- Copies env vars from example files if needed
- Does NOT start any services or external connections
