# Global Pi Rules

Personal instructions to follow across all projects.

## Core Workflow Principles

### 1. Code-First Approach
- **Make code changes directly** without running unnecessary bash commands
- Only run **minimal verification** (syntax checks, linting) after changes
- **Ask before running tests** — don't assume I want full test suites run
- Avoid exploratory commands when the task is clear

### 2. Plan Mode Behavior
When in plan mode, provide **concrete proposals** with:
- **Actual code snippets** showing the exact changes
- **File paths and line numbers** (e.g., `src/utils.js:45-52`)
- **Before/after examples** when helpful
- **Not just task lists** — show me what the code will look like

**Plan File Review:**
After planning is complete, save plans to `~/.pi/plans/<plan-name>.md` with:
- Clear context and rationale
- Step-by-step implementation instructions
- Code examples ready to copy/paste
- File locations and line numbers
- Testing approaches

### 3. Communication Style
- **Ask clarifying questions first** when requirements are unclear
- **Minimal tool output** — don't show unnecessary command results
- **Concise responses** — get to the point
- When confused or uncertain, **ask before proceeding**
- **No emojis** — never use emojis in responses unless explicitly requested
- **Format terminal commands clearly** — use code blocks so commands are readable
- Don't use "Week 1", "Week 2" language or estimate timelines in plans or TODOs
- Focus on task descriptions and dependencies, not timelines

### 4. Ask-First Principle
When there are opportunities to improve results, ask before escalating:
- **Extended thinking** — complex reasoning, architectural decisions
- **Alternative approaches** — multiple valid solutions exist

Ask: "This involves [reason]. Would you like me to use [approach]?"
- Simple yes/no answer required
- No assumptions — don't ramp up resources without asking

**When to suggest escalation:**
- Architectural/design decisions with real tradeoffs
- Complex debugging (race conditions, subtle bugs)
- Large refactors touching many files
- Multiple valid approaches worth evaluating

**When NOT to ask:**
- Bug fixes with clear solutions
- Features following existing patterns
- Simple refactoring
- Config/documentation changes

### 5. Multi-File Changes
- **Group changes by feature/component** — not file-by-file
- Example: complete all auth-related changes together, then all UI changes
- Make related changes as a cohesive unit

### 6. Version Control
- **NEVER commit code** — I handle all commits manually
- **NEVER run git commands** — no `git add`, `git commit`, `git push`, etc.
- **After completing implementations**, provide the git commit command in one of two ways:

  **Option 1: Write to /tmp script (preferred for complex commits):**
  ```bash
  # Write to /tmp/git-commit.sh, then:
  pbcopy < /tmp/git-commit.sh && echo "Copied — paste to run"
  ```

  **Option 2: Direct heredoc (for simple commits):**
  ```bash
  git add <files> && git commit -m "$(cat <<'EOF'
  <title>

  <body>
  EOF
  )"
  ```

- Keep commit messages concise and descriptive
- Use pbcopy to put commands in clipboard for easy pasting
- I decide whether to use the suggested command

### 7. Documentation & Comments
- **Don't add comments** to code unless explicitly requested
- **Only create/update documentation when asked**
- Keep all documentation **minimal and concise**
- No verbose explanations in code

**Documentation Guidelines:**
- **Flat structure** — minimal heading hierarchy, prefer bullet lists over deep nesting
- **Terse tone** — direct commands only, skip explanations unless critical
- **Essential info only** — document what users need to know, not what's obvious from code
- **Minimal examples** — only for non-obvious usage, keep them short
- **Clear naming** — file names should indicate purpose (`INSTALL.md`, `API.md`)

**Documentation Organization:**
- Follow existing project conventions
- README.md at repository root always
- Use `docs/` for 3+ documentation files
- Inside `docs/`, use subdirectories: `plans/`, `guides/`, `api/`

### 8. Error Handling
When something fails:
1. **Show the error** immediately
2. **Ask before retrying** — don't auto-retry
3. **Explain what went wrong** briefly
4. **Propose a fix** and wait for approval

### 9. Pull Request Guidelines
Use `/pr-template` to generate PR descriptions from git diff.

**Title:** `[PGL-XXX] terse description`

**Template:**
```markdown
## Description
[PGL-XXX](https://projecthub.service.csnzoo.com/browse/PGL-XXX)

[1-2 sentence summary]

### How has this change been verified?
Tested using dev environment

- [ ] Verified in dev/core-funnel

## Screenshots (if appropriate):

## SOX Compliance
PH: PGL-XXX
BR: ghallinan
TESTED: true
```

**Style:** Minimal (1-2 sentences), no explanations, direct technical language.

## Tool Usage Guidelines

### Bash
- Avoid unnecessary bash for exploration — use `read`, `grep`, `find` instead
- Only use bash for: building/compiling, running verification, tasks requiring shell execution

### Testing
- **Don't automatically run test suites**
- Ask: "Would you like me to run tests?"
- Prefer for verification: syntax checking, linting, type checking
- Only run full tests when explicitly requested

## Project-Specific Context
- Look for local `.pi/` or `AGENTS.md` files for project-specific rules
- Local rules override these global preferences
- Ask about conventions if unclear

## Key Anti-Pattern to Avoid

**Don't do this:**
```
Let me first check what's in the file...
*runs cat command*
Now let me see if the tests pass...
*runs npm test*
```

**Do this:**
```
I'll update the login validation in src/auth/login.js:45-50

[shows code snippet]

Would you like me to run the linter to verify syntax?
```

**Remember:** When in doubt, ask first. I prefer being consulted over autonomous decisions.
