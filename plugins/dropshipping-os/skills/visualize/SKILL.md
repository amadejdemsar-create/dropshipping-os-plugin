---
name: visualize
description: Turn a product, file, course document, pasted text or URL into a premium single-file HTML page, dashboard or report and save it in Dropshipping OS Files. Use when someone asks to visualize, present, compare or dashboard something, for example an offer comparison, test results or a competitor ad breakdown.
---

# visualize <source>

Transform any text or data source into one polished, self-contained HTML file that opens inside Dropshipping OS under Files.

References live next to this file in references/; read them with the Read tool when a step says so (in Dropshipping OS they are also in Files › Skills).

The skill has three modes, chosen from the shape of the source:

- **Mode B, Explain mode** (default): articles, essays, course lessons, notes, competitor write-ups. Explains the key ideas and frameworks, optionally applied to our product. Pipeline: `references/mode-b.md`.
- **Mode P, Plan mode**: test plans, launch plans, strategy docs, supplier proposals, roadmaps, anything with phases, timelines, risks and budgets. Sticky-nav, scroll-spy presentation. Pipeline: `references/mode-p.md`.
- **Mode D, Data mode**: anything where tables of entities and numbers dominate: offers side by side, test results, ad metrics, supplier price lists, competitor rankings, or whenever someone says "dashboard" or "tracker". Pipeline: `references/mode-d.md`.

Every mode runs the Quality Pipeline below. It separates a template render from a page the team can use in a decision. Never skip it.

## Who reads the result

The team members and anyone they show it to, usually on a laptop and often on a phone. They know the product and the niche, not the jargon of design or code. Write labels and headings in plain words, in the language of the source (the app UI itself is English).

## Inputs

Ingest whichever of these the person names, then confirm in one line what you got (title, rough length, what it is about):

- **A product**: `product_get` returns its fields (costs, prices, margins, status). Use `product_list` to find it if only a name is given. Money is stored in integer cents: divide by 100 for display. A value that is unknown (null) is shown as "unknown", never as 0.
- **A file in the OS**: browse with `files_tree`, then `file_read`. Note the returned version in case you later replace the same file.
- **A course document**: `course_search` to find it, `course_get` to read it. Label figures and rules taken from it as "Course rule" with the lesson as source, never as a team agreement. Course material is paid and private: the page stays in OS Files, behind team login. Do not paste it to public sites or share the HTML outside the team.
- **Pasted text or data**: use it as given.
- **A URL**: fetch it with WebFetch (or WebSearch to locate it first) and keep the final URL for the Sources block. A bot wall or 403 is not a finding; say the page could not be read and ask for a paste.
- **Several of the above**: allowed. Say which figure came from which source.

If the source is a PDF or another binary the tools cannot read, say so and ask for the text.

## Step 0: Detect the mode

**Mode D (any one is enough):**
- The person says "dashboard", "tracker", "compare these offers", "results".
- Half or more of the source is tables of entities with numbers, or a list of records with repeated numeric fields (prices, margins, CTR, ROAS, spend, orders, delivery days).
- The data has a reference date.

**Mode P (two or more):**
- H2 headings such as "Executive Summary", "Phase Plan", "Risk Register", "Budget", "Success Metrics", "Timeline", "Roadmap", "Open Questions", "Week 1".
- Three or more tables, at least one with weeks or dates, currency, or risk and impact columns.
- The file path or title contains plan, roadmap, strategy, proposal.

**Mode B (default):** a single-voice long text with chapters, principles or quotes.

Precedence: D beats P beats B for data-dominated sources; P beats B for plan-shaped documents. Tell the person which mode you picked in one line and offer to switch.

## Output contract (hard limits)

The page opens in a sandboxed iframe inside the OS. Scripts and popups work; same-origin access does not. Therefore:

- **One self-contained `.html` file**, under 1 MB (aim for under 400 KB). Inline CSS and JS. Libraries only from a public CDN (cdn.jsdelivr.net or cdnjs.cloudflare.com), and only when the mode file allows them. Google Fonts as a stylesheet link is fine, always with a system-font fallback so the page still looks right offline.
- **No `localStorage`, `sessionStorage`, cookies or IndexedDB.** They throw in the sandbox. Keep state (tabs, toggles, language, theme) in plain JS variables or CSS-only controls, and let it reset on reload.
- **No fetch or XHR to the app or to other sites.** All data is inlined in the file as it was when you built it.
- **No relative links to other files.** Navigation is in-page anchors (`#section`). External links open with `target="_blank" rel="noopener"`.
- **Set a descriptive `<title>`** and `<meta name="viewport">`.
- Images and logos are embedded as base64 data URIs (resize to about 96 px first) or drawn as inline SVG. Never hotlink an image the page depends on.

## Quality Pipeline (all modes, mandatory)

1. **Design direction first.** Before markup, write three lines for yourself: the one feeling the page should give, the accent color and type pairing derived from the source's own domain (beauty, pets, tools, kitchen, fitness each look different), and the one thing a reader must find in five seconds. The per-mode design systems are defaults, not a uniform; never converge on the same look every time. Define all colors as CSS custom properties in `:root`.
2. **Quality bar for anything a person reads.** Real hierarchy (one clear first read), consistent spacing on a 4 or 8 px grid, readable body text (16 px or more, line height 1.5 or more), contrast at least 4.5:1, direct labels on charts instead of legend hunting, every named product or competitor linked when a URL is known, tabular numerals for numbers, empty and error states written (what shows when a list is empty or a value is unknown). No stock-template look: no purple-blue gradient on white, no identical rounded cards in a three-column row for everything.
3. **Verify data, cite in the page.** A statistic, price, market size or ranking that did not come from the source gets a live check (WebSearch or WebFetch) before it enters the page. A figure from memory is never used. The page itself carries the receipts: per-item source tags, a numbered Sources block near the bottom with links, a short methodology note (what was excluded and why), and a `~` in front of estimates. Figures the team typed in or that came from `product_get` are shown as the team's data, not re-derived. Derived values (margins, shares, ROAS, bar widths) are recomputed in code or by script, shown consistent with each other, and the formula is stated once.
4. **Computed layouts, no heavy frameworks.** Plain CSS with custom properties. For treemaps, gantts and similar layouts compute the geometry (a short Python or JS script, run with Bash) and hard-code the result. Interactions are CSS-only where possible (hidden-radio tabs, `<details>`, hover, `title` tooltips) plus small inline JS for scroll-spy and copy buttons. Staggered reveal animations are fine; honor `prefers-reduced-motion`.
5. **Verify by looking.** After writing the file locally (use a scratch folder such as a temp directory, not the repo):
   - If Playwright or any headless browser is available (`npx playwright` or a Python install), screenshot at 1440 px and 390 px, plus a 2x close-up of every dense section, and look at each image. Compare against the brief.
   - Measure at 390 px: `document.documentElement.scrollWidth` must not exceed `window.innerWidth`. Fix any overflow and re-shoot.
   - If no browser is available, say so in the handover, and instead run a static review: every `id` that an anchor points to exists, no `localStorage` or `fetch` in the file (`grep -nE "localStorage|sessionStorage|fetch\(|XMLHttpRequest|document.cookie"` returns nothing), file size under 1 MB, every table wrapped in `overflow-x: auto`.
   - Only after this say "done".
6. **Save in Dropshipping OS.** Use `file_write` with `path`, `content` (the full HTML), a one-line `summary`, and `tags`:
   - Product related: `Products/<product-name>/<descriptive-name>.html`. Everything else: `Reports/<descriptive-name>.html`.
   - Tags: `visualization`, the mode (`explain`, `plan` or `dashboard`), and the product or topic. Add them with `file_write` or afterwards with `file_tags_set`.
   - `file_write` creates a new file. To replace one that exists, `file_read` it first and pass its version as `expected_version`; if the version is stale, re-read, merge and retry, never overwrite blind.
   - The page then opens inside the OS under Files. If the person also wants a local copy, write it to the folder they name with the Write tool.
7. **Handover.** Say who the page was written for in one clause, the mode used, the Files path, what was checked (screenshots, widths, grep), and any figure you could not verify. Offer one next step, for example "want a Slovenian version" or "want this refreshed when the new test numbers arrive".

## Dropshipping examples

**Offer comparison (Mode D).** Source: three offers for the same product, from `product_get` for ours plus pasted competitor prices. Page: sticky header with the headline numbers (best margin, lowest landed cost, fastest delivery), one table with a row per offer and a column per figure (landed cost, price, margin in percent and EUR, delivery days, refund policy), status dots against the margin target, a bar column for margin, a short "what decides it" card pair, and a Sources block linking each competitor page with the date it was read.

**Test results dashboard (Mode D).** Source: a pasted export of ad sets (spend, purchases, CTR, CPC, ROAS) for a creative test. Page: stat strip (total spend, blended ROAS, best ad set, days running), a table with the winner row marked and losers grayed, proportional spend and ROAS bars on a linear scale with the break-even ROAS drawn as a marked line, a verdict card ("scale", "keep testing", "kill") per ad set with the rule that produced it written out, and a note that the figures are the team's export as of its date. Break-even ROAS is computed from the product's margin, with the formula shown.

**Competitor ad breakdown (Mode B or D).** Source: a list of competitor ad URLs plus notes. Page: one card per ad with hook, angle, offer, proof used and format, a comparison grid of angles across competitors, a "gaps nobody covers" section, every ad linked. Claims about an ad are only what was actually seen in it.

## Rules that hold in every mode

- Render the source as written. Do not add your own opinions inside a section that claims to present the source; put interpretation in a clearly labeled "Reading" or "Takeaways" block.
- Quotes are real words from the source, attributed, never invented.
- No emoji and no dashes as punctuation in page text; use commas, colons or periods.
- Do not translate unless asked. If a translated version is requested, produce it as a separate file and keep names and numbers identical.
- Never print or embed credentials, API keys or private contact data that happened to be in a source.
- One file only. If the result would exceed 1 MB, cut embedded images before cutting content.
