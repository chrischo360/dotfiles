---
name: project-case-study
description: Turn a technical project or work story into a polished portfolio/interview case study using a Markdoc-style .mdoc article, clear layman explanations, visual evidence, and reusable story structure. Use when Chris asks to write, polish, extract, or prepare project stories/case studies for interviews or portfolio.
---

# project-case-study

Help Chris turn a project into a polished technical case study that is clear to non-specialists and credible to engineers.

Use this skill when:
- Chris asks to write or improve a portfolio article.
- Chris asks to prepare a project story for interviews.
- Chris references `.mdoc`, Markdoc, case studies, project showcases, or Stripe-style articles.
- Chris wants to turn raw notes, resume bullets, code research, screenshots, or diagrams into a polished project narrative.

## Goal

Create articles that signal:
- Product judgment: why the work mattered to users/business.
- Technical judgment: what architecture decisions were made and why.
- Execution: what was built, migrated, fixed, or shipped.
- Reliability: how failure modes, observability, and production safety were handled.
- Communication: the ability to explain complex systems in plain English.

These articles should be useful for:
- Interview prep.
- Portfolio case studies.
- Recruiter/founder-facing project summaries.
- Future blog posts.

## Preferred output format

Use a Markdoc-style `.mdoc` article for portfolio-ready versions.

File naming:

```txt
<project_slug>.mdoc
```

Example:

```txt
interviews/airgoods/technical/what_you_worked_on/high_friction_checkout.mdoc
```

The `.mdoc` file should include:
- YAML frontmatter.
- Normal Markdown headings and prose.
- Semantic Markdoc tags for reusable visual components.
- Image references to local `assets/` files when available.

Example frontmatter:

```md
---
title: Turning a Checkout Banner into Schema-Driven UI
description: A checkout loyalty enrollment flow that moved from hardcoded PHP/React plumbing to configurable CMS-driven screens, without making checkout more fragile.
tags:
  - React
  - GraphQL
  - Server-driven UI
  - Checkout
  - State management
---
```

## Article flow

Use this structure by default:

```md
---
title: ...
description: ...
tags:
  - ...
---

{% hero image="assets/example.svg" eyebrow="..." %}
One concise sentence explaining the work and why it mattered.
{% /hero %}

## The short version

Explain the project in plain English. Avoid jargon first. Mention what looked simple and what was actually hard.

## Why this existed

Give product/business/user context. Why did the team care?

## The problem: ...

State the core constraint. Examples:
- checkout cannot break
- data had to stay consistent
- users needed a faster flow
- product needed configurability

## Before vs. after

Show the migration or change clearly. Prefer concrete examples:
- before/after data shapes
- before/after architecture
- before/after UI flow
- before/after performance timeline

## The architecture: ...

Explain the key design decisions. Use 2-4 decision cards.

## Safety rails / Production behavior

Explain how the work behaved in production:
- fallbacks
- error handling
- observability
- feature flags
- rollbacks
- tests

## Evidence I’d show

List the best artifacts:
- 45-second video
- screenshots
- dashboard
- schema preview
- architecture diagram
- before/after comparison

## What this demonstrates

Translate the project into signals:
- I can migrate legacy systems.
- I can separate content/data/state.
- I can build configurable product surfaces.
- I care about production safety.

## Private TODO

Keep unfinished prep tasks here.
```

## Markdoc component tags

Use semantic tags. The portfolio can later map these tags to React components.

Common tags:

```md
{% hero image="assets/hero.svg" eyebrow="Checkout migration case study" %}
One-sentence summary.
{% /hero %}

{% callout title="Key idea" %}
Checkout provided the facts, Block Builder provided the content, and the component owned only its interaction state.
{% /callout %}

{% codeCompare %}
{% before title="Before" language="json" %}
{ "old": "shape" }
{% /before %}

{% after title="After" language="json" %}
{ "new": "shape" }
{% /after %}
{% /codeCompare %}

{% imageFrame src="assets/diagram.svg" alt="Architecture diagram" /%}

{% decisionGrid %}
{% decision title="1. Schema owned content" %}
Screens, copy, CTAs, and layout lived in CMS configuration.
{% /decision %}
{% /decisionGrid %}

{% evidenceGrid %}
{% evidence title="45-second video" %}
Show the core user flow.
{% /evidence %}
{% /evidenceGrid %}
```

If a tag is not supported yet, still use it in `.mdoc`. Treat `.mdoc` as the future portfolio source.

For plain Markdown previews, either:
- maintain a separate `.md` version, or
- keep tags simple enough to read even without rendering.

## Style guide

Write like Stripe-style technical content:
- Crisp title.
- Strong one-liner.
- Short paragraphs.
- One idea per paragraph.
- Diagrams near the paragraph they explain.
- Concrete examples instead of abstract descriptions.
- Jargon explained in layman terms.
- Technical depth without sounding like internal documentation.

Use plain-language translations:
- “Block Builder” -> “Wayfair’s internal CMS/server-driven UI platform.”
- “Server-driven UI” -> “the server sends the structure/content, the client renders it.”
- “Veil” -> “a semi-transparent overlay that focuses the user.”
- “SKU” -> “the membership item added to cart.”
- “Reducer” -> “a small state machine for the component.”
- “GraphQL fragment” -> “a typed slice of API data the component needs.”

Avoid:
- Long internal acronyms without explanation.
- Unexplained repo names.
- Raw implementation dumps.
- Proprietary screenshots or customer/order data.
- Claims that expose confidential metrics unless already approved/safe.

## Visuals and images

Good case studies use evidence.

Default visual set:
- Hero/mock screenshot of the product.
- Before/after diagram.
- Architecture diagram.
- State/data ownership diagram.
- Observability/dashboard screenshot or sanitized mock.
- Short video/GIF of the user flow.

Use local asset paths:

```txt
assets/<project_slug>_component_mock.svg
assets/<project_slug>_architecture.svg
assets/<project_slug>_state_separation.svg
assets/<project_slug>_observability.svg
```

When real screenshots are sensitive:
- recreate the UI with generic branding.
- blur or remove internal URLs, customer data, order IDs, dashboards, and private metrics.
- label visuals as representative mocks when needed.

## Research workflow

When asked to create or improve a case study, gather context in this order.

### 1. Read local notes first

Search `~/notes` for prior notes, interview prep, work docs, resumes, and archive files.

Use targeted searches for project names, ticket IDs, metrics, or concepts.

Examples:

```txt
High Friction Checkout
Lacuna
Prefetching Solution
PGL-548
checkout latency
```

Use `read`, `grep`, `find`, or `ls`. Avoid unnecessary shell exploration.

### 2. Use resume context

Look in:

```txt
resumes/
resumes/extra_bullets.md
resumes/resume_patterns.md
resumes/generated/
```

Extract:
- strongest bullets
- metrics
- role framing
- callback-informed positioning
- stack/technology claims already used safely

### 3. Use Glean for company knowledge

Use Glean when the project needs internal context across docs, Slack, PRDs, or Jira.

Good Glean searches:
- project name + repo name
- ticket ID + feature name
- feature name + “RFC”
- feature name + “PRD”
- feature name + “Datadog”
- feature name + “Block Builder”

Synthesize, do not dump internal details.

### 4. Use Sourcegraph for code evidence

Use Sourcegraph when you need to understand implementation details.

Search for:
- component names
- GraphQL type names
- endpoints
- reducers/context
- schema files
- generated fragments
- constants/feature flags

Read enough code to answer:
- What was the old path?
- What was the new path?
- What were the core data types?
- Where did state live?
- What fallback/error behavior existed?
- What repos were involved?

Use examples like:

```txt
repo:github.com/org/repo ComponentName
repo:github.com/org/repo GraphQLTypeName
repo:github.com/org/repo endpoint_or_feature_flag
```

Translate code findings into layman terms.

## How to explain technical details

Always separate:

```md
Content/configuration -> where copy/layout comes from
Dynamic data -> where live business/user data comes from
Interaction state -> how the component changes as the user acts
Safety -> what happens when something fails
```

Example:

```md
Content/layout -> CMS schema
Dynamic checkout data -> checkout state
Interaction flow -> local reducer/context
```

This makes architecture understandable to both engineers and non-engineers.

## Case study quality checklist

Before finalizing, verify:

- [ ] The first 3 sentences explain the project clearly.
- [ ] The article says why the work mattered.
- [ ] Jargon is linked or explained.
- [ ] There is a before/after comparison.
- [ ] Diagrams are placed near the text they explain.
- [ ] The architecture is explained through decisions, not just implementation.
- [ ] The article mentions safety/failure modes for production work.
- [ ] Evidence section says what screenshots/videos/dashboards to show.
- [ ] Confidential details are removed or generalized.
- [ ] The final section translates the project into interview/portfolio signals.

## Output behavior

When creating a new case study:
1. Ask only if the project goal or audience is unclear.
2. Otherwise, draft the `.mdoc` directly.
3. If a plain Markdown version already exists, preserve it and create a separate `.mdoc` next to it.
4. Add/update image references but do not fabricate real production screenshots. Use mock SVGs when helpful.
5. Keep the final response concise with changed file paths.
