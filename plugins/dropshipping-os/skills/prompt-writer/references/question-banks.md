# Adaptive Context Question Banks by Task Type

Read this with file_read when running Phase 2 (Adaptive Context Gathering). Detect the task type, then ask the relevant questions ONE AT A TIME, personalizing options to what the user already told you, and stop once you have enough context for their stakes level.

---

## Content & Marketing Prompts

**Question 1: Target Audience Specificity**
> Who exactly is this for? _(The more specific, the more persuasive the output)_
>
> Based on [what they mentioned], options might be:
> - A) [Specific role/demographic inferred from their input]
> - B) [Broader category that fits]
> - C) [Alternative interpretation]
> - D) Other (please specify)

**Question 2: Awareness Level**
> How familiar is your audience with [the topic/problem]? _(Determines how much education vs. persuasion needed)_
>
> - A) **Unaware**: Don't know they have this problem yet
> - B) **Problem-aware**: Know the problem, exploring solutions
> - C) **Solution-aware**: Know solutions exist, comparing options
> - D) **Product-aware**: Know your specific offering, need final push

**Question 3: Desired Action**
> What specific action should this content drive? _(One clear CTA performs better than multiple)_
>
> - A) [Most likely action based on context, e.g., "Order now with free shipping"]
> - B) [Alternative action, e.g., "Add to cart with the bundle"]
> - C) [Softer action, e.g., "Read the reviews / Learn more"]
> - D) Other specific action

**Question 4: Tone & Voice**
> What tone fits your brand and audience? _(Should match how your best content sounds)_
>
> - A) **Professional & authoritative**: Expert positioning, formal
> - B) **Conversational & friendly**: Approachable, like talking to a smart friend
> - C) **Bold & provocative**: Challenges assumptions, stands out
> - D) **Educational & helpful**: Teacher mode, builds trust through value
> - E) Other / I have brand guidelines to share

**Question 5: Competitive Context**
> What are you competing against for attention? _(Helps differentiate)_
>
> - A) Direct competitors selling [similar product]
> - B) The status quo / "do nothing" option
> - C) Alternative solutions (different approach to same problem)
> - D) Not sure / Skip this

**Question 6: Proof & Credibility**
> What proof points can we use? _(Specific results > vague claims)_
>
> - A) Customer reviews / UGC / testimonials (share specifics if available)
> - B) Data / statistics / research
> - C) Our own story / founder angle / testing we did
> - D) None yet: make it work without proof

**Question 7: Format & Length**
> What format works best for your use case?
>
> - A) [Most likely format based on context, e.g., "Meta ad primary text (under 125 characters before the fold)"]
> - B) [Alternative format, e.g., "Abandoned cart email sequence (3 to 5 emails)"]
> - C) [Another option, e.g., "Product page sections"]
> - D) Other specific format

**Question 8: Examples (Optional: for Excellence/Mission Critical)**
> Do you have examples of content you love (yours or others')? _(Showing beats telling)_
>
> - A) Yes, I can share links/text
> - B) I can describe what I like
> - C) No, but I know what I DON'T want
> - D) Skip: trust your judgment

---

## Product Research & Supplier Message Prompts

**Question 1: What the output feeds**
> What will this output be used for? _(A research prompt for a go or no go call is built differently from one for a first list of ideas)_
>
> - A) Deciding whether to test a product (go or no go)
> - B) Finding and shortlisting products or suppliers
> - C) Writing a message to a supplier, agent or creator
> - D) Other: [specify]

**Question 2: Market and constraints**
> Which market, price range and constraints apply? _(Country, shipping times, price band, margin floor, categories to avoid)_
>
> - A) [Inferred market and price band from context]
> - B) [Broader alternative]
> - C) I will give the numbers: [specify]
> - D) Use the product in Dropshipping OS as the baseline

**Question 3: Evidence standard**
> What counts as evidence? _(Prevents confident guesses)_
>
> - A) Only things with a source link I can open
> - B) Sources plus clearly labeled estimates
> - C) Course rules from our course material (cite the lesson)
> - D) Quick ideas, unverified, to be checked later

**Question 4: For a message, the relationship**
> Who is the recipient and what do we already have with them? _(Tone and ask follow from this)_
>
> - A) Cold first contact
> - B) Existing supplier, negotiating terms
> - C) Existing supplier, fixing a problem (delay, defect, refund)
> - D) Other: [specify]

**Question 5: For a message, the ask and the limits**
> What exactly do we want, and what is our walk-away point? _(One clear ask, one clear limit)_
>
> - A) Price or MOQ change (give the target)
> - B) Samples, photos or video of the product
> - C) Faster shipping or a better shipping method
> - D) Other: [specify]

**Question 6: Language and channel**
> In what language and where does it go? _(Email, chat app, marketplace messenger)_
>
> - A) English, email
> - B) English, chat message (short)
> - C) Another language: [specify]; the message must read as written by a native
> - D) Other: [specify]

---

## Technical & Coding Prompts

**Question 1: Tech Stack**
> What's the technical environment? _(Ensures compatible, idiomatic code)_
>
> - A) [Inferred stack from context, e.g., "Next.js + TypeScript + Tailwind"]
> - B) [Alternative interpretation]
> - C) Let me specify: [language/framework/tools]
> - D) Flexible / Best practices for the task

**Question 2: Codebase Context**
> How should this fit with existing code? _(Consistency matters)_
>
> - A) New project: establish patterns from scratch
> - B) Existing codebase: I'll share relevant examples
> - C) Follow [specific style guide/convention]
> - D) Standalone snippet: doesn't need to match anything

**Question 3: Error Handling Philosophy**
> How robust should error handling be?
>
> - A) **Production-grade**: Handle all edge cases, proper logging, user-friendly errors
> - B) **Solid basics**: Common errors handled, reasonable defaults
> - C) **Minimal**: Happy path focus, can add error handling later
> - D) Depends on the specific function (specify per-case)

**Question 4: Performance Requirements**
> Any performance constraints? _(Changes implementation approach)_
>
> - A) **Performance-critical**: Needs optimization, benchmarking
> - B) **Should be efficient**: No premature optimization, but don't be wasteful
> - C) **Correctness over speed**: Readable/maintainable > fast
> - D) Specific constraint: [memory/latency/throughput limit]

**Question 5: Integration Points**
> What does this code need to connect with?
>
> - A) [Inferred integrations, e.g., "Database via Prisma"]
> - B) [APIs/services mentioned or implied]
> - C) Nothing external: self-contained
> - D) Let me list the integrations: [specify]

**Question 6: Testing Expectations**
> What level of testing? _(For Professional+ stakes)_
>
> - A) Include unit tests for core logic
> - B) Include tests + explain testing strategy
> - C) No tests needed: I'll add later
> - D) Specific testing framework: [Jest/Vitest/pytest/etc.]

**Question 7: Documentation Level**
> How much documentation?
>
> - A) **Comprehensive**: JSDoc/docstrings, README, usage examples
> - B) **Inline comments**: Explain non-obvious parts
> - C) **Self-documenting**: Clear naming, minimal comments
> - D) None: I just need working code

---

## Analysis & Research Prompts

**Question 1: Decision Context**
> What decision will this analysis inform? _(Focuses the analysis on what matters)_
>
> - A) [Inferred decision, e.g., "Whether to test product X or drop it"]
> - B) [Alternative interpretation, e.g., "Which of three products to scale first"]
> - C) General understanding: no specific decision yet
> - D) Other: [specify the decision]

**Question 2: Hypothesis or Question**
> What's your current hypothesis or core question? _(Analysis needs a focus)_
>
> - A) Testing: "[Inferred hypothesis based on context]"
> - B) Exploring: "[Open question based on context]"
> - C) Comparing: "[Options they might be weighing]"
> - D) Let me frame it: [their framing]

**Question 3: Data Sources**
> What data/information is available? _(Can't analyze what we don't have)_
>
> - A) I'll provide raw data (specify format)
> - B) I'll share documents/reports to analyze
> - C) Use public information about [topic/company/market]
> - D) Combination: let me explain what's available

**Question 4: Rigor Level**
> How rigorous should the analysis be?
>
> - A) **Directionally correct**: Quick insights, acknowledge limitations
> - B) **Solid analysis**: Structured approach, key assumptions stated
> - C) **Comprehensive**: Multiple angles, sensitivity analysis, confidence levels
> - D) **Board/investor-ready**: Bulletproof logic, anticipate all questions

**Question 5: Output Format**
> What format is most useful?
>
> - A) Executive summary (1 page, key findings + recommendation)
> - B) Detailed report with sections
> - C) Comparison table/matrix
> - D) Slide-ready bullet points
> - E) Other format: [specify]

**Question 6: Stakeholder Lens**
> Whose perspective matters most? _(Different stakeholders care about different things)_
>
> - A) [Inferred stakeholder, e.g., "CEO: strategic implications"]
> - B) [Alternative, e.g., "Product team: implementation feasibility"]
> - C) [Another option, e.g., "Finance: ROI and costs"]
> - D) Multiple perspectives needed

---

## Strategy & Planning Prompts

**Question 1: Current Situation**
> What's the starting point? _(Strategy is always relative to where you are)_
>
> - A) Starting from scratch: greenfield
> - B) Existing [thing] that needs improvement
> - C) Pivot/major change from current approach
> - D) Let me describe the current state: [details]

**Question 2: Core Constraint**
> What's the biggest constraint? _(Every strategy has a binding constraint)_
>
> - A) **Time**: Need results by [deadline]
> - B) **Budget**: Limited to [range]
> - C) **Team/resources**: Only have [X people/skills]
> - D) **Technical**: Must work within [limitation]
> - E) **Political/organizational**: Need buy-in from [stakeholders]

**Question 3: Success Metrics**
> How will you measure success? _(Vague goals = vague strategies)_
>
> - A) [Inferred metric, e.g., "Profit: hit X EUR net by date"]
> - B) [Alternative metric, e.g., "Orders: reach X orders per day at break-even ROAS"]
> - C) [Qualitative, e.g., "Successfully launch X capability"]
> - D) Let me define the metrics: [specify]

**Question 4: Timeline**
> What's the time horizon?
>
> - A) Immediate (days/weeks): tactical execution
> - B) Near-term (1 to 3 months): quick wins + foundation
> - C) Medium-term (3 to 12 months): full initiative
> - D) Long-term (1+ years): vision + phased approach

**Question 5: Risk Tolerance**
> How much risk is acceptable?
>
> - A) **Conservative**: Proven approaches, minimize downside
> - B) **Balanced**: Calculated risks with mitigation plans
> - C) **Aggressive**: Big swings, accept higher failure rate for bigger wins
> - D) Depends on the specific decision

**Question 6: Stakeholder Buy-in**
> Who needs to approve/support this?
>
> - A) Just me: full autonomy
> - B) My manager/leadership
> - C) Cross-functional stakeholders
> - D) External parties (board, investors, partners)

**Question 7: Implementation Reality**
> Who will execute this strategy?
>
> - A) Me alone
> - B) My team of [X] people
> - C) Cross-functional teams
> - D) External vendors/partners
> - E) Not sure yet: strategy should inform this

---

## Creative Prompts

**Question 1: Style Reference**
> What's the creative direction? _(A reference is worth 1000 words)_
>
> - A) I have specific examples to share (links/images/text)
> - B) Similar to [known brand/creator/style]
> - C) Let me describe the vibe: [adjectives, feelings, associations]
> - D) Surprise me: I'm open to creative interpretation

**Question 2: Emotional Tone**
> What emotion should this evoke?
>
> - A) [Inferred emotion based on context, e.g., "Excitement / possibility"]
> - B) [Alternative, e.g., "Trust / reliability"]
> - C) [Another option, e.g., "Urgency / FOMO"]
> - D) Other: [specify]

**Question 3: Constraints (Often Helpful)**
> Any constraints to work within? _(Constraints breed creativity)_
>
> - A) Length/word count: [specify]
> - B) Must include: [specific elements]
> - C) Format: [specific structure]
> - D) No constraints: full creative freedom

**Question 4: What to Avoid**
> Anything that's definitely NOT right?
>
> - A) [Inferred anti-pattern, e.g., "Generic corporate speak"]
> - B) [Another to avoid, e.g., "Overly salesy/pushy"]
> - C) [Another, e.g., "Too casual/unprofessional"]
> - D) Nothing specific: just make it good

**Question 5: Iteration Expectation**
> How will we refine this?
>
> - A) Give me options to choose from (3 to 5 variations)
> - B) One strong direction, then we iterate
> - C) Complete draft, I'll give feedback
> - D) Nail it first try (share more context to help)
