# Claude Commands

Custom commands for Claude Code organized by scope (global vs repo-specific).

## Directory Structure

```
~/dotfiles/claude/commands/
├── global/                     # Cross-repo commands
│   ├── pr.md                  # Adaptive PR workflow menu
│   ├── pr-template.md         # Generate PR description from git diff
│   ├── pr-create.md           # Create PR with automated workflow
│   ├── pr-lint.md             # Adaptive quick validation (format + lint)
│   ├── git-commit.md          # Commit with branch validation
│   ├── pr-watch.md            # Monitor GitHub PR CI checks
│   ├── pr-dashboard.md        # View all PRs for a repository
│   └── create-command.md      # Meta-command to generate new commands
│
└── repos/                      # Repo-specific orchestration
    ├── sf-ui-web/
    │   ├── pr-build.md        # PR preparation workflow
    │   ├── pr-lint.md         # Format and lint validation
    │   ├── quick-rebuild.md   # Fast codegen + build
    │   ├── pr-check.md        # Full validation suite
    │   ├── pr-push.md         # Push + watch + diagnose failures (propose fixes)
    │   └── pr-automerge.md    # Watch + auto-merge
    │
    ├── block-builder-api/
    │   └── prepublish.md      # Test schema changes in sf-ui-web
    │
    ├── sf-js-libraries/
    │   └── prepublish.md      # Test library changes in consuming repos
    │
    └── notes/
        └── archive-week.md    # Archive weekly plan
```

## Command Types

### 1. Adaptive Commands (global)
Commands that intelligently adapt to repository context. Can detect tooling, create repo-specific commands, or gracefully skip.

**Examples:**
- `pr` - Adaptive menu showing available commands per repo
- `pr-lint` - Detects format/lint tools or creates custom command
- `git-commit` - Validates branch naming with non-blocking warnings

**How they work:**
1. Check for repo-specific version first
2. Try to detect standard patterns
3. Offer to create custom command if needed
4. Skip gracefully if not applicable

### 2. Workflow Commands (repo-specific)
Multi-step orchestrations for specific repositories.

**Examples:**
- `pr-build` - Commit + sync + rebuild + format
- `pr-push` - Push + watch + diagnose failures + propose fixes
- Custom workflows unique to each repo

### 3. Meta Commands (global)
Commands that work across all repositories.

**Examples:**
- `pr-template` - Analyzes git diff
- `create-command` - Generates new commands

### 4. Wrapper Commands
Delegates to existing tooling (`dev` CLI, `scout` CLI).

**Examples:**
- `pr-check` - Wraps `dev :run pr:check`
- `pr-watch` - Wraps `scout check`
- `pr-dashboard` - Wraps `scout pr-dashboard`

## Usage

### Invoking Commands

**Via skill name:**
```
/pr-check
/branch-cleanup
/pr-watch
```

**Via Skill tool (from LLM):**
```python
Skill(skill="repos:sf-ui-web:pr-check")
Skill(skill="global:pr-watch")
```

**Skill naming convention:**
- Global: `global:<command-name>`
- Repo-specific: `repos:<repo-name>:<command-name>`

### Auto-Discovery

Commands are automatically discovered and registered as skills:
- Located in `commands/global/` or `commands/repos/<repo>/`
- File extension: `.md`
- Skill name derived from file path

## Integration with `dev` and `scout` CLIs

### `dev` CLI Integration

The `dev` CLI (`~/dotfiles/scripts/dev/dev.sh`) provides context-aware development commands:

**Configuration:** `~/dotfiles/scripts/dev/config.json`

**Key features:**
- Project detection (sf-ui-web, scout, nextjs, node, python)
- Context-aware commands (root vs apps/* vs libs/*)
- Multi-step scripts with notifications
- Desktop notifications on completion

**Example scripts:**
- `dev :run pr:check` - Format + lint + typecheck + build + test
- `dev :run setup` - Full repo setup
- `dev :run quick` - Codegen + build

**Command wrappers:**
All `sf-ui-web` commands wrap `dev` scripts:
- `/pr-check` → `dev :run pr:check`
- `/setup` → `dev :run setup`
- `/quick-rebuild` → `dev :run quick`

### `scout` CLI Integration

The `scout` CLI (`~/codebase/scout`) provides GitHub/Buildkite automation:

**Key features:**
- PR CI check monitoring
- Auto-merge workflows
- PR dashboard views
- Buildkite build watching

**Example commands:**
- `scout check <PR_URL>` - Monitor PR checks
- `scout pr-dashboard <owner/repo>` - View all PRs
- `scout check --auto-merge` - Auto-merge on success

**Command wrappers:**
Global commands wrap `scout`:
- `/pr-watch` → `scout check`
- `/pr-dashboard` → `scout pr-dashboard`

## Command Development Guidelines

### When to Create a Command

**Create commands for:**
- ✅ Multi-step workflows (3+ steps)
- ✅ Orchestrates multiple tools
- ✅ Repo-specific complex processes
- ✅ Frequently-used workflows

**Don't create commands for:**
- ❌ Single bash commands (run directly)
- ❌ Logic already in `dev` CLI (use that instead)
- ❌ One-time operations
- ❌ Simple wrappers with no value

### Command Quality Checklist

- [ ] Clear one-line description
- [ ] Concrete bash commands (not pseudocode)
- [ ] Error handling for common failures
- [ ] Examples for non-obvious usage
- [ ] Anti-patterns section (what not to do)
- [ ] Related commands section
- [ ] Works non-interactively (no fzf/prompts)

### Command Template

```markdown
<One-line description of what this command does>

<Optional: Brief context or when to use>

Steps:

1. <First step with concrete bash command>
   ```bash
   command --with-flags
   ```
   - Detail about what this does

2. <Next step>

3. <Final step>

What this does:
- **Step 1**: Description
- **Step 2**: Description

Options (if applicable):
- `--flag`: Description

Examples (if helpful):
- Example usage

Error handling:
- Condition: Action

Related commands:
- `/command-name` - When to use

Notes:
- Additional context

Anti-Patterns to Avoid:
- Don't do X because Y
```

### Creating New Commands

Use the `/create-command` meta-command:

```
/create-command
```

Prompts for:
- Command description
- Scope (global or repo-specific)
- Repository name (if repo-specific)
- Command name
- Parameters/flags (optional)

Automatically:
- Creates file in correct location
- Generates structured content
- Registers as skill
- Validates format

## Command Patterns

### Pattern 1: Repository Verification

All repo-specific commands should verify they're in the correct repo:

```bash
git remote -v | grep -q 'sf-ui-web' || { echo "❌ Not in sf-ui-web repository"; exit 1; }
```

### Pattern 2: PR URL Detection

Commands that need PR context should auto-detect from current branch:

```bash
PR_URL=$(gh pr view --json url -q '.url' 2>/dev/null)
[ -z "$PR_URL" ] && echo "❌ No PR found for current branch. Create one first with: gh pr create" && exit 1
```

### Pattern 3: Non-Interactive Execution

Commands must work without user interaction (no fzf, no prompts):

**❌ Bad:**
```bash
scout check  # Uses fzf to select PR interactively
```

**✅ Good:**
```bash
PR_URL=$(gh pr view --json url -q '.url' 2>/dev/null)
scout check "$PR_URL"  # Passes URL directly
```

### Pattern 4: Error Messaging

Provide helpful error messages with next steps:

```bash
[ -z "$PR_URL" ] && echo "❌ No PR found. Create one with: gh pr create" && exit 1
```

## Extending Commands

### Adding Commands for New Repos

1. Create directory: `mkdir -p ~/dotfiles/claude/commands/repos/<repo-name>`
2. Add workflow commands (not basic build/test - use `dev` for that)
3. Commands auto-register as skills on next session

### Adding `dev` Config for New Repos

Edit `~/dotfiles/scripts/dev/config.json`:

```json
{
  "projects": {
    "my-repo": {
      "detect": [
        { "git_remote": "my-repo" },
        { "path_contains": "my-repo" }
      ],
      "scripts": {
        "pr:check": {
          "steps": ["format", "lint", "test"]
        }
      },
      "contexts": {
        "/": {
          "build": "npm run build",
          "test": "npm test"
        }
      }
    }
  }
}
```

Then create wrapper commands in `commands/repos/my-repo/`.

## Testing Commands

1. Start new Claude session (for skill registration)
2. Navigate to appropriate repo (for repo-specific commands)
3. Invoke command: `/command-name`
4. Verify execution
5. Check error handling (wrong repo, missing PR, etc.)

## Documentation Sync

When adding/removing commands, update:
- This README (if structural changes)
- Command file itself (examples, related commands)
- `dev/config.json` (if adding new `dev` scripts)

## Related Documentation

- `~/dotfiles/claude/README.md` - Claude Code configuration
- `~/dotfiles/scripts/dev/README.md` - `dev` CLI documentation
- `~/codebase/scout/README.md` - `scout` CLI documentation
- `~/dotfiles/CLAUDE.md` - Global workflow rules
