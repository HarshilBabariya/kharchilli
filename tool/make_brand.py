"""Renders every Gharcha icon and splash image from one lettermark. Usage: python3 tool/make_brand.py

Needs rsvg-convert and Pillow. Output goes to assets/brand and platform/, which tool/patch_platforms.py copies into the native folders.
"""
import json, pathlib, subprocess

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
HOUSE = '<path d="M512 236 L792 468 V716 Q792 788 720 788 H304 Q232 788 232 716 V468 Z" fill="{c}" stroke="{c}" stroke-width="72" stroke-linejoin="round"/>'
RUPEE = '<g fill="none" stroke="{c}" stroke-width="54" stroke-linecap="round" stroke-linejoin="round"><path d="M410 452 H614"/><path d="M410 540 H614"/><path d="M410 452 H486 Q576 452 576 540 Q576 628 486 628 H410 L560 760"/></g>'
FILL = '''<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FF4D4D"/><stop offset=".55" stop-color="#E8203F"/><stop offset="1" stop-color="#B3124F"/></linearGradient>
<radialGradient id="h" cx=".28" cy=".2" r=".8"><stop offset="0" stop-color="#fff" stop-opacity=".22"/><stop offset=".6" stop-color="#fff" stop-opacity="0"/></radialGradient></defs>
<rect width="1024" height="1024" rx="{rx}" fill="url(#g)"/><rect width="1024" height="1024" rx="{rx}" fill="url(#h)"/>'''


def mark(scale, dot='#FFC531', cutout=False):
    """The house with the rupee inside. With cutout the rupee is transparent, for single-colour icons."""
    t = 512 * (1 - scale)
    spark = f'<circle cx="770" cy="268" r="58" fill="{dot}"/>'
    if cutout:
        body = f'<mask id="m"><rect width="1024" height="1024" fill="#fff"/>{RUPEE.format(c="#000")}</mask><g mask="url(#m)">{HOUSE.format(c="#fff")}</g>{spark}'
    else:
        body = HOUSE.format(c='#fff') + RUPEE.format(c='#E8203F') + spark
    return f'<g transform="translate({t} {t}) scale({scale})">{body}</g>'


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
    render(mark(0.62, dot='#fff', cutout=True), round(108 * factor), folder / 'ic_launcher_monochrome.png')
render(mark(1.25, dot='#fff', cutout=True), 96, res / 'drawable' / 'ic_stat_gharcha.png')
render(mark(0.6), 960, res / 'drawable-nodpi' / 'splash_mark.png')

ios = ROOT / 'platform' / 'ios'
render(SQUARE, 1024, ios / 'AppIcon.appiconset' / 'AppIcon.png')
Image.open(ios / 'AppIcon.appiconset' / 'AppIcon.png').convert('RGB').save(ios / 'AppIcon.appiconset' / 'AppIcon.png')
(ios / 'AppIcon.appiconset' / 'Contents.json').write_text(json.dumps({
    'images': [{'filename': 'AppIcon.png', 'idiom': 'universal', 'platform': 'ios', 'size': '1024x1024'}],
    'info': {'author': 'xcode', 'version': 1},
}, indent=2) + '\n')
for suffix, size in (('', 168), ('@2x', 336), ('@3x', 504)):
    render(mark(1.3), size, ios / 'LaunchImage.imageset' / f'LaunchImage{suffix}.png')
