Generate a new Claude command from a natural language description.

This meta-command creates properly structured command files in the correct location within ~/dotfiles/claude.

Steps:

1. **Gather requirements**:
   - Get command description from user (either provided upfront or ask)
   - Ask: "Is this a global command or repo-specific?"
     * Global: Available in all projects
     * Repo-specific: Only available in a specific repository
   - If repo-specific, ask: "Which repository?" (e.g., sf-ui-web, php, etc.)
   - Ask: "What should the command be named?" (suggest kebab-case name based on description)
   - Optional: "Does it need any parameters/flags?" (e.g., --watch, --timeout=N)

2. **Determine file location**:
   - Global commands: `~/dotfiles/claude/commands/global/<command-name>.md`
   - Repo-specific: `~/dotfiles/claude/commands/repos/<repo-name>/<command-name>.md`
   - Verify parent directory exists, create if needed

3. **Analyze description and generate command structure**:
   - Break down the task into concrete steps
   - Identify bash commands, git operations, or tool calls needed
   - Determine if command should use other commands internally
   - Consider error handling and edge cases
   - Add relevant examples

4. **Generate command content** following this template:

```markdown
<One-line description of what this command does>

<Optional: Brief context or when to use this command>

Steps:

1. <First step with concrete bash command or action>
   ```bash
   command --with-flags
   ```
   - Detail about what this does
   - Expected output or side effects

2. <Next step>
   - Can reference other commands if needed
   - Include conditional logic if applicable

3. <Final step>

Options (if applicable):
- `--flag`: Description of what this flag does
- `--param=VALUE`: Description with default value

Examples (if helpful):
- Input: "example input"
  → Output: "expected behavior"

Anti-Patterns to Avoid:
- Don't do X because Y
- Avoid Z in favor of W

Notes (optional):
- Additional context
- Related commands or documentation
```

5. **Write the command file**:
   - Create parent directory if needed: `mkdir -p <parent-dir>`
   - Write content to file
   - Confirm location to user

6. **Validate and test**:
   - Show the generated command content
   - Offer to test the command immediately: "Would you like to test this command now?"
   - If yes, execute the newly created command

7. **Output confirmation**:
   ```
   ✓ Created command: <command-name>
   Location: <full-path>

   To use: /<command-name> or Skill tool with skill="<scope>:<command-name>"
   ```

**Command Naming Conventions:**
- Use kebab-case (e.g., `create-command`, `pr-template`, `branch-cleanup`)
- Be descriptive but concise (2-4 words ideal)
- Avoid redundant prefixes like "run-" or "do-"
- Good: `test-schema`, `cherry-pick-merge`, `pr-cleanup`
- Bad: `run-tests`, `do-merge`, `command-for-analyzing`

**Content Guidelines:**
- Start with imperative verb (Generate, Analyze, Execute, Update)
- Include concrete bash commands, not pseudocode
- Show actual command flags and options
- Add examples for non-obvious usage
- Keep explanations terse and technical
- No marketing language or over-explanation

**Common Command Patterns:**

1. **Git/PR workflow**: Check branch, analyze changes, create PR, monitor CI
2. **Code analysis**: Search files, read content, identify patterns, report findings
3. **Automation chains**: Execute multiple commands in sequence, handle errors
4. **Data gathering**: Fetch from APIs/tools, aggregate, format output
5. **File operations**: Create/update files, maintain structure, validate format

**Integration with Existing Commands:**
- Can call other commands using: "Execute the <command-name> command"
- Example: "Execute the pr-template command to generate title/description"
- Prefer composing commands over duplicating logic

Anti-Patterns to Avoid:
- Don't create vague steps like "do the thing" - be specific
- Don't skip bash command examples - show actual commands
- Don't create commands for one-time tasks - commands should be reusable
- Don't duplicate existing commands - check first with user or command list
- Don't use verbose explanations - keep it terse and technical
