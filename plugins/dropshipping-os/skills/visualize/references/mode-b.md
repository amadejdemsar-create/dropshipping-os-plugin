# visualize Mode B: Explain mode (articles, essays, course lessons, notes)

The full Mode B flow: the two questions, content extraction, optional application to our product, the HTML design system, saving, and the key rules. Load when Step 0 selects Mode B. Step 0, the inputs, the output contract and the Quality Pipeline live in SKILL.md and apply here in full.

## Step 2: Ask two questions

Before generating anything, ask:

**Question 1: Mode**
> "Would you like me to:
> (A) Just explain the key principles and frameworks from this source, or
> (B) Apply them: explain the principles AND tie each one to a specific product or situation of ours?"

**Question 2: Depth**
> "How deep should this go?
> (A) Executive summary: the 3 to 5 biggest ideas, compact (single page feel)
> (B) Comprehensive: all major concepts, frameworks and principles in full sections
> (C) Deep dive: everything above plus detailed breakdowns, diagrams and supporting arguments"

Wait for the answers before proceeding. If the person already stated both in the request, skip the question.

## Step 3: Extract the core content

Read the full source and write down, as structured notes before any HTML:

- **The central thesis**: what is the one thing this source is about?
- **Key frameworks**: named models, processes, checklists, formulas.
- **Core principles**: the major ideas, usually 3 to 10 depending on length.
- **Memorable quotes**: 2 to 4 real quotes that carry the essence.
- **Actionable techniques**: specific practices or steps the author recommends.
- **Contrasts and tensions**: what the source argues against (old way vs new way, common mistake vs correct approach).

For a course lesson, keep the course's own terminology and label every rule "Course rule" with the lesson title as source. These are the course's claims, not team agreements.

## Step 4: If applied (answer B), gather our context

Never invent details about the business. Pull them from the OS:

- `product_get` (or `product_list` to find it) for the product the lesson should be applied to: costs, price, margin, status, notes.
- `task_list` for what the team is currently doing on it.
- `files_tree` and `file_read` for existing research, test results or briefs about that product.
- `course_search` if a related lesson would sharpen an application.

If the OS has nothing relevant, ask the person to describe the product, the audience and the current problem in a few lines.

Use this context to:
- Add an "APPLIED:" annotation under each principle that connects it to our real numbers and situation.
- Turn the author's techniques into concrete next steps for this product.
- Rank which principles matter most for the stage the product is at.

Applied sections are honest and specific. "Our landed cost is X and the lesson says Y, so the first test should be Z" beats "consider improving your margins". If the data to apply a principle does not exist, say what is missing instead of guessing.

## Step 5: Generate the HTML

One self-contained file under the output contract in SKILL.md. The design language below is the Mode B default; per Quality Pipeline step 1, derive a bespoke direction when the source has its own domain or mood.

### Design system

**Typography:**
- Fonts: a body face (Inter works) and a distinct display face for the hero and section titles. Load from Google Fonts with a system fallback stack.
- Hero title: `clamp(40px, 6.5vw, 84px)`. Section titles: `clamp(28px, 4vw, 46px)`.
- Body text 16 to 17 px, dim text 13 to 14 px, labels 11 to 13 px uppercase with letter spacing 2 to 3 px and weight 700.

**Color (CSS custom properties in `:root`):**
- Dark theme default: near-black background with a subtle hue, cards one step lighter, card hover one step lighter again, a subtle border, light text, muted dim text.
- ONE primary accent chosen to match the source's mood: warm gold for mindset and self improvement, purple for creativity, teal for science and systems, blue for business and strategy, green for health and nature, orange for energy and action.
- Accent glow: the accent at 8 to 15 percent opacity for subtle backgrounds.
- Semantic colors: green (positive), red (negative or warning), plus two or three supporting colors with glow variants.
- Offer a light variant only if asked; if included, switch with a CSS-only or in-memory toggle, never `localStorage`.

**Layout:**
- Container `max-width: 1100px; margin: 0 auto; padding: 0 24px;`. Sections `padding: 80px 0` on desktop. Hairline gradient dividers between sections.

**Cards:**
- Surface color, 1 px border, radius 14 to 20 px. Hover: `translateY(-2px)` and a border color change. Big idea cards get larger padding and a subtle radial glow in a corner.

**Tags and pills:** inline-block, 11 px uppercase, background the semantic color at 8 to 12 percent, text in the semantic color, padding `4px 12px`, radius 6 px.

### Structure (top to bottom)

1. **Hero**: full viewport height, centered. Label, giant title, subtitle paragraph, meta line (author, source, date).
2. **Core idea**: the thesis in a big idea card, with an optional diagram.
3. **Key principles and frameworks**: each principle its own section or card grid, with varied layouts: two-column comparisons (old way vs new way), vertical timelines for sequences, three-column grids for technique collections, single large cards for ideas that need space.
4. **Diagrams**: CSS-only (grids with arrows, node layouts, flows) or inline SVG. No images needed.
5. **Quotes**: centered, display face italic, larger, with a cite element.
6. **If applied**: "APPLIED" blocks interspersed, with a marker in the accent color, our real numbers, and a concrete step.
7. **Action items**: numbered cards with priority markers. Applied: specific to our product. Otherwise: the author's recommended practices.
8. **Closing**: a short hero-style section with one clear closing paragraph.

### Responsive (mandatory)

- A `@media (max-width: 768px)` block: collapse all grids to one column, reduce padding and font sizes proportionally, remove hover transforms, stack horizontal diagrams vertically with rotated arrows, hero `min-height: auto`.
- A `@media (max-width: 380px)` block for small phones with further reductions.
- Zero horizontal overflow at 390 px, measured.

### Content guidelines

- Clear, direct language. No filler.
- Each section stands alone as a useful explanation of its concept.
- Use the source's own terminology and structure (numbered principles, acronyms, chapters).
- Quotes are the source's actual words.
- A reader who is not a designer or engineer must understand every label.

## Step 6: Save

Save with `file_write` as `Reports/<source-name>-visual.html` (principles only) or `Products/<product>/<source-name>-applied.html` (applied to a product). Summary: one line on what the page covers. Tags: `visualization`, `explain`, plus the topic. If the source is a course lesson, add the tag `course`. Tell the person the Files path. If they ask for a local copy, write it to the folder they name.

## Key rules (Mode B)

- Never start generating HTML before the mode and depth answers are in.
- Single self-contained file; follow the output contract (no `localStorage`, no fetch, no relative links).
- Every section has desktop and mobile styling.
- The color scheme feels intentional and matched to the source.
- If applied, use real data from `product_get` and Files; never fabricate details about the business.
- No dashes as punctuation in page text.
- No dramatic fragment pairs ("Not X. Y.").
- Quotes are real and attributed.

## Optional: a bilingual page

Only when the person asks for two languages. Put both languages in the one file as two blocks (`data-lang="en"`, `data-lang="sl"`), switch with a small toggle in the top right that flips a class on `<html>` using an in-memory variable (no `localStorage`; the choice resets on reload, default to English). Swap `<title>` and `<html lang>` on toggle. The second language must be written natively for that language, not word for word from the first; have it read once more as a native reader would before saving.
