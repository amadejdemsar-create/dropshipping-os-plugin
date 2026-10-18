# PROMETHEUS Detail and Advanced Techniques

Read this with file_read when constructing a Professional+ prompt and you want the full expansion of each PROMETHEUS element, or the advanced techniques that raise output quality.

---

## The PROMETHEUS Framework (full expansion)

**P: Purpose & Success Criteria**
Define exactly what success looks like. Not vague ("write good copy") but measurable ("write copy that clearly communicates X benefit to Y audience, compelling them to take Z action").

**R: Role & Expertise Assignment**
Assign a specific expert role that matches the task. Include:
- Level of expertise in the field
- Specific experience relevant to task
- Perspective/lens to apply
- What this expert would prioritize

**O: Output Specification**
Be surgical about what you want:
- Format (JSON, markdown, prose, list, etc.)
- Length constraints
- Structure requirements
- Tone and style parameters
- What NOT to include

**M: Methodology & Approach**
Don't just tell the AI what to produce, tell it HOW to think:
- Step-by-step reasoning required
- Frameworks to apply
- Quality checks to perform
- Iteration process (if applicable)

**E: Examples & Anti-Examples**
Show, don't just tell:
- 2 to 3 examples of excellent output (few-shot learning)
- 1 to 2 examples of what to avoid (negative prompting)
- Explain WHY each example is good/bad

**T: Thinking Protocol**
Select and specify the appropriate reasoning approach based on task complexity. See `references/thinking-protocols.md` for the full catalog and the model note on outcome-focused phrasing.

**H: Handling Edge Cases**
Address ambiguity explicitly:
- What to do when uncertain
- How to handle missing information
- When to ask for clarification vs. make assumptions
- Error handling and fallback behavior

**E: Evaluation Criteria**
Define how output should be judged:
- Specific quality metrics
- Prioritization when tradeoffs arise
- What "good enough" vs "excellent" looks like

**U: User Context & Background**
Include relevant context about:
- The broader project/goal
- Previous attempts or related work
- Constraints and preferences
- Audience and stakeholders

**S: Structure with XML Tags**
Organize all elements using clear delimiters:
```xml
<role>...</role>
<context>...</context>
<task>...</task>
<methodology>...</methodology>
<examples>...</examples>
<output_format>...</output_format>
<constraints>...</constraints>
<evaluation_criteria>...</evaluation_criteria>
```

---

## Advanced Techniques to Apply

### 1. Goldilocks Altitude
Find the right level of specificity:
- Too vague: "Write a good ad"
- Too rigid: 47 rules about every possible scenario
- Just right: Clear direction + room for intelligent judgment

### 2. Preemptive Objection Handling
Anticipate where the AI might go wrong and address it:
- "Do NOT start with 'Certainly!' or similar filler"
- "Avoid generic advice: every point must be specific and actionable"
- "If you're unsure about X, state your assumption explicitly"

### 3. Progressive Disclosure
For complex tasks, structure as sequential phases:
1. First, analyze the situation and summarize key factors
2. Then, generate 3 distinct approaches
3. Finally, develop the best approach in detail

### 4. Quality Forcing Functions
Build in mechanisms that force higher quality:
- "Before finalizing, identify the 3 weakest points and improve them"
- "Rate your confidence 1 to 10 on each section"
- "Explain why this approach is better than the obvious alternative"

### 5. Constraint Creativity
Paradoxically, constraints often improve output:
- Word limits force clarity
- Format requirements force structure
- "Explain like I'm 5" forces simplicity
- "No jargon allowed" forces accessibility

### 6. Meta-Cognitive Instructions
Tell the AI how to think about thinking:
- "If this were being graded by an expert, what would they criticize?"
- "What would a skeptic say about this?"
- "What's the most common mistake people make here?"
