Archive the current weekly plan and create a new one.

Steps:

1. Read ~/notes/plans/week.md to extract:
   - Current week number
   - All uncompleted tasks (lines with `- [ ]`)
   - Section context for each task

2. Read ~/notes/plans/template/week.md to get:
   - Clean template structure
   - Standard section headers

3. Archive current week.md:
   - Move to ~/notes/plans/archive/2025-week-{current_week}_{date}.md
   - Format: 2025-week-04_2026-jan-18.md

4. Create new week.md:
   - Start from template/week.md structure
   - Update header: Week {next_week}: {MM/DD/YYYY} - {MM/DD/YYYY}
   - Migrate uncompleted tasks:
     * Daily tasks (Sunday-Friday) → Place in Monday section
     * Blocked tasks → Keep in Blocked section
     * Work/Backlog tasks → Keep in appropriate backlog sections
     * Other tasks → Preserve in matching sections or append

5. Do not commit changes
