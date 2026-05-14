Match a job description to an existing resume variant before tailoring.

Inputs:
- Company name
- Job description text or URL content pasted by the user

Read first:
- `~/notes/resumes/resume-patterns.md`
- `~/notes/resumes/bullet-bank.yml`
- `~/notes/resumes/application-results.csv`
- Existing variants under `~/notes/resumes/variants/`

Workflow:

1. Normalize the job description.
   - Replace smart quotes with straight quotes.
   - Replace em/en dashes with hyphens.
   - Collapse repeated whitespace.

2. Classify the role into exactly one primary variant:
   - `full-stack`
   - `backend-platform`
   - `frontend-product`
   - `ai-devtools`
   - `startup-product`

3. Use this weighting:
   - `full-stack`: full-stack, React, Node, API, GraphQL, product, TypeScript, frontend + backend.
   - `backend-platform`: backend, Java, Spring, REST, microservices, distributed systems, reliability, observability, Datadog, payments.
   - `frontend-product`: frontend, UI, UX, React, consumer product, experimentation, conversion, web performance.
   - `ai-devtools`: AI, LLM, Claude, OpenAI, agentic, developer tools, CI/CD, Buildkite, automation.
   - `startup-product`: startup, founding, zero-to-one, ownership, customer, iterate, generalist, YC.

4. Explain the classification in 2-3 bullets.
   - Quote exact JD phrases that drove the classification.
   - Mention the runner-up variant if close.

5. Recommend the best base resume.
   - Use `~/notes/resumes/variants/<variant>.tex`.
   - If there is already a company-specific resume at `~/notes/resumes/resume-<company>.tex`, compare it against the chosen variant and say whether to reuse it.
   - If there is a finished PDF at `~/notes/resumes/finished/<company>/Christopher_Cho_Resume.pdf`, mention it.

6. Suggest 2-4 bullet swaps from `bullet-bank.yml`.
   - Prefer bullets whose tags match the chosen variant.
   - Preserve high-signal metric bullets unless clearly irrelevant.
   - Do not fabricate experience.

7. Output this structure:

```md
## Recommendation
Variant: <variant>
Base resume: `~/notes/resumes/variants/<variant>.tex`
Existing company resume: <path or none>
Finished PDF: <path or none>

## Why
- <classification reason>
- <classification reason>
- <runner-up / tradeoff>

## Bullet swaps
| Action | Bullet ID | Reason |
|---|---|---|
| Keep/Add/Replace | `...` | ... |

## Skills keywords to mirror
- <exact JD keyword>
- <exact JD keyword>

## Next step
Ask: "Do you want me to generate `~/notes/resumes/resume-<company>.tex` from this variant?"
```

8. Do not generate or edit the final `.tex` until the user approves.

Optional helper:
```bash
cd ~/notes && resumes/scripts/match_resume.py /path/to/job-description.txt
cd ~/notes && resumes/scripts/match_resume.py --analyze-results
```
