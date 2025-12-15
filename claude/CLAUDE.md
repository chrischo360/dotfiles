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

### 3. Communication Style
- **Ask clarifying questions first** when requirements are unclear
- **Minimal tool output** - don't show unnecessary command results
- **Concise responses** - get to the point
- When confused or uncertain, **ask before proceeding**
- **No emojis** - Never use emojis in responses unless explicitly requested
- **Format terminal commands with whitespace** - When showing terminal commands (e.g., `git diff`, `yarn dev`), use code blocks with whitespace/padding so commands are clearly visible and readable

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
- **Explore agent** - Codebase exploration and investigation
- **PAL tools** - External model consultation (clink, thinkdeep, planner, consensus, debug, apilookup)
  - `apilookup` - API/SDK documentation, version info, breaking changes
  - `clink` - Quick external model consultation for second opinions
  - `thinkdeep` - Deep investigation (complex bugs, architecture, performance)
  - `planner` - Implementation planning (features, migrations, system design)
  - `consensus` - Multi-model decisions (tech choices, architectural decisions)
  - `debug` - Systematic debugging (mysterious bugs, race conditions)

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
