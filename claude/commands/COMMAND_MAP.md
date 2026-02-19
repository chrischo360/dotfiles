# Claude Commands Map

Visualization of all Claude commands and their relationships.

## Command Categories

- [[#Global Commands]] - Work in any repository
- [[#sf-ui-web Commands]] - Specific to sf-ui-web repository
- [[#Other Repository Commands]] - Specific to other repos
- [[#External Tools]] - Underlying CLIs and scripts

---

## Global Commands

### commands
**Skill:** `global:commands`
**Purpose:** Show available commands and tools for current context

**Uses:**
- git (detect repo, branch, PR status)
- gh CLI (detect PR)

**Used by:**
- User invoked for discovery

**Related:**
- None (standalone discovery tool)

---

### create-command
**Skill:** `global:create-command`
**Purpose:** Generate a new Claude command from a natural language description

**Uses:**
- File I/O (creates .md files)
- Template generation

**Used by:**
- User invoked to create new commands

**Related:**
- Creates new entries in this map

---

### pr
**Skill:** `global:pr`
**Purpose:** Adaptive PR workflow menu with repository detection

**Uses:**
- git (repository detection)
- AskUserQuestion (presents menu)
- Delegates to other PR commands based on selection

**Used by:**
- User invoked for discovery/navigation

**Options:**
- Base (all repos): Create PR, Generate Description, Git Commit, Quick Lint, Watch, Dashboard
- sf-ui-web additional: Build, Check, Push & Diagnose, Auto-merge
- Other repos: Dynamically shows repo-specific commands

**Related:**
- Replaces repos:sf-ui-web:pr (now global)

---

### pr-lint
**Skill:** `global:pr-lint`
**Purpose:** Adaptive quick validation (format + lint)

**Uses:**
- git (repository detection)
- package.json detection
- Creates repo-specific commands via Task/Plan agent
- Falls back to direct execution or graceful skip

**Used by:**
- [[#pr-create]] (optional validation)
- User invoked manually

**Adaptive strategy:**
1. Check for repos/${REPO_NAME}/pr-lint.md
2. Detect standard format/lint scripts
3. Offer to create custom command
4. Skip gracefully if not applicable

**Related:**
- Can create new repo-specific commands dynamically

---

### git-commit
**Skill:** `global:git-commit`
**Purpose:** Commit with branch validation (warns if no ticket reference)

**Uses:**
- git (status, branch, commit)
- AskUserQuestion (commit message, warnings)

**Used by:**
- User invoked to commit changes
- [[#pr]] menu option

**Features:**
- Validates branch name for ticket patterns (PGL-XXX, ph-XXX, ticket/XXX)
- Non-blocking warnings (user can continue)
- Suggests next steps after commit

**Related:**
- Preparation step before PR workflows

---

### pr-template
**Skill:** `global:pr-template`
**Purpose:** Generate PR title and description from git changes matching your terse, technical style

**Uses:**
- git (diff, branch info)
- Optional: Glean MCP (ticket context)
- Optional: Confluence MCP (documentation)
- Optional: Jira MCP (ticket details)

**Used by:**
- [[#pr-create]] (invoked internally)
- [[#pr-build]] (suggested next step)
- User invoked manually

**Related:**
- Input to PR creation workflow

---

### pr-create
**Skill:** `global:pr-create`
**Purpose:** Create GitHub PR with automated workflow (checks, template, push, create)

**Uses:**
- [[#pr-template]] ← **invokes to generate title/body**
- [[#pr-check]] ← **optionally invokes for validation** (if available)
- [[#pr-lint]] ← **fallback validation if pr-check not available**
- git (push, branch validation)
- gh CLI (create PR)

**Used by:**
- [[#pr-build]] (suggested next step)
- User invoked to create PR

**Workflow:**
```
1. Pre-flight validation
2. Optional: invoke pr-check
3. Invoke pr-template → get title and body
4. Push branch
5. Create PR with gh CLI
6. Suggest next steps: pr-watch, pr-automerge
```

**Related:**
- [[#pr-watch]] (suggested next step)
- [[#pr-automerge]] (suggested next step)

---

### pr-watch
**Skill:** `global:pr-watch`
**Purpose:** Monitor GitHub PR CI checks in real-time

**Uses:**
- gh CLI (PR status)
- scout CLI (`scout check`) ← **wraps this tool**

**Used by:**
- [[#pr-push]] ← **uses internally**
- [[#pr-automerge]] ← **uses internally**
- [[#pr-create]] (suggested next step)
- User invoked manually

**Related:**
- Core monitoring component reused by multiple commands

---

### pr-dashboard
**Skill:** `global:pr-dashboard`
**Purpose:** Display PR dashboard for a repository showing status of all open PRs

**Uses:**
- scout CLI (`scout pr-dashboard`) ← **wraps this tool**

**Used by:**
- User invoked for PR overview

**Related:**
- [[#pr-watch]] (monitor specific PR)

---

### buildkite-watch
**Skill:** `global:buildkite-watch`
**Purpose:** Monitor Buildkite build status with live progress and notifications

**Uses:**
- gh CLI (PR detection)
- Monitoring script (`~/dotfiles/claude/scripts/monitoring/buildkite-monitor-pr.sh`)
- scout CLI (optional, fallback)

**Used by:**
- [[#prepublish (block-builder-api)]] ← **invoked to monitor builds**
- [[#prepublish (sf-js-libraries)]] ← **invoked to monitor builds**
- User invoked manually

**Workflow:**
```
1. Auto-detect PR number (if not provided)
2. Auto-detect Buildkite context from repo
3. Delegate to monitoring script
4. Return exit codes:
   - 0 = success
   - 1 = failure
   - 2 = timeout
   - 3 = no build found
```

**Related:**
- Reusable monitoring component for prepublish workflows

---

## sf-ui-web Commands

### pr-lint
**Skill:** `repos:sf-ui-web:pr-lint`
**Purpose:** Run format and lint validation for sf-ui-web

**Uses:**
- yarn (format, biome lint, eslint)

**Used by:**
- [[#pr-lint (global)]] ← **delegates to this**
- User invoked manually

**Workflow:**
```
1. Verify repository
2. Run yarn format
3. Run yarn biome lint
4. Run yarn lint
```

**Related:**
- Faster than [[#pr-check]] (no typecheck, build, test)

---

### pr-build
**Skill:** `repos:sf-ui-web:pr-build`
**Purpose:** Build and prepare branch for PR by committing unstaged changes, syncing with main, rebuilding, and formatting

**Uses:**
- git (commit, fetch, merge, checkout)
- yarn (install, codegen, build, format, lint)

**Used by:**
- User invoked before creating PR

**Workflow:**
```
1. Save current branch
2. Fetch latest from origin
3. Commit unstaged changes (if any)
4. Update main branch + build
5. Return to feature branch + sync with main
6. Install deps + codegen
7. Format and lint
8. Show final state
```

**Next Steps:**
- [[#pr-template]] (generate PR description)
- [[#pr-create]] (create PR)

**Related:**
- Preparation step before PR creation

---

### quick-rebuild
**Skill:** `repos:sf-ui-web:quick-rebuild`
**Purpose:** Fast rebuild: regenerate GraphQL types and build libraries

**Uses:**
- dev CLI (`dev :run quick`) ← **wraps this script**
  - yarn gql:codegen
  - yarn lib:build

**Used by:**
- [[#pr-build]] (includes rebuild)
- User invoked after schema changes

**Related:**
- Faster alternative to full setup

---

### pr-check
**Skill:** `repos:sf-ui-web:pr-check`
**Purpose:** Run full pre-PR validation suite (format, lint, typecheck, build, test)

**Uses:**
- dev CLI (`dev :run pr:check`) ← **wraps this script**
  - yarn format
  - yarn lint
  - yarn type-check
  - yarn lib:build
  - yarn test

**Used by:**
- [[#pr-create]] ← **optionally invoked**
- User invoked manually

**Related:**
- Validation component used by other commands

---

### pr-push
**Skill:** `repos:sf-ui-web:pr-push`
**Purpose:** Push changes and auto-diagnose CI failures with proposed fixes

**Uses:**
- git (push branch)
- dev CLI (`dev :run pr:diagnose`) ← **wraps this script**
  - Uses scout watch-builds (same as [[#pr-watch]])
  - Spawns Claude agent on failure

**Used by:**
- User invoked to push and monitor

**Workflow:**
```
1. Push current branch to remote
2. Watch PR checks
3. On failure: spawn Claude agent
4. Agent reads logs and proposes fix
5. Desktop notification with results
6. User reviews proposed fix
7. User applies fix and runs pr-check
```

**Related:**
- [[#pr-watch]] (monitoring component)
- [[#pr-check]] (to test proposed fix)
- Replaces pr-submit with added AI diagnosis

---

### pr-automerge
**Skill:** `repos:sf-ui-web:pr-automerge`
**Purpose:** Watch PR checks, auto-merge when all checks pass

**Uses:**
- dev CLI (`dev :run pr:automerge`) ← **wraps this script**
  - Uses scout watch-builds (same as [[#pr-watch]])
  - gh CLI (for merge)

**Used by:**
- [[#pr-create]] (suggested next step)
- User invoked for hands-off merging

**Workflow:**
```
1. Watch PR checks
2. On success: gh pr merge --auto --squash
3. On failure: stop and report
4. Desktop notifications
```

**Related:**
- [[#pr-watch]] (monitoring component)
- [[#pr-push]] (watch with AI diagnosis)

---

## Other Repository Commands

### prepublish (block-builder-api)
**Skill:** `repos:block-builder-api:prepublish`
**Purpose:** Automate testing block-builder-api GraphQL schema changes in sf-ui-web

**Uses:**
- [[#buildkite-watch]] ← **invokes to monitor build**
- git (branch operations)
- yarn (publish to Verdaccio)

**Used by:**
- User invoked when testing schema changes

**Workflow:**
```
1. Create feature variant in sf-ui-web
2. Publish to Verdaccio
3. Invoke buildkite-watch to monitor build
4. Handle exit codes from buildkite-watch
5. Test in dev environment
```

**Related:**
- [[#buildkite-watch]] (build monitoring)

---

### prepublish (sf-js-libraries)
**Skill:** `repos:sf-js-libraries:prepublish`
**Purpose:** Automate testing pre-published libraries in consuming repos

**Uses:**
- [[#buildkite-watch]] ← **invokes to monitor build**
- git (branch operations)
- yarn (publish to Verdaccio)

**Used by:**
- User invoked when testing library changes

**Workflow:**
```
1. Create feature variant in consuming repo
2. Publish to Verdaccio
3. Invoke buildkite-watch to monitor build
4. Handle exit codes from buildkite-watch
5. Test in dev environment
```

**Related:**
- [[#buildkite-watch]] (build monitoring)

---

### archive-week
**Skill:** `repos:notes:archive-week`
**Purpose:** Archive the current weekly plan and create a new one

**Uses:**
- File I/O (markdown files)
- Date utilities

**Used by:**
- User invoked weekly

**Related:**
- None (standalone notes utility)

---

## External Tools

These are the underlying CLIs that commands wrap or delegate to.

### dev CLI
**Location:** `~/dotfiles/scripts/dev/dev.sh`
**Purpose:** Context-aware development commands

**Used by:**
- [[#pr-check]] → `dev :run pr:check`
- [[#pr-push]] → `dev :run pr:diagnose`
- [[#pr-automerge]] → `dev :run pr:automerge`
- [[#quick-rebuild]] → `dev :run quick`

**Features:**
- Project detection (sf-ui-web, scout, nextjs, node, python)
- Context-aware commands (root vs apps/* vs libs/*)
- Multi-step scripts with notifications
- Desktop notifications on completion

---

### scout CLI
**Location:** `~/codebase/scout` (npm package)
**Purpose:** GitHub/Buildkite automation

**Used by:**
- [[#pr-watch]] → `scout check`
- [[#pr-dashboard]] → `scout pr-dashboard`
- [[#buildkite-watch]] → `scout buildkite-watch` (delegated)

**Features:**
- PR CI check monitoring
- Auto-merge workflows
- PR dashboard views
- Buildkite build watching

---

### gh CLI
**Purpose:** GitHub official CLI

**Used by:**
- [[#pr-create]] (create PR)
- [[#pr-watch]] (PR status)
- [[#pr-automerge]] (merge PR)
- [[#buildkite-watch]] (PR detection)
- [[#commands]] (PR detection)

**Features:**
- PR creation, viewing, merging
- Authentication
- Issue management

---

## Workflow Diagrams

### Complete PR Workflow (sf-ui-web)

```
1. Development
   ├─ Make changes
   └─ pr-build
       ├─ commits unstaged changes
       ├─ syncs with main
       ├─ rebuilds
       └─ formats

2. PR Creation
   └─ pr-create
       ├─ handles uncommitted changes
       ├─ runs pr-check (optional)
       ├─ invokes pr-template
       ├─ pushes branch
       └─ creates PR with gh CLI

3. Monitoring (choose one)
   ├─ pr-watch
   │   └─ monitor only
   ├─ pr-push
   │   ├─ push changes
   │   ├─ monitor
   │   └─ propose fixes on failure
   └─ pr-automerge
       ├─ monitor
       └─ auto-merge on success
```

### Prepublish Workflow (block-builder-api / sf-js-libraries)

```
1. Make changes to schema/library

2. Run prepublish
   ├─ creates feature variant in consuming repo
   ├─ publishes to Verdaccio
   └─ invokes buildkite-watch
       ├─ auto-detects PR and context
       ├─ monitors build progress
       └─ returns exit code

3. Handle build result
   ├─ success (0): continue to testing
   ├─ failure (1): ask to continue or exit
   ├─ timeout (2): ask to wait/skip/exit
   └─ no build (3): warn and ask to continue

4. Test in dev environment
```

---

## Command Reuse Patterns

### pr-watch (used by 2 commands)
- [[#pr-push]]
- [[#pr-automerge]]

### buildkite-watch (used by 2 commands)
- [[#prepublish (block-builder-api)]]
- [[#prepublish (sf-js-libraries)]]

### pr-template (used by 1 command + manual)
- [[#pr-create]]
- Manual invocation after [[#pr-build]]

### pr-check (used by 1 command + manual)
- [[#pr-create]] (optional)
- Manual invocation

---

## Quick Reference

### By Use Case

**Preparing a PR:**
1. [[#pr-build]] - prepare branch
2. [[#pr-create]] - create PR

**Validating changes:**
- [[#pr-check]] - full validation suite
- [[#quick-rebuild]] - just codegen + build

**Monitoring PR:**
- [[#pr-watch]] - basic monitoring
- [[#pr-push]] - push + monitor + auto-diagnose (recommended)
- [[#pr-automerge]] - monitor + auto-merge

**Discovery:**
- [[#pr]] - PR workflow menu (meta command)

**Testing cross-repo changes:**
- [[#prepublish (block-builder-api)]] - test schema changes
- [[#prepublish (sf-js-libraries)]] - test library changes

**Command discovery:**
- [[#commands]] - show available commands for current context

**Utilities:**
- [[#pr-template]] - generate PR description
- [[#pr-dashboard]] - view all PRs
- [[#create-command]] - create new command

---

## Architecture Layers

```
┌─────────────────────────────────────────────────┐
│ Layer 1: Claude Commands (Orchestration)       │
│ - High-level workflows                          │
│ - Multi-step processes                          │
│ - User-facing commands                          │
└─────────────────────────────────────────────────┘
                    ↓ invokes
┌─────────────────────────────────────────────────┐
│ Layer 2: CLI Tools (Implementation)             │
│ - dev CLI (context-aware dev commands)          │
│ - scout CLI (GitHub/Buildkite automation)       │
│ - Monitoring scripts (buildkite-monitor-pr.sh)  │
└─────────────────────────────────────────────────┘
                    ↓ uses
┌─────────────────────────────────────────────────┐
│ Layer 3: Platform APIs (Low-level)              │
│ - gh CLI (GitHub API)                           │
│ - git (version control)                         │
│ - yarn (package management)                     │
└─────────────────────────────────────────────────┘
```

This separation allows:
- **Flexibility** - swap implementations without changing workflows
- **Reusability** - commands compose well
- **Testability** - each layer can be tested independently
- **Maintainability** - clear boundaries between concerns
