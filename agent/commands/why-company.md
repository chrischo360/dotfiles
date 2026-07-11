Generate a tailored "Why do you want to work here?" answer for a job application.

Reads the canonical why-company draft from ~/notes/resumes/app_questions.md and
customizes it with 1-2 concrete hooks from the job description.
Outputs a polished answer in the user's voice.

Steps:

1. If not already provided, ask for:
   - Company name
   - Job description (full text, pasted inline)
   - Length: short (150-250w) or long (300-450w) — default short

2. Read context in parallel:
   ```bash
   cat ~/notes/resumes/app_questions.md
   ```
   ```bash
   cat ~/notes/career/background.md
   ```

3. Extract 1-2 company-specific hooks from the JD that map to the user's documented motivations.
   Look for signals that connect to these raw notes from the bank:
   - "want to see the direct result of what I ship" → small team, high ownership, startup stage
   - "companies actually using AI in their product, not just talking about it" → AI-native product
   - "how much more satisfying it is to build from scratch with real stakes" → 0-to-1, early stage
   - "what gets lost in large orgs — ownership, speed, directness" → contrast with enterprise

   Be specific: name the product area, the company stage, the mission framing, the technical problem.
   Never use: "I've always admired", "passionate about", "excited to leverage", or generic praise.

4. Customize the canonical draft from the bank:
   - The structure is: (1) what I learned at Wayfair → (2) [COMPANY] fits that → (3) Lacuna callback
   - Only the middle section changes — fill in 1-2 sentences specific to this company
   - Do NOT rewrite the opening or closing — preserve the voice in the canonical draft
   - Adjust length by expanding or compressing the company-specific section, not the framing

5. Run the four-ingredient check mentally before outputting:
   - [ ] Personal hook: opens with a specific observation, not an assertion
   - [ ] Company-specific resonance: exactly one concrete JD detail, not vague praise
   - [ ] Skill fit: implied through Lacuna/Wayfair framing, not asserted ("I am good at X")
   - [ ] Forward-looking energy: ends with what you want to build/do, not what you want to receive

6. Run the human voice check against Chris's actual writing style (observed from Slack):
   - [ ] No em dashes used as list openers (e.g. "— decisions by committee, features that...")
         → Replace with short declarative sentences or plain conjunctions
   - [ ] No complex nested constructions ("what X taught me is Y, which is Z")
         → Break into 2 short sentences instead
   - [ ] No "I've always been passionate about...", "excited to leverage", "what I want now is the opposite"
   - [ ] Sentences are short and direct — fragments are fine ("Features that take months to reach users.")
   - [ ] Qualifiers used naturally where appropriate ("I think", "it's hard to feel like")
   - [ ] At least one concrete detail: company name, product area, or specific outcome
   - [ ] Reads like the pitch template voice — declarative, peer-to-peer, no cover letter formality

   Reference: the pitch command at ~/dotfiles/agent/commands/pitch.md is the canonical voice
   example. Match that register, not a polished essay register.

7. Output the answer, then ask: "Does this feel right? Anything to adjust?"
   Apply any edits surgically — don't rewrite sections that weren't touched.
   Re-output the full answer after any change.

8. After approval, ask:
   "Want to save a company-specific version of this to app-questions.md?"
   If yes, append under a "Company-Specific Answers" section:
   ```markdown
   ### [Company] — Why do you want to work here?
   [approved answer text]
   ```

What this does:
- Produces a human-sounding answer in one pass by preserving the canonical voice
- Customizes only what should change (the company-specific hook), not the whole answer
- Enforces the four ingredients and human-voice checks before outputting
- Optionally grows the answer bank with approved company-specific versions

Notes:
- Bank file: ~/notes/resumes/app_questions.md (why-company entry is the canonical base)
- Experience profile: ~/notes/career/background.md
- Pitch command: ~/dotfiles/agent/commands/pitch.md — canonical voice reference
- Do not fabricate experience — draw only from the bank raw notes or what the user provides
- This command is for written application fields. For interview prep, use /answer-app-questions
- If the user provides new context not in the raw notes, use it for the answer and flag that
  the bank's raw notes could be updated to capture it

Voice reference (from Slack + approved pitch template):
- Short declarative sentences. Fragments are fine.
- No em dashes as list starters
- No complex "what X taught me is Y" constructions
- Plain conjunctions over formal transitions ("but" not "however")
- Concrete nouns over abstract claims ("help someone find the right doctor" not "enable better outcomes")
