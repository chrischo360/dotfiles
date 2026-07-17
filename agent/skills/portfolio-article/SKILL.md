---
name: portfolio-article
description: Write or improve a portfolio article for Chris's personal site. Covers research, writing style, frontmatter, and Markdoc components. Use when Chris asks to write, draft, or improve an article in src/content/work/.
---

# portfolio-article

Help Chris write articles for his portfolio at `~/codebase/portfolio`.

Use this skill when:
- Chris asks to write, draft, or improve an article.
- Chris asks to add a case study or project writeup to the portfolio.
- Chris references `src/content/work/` or `.md` article files.

## Where articles live

```txt
~/codebase/portfolio/src/content/work/<slug>.md
```

Assets go in:

```txt
~/codebase/portfolio/public/work/<slug>/
```

Referenced in the article as `/work/<slug>/filename.png`.

---

## Frontmatter

Every article needs this block at the top:

```yaml
---
slug: your-slug-here
collection: work
order: 0                        # controls sort order; lower = earlier
eyebrow: Company · Topic        # small label above the title
title: "Title of the article"
summary: One sentence summary of what you built.
impact: One sentence on the outcome or result.  # optional but good
hero:
  src: /work/your-slug/hero.png
  alt: Description of the hero image
tags: []
hidden: true                    # optional — hide from listing until ready
---
```

---

## Research first

Before writing anything, gather enough context to write with real specificity. Vague writing is a symptom of not knowing the project well enough.

### Questions to ask Chris up front

Ask these before starting if the answers are not obvious:

- What is the project? One sentence.
- What problem were you solving? What was broken, missing, or wrong?
- What did you actually build or change? Be specific.
- What was the before state and the after state?
- Do you have numbers? (latency, load time, conversion, anything measurable)
- What was the hardest part or the non-obvious decision?
- Do you have screenshots, videos, diagrams, or code snippets?
- Who is this article for? (recruiters, engineers, founders, all of the above)
- Any parts that are confidential or should be kept vague?

### What to gather from source code

Use Sourcegraph or GitHub to get implementation evidence:

- Component names and file paths
- GraphQL types, fragments, or queries involved
- State management patterns (reducers, context, hooks)
- API endpoints or data shapes
- Feature flag names and how they were used
- Error handling or fallback paths

Translate code findings into prose — don't dump raw code into the article unless it illustrates a specific point clearly.

### What to look for in notes / Glean

- Prior notes at `~/notes` — project names, ticket IDs, prep docs
- Jira tickets for context and acceptance criteria
- Confluence docs, RFCs, or PRDs for the feature
- Slack threads around the work period
- Datadog or performance dashboard screenshots
- Resume bullets already written for this project

The goal is to write with numbers, names, and decisions — not generalities.

---

## Writing style

Read `src/content/work/checkout-performance.md`, `pi-codeblock-copy.md`, and `inventory-reorder-design.md` as the reference baseline.

### Voice and tone

- First person. "I traced the regression" not "the regression was traced."
- Casual but precise. Write like you're explaining it to a smart engineer over coffee, not presenting to a committee.
- Specific over generic. "43% P75 latency reduction" not "significantly improved performance."
- Short paragraphs. One idea per paragraph.
- No filler. Cut every sentence that does not add information.

### What to avoid

- AI-sounding phrases: "In this article we will explore...", "This demonstrates a deep understanding of...", "leveraging cutting-edge...", "robust and scalable..."
- Over-explaining obvious things.
- Walls of text with no structure.
- Hedging everything: "This might potentially be considered..."
- Padding to hit a length target. Shorter is almost always better.

### Combine personal narrative with technical specificity

The best articles do both at the same time:

```md
// Too vague
The team investigated performance issues and found that feature flags were causing slowdowns.

// Too technical, no story
The flag evaluation service contributed ~33% of server-side time on the checkout controller.

// Good: both
Reading the traces, the flag-evaluation service was eating roughly a third of the server-side time
on the checkout controller. That was the leak.
```

Lead with the decision or finding, then back it up with the technical detail.

### Length

Most articles should be readable in 4–7 minutes. If it is getting longer, cut — don't add a summary.

- `pi-codeblock-copy.md` is a good example of a short, tight article that covers everything it needs to.
- `checkout-performance.md` is a good example of a longer article that earns its length with specifics.

---

## Article structure

Not every section is required. Use what fits the project.

```md
# [Same as frontmatter title]

[One-sentence lede. What was built and why it mattered.]

_Optional: note that images are representative mocks if real ones can't be shown._

## The short version

3–5 bullets covering the core problem and what made it non-trivial.
Lets a skimming reader get the gist before they commit.

{% callout title="Helpful references" %}
Links to relevant docs, concepts, or background reading.
Only include if the article uses terms a non-specialist might not know.
{% /callout %}

## Why this existed

Product or business context. Why did anyone care about this problem?

## The problem: [name it]

What was actually hard about this. What constraints made it non-trivial.

## Before vs. after

Show the change concretely. Use code blocks, plain-text diagrams, or before/after images.
The reader should be able to see what changed.

## [Architecture / How it worked / The fix]

Core design decisions. 2–4 key ideas. 
Use callouts for key ideas. Use diagrams near the paragraph they explain.

## Safety rails / Production behavior

What happened when things went wrong. Fallbacks, feature flags, observability, phasing.
Only include if relevant to the project.

## What this demonstrates

Translate the project into concrete signals. What can someone take away?
```

---

## Markdoc components

Use these tags in the article body.

### Callout

```md
{% callout title="Key idea" %}
The server could say "this customer is eligible" without also saying "I've started a checkout session."
{% /callout %}
```

Use callouts for:
- Key architectural ideas
- Helpful references (external links only)
- Goals or constraints worth calling out

### Media (video or embed)

```md
{% media type="video" src="/work/slug/demo.mp4" caption="Caption text here." /%}

{% media type="embed" src="/work/slug/page.html" title="Page title" caption="Caption." /%}
```

### Images

Plain markdown for images is fine:

```md
![Alt text](/work/slug/diagram.svg)
```

Put the image immediately after the paragraph it explains, not at the end of the section.

### Code blocks

Use fenced code blocks with a language tag. For plain-text flow diagrams, use `text`:

```text
user opens modal
  → prefetch preview query
  → preview content renders immediately
  → full query runs on open
```

---

## Visuals and evidence

Good articles show evidence, not just claims.

Default asset set to aim for:
- Hero image or video of the product/tool
- Before/after flow comparison (text diagram or SVG)
- Architecture or data flow diagram
- Screenshot of the result, dashboard, or tool
- Short video or GIF of the actual interaction

When real screenshots are sensitive:
- Recreate the UI with generic data.
- Blur internal URLs, customer data, and private metrics.
- Note in the article that images are representative mocks.

Asset paths:
```txt
/work/<slug>/hero.png
/work/<slug>/diagram.svg
/work/<slug>/demo.mp4
```

---

## Output behavior

1. Read the articles in `src/content/work/` to calibrate tone before drafting.
2. Ask the research questions above if context is thin.
3. Draft the article in `src/content/work/<slug>.md`.
4. Keep the draft tight — cut anything that does not add information.
5. Note any assets that still need to be created (images, diagrams, videos).
6. Don't fabricate metrics or details Chris hasn't confirmed.
