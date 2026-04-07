Generate a tailored LaTeX resume for a specific job description.

Reads ~/notes/resumes/resume.tex as the base, incorporates JD keywords, selects
relevant extra bullets, and writes a new ~/notes/resumes/resume-<company>.tex.

Steps:

1. Ask the user for the following if not already provided:
   - Company name (used for output filename, e.g. "stripe" → resume-stripe.tex)
   - Job description (full text, pasted inline)

2. Read the base resume and extra bullets pool in parallel:
   ```bash
   cat ~/notes/resumes/resume.tex
   ```
   ```bash
   cat ~/notes/resumes/extra-bullets.md
   ```

3. Parse the job description into the following keyword categories. Be exhaustive — extract exact phrasing, not paraphrases:

   **A. Action verbs from responsibilities** (these signal what the role *does* day-to-day)
   - Extract every verb or verb phrase from the Responsibilities section
   - Examples: "design and implement", "ship", "advocate for", "write architecture briefs", "carry out experiments"
   - These should appear in resume bullet *beginnings* where accurate

   **B. Technical keywords** (exact strings — ATS matches literally)
   - Programming languages (note exact casing: "React.js" not "React", "Node.js" not "Node")
   - Frameworks, libraries, platforms, tools
   - Architectural patterns: "federated", "microservices", "REST", "GraphQL", "CI/CD pipelines"
   - Domain-specific terms: "identity", "auth", "payments", "distributed systems", "planetary scale"

   **C. Required qualifications** (must cover — flag if missing)
   - List each required qualification as a discrete item
   - Note which are satisfied by experience vs. education vs. missing entirely

   **D. Preferred qualifications** (nice to cover — flag if missing but don't over-weight)
   - List each preferred qualification as a discrete item

   **E. Soft signals** (culture/collaboration language — cannot go in bullets, but inform tone)
   - Examples: "cross-functional", "distributed team", "written and verbal communication", "healthy team culture"
   - Note these separately — they inform word choice in bullets but shouldn't be fabricated as skills

   **F. Role emphasis classification**
   - Primary: frontend / backend / fullstack / platform / infra / leadership
   - Domain: identity/auth / payments / devtools / data / etc.
   - Use this to weight which extra-bullets.md tags to prioritize in step 4

4. Generate the tailored resume by applying these rules (in order of priority):
   - Reorder bullets within each role to front-load the most JD-relevant ones
   - Incorporate **Category A action verbs** into bullet openings where accurate (e.g. if JD says "design and implement APIs", and a bullet describes doing that, start it with "Designed and implemented...")
   - Incorporate **Category B technical keywords** into existing bullets where accurate and natural (do not change meaning)
   - Use **Category E soft signals** to inform word choice — e.g. if JD emphasizes "cross-functional", ensure bullets that involve cross-team work use that framing
   - From extra-bullets.md, select bullets whose tags match the **Category F role emphasis**
   - Insert selected extra bullets, replacing the weakest existing bullets if a role already has 4+ bullets
   - Update the Skills section to mirror exact terminology from **Category B** (e.g. if JD says "React.js" not "React", use that)
   - Do NOT fabricate experience, invent metrics, or add claims that aren't supported by the input content

   **Bullet length rules (enforce strictly):**
   - Target: 1 line (~85 characters). Maximum: 2 lines (~140 characters)
   - If a bullet exceeds 140 characters, trim it: cut filler phrases, collapse redundant detail, or split into two separate bullets if both halves are strong enough to stand alone
   - Prefer a tight 1-line bullet over a padded 2-line one
   - After ordering bullets within a role, check that adjacent bullet lengths are varied — avoid 3+ consecutive long bullets, which makes the section feel dense

5. Before writing, briefly summarize what changes you made:
   - Which bullets were reordered or reworded
   - Which extra bullets were added (and which existing ones were replaced, if any)
   - Which JD keywords were incorporated and where

6. Write output to ~/notes/resumes/resume-<company>.tex
   - Lowercase company name, hyphens for spaces (e.g. resume-stripe.tex, resume-jane-street.tex)
   - Preserve all LaTeX formatting and escaping from the original (\%, \$, \&, etc.)
   - Keep \documentclass{resume} and all \begin/\end environments intact

7. Confirm the file was written, then compile and move to the finished output location:
   ```bash
   cd ~/notes/resumes && mkdir -p finished/<company> && pdflatex resume-<company>.tex && mv resume-<company>.pdf finished/<company>/Christopher_Cho_Resume.pdf && rm -f resume-<company>.{aux,log,out}
   ```
   - Output: `~/notes/resumes/finished/<company>/Christopher_Cho_Resume.pdf`
   - The `.tex` source stays at `~/notes/resumes/resume-<company>.tex`
   - aux/log/out files are cleaned up automatically

7.5. Run a bullet length audit on the written file. For every `\item` line:
   - Count characters (excluding the `\item ` prefix and LaTeX escape sequences like `\%`, `\$`)
   - Flag any bullet over 140 characters as **TOO LONG** — trim it before continuing
   - Flag any bullet over 85 characters as **2-line** — acceptable but note it
   - Print a compact audit table:

   | # | Role | Length | Status | Bullet (truncated) |
   |---|---|---|---|---|
   | 1 | Wayfair | 105 | 2-line | "Responded to production incidents..." |
   | 2 | Wayfair | 175 | TOO LONG | "Built an agentic developer toolchain..." |

   - For any TOO LONG bullets: trim inline (remove filler, collapse redundant detail) and update the file
   - Check rhythm: flag if 3+ consecutive bullets are all 2-line length (dense sections read poorly)
   - Re-audit after any trims until all bullets pass

8. Output a gap analysis table comparing the JD against the final resume. Run through all six keyword categories from step 3:

   | JD Term / Phrase | Category | Coverage | Notes |
   |---|---|---|---|
   | (exact JD phrase) | A/B/C/D/E/F | strong / partial / missing | where it appears, or why absent |

   - Cover all Category A action verbs, all Category B tech terms, all Category C required qualifications, all Category D preferred qualifications
   - Skip Category E (soft signals) and F (role emphasis) from the table — note them in a sentence below instead
   - Flag required qualification gaps (Category C) prominently
   - Do NOT suggest fabricating missing experience — only flag genuine gaps

9. Prompt the user to grow extra-bullets.md:
   - For each "missing" or "partial" gap identified in step 8, ask:
     "Do you have real experience with [term/skill] that isn't captured in the resume yet?"
   - If yes, ask them to describe it briefly, then offer a draft bullet with appropriate tags
   - Append confirmed bullets to ~/notes/resumes/extra-bullets.md under the correct role section
   - This step is optional — user can skip any or all gaps

What this does:
- Maximizes ATS keyword match rate without fabricating experience
- Preserves accurate content — only reorders, rewords, and selects
- Selects the strongest subset of bullets for the target role
- Outputs a ready-to-compile .tex file

Notes:
- Base resume is always ~/notes/resumes/resume.tex
- Output filename pattern: resumes/resume-<company>.tex
- Extra bullets are auto-read from ~/notes/resumes/extra-bullets.md — no need to paste them
- Do not commit the output file
- If the JD mentions a technology already in the resume, ensure it appears in Skills even if not currently listed
