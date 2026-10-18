---
name: premortem
description: Prospective hindsight stress test. Use before a product test, an ad spend, an offer launch, a supplier order or any hard to reverse choice, or when someone says "premortem", "how could this fail" or "poke holes in this". It assumes the plan already failed and works backward to find why.
---

# Premortem

A premortem runs the clock forward and assumes defeat. Instead of asking "what could go wrong?", which invites a list of mild risks, you declare the plan already dead and force an explanation of the autopsy. The failure is a given, so the only work left is finding the cause. People generate far more, and far more specific, reasons for an outcome they are told already happened than for one they are merely asked to imagine. The same holds for a model: asked "is this a good plan?" it drifts toward reassurance, told "this failed, explain how" it looks for the real cracks.

## When to run it

Run it when someone says premortem, "how could this fail", "stress test this" or "poke holes in this".

Also offer it, and lean toward offering it more often than feels needed, before anything costly or slow to reverse:

- a product test with real ad spend
- an offer, price or bundle change
- a supplier order beyond a sample, or switching suppliers
- a new store, brand or niche commitment
- scaling a winner (raising budgets, adding countries, hiring)
- a new ad angle batch built on an unproven belief

Skip it for cheap, reversible actions (a copy tweak, a 5 USD test, a quick lookup). A premortem on everything becomes noise.

## Procedure

### 1. Pin the target and define success

Read what exists first: `product_get` for the product, `task_list` for open work, `course_search` for the course rule that applies (for example test budgets or kill criteria). State the plan in one sentence and define what success at the horizon concretely looked like (the number, the milestone, the state of the world). Failure needs something specific to be measured against. Default horizon is six months. For a small test use two weeks, for a big build a year. If the success number is unknown, write `[X]` and ask for it. Do not invent it.

### 2. Declare it dead, then autopsy

Open with the frame literally: "It is [horizon] from now. This plan has already failed. It did not half work, it is dead." Then generate the distinct ways it died. Aim for five to eight and stop when new ones are rephrasings.

For each failure mode write:
- **How it died:** a short concrete story, the actual sequence (what happened first, what cascaded), not a category like "execution risk".
- **Early warning signs:** leading indicators visible weeks before the death. This is the part the team can act on.
- **Likelihood and severity:** likelihood high, medium or low; severity fatal, major or minor.

Push for variety across the chain. For dropshipping that usually means: demand and the avatar (nobody wants it enough), the angle and creative (right product, wrong message), the offer and margin (price, shipping cost, refunds, fees eat the profit), traffic and test design (budget too thin to read, wrong audience, tracking broken), the supplier (slow shipping, quality, stockouts, no sample checked), platform and compliance risk (ad account bans, policy, claims that get ads rejected), execution and bandwidth (four people, one owner per task), and the failure where the plan worked but did not matter.

People cluster failures around the part they find interesting and miss the boring upstream killers. Deliberately probe the link nobody wants to look at.

### 3. Synthesize

- **Most likely** failure.
- **Most dangerous** failure (highest severity, even if less likely).
- **Biggest hidden assumption:** the one load bearing belief that, if false, takes down several failure modes at once. This is usually the most valuable line, so spend real effort on it.
- **Revised plan:** the original with the top one to three gaps closed, plus the leading indicators to watch and the threshold at which to stop or change course.

## Output template

```
PREMORTEM: <plan in one line>
Success by <horizon> was: <concrete definition>

It is <horizon> from now. The plan is dead. Here is the autopsy.

1. <Failure name> [likelihood / severity]
   How it died: <story>
   Early signs: <leading indicators>
2. ...

SYNTHESIS
- Most likely: <which, why>
- Most dangerous: <which, why>
- Biggest hidden assumption: <the load bearing belief>
- Revised plan: <original + gaps closed + indicators and stop thresholds>
```

## Quality bar

A good premortem is specific and uncomfortable. A bad one is generic and reassuring.

- Each failure is a story someone can picture, with a named mechanism.
- At least one failure is one the team did not want to hear. If every failure is comfortable, you flinched.
- The hidden assumption makes the reader pause. If it is obvious, dig deeper.
- Commit to a most likely and a most dangerous failure and say why. "Any of these could happen" is not a synthesis.
- No invented numbers. If a figure matters (CPC, conversion rate, margin), either take it from `product_get` or the course with its source, or mark it `[X]` and list it as something to measure.

## Mini example (shape, not a script)

> PREMORTEM: spend 300 USD on Meta ads over 7 days to test a pet grooming glove with one angle.
> Success by 7 days was: at least [X] purchases at a cost per purchase under the break even from product_get, or a clear click to checkout gradient.
>
> It is 7 days from now. The test told us nothing. Autopsy:
> 1. Thin traffic [high / major]. 300 USD bought a few hundred clicks, so zero or two purchases cannot separate a bad product from a bad week. Early sign: day one CPC far above what the margin allows.
> 2. One angle, one creative [high / major]. We tested a single hook, so a fail reads as "product dead" when it was "hook dead". Early sign: strong thumb stop but weak click, or the reverse.
> 3. Supplier reality [medium / fatal]. Listing says 7 to 12 day shipping, an order of the sample shows 25. Refund requests start in week three. Early sign: no sample ordered before launch.
>
> SYNTHESIS. Most likely: thin traffic. Most dangerous: supplier reality, because a winner would still lose money on refunds. Hidden assumption: that the supplier's stated shipping time holds for US addresses. Revised: order a sample first, test three hooks at a lower spend each, and decide the stop rule before launch.

## After the premortem

Present the result and ask whether to act on it. Only after the person agrees:
- Offer `team_decision_record` to record the decision and the stop rule, so the team shares one source of truth.
- Offer `task_create` for each early warning indicator or gap that needs an owner and a date.
- Offer `file_write` to save the premortem to `Products/<product>/premortem-<date>.md` with a summary and tags.

If the premortem shows the real problem is upstream (no validated demand, wrong product, wrong market), say so and suggest going back to product research with `course_search` for the validation method.
