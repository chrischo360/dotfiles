# Global `/pr` Command Implementation Summary

Implementation of the adaptive global PR workflow with intelligent command creation.

## What Was Implemented

### Core Infrastructure

**New Global Commands:**
1. `global/pr.md` - Adaptive PR workflow menu (works everywhere)
2. `global/pr-lint.md` - Intelligent quick validation (detects/creates/skips)
3. `global/git-commit.md` - Commit helper with branch validation

**New Repo-Specific Commands:**
1. `repos/sf-ui-web/pr-lint.md` - sf-ui-web specific format + lint

**Updated Commands:**
1. `global/pr-create.md` - Now uses adaptive validation (pr-check OR pr-lint)

**Deleted Commands:**
1. `repos/sf-ui-web/pr.md` - Replaced by global adaptive version

**Updated Documentation:**
1. `claude/commands/README.md` - Added adaptive commands section
2. `claude/commands/COMMAND_MAP.md` - Added new command mappings

## Key Features

### 1. Adaptive Command Pattern

Commands now follow a 3-tier fallback strategy:

**Tier 1: Use existing repo-specific command**
```
/pr-lint in sf-ui-web
→ Uses repos/sf-ui-web/pr-lint.md (exists)
```

**Tier 2: Offer to create custom command**
```
/pr-lint in my-app
→ No custom command found
→ Shows available package.json scripts
→ Prompts: "Create custom pr-lint? (Yes/No)"
→ If Yes: Spawns Plan agent to research and propose
→ Creates: repos/my-app/pr-lint.md
```

**Tier 3: Graceful skip**
```
/pr-lint in non-js-repo
→ No package.json found
→ Skips: "Not a JavaScript project, skipping validation"

/pr-lint in my-app (user declined)
→ User said "No" to creation
→ Skips: "Skipping validation"
```

### 2. Global PR Menu

The `/pr` command now works in ANY repository:

**In sf-ui-web:**
- Shows all base options + sf-ui-web specific commands
- Build, Check, Push & Diagnose, Auto-merge

**In other repos:**
- Shows base options (Create, Template, Commit, Lint, Watch, Dashboard)
- Dynamically adds any repo-specific commands found

**In dotfiles:**
- Shows base options only
- Works immediately without setup

### 3. Git Commit Helper

The `/git-commit` command provides:
- Branch name validation (warns if no ticket reference)
- Non-blocking warnings (user can continue)
- Interactive commit message prompt
- Suggests next steps after commit

### 4. Intelligent Validation

The `/pr-lint` command:
- Never runs unknown commands automatically
- Always asks before creating custom commands
- Shows available scripts for context
- Spawns Plan agent to research and propose
- Creates persistent commands for reuse
- Gracefully skips if not applicable or user declines

## Architecture

### Command Hierarchy

```
Global Adaptive Commands (work everywhere)
├─ pr.md (menu)
├─ pr-lint.md (validation)
└─ git-commit.md (helper)
    ↓ delegates to
Repo-Specific Commands (optimized per repo)
├─ repos/sf-ui-web/pr-lint.md
├─ repos/sf-ui-web/pr-build.md
└─ (future: repos/*/pr-*.md)
```

### Adaptive Flow

```
User runs: /pr-lint

1. Check for repo-specific command
   ├─ If exists → Use it
   └─ If not → Continue

2. Check if JavaScript project
   ├─ If not → Skip gracefully
   └─ If yes → Continue

3. Offer to create command
   ├─ User accepts → Spawn Plan agent
   │                  Research repo
   │                  Propose command
   │                  Create file
   └─ User declines → Skip gracefully
```

## Testing Strategy

### Basic Functionality
- [ ] `/pr` in sf-ui-web shows all options
- [ ] `/pr` in dotfiles shows base options
- [ ] `/pr-lint` in sf-ui-web uses existing command
- [ ] `/pr-lint` in new repo offers creation
- [ ] `/git-commit` validates branch names
- [ ] `/git-commit` allows override on warning

### Adaptive Behavior
- [ ] pr-lint detects standard scripts correctly
- [ ] pr-lint offers creation when needed
- [ ] Plan agent researches repo properly
- [ ] Created commands persist across sessions
- [ ] Menu reflects newly created commands

### Edge Cases
- [ ] pr-lint in non-JS repo skips gracefully
- [ ] pr-lint with missing package.json skips
- [ ] git-commit on branch without ticket warns
- [ ] pr menu outside git repo shows error

## Migration Notes

**Breaking Changes:** None

**User Impact:**
- `/pr` now global (works everywhere, not just sf-ui-web)
- New commands: `/pr-lint`, `/git-commit`
- All existing commands work unchanged

**What Users Get:**
- PR workflow in any repository
- Quick validation without full checks
- Self-improving command ecosystem
- Commit helper with validation

## Next Steps

**For Future Enhancement:**
- Add more adaptive commands (pr-build, pr-check, pr-push)
- Apply same pattern to other workflows
- Build command library across repos

**For Testing:**
- Test in multiple repositories
- Verify command creation flow
- Test persistence across sessions
- Validate menu adaptivity

## Files Changed

**New:**
- claude/commands/global/pr.md
- claude/commands/global/pr-lint.md
- claude/commands/global/git-commit.md
- claude/commands/repos/sf-ui-web/pr-lint.md

**Modified:**
- claude/commands/global/pr-create.md
- claude/commands/README.md
- claude/commands/COMMAND_MAP.md

**Deleted:**
- claude/commands/repos/sf-ui-web/pr.md

## Success Criteria

The implementation is successful if:

1. `/pr` works in any git repository
2. `/pr-lint` adapts intelligently to any repo
3. Commands self-improve (create custom versions)
4. No errors when running in incompatible contexts
5. Documentation reflects new structure
6. Skills register correctly after restart

## Known Limitations

1. Command creation requires user approval
2. Plan agent may take time to research
3. Created commands persist only in dotfiles (need git sync)
4. Menu shows all options even if some don't apply

## Future Improvements

1. Auto-detect more tooling patterns
2. Smarter menu filtering (hide inapplicable options)
3. Command templates for common patterns
4. Analytics on which commands get created most
