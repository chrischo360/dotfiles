Batch match job application URLs to existing resume variants, generate tailored LaTeX resumes, and compile PDFs into `~/notes/resumes/finished/<company>/`.

Input:
- A pasted list of jobs, one per line:
  ```text
  Company | Role | URL
  Company | URL
  ```
- Or a CSV/Markdown file path with company, role, and URL.

Read first:
- `~/notes/resumes/resume-patterns.md`
- `~/notes/resumes/bullet-bank.yml`
- `~/notes/resumes/application-results.csv`
- `~/notes/resumes/variants/*.tex`
- `~/dotfiles/claude/commands/notes/match-resume.md`
- `~/dotfiles/claude/commands/notes/tailor-resume.md`

Workflow:

0. Parallelization rule.
   - If the input contains multiple jobs, use one subagent per job URL.
   - Each subagent owns exactly one company/role/URL and writes only inside that job's generated directory plus the final `~/notes/resumes/resume-<slug>.tex`.
   - The parent agent prepares the batch directory first, launches subagents, then compiles all finished sources after subagents complete.
   - If subagents are unavailable, process jobs sequentially and state that parallel execution was unavailable.

1. Parse the job list.
   - Normalize company slugs with lowercase hyphens.
   - Create a queue under `~/notes/resumes/generated/batch-YYYY-MM-DD/`.
   - For each job, create:
     ```text
     ~/notes/resumes/generated/batch-YYYY-MM-DD/<slug>/job.md
     ~/notes/resumes/generated/batch-YYYY-MM-DD/<slug>/match-summary.md
     ~/notes/resumes/generated/batch-YYYY-MM-DD/<slug>/resume.tex
     ```

2. Fetch each job description.
   - For multiple jobs, perform this step inside each job subagent.
   - Use the available Brave/browser/web extension if present.
   - If a page cannot be fetched, fall back to `/tailor-resume` only when the user supplied enough job text in the input line or follow-up prompt.
   - If no JD text is available, write the fetch failure to `job.md`, ask the user to paste the JD, and skip final generation for that job until the JD is provided.
   - Do not guess job requirements from the URL alone.

3. For each fetched JD, classify the role using `/match-resume` rules.
   - For multiple jobs, perform this step inside each job subagent.
   - Choose exactly one primary variant:
     - `full-stack`
     - `backend-platform`
     - `frontend-product`
     - `ai-devtools`
     - `startup-product`
   - Write the classification and chosen base resume to `match-summary.md`.

4. Generate the tailored resume.
   - For multiple jobs, perform this step inside each job subagent.
   - Start from the selected variant, not always `resume.tex`.
   - Reuse `/tailor-resume` rules for keyword extraction, bullet ordering, skill mirroring, and no fabrication.
   - Use `bullet-bank.yml` for 2-4 targeted bullet swaps.
   - Preserve LaTeX syntax and escaping.
   - Write the generated source to both:
     ```text
     ~/notes/resumes/generated/batch-YYYY-MM-DD/<slug>/resume.tex
     ~/notes/resumes/resume-<slug>.tex
     ```

5. Compile each resume.
   - Parent agent only: run compilation after all job subagents finish.
   ```bash
   cd ~/notes/resumes && mkdir -p finished/<slug> && pdflatex resume-<slug>.tex && mv resume-<slug>.pdf finished/<slug>/Christopher_Cho_Resume.pdf && rm -f resume-<slug>.{aux,log,out}
   ```

6. Update application tracking.
   - Append or update `~/notes/resumes/application-results.csv` with:
     - company
     - slug
     - resume_path
     - finished_pdf
     - role
     - url
     - applied_date blank unless provided
     - outcome `unknown`
     - notes `batch generated`

7. Output a compact summary table:

```md
| Company | Variant | PDF | Status |
|---|---|---|---|
| Example | startup-product | `resumes/finished/example/Christopher_Cho_Resume.pdf` | compiled |
```

Subagent task contract:

```md
You are tailoring one resume for one job.

Inputs:
- Company: <company>
- Role: <role>
- URL: <url>
- Slug: <slug>
- Batch dir: ~/notes/resumes/generated/batch-YYYY-MM-DD/<slug>/

Steps:
1. Fetch the full JD using the available browser/web tooling.
2. Write the fetched JD to `job.md`.
3. Classify using `~/notes/resumes/resume-patterns.md` and `~/notes/resumes/bullet-bank.yml`.
4. Write `match-summary.md`.
5. Generate `resume.tex` from the selected variant.
6. Copy the final source to `~/notes/resumes/resume-<slug>.tex`.

Rules:
- Do not compile PDFs.
- Do not edit other jobs' directories.
- Do not update `application-results.csv`.
- Do not fabricate missing experience.
```

Fallback behavior:
- Fetch succeeds: use fetched JD, classify with `/match-resume`, then generate from selected variant.
- Fetch fails but pasted JD text exists: use `/tailor-resume` rules against the pasted JD, still selecting the closest variant first.
- Fetch fails and no JD text exists: do not generate a resume; write a clear `job.md` failure note and ask for the JD text.

Rules:
- Use one subagent per job URL when multiple jobs are supplied.
- Do not fabricate missing experience.
- Do not generate a final `.tex` from an unfetched or failed JD.
- If several jobs are supplied, continue on individual failures instead of stopping the whole batch.
- Keep each resume one page.
- Prefer existing high-performing patterns from `resume-patterns.md`.
- For YC/startup product roles, prefer `startup-product` when tied with `full-stack`.

Optional helper:
```bash
cd ~/notes
resumes/scripts/batch_match_resumes.py jobs.csv --prepare
resumes/scripts/batch_match_resumes.py jobs.csv --status
resumes/scripts/batch_match_resumes.py jobs.csv --compile
```
