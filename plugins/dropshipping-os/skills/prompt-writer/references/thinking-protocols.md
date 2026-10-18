# Thinking Protocols Reference

Read this with file_read when the "T: Thinking Protocol" element of PROMETHEUS needs a concrete reasoning approach, or when a prompt's task complexity calls for a named protocol. Select by task characteristics; for complex prompts, combine multiple protocols.

> **Model note (important).** These protocols emit prompt text that will run on some target model. On Claude models, avoid baking in phrasing that orders the model to reproduce its own private reasoning as reply text ("show your reasoning", "show your work", "narrate your thinking"): it can trip a reasoning-extraction refusal and silent fallback. Phrase these prompts around the OUTCOME instead (the final answer plus the key decisions that drove it). The classic chain-of-thought trigger phrases below ("think step by step", "let's think step by step") are safe as reference and are most useful when the emitted prompt EXPLICITLY targets a non-Claude model (GPT, Gemini, Llama, etc.); when a template is written for a non-Claude model, mark it as such.

Select the appropriate reasoning protocol based on task characteristics. For complex prompts, combine multiple protocols.

## 1. Chain-of-Thought (CoT): Foundation Protocol

**What it is:** Explicit step-by-step reasoning that mirrors human problem-solving.

**When to use:**
- Mathematical calculations
- Multi-step logical deductions
- Any task with a clear sequential solution path
- When you need to show work for verification

**Implementation levels:**

| Level | Prompt Addition | Best For |
|-------|----------------|----------|
| Basic | "Think step by step." | Simple reasoning tasks |
| Enhanced | "Let's work through this step by step to ensure accuracy." | Math, logic problems |
| Structured | "First, identify the given information. Then, determine the required steps. Finally, execute each step and verify." | Complex multi-step problems |
| Deep Breath | "Take a deep breath and work through this problem step by step." | Improved math performance |

**Example implementation (non-Claude target):**
```
Before answering, work through this systematically:
1. State what information is given
2. Identify what we need to find
3. Determine the logical steps required
4. Execute each step, showing your reasoning
5. Verify the answer makes sense
```

---

## 2. Zero-Shot CoT: No Examples Needed

**What it is:** Triggers step-by-step reasoning without providing examples.

**When to use:**
- When you don't have good examples to provide
- For straightforward reasoning tasks
- When speed matters more than maximum accuracy

**Best trigger phrases (ranked by effectiveness; non-Claude targets):**
1. "Let's work this out in a step by step way to be sure we have the right answer."
2. "Take a deep breath and work on this problem step by step."
3. "Let's think step by step."
4. "First, let's think about this carefully."

---

## 3. Tree-of-Thoughts (ToT): Explore Multiple Paths

**What it is:** Generates multiple solution approaches, evaluates each, pursues most promising.

**When to use:**
- Problems with multiple valid approaches
- Strategic decisions with tradeoffs
- Creative tasks needing exploration
- When the "obvious" approach might not be best

**Implementation:**
```
Approach this problem using Tree-of-Thoughts reasoning:

1. GENERATE: Identify 3 distinct approaches to solve this problem
2. EVALUATE: For each approach, assess:
   - Likelihood of success (high/medium/low)
   - Potential risks or downsides
   - Resource requirements
3. SELECT: Choose the most promising approach and explain why
4. EXECUTE: Develop the selected approach fully
5. VERIFY: Check if the solution meets all requirements

If the selected approach hits a dead end, backtrack and try the next most promising option.
```

**Evaluation prompts to include:**
- "Rate each approach as 'promising', 'possible', or 'unlikely to work'"
- "Which approach has the highest probability of success?"
- "What could go wrong with each approach?"

---

## 4. Step-Back Prompting: Principles First

**What it is:** Abstract to high-level principles before solving specific problem.

**When to use:**
- Complex domain-specific problems
- When models might jump to wrong conclusions
- Physics, chemistry, legal, medical reasoning
- Any task where underlying principles matter

**Implementation:**
```
Before solving this specific problem:

STEP BACK: What general principles or concepts are relevant here?
- What knowledge of the field applies?
- What fundamental rules or laws govern this situation?
- What similar problems have we seen, and what made them work?

APPLY: Now, using these principles, solve the specific problem at hand.
```

**Example for a physics problem:**
```
Step 1: What physical principles relate to this scenario?
Step 2: What equations or relationships apply?
Step 3: Now solve the specific problem using these principles.
```

---

## 5. Self-Consistency: Multiple Attempts, Best Answer

**What it is:** Generate multiple independent solutions, select most common/consistent answer.

**When to use:**
- High-stakes decisions where accuracy is critical
- Mathematical problems with potential calculation errors
- When you want to reduce random errors
- Complex reasoning where different paths should converge

**Implementation:**
```
Solve this problem using 3 independent reasoning paths:

PATH 1: [Solve using first approach]
PATH 2: [Solve using alternative method]
PATH 3: [Solve using third approach if possible]

CONSISTENCY CHECK:
- Do all paths reach the same conclusion?
- If not, which reasoning is most sound?
- Final answer based on most consistent/reliable path:
```

**Note:** Computationally expensive but significantly more accurate for complex tasks.

---

## 6. Self-Critique & Self-Refine: Iterative Improvement

**What it is:** Generate output, critique it, improve based on critique.

**When to use:**
- Writing and content creation
- Code generation
- Any task where first drafts can be improved
- When quality matters more than speed

**Self-Critique Implementation:**
```
After completing your initial response:

CRITIQUE: Review your work from the perspective of [expert type]:
- What are the 3 weakest points?
- What assumptions might be wrong?
- What would a skeptic challenge?
- What's missing or incomplete?

IMPROVE: Based on this critique, revise your response to address these issues.
```

**Self-Refine Implementation (3-step cycle):**
```
STEP 1: GENERATE: Create initial output

STEP 2: FEEDBACK: Evaluate the output:
- Does it fully address the task?
- What specific improvements would make it better?
- Rate quality 1 to 10 and explain why not higher

STEP 3: REFINE: Incorporate feedback into improved version

Repeat steps 2 to 3 until quality reaches acceptable level or no further improvements identified.
```

**Persona-based critique (more powerful):**
```
Now critique this response as if you were:
- A domain expert finding technical flaws
- A skeptical reviewer looking for weak arguments
- An end-user trying to actually use this
- A competitor looking for advantages to exploit
```

---

## 7. Reflexion: Learn From Failures

**What it is:** Structured reflection on what went wrong, stored for future attempts.

**When to use:**
- Iterative problem-solving (debugging, optimization)
- When similar problems recur
- Learning from mistakes across attempts
- Complex tasks requiring multiple tries

**Implementation:**
```
After each attempt:

EVALUATE: Did this succeed? If not, what specifically went wrong?

REFLECT:
- What was the root cause of the failure?
- What incorrect assumption did I make?
- What should I do differently next time?

STORE: Key insight to remember: [specific lesson]

RETRY: Apply this insight to the next attempt.
```

---

## 8. Least-to-Most: Build Up Complexity

**What it is:** Decompose hard problems into easier subproblems, solve sequentially.

**When to use:**
- Problems harder than your examples
- Compositional tasks (building complex from simple)
- When direct approaches fail
- Teaching/explanatory contexts

**Implementation:**
```
DECOMPOSE: Break this problem into simpler subproblems, ordered from easiest to hardest:
1. [Simplest subproblem]
2. [Next level of complexity]
3. [More complex, building on previous]
4. [Full problem]

SOLVE SEQUENTIALLY:
- Solve subproblem 1
- Using that solution, solve subproblem 2
- Continue until full problem is solved

Each solution becomes context for the next.
```

---

## 9. Plan-and-Solve: Separate Planning from Execution

**What it is:** Explicit planning phase before any execution.

**When to use:**
- Complex multi-step tasks
- When models skip steps
- Project planning and strategy
- Any task where order matters

**Implementation:**
```
PHASE 1: UNDERSTAND & PLAN:
First, understand the problem completely:
- What is being asked?
- What information is provided?
- What are the constraints?

Create a plan:
- List all steps needed to solve this
- Identify dependencies between steps
- Note any potential issues to watch for

PHASE 2: EXECUTE:
Now follow the plan step by step:
- Complete each step fully before moving to next
- Record intermediate results
- Verify each step before proceeding
```

**Enhanced version (PS+):**
Add: "Extract relevant variables and their values. Calculate intermediate results explicitly. Verify calculations at each step."

---

## 10. Analogical Prompting: Self-Generated Examples

**What it is:** Model generates its own relevant examples before solving.

**When to use:**
- When you don't have good examples
- Novel problems that resemble known patterns
- Creative problem-solving
- When examples would help but curation is hard

**Implementation:**
```
Before solving this problem:

RECALL: Generate 2 to 3 similar problems you know how to solve:
- Problem 1: [similar problem] → Solution approach: [how it's solved]
- Problem 2: [different but related] → Solution approach: [how it's solved]
- Problem 3: [another angle] → Solution approach: [how it's solved]

APPLY: Now, using insights from these analogous problems, solve the original problem.
```

---

## 11. ReAct: Reasoning + Acting (For Tool Use)

**What it is:** Interleaved thinking and action when using external tools/information.

**When to use:**
- Tasks requiring external information lookup
- Multi-step processes with tool calls
- When grounding in real data matters
- Research and fact-checking tasks

**Implementation:**
```
For each step:

THOUGHT: What do I need to find out or do next? What's my reasoning?
ACTION: [Specific action to take: search, calculate, look up, etc.]
OBSERVATION: [Result of the action]

Repeat until task is complete.

THOUGHT: Based on all observations, what's the final answer?
```

---

## 12. Meta-Cognitive Prompting: Thinking About Thinking

**What it is:** Explicit monitoring and evaluation of own reasoning process.

**When to use:**
- Educational contexts
- When transparency matters
- Complex reasoning needing explanation
- Building trust through visible process

**Implementation:**
```
As you work through this:

PLANNING: Before starting, what's your approach? What steps will you take?

MONITORING: During execution:
- Am I on track?
- Is this approach working?
- Do I need to adjust?

EVALUATING: After completion:
- How confident am I in this answer (1 to 10)?
- What's the weakest part of my reasoning?
- What would make me more confident?
```

---

## 13. Socratic Method: Guided Discovery

**What it is:** Iterative questioning that guides toward understanding.

**When to use:**
- Educational/teaching contexts
- When user should discover answer themselves
- Developing deeper understanding
- Coaching and mentoring scenarios

**Implementation:**
```
Rather than providing the answer directly, guide discovery through questions:

1. Ask a question that probes current understanding
2. Based on response, ask a follow-up that addresses gaps
3. Continue until the person reaches the insight themselves

Question types to use:
- Clarification: "What do you mean by...?"
- Assumption probing: "What are you assuming here?"
- Evidence seeking: "What evidence supports that?"
- Alternative viewpoints: "What would someone who disagrees say?"
- Implication exploring: "If that's true, what follows?"
```

---

## Protocol Selection Guide

| Task Type | Primary Protocol | Supporting Protocols |
|-----------|-----------------|---------------------|
| **Math/Logic** | Chain-of-Thought | Self-Consistency, Plan-and-Solve |
| **Strategy/Decisions** | Tree-of-Thoughts | Step-Back, Self-Critique |
| **Writing/Content** | Self-Refine | Self-Critique, Analogical |
| **Code Generation** | Plan-and-Solve | Self-Critique, Reflexion |
| **Research/Factual** | ReAct | Step-Back, Self-Consistency |
| **Complex Reasoning** | Tree-of-Thoughts + CoT | Least-to-Most, Self-Consistency |
| **Creative Tasks** | Analogical | Tree-of-Thoughts, Self-Refine |
| **Teaching/Explaining** | Socratic | Meta-Cognitive, Least-to-Most |
| **Debugging** | Reflexion | Self-Critique, Step-Back |
| **High-Stakes** | Self-Consistency | Multiple protocols combined |

## Combining Protocols

For complex prompts, layer multiple protocols:

**Example: High-stakes analysis**
```
Use the following reasoning approach:

1. STEP-BACK: First, identify the key principles and frameworks relevant to this analysis

2. PLAN: Create a structured approach before diving in

3. EXECUTE: Work through the problem systematically and give the final answer with the key decisions that drove it

4. SELF-CRITIQUE: Review from an expert perspective, identify weaknesses

5. REFINE: Improve based on critique

6. CONFIDENCE CHECK: Rate confidence 1 to 10 and explain any uncertainties
```
