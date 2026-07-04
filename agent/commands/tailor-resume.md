---
description: Generate a tailored LaTeX resume from a company and job description
---
Generate a tailored LaTeX resume for a specific job description.

Shared command for Pi, Claude, and Devin. Treat this file as the canonical workflow; do not copy agent-specific variants. Use native file-read/edit tools when available, and use the bash snippets only as fallbacks or for compilation.

Reads the best-matching base template from `~/notes/Resumes/Templates/`, incorporates JD keywords, selects relevant extra bullets, and writes a new `~/notes/Resumes/resume-<company>-<date>.tex`.

## Inputs

Ask the user for anything not already provided:
- Company name (used for output filename, e.g. `stripe`)
- Date for output filename, defaulting to today's date in `YYYY-MM-DD` format
- Job description (full text pasted inline, or fetched content if the user provides a URL and the agent can fetch it)

## Workflow

1. Confirm the inputs are available. If either company name or job description is missing, ask for it before continuing.

2. Select and read the base resume template, extra bullets pool, and experience profile in parallel:
   - List available templates in `~/notes/Resumes/Templates/`.
   - Choose the best-matching `.tex` template based on role emphasis:
     - Frontend/product/growth/design roles: `frontend_product_growth.tex`
     - AI/devtools/tooling roles: `ai_devtools_engineer.tex`
     - If no clear match exists, ask the user which template to use.
   - Read the selected template plus the support files using the agent's native read tool. If unavailable, use:
   ```bash
   cat ~/notes/Resumes/Templates/<selected-template>.tex
   cat ~/notes/Resumes/extra_bullets.md
   cat ~/notes/Career/background.md
   ```

3. Normalize the job description text before keyword extraction:
   - Replace smart quotes (`"` `"` `'` `'`) with straight equivalents
   - Replace em dashes (`—`) and en dashes (`–`) with hyphens
   - Replace non-breaking spaces with regular spaces
   - This ensures exact-string ATS terms like `co-design` are not missed due to hidden Unicode variants

4. Parse the job description into the following keyword categories. Be exhaustive — extract exact phrasing, not paraphrases:

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
   - Use this to weight which extra-bullets.md tags to prioritize in step 5

5. Generate the tailored resume by applying these rules (in order of priority):
   - Reorder bullets within each role to front-load the most JD-relevant ones
   - Incorporate **Category A action verbs** into bullet openings where accurate (e.g. if JD says "design and implement APIs", and a bullet describes doing that, start it with "Designed and implemented...")
   - Incorporate **Category B technical keywords** into existing bullets where accurate and natural (do not change meaning)
   - Use **Category E soft signals** to inform word choice — e.g. if JD emphasizes "cross-functional", ensure bullets that involve cross-team work use that framing
   - From extra-bullets.md, select bullets whose tags match the **Category F role emphasis**
   - Insert selected extra bullets, replacing the weakest existing bullets if a role already has 4+ bullets. **Weakest** = bullets with no tech keywords, vague outcomes, no measurable impact, or lowest relevance to the JD. Do not drop a strong bullet (specific metric, named technology, concrete outcome) in favor of keeping a filler one.
   - Update the Skills section to mirror exact terminology from **Category B** (e.g. if JD says "React.js" not "React", use that). Before adding a term, check for existing aliases and replace rather than append (e.g. if "React" is already listed, replace it with "React.js" — do not add both).
   - Do NOT fabricate experience, invent metrics, or add claims that aren't supported by the input content

   **Bullet visual-fit rules (enforce strictly):**
   - Target: bullets may render as 1 or 2 visual lines in the compiled PDF
   - A 2-line bullet is acceptable when the first line reaches near the right margin and the second line is substantial
   - Avoid bullets where the second line is only a few words; trim or rephrase those
   - Never allow bullets that wrap to 3+ visual lines
   - Prefer high-density, high-signal bullets over artificially short bullets
   - Do not trim a strong bullet solely because it exceeds a character-count threshold
   - Trim only when the bullet wraps poorly, has filler, or creates an orphan second line

6. Before writing the file, show a structured summary of planned changes and ask the user to confirm:
   - Which bullets were reordered or reworded (show before → after for any reworded bullets)
   - Which extra bullets were added (and which existing ones they replace, if any)
   - Which JD keywords were incorporated and where
   - Skills section changes (terms added, replaced, or removed)

   Wait for user approval before proceeding. If the user requests changes, apply them and re-summarize before writing.

7. Write output to `~/notes/Resumes/resume-<company>-<date>.tex`
   - Lowercase company name, hyphens for spaces, and use `YYYY-MM-DD` date format (e.g. `resume-stripe-2026-06-26.tex`, `resume-jane-street-2026-06-26.tex`)
   - Preserve all LaTeX formatting and escaping from the original (\%, \$, \&, etc.)
   - Keep \documentclass{resume} and all \begin/\end environments intact

8. Run a visual bullet-fit audit on the written file:
   - Compile the PDF before finalizing
   - Inspect each `\item` in the rendered PDF
   - Classify each bullet by rendered visual fit:
     - `OK`: 1 line
     - `OK-2`: 2 lines with good line usage; first line reaches near the right margin and second line is substantial
     - `ORPHAN`: 2 lines where the second line is only a few words
     - `TOO LONG`: 3+ lines
   - Print a compact audit table:

   | # | Role | Visual Fit | Status | Bullet |
   |---|---|---|---|---|
   | 1 | Wayfair | 1 line | OK | "Designed Java Spring Boot..." |
   | 2 | Wayfair | 2 lines | OK-2 | "Built a GraphQL preloading flow..." |
   | 3 | Wayfair | 3 lines | TOO LONG | "Led the full product lifecycle..." |

   - Trim every `TOO LONG` bullet
   - Rephrase every `ORPHAN` bullet to either fit on 1 line or use the second line meaningfully
   - Check rhythm: 2-line bullets are fine if they are high-signal and visually balanced
   - Recompile and re-audit after trims until all bullets are `OK` or `OK-2`
   - If PDF inspection is unavailable, use character count only as a fallback:
     - Do not automatically trim based on character count alone
     - Flag bullets under ~95 characters as likely `OK`
     - Flag bullets between ~96–135 characters as likely `OK-2`; review for orphan second lines
     - Flag bullets over ~135 characters as likely `TOO LONG`, but confirm visually if possible

9. Compile and move to the finished output location:
   ```bash
   cd ~/notes/Resumes && mkdir -p Finished/<company>-<date> && pdflatex resume-<company>-<date>.tex && mv resume-<company>-<date>.pdf Finished/<company>-<date>/Christopher_Cho_Resume.pdf && rm -f resume-<company>-<date>.{aux,log,out}
   ```
   - Output: `~/notes/Resumes/Finished/<company>-<date>/Christopher_Cho_Resume.pdf`
   - The `.tex` source stays at `~/notes/Resumes/resume-<company>-<date>.tex`
   - aux/log/out files are cleaned up automatically

10. Output a gap analysis table comparing the JD against the final resume. Run through all six keyword categories from step 4:

    | JD Term / Phrase | Category | Coverage | Notes |
    |---|---|---|---|
    | (exact JD phrase) | A/B/C/D/E/F | strong / partial / missing | where it appears, or why absent |

    - Cover all Category A action verbs, all Category B tech terms, all Category C required qualifications, all Category D preferred qualifications
    - Skip Category E (soft signals) and F (role emphasis) from the table — note them in a sentence below instead
    - Flag required qualification gaps (Category C) prominently
    - Do NOT suggest fabricating missing experience — only flag genuine gaps

    **Keyword density check:** After mapping coverage, scan the final resume for any Category B term appearing 4+ times. Flag it as potentially over-indexed — ATS systems can penalize keyword stuffing.

11. Output a fit score out of 100 using the following algorithm:

    **Signal 1 — Years of experience (20 points)**
    - Extract the JD's stated YOE requirement (e.g. "5+ years")
    - Compare against the candidate's total relevant YOE from the resume
    - Met or exceeded = 20 pts. 1 year short = 14 pts. 2 years short = 8 pts. 3+ years short = 2 pts.
    - If JD states no explicit YOE requirement, award 20 pts if the resume's seniority level clearly matches the role title

    **Signal 2 — Type of work alignment (40 points)**, broken into four sub-signals:
    - **Domain match (10 pts):** Does the candidate's industry/product domain overlap with the JD? (e.g. payments, devtools, identity, data). Full overlap = 10. Adjacent = 6. Unrelated = 2.
    - **Tech stack overlap (15 pts):** What % of the JD's required tech terms appear in the resume? 80%+ = 15. 60–79% = 11. 40–59% = 7. Below 40% = 3.
    - **Role type match (10 pts):** Does the candidate's shape match what the JD needs? (frontend / backend / fullstack / platform / infra / leadership). Exact match = 10. Adjacent = 6. Mismatched = 2.
    - **Scope match (5 pts):** Does the candidate's system scale and ownership level fit? (e.g. led a team, owned a product, built at scale). Strong match = 5. Partial = 3. Unclear = 1.

    **Signal 3 — Required qualifications met (Category C): 30 points**
    - Each required qualification is weighted equally. Deduct proportionally for each unmet one.
    - Partial credit (half) if the candidate has adjacent but not exact experience.

    **Signal 4 — Preferred qualifications met (Category D): 10 points**
    - Partial credit for partial matches. Don't over-penalize misses here.

    Show the breakdown table, then a final score:

    | Signal | Points Available | Points Earned | Notes |
    |---|---|---|---|
    | Years of experience | 20 | ... | ... |
    | Domain match | 10 | ... | ... |
    | Tech stack overlap | 15 | ... | ... |
    | Role type match | 10 | ... | ... |
    | Scope match | 5 | ... | ... |
    | Required qualifications (C) | 30 | ... | ... |
    | Preferred qualifications (D) | 10 | ... | ... |
    | **Total** | **100** | **...** | |

    Interpret the score:
    - 85–100: Strong match — apply with confidence
    - 70–84: Good match — minor gaps, worth applying
    - 55–69: Partial match — address gaps before applying
    - Below 55: Weak match — consider whether to pursue

12. Prompt the user to grow extra-bullets.md:
    - For each "missing" or "partial" gap identified in step 10, ask:
      "Do you have real experience with [term/skill] that isn't captured in the resume yet?"
    - If yes, ask them to describe it briefly, then offer a draft bullet pre-filled with the JD action verb and domain as a template (e.g. "Designed and implemented [X] for [Y], reducing [Z] by [N]%") — user fills in the specifics
    - Append confirmed bullets to ~/notes/Resumes/extra_bullets.md under the correct role section
    - This step is optional — user can skip any or all gaps

What this does:
- Maximizes ATS keyword match rate without fabricating experience
- Preserves accurate content — only reorders, rewords, and selects
- Selects the strongest subset of bullets for the target role
- Outputs a ready-to-compile .tex file

Agent compatibility:
- Pi discovers this from `~/.pi/agent/prompts/` via the shared symlink.
- Claude discovers this from `~/.claude/commands/global/` via the shared symlink.
- Devin can execute this by reading `~/dotfiles/agent/commands/tailor-resume.md` as the canonical command prompt.
- Keep the workflow tool-agnostic: prefer read/edit/write operations, reserve bash for listing files and compiling LaTeX.

Notes:
- Base resumes live in `~/notes/Resumes/Templates/`; select the best-matching `.tex` template for the JD.
- Output filename pattern: `Resumes/resume-<company>-<date>.tex`
- Extra bullets are auto-read from `~/notes/Resumes/extra_bullets.md` — no need to paste them
- Do not commit the output file
- If the JD mentions a technology already in the resume, ensure it appears in Skills even if not currently listed
