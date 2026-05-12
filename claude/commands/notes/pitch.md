Generate a tailored outreach/pitch message for a job application.

Uses a canonical pitch template grounded in the experience profile.
Customizes the closing paragraph and company-specific framing based on the JD.
Outputs a ready-to-send message.

Steps:

1. If not already provided, ask the user for:
   - Company name
   - Job description (full text, pasted inline)
   - Platform (e.g. Work at a Startup, LinkedIn, cold email) — affects tone slightly

2. Read the experience profile:
   ```bash
   cat ~/dotfiles/claude/commands/notes/experience.md
   ```

3. Use the following as the canonical pitch template. This is the approved base — do NOT rewrite
   the core paragraphs. Only the closing paragraph (company-specific hook) should be customized:

   ---
   Hi [Company] team,

   I'm a full-stack engineer at Wayfair (Fintech & Loyalty Rewards). At Wayfair I own features
   end-to-end: from React/Next.js/TypeScript frontend to GraphQL and Java microservices — across
   surfaces like checkout and cart.

   A few things I'm proud of:
   - I cut payment modal load time from 3.8s to 0.5s
   - Led the migration of our checkout page from a legacy monolith to a federated GraphQL architecture
   - Shipped multiple production hotfixes within my tenure

   I've been rated Exceeds Expectations in my performance review and ranked first on my team by
   lines of code changed.

   Before Wayfair, I co-founded Lacuna Mentors — built the product from scratch as sole engineer,
   grew to 60+ mentors.

   I'm very comfortable with ambiguity and startup pace — I recently completed a work trial with a
   YC-backed startup, onboarded to a new codebase, shipped a production Excel integration feature
   within 3 days, and received an offer.

   [COMPANY-SPECIFIC PARAGRAPH — customized per role, see step 4]

   Happy to jump on a quick call if it seems like I'd be a good fit.

   Christopher Cho
   christopher.cho.dev@gmail.com | linkedin.com/in/chrischo360 | github.com/chrischo360
   ---

4. Write the company-specific closing paragraph by:
   - Identifying 1-2 concrete things from the JD that genuinely connect to Chris's background
     (mission, product domain, tech stack, company stage, a specific problem they're solving)
   - Connecting them to specific experience from the profile (e.g. A/B experimentation, observability,
     GraphQL migration, co-founder background, production incident response)
   - Expressing genuine excitement about the specific role — not generic praise
   - Keeping it to 2-3 sentences max
   - Never use: "I've always admired", "passionate about", "synergy", "leverage my skills"
   - The tone should feel like a peer reaching out, not a cover letter

   Example (Shaped):
   > "Shaped's mission — turning behavioral data into relevant product experiences — maps directly
   > to work I've done running A/B experiments on checkout UX and building observability tooling for
   > real-time systems. I'm genuinely excited about the search and recommendations space, and I'd
   > love to bring that same product + engineering mindset to your team."

5. Output the full pitch with the company name filled in and the closing paragraph customized.
   Then ask: "Does this feel right? Anything to adjust?"

6. If the user requests edits, apply them surgically — don't rewrite paragraphs that weren't touched.
   Re-output the full pitch after any change so the user always sees the complete version.

What this does:
- Preserves a consistent, approved voice across all applications
- Customizes only what should be customized (the company-specific hook)
- Produces a ready-to-send pitch in one pass

Notes:
- Do not fabricate experience or metrics — draw only from experience.md or what the user provides
- The template paragraphs are fixed — resist the urge to "improve" them unless the user asks
- If the role is notably different (e.g. pure backend, leadership, non-startup), flag which
  template sections may need adjustment before outputting
