# Avatar walkthrough toolkit (bundle)

Every file of the toolkit in one document: page capture, ad mock, checker, the HTML player and the packer. Files: _serve.py, _views.py, ad_view.py, capture.py, check_walk.py, pack.py, player.html, render.py, stills.py, walk.example.js. Each block carries its sha256; unpacking fails loudly on a mismatch. Regenerate this file with `python3 pack.py` from the toolkit folder (`--check` tells whether it is out of date).

Unpack (set TOOLKIT_MD to this file and DEST to an empty folder; needs python3, playwright, Pillow, ffmpeg, node):

```bash
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

````text file=_serve.py sha256=df0fefef893f6e645f0b68583b369afe7502cd57e4a810f44abcfac1585129f6
"""Serve a folder over http on a free localhost port in a background thread."""
import contextlib
import functools
import http.server
import threading


class _Quiet(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


@contextlib.contextmanager
def serve(folder):
    """Yield the base URL (http://127.0.0.1:PORT/) serving `folder`."""
    handler = functools.partial(_Quiet, directory=str(folder))
    srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
    th = threading.Thread(target=srv.serve_forever, daemon=True)
    th.start()
    try:
        yield f"http://127.0.0.1:{srv.server_address[1]}/"
    finally:
        srv.shutdown()
        srv.server_close()

````

````text file=_views.py sha256=355f510ab16729f7dc2b0f7fd6ff47caa16dd210796134146dccb76a21a9cb61
"""Shared helpers for the avatar-walkthrough toolkit: views.js merge, tile stitching, text map."""
import json, os, re
from datetime import datetime, timezone
from pathlib import Path

TILE = 3000  # css px per screenshot tile


def now_iso():
    return datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')


def read_views(run_dir):
    p = Path(run_dir) / 'capture' / 'views.js'
    if not p.exists():
        return {}
    src = p.read_text(encoding='utf-8')
    m = re.search(r'window\.VIEWS\s*=\s*(.*?);?\s*$', src, re.S)
    try:
        return json.loads(m.group(1)) if m else json.loads('x')
    except ValueError:
        # never evaluate it as code: views.js is data the tools write as JSON
        raise SystemExit(f'error: {p} is not in the format the tools write (window.VIEWS = <JSON>). '
                         'Move it away and capture again.')


def merge_view(run_dir, key, view):
    """Replace `key` in capture/views.js, keep every other view."""
    views = read_views(run_dir)
    views[key] = view
    p = Path(run_dir) / 'capture' / 'views.js'
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text('window.VIEWS = ' + json.dumps(views, ensure_ascii=False, indent=1) + ';\n', encoding='utf-8')
    return views


def screenshot_tiles(page, width, height, tmp_dir, prefix):
    """Clip tiles of TILE css px (full_page + clip works on very tall pages)."""
    files = []
    for i, y in enumerate(range(0, height, TILE)):
        f = Path(tmp_dir) / f'{prefix}-tile{i}.png'
        page.screenshot(path=str(f), full_page=True,
                        clip={'x': 0, 'y': y, 'width': width, 'height': min(TILE, height - y)})
        files.append(f)
    return files


def stitch(tiles, out, dpr, quality=86):
    from PIL import Image
    ims = [Image.open(t).convert('RGB') for t in tiles]
    W = ims[0].width
    H = sum(i.height for i in ims)
    canvas = Image.new('RGB', (W, H), 'white')
    y = 0
    for im in ims:
        canvas.paste(im, (0, y)); y += im.height
    canvas.save(out, 'JPEG', quality=quality, optimize=True)
    for t in tiles:
        os.remove(t)
    return W, H


def write_text_map(run_dir, key, header, boxes):
    """capture/<key>-text.md: one line per box, for the AI to pick boxes from."""
    lines = [header, '']
    for b in boxes:
        t = (b['text'] or '').replace('\n', ' ')
        lines.append(f"{b['id']:<10} {b['kind']:<8} y {b['y']:<5} {t}")
    cap = Path(run_dir) / 'capture'
    (cap / f'{key}-text.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    (cap / f'{key}-boxes.json').write_text(json.dumps(boxes, ensure_ascii=False, indent=1), encoding='utf-8')

````

````text file=ad_view.py sha256=399d9480e16c1ba10e4415b9742a1edbc877ff0dfb80449ddb0f23ae71eb1394
#!/usr/bin/env python3
"""Build the view of an ad as a buyer meets it in a generic social feed (390 px wide phone).

usage: ad_view.py RUN_DIR --key ad-jess (--image PATH | --video PATH [--transcript PATH] [--every 1.5])
                  [--brand NAME] [--text "primary text"] [--headline "..."] [--cta "Shop now"] [--domain example.com]

Image: skeleton post, the ad post (brand, Sponsored, text, image, domain/headline/CTA row), skeleton post.
Video: frames every --every seconds across the whole video, ending included (24 at most, spread evenly when the
video is longer), as cards with a time label and the line spoken then. A filmstrip is a reading aid, not the
viewing experience: watch the video and read its full transcript as well.
Writes RUN_DIR/capture/<key>.jpg, <key>-boxes.json, <key>-text.md and merges into views.js.
Neutral feed: no platform branding on purpose.
"""
import argparse, html, json, re, shutil, subprocess, sys, tempfile
from pathlib import Path
from playwright.sync_api import sync_playwright

sys.path.insert(0, str(Path(__file__).resolve().parent))
import _views

W, DPR = 390, 2
COLORS = ['#4f6bed', '#d9534f', '#2f9e6f', '#b8791f', '#8e5bd1', '#1f8aa8', '#c2427e', '#4a5568']

CSS = '''
*{box-sizing:border-box;margin:0;padding:0}
body{width:390px;background:#eceef1;font:15px/1.4 -apple-system,"Segoe UI",Helvetica,Arial,sans-serif;color:#1c1e21;padding:8px 0}
.card{background:#fff;margin:0 0 8px;padding:12px 0 0}
.sk .row{display:flex;gap:10px;align-items:center;padding:0 12px 12px}
.sk .av{width:40px;height:40px;border-radius:50%;background:#dfe2e6;flex:none}
.sk .ln{height:10px;border-radius:5px;background:#e4e6ea;margin-bottom:7px}
.sk .blk{height:120px;background:#e9ebee;margin-top:2px}
.sk .bar{display:flex;gap:8px;padding:12px}.sk .bar i{height:28px;flex:1;border-radius:14px;background:#eceef1}
.hd{display:flex;gap:10px;align-items:center;padding:0 12px 8px}
.av{width:40px;height:40px;border-radius:50%;color:#fff;font-weight:700;font-size:18px;display:flex;align-items:center;justify-content:center;flex:none}
.brand{font-weight:600;font-size:15px;display:inline-block}
.sp{font-size:12.5px;color:#65676b;display:block}
.ptxt{padding:2px 12px 10px;white-space:pre-wrap;overflow-wrap:anywhere;font-size:15px}
.media{display:block;width:100%}
.media img{display:block;width:100%;height:auto}
.link{display:flex;align-items:center;gap:10px;background:#f0f2f5;padding:10px 12px;border-top:1px solid #e4e6ea}
.link .l{flex:1;min-width:0}
.dom{font-size:12px;color:#65676b;text-transform:uppercase;letter-spacing:.2px;display:block}
.hl{font-weight:600;font-size:15px;line-height:1.25;display:block;overflow-wrap:anywhere}
.cta{background:#dfe3e8;border:0;border-radius:6px;padding:8px 14px;font:600 14px/1.2 inherit;color:#1c1e21;white-space:nowrap;display:inline-block}
.strip .fc{position:relative;border-top:1px solid #e4e6ea}
.tl{display:inline-block;background:#1c1e21;color:#fff;font:600 12px/1 ui-monospace,Menlo,monospace;padding:5px 7px;border-radius:4px;margin:8px 12px}
.fr{display:block;width:100%;height:auto}
.cap{padding:8px 12px 10px;font-size:14px;color:#3a3d42;min-height:20px}
.cap.empty{color:#a0a4aa;font-style:italic}
'''


def esc(s):
    return html.escape(s or '', quote=True)


def skeleton():
    return ('<div class="card sk"><div class="row"><div class="av"></div><div style="flex:1"><div class="ln" style="width:45%"></div>'
            '<div class="ln" style="width:25%;margin:0"></div></div></div><div style="padding:0 12px 10px"><div class="ln" style="width:92%"></div>'
            '<div class="ln" style="width:70%"></div></div><div class="blk"></div><div class="bar"><i></i><i></i><i></i></div></div>')


def header(brand, text):
    color = COLORS[sum(map(ord, brand)) % len(COLORS)]
    h = (f'<div class="hd"><div class="av" style="background:{color}">{esc(brand[:1].upper())}</div><div>'
         f'<span class="brand" data-box="brand" data-kind="brand">{esc(brand)}</span><span class="sp">Sponsored</span></div></div>')
    if text:
        h += f'<div class="ptxt" data-box="text" data-kind="p">{esc(text)}</div>'
    return h


def link_row(domain, headline, cta):
    if not (domain or headline or cta):
        return ''
    l = '<div class="link"><div class="l">'
    if domain: l += f'<span class="dom" data-box="domain" data-kind="a">{esc(domain)}</span>'
    if headline: l += f'<span class="hl" data-box="headline" data-kind="h3">{esc(headline)}</span>'
    l += '</div>'
    if cta: l += f'<span class="cta" data-box="cta" data-kind="button">{esc(cta)}</span>'
    return l + '</div>'


def fmt_t(t):
    m, s = divmod(t, 60)
    return f'{int(m)}:{s:04.1f}'


def parse_ts(s):
    s = s.strip().replace(',', '.')
    parts = [float(x) for x in s.split(':')]
    t = 0.0
    for p in parts:
        t = t * 60 + p
    return t


def parse_transcript(path):
    """-> list of (start, end|None, text)"""
    raw = Path(path).read_text(encoding='utf-8', errors='replace').replace('\r', '')
    cues = []
    if '-->' in raw:
        for block in re.split(r'\n\s*\n', raw):
            lines = [l for l in block.split('\n') if l.strip()]
            for i, l in enumerate(lines):
                m = re.match(r'\s*([\d:.,]+)\s*-->\s*([\d:.,]+)', l)
                if m:
                    txt = re.sub(r'<[^>]+>', '', ' '.join(lines[i + 1:])).strip()
                    if txt: cues.append((parse_ts(m.group(1)), parse_ts(m.group(2)), txt))
                    break
    else:
        for l in raw.split('\n'):
            m = re.match(r'\s*\[?(\d+(?::\d+){1,2}(?:[.,]\d+)?)\]?\s*[-–:]?\s*(.+)', l)
            if m: cues.append([parse_ts(m.group(1)), None, m.group(2).strip()])
        for i, c in enumerate(cues):
            c[1] = cues[i + 1][0] if i + 1 < len(cues) else c[0] + 5
        cues = [tuple(c) for c in cues]
    return cues


def caption_at(cues, t):
    hit = [c[2] for c in cues if c[0] <= t + 0.05 < c[1]]
    return ' '.join(hit)


def extract_frames(video, every, tmp):
    dur = float(subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', video],
                               capture_output=True, text=True, check=True).stdout.strip())
    # cover the whole video, ending included: every `every` seconds while that fits in 24 frames,
    # otherwise 24 frames spread evenly from the first to the last moment
    end = max(0.0, dur - 0.1)
    if end / every <= 23:
        times = [round(i * every, 2) for i in range(int(end // every) + 1)]
        if end - times[-1] > 0.5: times.append(round(end, 2))
    else:
        times = [round(i * end / 23, 2) for i in range(24)]
    print(f'video {dur:.1f} s: {len(times)} frames from 0:00 to {fmt_t(times[-1])}, '
          f'one every {(times[1] - times[0]) if len(times) > 1 else 0:.1f} s', flush=True)
    out = []
    for i, t in enumerate(times):
        f = Path(tmp) / f'f{i:02d}.jpg'
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-ss', str(t), '-i', video, '-frames:v', '1',
                        '-vf', f'scale={W * DPR}:-2', '-q:v', '3', str(f)], check=True)
        if f.exists(): out.append((t, f))
    return dur, out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('run_dir'); ap.add_argument('--key', required=True)
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument('--image'); g.add_argument('--video')
    ap.add_argument('--transcript'); ap.add_argument('--every', type=float, default=1.5)
    ap.add_argument('--brand', default='Brand'); ap.add_argument('--text', default='')
    ap.add_argument('--headline', default=''); ap.add_argument('--cta', default='')
    ap.add_argument('--domain', default='')
    a = ap.parse_args()
    if a.every <= 0: sys.exit('--every must be > 0')
    src = Path(a.image or a.video)
    if not src.exists(): sys.exit(f'not found: {src}')

    tmp = Path(tempfile.mkdtemp(prefix='adview-'))
    try:
        body = skeleton() + '<div class="card">' + header(a.brand, a.text)
        frame_meta = []
        if a.image:
            shutil.copy(src, tmp / ('ad' + src.suffix.lower()))
            body += f'<div class="media" data-box-group="image"><img src="ad{src.suffix.lower()}"></div>'
        else:
            cues = parse_transcript(a.transcript) if a.transcript else []
            dur, frames = extract_frames(str(src), a.every, tmp)
            if not frames: sys.exit('ffmpeg produced no frames')
            body += '<div class="strip">'
            for i, (t, f) in enumerate(frames):
                cap = caption_at(cues, t)
                frame_meta.append((fmt_t(t), cap))
                body += (f'<div class="fc"><span class="tl">{fmt_t(t)}</span><img class="fr" src="{f.name}" data-frame="{i}">'
                         f'<div class="cap{"" if cap else " empty"}">{esc(cap) if cap else ""}</div></div>')
            body += '</div>'
        body += link_row(a.domain, a.headline, a.cta) + '</div>' + skeleton()
        page_html = f'<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=390"><style>{CSS}</style><body>{body}</body>'
        (tmp / 'ad.html').write_text(page_html, encoding='utf-8')

        with sync_playwright() as p:
            b = p.chromium.launch(chromium_sandbox=True)
            pg = b.new_context(viewport={'width': W, 'height': 844}, device_scale_factor=DPR, is_mobile=True, has_touch=True).new_page()
            pg.goto((tmp / 'ad.html').as_uri(), wait_until='load')
            pg.evaluate("Promise.all(Array.from(document.images).map(i=>i.complete?1:new Promise(r=>{i.onload=i.onerror=r})))")
            pg.wait_for_timeout(200)
            raw = pg.evaluate('''() => {
              const R = e => { const r = e.getBoundingClientRect(); return {x: Math.round(r.left + scrollX), y: Math.round(r.top + scrollY), w: Math.round(r.width), h: Math.round(r.height)}; };
              const out = [];
              document.querySelectorAll('[data-box]').forEach(e => out.push({name: e.dataset.box, kind: e.dataset.kind, text: (e.textContent || '').replace(/\\s+/g,' ').trim(), ...R(e)}));
              const im = document.querySelector('[data-box-group=image] img');
              if (im) out.push({name: 'image', kind: 'img', text: '', ...R(im)});
              document.querySelectorAll('img[data-frame]').forEach(e => out.push({name: 'frame', kind: 'frame', text: '', ...R(e)}));
              return {boxes: out, height: Math.ceil(document.documentElement.scrollHeight)};
            }''')
            height = raw['height']
            tiles = _views.screenshot_tiles(pg, W, height, tmp, a.key)
            cap_dir = Path(a.run_dir) / 'capture'; cap_dir.mkdir(parents=True, exist_ok=True)
            _views.stitch(tiles, cap_dir / f'{a.key}.jpg', DPR)
            b.close()

        order = ['brand', 'text', 'image', 'frame', 'domain', 'headline', 'cta']
        items = []
        fi = 0
        for r in sorted(raw['boxes'], key=lambda r: (r['y'], r['x'])):
            if r['name'] == 'image':
                third = r['h'] / 3
                for j, lab in enumerate(('image top', 'image middle', 'image bottom')):
                    items.append(dict(kind='img', text=lab, x=r['x'], y=round(r['y'] + j * third), w=r['w'], h=round(third)))
            elif r['name'] == 'frame':
                t, cap = frame_meta[fi]; fi += 1
                items.append(dict(kind='frame', text=f'{t} {cap}'.strip(), x=r['x'], y=r['y'], w=r['w'], h=r['h']))
            else:
                items.append(dict(kind=r['kind'], text=r['text'], x=r['x'], y=r['y'], w=r['w'], h=r['h']))
        # domain sits above headline in the same row, so sort again by y then x
        items.sort(key=lambda r: (r['y'], r['x']))
        boxes = [dict(id=f'{a.key}-{i}', **it) for i, it in enumerate(items, 1)]
        when = _views.now_iso()
        view = dict(key=a.key, src=f'capture/{a.key}.jpg', w=W, h=height, frame='phone', url='',
                    label='In {pronoun} feed', captured=when, title=f'Ad: {a.brand}', boxes=boxes)
        _views.merge_view(a.run_dir, a.key, view)
        _views.write_text_map(a.run_dir, a.key, f"# {a.key}: ad view ({'video' if a.video else 'image'}) | {W}x{height} css px | {len(boxes)} boxes | built {when}", boxes)
        print(f'{a.key}: height {height}px, boxes {len(boxes)}' + (f', frames {len(frame_meta)}' if frame_meta else ''))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == '__main__':
    main()

````

````text file=capture.py sha256=a9db9ba8ed6e34e9fc8524274a1815942b97afbdcdb18e05439c5642e8191fdb
#!/usr/bin/env python3
"""Capture a product page as stitched full-page JPGs plus an element map.

usage: capture.py URL RUN_DIR [--views mobile,desktop] [--expand]

Writes RUN_DIR/capture/<key>.jpg, <key>-boxes.json, <key>-text.md and merges the view into
RUN_DIR/capture/views.js. The stitched page hides popups and fixed or sticky bars (they would paint in the
wrong place); the -text.md header lists what was hidden, and <view>-first is the first screen exactly as it
loads, popups and bars included. With --expand every collapsed section (details, accordion and tab
buttons) is also opened in a second capture stored as <key>-open (mobile-open, desktop-open), so a run
has the page as it loads and the page with every FAQ answer showing.
"""
import argparse, sys, tempfile
from pathlib import Path
from urllib.parse import urlparse
from playwright.sync_api import sync_playwright

sys.path.insert(0, str(Path(__file__).resolve().parent))
import _views

IPHONE_UA = ('Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 '
             '(KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1')
PROFILES = {
    'mobile': dict(w=390, h=844, dpr=2, mobile=True, frame='phone', label='On {pronoun} phone', prefix='m'),
    'desktop': dict(w=1440, h=900, dpr=1, mobile=False, frame='laptop', label='On {pronoun} laptop', prefix='d'),
}

CALM_CSS = ('*,*::before,*::after{animation-play-state:paused!important;animation-delay:0s!important;'
            'transition:none!important;scroll-behavior:auto!important}')

JS_EXPAND_TAG = r'''() => {
  let n = 0;
  document.querySelectorAll('details').forEach(d => { if (!d.closest('nav,header,dialog,[role=dialog],[role=menu]')) d.setAttribute('open', ''); });
  const out = [];
  document.querySelectorAll('[aria-expanded="false"]').forEach(e => {
    if (!(e.hasAttribute('aria-controls') || e.getAttribute('role') === 'tab')) return;
    if (e.hasAttribute('aria-haspopup') && e.getAttribute('aria-haspopup') !== 'false') return;
    if (e.closest('nav,header,dialog,[role=dialog],[role=menu],[role=menubar]')) return;
    if (e.tagName === 'A') { const h = e.getAttribute('href') || ''; if (h && !h.startsWith('#') && !h.startsWith('javascript')) return; }
    if (e.tagName === 'BUTTON' && e.closest('form') && (e.getAttribute('type') || 'submit') !== 'button') return;
    if (e.tagName === 'INPUT') return;
    e.setAttribute('data-aw-exp', String(n)); out.push(n++);
  });
  return out;
}'''

JS_HIDE = r'''() => {
  let fixed = 0, popups = 0; const names = [];
  const label = e => (e.getAttribute('aria-label') || e.innerText || e.tagName).replace(/\s+/g, ' ').trim().slice(0, 70);
  const hide = e => { names.push(label(e)); e.style.setProperty('display', 'none', 'important'); };
  document.querySelectorAll('dialog,[role=dialog],[role=alertdialog],[aria-modal=true]').forEach(e => { hide(e); popups++; });
  document.querySelectorAll('body *').forEach(e => {
    if (e.style.display === 'none') return;
    const s = getComputedStyle(e);
    if (s.display === 'none') return;
    if (s.position === 'fixed') { hide(e); fixed++; }
    else if (s.position === 'sticky') e.style.setProperty('position', 'static', 'important');
    else if (s.position === 'absolute' && parseInt(s.zIndex || '0', 10) >= 1000 &&
             /cookie|consent|onetrust|gdpr|popup|modal|newsletter/i.test((e.id || '') + ' ' + (typeof e.className === 'string' ? e.className : ''))) { hide(e); popups++; }
  });
  return { fixed, popups, names };
}'''

JS_BOXES = r'''() => {
  const W = document.documentElement.clientWidth;
  const H = Math.max(document.documentElement.scrollHeight, document.body ? document.body.scrollHeight : 0);
  const norm = s => (s || '').replace(/\s+/g, ' ').trim();
  const clip = (s, n) => s.length > n ? s.slice(0, n - 1).trimEnd() + '…' : s;
  const PRICE = /[$€£]\s?\d/;
  const MAIN = 'h1,h2,h3,h4,p,button,a,label,summary,li,img,input,textarea,select,details,[role=button],[role=tab]';
  const cache = new Map();
  const style = e => { let s = cache.get(e); if (!s) { s = getComputedStyle(e); cache.set(e, s); } return s; };
  const ownText = e => norm(Array.from(e.childNodes).filter(n => n.nodeType === 3).map(n => n.textContent).join(' '));
  function visible(e, r) {
    if (r.width < 2 || r.height < 2) return false;
    if (r.bottom <= 0 || r.top >= H || r.right <= 0 || r.left >= W) return false;
    if (e.checkVisibility && !e.checkVisibility({ checkOpacity: true, checkVisibilityCSS: true })) return false;
    // clipped away by an overflow container (carousel slides parked off screen)
    for (let a = e.parentElement; a && a !== document.body; a = a.parentElement) {
      const s = style(a);
      if (s.overflowX !== 'visible' || s.overflowY !== 'visible') {
        const ar = a.getBoundingClientRect();
        if (ar.width < 1 || ar.height < 1) return false;
        if (r.right <= ar.left || r.left >= ar.right || r.bottom <= ar.top || r.top >= ar.bottom) return false;
      }
    }
    return true;
  }
  function describe(e, r, phase) {
    const tag = e.tagName.toLowerCase(), role = e.getAttribute('role');
    let kind = role || tag, text = '';
    if (tag === 'img') {
      const alt = norm(e.getAttribute('alt'));
      if (alt) { if (r.width * r.height < 24 * 24) return null; text = alt; }
      else if (r.width >= 100 && r.height >= 100) text = '(image)';
      else return null;
      kind = 'img';
    } else if (tag === 'input' || tag === 'textarea') {
      const t = (e.getAttribute('type') || 'text').toLowerCase();
      if (['hidden', 'checkbox', 'radio'].includes(t) && !e.getAttribute('aria-label')) return null;
      text = norm(e.getAttribute('placeholder') || e.value || e.getAttribute('aria-label') || '');
      if (!text) return null;
      if (t === 'submit' || t === 'button') kind = 'button';
    } else if (tag === 'select') {
      const o = e.options && e.options[e.selectedIndex];
      text = norm((o && o.textContent) || e.getAttribute('aria-label') || e.name || '');
      if (!text) return null;
    } else if (phase === 'price' || phase === 'fallback') {
      text = ownText(e);
    } else {
      text = norm(e.innerText || e.textContent);
      if (tag === 'li' && text.length >= 120) return null;
      if (tag === 'a' && text.length >= 80) return null;
      if (tag === 'details') text = norm((e.querySelector('summary') || {}).innerText || '');
    }
    if (!text) return null;
    return { el: e, kind, full: text, text: clip(text, 160) };
  }
  const found = new Map();
  const add = (e, phase) => {
    if (found.has(e)) return;
    const r = e.getBoundingClientRect();
    if (!visible(e, r)) return;
    const d = describe(e, r, phase);
    if (!d) return;
    d.r = r; found.set(e, d);
  };
  document.querySelectorAll(MAIN).forEach(e => add(e, 'main'));
  // price elements (own text looks like a price)
  document.querySelectorAll('body *').forEach(e => {
    if (found.has(e) || e.children.length > 6) return;
    if (PRICE.test(ownText(e))) add(e, 'price');
  });
  // fallback: other text carriers not covered by a collected ancestor
  const FB = 'div,span,strong,em,b,i,small,td,th,dt,dd,figcaption,blockquote,s,ins,del,section,article';
  document.querySelectorAll(FB).forEach(e => {
    if (found.has(e)) return;
    const t = ownText(e);
    if (t.length < 2) return;
    for (let a = e.parentElement; a; a = a.parentElement) { if (found.has(a) && a.tagName !== 'DETAILS') return; }
    add(e, 'fallback');
  });
  let list = Array.from(found.values());
  // parent and child with the same text: keep the child
  const byText = new Map();
  list.forEach(d => { const k = d.full; if (!byText.has(k)) byText.set(k, []); byText.get(k).push(d); });
  const drop = new Set();
  byText.forEach(g => { if (g.length > 1) g.forEach(a => g.forEach(b => { if (a !== b && a.el.contains(b.el) && b.kind !== 'img') drop.add(a); })); });
  list = list.filter(d => !drop.has(d));
  const sx = window.scrollX, sy = window.scrollY;
  const boxes = list.map(d => {
    let x = Math.max(0, d.r.left + sx), y = Math.max(0, d.r.top + sy);
    const w = Math.min(W, d.r.right + sx) - x, h = Math.min(H, d.r.bottom + sy) - y;
    return { kind: d.kind, text: d.text, x: Math.round(x), y: Math.round(y), w: Math.round(w), h: Math.round(h) };
  }).filter(b => b.w >= 2 && b.h >= 2);
  boxes.sort((a, b) => a.y - b.y || a.x - b.x);
  return { width: W, height: Math.ceil(H), boxes, title: document.title, url: location.href };
}'''


def display_url(u):
    p = urlparse(u)
    host = p.netloc[4:] if p.netloc.startswith('www.') else p.netloc
    return (host + p.path).rstrip('/')


def expand_all(page):
    ids = page.evaluate(JS_EXPAND_TAG)
    start_url = page.url
    clicked = 0
    for i in ids:
        try:
            page.evaluate("i => { const e = document.querySelector('[data-aw-exp=\"' + i + '\"]'); if (e && e.getAttribute('aria-expanded') === 'false') e.click(); }", str(i))
            page.wait_for_timeout(150)
            clicked += 1
        except Exception:
            pass
    if page.url != start_url:  # a control navigated: undo, we promised not to follow links
        page.go_back(wait_until='load'); page.wait_for_timeout(500)
    return clicked


def capture_view(p, url, run_dir, name, expand):
    prof = PROFILES[name]
    key = name + ('-open' if expand else '')
    w, dpr = prof['w'], prof['dpr']
    browser = p.chromium.launch(chromium_sandbox=True)
    kw = dict(viewport={'width': w, 'height': prof['h']}, device_scale_factor=dpr,
              is_mobile=prof['mobile'], has_touch=prof['mobile'])
    if prof['mobile']:
        kw['user_agent'] = IPHONE_UA
    ctx = browser.new_context(**kw)
    page = ctx.new_page()
    try:
        page.goto(url, wait_until='networkidle', timeout=45000)
    except Exception:
        page.wait_for_load_state('load')
    H = page.evaluate('document.documentElement.scrollHeight')
    for y in range(0, H, 600):
        page.evaluate(f'scrollTo(0,{y})'); page.wait_for_timeout(120)
        H = max(H, page.evaluate('document.documentElement.scrollHeight'))
    page.evaluate("document.querySelectorAll('img[loading=lazy]').forEach(i=>i.loading='eager')")
    try:
        page.wait_for_load_state('networkidle', timeout=8000)
    except Exception:
        pass
    page.evaluate('scrollTo(0,0)'); page.wait_for_timeout(800)
    cap = Path(run_dir) / 'capture'
    cap.mkdir(parents=True, exist_ok=True)
    first = None
    if not expand:
        # the first screen exactly as it loads: popups, cookie banners and sticky bars included
        page.wait_for_timeout(2500)
        page.screenshot(path=str(cap / f'{name}-first.png'))
        fb = [b for b in page.evaluate(JS_BOXES)['boxes'] if b['y'] < prof['h']]
        first = [dict(id=f"{prof['prefix']}f{i}", **b) for i, b in enumerate(fb, 1)]
    expanded = expand_all(page) if expand else 0
    page.add_style_tag(content=CALM_CSS)
    page.evaluate("try{document.getAnimations().forEach(a=>{try{a.finish()}catch(e){}})}catch(e){}")
    page.evaluate("Promise.all(Array.from(document.images).map(i=>i.complete?1:new Promise(r=>{i.onload=i.onerror=r;setTimeout(r,5000)})))")
    hid = page.evaluate(JS_HIDE)
    page.wait_for_timeout(300)
    info = page.evaluate(JS_BOXES)
    height = info['height']
    with tempfile.TemporaryDirectory() as tmp:
        tiles = _views.screenshot_tiles(page, w, height, tmp, key)
        _views.stitch(tiles, cap / f'{key}.jpg', dpr)
    final_url = info['url']
    browser.close()
    boxes = [dict(id=f"{prof['prefix']}{i}", **b) for i, b in enumerate(info['boxes'], 1)]
    when = _views.now_iso()
    view = dict(key=key, src=f'capture/{key}.jpg', w=w, h=height, frame=prof['frame'], url=display_url(final_url),
                label=prof['label'], captured=when, title=info['title'], boxes=boxes)
    _views.merge_view(run_dir, key, view)
    hidden = '; '.join(n for n in hid.get('names', []) if n) or 'nothing'
    header = (f"# {key}: {final_url} | {w}x{height} css px | {len(boxes)} boxes | captured {when}\n"
              f"# Hidden for the stitched capture (popups, fixed and sticky bars; the buyer does meet them): {hidden}")
    _views.write_text_map(run_dir, key, header, boxes)
    if first is not None:
        from PIL import Image
        png = cap / f'{name}-first.png'
        Image.open(png).convert('RGB').save(cap / f'{name}-first.jpg', quality=86); png.unlink()
        fkey = f'{name}-first'
        _views.merge_view(run_dir, fkey, dict(key=fkey, src=f'capture/{fkey}.jpg', w=w, h=prof['h'], frame=prof['frame'],
                          url=display_url(final_url), label=prof['label'], captured=when, title=info['title'], boxes=first))
        _views.write_text_map(run_dir, fkey, f"# {fkey}: the first screen as it loads, popups included | {w}x{prof['h']} css px | "
                              f"{len(first)} boxes | captured {when}", first)
    return key, height, len(boxes), hid, expanded


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('url'); ap.add_argument('run_dir')
    ap.add_argument('--views', default='mobile,desktop')
    ap.add_argument('--expand', action='store_true', help='also capture each view with details/accordions/tabs opened, stored as <view>-open')
    a = ap.parse_args()
    names = [v.strip() for v in a.views.split(',') if v.strip()]
    bad = [n for n in names if n not in PROFILES]
    if bad:
        sys.exit(f'unknown view {bad}; choose from {list(PROFILES)}')
    with sync_playwright() as p:
        for n in names:
            for expand in ([False, True] if a.expand else [False]):
                key, h, nb, hid, ex = capture_view(p, a.url, a.run_dir, n, expand)
                extra = f', expanded controls {ex}' if expand else ''
                print(f"{key}: height {h}px, boxes {nb}, hidden fixed {hid['fixed']}, popups {hid['popups']}{extra}")


if __name__ == '__main__':
    main()

````

````text file=check_walk.py sha256=138df11ee283271594527b39773b0bfbd52b72b64b5a6e64593e6cce20783b64
#!/usr/bin/env python3
"""Check RUN_DIR/walk.js against RUN_DIR/capture/views.js. Exit 1 on any error.

usage: check_walk.py RUN_DIR      |      check_walk.py --selftest
Catches: missing views or boxes, gaze outside the view, bad d / mood / length, missing persona fields,
quoted text (curly quotes) that is not on the page, findings without t and fix.
"""
import json, re, sys, tempfile, copy, shutil
from pathlib import Path

def load(run):
    """Read views.js and walk.js as data. Neither file is ever run: both must be `window.X = <JSON>;`,
    so a run folder someone shares cannot execute anything on this machine."""
    run = Path(run)
    out = {}
    for key, f, var in (('views', run / 'capture' / 'views.js', 'VIEWS'), ('walk', run / 'walk.js', 'WALK')):
        if not f.exists(): sys.exit(f'error: missing {f}')
        src = f.read_text(encoding='utf-8')
        m = re.search(r'window\.' + var + r'\s*=\s*(\{.*\})\s*;?\s*$', src, re.S)
        if not m: sys.exit(f'error: {f.name} must contain window.{var} = {{...}}; with JSON after the equals sign')
        try:
            out[key] = json.loads(m.group(1))
        except ValueError as e:
            sys.exit(f'error: {f.name} is not valid JSON after window.{var} = ({e}). Use double quotes on keys and '
                     'strings, no trailing commas and no comments inside the object; comments go above it.')
    return out


def norm(s):
    s = str(s).lower()
    s = s.replace('’', "'").replace('‘', "'").replace('“', '"').replace('”', '"')
    s = s.replace('…', '...').replace(' ', ' ')
    return re.sub(r'\s+', ' ', s).strip()


def strings(x):
    if isinstance(x, str): yield x
    elif isinstance(x, dict):
        for v in x.values(): yield from strings(v)
    elif isinstance(x, (list, tuple)):
        for v in x: yield from strings(v)


QUOTE = re.compile(r'“(.+?)”|‘(.+?)’(?![A-Za-z])')


def on_page(q, haystacks):
    q = norm(q).strip(' .,;:!?')
    q = q.removesuffix('...').strip() if q.endswith('...') else q
    return any(q in h for h in haystacks)


def check(data):
    errs, warns = [], []
    views, walk = data['views'] or {}, data['walk'] or {}
    nb = nbeats = nq = 0
    texts = {k: [norm(b.get('text', '')) for b in v.get('boxes', [])] for k, v in views.items()}
    for f in ('title', 'intro'):
        if not walk.get(f): warns.append(f'walk.{f} is missing')
    personas = walk.get('personas') or []
    if not personas: errs.append('walk.personas is empty')
    for pi, p in enumerate(personas):
        who = p.get('name') or f'persona[{pi}]'
        for f in ('name', 'line', 'wants'):
            if not p.get(f): errs.append(f'{who}: persona.{f} missing')
        d = p.get('decision') or {}
        if not d.get('label'): errs.append(f'{who}: decision.label missing')
        if not d.get('why'): errs.append(f'{who}: decision.why missing')
        own = [norm(s) for k in ('wants', 'ad', 'quotes') for s in strings(p.get(k))]
        if not p.get('src'): warns.append(f'{who}: no src for the wants quote (where the team found these words)')
        if not p.get('path'): errs.append(f'{who}: path is empty')
        for ei, entry in enumerate(p.get('path') or []):
            vk = entry.get('view')
            tag = f'{who} path[{ei}] ({vk})'
            view = views.get(vk)
            if view is None:
                errs.append(f'{tag}: view "{vk}" is not in views.js (has: {", ".join(views) or "none"})'); continue
            ids = {b['id'] for b in view.get('boxes', [])}
            if not entry.get('beats'): errs.append(f'{tag}: no beats')
            for bi, beat in enumerate(entry.get('beats') or []):
                nbeats += 1
                bt = f'{tag} beat[{bi}]'
                box, gaze = beat.get('box'), beat.get('gaze')
                if box is not None:
                    if box not in ids: errs.append(f'{bt}: box "{box}" does not exist in view {vk}')
                    else: nb += 1
                elif gaze is not None:
                    pts = gaze if isinstance(gaze, list) else []
                    if not pts: errs.append(f'{bt}: gaze is empty')
                    for pt in pts:
                        ok = (isinstance(pt, list) and len(pt) == 2 and all(isinstance(n, (int, float)) for n in pt)
                              and 0 <= pt[0] <= view['w'] and 0 <= pt[1] <= view['h'])
                        if not ok: errs.append(f'{bt}: gaze point {pt} is outside view {vk} ({view["w"]}x{view["h"]})')
                else:
                    errs.append(f'{bt}: needs a box or a gaze')
                dd = beat.get('d')
                if not isinstance(dd, (int, float)) or isinstance(dd, bool) or not 2 <= dd <= 6:
                    errs.append(f'{bt}: d must be between 2 and 6 (got {dd!r})')
                if beat.get('mood') not in ('+', '-', '?'): errs.append(f'{bt}: mood must be + - or ? (got {beat.get("mood")!r})')
                t = beat.get('t')
                if not isinstance(t, str) or not t.strip(): errs.append(f'{bt}: t is missing')
                elif len(t) > 120: errs.append(f'{bt}: t is {len(t)} characters (max 120)')
                elif len(t) > 100: warns.append(f'{bt}: t is {len(t)} characters (over 100)')
                # page text in curly quotes must be in the box she is looking at (or anywhere in the view for a gaze beat),
                # unless it is her own words from wants, ad or quotes
                seen = [norm(x.get('text', '')) for x in view.get('boxes', []) if x['id'] == box] if box in ids else texts[vk]
                for s in (beat.get('t'), beat.get('look')):
                    for m in QUOTE.finditer(s or ''):
                        q = m.group(1) or m.group(2); nq += 1
                        if not on_page(q, seen + own):
                            where = f'box {box}' if box in ids else f'view {vk}'
                            errs.append(f'{bt}: quoted text not in {where}: “{q}”')
    fs = walk.get('findings') or []
    if not fs: warns.append('walk.findings is empty')
    for i, f in enumerate(fs):
        for k in ('t', 'fix'):
            if not f.get(k): errs.append(f'findings[{i}]: {k} missing')
        if f.get('mood') is not None and f['mood'] not in ('+', '-', '?'): errs.append(f'findings[{i}]: mood must be + - or ?')
    stats = dict(personas=len(personas), beats=nbeats, box_beats=nb, quotes_checked=nq, findings=len(fs), views=len(views))
    return errs, warns, stats


def report(run):
    errs, warns, st = check(load(run))
    print('check_walk: ' + ', '.join(f'{k} {v}' for k, v in st.items()))
    for w in warns: print('  warn:', w)
    for e in errs: print('  ERROR:', e)
    print(f'{len(errs)} error(s), {len(warns)} warning(s)')
    return 1 if errs else 0


def selftest():
    good_views = {'mobile': dict(key='mobile', w=390, h=2000, boxes=[
        dict(id='m1', kind='h1', text='Your electric heating pad stays home…', x=16, y=600, w=358, h=90),
        dict(id='m2', kind='button', text='ADD TO CART · $84.90', x=16, y=900, w=358, h=50)])}
    beat = lambda **k: dict(dict(d=3, look='reads the headline', mood='+', box='m1', t='Okay, “Your electric heating pad stays home”, that is me.'), **k)
    good = dict(title='T', intro='I', findings=[dict(t='a', fix='b', mood='-')], personas=[dict(
        name='Jess', line='l', wants='cordless “no outlet” heat', src='R9', quotes=['“I love it”'],
        path=[dict(view='mobile', beats=[beat(), beat(box='m2', t='Price is fine.'), beat(box=None, gaze=[[10, 10], [300, 1500]], t='Scrolling.')])],
        decision=dict(label='Buy', why='fits'))])
    for b in good['personas'][0]['path'][0]['beats']:
        if b.get('box') is None: b.pop('box')
    def mut(fn):
        w = copy.deepcopy(good); fn(w); return w
    P = lambda w: w['personas'][0]
    cases = [
        ('missing view', mut(lambda w: P(w)['path'].append(dict(view='tablet', beats=[beat()]))), 'is not in views.js'),
        ('missing box', mut(lambda w: P(w)['path'][0]['beats'].append(beat(box='m99'))), 'does not exist in view'),
        ('gaze outside', mut(lambda w: P(w)['path'][0]['beats'].append(dict(d=3, mood='?', t='x', gaze=[[500, 10]]))), 'is outside view'),
        ('invented quote', mut(lambda w: P(w)['path'][0]['beats'].append(beat(t='It says “clinically proven to cure cramps”.'))), 'quoted text not in'),
        ('quote from another box', mut(lambda w: P(w)['path'][0]['beats'].append(beat(box='m2', t='“Your electric heating pad stays home” again?'))), 'quoted text not in box m2'),
        ('missing decision', mut(lambda w: P(w).pop('decision')), 'decision.label missing'),
        ('bad d', mut(lambda w: P(w)['path'][0]['beats'].append(beat(d=9))), 'd must be between 2 and 6'),
        ('bad mood', mut(lambda w: P(w)['path'][0]['beats'].append(beat(mood='x'))), 'mood must be'),
        ('long t', mut(lambda w: P(w)['path'][0]['beats'].append(beat(t='x' * 130))), 'max 120'),
        ('finding without fix', mut(lambda w: w['findings'].append(dict(t='only t'))), 'findings[1]: fix missing'),
    ]
    tmp = Path(tempfile.mkdtemp(prefix='cw-selftest-'))
    def write(w):
        (tmp / 'capture').mkdir(exist_ok=True)
        (tmp / 'capture' / 'views.js').write_text('window.VIEWS = ' + json.dumps(good_views) + ';')
        (tmp / 'walk.js').write_text('window.WALK = ' + json.dumps(w) + ';')
    fails = 0
    write(good)
    errs, _, _ = check(load(tmp))
    (tmp / 'walk.js').write_text("window.WALK = {personas: [], x: require('child_process')};")
    try:
        load(tmp); print('  bad fixture "code instead of JSON": NOT REJECTED'); fails += 1
    except SystemExit as e:
        print(f'  bad fixture "code instead of JSON": rejected  -> {str(e)[:90]}')
    write(good); errs, _, _ = check(load(tmp))
    print(f'  good fixture: {"PASS" if not errs else "FAIL " + str(errs)}'); fails += bool(errs)
    for name, w, needle in cases:
        write(w); errs, _, _ = check(load(tmp))
        hit = any(needle in e for e in errs)
        print(f'  bad fixture "{name}": {"rejected" if hit else "NOT REJECTED"}' + (f'  -> {next(e for e in errs if needle in e)}' if hit else ''))
        fails += not hit
    shutil.rmtree(tmp, ignore_errors=True)
    print('selftest ' + ('FAILED' if fails else 'ok'))
    return 1 if fails else 0


if __name__ == '__main__':
    if len(sys.argv) == 2 and sys.argv[1] == '--selftest': sys.exit(selftest())
    if len(sys.argv) != 2: sys.exit(__doc__)
    sys.exit(report(sys.argv[1]))

````

````text file=pack.py sha256=03a805193a67ad7ae43dadf788e51b7322fb45ec11950818ccebdb0f3c3d5be3
#!/usr/bin/env python3
"""Bundle every file of this toolkit folder into ../references/toolkit.md (one fenced block per file).

usage: pack.py            write ../references/toolkit.md and print the unpack snippet
       pack.py --check    exit 1 if toolkit.md is out of date
"""
import hashlib, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE.parent / 'references' / 'toolkit.md'
SKIP_NAMES = {'.DS_Store'}
SKIP_DIRS = {'__pycache__'}
FENCE = '`' * 4

UNPACK = '''python3 - "$TOOLKIT_MD" "$DEST" <<'PY'
import re, sys, hashlib, pathlib
md, dest = sys.argv[1:3]
pathlib.Path(dest).mkdir(parents=True, exist_ok=True)
rx = re.compile('^' + '`' * 4 + r'text file=([^/\\s]+) sha256=([0-9a-f]{64})\\n(.*?)\\n' + '`' * 4 + '$', re.S | re.M)
found = rx.findall(open(md, encoding='utf-8', newline='').read())
if not found: sys.exit('no files found in ' + md)
for name, sha, body in found:
    data = body.encode('utf-8')
    if hashlib.sha256(data).hexdigest() != sha: sys.exit('SHA256 MISMATCH: ' + name)
    p = pathlib.Path(dest, name); p.write_bytes(data)
    if name.endswith('.py'): p.chmod(0o755)
    print('wrote', p)
PY'''


def files():
    out = []
    for p in sorted(HERE.iterdir()):
        if p.is_dir() or p.name in SKIP_NAMES or p.suffix == '.pyc' or p.name.startswith('.'):
            continue
        out.append(p)
    return out


def build():
    parts = []
    for p in files():
        data = p.read_bytes()
        try:
            text = data.decode('utf-8')
        except UnicodeDecodeError:
            sys.exit(f'pack.py: {p.name} is not UTF-8 text; the bundle only carries text files')
        if '\r' in text:
            sys.exit(f'pack.py: {p.name} has CR characters; convert to LF first')
        if any(l.startswith(FENCE) for l in text.split('\n')):
            sys.exit(f'pack.py: {p.name} has a line starting with four backticks')
        sha = hashlib.sha256(data).hexdigest()
        parts.append(f'{FENCE}text file={p.name} sha256={sha}\n{text}\n{FENCE}\n')
    names = ', '.join(p.name for p in files())
    head = (
        '# Avatar walkthrough toolkit (bundle)\n\n'
        'Every file of the toolkit in one document: page capture, ad mock, checker, the HTML player and the packer. '
        f'Files: {names}. Each block carries its sha256; unpacking fails loudly on a mismatch. '
        'Regenerate this file with `python3 pack.py` from the toolkit folder (`--check` tells whether it is out of date).\n\n'
        'Unpack (set TOOLKIT_MD to this file and DEST to an empty folder; needs python3, playwright, Pillow, ffmpeg, node):\n\n'
        f'```bash\n{UNPACK}\n```\n\n'
    )
    return head + '\n'.join(parts)


def main():
    content = build()
    if '--check' in sys.argv:
        cur = OUT.read_text(encoding='utf-8') if OUT.exists() else None
        if cur != content:
            print(f'OUT OF DATE: {OUT} (run python3 pack.py)'); sys.exit(1)
        print(f'up to date: {OUT}'); return
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(content, encoding='utf-8')
    print(f'wrote {OUT}: {len(files())} files, {len(content)} bytes\n\nunpack snippet:\n{UNPACK}')


if __name__ == '__main__':
    main()

````

````text file=player.html sha256=7cb169983c347a86de48fcad61e0d779699b2e2315f5f83040274d9dc6c0f471
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Buyer walkthrough</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;700&family=Fraunces:ital,opsz,wght@0,9..144,500;1,9..144,500&display=swap" rel="stylesheet">
<style>
:root{--bg:#1f2638;--panel:#273049;--cream:#fef4ea;--soft:#c9c3d6;--purple:#b59ad9;--plus:#7fd3a3;--q:#f2c46b;--minus:#f08a8a;color-scheme:dark}
*{box-sizing:border-box}
html,body{margin:0;background:var(--bg);height:100%;overflow:hidden}
#wrap{position:fixed;left:0;top:0;transform-origin:0 0}
#ctl{position:fixed;left:0;right:0;bottom:0;height:64px;display:flex;align-items:center;gap:14px;padding:0 20px;background:#141a29;color:var(--cream);font:500 15px "DM Sans",system-ui,sans-serif;z-index:20}
#ctl button{background:#273049;color:var(--cream);border:0;border-radius:8px;height:38px;min-width:38px;padding:0 12px;font:inherit;cursor:pointer}
#ctl button:hover{background:#34405f}
#ctl button:focus-visible,#scrub:focus-visible{outline:2px solid var(--purple);outline-offset:2px}
#ctl .ch{display:flex;gap:6px;min-width:0}
#ctl .ch button.on{background:var(--purple);color:#1f2638}
#scrubw{position:relative;flex:1;height:38px;display:flex;align-items:center;min-width:0}
#scrub{width:100%;accent-color:#b59ad9;cursor:pointer}
#time{font-variant-numeric:tabular-nums;color:var(--soft);min-width:96px;text-align:right}
body.render #ctl{display:none}
/* portrait (phone) layout */
body.portrait #stage{width:1080px;height:1920px}
body.portrait #device{left:0;right:0;top:20px;bottom:auto;height:1110px;width:auto}
body.portrait .laptop{transform:scale(.94)}
body.portrait .devlabel{bottom:0}
body.portrait #panel{left:64px;right:64px;top:1160px;bottom:56px;width:auto}
body.portrait .who h2{font-size:52px}
body.portrait .who p{font-size:24px}
body.portrait .wants{font-size:32px;margin-top:16px}
body.portrait .from{font-size:22px}
body.portrait .sep{margin:18px 0 16px}
body.portrait .lookl{font-size:19px}
body.portrait .look{font-size:28px}
body.portrait .thought{font-size:44px;margin-top:16px;min-height:0}
body.portrait .mood{font-size:19px}
body.portrait .hist{display:none}
body.portrait .note{font-size:19px}
body.portrait .decision{bottom:96px}
body.portrait .decision h3{font-size:46px}
body.portrait .decision p{font-size:24px}
body.portrait .card{padding:0 70px}
body.portrait .card h1{font-size:84px!important}
body.portrait .card p{font-size:30px}
body.portrait .card .ppl{flex-direction:column;gap:18px}
body.portrait .find{grid-template-columns:1fr;gap:8px}
body.portrait .find .fh{display:none}
body.portrait .find .fi{font-size:27px;padding-bottom:4px}
body.portrait .find .fx{font-size:27px;margin-bottom:14px}
@media (max-width:760px){#ctl{height:auto;flex-wrap:wrap;gap:8px;padding:10px 12px calc(10px + env(safe-area-inset-bottom))}#ctl .ch{order:3;overflow-x:auto;max-width:100%}#scrubw{order:4;flex:1 1 100%;height:28px}#time{min-width:0;margin-left:auto}#ctl button{height:40px}}
#stage{position:relative;width:1920px;height:1080px;overflow:hidden;background:var(--bg);color:var(--cream);font:22px/1.4 "DM Sans",system-ui,sans-serif}
.layer{position:absolute;inset:0;opacity:0}
/* device area */
#device{position:absolute;left:70px;top:0;bottom:0;width:1120px;display:flex;align-items:center;justify-content:center}
.phone{position:relative;width:461px;height:983px;border-radius:64px;background:#0d1120;padding:16px;box-shadow:0 30px 80px rgba(0,0,0,.45)}
.phone .vp{position:relative;width:429px;height:951px;border-radius:50px;overflow:hidden;background:#fef4ea}
.phone .notch{position:absolute;top:26px;left:50%;transform:translateX(-50%);width:120px;height:32px;border-radius:20px;background:#0d1120;z-index:4}
.laptop{position:relative;width:1080px;border-radius:14px;background:#0d1120;padding:0 0 0;box-shadow:0 30px 80px rgba(0,0,0,.45);overflow:hidden}
.laptop .bar{height:38px;background:#e6e1ee;display:flex;align-items:center;gap:8px;padding:0 16px}
.laptop .bar i{width:12px;height:12px;border-radius:50%;background:#bdb6cc}
.laptop .bar span{margin-left:14px;background:#fff;border-radius:7px;font-size:14px;color:#4f566a;padding:3px 16px;width:420px;min-height:24px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.laptop .vp{position:relative;width:1080px;height:675px;overflow:hidden;background:#fef4ea}
.page{position:absolute;left:0;top:0;transform-origin:0 0;will-change:transform}
.page img{display:block}
.page canvas{position:absolute;left:0;top:0;mix-blend-mode:multiply;opacity:1}
.gaze{position:absolute;left:0;top:0;width:58px;height:58px;margin:-29px 0 0 -29px;border-radius:50%;border:3px solid #ff3b5c;box-shadow:0 0 0 6px rgba(255,59,92,.18);z-index:3}
.gaze::after{content:"";position:absolute;left:50%;top:50%;width:8px;height:8px;margin:-4px 0 0 -4px;border-radius:50%;background:#ff3b5c}
.devlabel{position:absolute;left:0;right:0;bottom:22px;text-align:center;font-size:17px;color:var(--soft);letter-spacing:.08em;text-transform:uppercase}
/* right panel */
#panel{position:absolute;right:70px;top:70px;bottom:70px;width:640px;display:flex;flex-direction:column}
.who{display:flex;gap:18px;align-items:center}
.av{width:72px;height:72px;border-radius:50%;display:grid;place-items:center;font:500 34px/1 Fraunces,serif;color:#1f2638}
.who h2{margin:0;font:500 40px/1.05 Fraunces,serif}
.who h2 small{font:400 22px "DM Sans";color:var(--soft);margin-left:8px}
.who p{margin:4px 0 0;color:var(--soft);font-size:19px}
.wants{margin:22px 0 0;font:italic 500 25px/1.3 Fraunces,serif;color:var(--cream)}
.from{margin:8px 0 0;font-size:17px;color:var(--soft)}
.sep{height:1px;background:rgba(255,255,255,.12);margin:26px 0 24px}
.lookl{font-size:15px;letter-spacing:.12em;text-transform:uppercase;color:var(--soft)}
.look{font-size:22px;font-weight:700;margin-top:4px;color:var(--purple)}
.thought{position:relative;margin-top:22px;background:var(--panel);border-radius:22px;padding:26px 30px 28px 30px;font:500 34px/1.25 Fraunces,serif;min-height:150px}
.thought::before{content:"";position:absolute;left:-14px;top:40px;border:14px solid transparent;border-right-color:var(--panel);border-left:0}
.mood{display:inline-flex;align-items:center;gap:8px;font:700 15px "DM Sans";letter-spacing:.1em;text-transform:uppercase;margin-bottom:10px}
.mood i{width:12px;height:12px;border-radius:50%}
.hist{margin-top:22px;display:flex;flex-direction:column;gap:10px}
.hist div{font-size:18px;color:var(--soft);padding-left:18px;position:relative;line-height:1.35}
.hist div i{position:absolute;left:0;top:8px;width:8px;height:8px;border-radius:50%}
.prog{margin-top:auto;display:flex;gap:6px}
.prog b{flex:1;height:5px;border-radius:3px;background:rgba(255,255,255,.14)}
.prog b.on{background:var(--purple)}
.note{margin-top:14px;font-size:15px;color:var(--soft)}
.decision{position:absolute;left:0;right:0;bottom:84px;background:var(--cream);color:#1f2638;border-radius:22px;padding:26px 30px}
.decision .k{font:700 15px "DM Sans";letter-spacing:.12em;text-transform:uppercase;color:#1d7448}
.decision h3{margin:6px 0 4px;font:500 40px/1.1 Fraunces,serif}
.decision p{margin:0;font-size:19px;color:#4f566a}
/* cards */
.card{display:flex;flex-direction:column;justify-content:center;padding:0 160px;background:var(--bg)}
.card .kick{font-size:20px;letter-spacing:.14em;text-transform:uppercase;color:var(--purple);margin-bottom:22px}
.card h1{margin:0;font:500 92px/1.05 Fraunces,serif;max-width:16ch}
.card h1 em{color:var(--purple)}
.card p{margin:28px 0 0;font-size:28px;color:var(--soft);max-width:60ch}
.card .ppl{display:flex;gap:28px;margin-top:56px}
.card .ppl div{display:flex;gap:14px;align-items:center;font-size:24px}
.card .ppl .av{width:56px;height:56px;font-size:26px}
.find{margin-top:34px;display:grid;grid-template-columns:1fr 1fr;gap:16px 56px;max-width:1520px}
.find .fh{font-size:17px;letter-spacing:.14em;text-transform:uppercase;color:var(--soft);padding:0}
.find .fx{color:var(--cream);background:#273049;border-radius:14px;padding:14px 18px;font-size:23px}
.find .fx b{color:var(--plus);margin-right:8px}
.find .fi{font-size:23px;line-height:1.35;padding:14px 0 14px 30px;position:relative}
.find .fi i{position:absolute;left:0;top:24px;width:13px;height:13px;border-radius:50%}
.find .fx{line-height:1.35}
.pcard .av{width:120px;height:120px;font-size:56px;margin-bottom:28px}
/* data error card */
#err{z-index:30;background:#2a1d2b}
#err .kick{color:var(--minus)}
#err h1{font-size:72px;max-width:none}
#err ul{margin:34px 0 0;padding:0 0 0 30px;font-size:28px;line-height:1.4;max-width:1500px}
#err li{margin-bottom:10px;color:var(--cream)}
#err code{font:600 .9em ui-monospace,Menlo,monospace;color:var(--q)}
body.portrait #err h1{font-size:64px!important}
body.portrait #err ul{font-size:26px}
</style>
</head>
<body>
<div id="wrap"><div id="stage">
  <div id="walk" class="layer">
    <div id="device"></div>
    <div id="panel">
      <div class="who"><div class="av" id="av"></div><div><h2 id="nm"></h2><p id="line"></p></div></div>
      <div class="wants" id="wants"></div>
      <div class="from" id="from"></div>
      <div class="sep"></div>
      <div class="lookl">Looking at</div>
      <div class="look" id="look"></div>
      <div class="thought" id="thought"><div class="mood" id="mood"></div><div id="ttext"></div></div>
      <div class="hist" id="hist"></div>
      <div class="decision" id="decision" style="opacity:0"></div>
      <div class="prog" id="prog"></div>
      <div class="note" id="note"></div>
    </div>
  </div>
  <div id="card" class="layer card"></div>
  <div id="err" class="layer card"></div>
</div>
</div><div id="ctl"><button id="pp" aria-label="Pause">❚❚</button><button id="back" aria-label="Back 5 seconds">−5 s</button><button id="fwd" aria-label="Forward 5 seconds">+5 s</button><div class="ch" id="chapters"></div><div id="scrubw"><input id="scrub" type="range" min="0" step="0.1" aria-label="Seek"></div><span id="time"></span></div>
<script src="capture/views.js"></script>
<script src="walk.js"></script>
<script>
const W=window.WALK||{}, VIEWS=window.VIEWS||{};
const FRAME={phone:{vw:429,vh:951,look:.45},laptop:{vw:1080,vh:675,look:.5}};
const MONTHS=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
const MOOD={'+':'var(--plus)','?':'var(--q)','-':'var(--minus)'};
const esc=s=>String(s==null?'':s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
const moodFor=(p,m)=>{const t={'+':`Pulls ${p.pronoun||'her'} in`,'?':'Doubt','-':'Turn-off'}[m]||'Doubt';return [MOOD[m]||MOOD['?'],t];};
const SCROLL=1.1, MOVE=.35, INTRO=6, PCARD=4.2, DEC=4.4, OUTRO=22;
const ease=x=>x<.5?4*x*x*x:1-Math.pow(-2*x+2,3)/2;
const $=id=>document.getElementById(id);
const plain=s=>String(s||'').replace(/<[^>]*>/g,'');
if(W.title) document.title=plain(W.title);
// ---- validate + timeline
const ERRS=[]; const fail=(msg)=>{ ERRS.push(msg); console.error('[walkthrough] '+plain(msg)); };
const NOTE=W.note||'Simulated walkthrough. The heatmap is scripted attention, not measured data.';
const T=[]; let t=0;
function boxGaze(v,b){ const cl=(x,lo,hi)=>Math.min(hi,Math.max(lo,x)); const y=cl(b.y+b.h/2,0,v.h); return [[cl(b.x+b.w*.30,0,v.w),y],[cl(b.x+b.w*.65,0,v.w),y]]; }
(function build(){
  if(!window.VIEWS) fail('<code>capture/views.js</code> did not load: window.VIEWS is missing.');
  if(!window.WALK) fail('<code>walk.js</code> did not load: window.WALK is missing.');
  if(window.WALK&&(!Array.isArray(W.personas)||!W.personas.length)) fail('<code>walk.js</code> has no personas.');
  const tl=[{type:'intro',s:0,e:INTRO}]; let tt=INTRO;
  (W.personas||[]).forEach((p,pi)=>{
    const who=`${p.name||p.id||'persona '+(pi+1)}`;
    if(!Array.isArray(p.path)||!p.path.length){ fail(`<code>${esc(who)}</code> has no <code>path</code> entries.`); return; }
    const pc={type:'pcard',p,s:tt,e:tt+PCARD}; tl.push(pc); tt+=PCARD;
    const segs=[]; let off=0; const flat=[];
    p.path.forEach((pe,si)=>{
      const v=VIEWS[pe.view];
      if(!v){ fail(`View <code>${esc(pe.view)}</code> (persona ${esc(who)}, path step ${si+1}) is missing from <code>capture/views.js</code>.`); return; }
      const fr=FRAME[v.frame]||FRAME.phone;
      if(!(v.w>0&&v.h>0&&v.src)){ fail(`View <code>${esc(pe.view)}</code> needs <code>src</code>, <code>w</code> and <code>h</code>.`); return; }
      if(!Array.isArray(pe.beats)||!pe.beats.length){ fail(`${esc(who)}: path step ${si+1} (<code>${esc(pe.view)}</code>) has no beats.`); return; }
      const sc=fr.vw/v.w, vhCss=fr.vh/sc, maxY=Math.max(0,v.h-vhCss); const beats=[]; let ok=true;
      pe.beats.forEach((b,i)=>{
        let gaze=b.gaze;
        if(b.box!=null){ const bx=(v.boxes||[]).find(x=>x.id===b.box); if(!bx){ fail(`Box <code>${esc(b.box)}</code> is missing from view <code>${esc(pe.view)}</code> (${esc(who)}, beat ${i+1}).`); ok=false; return; } gaze=boxGaze(v,bx); }
        if(!Array.isArray(gaze)||!gaze.length){ fail(`${esc(who)}, beat ${i+1} of <code>${esc(pe.view)}</code>: needs a <code>box</code> or a <code>gaze</code> list.`); ok=false; return; }
        const nb={...b,gaze}; beats.push(nb); flat.push(nb);
      });
      if(!ok) return;
      segs.push({v,fr,sc,vhCss,maxY,beats,si,off});
      off+=beats.length;
    });
    segs.forEach((sg,k)=>{
      const last=k===segs.length-1; let bt=tt+.6; const beats=[];
      sg.beats.forEach((b,i)=>{ const scd=i===0?0:SCROLL; const ys=b.gaze.map(q=>q[1]); const mid=(Math.min(...ys)+Math.max(...ys))/2;
        const y=Math.round(Math.min(sg.maxY,Math.max(0,mid-sg.vhCss*sg.fr.look)));
        const d=+b.d||3.4; beats.push({...b,y,s:bt,ds:bt+scd,e:bt+scd+d}); bt+=scd+d; });
      const e=bt+.4+(last?DEC:0);
      tl.push({type:'walk',p,view:sg.v,fr:sg.fr,sc:sg.sc,maxY:sg.maxY,idx:sg.si,off:sg.off,flat,beats,s:tt,e,decAt:last?bt+.4:null}); tt=e;
    });
  });
  tl.push({type:'outro',s:tt,e:tt+OUTRO}); tt+=OUTRO;
  if(ERRS.length){ T.push({type:'error',s:0,e:8}); t=8; }
  else { tl.forEach(x=>T.push(x)); t=tt; }
})();
window.DURATION=t;
window.WALK_ERRORS=ERRS.slice();
// ---- heat buffers
const HS=4; const heat={};
function heatFor(key,g){ if(!heat[key]){const w=Math.ceil(g.w/HS),h=Math.ceil(g.h/HS);heat[key]={w,h,v:new Float32Array(w*h),last:null};} return heat[key]; }
function addHeat(H,x,y,amt){ const r=Math.round((H.w>200?30:20)); const cx=x/HS, cy=y/HS;
  for(let j=Math.max(0,Math.floor(cy-r));j<Math.min(H.h,Math.ceil(cy+r));j++)for(let i=Math.max(0,Math.floor(cx-r));i<Math.min(H.w,Math.ceil(cx+r));i++){
    const d2=((i-cx)**2+(j-cy)**2)/(r*r); if(d2<1) H.v[j*H.w+i]+=amt*Math.exp(-d2*3.2); } }
const LUT=(()=>{const a=new Uint8ClampedArray(256*4);const st=[[0,[60,90,255,0]],[.15,[60,120,255,90]],[.4,[60,220,140,150]],[.65,[255,215,40,200]],[1,[255,30,30,225]]];
  for(let k=0;k<256;k++){const x=k/255;let i=0;while(i<st.length-2&&x>st[i+1][0])i++;const [x0,c0]=st[i],[x1,c1]=st[i+1];const f=Math.min(1,Math.max(0,(x-x0)/(x1-x0)));for(let c=0;c<4;c++)a[k*4+c]=c0[c]+(c1[c]-c0[c])*f;}return a;})();
function paintHeat(H,cv){ const ctx=cv.getContext('2d'); const img=ctx.createImageData(H.w,H.h); const d=img.data;
  for(let k=0;k<H.v.length;k++){ const v=Math.min(1,H.v[k]/1.5); if(v<.02) continue; const L=Math.round(v*255)*4; d[k*4]=LUT[L];d[k*4+1]=LUT[L+1];d[k*4+2]=LUT[L+2];d[k*4+3]=LUT[L+3]; }
  ctx.putImageData(img,0,0); }
// ---- gaze path inside a beat
function gazeAt(b,t){ const g=b.gaze, n=g.length, dur=(b.e-b.ds)/n; const k=Math.min(n-1,Math.floor((t-b.ds)/dur)); const local=(t-b.ds)-k*dur;
  if(k===0||local>=MOVE) return g[k]; const f=ease(local/MOVE); return [g[k-1][0]+(g[k][0]-g[k-1][0])*f, g[k-1][1]+(g[k][1]-g[k-1][1])*f]; }
function gazeState(seg,t){ const b=seg.beats; let i=b.findIndex(x=>t<x.e); if(i<0) i=b.length-1; const cur=b[i], prev=b[i-1]; const dwell=t>=cur.ds;
  return {i,cur,prev,dwell,gp:dwell?gazeAt(cur,t):(prev?prev.gaze[prev.gaze.length-1]:cur.gaze[0])}; }
function accumulate(seg,H,t0,t1){ const end=seg.beats[seg.beats.length-1].e; for(let x=t0;x<Math.min(t1,end);x+=1/30){ const g=gazeState(seg,x); addHeat(H,g.gp[0],g.gp[1],(1/30)*(g.dwell?1.15:.15)); } H.last=t1; }
// ---- text fitting (shrinks until nothing overflows)
const px=el=>parseFloat(getComputedStyle(el).fontSize);
const panelOverflows=()=>{ const P=$('panel'), n=$('note'); return n.offsetTop+n.offsetHeight>P.clientHeight+1; };
function fitThought(){
  const el=$('thought'); el.style.fontSize=''; const base=px(el), min=Math.min(base,24); let s=base;
  while(panelOverflows()&&s>min){ s=Math.max(min,s-2); el.style.fontSize=s+'px'; }
  const h=$('hist'); while(panelOverflows()&&h.children.length) h.removeChild(h.lastChild);
}
// builds the decision card and fits it together with the thought above it (both shrink, never overlap)
function prepDecision(p,key){
  const dec=$('decision'), th=$('thought'), d=p.decision||{}; dec.dataset.k=key;
  dec.innerHTML=`<div class="k" style="color:${{'+':'#1d7448','?':'#9a6a00','-':'#b42318'}[d.mood]||'#9a6a00'}">Decision</div><h3>${esc(d.label)}${d.price&&d.price!=='$0'?' · '+esc(d.price):''}</h3><p>${esc(d.why)}</p>`;
  const h3=dec.querySelector('h3'), pp=dec.querySelector('p'); $('hist').style.display='none';
  const b3=px(h3), bp=px(pp), m3=Math.min(b3,24), mp=Math.min(bp,17);
  let ts=px(th); const tmin=Math.min(ts,24); let f=1;
  const clash=()=>dec.offsetTop<th.offsetTop+th.offsetHeight+12;
  while(clash()){
    const canT=ts>tmin, canD=Math.max(m3,b3*(f-.04))<Math.max(m3,b3*f)||Math.max(mp,bp*(f-.04))<Math.max(mp,bp*f);
    if(!canT&&!canD) break;
    if(canT){ ts=Math.max(tmin,ts-2); th.style.fontSize=ts+'px'; }
    if(canD){ f-=.04; h3.style.fontSize=Math.max(m3,b3*f)+'px'; pp.style.fontSize=Math.max(mp,bp*f)+'px'; }
  }
}
// ---- DOM builders
let built=null;
function buildDevice(seg){
  const g=seg.view, sc=seg.sc;
  const phone=seg.fr===FRAME.phone;
  const wrap=phone?`<div class="phone"><div class="notch"></div><div class="vp" id="vp"></div></div>`:`<div class="laptop"><div class="bar"><i></i><i></i><i></i><span>${esc(g.url||'')}</span></div><div class="vp" id="vp"></div></div>`;
  const label=(g.label||(phone?'On {pronoun} phone':'On {pronoun} laptop')).replace(/\{pronoun\}/g,seg.p.pronoun||'her');
  $('device').innerHTML=wrap+`<div class="devlabel">${esc(label)}</div>`;
  const vp=$('vp'); const page=document.createElement('div'); page.className='page'; page.style.width=g.w+'px'; page.style.height=g.h+'px';
  page.innerHTML=`<img src="${esc(g.src)}" width="${g.w}" height="${g.h}" alt=""><canvas width="${Math.ceil(g.w/HS)}" height="${Math.ceil(g.h/HS)}" style="width:${g.w}px;height:${g.h}px"></canvas><div class="gaze"></div>`;
  page.querySelector('img').onerror=()=>console.error('[walkthrough] image failed to load: '+g.src);
  vp.appendChild(page); return {page,sc,cv:page.querySelector('canvas'),gz:page.querySelector('.gaze'),g};
}
function setPanel(p,seg){
  $('av').textContent=p.initials||''; $('av').style.background=p.color||'var(--purple)';
  $('nm').innerHTML=`${esc(p.name)}<small>${esc(p.age)}</small>`; $('line').textContent=p.line||''; $('wants').textContent=p.wants||''; $('from').innerHTML=p.ad?`Came from the ad: <b style="color:var(--cream)">“${esc(p.ad)}”</b>`:esc(p.from||'');
  $('prog').innerHTML=seg.flat.map(()=>'<b></b>').join(''); $('note').textContent=NOTE;
}
function kicker(){
  if(W.kicker) return esc(W.kicker);
  for(const p of (W.personas||[])) for(const pe of (p.path||[])){ const v=VIEWS[pe.view]; if(v&&v.url){ let d=''; if(v.captured){ const dt=new Date(v.captured); if(!isNaN(dt)) d=` · ${dt.getUTCDate()} ${MONTHS[dt.getUTCMonth()]} ${dt.getUTCFullYear()}`; } return esc(v.url)+d; } }
  return 'Buyer walkthrough';
}
// ---- render
let lastT=-1;
window.renderAt=function(t){
  const seg=T.find(s=>t>=s.s&&t<s.e)||T[T.length-1];
  const fade=Math.min(1,(t-seg.s)/.45,(seg.e-t)/.45);
  const errEl=$('err');
  if(seg.type==='error'){
    $('walk').style.opacity=0; $('card').style.opacity=0; errEl.style.opacity=1; built=null;
    if(!errEl.dataset.k){ errEl.dataset.k='1'; errEl.innerHTML=`<div class="kick">Walkthrough data error</div><h1>This walkthrough cannot play yet.</h1><ul>${ERRS.map(e=>`<li>${e}</li>`).join('')}</ul>`; }
    lastT=t; return;
  }
  errEl.style.opacity=0;
  if(seg.type==='walk'){
    $('walk').style.opacity=fade; $('card').style.opacity=0;
    const key=seg.p.id+'-'+seg.idx;
    if(!built||built.key!==key){ built={key,...buildDevice(seg)}; setPanel(seg.p,seg); built.lastBeat=-2; $('decision').dataset.k=''; }
    const b=seg.beats; let i=b.findIndex(x=>t<x.e); if(i<0) i=b.length-1;
    const cur=b[i]; const prev=b[i-1];
    // scroll
    let y=cur.y; if(t<cur.ds&&prev){ y=prev.y+(cur.y-prev.y)*ease(Math.max(0,(t-cur.s)/(cur.ds-cur.s))); }
    y=Math.min(Math.max(0,y),seg.maxY);
    built.page.style.transform=`scale(${built.sc}) translateY(${-y}px)`;
    // gaze + heat
    const H=heatFor(key,seg.view); const GS=gazeState(seg,t); const dwell=GS.dwell, gp=GS.gp;
    if(H.last===null||t<H.last||t-H.last>.5){ H.v.fill(0); accumulate(seg,H,seg.s,t); }
    built.gz.style.transform=`translate(${gp[0]}px,${gp[1]}px)`; built.gz.style.opacity=dwell?1:.35;
    if(t>H.last&&t<=b[b.length-1].e) addHeat(H,gp[0],gp[1],(t-H.last)*(dwell?1.15:.15));
    H.last=t; paintHeat(H,built.cv);
    // panel
    const p=seg.p; const idx=seg.off+i;
    if(built.lastBeat!==idx){ built.lastBeat=idx;
      const [mc,mt]=moodFor(p,cur.mood); $('mood').innerHTML=`<i style="background:${mc}"></i>${esc(mt)}`; $('mood').style.color=mc;
      $('look').textContent=cur.look||''; $('ttext').textContent=cur.t||'';
      const list=seg.flat.slice(0,idx).slice(-3).reverse();
      $('hist').innerHTML=list.map(x=>`<div><i style="background:${moodFor(p,x.mood)[0]}"></i>${esc(x.t)}</div>`).join('');
      [...$('prog').children].forEach((el,k)=>el.classList.toggle('on',k<=idx));
      $('hist').style.display=''; fitThought(); $('decision').dataset.k=''; if(seg.decAt&&i===b.length-1) prepDecision(p,key);
    }
    const tf=Math.min(1,Math.max(0,(t-cur.ds)/.35)); $('thought').style.opacity=.25+.75*tf; $('thought').style.transform=`translateY(${(1-tf)*10}px)`;
    // decision (history hides while it shows, so it never sits under the card)
    const dec=$('decision'); const showDec=!!(seg.decAt&&t>=seg.decAt);
    $('hist').style.display=showDec?'none':'';
    if(showDec){
      if(dec.dataset.k!==key) prepDecision(p,key);
      const f=Math.min(1,(t-seg.decAt)/.4); dec.style.opacity=f; dec.style.transform=`translateY(${(1-f)*16}px)`; built.gz.style.opacity=0; }
    else dec.style.opacity=0;
  } else {
    $('walk').style.opacity=0; const c=$('card'); c.style.opacity=fade; built=null;
    if(c.dataset.k!==seg.type+(seg.p?seg.p.id:'')){ c.dataset.k=seg.type+(seg.p?seg.p.id:'');
      if(seg.type==='intro') c.innerHTML=`<div class="kick">${kicker()}</div><h1>${W.title||''}</h1><p>${esc(W.intro||'')}</p><div class="ppl">${W.personas.map(p=>`<div><span class="av" style="background:${esc(p.color)}">${esc(p.initials)}</span>${esc(p.name)}, ${esc(p.age)}</div>`).join('')}</div>`;
      if(seg.type==='pcard'){ const p=seg.p; c.innerHTML=`<div class="pcard"><div class="av" style="background:${esc(p.color)}">${esc(p.initials)}</div></div><div class="kick">Buyer ${W.personas.indexOf(p)+1} of ${W.personas.length}</div><h1>${esc(p.name)}, ${esc(p.age)}</h1><p>${esc(p.line)}<br>${esc(p.wants)}</p>${p.ad?`<p style="color:var(--cream);font-size:34px;margin-top:34px">Came from the ad: <b>“${esc(p.ad)}”</b></p>`:''}`; }
      if(seg.type==='outro') c.innerHTML=`<div class="kick">Walkthrough</div><h1 style="font-size:58px;max-width:none">${esc(W.findingsTitle||'What to change.')}</h1><div class="find"><div class="fh">What happened</div><div class="fh">What to change</div>${(W.findings||[]).map(f=>`<div class="fi"><i style="background:${MOOD[f.mood]||MOOD['?']}"></i>${esc(f.t)}</div><div class="fx"><b>→</b>${esc(f.fix)}</div>`).join('')}</div><p style="font-size:20px;margin-top:40px">${esc(NOTE)}</p>`;
    }
  }
  lastT=t;
};
// resolves when every image and font is ready (used by the frame renderer)
window.frameReady=()=>Promise.all([...document.images].map(i=>i.complete?Promise.resolve():new Promise(r=>{i.onload=i.onerror=r;}))).then(()=>document.fonts.ready);
// ---- player (not used when rendering frames: ?render=1)
(function(){ const q=new URLSearchParams(location.search);
  const relayout=()=>{ if(built) built.lastBeat=-2; $('decision').dataset.k=''; $('card').dataset.k=''; if(lastT>=0) renderAt(lastT); };
  const fitStage=()=>{ const ctlH=q.has('render')?0:$('ctl').offsetHeight; const was=document.body.classList.contains('portrait'); const por=q.has('portrait')||(!q.has('render')&&innerWidth/(innerHeight-ctlH)<.9); document.body.classList.toggle('portrait',por); const SW=por?1080:1920, SH=por?1920:1080; const sc=Math.min(innerWidth/SW,(innerHeight-ctlH)/SH); const w=$('wrap'); w.style.transform=`scale(${sc})`; w.style.left=((innerWidth-SW*sc)/2)+'px'; w.style.top=((innerHeight-ctlH-SH*sc)/2)+'px'; if(was!==por) relayout(); };
  if(q.has('render')){ document.body.classList.add('render'); if(q.has('portrait')) document.body.classList.add('portrait'); return; }
  addEventListener('resize',fitStage); fitStage(); setTimeout(fitStage,50);
  let t=+(q.get('t')||0), playing=true, last=null;
  const sc=$('scrub'); sc.max=DURATION.toFixed(1);
  const marks=[['Intro',0]].concat(T.filter(x=>x.type==='pcard').map(x=>[x.p.name,x.s])).concat(T.some(x=>x.type==='outro')?[['Findings',T[T.length-1].s]]:[]);
  $('chapters').innerHTML=marks.map(([n,s],k)=>`<button data-s="${s}">${esc(n)}</button>`).join('');
  const fmt=x=>{x=Math.max(0,Math.floor(x));return Math.floor(x/60)+':'+String(x%60).padStart(2,'0');};
  const seek=x=>{ t=Math.min(Math.max(0,x),DURATION-.01); renderAt(t); ui(); };
  const ui=()=>{ sc.value=t.toFixed(1); $('time').textContent=fmt(t)+' / '+fmt(DURATION); $('pp').textContent=playing?'❚❚':'▶'; $('pp').setAttribute('aria-label',playing?'Pause':'Play');
    [...$('chapters').children].forEach((b,k)=>{ const s0=marks[k][1], s1=k+1<marks.length?marks[k+1][1]:DURATION; b.classList.toggle('on',t>=s0&&t<s1); }); };
  $('pp').onclick=()=>{ playing=!playing; last=null; ui(); };
  $('back').onclick=()=>seek(t-5); $('fwd').onclick=()=>seek(t+5);
  $('chapters').onclick=e=>{ const b=e.target.closest('button'); if(b) seek(+b.dataset.s+.6); };
  sc.oninput=()=>seek(+sc.value);
  addEventListener('keydown',e=>{ if(e.target===sc) return; if(e.key===' '){e.preventDefault();$('pp').click();} if(e.key==='ArrowRight') seek(t+5); if(e.key==='ArrowLeft') seek(t-5); });
  const loop=now=>{ if(playing){ if(last!==null){ t+= (now-last)/1000; if(t>=DURATION){ t=DURATION-.01; playing=false; } } last=now; renderAt(t); ui(); } else last=null; requestAnimationFrame(loop); };
  document.fonts.ready.then(()=>{ seek(t); requestAnimationFrame(loop); });
})();
</script>
</body>
</html>

````

````text file=render.py sha256=8d552e81e5792e15c2ee1cb866c4aa9517debfc04bb0a26231bc3bd43af99f51
#!/usr/bin/env python3
"""Render a walkthrough run folder to MP4.

usage: render.py RUN_DIR [--fps 30] [--max-seconds N] [--name SLUG]
Frames are written as JPEG files to a temp dir, then encoded with ffmpeg:
RUN_DIR/<SLUG>.mp4 (crf 20) and RUN_DIR/<SLUG>-small.mp4 (crf 26, slow).
Exits 1 when the frame count or duration does not match, or on page errors.
"""
import argparse
import os
import shutil
import subprocess
import sys
import tempfile

from playwright.sync_api import sync_playwright

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _serve import serve  # noqa: E402


def probe(path):
    r = subprocess.run(
        ["ffprobe", "-v", "error", "-count_frames", "-select_streams", "v:0",
         "-show_entries", "stream=nb_read_frames:format=duration", "-of", "default=nw=1", path],
        capture_output=True, text=True, check=True).stdout
    d = dict(l.split("=", 1) for l in r.split() if "=" in l)
    return int(d["nb_read_frames"]), float(d["duration"])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("run_dir")
    ap.add_argument("--fps", type=int, default=30)
    ap.add_argument("--max-seconds", type=float)
    ap.add_argument("--name")
    a = ap.parse_args()
    run = os.path.abspath(a.run_dir)
    slug = a.name or os.path.basename(run.rstrip("/"))
    if not os.path.exists(os.path.join(run, "index.html")):
        print(f"no index.html in {run}", file=sys.stderr)
        return 1
    tmp = tempfile.mkdtemp(prefix="aw-frames-")
    errors = []
    try:
        with serve(run) as base, sync_playwright() as pw:
            br = pw.chromium.launch(headless=True, chromium_sandbox=True)
            pg = br.new_page(viewport={"width": 1920, "height": 1080})
            pg.on("pageerror", lambda e: errors.append(f"pageerror: {e}"))
            pg.on("console", lambda m: errors.append(f"console.{m.type}: {m.text}") if m.type == "error" else None)
            pg.goto(base + "index.html?render=1", wait_until="load")
            pg.wait_for_function("typeof window.renderAt==='function'")
            pg.evaluate("document.fonts.ready.then(()=>1)")
            dur = pg.evaluate("window.DURATION")
            if a.max_seconds:
                dur = min(dur, a.max_seconds)
            n = int(round(dur * a.fps))
            print(f"duration {dur:.2f}s, {n} frames at {a.fps} fps")
            for i in range(n):
                pg.evaluate(f"renderAt({i / a.fps})")
                pg.evaluate("window.frameReady()")
                pg.screenshot(path=os.path.join(tmp, f"f{i:06d}.jpg"), type="jpeg", quality=95)
                if i % 300 == 0:
                    print(f"  frame {i}/{n}", flush=True)
            br.close()
        have = len([f for f in os.listdir(tmp) if f.endswith(".jpg")])
        if have != n:
            print(f"frame files {have} != expected {n}", file=sys.stderr)
            return 1
        big = os.path.join(run, slug + ".mp4")
        small = os.path.join(run, slug + "-small.mp4")
        src = ["ffmpeg", "-y", "-v", "error", "-framerate", str(a.fps), "-i", os.path.join(tmp, "f%06d.jpg")]
        subprocess.run(src + ["-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "20", "-preset", "medium",
                              "-movflags", "+faststart", big], check=True)
        subprocess.run(src + ["-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "26", "-preset", "slow",
                              "-movflags", "+faststart", small], check=True)
        bad = False
        for p in (big, small):
            frames, d = probe(p)
            ok = frames == n and abs(d - n / a.fps) <= 0.2 and abs(d - dur) <= 0.2
            print(f"{p}  {os.path.getsize(p) / 1e6:.1f} MB  {d:.2f}s  {frames} frames  {'OK' if ok else 'MISMATCH'}")
            bad |= not ok
        if errors:
            print("PAGE ERRORS:", file=sys.stderr)
            for e in dict.fromkeys(errors):
                print("  " + e, file=sys.stderr)
            bad = True
        return 1 if bad else 0
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())

````

````text file=stills.py sha256=550904ef6e6fc308be31355189c9b4da94060cd48033dd9cab9075c329258929
#!/usr/bin/env python3
"""Render stills of a walkthrough run folder.

usage: stills.py RUN_DIR t1 [t2 ...] [--portrait]
Steps renderAt from 0 to each t at 30 fps so the heatmap accumulates like the
video. Saves RUN_DIR/stills/still-<t>.jpg (1920x1080, portrait 1080x1920).
Exits 1 on any page error or console error.
"""
import argparse
import os
import sys

from playwright.sync_api import sync_playwright

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _serve import serve  # noqa: E402

FPS = 30


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("run_dir")
    ap.add_argument("times", nargs="+", type=float)
    ap.add_argument("--portrait", action="store_true")
    a = ap.parse_args()
    run = os.path.abspath(a.run_dir)
    if not os.path.exists(os.path.join(run, "index.html")):
        print(f"no index.html in {run}", file=sys.stderr)
        return 1
    out = os.path.join(run, "stills")
    os.makedirs(out, exist_ok=True)
    W, H = (1080, 1920) if a.portrait else (1920, 1080)
    errors = []
    with serve(run) as base, sync_playwright() as pw:
        br = pw.chromium.launch(headless=True, chromium_sandbox=True)
        pg = br.new_page(viewport={"width": W, "height": H})
        pg.on("pageerror", lambda e: errors.append(f"pageerror: {e}"))
        pg.on("console", lambda m: errors.append(f"console.{m.type}: {m.text}") if m.type == "error" else None)
        pg.goto(base + "index.html?render=1" + ("&portrait=1" if a.portrait else ""), wait_until="load")
        pg.wait_for_function("typeof window.renderAt==='function'")
        pg.evaluate("document.fonts.ready.then(()=>1)")
        dur = pg.evaluate("window.DURATION")
        print(f"DURATION {dur:.2f}")
        cur = 0.0
        first = True
        for t in sorted(a.times):
            if t > dur:
                print(f"warning: t={t} is past DURATION {dur:.2f}, clamped", file=sys.stderr)
            tt = min(t, dur - 0.01)
            n = int((tt - cur) * FPS)
            # step in one page call for speed, same 1/30 s steps as the video
            pg.evaluate(
                "([a,n,fps,first])=>{ if(first) renderAt(0); for(let i=1;i<=n;i++) renderAt(a+i/fps); }",
                [cur, n, FPS, first],
            )
            first = False
            cur = cur + n / FPS
            pg.evaluate(f"renderAt({tt})")
            pg.evaluate("window.frameReady()")
            pg.evaluate(f"renderAt({tt})")
            name = f"still-{t:g}" + ("-portrait" if a.portrait else "") + ".jpg"
            pg.screenshot(path=os.path.join(out, name), type="jpeg", quality=92)
            print(os.path.join(out, name))
            cur = max(cur, tt)
        br.close()
    if errors:
        print("ERRORS:", file=sys.stderr)
        for e in dict.fromkeys(errors):
            print("  " + e, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

````

````text file=walk.example.js sha256=5310f6c2bd472bce969554b26673c166615bf31fc34a5e914a5f3f09934eac32
// walk.js: what the buyers see, think and decide. Copy this file to walk.js in the run folder and replace the data.
// The player reads it together with capture/views.js (written by capture.py and ad_view.py).
//
// Format: comments only up here. After `window.WALK =` comes plain JSON (double quotes on keys and strings, no
// trailing commas, no comments), so check_walk.py reads it as data and never runs it.
//
// Top level
//   title          intro card headline; may hold one <em> for the accent colour
//   intro          intro card paragraph
//   note           small print on every walk screen; keep "simulated" and "scripted attention"
//   findingsTitle  end card headline
//   personas       one buyer per sub avatar
//   findings       end card rows: t (what happened, naming the buyer and the element) and fix (what to change)
// Persona
//   id, name, age, initials, color, pronoun ("her" or "his")
//   line           "Sub avatar N: ..." one line situation
//   wants          her own words from the research, verbatim, in curly quotes
//   src            where those words come from (a quote id like A045 or R9, or a link)
//   ad             optional: the ad she came from, shown as "Came from the ad"
//   quotes         optional: more of her verbatim words she may echo (strings, or {"t": "...", "src": "..."})
//   path           one segment per view in the order she meets them: [{"view": "ad-jess", "beats": [...]}, ...]
//   decision       label (what she does), price ($0 when she leaves), mood, why (the page element that decided it)
// Beat
//   d              seconds on this beat, 3.2 to 3.6 reads well
//   look           what she looks at, a few words
//   mood           "+" pulls her in, "-" pushes her away, "?" doubt
//   box            an id from capture/<view>-text.md (or "gaze": [[x, y], [x, y]] in page px when no box fits)
//   t              her thought, first person, at most 100 characters; page text in curly quotes must be copied
//                  exactly from the box she looks at
window.WALK = {
  "title": "Three buyers from our ads walk through <em>our store.</em>",
  "intro": "One buyer per sub avatar, each arriving from the ad written for her. Right side: what she looks at and what she thinks. The heatmap shows where the script puts her eyes.",
  "note": "Simulated walkthrough built from real customer quotes; the heatmap is scripted attention, not measured data.",
  "findingsTitle": "What the buyers show, and what to change.",
  "personas": [
    {
      "id": "jess", "name": "Jess", "age": 27, "initials": "J", "color": "#b59ad9", "pronoun": "her",
      "line": "Sub avatar 1: on her feet all day, no outlet. Works at a dog day camp.",
      "wants": "“I can't just bring a heating pad that I can plug into the wall.”",
      "src": "A1",
      "ad": "Can't plug a heating pad into the wall at work?",
      "quotes": [{ "t": "I work at a doggy day camp, so I can't just bring a heating pad that I can plug into the wall.", "src": "A1" }],
      "path": [
        { "view": "ad-jess", "beats": [
          { "d": 3.2, "look": "The hook", "mood": "+", "box": "ad-jess-2", "t": "That is literally my job. No outlet anywhere." },
          { "d": 3.0, "look": "Shop now", "mood": "?", "box": "ad-jess-6", "t": "Okay, show me how long it lasts." }
        ] },
        { "view": "mobile", "beats": [
          { "d": 3.4, "look": "Headline", "mood": "-", "box": "m7", "t": "The ad was about work. The headline is about my couch." },
          { "d": 3.6, "look": "Battery line", "mood": "-", "box": "m10", "t": "Half an hour per session. My shift is eight hours." }
        ] }
      ],
      "decision": { "label": "Leaves to compare", "price": "$0", "mood": "-", "why": "The ad promised a workday; the page sells half hour sessions and a second belt." }
    }
  ],
  "findings": [
    { "t": "Jess: the ad sells a whole shift, the page sells half hour sessions.", "fix": "Say it in the ad: two belts, one on you, one charging in your bag. Do not promise the shift.", "mood": "-" }
  ]
};

````
