---
name: grill-me
description: Interview the person relentlessly about a plan, product idea, offer or test design until the team reaches shared understanding. Use when someone wants to stress test a plan, says "grill me", or has a rough idea that needs its decisions made explicit.
---

# Grill Me

Interview the person relentlessly about every aspect of the plan until you both understand it the same way. Walk down each branch of the decision tree and resolve the dependencies between decisions one by one. For each question, give your recommended answer so they can accept it with one word or correct it.

## Rules

1. **One question at a time.** Wait for the answer before the next. Never send a list of questions.
2. **Every question carries a recommended answer** and one line of why. Example: "What is the test budget per ad set? I recommend [X] because the course rule says [X] (course_search 'test budget'). Agree, or different?" If you have no basis for a recommendation, say so and propose a way to find one.
3. **Look before you ask.** If the answer can be found, find it instead of asking: `product_get` and `product_list` for existing product data, `task_list` for what is in flight, `files_tree` and `file_read` for earlier research and copy, `course_search` and `course_get` for the Origins course method. Only ask what the files cannot answer, and say what you already found.
4. **Order by dependency.** Settle the decisions others depend on first. In dropshipping that is usually: who the buyer is and the desire behind the purchase, then the product and why it fits, then the offer and price against real costs, then the angle and creative plan, then the supplier and shipping reality, then the test design (budget, duration, success and kill numbers), then who owns what.
5. **Challenge, do not just collect.** If an answer is vague, contradicts an earlier one, or rests on a belief with no evidence, say so and ask what would prove it. Name the weakest assumption you have heard so far.
6. **Unknown stays unknown.** If they do not know a number (margin, CPC, shipping time), record it as `[X]` and note how to find it. Do not fill it with a plausible figure.
7. **Keep it moving.** When the tree is exhausted, or the person says stop, close with a summary.

## Branches to walk (adapt to the plan)

- **Buyer and desire:** Who exactly buys this? What do they want, fear and believe? In their words, where did you see it (reviews, comments, forums)?
- **Product fit:** Why this product, why now, how many others sell it, what is the difference?
- **Offer and economics:** Price, landed cost, shipping, fees, refund rate, break even cost per purchase. What bundle or guarantee lifts value?
- **Angle and creative:** Which single angle first? What are the hooks? What is the proof, and is it real?
- **Supplier:** Sample ordered? Real shipping time to US addresses? Quality checked? Backup supplier?
- **Test design:** Budget, platform, audience, duration, what number means scale, what number means kill, what you will do if the result is in between.
- **Risks and ownership:** What kills this? Who owns each next step, by when?

## Closing summary

When done, write back:

```
PLAN AS UNDERSTOOD
- Goal: ...
- Decisions made: ... (each with the reason)
- Open unknowns: [X] items and how to find each
- Weakest assumption: ...
- Next steps: owner, action, date
```

Then ask whether to act on it. Only after they agree:
- `team_decision_record` for each decision the team should treat as settled.
- `task_create` for each next step with an owner.
- `file_write` the summary to `Products/<product>/plan-<date>.md` when it concerns one product.

If the plan looks shaky rather than merely unclear, suggest running the premortem skill on it next.
