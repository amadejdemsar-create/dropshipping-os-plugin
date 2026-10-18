---
name: avatar-walkthrough
description: Use to see a product page or an ad through the eyes of the product's avatar and sub avatars, and turn it into a video. Simulated buyers, one per sub avatar, arrive from their ad or straight on the page, scroll on a phone or laptop, think out loud in their own words and decide; a heatmap shows where they look; the end card lists what to change, with a fix next to each finding. Use when someone says "walkthrough", "naredi video kupcev", "poglej stran skozi avatarje", "how would our buyers see this page or ad", before spending on ads, after changing the store, or to compare ad angles against the landing page.
---

# Avatar Walkthrough

You put each sub avatar of a product in front of the real page or ad, as captured today, and write what she looks at, what she thinks and what she does. The output is a video the team can watch in three minutes: an interactive player (pause, skip, chapters, phone layout) and an MP4, plus a written record in Dropshipping OS. The point is to find what stops a buyer before ad money finds it. It is a structured hypothesis, not a measurement: the buyers, their thoughts and the heatmap are written by you from real quotes and the real page, and every finding ends with a way to check it with real visitors.

References live next to this file in references/; read them with the Read tool when a step says so (in Dropshipping OS they are also in Files › Skills).

## What it needs

- A computer with Python 3, Playwright with Chromium, Pillow and ffmpeg. Check in one go: `python3 -c "import playwright, PIL" && ffmpeg -version | head -1`. If something is missing: `pip3 install playwright pillow && python3 -m playwright install chromium`, `brew install ffmpeg`. Without a shell (Claude in the app) you can still do steps 0, 3 and 4 and hand the person the rest.
- What to look at: a product page URL, ads (image or video files, or hooks from the product's creative roadmap), or both, ad first and then the page it sends to.
- Who looks: the product's core avatar and sub avatars, with real customer quotes.

## Step 0: load the brief, never guess it

1. `product_get` for the product: desire, core avatar, sub avatars, angle, offer and prices, the creative roadmap (hooks per cell), decisions.
2. `files_tree` and `file_read` under `Products/<product>/`: avatar research, customer quotes from reviews and forums, earlier walkthroughs in `Products/<product>/walkthroughs/` (read the last one: what changed since?).
3. Ask the person once, in one message, with your defaults filled in: what to review (the page, the ads, or each ad and then the page), which buyers (default: one per sub avatar, three to five), how strict (default strict), the market's language (default English for the USA).
4. If the sub avatars or their quotes are missing, say so. Propose them clearly labeled as a proposal, and never invent a customer quote.

## Step 1: set up the run folder

Make `walkthroughs/<YYYY-MM-DD>-<product>-<what>/` in the person's working folder (never Desktop or Downloads); below it is `RUN`. Unpack the tools from `references/toolkit.md` into `RUN/tools` (in Claude Code the file sits in this skill's folder; elsewhere `file_read` it and save it as a file first). Every file carries a checksum, so a damaged copy fails loudly:

```
TOOLKIT_MD=<path to toolkit.md>; DEST=RUN/tools
python3 - "$TOOLKIT_MD" "$DEST" <<'PY'
import re, sys, hashlib, pathlib
md, dest = sys.argv[1:3]
pathlib.Path(dest).mkdir(parents=True, exist_ok=True)
rx = re.compile('^' + '`' * 4 + r'text file=([^/\s]+) sha256=([0-9a-f]{64})\n(.*?)\n' + '`' * 4 + '$', re.S | re.M)
found = rx.findall(open(md, encoding='utf-8', newline='').read())
if not found: sys.exit('no files found in ' + md)
for name, sha, body in found:
    data = body.encode('utf-8')
    if hashlib.sha256(data).hexdigest() != sha: sys.exit('SHA256 MISMATCH: ' + name)
    p = pathlib.Path(dest, name); p.write_bytes(data)
    if name.endswith('.py'): p.chmod(0o755)
    print('wrote', p)
PY
```

Then `cp RUN/tools/player.html RUN/index.html`. The tools: `capture.py`, `ad_view.py`, `check_walk.py`, `stills.py`, `render.py`, `walk.example.js`.

## Step 2: capture what the buyer sees

- **The page:** `python3 RUN/tools/capture.py <url> RUN --expand` captures it on a phone (390 px) and a laptop (1440 px) as three views each: `mobile-first` (the first screen exactly as it loads, popups, cookie banners and sticky bars included), `mobile` (the whole page, with those overlays hidden so it stitches cleanly; the `-text.md` header lists what was hidden) and `mobile-open` (every FAQ and accordion opened by the tool). Start a buyer who lands on the page with a beat on the first screen, walk the clean page, and use the opened view only for a buyer who opens the FAQ; only then may she react to an answer. Capture once per run and keep the capture time: stores change, and every box id changes with them.
- **Where you capture from changes what you see.** Shopify shows the cookie banner and some popups by region, so a capture from Europe can show a banner a buyer in the USA never sees, and the reverse. Name the capture location in the record and do not report a regional overlay as a finding for another market without checking it from there.
- **An ad:** `python3 RUN/tools/ad_view.py RUN --key ad-<buyer> --image <file> --brand <brand> --text "<primary text>" --headline "<headline>" --cta "Shop now" --domain <domain>`. For a video ad use `--video <file>` with `--transcript <srt or txt>`: it samples the whole video, ending included, and prints the coverage. The filmstrip is a reading aid, not the viewing experience: watch the video and read the full transcript (the `video-watch` skill makes both possible) before you write her beats, so a claim or offer late in the video is not missed. One ad view per ad; buyers who saw the same ad share it.
- Read every `capture/<view>-text.md` from top to bottom and look at the captured images (open slices of the tall JPG). Note what is above the fold on the phone, what is hidden in closed tabs, what the first photo shows, where price, delivery date, reviews and guarantee sit.

## Step 3: premortem first

Run the team skill `premortem` on: "<N> buyers, one per sub avatar, arrive from <their ad / the page>; four weeks later none of them bought." Make it strict. Look hard at:

- ad to page mismatch: the ad opens one story, the first screen of the page tells another
- the cheapest alternative: what the same looking product costs on Amazon or Temu today (check it live and keep the source, or leave it out)
- claims the page itself contradicts (the FAQ admits what the ad hides)
- delivery date against the moment she needs it
- trust: an unknown brand, the review count, who answers if it breaks, how a refund works
- price against what she uses now

Save it as `RUN/premortem.md`. Each failure mode that touches a buyer becomes beats in step 4.

## Step 4: write the buyers

Copy `RUN/tools/walk.example.js` to `RUN/walk.js` and replace the data. The comment block at its top explains every field. After `window.WALK =` it is plain JSON, so the checker reads it as data and never runs it.

- **One buyer per sub avatar.** A first name, an age inside the avatar, a one line situation, and `wants`: one verbatim quote from the research in curly quotes, with `src` saying where the team found it. Put her other quotes in `quotes`, each with its source.
- **From an ad:** her `path` starts with the ad view (two or three beats: the hook, the picture, the button), then the page. On landing, judge first whether the first screen continues the ad's story.
- **Beats:** five to seven per view, 3.2 to 3.6 seconds each, about 30 to 45 seconds per buyer. Every beat looks at a real box id from the `-text.md` files. Eyes go top to bottom the way people scroll, jumping only when something pulls them (price, stars, a photo).
- **Thoughts:** first person, her words, one idea, at most 100 characters. React to what the box really says. Text in curly quotes is copied exactly from the box she is looking at (or is her own sourced words); `check_walk.py` rejects anything else. Numbers come from the page, or from a live check this session whose source you write in the record.
- **Mood:** `+` pulls her in, `-` pushes her away, `?` doubt.
- **Decision:** a hypothesis that follows from her beats, never decided first. Strict means you never answer a doubt for the page: a doubt counts as answered only when the page answers it where she can see it. She buys when her doubts are answered that way; otherwise she leaves, compares elsewhere, bookmarks it or closes the tab, and `why` names the page element that decided it. Check both directions: for every buyer who buys, point to the boxes that answered her doubts; for every buyer who leaves, confirm the doubt is really unanswered on the page.
- **Findings:** four to six rows. Each names the buyer or buyers and the exact page or ad element, and the fix sits next to it: what to change, where, in words the team can act on today (a headline, the photo order, a line under a bundle, an ad to pause, a sample to test first).
- Never present the buyers as real people. The `note` says it is simulated and the heatmap is scripted attention, not measured data.

## Step 5: check, look, fix

1. `python3 RUN/tools/check_walk.py RUN` must pass. It checks structure (views, boxes, timing, fields) and that quoted page text is in the box she looks at. It cannot tell whether a thought is fair or a finding true; that is step 3 and 4.
2. `python3 RUN/tools/stills.py RUN <times>`: the intro, each buyer's middle beat and decision, and the findings; again with `--portrait`. It prints the length. Open every still and look: the gaze on the right element, no clipped text, nothing covered. Fix and repeat.
3. Read `walk.js` once as each buyer, first beat to last: would she think this, here, in these words? Cut what only the team would think.
4. Every claim about the page or the product in the findings and the premortem is checked against the capture, not memory. One wrong claim means you check them all again.

## Step 6: render and hand over

1. `python3 RUN/tools/render.py RUN` writes `<run>.mp4` and `<run>-small.mp4` and verifies frames and length. Watch the small one at three random points.
2. Save the record to Dropshipping OS with `file_write` at `Products/<product>/walkthroughs/<YYYY-MM-DD>-<what>.md`: what was reviewed (URL, ads, capture time), each buyer (sub avatar, ad, decision, why), the findings with fixes and, for each, its evidence (box ids and what they say) and how to check it with real visitors (session recordings, ad comments, a split test, the sample in hand), the premortem's most likely and most dangerous failure, the capture location, and where the video and player are. One line summary, tags `walkthrough` and the product.
3. Hand over: the small MP4 (fits in chat), and the run folder zipped for the interactive player (open `index.html`; it works offline except the fonts). For a link, whoever can push to the dropshipping-os repository copies `index.html`, `walk.js`, `capture/` and the small MP4 into `public/share/<run>-<6 random hex>/`, commits, deploys and opens the link to check it.
4. Reply in the person's language: one line per buyer (who, from which ad, what she did, why), the three fixes that matter most, and the paths or link.

## Never

- Never change the live store, the theme or the ads. This skill only looks and recommends.
- Never invent customer quotes, reviews, ratings, prices or product facts. Unknown stays unknown.
- Never post the result to a team channel unless the person asks.
- Never put paid course material or a customer's personal data in the video, the record or a shared link.

## Maintaining the tools

The source files are `skills/team/avatar-walkthrough/toolkit/` in the dropshipping-os repository. After editing one, run `python3 skills/team/avatar-walkthrough/toolkit/pack.py` (it rewrites `references/toolkit.md`; `--check` fails when it is behind), then `python3 scripts/build-plugin.py`.
