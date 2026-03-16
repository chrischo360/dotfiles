Clean up backlog by consolidating recurring tasks and creating execution plans.

Steps:

1. Analyze archived weeks:
   - Read all files in ~/notes/plans/archive/
   - Extract uncompleted tasks (lines with `- [ ]`)
   - Track task frequency: count how many weeks each unique task appears
   - Identify tasks appearing in 3+ archived weeks as "recurring"

2. Categorize recurring tasks:
   - Tasks Claude Code can complete (code, documentation, automation)
   - Tasks requiring user action (meetings, conversations, decisions)
   - Tasks needing more context (research, investigation)

3. Read current backlog from ~/notes/plans/week.md:
   - Extract all Backlog section items
   - Preserve categorization (Important/Urgent matrix)

4. Determine next backlog version:
   - Check ~/notes/plans/ for existing backlog_N.md files
   - Find highest N and increment (e.g., backlog_1.md → backlog_2.md)
   - If none exist, start with backlog_1.md

5. Create ~/notes/plans/backlog_N.md:
   - Add timestamp header: `# Backlog Cleanup - {YYYY-MM-DD}`
   - Structure:
     ```markdown
     # Backlog Cleanup - 2026-03-14

     ## Recurring Tasks (3+ weeks)
     [Tasks that keep appearing - may need different approach]

     ## Claude Code Actionable
     [Tasks with execution plans - see ~/.claude/plans/]

     ## Requires User Action
     [Meetings, decisions, conversations]

     ## Investigation/Research
     [Needs more context or exploration]

     ## One-Time Tasks
     [From current week backlog]
     ```

6. For Claude Code actionable tasks:
   - Create plan file in ~/.claude/plans/backlog-{task-slug}.md
   - Include plan outline with:
     * Context and goal
     * Files/directories involved
     * Proposed approach
     * Acceptance criteria
   - Add reference to plan in backlog_N.md item:
     `- [ ] Task description [plan](~/.claude/plans/backlog-{task-slug}.md)`

7. Update ~/notes/plans/week.md:
   - Keep only current week tasks in Backlog section
   - Add note at top of Backlog section: "Latest cleanup: backlog_{N}.md ({date})"

8. Output summary:
   - Backlog file created: backlog_N.md
   - Total tasks analyzed
   - Recurring tasks found (3+ weeks)
   - Plans created
   - Tasks moved to backlog file

Notes:
- Use fuzzy matching for task similarity (ignore minor wording differences)
- Preserve task links and context
- Don't create plans for tasks requiring meetings/conversations
- Focus on automation, tooling, and code tasks for Claude Code plans
- Each cleanup creates a new snapshot - allows comparing backlog evolution over time
