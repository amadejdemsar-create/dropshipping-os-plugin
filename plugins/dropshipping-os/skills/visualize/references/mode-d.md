# visualize Mode D: Data and dashboard mode

The full Mode D pipeline. Load when Step 0 selects Mode D. Step 0, the inputs, the output contract and the Quality Pipeline live in SKILL.md and apply here in full.

Do NOT ask the Mode B mode and depth questions. Render the data fully and ask only about genuine ambiguities: a missing baseline, an unclear unit, an undefined benchmark for "in profit" or "winner".

## Design language

- Data-dense and terminal-grade: "Bloomberg meets the source's domain". Dark theme by default. ONE signature accent for positive or highlight, plus semantic red (loss or risk) and orange (warning or neutral), plus a distinct accent per major section, all as `:root` custom properties.
- A distinctive display font for headings and big numbers, a clean body font. All numerals bold with `font-variant-numeric: tabular-nums`.
- Cards with about 12 px radius, a 1 px subtle border, alternating row shading two shades apart, accent-tinted row hover with a colored inset edge. A subtle page atmosphere (faint radial accent glow, hairline grid) instead of flat black.
- Staggered `@keyframes` reveals on sections and chart fills; `prefers-reduced-motion` honored.

## Required structure (adapt to the data, keep the order)

1. **Sticky header**: identity on the left (name and tagline), a stat strip on the right with 3 or 4 headline numbers and the data's reference date, deltas colored semantically.
2. **Section tabs**: anchor-linked cards, one per data section, each with its accent color and a count or total. A tab without a target section renders inert, never mislinked.
3. **Data tables**: the exact columns from the source. Per row: a status dot (signature color above benchmark, red below, gray unknown); a CSS bar next to weight, spend or margin columns, width proportional and colored by threshold; performance columns green above baseline, red below, gray for missing values. Wrap each table in `overflow-x: auto` with a min width so mobile scrolls instead of crushing.
4. **Explainer section** (only when the person supplies or asks for concept education): a lead definition with the key phrase highlighted, side-by-side rails (status quo vs proposal), a card grid, a flow of steps.
5. **Comparative scale section** (when entities are compared by size): proportional horizontal bars on a LINEAR scale with "Nx baseline" multiples. Add a squarified treemap (geometry computed offline with a short script and hard-coded) only when there are many entities, switched via a CSS-only hidden-radio toggle. Leave subset categories out of the treemap (they double count area) and say so in the caption. Tiny boxes get labels plus `title` tooltips.
6. **Key signal cards**: verdicts, catalysts or risks as cards with colored borders and small chips. Each verdict states the rule that produced it.
7. **Sources block and methodology note**: numbered linked sources, per-row `[n]` tags, overlaps and deliberate exclusions named, the data's reference date and where it came from (for example "export pasted by the team, 3. 10. 2026" or "product_get, read 3. 10. 2026").
8. **Footer**: attribution, the data date, and a short disclaimer where relevant (estimates, platform numbers that change).

## Data rules

- Figures the team supplied (pasted exports, `product_get` fields) render verbatim and are labeled as the team's data. Derived values you compute (margins, ROAS, break-even, multiples, shares, bar widths, treemap rectangles) are recomputed in code, not eyeballed, mutually consistent, and the formula is stated once on the page.
- Money from the OS is integer cents: convert for display and show the currency. Unknown is shown as "unknown", never as 0, and an unknown never feeds a computed total silently; say which rows were left out of a sum.
- Every externally sourced number goes through a live check (WebSearch, WebFetch) before it enters the page. No figure from memory.
- Logos: only when the source has them or an official source is reachable; embed small base64 versions inside light circular chips so dark marks survive the dark theme. Otherwise use the name in text. Do not hand-draw brand marks.
- Benchmarks (for example "good CTR", "break-even ROAS") are labeled as rules of thumb or as Course rule with the source, never stated as fact.

## Save and finish

Save with `file_write` as `Reports/<source-name>-dashboard.html`, or `Products/<product>/<source-name>-dashboard.html` when it is about one product. Tags: `visualization`, `dashboard`, plus the product or topic. Summary: the data date and what the page answers. Then run Quality Pipeline steps 5 to 7 (verification, save, handover).

## Mode D example

Source: a pasted export of five ad sets from a creative test (spend, purchases, revenue, CTR) and a product from `product_get` with price and landed cost.
Result: header with total spend, blended ROAS and break-even ROAS (computed from the product's margin, formula shown); a table with a status dot per ad set against break-even; a spend bar and a ROAS bar per row on linear scales with the break-even line marked; three verdict cards (scale, keep testing, kill) each quoting its rule; a Sources block naming the export and the date; checked at 1440 px and 390 px.
