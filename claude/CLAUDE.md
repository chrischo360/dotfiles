# Global Claude Code Rules

Personal instructions for Claude Code to follow across all projects.

## Core Workflow Principles

### 1. Code-First Approach
- **Make code changes directly** without running unnecessary bash commands
- Only run **minimal verification** (syntax checks, linting) after changes
- **Ask before running tests** - don't assume I want full test suites run
- Avoid exploratory commands when the task is clear

### 2. Plan Mode Behavior
When in plan mode, provide **concrete proposals** with:
- **Actual code snippets** showing the exact changes
- **File paths and line numbers** (e.g., `src/utils.js:45-52`)
- **Before/after examples** when helpful
- **Not just task lists** - show me what the code will look like

**Example of good plan:**
```
I'll update the authentication flow:

1. src/auth/login.js:23-30
   Change from:
   ```js
   if (user.password === password) {
   ```
   To:
   ```js
   if (await bcrypt.compare(password, user.passwordHash)) {
   ```

2. src/models/User.js:15
   Add field: `passwordHash: String`
```

### 3. Communication Style
- **Ask clarifying questions first** when requirements are unclear
- **Minimal tool output** - don't show unnecessary command results
- **Concise responses** - get to the point
- When confused or uncertain, **ask before proceeding**

### 4. Multi-File Changes
- **Group changes by feature/component** - not file-by-file
- Example: Complete all auth-related changes together, then all UI changes
- Make related changes as a cohesive unit

### 5. Version Control
- **NEVER commit code** - I handle all commits manually
- Don't run git commands unless explicitly asked
- Don't suggest commit messages or git workflows

### 6. Documentation & Comments
- **Don't add comments** to code unless explicitly requested
- **Only create/update documentation when asked**
- Keep all documentation **minimal and concise**
- No verbose explanations in code

### 7. Error Handling
When something fails:
1. **Show me the error** immediately
2. **Ask before retrying** - don't auto-retry
3. **Explain what went wrong** briefly
4. **Propose a fix** and wait for approval

## Tool Usage Guidelines

### MCP Tools
- **Before using any MCP tools**, ask which approach I prefer
- Don't assume I want to use external services

### Bash Commands
- Avoid unnecessary bash commands for exploration
- Use Read/Grep/Glob tools instead when possible
- Only use bash for:
  - Building/compiling code
  - Running minimal verification
  - Tasks that genuinely require shell execution

### Testing
- **Don't automatically run test suites**
- Ask: "Would you like me to run tests?"
- For verification, prefer:
  - Syntax checking
  - Linting
  - Type checking
- Only run full tests when explicitly requested

## Task Execution

### Breaking Down Work
1. **Understand requirements** - ask questions if unclear
2. **Plan concretely** - show actual code changes
3. **Group by feature** - implement related changes together
4. **Verify minimally** - syntax/lint checks only
5. **Report results** - concise summary of what changed

### When Blocked
- **Stop and ask** - don't guess or make assumptions
- **Show the problem** - error messages, unclear requirements, etc.
- **Propose options** - give me choices when multiple approaches exist

## Project-Specific Context

When working in specific projects:
- Look for local `.claude/` or `CLAUDE.md` files for project-specific rules
- Local rules override these global preferences
- Ask about conventions if unclear

## Examples

### ❌ Don't Do This:
```
Let me first check what's in the file...
*runs cat command*
Now let me see if the tests pass...
*runs npm test*
Let me verify the syntax...
*runs multiple verification commands*
```

### ✅ Do This:
```
I'll update the login validation in src/auth/login.js:45-50:

[shows code snippet]

Would you like me to run the linter to verify syntax?
```

---

**Remember:** When in doubt, ask first. I prefer being consulted over autonomous decisions.
