# visualize Mode P: Plan, proposal and strategy documents

The full Mode P pipeline. Load when Step 0 selects Mode P. Step 0, the inputs, the output contract and the Quality Pipeline live in SKILL.md and apply here in full.

Mode P produces a sticky-nav, scroll-spy, decision-ready single-file HTML with gantt-style timelines, risk cards, budget charts and collapsible appendices. Typical sources: a product test plan, a launch plan, a supplier proposal, a budget for a scaling phase, a roadmap.

Do NOT ask the Mode B mode and depth questions. Mode P renders the whole document; depth is controlled by collapsible sections, not by trimming content.

## Step 2p: Parse the document structure

Produce an internal outline:

- Document title (first H1) and optional subtitle (first paragraph after it).
- All H2 sections in order, with their H3 children.
- For each section: inventory tables, code blocks, diagram blocks, callouts.
- Classify each table:
  - **Timeline** if column headers include "week", "day", "date", "when", "phase", "sprint".
  - **Risk** if headers include "likelihood", "impact", "probability", "severity", "mitigation".
  - **Budget / Cost** if any cell contains a currency sign or code (EUR, USD), "/mo", "/yr" or "total".
  - **Metric / Target** if columns mention targets, percentages, ROAS, CPA, CTR, days.
  - **Mapping / Reference** for everything else.

Classification drives rendering in Step 4p. Also detect for the hero: a TL;DR list, the first prominent budget total, the timeline span (first to last week), the top three risks.

If the source is a pasted or file document with no markdown structure, first restructure it into clear headings without changing its content, and say you did.

## Step 3p: Choose the look

Use the default token set below unless the source has its own brand or mood (then derive a bespoke palette and type pairing, per Quality Pipeline step 1). Do not invent a brand for the team; if the document names a brand with colors, use those exactly.

```css
:root {
  --c-bg: #0B0F1A;
  --c-surface: #111726;
  --c-surface-2: #1A2138;
  --c-text: #F5F7FB;
  --c-text-mute: #A7B0C5;
  --c-primary: #6366F1;
  --c-accent: #22D3EE;
  --c-success: #10B981;
  --c-warning: #F59E0B;
  --c-danger: #EF4444;
  --c-border: #2A3250;
  --font-display: 'Space Grotesk', 'Inter', system-ui, sans-serif;
  --font-body: 'Inter', system-ui, sans-serif;
}
```

These are a starting point; shift primary and accent to suit the document's domain so outputs do not all look alike.

## Step 4p: Generate the HTML

One single-file document with this structure (adapt to the source; these sections are required when the source provides the data).

### 4p.1 Head

- Viewport meta, theme-color meta, an inline SVG favicon dot in the primary color.
- Google Fonts link for display and body fonts, with system fallbacks.
- Inline `<style>` with the custom properties and all layout rules.
- Title: the document title.

### 4p.2 Header bar (sticky)

- Left: a simple mark (inline SVG) and the document title condensed.
- Right: a print button (`window.print()`) and an outline toggle on mobile. Skip a theme toggle unless both themes are fully designed; if present it lives in memory only.

### 4p.3 Hero (full viewport height on desktop)

- Eyebrow label (document version and date), big H1, subtitle paragraph.
- **TL;DR cards**: up to 5 cards from the detected TL;DR, each with a number badge and a one-line summary.
- **Snapshot strip**: 3 or 4 big numbers from the document (budget total, timeline span in weeks, risk count, decision count).
- A subtle scroll hint.

### 4p.4 Layout

Desktop: sticky header, left sidebar nav 240 px, main column up to 900 px. Mobile: sticky header with a hamburger, the nav as a drawer, main content full width.

### 4p.5 Sticky left navigation

- Document title (small, muted); ordered list of all H2 sections with numbers; nested H3s visible when the parent is active.
- Scroll-spy with IntersectionObserver highlights the section in view; click smooth-scrolls to the anchor; `aria-current="page"` on the active item.
- Anchors are in-page only (`#sec-...`), they work inside the sandboxed iframe.

### 4p.6 Main content (per section)

```html
<section id="sec-<slug>" class="plan-section">
  <header class="plan-section-header">
    <span class="plan-section-number">01</span>
    <h2>Executive Summary</h2>
    <p class="plan-section-lede">{first paragraph}</p>
  </header>
  <div class="plan-section-body">
    {rendered content}
  </div>
</section>
```

Rendering rules:

- **Paragraphs**: 17 px body, 1.6 line height.
- **Lists**: custom accent markers; ordered lists get accent number badges.
- **Timeline tables**: a horizontal gantt-style track. For a plan with weeks 1 to 8, produce 8 swimlanes; within each, stack task cards showing title, owner badge and hours or budget. Acceptance criteria go inside `<details>`.
- **Risk tables**: a grid of risk cards. Left border colored by likelihood times impact (green low, amber medium, red high). Header: risk name plus `Lk | Im` badges. Body: mitigation and detection. Preserve the source's priority order.
- **Budget tables**: two panels. Left: line items with right-aligned values. Right: a horizontal bar chart showing item weights (Chart.js only if there are 3 or more line items, otherwise plain CSS bars). Bottom: the total as a prominent card. Two budget tables (one-time and recurring) sit side by side on desktop and stack on mobile. Verify totals add up; if the source's total does not match its line items, show the source's figure and flag the mismatch in a note.
- **Metric tables**: a responsive stat grid, one card per row: big number, unit, description, small target badge.
- **Mapping tables**: native HTML table with sticky header, zebra striping, hover highlight, horizontal scroll on mobile.
- **Code blocks**: monospace with a small Copy button (clipboard writes may be blocked in the sandbox, so show "Press Ctrl or Cmd C" as a fallback message when the call fails). Syntax highlighting with Prism only when the source has code in known languages.
- **Diagram blocks** (mermaid): render once via mermaid.js, centered, max width 100 percent, themed to the palette. Never also print the fallback text.
- **Quote blocks**: left-bordered pull quote on a muted surface.

### 4p.7 Collapsible sections

Collapse by default, with a "Show N items" control: the Risk Register if it has more than 8 rows, each week of a week-by-week plan (one `<details>` per week), every appendix. Print mode expands all.

### 4p.8 Footer

Document version and date, a "Generated from" line naming the source (file name in Files, product, or URL, never a local machine path), and a back-to-top button on mobile after 400 px of scroll.

## Step 5p: CDN dependencies (only when needed)

- Google Fonts: the display and body fonts.
- `https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js`: ONLY if the source has diagram blocks.
- `https://cdn.jsdelivr.net/npm/prismjs@1.29.0/prism.min.js` plus a theme CSS: ONLY if the source has code in known languages.
- `https://cdn.jsdelivr.net/npm/chart.js@4`: ONLY if a budget table has 3 or more line items.

Check each library URL once with WebFetch before shipping it. No Tailwind, Bootstrap or other frameworks. Plain CSS with custom properties, under 800 lines of CSS. Target file size under 400 KB (hard limit 1 MB). Every library must degrade gracefully: if a CDN script fails to load, the content is still readable (tables and text remain, the chart area shows its numbers as text).

## Step 6p: Accessibility

- Text contrast at least 4.5:1; every interactive element focusable with a visible focus ring.
- `aria-expanded` on collapsibles; `aria-current="page"` on the active nav item.
- `prefers-reduced-motion` disables smooth scroll and fade-ins.
- Semantic HTML: `<nav>`, `<main>`, `<section>`, `<article>`, `<aside>`, `<header>`, `<footer>`.

## Step 7p: Save and report

- Save with `file_write` as `Reports/<source-basename>-visualization.html`, or `Products/<product>/<source-basename>-visualization.html` when the plan is about one product. Tags: `visualization`, `plan`, plus the product or topic. Summary: one line naming the plan and its date.
- Report in 40 words or fewer: the Files path, the number of sections rendered, which table types were auto converted (timeline, risks, budget, metrics).

## Step 8p: Self-rate before announcing done

Score 1 to 10 on five criteria; fix anything below 8:

1. **Visual hierarchy**: can a reader find any section in 5 seconds?
2. **Information fidelity**: is every non-appendix data point from the source present?
3. **Interaction quality**: do scroll-spy, collapsibles and print work (checked, not assumed)?
4. **Look and feel**: does it read as a premium, purpose-made page rather than a template?
5. **File size**: under 500 KB, and never above 1 MB?

## Failure modes to avoid

- Multiple output files. One `.html` only.
- Any dependency on a separately served asset or a relative link.
- Translating the source. Render as written.
- Editorial commentary inside the plan sections.
- Emoji or dashes as punctuation in page text.
- Dropping table columns in the name of simplification. Convert to a visual or keep the table, never silently drop information.
- Rendering a diagram twice.
- Asking mode or depth questions in Mode P. Just render.

## Mode P examples

A launch plan for a new product, pasted or read with `file_read`, with phases by week, a budget table and a risk table becomes `Products/<product>/launch-plan-visualization.html`: hero with the budget total and the number of weeks, a gantt of the phases, a risk grid, a budget panel with bars.

A supplier proposal with price tiers, lead times and conditions becomes a decision page: tiers as a budget panel, lead times as a timeline, conditions as a risk grid with the points to negotiate marked.
