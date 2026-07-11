Move uncompleted tasks from a source day to a target day in weekly plan files.

Plan files:
- Work: `~/notes/plans/week.md` (Monday-Friday)
- Personal: `~/notes/plans/personal_week.md` (Sunday-Saturday)

Process both files when present. Skip a file only when it does not exist or the resolved source/target day is outside that file's day set.

Steps:

1. Parse command arguments:
   - Supported flags: `--from <day>` and `--to <day>`
   - Use the system clock to determine the current weekday and hour:
     ```bash
     current_day="$(date +%A)"
     current_hour="$(date +%H)"
     ```
   - Resolve defaults per file unless overridden by `--from` or `--to`:
     * Work file (`week.md`):
       - Beginning/midday (`current_hour` < 15): previous weekday → current weekday
       - End of day (`current_hour` >= 15): current weekday → next weekday
       - Weekday maps: previous Monday→Friday, Tuesday→Monday, Wednesday→Tuesday, Thursday→Wednesday, Friday→Thursday; next Monday→Tuesday, Tuesday→Wednesday, Wednesday→Thursday, Thursday→Friday, Friday→Monday
       - If run on Saturday/Sunday with no explicit Monday-Friday source/target pair, skip `week.md`
     * Personal file (`personal_week.md`):
       - Beginning/midday (`current_hour` < 15): previous calendar day → current day
       - End of day (`current_hour` >= 15): current day → next calendar day
       - Calendar maps include Sunday-Saturday
   - Explicit flags override only the specified side for each file:
     * `/archive-day --to Thursday`: auto-detect source per file, target Thursday
     * `/archive-day --from Tuesday`: source Tuesday, auto-detect target per file
     * `/archive-day --from Saturday --to Sunday`: process `personal_week.md` only
   - Validate day names. Work days are Monday-Friday; personal days are Sunday-Saturday.
   - Validate source ≠ target for every processed file.
   - If no files are eligible, error with a clear message.

2. Read and parse each eligible plan file:
   - `~/notes/plans/week.md`: identify day sections `## Monday` through `## Friday`
   - `~/notes/plans/personal_week.md`: identify day sections `## Sunday` through `## Saturday`
   - If `personal_week.md` has duplicate day headers, process all matching source sections and append moved tasks to the last matching target section.
   - Identify priority subsections within each day when present:
     * `--- **Important** + **Urgent** ---`
     * `--- Not Important + Urgent ---`
     * `--- Important + Not Urgent ---`
     * `--- Not Important + Not Urgent ---`
   - Extract all tasks from source day section(s) with their priority subsection and local heading context.

3. Process tasks for migration:
   - Identify uncompleted tasks (`- [ ]`) in source day.
   - For standalone uncompleted tasks:
     * Move the entire task line to the target day.
   - For parent tasks with children:
     * If parent is `- [ ]` and has any uncompleted children (`- [ ]`):
       - Source day: replace parent with `- [x]` and keep only completed children (`- [x]`).
       - Target day: create `- [ ]` parent with only uncompleted children (`- [ ]`).
     * If parent is `- [ ]` but all children are `- [x]`:
       - Move the entire task block to target day as-is.
   - Completed tasks (`- [x]`) never move.
   - Preserve indentation, links, metadata, priority subsection context, and personal `###` category headings when present.

4. Update each eligible plan file:
   - Remove moved uncompleted tasks from source day.
   - Keep completed parent stubs in source day when parent tasks are split.
   - Append moved tasks to target day in matching priority subsections when present.
   - For `personal_week.md`, preserve personal category headings (for example `### Career`, `### Personal/Mental-Health`, `### Relationship`, `### Maybe`) and append under the matching category when present.
   - If a matching priority subsection or category does not exist in the target day, append at the end of the target day section.
   - Write modified content back to the same file.

5. Display per-file results:
   - Success: `week.md: Moved {count} uncompleted tasks from {source_day} to {target_day}`
   - Success: `personal_week.md: Moved {count} uncompleted tasks from {source_day} to {target_day}`
   - No tasks: `{file}: No uncompleted tasks in {source_day}`
   - If no tasks moved in any file, say so clearly.

6. Do not commit changes.

Edge cases:
- Missing `personal_week.md`: skip it without failing.
- Missing `week.md`: process `personal_week.md` if present.
- Source = target: error `Source and target must be different days`.
- Invalid day name: error `Invalid day: {day}. Use Sunday-Saturday`.
- Target day missing from an eligible file: error `Target day {day} not found in {file}`.
- Source day missing from an eligible file: error `Source day {day} not found in {file}`.

Command invocation:
```bash
/archive-day                              # Defaults per file based on current time
/archive-day --to Thursday                # Auto-detected source per file → Thursday
/archive-day --from Monday --to Wednesday # Monday → Wednesday in both files when present
/archive-day --from Saturday --to Sunday  # Personal plan only
```
