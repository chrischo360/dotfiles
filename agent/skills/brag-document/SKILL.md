---
name: brag-document
description: Record weekly accomplishments into a running brag document at ~/notes/plans/brag_document.md. Translates completed tickets and work from the weekly plan into clear, promotable, interview-ready entries. Use when Chris asks to update the brag doc, log wins, record accomplishments, or do a weekly reflection.
metadata:
  source: local://dotfiles/agent/skills/brag-document
---

# brag-document

Help Chris maintain a running record of accomplishments that is useful for performance reviews, promotion cases, and interview prep.

Use this skill when:
- Chris asks to update the brag doc, log wins, or record accomplishments.
- Chris asks what he shipped or did this week.
- Chris runs `/brag` or says "add to brag doc."
- Chris says "weekly reflection" or "log this week."

## Brag document location

```txt
~/notes/plans/brag_document.md
```

Create the file with a header if it does not exist:

```md
# Brag Document

A running log of accomplishments, shipped work, and growth. Used for performance reviews, promotion cases, and interviews.

---
```

## Entry format

Each entry is reverse-chronological (newest at top, after the header).

```md
## Week <N> — <Month DD, YYYY>

### Shipped
- **[TICKET-ID]** Short description of what was completed and what it does. Impact if known.
- ...

### In Flight
- **[TICKET-ID]** What is actively in progress.
- ...

### Collaboration & Influence
- Reviewed PRs from / gave feedback to ...
- Partnered with [person/team] on ...
- Unblocked [person] on ...
- ...

### Growth & Learning
- ...

### Notes / Impact
Freeform notes about why this work matters — performance, reliability, architecture, user impact, business context.
```

Only include sections that have real content. Omit empty sections.

## Workflow

### Step 1 — Read the weekly plan

Read `~/notes/plans/week.md` for:
- Completed tasks (`- [x]`).
- In-progress tasks (`- [ ]` with subtasks started).
- Ticket IDs (e.g., `[PGL-1754]`).
- Any notes about deployment, reviews, or collaboration.

If Chris says "last week" or the current week is sparse, also check the most recent file in `~/notes/plans/archive/` to find the prior week.

### Step 2 — Ask for missing context (briefly)

Ask at most 2 questions if important context is missing:
- "Was anything deployed to production this week?"
- "Any notable collaboration or code reviews worth logging?"

Do not ask if context is clearly present in the notes.

### Step 3 — Draft the entry

Translate raw task descriptions into clear, human-readable accomplishments.

**Good:**
> **[PGL-1754]** Lazy-loaded `@wayfair/sf-loyalty-enrollment` on browse pages, reducing initial bundle weight for rewards members.

**Bad:**
> Done the lazy load ticket.

Tips:
- Lead with what changed, not what was done ("shipped X" not "worked on X").
- Add impact when known: performance win, user coverage, unblocking another team.
- Use ticket IDs for traceability.
- Keep bullets concise — one sentence each.
- Promotion-relevant signals to watch for:
  - Performance improvements (bundle size, latency, load time).
  - Architecture decisions (configurability, signal systems, schema design).
  - Reliability/safety (fallbacks, error handling, observability).
  - Cross-team collaboration or influence.
  - Mentorship or unblocking others.
  - Self-directed technical bets (prefetch, lazy load, new patterns).

### Step 4 — Write the entry

Prepend the new entry into `~/notes/plans/brag_document.md` below the file header (above any existing entries).

Preserve all existing entries exactly as written.

### Step 5 — Confirm

Tell Chris:
- What was logged.
- Any accomplishments that look strong for promotion or interviews.
- If anything looks worth expanding later into a case study (connect to `/project-case-study` skill).

## Promotion context

Chris is building a promotion case. When logging entries, note in the `### Notes / Impact` section when work demonstrates:

- **Technical judgment** — architectural decisions, new patterns, avoiding bad patterns.
- **Scope and autonomy** — self-directed work, leading features.
- **Impact** — measurable user, product, or team outcomes.
- **Collaboration and influence** — affecting other engineers, code reviews, partnering cross-team.
- **Reliability** — production safety, observability, handling edge cases.
- **Growth** — picking up unfamiliar systems, self-teaching, new responsibilities.

Promotion plan document for context (read when relevant):

```txt
~/notes/plans/promotion_summer_2026/plan.md
```

## Tone

- Direct and confident.
- Credit the work accurately — not undersell, not oversell.
- Write as if this will be read by a manager and a senior engineer doing a promo review.
- No fluff or hedging phrases like "helped with" or "assisted in" unless truly accurate.
- Use "shipped," "implemented," "reduced," "unblocked," "designed," "refactored" over weak verbs.

## Output behavior

1. Read the weekly plan and any relevant context.
2. Draft the brag entry without asking unnecessary questions.
3. Write the entry to `~/notes/plans/brag_document.md`.
4. Show Chris the drafted entry in the response.
5. Note any entries worth turning into a case study later.
