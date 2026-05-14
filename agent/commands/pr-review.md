---
description: Review code changes on the current branch vs main
---
Review code changes on the current branch with the eye of a code reviewer.

Analyzes the diff between this branch and main, then provides structured feedback covering correctness, style, edge cases, and potential issues.

Steps:

1. Determine base branch and current context:
   ```bash
   BASE=$(git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null)
   BRANCH=$(git branch --show-current)
   echo "BRANCH: $BRANCH"
   echo "BASE: $BASE"
   ```

2. Get the full diff:
   ```bash
   git diff main...HEAD
   ```
   - If diff is empty and branch == main/master: inform user there are no branch changes to review
   - If `--staged` flag provided: use `git diff --staged` instead
   - If user provides a commit range (e.g., `HEAD~3..HEAD`): use that range

3. Get changed file list for context:
   ```bash
   git diff main...HEAD --name-status
   ```

4. Get commit log for this branch:
   ```bash
   git log main...HEAD --oneline
   ```

5. Analyze the diff and produce a structured review.

   For each changed file or logical group of changes, evaluate:
   - **Correctness** — Does the logic do what it appears to intend? Edge cases missed?
   - **Consistency** — Does it match surrounding code style and patterns?
   - **Complexity** — Is anything harder to follow than it needs to be?
   - **Safety** — Security issues, unhandled errors, null/undefined risks
   - **Naming** — Variables, functions, files — clear and consistent?
   - **Scope creep** — Changes that seem unrelated to the apparent goal

   Severity levels:
   - `[ISSUE]` — Bug or clear problem that should be fixed before merging
   - `[SUGGESTION]` — Improvement worth considering, not blocking
   - `[NITPICK]` — Minor style/preference, purely optional

6. Output the review in this format:

**Branch:** `<branch-name>`
**Files changed:** N
**Commits:** N

---

### Summary

<1-2 sentence overall assessment — is this ready to merge, needs work, etc.>

---

### Findings

<Group findings by file or logical area. Skip files with no findings.>

**`path/to/file.ts`**
- `[ISSUE]` Line 42: <description of problem and why it matters>
- `[SUGGESTION]` Line 78: <description>
- `[NITPICK]` Line 91: <description>

---

### Verdict

One of:
- `LGTM` — No issues, ready to merge
- `LGTM with suggestions` — Minor improvements noted, not blocking
- `Needs changes` — One or more [ISSUE] items must be addressed

Flags:
- `--staged` - Review only staged changes (pre-commit review)
- `--summary` - Summary and verdict only, no per-file findings
- `--focus <area>` - Limit review to a specific concern: `security`, `correctness`, `style`

Examples:
```
/pr-review                        # Full review of branch vs main
/pr-review --staged               # Review staged changes before committing
/pr-review --summary              # High-level verdict only
/pr-review --focus security       # Security-focused pass only
```

Notes:
- Review reflects changes vs main — make sure your branch is up to date if needed
- For large diffs (500+ lines), findings may be grouped at file level rather than line level
- Use alongside /pr-template to generate the PR description after addressing issues

Related commands:
- `/review` - General code review (not branch-specific)
- `/pr-template` - Generate PR title and description
- `/pr-create` - Create the PR after review passes

Anti-Patterns to Avoid:
- Don't flag style issues as [ISSUE] — use [NITPICK] for pure preferences
- Don't repeat the same finding across similar patterns — note it once and say "applies elsewhere"
- Don't give a LGTM verdict when [ISSUE] items exist
