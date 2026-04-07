Move uncompleted tasks from current day to a specified day in the weekly plan.

Steps:

1. Parse command arguments:
   - Determine source day: auto-detect from system date (Monday-Friday) or use `--from <day>` flag
   - Determine target day: next calendar day by default or use `--to <day>` flag
   - Validate: source ≠ target, both are valid weekdays (Monday-Friday)
   - If run on weekend: error "archive-day only works Monday-Friday"
   - Day mapping for next-day: Monday→Tuesday, Tuesday→Wednesday, Wednesday→Thursday, Thursday→Friday, Friday→Monday

2. Read and parse ~/notes/plans/week.md:
   - Identify day sections: `## Monday` through `## Friday`
   - Identify priority subsections within each day:
     * `--- **Important** + **Urgent** ---`
     * `--- Not Important + Urgent ---`
     * `--- Important + Not Urgent ---`
     * `--- Not Important + Not Urgent ---`
   - Extract all tasks from source day section with their priority subsection context

3. Process tasks for migration:
   - Identify uncompleted tasks (`- [ ]`) in source day
   - For standalone uncompleted tasks:
     * Move entire task line to target day (preserve priority subsection)
   - For parent tasks with children:
     * If parent is `- [ ]` and has any uncompleted children (`- [ ]`):
       - Source day: Replace parent with `- [x]` and keep ONLY completed children (`- [x]`)
       - Target day: Create `- [ ]` parent with ONLY uncompleted children (`- [ ]`)
     * If parent is `- [ ]` but ALL children are `- [x]`:
       - Move entire task block to target day as-is
   - Preserve indentation (4 spaces for children), links, and metadata

4. Update week.md:
   - Remove uncompleted tasks from source day
   - Keep completed parent stubs in source day (when parent has children)
   - Append uncompleted tasks to target day in matching priority subsections
   - If target day priority subsection doesn't exist, append at end of target day section
   - Write modified content back to ~/notes/plans/week.md

5. Display result:
   - Success: "Moved {count} uncompleted tasks from {source_day} to {target_day}"
   - No tasks: "No uncompleted tasks in {source_day}"

6. Do not commit changes

Edge cases:
- Source day has no uncompleted tasks: Display "No uncompleted tasks in {source_day}"
- Source = target: Error "Source and target must be different days"
- Command run on weekend: Error "archive-day only works Monday-Friday"
- Target day not found in week.md: Error "Target day {day} not found in week.md"
- Invalid day name: Error "Invalid day: {day}. Use Monday-Friday"

Example:

Source day (Monday) BEFORE:
```
## Monday
--- **Important** + **Urgent** ---
- [ ] [PGL-948] ATC Mutation
    - [x] Code Changes
    - [x] Test in dev env
    - [ ] Figure out solution for order summary errors
    - [ ] Send out for code review
- [x] Completed standalone task
```

Source day (Monday) AFTER:
```
## Monday
--- **Important** + **Urgent** ---
- [x] [PGL-948] ATC Mutation
    - [x] Code Changes
    - [x] Test in dev env
- [x] Completed standalone task
```

Target day (Tuesday) AFTER:
```
## Tuesday
--- **Important** + **Urgent** ---
- [ ] [PGL-948] ATC Mutation
    - [ ] Figure out solution for order summary errors
    - [ ] Send out for code review
```

Command invocation:
```bash
/archive-day                              # Today → Tomorrow
/archive-day --to Thursday                # Today → Thursday
/archive-day --from Monday --to Wednesday # Monday → Wednesday
```
