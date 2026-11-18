"""Renders the Kharchili launcher, splash and store icons from one lettermark. Usage: python3 tool/make_brand.py assets/brand"""
import subprocess, sys, pathlib

out = pathlib.Path(sys.argv[1])
MARK = '''<g fill="none" stroke="#fff" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round">
<path d="M372 262 V762"/><path d="M372 598 C470 560 560 500 628 410"/><path d="M486 548 C540 640 590 712 664 762"/></g>
<circle cx="726" cy="296" r="{r}" fill="#FFC531"/>'''
BG = '''<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FF4D4D"/><stop offset=".55" stop-color="#E8203F"/><stop offset="1" stop-color="#B3124F"/></linearGradient>
<radialGradient id="h" cx=".28" cy=".2" r=".8"><stop offset="0" stop-color="#fff" stop-opacity=".22"/><stop offset=".6" stop-color="#fff" stop-opacity="0"/></radialGradient></defs>'''

def svg(body, size=1024):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 1024 1024">{body}</svg>'

def scaled(scale, w=112, r=58):
    t = 512 * (1 - scale)
    return f'<g transform="translate({t} {t}) scale({scale})">{MARK.format(w=w, r=r)}</g>'

files = {
    'icon.svg': svg(BG + '<rect width="1024" height="1024" fill="url(#g)"/><rect width="1024" height="1024" fill="url(#h)"/>' + scaled(1.0)),
    'icon_background.svg': svg(BG + '<rect width="1024" height="1024" fill="url(#g)"/><rect width="1024" height="1024" fill="url(#h)"/>'),
    'icon_foreground.svg': svg(scaled(0.62)),
    'icon_monochrome.svg': svg(scaled(0.62).replace('#FFC531', '#fff')),
    'splash.svg': svg(scaled(0.9), 768),
}
for name, text in files.items():
    (out / name).write_text(text)
    subprocess.run(['rsvg-convert', str(out / name), '-o', str(out / name.replace('.svg', '.png'))], check=True)
notification = out.parent.parent / 'platform' / 'android' / 'res' / 'drawable' / 'ic_stat_kharchili.png'
subprocess.run(['rsvg-convert', '/dev/stdin', '-o', str(notification)], input=svg(scaled(0.98, 124, 64).replace('#FFC531', '#fff'), 96).encode(), check=True)
