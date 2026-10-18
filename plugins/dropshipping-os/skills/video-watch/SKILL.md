---
name: video-watch
description: Watch, see, transcribe, or analyze a video from YouTube, TikTok, Instagram, X/Twitter, the Meta Ad Library, or a local file. Use when the team wants Claude to actually watch a video (not just read its title): break down a competitor ad, a UGC clip or a product demo, summarize a course video, transcribe it, pull quotes, describe what is shown on screen, or answer questions about a moment in it. Triggers on a pasted video URL with intent, or phrases like "watch this", "break down this ad", "what happens in this video", "transcribe this", "summarize this video".
---

# Video Watch

Claude cannot stream video. This skill gives it eyes and ears: a Python pipeline downloads the video, extracts JPEG frames with ffmpeg, and pulls a timestamped transcript (native captions first, then local faster-whisper, then optional cloud Whisper). It prints a markdown report listing every frame path. Claude then reads each frame, lines it up with the spoken words, and writes structured notes.

Works for YouTube, TikTok, Instagram, X/Twitter, Vimeo, ad videos from the Meta Ad Library, any of the 1000+ sites yt-dlp supports, and local video files.

## What the team uses it for

- Competitor ads on TikTok, Instagram, Facebook and YouTube: why does this ad work, and how do we make our own version?
- UGC clips from creators: hook, delivery, proof, what to brief.
- Product demo videos from suppliers: what the product does, what is shown, what is missing.
- An ad from the Meta Ad Library: paste the video URL or a downloaded file.
- The course videos: notes, quotes and a timeline so nobody has to rewatch.

## Paths: resolve them first

This plugin is installed under `${CLAUDE_PLUGIN_ROOT}` (read-only). Writable files, including the transcription venv, live under `${CLAUDE_PLUGIN_DATA}`. Both variables are expanded in this text and are normally set in the shell. Before the first command, check them:

```
echo "root=${CLAUDE_PLUGIN_ROOT:-} data=${CLAUDE_PLUGIN_DATA:-}"
```

If `CLAUDE_PLUGIN_ROOT` is empty in the shell, use the absolute path of the folder two levels above this SKILL.md (the folder that holds `skills/` and `agents/`) wherever this file says `${CLAUDE_PLUGIN_ROOT}`. If `CLAUDE_PLUGIN_DATA` is empty, leave it empty: the scripts then use `$HOME/.cache/dropshipping-os/video-watch/.venv`. To pin the venv somewhere else, set `VW_VENV`.

## Protect the context window: prefer the agent

Reading 40 to 100 frames into the main session burns a lot of context. For most requests, delegate to the `dropshipping-os:video-analyst` agent (Task tool, subagent_type `dropshipping-os:video-analyst`). It runs this pipeline, reads the frames in its own context, and returns only the structured summary. Run the pipeline inline only for a short clip where the user wants the frames in the main conversation, or when you are already inside a subagent.

## One-time setup

```
bash "${CLAUDE_PLUGIN_ROOT}/skills/video-watch/setup.sh"
```

It installs `ffmpeg`, `yt-dlp` and `uv` with Homebrew (if Homebrew is missing it prints the exact commands and the Homebrew install line, then stops), and creates the faster-whisper venv in `${CLAUDE_PLUGIN_DATA}/video-watch/.venv`. It is safe to re-run, and re-running upgrades yt-dlp (do that first when a download fails). Local transcription is free and offline.

Optional faster cloud transcription for long videos: set `GROQ_API_KEY` or `OPENAI_API_KEY` in the environment, or in `~/.config/watch/.env` as `GROQ_API_KEY=...`.

## Run the pipeline

```
python3 "${CLAUDE_PLUGIN_ROOT}/skills/video-watch/scripts/watch.py" "<url-or-path>" [flags]
```

`watch.py` finds the venv by itself (same rule as `setup.sh`) and restarts inside it when faster-whisper is needed, so plain `python3` is enough. If it prints that no transcription backend is available, run the setup and try again.

### Transcript priority

1. Native captions via yt-dlp (free, instant).
2. Local faster-whisper (free, offline, the default when there are no captions). The first run downloads the model (about 0.5 GB for `small`). Size via `VIDEO_WATCH_WHISPER_MODEL` (tiny|base|small|medium|large-v3).
3. Cloud Groq/OpenAI Whisper, only when forced with `--whisper groq|openai` and the key is set.

### Flags

- `--start T` / `--end T` (SS, MM:SS or HH:MM:SS): focus on a section, with denser frames. Use for a specific moment or any video over 10 minutes.
- `--max-frames N`: cap (default 80, hard max 100).
- `--resolution W`: frame width in px (default 512; use 1024 when on-screen text or captions are unreadable, common with ads).
- `--whisper local|groq|openai`, `--no-whisper` (frames only).
- `--out-dir DIR`: keep the working files somewhere specific (default: an auto temp dir).

Frame budget: up to 30 s gets up to 30 frames; 30 to 60 s about 40; 1 to 3 min about 60; 3 to 10 min about 80; longer is capped at 100 and sparse.

## Workflow

1. Run `watch.py`. It prints a markdown report: header, a `## Frames` list of `- \`<path>\` (t=MM:SS)` lines, a `## Transcript` of `[MM:SS] text` lines, and the work dir.
2. Read every listed frame in one message (parallel Read calls). Pair each frame's timestamp with the transcript line at that moment.
3. Write the notes (below). Ads get the ad breakdown; everything else gets the general notes.
4. Delete the work dir once the notes exist (it holds the full download and all frames). If the user passed their own `--out-dir`, ask first.

### General notes

```markdown
# <Title>
**Source:** <URL or path>  **Duration:** <mm:ss>  **Transcript source:** <captions / faster-whisper / cloud / none>

## One-line summary
## TL;DR
<3 to 5 bullets>
## Timeline
- **[00:00]** <what is shown + key line spoken>
## Key quotes
> "<verbatim>" [mm:ss]
## Visual notes
<on-screen text, B-roll, graphics, transitions, emotion>
```

### Ad breakdown (competitor ads, UGC, Meta Ad Library)

Return these, with timestamps from the frames and transcript:

- **Hook (first 3 seconds):** exact visual, exact words, on-screen text, and the hook type (pattern interrupt, problem call-out, curiosity, result first, and so on).
- **Angle:** the one idea the ad sells (for example "stop back pain at the desk", not "a product").
- **Desire:** the underlying want or fear it plays on.
- **Offer:** price, discount, bundle, guarantee, urgency, shipping terms, as actually shown or said. Mark anything not shown as "not shown".
- **CTA:** the exact words and where they appear.
- **Shot list with timestamps:** one line per shot: `[00:03-00:06] close-up, hand pressing the button, voiceover says "..."`.
- **On-screen text:** every caption and overlay, verbatim, with time.
- **Format and audio:** length, aspect ratio, UGC or studio, voiceover or talking head, music, subtitles.
- **What to copy and what not:** the structural moves worth reusing (hook pattern, pacing, proof order, CTA placement), and what to avoid copying (their brand name, music, footage, exact script, claims we cannot back up). We make our own version, we do not clone it.

Never state a claim, price or result the video did not show or say. Ad claims are the advertiser's claims, not facts about the product.

## Save results to Dropshipping OS

If the `dropshipping-os` MCP server is connected (a `file_write` tool is available), save the finished notes to Files with `file_write`: folder `Products/<product>/` (use the product the video is about, lowercase, hyphenated; ask when unclear), a descriptive file name such as `ad-breakdown-<brand>-<yyyy-mm-dd>.md`, a two to three sentence summary, and tags such as `ad`, `competitor`, `ugc`, `demo`, `course`. Include the source URL in the note. If the tool is not available, write the notes to the work dir or the folder the user names and say where they are.

## Platform notes and responsible use

- YouTube: most reliable. Age-restricted or members-only videos may need `--cookies-from-browser safari` (or chrome/firefox).
- TikTok: public videos work, usually watermarked. Private ones need cookies.
- Instagram: public posts and reels work; stories and private accounts need login cookies.
- X/Twitter: public posts work; `x.com` links sometimes need rewriting to `twitter.com`.
- Meta Ad Library: the page itself is not a video file. Open the ad, copy the video link, or download the video and pass the local file.
- Download only what you may access, for analysis and learning, never for republishing. Respect each platform's terms and creators' rights.

## Gotchas

- A download fails: re-run `setup.sh` to upgrade yt-dlp, and show yt-dlp's error as it is instead of retrying silently.
- The first local Whisper run pauses to download the model. That is normal once.
- A local file without audio: local Whisper errors cleanly. Use `--no-whisper` for frames only.
- Videos over 30 minutes: confirm with the user and focus with `--start`/`--end`.

## What not to do

- Never invent a video's content from its title or thumbnail. If the pipeline fails, say so.
- Never write the summary before reading the frames.
- Never skip the cleanup of the work dir.

## Engine attribution

The pipeline scripts `download.py`, `frames.py`, `transcribe.py` and `whisper.py` are vendored from [bradautomates/claude-video](https://github.com/bradautomates/claude-video) and [Newuxtreme/watch-video-skill](https://github.com/Newuxtreme/watch-video-skill) (MIT). The local faster-whisper backend (`whisper_local.py`) and the backend selection were added here. See `CREDITS.md`.
