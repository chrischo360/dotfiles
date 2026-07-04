Archive the current weekly plan files and create new ones.

Plan files:
- Work: `~/notes/Plans/week.md`
- Personal: `~/notes/Plans/personal_week.md`

Process both files when present. Skip missing optional files, but report what was skipped.

Steps:

1. For each existing plan file, read the current content and extract:
   - Current week number from `Week {n}: {start} - {end}`
   - Current date range
   - All uncompleted tasks (`- [ ]`) with section, day, priority subsection, and local heading context
   - Parent task context for uncompleted child tasks

2. Load the matching template:
   - Work: `~/notes/Plans/template/week.md`
   - Personal: `~/notes/Plans/template/personal_week.md`
   - If the personal template does not exist, derive a clean personal template from the current `personal_week.md` by keeping the header, section headings, day headings, priority separators, and personal `###` category headings, then removing task lines.

3. Archive each current plan file before rewriting it:
   - `week.md` → `~/notes/Plans/archive/{year}-week-{current_week}_{date}.md`
   - `personal_week.md` → `~/notes/Plans/archive/personal_week-{year}-week-{current_week}_{date}.md`
   - Date format example: `2026-week-30_2026-jul-18.md`
   - Use unique filenames if an archive already exists.

4. Create the new `week.md` from `template/week.md`:
   - Update header: `Week {next_week}: {MM/DD/YYYY} - {MM/DD/YYYY}`
   - Advance the existing date range by 7 days and preserve the same range length.
   - Migrate uncompleted tasks:
     * Daily Monday-Friday tasks → place in Monday section
     * Blocked tasks → keep in Blocked section
     * Work/Backlog tasks → keep in appropriate backlog sections
     * Other tasks → preserve in matching sections or append to the closest matching section
   - For parent tasks with mixed child completion, carry forward only the uncompleted child tasks under the parent.

5. Create the new `personal_week.md` from its template or derived clean structure:
   - Update header: `Week {next_week}: {MM/DD/YYYY} - {MM/DD/YYYY}`
   - Advance the existing date range by 7 days and preserve the same range length.
   - Migrate uncompleted tasks:
     * Daily Sunday-Saturday tasks → place in Monday section when present, otherwise the first day section in the file
     * Preserve personal `###` category context when possible (for example `### Career`, `### Personal/Mental-Health`, `### Relationship`, `### Maybe`)
     * Blocked/Backlog/Maybe tasks → keep in matching sections when present
     * Other tasks → preserve in matching sections or append to the closest matching section
   - For parent tasks with mixed child completion, carry forward only the uncompleted child tasks under the parent.
   - If duplicate day headings exist, preserve the template order and append migrated daily tasks to the first matching target day section.

6. Write the new plan files back to:
   - `~/notes/Plans/week.md`
   - `~/notes/Plans/personal_week.md`

7. Display a concise result:
   - `Archived week.md to {archive_path}`
   - `Archived personal_week.md to {archive_path}`
   - `Created new week.md for Week {next_week}`
   - `Created new personal_week.md for Week {next_week}`
   - Include skipped files, if any.

8. Do not commit changes.
