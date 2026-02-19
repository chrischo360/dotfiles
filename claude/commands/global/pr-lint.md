Run minimal validation (format + lint) with intelligent adaptation.

Fast validation before running full pr-check. Automatically creates repo-specific command if needed.

Steps:

1. Check for repo-specific pr-lint command:
   ```bash
   REPO_NAME=$(basename $(git rev-parse --show-toplevel 2>/dev/null))

   # Try to find repos/${REPO_NAME}/pr-lint.md
   if [[ -f "~/dotfiles/claude/commands/repos/${REPO_NAME}/pr-lint.md" ]]; then
     # Delegate to repo-specific implementation
     Skill(skill="repos:${REPO_NAME}:pr-lint")
     exit 0
   fi
   ```

2. Detect if this is a JavaScript project:
   ```bash
   # Check for package.json
   if [[ ! -f "package.json" ]]; then
     echo "Not a JavaScript project (no package.json found)"
     echo "Skipping validation"
     exit 0
   fi
   ```

3. Offer to create repo-specific command:
   ```bash
   # Extract available scripts for context
   AVAILABLE_SCRIPTS=$(jq -r '.scripts | keys[]' package.json 2>/dev/null)

   echo "No custom pr-lint command found for ${REPO_NAME}"
   echo ""
   echo "Available package.json scripts:"
   echo "$AVAILABLE_SCRIPTS"
   echo ""

   # Use AskUserQuestion:
   # Question: "Create a custom pr-lint command for ${REPO_NAME}?"
   # Options:
   #   - Yes - Research and create repo-specific command
   #   - No - Skip validation and continue

   if [[ "$USER_CHOICE" == "Yes" ]]; then
     # Invoke create-command skill with context
     echo "Researching ${REPO_NAME} to create pr-lint command..."

     # Use Task tool to spawn agent that:
     # 1. Reads package.json, explores codebase
     # 2. Identifies format/lint tools (ESLint config, Prettier config, etc.)
     # 3. Proposes command structure
     # 4. Asks user for approval
     # 5. Creates ~/dotfiles/claude/commands/repos/${REPO_NAME}/pr-lint.md

     Task(
       subagent_type="Plan",
       prompt="Research this repository and create a pr-lint command.

       Context:
       - Repository: ${REPO_NAME}
       - Available scripts: ${AVAILABLE_SCRIPTS}
       - package.json location: $(pwd)/package.json

       Task:
       1. Read package.json to understand tooling
       2. Check for config files: .eslintrc, .prettierrc, biome.json, etc.
       3. Identify format and lint commands (may have different names)
       4. Create repos/${REPO_NAME}/pr-lint.md that runs the correct commands
       5. Ask user to approve before writing file

       Output:
       - Command file at: ~/dotfiles/claude/commands/repos/${REPO_NAME}/pr-lint.md
       - Should follow same pattern as sf-ui-web commands"
     )

     # If user approves: Command created, run it
     # If user denies: Skip and continue
   else
     echo "Skipping validation"
     exit 0
   fi
   ```

What this does:
- **First:** Check if repo already has custom pr-lint command
- **Second:** Offer to research and create custom command
- **Third:** Skip gracefully if user declines or not applicable

Intelligent features:
- Never runs unknown commands automatically
- Always asks before creating new commands
- Explores codebase to understand tooling
- Creates persistent repo-specific commands
- Graceful skip for non-JS projects

Examples:

**In sf-ui-web (has repos/sf-ui-web/pr-lint.md):**
```bash
/pr-lint
# Uses existing repo-specific command
# Runs: yarn format && yarn lint
```

**In new repo (no custom command):**
```bash
/pr-lint
# No custom command found
# Shows available package.json scripts
# Prompts: "Create custom pr-lint command for my-app? (Yes/No)"
# If Yes: Spawns agent to research and propose command
# If No: Skips validation
```

**In non-JS repo:**
```bash
/pr-lint
# No package.json found
# Skips: "Not a JavaScript project, skipping validation"
```

Notes:
- Never runs arbitrary commands without understanding them
- Creates reusable commands for future use
- Graceful degradation (skip if unavailable)
- Learns from each repository
