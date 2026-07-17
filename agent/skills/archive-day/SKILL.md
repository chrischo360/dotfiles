---
name: archive-day
description: Move uncompleted tasks from one weekday to another in ~/notes/Plans/week.md. Handles parent/child task splitting, priority subsection matching, and time-based defaults. Use when the user runs /archive-day with optional --from and --to flags.
---

# archive-day

Move uncompleted tasks between day sections in `~/notes/Plans/week.md`.

## Usage

```
/archive-day [--from DAY] [--to DAY]
```

Arguments after `/archive-day` are passed directly to the script.

## Run

```bash
python3 ~/.agents/skills/archive-day/scripts/archive_day.py <args>
```

Replace `<args>` with whatever flags the user provided (e.g. `--to Thursday`, `--from Monday --to Wednesday`).

## Day and Time Defaults

When no flags are given, defaults are based on current time:
- Before 15:00 → source = previous weekday, target = today
- 15:00+ → source = today, target = next weekday

Previous-day map: Monday→Friday, Tuesday→Monday, Wednesday→Tuesday, Thursday→Wednesday, Friday→Thursday
Next-day map: Monday→Tuesday, Tuesday→Wednesday, Wednesday→Thursday, Thursday→Friday, Friday→Monday

## Task Migration Rules

- **Standalone `- [ ]`** → removed from source, appended to target
- **Parent `- [ ]` with mixed children** → source keeps `- [x]` parent + completed children; target gets `- [ ]` parent + uncompleted children only
- **Parent `- [ ]` with all children `- [x]`** → entire block moves to target
- **Completed tasks** (`- [x]`) → never moved

Priority subsections (`--- **Important** + **Urgent** ---`, etc.) are matched in the target day when present. If missing, tasks are appended at the end of the target day section.

## Output

- `Moved N uncompleted tasks from <source> to <target>`
- `No uncompleted tasks in <source>` (no changes made)
- Error messages to stderr with exit code 1
