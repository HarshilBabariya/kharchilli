"""Renders every Kharchili icon and splash image from one lettermark. Usage: python3 tool/make_brand.py

Needs rsvg-convert and Pillow. Output goes to assets/brand and platform/, which tool/patch_platforms.py copies into the native folders.
"""
import json, pathlib, subprocess

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
MARK = '''<g fill="none" stroke="#fff" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round">
<path d="M372 262 V762"/><path d="M372 598 C470 560 560 500 628 410"/><path d="M486 548 C540 640 590 712 664 762"/></g>
<circle cx="726" cy="296" r="{r}" fill="{dot}"/>'''
FILL = '''<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FF4D4D"/><stop offset=".55" stop-color="#E8203F"/><stop offset="1" stop-color="#B3124F"/></linearGradient>
<radialGradient id="h" cx=".28" cy=".2" r=".8"><stop offset="0" stop-color="#fff" stop-opacity=".22"/><stop offset=".6" stop-color="#fff" stop-opacity="0"/></radialGradient></defs>
<rect width="1024" height="1024" rx="{rx}" fill="url(#g)"/><rect width="1024" height="1024" rx="{rx}" fill="url(#h)"/>'''


def mark(scale, dot='#FFC531', w=112, r=58):
    t = 512 * (1 - scale)
    return f'<g transform="translate({t} {t}) scale({scale})">{MARK.format(w=w, r=r, dot=dot)}</g>'


def render(body, size, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 1024 1024">{body}</svg>'
    subprocess.run(['rsvg-convert', '/dev/stdin', '-o', str(path)], input=svg.encode(), check=True)


SQUARE = FILL.format(rx=0) + mark(1.0)
render(SQUARE, 1024, ROOT / 'assets' / 'brand' / 'icon.png')

res = ROOT / 'platform' / 'android' / 'res'
for density, factor in (('mdpi', 1), ('hdpi', 1.5), ('xhdpi', 2), ('xxhdpi', 3), ('xxxhdpi', 4)):
    folder = res / f'mipmap-{density}'
    render(FILL.format(rx=230) + mark(1.0), round(48 * factor), folder / 'ic_launcher.png')
    render(FILL.format(rx=0), round(108 * factor), folder / 'ic_launcher_background.png')
    render(mark(0.62), round(108 * factor), folder / 'ic_launcher_foreground.png')
    render(mark(0.62, dot='#fff'), round(108 * factor), folder / 'ic_launcher_monochrome.png')
render(mark(0.98, dot='#fff', w=124, r=64), 96, res / 'drawable' / 'ic_stat_kharchili.png')

ios = ROOT / 'platform' / 'ios'
render(SQUARE, 1024, ios / 'AppIcon.appiconset' / 'AppIcon.png')
Image.open(ios / 'AppIcon.appiconset' / 'AppIcon.png').convert('RGB').save(ios / 'AppIcon.appiconset' / 'AppIcon.png')
(ios / 'AppIcon.appiconset' / 'Contents.json').write_text(json.dumps({
    'images': [{'filename': 'AppIcon.png', 'idiom': 'universal', 'platform': 'ios', 'size': '1024x1024'}],
    'info': {'author': 'xcode', 'version': 1},
}, indent=2) + '\n')
for suffix, size in (('', 168), ('@2x', 336), ('@3x', 504)):
    render(mark(1.0), size, ios / 'LaunchImage.imageset' / f'LaunchImage{suffix}.png')
