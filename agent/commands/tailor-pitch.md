---
description: Tailor a concise job application pitch from a company and job posting
---
Tailor a concise job application pitch from a company and job posting.

This command is an alias-style companion to `/pitch`; follow the same workflow and output rules.

## Inputs

Ask for anything not already provided:
- Company name
- Job posting content
- Platform: Work at a Startup, LinkedIn, cold email, application form, or other

## Sources

Read these files before generating:
- `~/notes/career/background.md` — required experience profile
- `~/notes/career/examples/successful-pitches.md` — optional examples; use only if it has real examples

If `~/notes/career/background.md` is missing, stop and ask the user for background details. Do not invent experience.

## Output rules

Generate one ready-to-send pitch.

Length: 150–250 words.
Tone: direct, specific, peer-to-peer; not a cover letter.

Do:
- Reference concrete company/product/role details from the posting
- Connect the role to specific background from `~/notes/career/background.md`
- Emphasize strongest matching experience: Wayfair checkout/cart/browse, fintech/payments, React/Next.js/TypeScript, GraphQL, Java microservices, observability, A/B testing, startup/co-founder ownership
- Use examples/phrasing from successful pitches only when relevant

Do not:
- Fabricate experience, metrics, or company research
- Use generic phrases like "I am writing to express my interest", "great fit", "passionate about", "synergy", or "leverage my skills"
- Add bullets in the pitch body unless the platform specifically calls for it
- Over-explain or exceed 250 words

## Suggested structure

```
Hi [Company] team,

[Opening hook connecting Chris's background to a concrete company/role need.]

[1–2 short paragraphs with relevant experience and proof points.]

[Company-specific closing: why this role/company specifically, tied to the posting.]

Happy to jump on a quick call if it seems like I'd be a good fit.

Christopher Cho
christopher.cho.dev@gmail.com | linkedin.com/in/chrischo360 | github.com/chrischo360
```

After outputting the pitch, ask:

"Does this feel right? Anything to adjust?"

If edits are requested, apply them surgically and re-output the complete pitch.
