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

**Custom Agent Detection:**
If the planning task would benefit from a specialized agent:
- **project-discovery-researcher** - Requirements gathering or researching new projects/features
- **implementation-planner** - Synthesizing requirements into implementation strategies
- **task-coordinator-qa** - Breaking down implementation plans into executable tasks

See "Ask-First Principle" below for how this works.

**Plan File Review:**
After planning is complete, plans are saved to `~/.claude/plans/<plan-name>.md` with:
- Clear context and rationale
- Step-by-step implementation instructions
- Code examples ready to copy/paste
- File locations and line numbers
- Testing approaches

### 3. Communication Style
- **Ask clarifying questions first** when requirements are unclear
- **Minimal tool output** - don't show unnecessary command results
- **Concise responses** - get to the point
- When confused or uncertain, **ask before proceeding**
- **No emojis** - Never use emojis in responses unless explicitly requested
- **Format terminal commands with whitespace** - When showing terminal commands (e.g., `git diff`, `yarn dev`), use code blocks with whitespace/padding so commands are clearly visible and readable
- Don't use "Week 1", "Week 2" language or estimate how long tasks will take in TODO lists or plans
- Focus on task descriptions and dependencies, not timelines
**Ask-First Principle:**
When I detect opportunities to improve results, I'll ask before escalating:
- **Extended thinking** - Complex reasoning, architectural decisions
- **Different model** - Particularly difficult problems
- **Alternative approaches** - Multiple valid solutions

I will ask: "This involves [reason]. Would you like me to use [approach/model/agent]?"
- **Your control**: Simple yes/no answer
- **No assumptions**: I don't decide to ramp up resources without asking

**When I might suggest escalation:**
- Architectural/design decisions with tradeoffs
- Complex debugging (race conditions, subtle bugs)
- Large refactors touching many files
- Multiple valid approaches to evaluate

**When I won't ask:**
- Bug fixes with clear solutions
- Features following existing patterns
- Simple refactoring
- Config/documentation changes

**Auto-Escalation (No Asking Required):**
For these tools, I will automatically use them when appropriate without asking:
- **mcp__pal__clink** - PREFERRED for codebase exploration and investigation (uses Cursor by default). Always use this instead of Explore agent for:
  - Finding files and searching code
  - Understanding codebase structure
  - Exploring existing implementations
  - Answering questions about the codebase
  - Any exploratory investigation tasks

  **Usage guidelines:**
  - **Do NOT specify cli_name** - Let it use the default (cursor). Only specify cli_name if explicitly requested by the user
  - **One-shot queries only** - Send task, get results, done. No back-and-forth conversation between models
  - **Data gathering focus** - Use for collecting information, not for iterative discussions
  - **Parallel execution** - When exploring multiple areas, spawn multiple clink agents in parallel (single message, multiple tool calls)
  - Example: Instead of one clink exploring everything sequentially, spawn 2-3 clink calls in parallel for different search focuses

- **PAL tools** - External model consultation (only clink is enabled)
  - `clink` - Quick external model consultation, codebase exploration (ENABLED)

### 4. Multi-File Changes
- **Group changes by feature/component** - not file-by-file
- Example: Complete all auth-related changes together, then all UI changes
- Make related changes as a cohesive unit

### 5. Version Control
- **NEVER commit code** - I handle all commits manually
- **NEVER run git commands** - Don't execute git add, commit, push, etc.
- **After completing implementations**, provide an optional git commit suggestion:
  ```bash
  # Optional commit command (you run this):
  git add <files> && git commit -m "<descriptive message>"
  ```
- Keep commit messages concise and descriptive
- Focus on what changed and why
- User decides whether to use the suggested command

### 6. Documentation & Comments
- **Don't add comments** to code unless explicitly requested
- **Only create/update documentation when asked**
- Keep all documentation **minimal and concise**
- No verbose explanations in code

**Documentation Guidelines:**
- **Flat structure** - Use minimal heading hierarchy. Prefer bullet lists over deep nesting
- **Terse tone** - Direct commands only. "Run X. Configure Y." Skip explanations unless critical
- **Essential info only** - Document what users need to know, not what's obvious from code
- **Minimal examples** - Include code examples only for non-obvious usage. Keep them short and focused
- **Clear naming** - File names should indicate purpose (e.g., `INSTALL.md`, `API.md`). No verbose titles

**Documentation Organization:**
- **Follow existing conventions** - Match the project's current documentation structure
- **README.md at root** - Always keep README.md at repository root
- **Use docs/ for 3+ files** - When you have 3 or more documentation files, organize them in a `docs/` folder
- **Structure docs/ by type** - Inside docs/, use subdirectories like `plans/`, `guides/`, `api/` to organize content

### 7. Error Handling
When something fails:
1. **Show me the error** immediately
2. **Ask before retrying** - don't auto-retry
3. **Explain what went wrong** briefly
4. **Propose a fix** and wait for approval

### 8. Pull Request Guidelines

**Auto-generation:** Use `/pr-template` command to generate PR descriptions from git changes. Analyzes git diff and outputs formatted PR body.

**Title:** Include ticket ID (PGL-XXX), terse description

**Template:**
```markdown
## Description
[PGL-XXX](https://projecthub.service.csnzoo.com/browse/PGL-XXX)

[1-2 sentence summary]

### How has this change been verified?
[Brief method - "Tested using dev environment"]

- [ ] Verified in dev/core-funnel

## Screenshots (if appropriate):

## SOX Compliance
PH: PGL-XXX
BR: mro
TESTED: true
```

**Style:** Minimal descriptions (1-2 sentences), no explanations, direct technical language. Let Cursor AI handle detailed summaries.

## Tool Usage Guidelines

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

## Project-Specific Context

When working in specific projects:
- Look for local `.claude/` or `CLAUDE.md` files for project-specific rules
- Local rules override these global preferences
- Ask about conventions if unclear

## Key Anti-Pattern to Avoid

**❌ Don't Do This:**
Running exploratory commands and tests without asking:
```
Let me first check what's in the file...
*runs cat command*
Now let me see if the tests pass...
*runs npm test*
```

**✅ Do This:**
Make changes directly, then ask about verification:
```
I'll update the login validation in src/auth/login.js:45-50

[shows code snippet]

Would you like me to run the linter to verify syntax?
```

## Negative Examples

**Add anti-patterns here as you encounter them repeatedly.**

Format:
```markdown
**❌ Don't [bad pattern]** - [why/when not to do it]
```

<!--
Examples to add:
- Don't automatically fix linting issues - ask first
- Don't add error handling unless requested
- Don't refactor surrounding code while fixing a bug
-->

---

**Remember:** When in doubt, ask first. I prefer being consulted over autonomous decisions.
