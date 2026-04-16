Answer job application questions in a human writing style, drawing from a personal Q&A bank.

Reads ~/notes/resumes/app-questions.md for existing answers and style guide.
Reads ~/notes/resumes/resume.tex for experience context.
Outputs polished answers and optionally saves new ones to the bank.

Steps:

1. If not already provided, ask the user for:
   - Company name
   - The question(s) to answer (paste them — can be one or multiple)
   - Job description (optional but improves customization — can be the same JD used for /tailor-resume)
   - Answer length target: short (150-300w), long (400-600w), or one-liner (50-100w)

2. Read context in parallel:
   ```bash
   cat ~/notes/resumes/app-questions.md
   ```
   ```bash
   cat ~/notes/resumes/resume.tex
   ```

3. For each question, classify it into one of these categories:
   - **why-company** — "Why [Company]?", "Why do you want to work here?"
   - **why-role** — "Why this role?", "Why software engineering?"
   - **background** — "Tell me about yourself", "Walk me through your resume"
   - **strength** — "Greatest strength?", "What do you bring?"
   - **weakness** — "Greatest weakness?", "Challenge you faced?"
   - **goals** — "Where do you see yourself in 5 years?", "Career goals?"
   - **motivation** — "What excites you about this?", "Why are you leaving your current role?"
   - **behavioral** — "Tell me about a time when...", STAR-format questions
   - **other** — anything that doesn't fit above

4. For each question:

   **If a matching entry exists in app-questions.md:**
   - Pull the draft from the bank
   - Customize it for this specific company and JD:
     - Replace [COMPANY] placeholders with the actual company name
     - Incorporate 1-2 specific details from the JD (mission, product, tech stack, scale)
     - Adjust tone if needed (e.g., mission-driven company vs. pure tech startup)
   - Do NOT wholesale rewrite — preserve the human voice in the draft

   **If no matching entry exists:**
   - Draft from scratch using resume.tex for factual grounding
   - Follow the Style Guide from app-questions.md exactly:
     - Open with a specific moment or detail, never a generic opener
     - Vary sentence length for rhythm
     - Use one concrete anecdote where possible
     - End with forward momentum
     - Avoid the banned phrases listed in the Style Guide
   - After drafting, note that this is a new answer and ask if user wants to save it

5. For **why-company** questions specifically:
   - Always pull 1-2 concrete details from the JD (not generic praise)
   - Examples: specific product area, a stated mission, a technical challenge mentioned, the company stage
   - If JD mentions AI/ML integration, autonomy, scale — use those as hooks
   - Never write "I've always admired [Company]" — anchor to something real

6. For **behavioral** questions (Tell me about a time when...):
   - Use STAR structure but don't label the sections — write in flowing prose
   - Situation: 1-2 sentences to set context (don't over-explain)
   - Task: embed in the situation, don't separate
   - Action: this is the meat — specific steps, your thinking, your decisions
   - Result: concrete outcome with metric if possible
   - End with what you learned or would do differently

7. Output format:
   For each question, output:
   ```
   ---
   Q: [question text]
   Category: [category]
   Source: [from bank / drafted fresh]
   Length: [word count]

   [answer text]
   ---
   ```

   Then ask: "Does this answer feel right? Any details to adjust?"

8. Human style self-check before outputting — run through this checklist mentally for each answer:
   - [ ] Does it open with something specific (not "I have always been passionate about...")?
   - [ ] Does it have varied sentence rhythm (not all the same length)?
   - [ ] Does it include at least one concrete detail (metric, tech name, company name, outcome)?
   - [ ] Does it avoid the banned phrases from the Style Guide?
   - [ ] Does it sound like something you'd actually say, not something you'd submit to a college application?
   - [ ] Is it the right length?
   If any check fails, rewrite that part before outputting.

9. After user approves an answer:
   - If it came from the bank: ask if they want to save the company-specific version under "Company-Specific Answers" in app-questions.md
   - If it was drafted fresh: ask if they want to save it as a new canonical entry in the bank
   - If saving: ask for any "raw notes" to add (the user's informal thoughts behind the answer)
   - Append to ~/notes/resumes/app-questions.md in the correct section with proper format:
     ```markdown
     ### Q: [question text]
     **Raw notes:** [user's informal notes, or "n/a"]
     **Draft:** [approved answer text]
     **Tags:** [relevant tags]
     ```

10. Growing the bank over time:
    - After each session, note which question types are still uncovered (no bank entry)
    - Suggest: "These question types have no saved answers yet: [list]. Want to draft them proactively?"
    - This primes the bank before applications ask them

What this does:
- Answers sound human because they're grounded in real specifics and follow an explicit anti-AI-writing style guide
- Bank improves over time — each approved answer becomes a reusable base
- Company customization is surgical (1-2 specific hooks) not a full rewrite
- Behavioral answers use STAR in prose, not labeled bullets

Notes:
- Bank file: ~/notes/resumes/app-questions.md
- Resume file: ~/notes/resumes/resume.tex (for factual grounding)
- Do not fabricate experiences — only draw from what's in the resume or what the user provides as raw notes
- If the user provides new raw notes about an experience not in the resume, use them for the answer but flag that the resume doesn't capture it yet
- Answers are for written application fields, not interview coaching (different skill)
