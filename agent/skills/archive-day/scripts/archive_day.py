#!/usr/bin/env python3
"""archive-day: Move uncompleted tasks between day sections in plan files."""

import sys
import re
import os
from datetime import datetime

WEEK_MD = os.path.expanduser("~/notes/plans/week.md")
PERSONAL_MD = os.path.expanduser("~/notes/plans/personal_week.md")

WORK_DAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
ALL_DAYS = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

WORK_NEXT = {
    "Monday": "Tuesday", "Tuesday": "Wednesday", "Wednesday": "Thursday",
    "Thursday": "Friday", "Friday": "Monday",
}
WORK_PREV = {
    "Monday": "Friday", "Tuesday": "Monday", "Wednesday": "Tuesday",
    "Thursday": "Wednesday", "Friday": "Thursday",
}
_cal_idx = {d: i for i, d in enumerate(ALL_DAYS)}
CAL_PREV = {d: ALL_DAYS[(_cal_idx[d] - 1) % 7] for d in ALL_DAYS}
CAL_NEXT = {d: ALL_DAYS[(_cal_idx[d] + 1) % 7] for d in ALL_DAYS}

PRIORITY_HEADERS = {
    "--- **Important** + **Urgent** ---",
    "--- Not Important + Urgent ---",
    "--- Important + Not Urgent ---",
    "--- Not Important + Not Urgent ---",
}


def die(msg):
    print(f"Error: {msg}", file=sys.stderr)
    sys.exit(1)


def parse_args():
    args = sys.argv[1:]
    src = tgt = None
    i = 0
    while i < len(args):
        if args[i] == "--from" and i + 1 < len(args):
            src = args[i + 1].capitalize()
            i += 2
        elif args[i] == "--to" and i + 1 < len(args):
            tgt = args[i + 1].capitalize()
            i += 2
        else:
            die(f"Unknown argument: {args[i]}")
    return src, tgt


def validate_explicit_days(ex_src, ex_tgt):
    if ex_src and ex_src not in ALL_DAYS:
        die(f"Invalid day: {ex_src}. Use Sunday-Saturday")
    if ex_tgt and ex_tgt not in ALL_DAYS:
        die(f"Invalid day: {ex_tgt}. Use Sunday-Saturday")


def resolve_for_file(ex_src, ex_tgt, file_type, today, hour):
    """Return (source, target) or None if the file should be skipped."""
    valid_days = WORK_DAYS if file_type == "work" else ALL_DAYS

    if file_type == "work":
        if today in WORK_DAYS:
            def_src, def_tgt = (
                (WORK_PREV[today], today) if hour < 15 else (today, WORK_NEXT[today])
            )
        else:
            def_src, def_tgt = None, None
    else:  # personal
        def_src, def_tgt = (
            (CAL_PREV[today], today) if hour < 15 else (today, CAL_NEXT[today])
        )

    src = ex_src if ex_src else def_src
    tgt = ex_tgt if ex_tgt else def_tgt

    if src is None or tgt is None:
        return None
    if src not in valid_days or tgt not in valid_days:
        return None
    return src, tgt


# ── Task / line helpers ───────────────────────────────────────────────────────

def get_indent(line):
    return len(line) - len(line.lstrip())


def is_task(line):
    s = line.lstrip()
    return s.startswith("- [ ]") or s.startswith("- [x]")


def is_uncompleted(line):
    return line.lstrip().startswith("- [ ]")


def is_completed(line):
    return line.lstrip().startswith("- [x]")


def mark_done(line):
    return line.replace("- [ ]", "- [x]", 1)


def is_priority_header(line):
    return line.strip() in PRIORITY_HEADERS


def is_category_header(line):
    return bool(re.match(r"^###\s+\S", line))


def is_section_boundary(line):
    """True for h1 or h2 headers only (not h3+)."""
    return bool(re.match(r"^# ", line) or re.match(r"^## ", line))


# ── Section finding ───────────────────────────────────────────────────────────

def find_all_sections(lines, day):
    """Return list of (start, end) for all '## day' sections (end exclusive)."""
    hdr = f"## {day}"
    sections = []
    i = 0
    while i < len(lines):
        if lines[i].rstrip() == hdr:
            start = i
            end = len(lines)
            for j in range(start + 1, len(lines)):
                if is_section_boundary(lines[j]):
                    end = j
                    break
            sections.append((start, end))
            i = end
        else:
            i += 1
    return sections


# ── Block parsing ─────────────────────────────────────────────────────────────

def parse_blocks(section_lines):
    """
    Parse section lines into typed blocks.
    block = (kind, lines, priority_ctx, category_ctx)
    kind: 'header' | 'priority' | 'category' | 'task' | 'blank' | 'other'
    """
    blocks = []
    cur_priority = None
    cur_category = None
    n = len(section_lines)
    i = 0

    while i < n:
        line = section_lines[i]

        if i == 0 and re.match(r"^## ", line):
            blocks.append(("header", [line], None, None))
            i += 1
            continue

        if not line.strip():
            blocks.append(("blank", [line], cur_priority, cur_category))
            i += 1
            continue

        if is_priority_header(line):
            cur_priority = line.strip()
            cur_category = None
            blocks.append(("priority", [line], cur_priority, None))
            i += 1
            continue

        if is_category_header(line):
            cur_category = line.strip()
            blocks.append(("category", [line], cur_priority, cur_category))
            i += 1
            continue

        if is_task(line) and get_indent(line) == 0:
            task_lines = [line]
            j = i + 1
            while j < n:
                nxt = section_lines[j]
                stops = (
                    is_priority_header(nxt)
                    or is_category_header(nxt)
                    or (is_task(nxt) and get_indent(nxt) == 0)
                )
                if nxt.strip() and stops:
                    break
                if not nxt.strip():
                    peek = j + 1
                    while peek < n and not section_lines[peek].strip():
                        peek += 1
                    if (
                        peek < n
                        and get_indent(section_lines[peek]) > 0
                        and not is_priority_header(section_lines[peek])
                        and not is_category_header(section_lines[peek])
                    ):
                        task_lines.append(nxt)
                        j += 1
                        continue
                    break
                task_lines.append(nxt)
                j += 1
            blocks.append(("task", task_lines, cur_priority, cur_category))
            i = j
            continue

        blocks.append(("other", [line], cur_priority, cur_category))
        i += 1

    return blocks


def blocks_to_lines(blocks):
    out = []
    for b in blocks:
        out.extend(b[1])
    return out


# ── Task splitting ────────────────────────────────────────────────────────────

def split_block(block_lines):
    """Return (keep_in_source, move_to_target). Either may be empty."""
    parent = block_lines[0]
    children = block_lines[1:]
    child_tasks = [l for l in children if is_task(l)]

    if not child_tasks:
        if is_uncompleted(parent):
            return [], list(block_lines)
        return list(block_lines), []

    if is_completed(parent):
        return list(block_lines), []

    uncompleted_kids = [l for l in child_tasks if is_uncompleted(l)]

    if not uncompleted_kids:
        return [], list(block_lines)

    # Mixed children: split
    completed_kids = [l for l in child_tasks if is_completed(l)]
    kept_children = [l for l in children if not is_task(l) or is_completed(l)]
    while kept_children and not kept_children[-1].strip():
        kept_children.pop()

    source_keep = ([mark_done(parent)] + kept_children) if completed_kids else []
    target_move = [parent] + uncompleted_kids
    return source_keep, target_move


# ── Target insertion ──────────────────────────────────────────────────────────

def insert_tasks_into_target(tgt_blocks, tasks_by_ctx):
    """
    Append moved tasks into target, respecting priority and category context.
    tasks_by_ctx: {(priority, category): [task_line_lists]}
    """
    result = list(tgt_blocks)

    for (priority, category), task_groups in tasks_by_ctx.items():
        inserted = False

        if priority is not None:
            pri_idx = next(
                (i for i, b in enumerate(result)
                 if b[0] == "priority" and b[1][0].strip() == priority),
                None,
            )
            if pri_idx is not None:
                sec_end = len(result)
                for i in range(pri_idx + 1, len(result)):
                    if result[i][0] == "priority":
                        sec_end = i
                        break

                cat_idx = None
                if category is not None:
                    cat_idx = next(
                        (i for i in range(pri_idx + 1, sec_end)
                         if result[i][0] == "category"
                         and result[i][1][0].strip() == category),
                        None,
                    )

                if cat_idx is not None:
                    insert_before = sec_end
                    for i in range(cat_idx + 1, sec_end):
                        if result[i][0] == "category":
                            insert_before = i
                            break
                    while insert_before > cat_idx + 1 and result[insert_before - 1][0] == "blank":
                        insert_before -= 1
                else:
                    insert_before = sec_end
                    while insert_before > pri_idx + 1 and result[insert_before - 1][0] == "blank":
                        insert_before -= 1

                new_blocks = [("task", tl, priority, category) for tl in task_groups]
                result = result[:insert_before] + new_blocks + result[insert_before:]
                inserted = True

        if not inserted and category is not None:
            cat_idx = next(
                (i for i, b in enumerate(result)
                 if b[0] == "category" and b[1][0].strip() == category),
                None,
            )
            if cat_idx is not None:
                insert_before = len(result)
                for i in range(cat_idx + 1, len(result)):
                    if result[i][0] in ("category", "priority"):
                        insert_before = i
                        break
                while insert_before > cat_idx + 1 and result[insert_before - 1][0] == "blank":
                    insert_before -= 1
                new_blocks = [("task", tl, priority, category) for tl in task_groups]
                result = result[:insert_before] + new_blocks + result[insert_before:]
                inserted = True

        if not inserted:
            while result and result[-1][0] == "blank":
                result.pop()
            for tl in task_groups:
                result.append(("task", tl, priority, category))

    return result


# ── File processing ───────────────────────────────────────────────────────────

def process_file(filepath, source, target):
    """
    Move uncompleted tasks from source day(s) to target day.
    Returns moved_count. Raises ValueError on structural errors.
    """
    fname = os.path.basename(filepath)

    with open(filepath) as f:
        content = f.read()

    lines = content.split("\n")

    src_sections = find_all_sections(lines, source)
    tgt_sections = find_all_sections(lines, target)

    if not src_sections:
        raise ValueError(f"Source day {source} not found in {fname}")
    if not tgt_sections:
        raise ValueError(f"Target day {target} not found in {fname}")

    tgt_start, tgt_end = tgt_sections[-1]

    tasks_by_ctx = {}
    moved_count = 0
    replacements = {}  # start → (end, new_lines)

    for src_start, src_end in src_sections:
        src_blocks = parse_blocks(lines[src_start:src_end])
        new_src_blocks = []

        for block in src_blocks:
            kind, content_lines, priority, category = block
            if kind == "task":
                keep, move = split_block(content_lines)
                if move:
                    moved_count += 1
                    ctx = (priority, category)
                    tasks_by_ctx.setdefault(ctx, []).append(move)
                if keep:
                    new_src_blocks.append((kind, keep, priority, category))
            else:
                new_src_blocks.append(block)

        new_src_lines = blocks_to_lines(new_src_blocks)
        if new_src_lines and new_src_lines[-1].strip():
            new_src_lines.append("")
        replacements[src_start] = (src_end, new_src_lines)

    if moved_count == 0:
        return 0

    tgt_blocks = parse_blocks(lines[tgt_start:tgt_end])
    new_tgt_blocks = insert_tasks_into_target(tgt_blocks, tasks_by_ctx)
    new_tgt_lines = blocks_to_lines(new_tgt_blocks)
    if new_tgt_lines and new_tgt_lines[-1].strip():
        new_tgt_lines.append("")
    replacements[tgt_start] = (tgt_end, new_tgt_lines)

    new_lines = list(lines)
    for start in sorted(replacements.keys(), reverse=True):
        end, repl = replacements[start]
        new_lines = new_lines[:start] + repl + new_lines[end:]

    with open(filepath, "w") as f:
        f.write("\n".join(new_lines))

    return moved_count


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    ex_src, ex_tgt = parse_args()
    validate_explicit_days(ex_src, ex_tgt)

    now = datetime.now()
    today = now.strftime("%A")
    hour = now.hour

    work_days = resolve_for_file(ex_src, ex_tgt, "work", today, hour)
    personal_days = resolve_for_file(ex_src, ex_tgt, "personal", today, hour)

    work_eligible = work_days is not None and os.path.exists(WEEK_MD)
    personal_eligible = personal_days is not None and os.path.exists(PERSONAL_MD)

    if not work_eligible and not personal_eligible:
        if not os.path.exists(WEEK_MD) and not os.path.exists(PERSONAL_MD):
            die("No plan files found")
        die("No eligible files for the given day combination")

    if work_eligible and work_days[0] == work_days[1]:
        die("Source and target must be different days")
    if personal_eligible and personal_days[0] == personal_days[1]:
        die("Source and target must be different days")

    for eligible, filepath, days, label in [
        (work_eligible, WEEK_MD, work_days, "week.md"),
        (personal_eligible, PERSONAL_MD, personal_days, "personal_week.md"),
    ]:
        if not eligible:
            continue
        source, target = days
        try:
            count = process_file(filepath, source, target)
            if count > 0:
                noun = "task" if count == 1 else "tasks"
                print(f"{label}: Moved {count} uncompleted {noun} from {source} to {target}")
            else:
                print(f"{label}: No uncompleted tasks in {source}")
        except ValueError as e:
            print(f"Error ({label}): {e}", file=sys.stderr)


if __name__ == "__main__":
    main()
