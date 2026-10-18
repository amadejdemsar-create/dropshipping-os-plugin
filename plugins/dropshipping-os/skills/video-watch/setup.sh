#!/usr/bin/env bash
# Setup for the video-watch skill: ffmpeg, yt-dlp, and a local faster-whisper venv.
# Idempotent. Safe to re-run (also use it to upgrade yt-dlp, which moves fast).
#
# The venv never lives inside the plugin folder (it is read-only and replaced on update).
# Location: $VW_VENV, else ${CLAUDE_PLUGIN_DATA}/video-watch/.venv,
# else $HOME/.cache/dropshipping-os/video-watch/.venv.
set -euo pipefail

if [ -n "${VW_VENV:-}" ]; then
  VENV="$VW_VENV"
elif [ -n "${CLAUDE_PLUGIN_DATA:-}" ]; then
  VENV="$CLAUDE_PLUGIN_DATA/video-watch/.venv"
else
  VENV="$HOME/.cache/dropshipping-os/video-watch/.venv"
fi
echo "video-watch setup (venv: $VENV)"

have_brew=0
command -v brew >/dev/null 2>&1 && have_brew=1
BREW_URL='/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
missing=0

# 1. ffmpeg + ffprobe (frame + audio extraction)
if ! command -v ffmpeg >/dev/null 2>&1; then
  if [ "$have_brew" = 1 ]; then
    echo "installing ffmpeg..."; brew install ffmpeg
  else
    echo "MISSING: ffmpeg. Install Homebrew first, then run: brew install ffmpeg"
    echo "  Homebrew: $BREW_URL"
    missing=1
  fi
else
  echo "ffmpeg present: $(command -v ffmpeg)"
fi

# 2. yt-dlp (download + caption fetch across 1000+ sites). Keep it current.
if ! command -v yt-dlp >/dev/null 2>&1; then
  if [ "$have_brew" = 1 ]; then
    echo "installing yt-dlp..."; brew install yt-dlp
  else
    echo "MISSING: yt-dlp. Install Homebrew first, then run: brew install yt-dlp"
    echo "  Homebrew: $BREW_URL"
    missing=1
  fi
else
  echo "yt-dlp present: $(yt-dlp --version)"
  if [ "$have_brew" = 1 ]; then brew upgrade yt-dlp 2>/dev/null || true; fi
fi

# 3. Local Whisper (free, offline transcription) via a dedicated uv venv
if ! command -v uv >/dev/null 2>&1; then
  if [ "$have_brew" = 1 ]; then
    echo "installing uv..."; brew install uv
  else
    echo "MISSING: uv. Install Homebrew first, then run: brew install uv"
    echo "  or: curl -LsSf https://astral.sh/uv/install.sh | sh"
    missing=1
  fi
fi

if [ "$missing" = 1 ]; then
  echo ""
  echo "Setup incomplete: install the missing tools above, then run this script again."
  exit 1
fi

if [ ! -x "$VENV/bin/python" ]; then
  echo "creating venv..."; mkdir -p "$(dirname "$VENV")"; uv venv "$VENV"
fi
echo "installing/upgrading faster-whisper..."
# av is pinned below 18: faster-whisper 1.2.1 calls av.open(metadata_errors=...), which av 19 rejects.
uv pip install --python "$VENV/bin/python" --upgrade faster-whisper "av>=11,<18"
"$VENV/bin/python" -c "import faster_whisper; print('faster-whisper', faster_whisper.__version__)"

echo ""
echo "done. Local transcription is ready (free, offline). venv: $VENV"
echo "Optional faster cloud transcription: set GROQ_API_KEY or OPENAI_API_KEY"
echo "(environment, or in ~/.config/watch/.env)."
