# Create Pitch Command

Command to generate tailored job application pitches by combining company/role info with personal background.

## Usage
```
/create-pitch [company-name]
```
Then paste the job posting content when prompted.

## Workflow

### 1. Input Collection
- Extract key information from job posting:
  - **About Company**: Mission, product, customers, funding, team size
  - **About Role**: Position title, responsibilities, tech stack
  - **Who You Are**: Required experience, education, skills, mindset
  - **Why Join**: Growth opportunities, impact, culture, benefits
  - **What You'll Do**: Day-to-day tasks, projects, expectations

### 2. Personal Background Integration
Sources to pull from:
- `career/background.md` - Work experience, skills, achievements
- `career/examples/successful-pitches.md` - Reference examples that worked
- Key highlights to emphasize:
  - Technical experience (internships, projects, tech stack)
  - Education background
  - Ownership/autonomy examples
  - Product sense demonstrations
  - Entrepreneurial projects

### 3. Pitch Generation

**Structure:**
```
[Opening Hook - 1-2 sentences connecting your background to their mission]

[Body - 2-3 short paragraphs]
- Paragraph 1: Relevant experience + specific skills match
- Paragraph 2: Why this company/role specifically excites you
- Paragraph 3: What you'll bring / how you'll contribute

[Closing - 1 sentence call to action]
```

**Length:** 150-250 words total (keep concise)

## Elements of a Good Pitch

### DO
- **Be specific**: Reference actual company details (product, customers, tech)
- **Show research**: Mention specific features, recent news, or unique aspects
- **Connect dots**: Explicitly link your experience to their needs
- **Use concrete examples**: "Built X using Y, resulting in Z"
- **Match their language**: Mirror terms from job posting (their tech stack, values)
- **Show enthusiasm**: Genuine excitement about specific aspects of the role
- **Demonstrate value**: Focus on what you'll contribute, not just what you want

### DON'T
- **Be vague**: Generic statements like "I'm passionate about technology"
- **Sound AI-generated**:
  - Avoid: "I am writing to express my interest..."
  - Avoid: "I believe I would be a great fit..."
  - Avoid: Overly formal or template language
  - Avoid: Bullet points in pitch body
- **Make it about you**: Don't focus only on what you'll learn/gain
- **Repeat resume**: Don't just list past jobs - connect them to this role
- **Use clichés**: "Fast learner", "team player", "passionate", "excited to learn"
- **Be too long**: Anything over 300 words loses attention
- **Oversell**: Avoid superlatives ("best", "perfect", "ideal candidate")

## Red Flags to Avoid

### AI Detection Signals
- Overuse of adjectives ("excellent", "outstanding", "exceptional")
- Formal salutations ("To Whom It May Concern", "Dear Hiring Manager")
- Generic structure that doesn't flow naturally
- Lack of personality/voice
- No specific details about the company

### Generic/Template Signals
- Could apply to any company with find-replace
- No mention of specific product, team, or mission details
- Focus on what you want vs. what you'll contribute
- Lists of skills without context
- No demonstration of research

## Example Analysis

### PointOne Role Extraction
**About Company:**
- AI time platform for law firms
- Customers: SMBs to world's largest law firms
- $3.5M seed (Bessemer, 8VC, General Catalyst)
- Small team, 2x'ing in 2 months
- Solving: Time tracking (6-min increments), billing admin

**About Role:**
- New Grad Software Engineer
- $100K-$140K, 0.10%-0.20% equity
- New York, in-person
- Multi-product company

**Who You Are:**
- Internship experience (hyper-growth startups / big tech)
- CS degree from top university
- Strong product sense
- High ownership, autonomous
- Entrepreneurial mindset
- Excited about in-person, customer interaction

**What You'll Do:**
- Develop novel AI products
- Work directly with customers (visit offices)
- Prototype AI pipelines (RAG, etc.)
- Lead through mentoring, pairing, code reviews
- Shape engineering culture

**Why Join:**
- Growth: Work with founders, own high-impact projects
- Impact: Sticky tools, hard ROI, multi-product company
- Support: Collaborative, high feedback culture

## Resources Needed

Create these files to support the command:

### `career/background.md`
Your professional background:
- Work experience (companies, roles, achievements)
- Technical skills (languages, frameworks, tools)
- Education (degree, school, relevant coursework)
- Projects (personal, entrepreneurial, side projects)
- Key strengths (product sense, ownership examples, etc.)

### `career/examples/successful-pitches.md`
Examples of pitches that got responses:
- Company name
- Role applied for
- Pitch text
- Outcome (interview, offer, etc.)
- What worked (analysis)

### `career/pitch-templates/` (optional)
- `startup.md` - Template for startup roles
- `big-tech.md` - Template for established companies
- `technical.md` - Deep technical roles
