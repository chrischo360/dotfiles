---
name: answer-app-questions
description: Answer job application questions in a human writing style, drawing from a personal Q&A bank. Use when Chris asks to answer application questions, cover letter prompts, or "why this company/role" fields for a job application.
---

# answer-app-questions

Answer written job application questions grounded in real experience, using a personal Q&A bank and style guide to avoid generic AI-sounding writing.

## Inputs

If not already provided, ask for:
- Company name
- The question(s) to answer (paste them)
- Job description (optional but improves customization)
- Answer length target: short (150-300w), long (400-600w), or one-liner (50-100w)

## Context to read (in parallel)

```bash
cat ~/notes/resumes/app-questions.md
```
```bash
cat ~/notes/resumes/resume-forus-2026-07-14.tex  # most recent resume
```

If the most recent resume file doesn't exist, check `ls ~/notes/resumes/` and use the newest `.tex` file.

## Question categories

Classify each question before answering:

| Category | Triggers |
|---|---|
| **why-company** | "Why [Company]?", "Why do you want to work here?" |
| **why-role** | "Why this role?", "Why software engineering?" |
| **background** | "Tell me about yourself", "Walk me through your resume" |
| **strength** | "Greatest strength?", "What do you bring?" |
| **weakness** | "Greatest weakness?", "Challenge you faced?" |
| **goals** | "Where do you see yourself in 5 years?", "Career goals?" |
| **motivation** | "What excites you about this?", "Why are you leaving?" |
| **behavioral** | "Tell me about a time when..." |
| **other** | Anything else |

## Drafting rules

**If a matching entry exists in app-questions.md:**
- Pull the draft from the bank
- Customize for this company and JD:
  - Replace `[COMPANY]` placeholders
  - Add 1-2 specific JD details (mission, product, tech stack, stage)
  - Adjust tone if needed
- Do NOT wholesale rewrite — preserve the human voice

**If no matching entry exists:**
- Draft from scratch using resume for factual grounding
- Follow the Style Guide in app-questions.md exactly
- Flag it as a new answer and ask if user wants to save it

**For why-company specifically:**
- Always pull 1-2 concrete details from the JD (not generic praise)
- Anchor to: product area, stated mission, technical challenge, company stage
- Never write "I've always admired [Company]"

**For behavioral questions:**
- Use STAR in flowing prose — do not label sections
- Situation: 1-2 sentences
- Action: this is the meat — specific steps, thinking, decisions
- Result: concrete outcome with metric if possible
- Close with what you learned or would do differently

## Human style checklist

Before outputting each answer, verify:
- [ ] Opens with something specific (not "I have always been passionate about...")
- [ ] Varied sentence rhythm (not all same length)
- [ ] At least one concrete detail (metric, tech name, outcome)
- [ ] Avoids all banned phrases from the Style Guide
- [ ] Sounds like something you'd actually say, not a college application
- [ ] Correct length target

Rewrite any section that fails a check before outputting.

## Output format

For each question:

```
---
Q: [question text]
Category: [category]
Source: [from bank / drafted fresh]
Length: [word count]

[answer text]
---
```

Then ask: "Does this feel right? Any details to adjust?"

## Saving answers

After user approves:
- **From bank:** Ask if they want to save the company-specific version under "Company-Specific Answers" in app-questions.md
- **Drafted fresh:** Ask if they want to save it as a new canonical entry
- If saving, ask for any raw notes (informal thoughts behind the answer)
- Append to `~/notes/resumes/app-questions.md` in the correct section:

```markdown
### Q: [question text]
**Raw notes:** [user's informal notes, or "n/a"]
**Draft:** [approved answer text]
**Tags:** [relevant tags]
```

## Growing the bank

After each session, note which question types have no saved entry yet and ask:
"These question types have no saved answers yet: [list]. Want to draft them proactively?"

## Hard rules

- Do not fabricate experiences — only draw from what's in the resume or what the user provides as raw notes
- If the user provides raw notes about an experience not in the resume, use them but flag that the resume doesn't capture it yet
- Answers are for written application fields, not interview coaching
