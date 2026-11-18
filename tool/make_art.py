"""Draws the illustrated art (badge medals and sticker icons) and renders it to assets/art and website/public/art.

Usage: python3 tool/make_art.py   (needs rsvg-convert)
"""
import math, pathlib, subprocess, tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / 'assets' / 'art'


def mix(c, to, t):
    a = [int(c[i:i + 2], 16) for i in (1, 3, 5)]
    b = [int(to[i:i + 2], 16) for i in (1, 3, 5)]
    return '#%02x%02x%02x' % tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def light(c, t): return mix(c, '#ffffff', t)
def dark(c, t): return mix(c, '#000000', t)


class Art:
    """Collects gradient definitions while a drawing is being put together."""

    def __init__(self):
        self.defs = []

    def lin(self, *stops, x1=0, y1=0, x2=0, y2=1):
        i = f'g{len(self.defs)}'
        body = ''.join(f'<stop offset="{k / (len(stops) - 1):.3f}" stop-color="{c}"/>' for k, c in enumerate(stops))
        self.defs.append(f'<linearGradient id="{i}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}">{body}</linearGradient>')
        return f'url(#{i})'

    def rad(self, *stops, cx=.35, cy=.3, r=.9):
        i = f'g{len(self.defs)}'
        body = ''.join(f'<stop offset="{k / (len(stops) - 1):.3f}" stop-color="{c}"/>' for k, c in enumerate(stops))
        self.defs.append(f'<radialGradient id="{i}" cx="{cx}" cy="{cy}" r="{r}">{body}</radialGradient>')
        return f'url(#{i})'

    def gold(self): return self.lin('#FFF6C2', '#FFD23F', '#F5A300', '#C97A00')
    def steel(self): return self.lin('#FFFFFF', '#DCE3EC', '#A9B4C2')

    def svg(self, w, h, body):
        blur = '<filter id="sh" x="-30%" y="-30%" width="160%" height="170%"><feGaussianBlur in="SourceAlpha" stdDeviation="2.2"/><feOffset dy="2.5"/><feComponentTransfer><feFuncA type="linear" slope=".38"/></feComponentTransfer><feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge></filter>'
        return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}"><defs>{blur}{"".join(self.defs)}</defs>{body}</svg>'


def star(cx, cy, r, fill, inner=.45, points=5, extra=''):
    pts = []
    for k in range(points * 2):
        rr = r if k % 2 == 0 else r * inner
        ang = math.pi * k / points - math.pi / 2
        pts.append(f'{cx + rr * math.cos(ang):.1f},{cy + rr * math.sin(ang):.1f}')
    return f'<polygon points="{" ".join(pts)}" fill="{fill}" stroke-linejoin="round" {extra}/>'


def sparkle(cx, cy, r, fill='#fff', op=1):
    return f'<path d="M{cx} {cy - r} Q{cx} {cy} {cx + r} {cy} Q{cx} {cy} {cx} {cy + r} Q{cx} {cy} {cx - r} {cy} Q{cx} {cy} {cx} {cy - r} Z" fill="{fill}" opacity="{op}"/>'


def heart(cx, cy, s, fill):
    return f'<path transform="translate({cx} {cy}) scale({s / 10})" d="M0 9 C-14 -1 -10 -11 -4 -11 C-1 -11 0 -8 0 -7 C0 -8 1 -11 4 -11 C10 -11 14 -1 0 9 Z" fill="{fill}"/>'


def person(a, cx, cy, s, col):
    skin = a.rad('#FFE6C4', '#F4B77E')
    body = a.lin(light(col, .25), col, dark(col, .2))
    return (f'<path d="M{cx - 21 * s} {cy + 26 * s} C{cx - 21 * s} {cy + 4 * s} {cx - 10 * s} {cy} {cx} {cy} C{cx + 10 * s} {cy} {cx + 21 * s} {cy + 4 * s} {cx + 21 * s} {cy + 26 * s} Z" fill="{body}"/>'
            f'<circle cx="{cx}" cy="{cy - 15 * s}" r="{12 * s}" fill="{skin}"/>')


def house(a, extra):
    wall = a.lin('#FFFFFF', '#FFE9D6')
    roof = a.lin('#FF7A7A', '#E8203F', '#B0122E')
    return (f'<rect x="64" y="20" width="10" height="20" rx="2" fill="#B0122E"/>'
            f'<path d="M20 46 V82 Q20 88 26 88 H74 Q80 88 80 82 V46 L50 22 Z" fill="{wall}"/>'
            f'<path d="M8 52 L50 14 L92 52" fill="none" stroke="{roof}" stroke-width="11" stroke-linecap="round" stroke-linejoin="round"/>'
            f'<path d="M14 49 L50 17" fill="none" stroke="#fff" stroke-opacity=".35" stroke-width="3" stroke-linecap="round"/>{extra}')


def target(a, cx=50, cy=52, r=38):
    red = a.rad('#FF8A8A', '#E8203F', '#B0122E')
    out = ''
    for k, rr in enumerate((1, .76, .52, .28)):
        out += f'<circle cx="{cx}" cy="{cy}" r="{r * rr}" fill="{red if k % 2 == 0 else "#FFFFFF"}"/>'
    return out + (f'<path d="M{cx} {cy} L{cx + r * .92} {cy - r * .92}" stroke="#6B4423" stroke-width="5" stroke-linecap="round"/>'
                  f'<path d="M{cx + r * .92} {cy - r * .92} l10 -2 l-6 8 Z M{cx + r * .92} {cy - r * .92} l2 -10 l-8 6 Z" fill="#FFC83D" stroke="#FFC83D" stroke-width="3" stroke-linejoin="round"/>'
                  f'<path d="M{cx} {cy} l12 -4 l-8 -8 Z" fill="#8892A0"/>')


# ---------------------------------------------------------------------------------------------------------------------
# Emblems: each draws inside a 100 x 100 box.

def e_flag(a):
    return (f'<ellipse cx="32" cy="88" rx="16" ry="5" fill="#1F7A45"/><rect x="29" y="14" width="6" height="74" rx="3" fill="{a.gold()}"/><circle cx="32" cy="13" r="6" fill="{a.gold()}"/>'
            f'<path d="M35 20 C47 12 60 28 80 20 V52 C60 60 47 44 35 52 Z" fill="{a.lin("#FF8A8A", "#E8203F")}"/>'
            f'<path d="M35 38 C47 30 60 46 80 38 V52 C60 60 47 44 35 52 Z" fill="#8E0F26" opacity=".3"/>{star(56, 34, 8, "#FFE58A")}')


def e_receipt(a):
    lines = ''.join(f'<rect x="32" y="{y}" width="{w}" height="5" rx="2.5" fill="#C9D3E0"/>' for y, w in ((24, 36), (36, 28), (48, 34)))
    return (f'<path d="M22 10 H78 V86 L70 79 L62 86 L54 79 L46 86 L38 79 L30 86 L22 79 Z" fill="{a.lin("#FFFFFF", "#E8EEF6")}"/>{lines}'
            f'<circle cx="64" cy="66" r="19" fill="{a.lin("#5BB8FF", "#0277BD")}" stroke="#fff" stroke-width="3"/>'
            f'<text x="64" y="74" font-family="Poppins" font-weight="700" font-size="21" fill="#fff" text-anchor="middle">10</text>')


def e_hundred(a):
    return (f'<text x="50" y="64" font-family="Poppins" font-weight="700" font-size="44" fill="{a.gold()}" stroke="#8A5200" stroke-width="2" paint-order="stroke" text-anchor="middle" letter-spacing="-2">100</text>'
            f'<rect x="16" y="74" width="68" height="6" rx="3" fill="{a.gold()}"/><rect x="28" y="84" width="44" height="5" rx="2.5" fill="{a.gold()}" opacity=".7"/>{sparkle(82, 22, 9)}{sparkle(18, 30, 6)}')


def e_rocket(a):
    return (f'<g transform="rotate(38 50 50)"><path d="M41 62 H59 C59 78 54 86 50 96 C46 86 41 78 41 62 Z" fill="{a.lin("#FFE58A", "#FF7A1A", "#E8203F")}"/>'
            f'<path d="M37 48 L20 72 L38 66 Z M63 48 L80 72 L62 66 Z" fill="{a.lin("#FF7A7A", "#C2152F")}"/>'
            f'<path d="M50 4 C66 20 70 42 64 64 H36 C30 42 34 20 50 4 Z" fill="{a.lin("#FFFFFF", "#D5DFEE", x2=1, y2=0)}"/>'
            f'<path d="M50 4 C58 12 63 21 65 30 H35 C37 21 42 12 50 4 Z" fill="{a.lin("#FF7A7A", "#E8203F")}"/>'
            f'<circle cx="50" cy="42" r="9" fill="{a.rad("#B5E3FF", "#1E88E5")}" stroke="#34495E" stroke-width="3"/></g>')


def e_flame(a):
    return (f'<path d="M50 6 C56 26 80 34 76 60 C74 80 60 92 50 92 C36 92 22 80 24 60 C25 47 34 43 36 30 C44 35 46 42 46 48 C52 40 53 22 50 6 Z" fill="{a.lin("#FFD23F", "#FF8A1F", "#E8203F")}"/>'
            f'<path d="M51 44 C55 56 66 60 64 74 C63 84 56 90 50 90 C42 90 36 84 37 74 C38 66 44 64 45 57 C48 59 49 62 51 44 Z" fill="{a.lin("#FFF6C2", "#FFC83D")}"/>'
            f'<ellipse cx="50" cy="80" rx="6" ry="8" fill="#fff" opacity=".75"/>')


def e_trophy(a):
    g = a.gold()
    return (f'<path d="M30 22 H14 C14 42 22 48 34 48 M70 22 H86 C86 42 78 48 66 48" fill="none" stroke="{g}" stroke-width="7" stroke-linecap="round"/>'
            f'<rect x="45" y="58" width="10" height="18" fill="#C97A00"/><rect x="32" y="74" width="36" height="9" rx="3" fill="{g}"/><rect x="24" y="82" width="52" height="10" rx="3" fill="{a.lin("#7A4A1E", "#4A2A0C")}"/>'
            f'<path d="M26 12 H74 V32 C74 52 63 62 50 62 C37 62 26 52 26 32 Z" fill="{g}"/>'
            f'<path d="M32 16 H39 V36 C39 46 43 53 48 57 C39 54 32 46 32 34 Z" fill="#fff" opacity=".5"/>{star(54, 34, 10, "#FFF6C2")}')


def e_bolt(a):
    return (f'<path d="M60 4 L20 54 H44 L34 96 L80 40 H55 Z" fill="{a.lin("#FFF79A", "#FFC83D", "#F59300")}" stroke="#B36A00" stroke-width="2.5" stroke-linejoin="round"/>'
            f'<path d="M55 14 L29 49 H39 Z" fill="#fff" opacity=".6"/>')


def e_flame_star(a):
    return e_flame(a) + star(50, 70, 13, '#fff', extra='opacity=".95"')


def e_sunrise(a):
    rays = ''.join(f'<path d="M{50 + 31 * math.cos(math.radians(t)):.1f} {60 + 31 * math.sin(math.radians(t)):.1f} L{50 + 42 * math.cos(math.radians(t)):.1f} {60 + 42 * math.sin(math.radians(t)):.1f}" stroke="#FFD23F" stroke-width="5" stroke-linecap="round"/>' for t in range(195, 350, 25))
    return (f'{rays}<path d="M25 60 A25 25 0 0 1 75 60 Z" fill="{a.lin("#FFF27A", "#FF9F1C")}"/>'
            f'<rect x="8" y="60" width="84" height="10" rx="5" fill="{a.lin("#FF8A3D", "#E8551F")}"/><rect x="22" y="75" width="56" height="7" rx="3.5" fill="#FF8A3D" opacity=".75"/><rect x="34" y="87" width="32" height="6" rx="3" fill="#FF8A3D" opacity=".5"/>')


def e_moon(a):
    return (f'<path d="M60 8 A40 40 0 1 0 92 62 A32 32 0 1 1 60 8 Z" fill="{a.lin("#FFF6C2", "#FFC83D")}"/>'
            f'<circle cx="36" cy="58" r="5" fill="#E0A21F" opacity=".45"/><circle cx="50" cy="76" r="3.5" fill="#E0A21F" opacity=".45"/>{sparkle(72, 30, 9, "#FFF6C2")}{sparkle(86, 46, 5, "#fff")}{sparkle(60, 46, 4, "#fff")}')


def e_mic(a):
    grille = ''.join(f'<rect x="38" y="{y}" width="24" height="3" rx="1.5" fill="#5B6472" opacity=".35"/>' for y in (18, 25, 32))
    return (f'<path d="M24 44 C24 62 36 72 50 72 C64 72 76 62 76 44" fill="none" stroke="#4A5362" stroke-width="6" stroke-linecap="round"/><rect x="47" y="72" width="6" height="14" fill="#4A5362"/><rect x="32" y="84" width="36" height="8" rx="4" fill="#4A5362"/>'
            f'<rect x="35" y="8" width="30" height="52" rx="15" fill="{a.steel()}"/>{grille}<rect x="35" y="40" width="30" height="7" fill="#E8203F"/>'
            f'<rect x="40" y="13" width="6" height="22" rx="3" fill="#fff" opacity=".7"/>')


def e_notes(a):
    lines = ''.join(f'<rect x="26" y="{y}" width="{w}" height="5" rx="2.5" fill="#C9D3E0"/>' for y, w in ((26, 34), (38, 26), (50, 30), (62, 20)))
    return (f'<rect x="16" y="12" width="54" height="76" rx="8" fill="{a.lin("#FFFFFF", "#E8EEF6")}"/>{lines}'
            f'<g transform="rotate(38 68 54)"><rect x="61" y="18" width="14" height="10" rx="4" fill="#FF8FA3"/><rect x="61" y="26" width="14" height="6" fill="#B8C0CC"/>'
            f'<rect x="61" y="32" width="14" height="44" fill="{a.lin("#FFE58A", "#F5A300", x2=1, y2=0)}"/><path d="M61 76 H75 L68 92 Z" fill="#F3D2A2"/><path d="M65.5 86 H70.5 L68 92 Z" fill="#34495E"/></g>')


def e_compass(a):
    ticks = ''.join(f'<rect x="48.5" y="16" width="3" height="7" rx="1.5" fill="#7A8696" transform="rotate({t} 50 50)"/>' for t in range(0, 360, 45))
    return (f'<circle cx="50" cy="50" r="42" fill="{a.steel()}"/><circle cx="50" cy="50" r="35" fill="{a.rad("#FFFFFF", "#DCEBFF")}"/>{ticks}'
            f'<g transform="rotate(35 50 50)"><path d="M50 16 L60 50 H40 Z" fill="{a.lin("#FF7A7A", "#C2152F")}"/><path d="M50 84 L60 50 H40 Z" fill="#8892A0"/></g><circle cx="50" cy="50" r="6" fill="{a.gold()}"/>')


def e_tag(a):
    return (f'<path d="M12 50 L46 16 Q49 13 53 13 H80 Q87 13 87 20 V47 Q87 51 84 54 L50 88 Q46 92 42 88 L12 58 Q8 54 12 50 Z" fill="{a.lin("#C77DFF", "#8E24AA", "#5E1380", x2=1)}"/>'
            f'<path d="M20 50 L50 20" stroke="#fff" stroke-opacity=".4" stroke-width="4" stroke-linecap="round"/><circle cx="70" cy="30" r="7" fill="#fff"/>'
            f'<path d="M70 30 C82 22 90 10 96 4" fill="none" stroke="{a.gold()}" stroke-width="3" stroke-linecap="round"/>{star(42, 60, 9, "#FFE58A")}')


def e_card(a):
    return (f'<g transform="rotate(-12 50 50)"><rect x="8" y="24" width="84" height="56" rx="10" fill="{a.lin("#FFC46B", "#FB8C00", "#D35400", x2=1)}"/><rect x="8" y="36" width="84" height="11" fill="#4A2A0C" opacity=".8"/>'
            f'<rect x="18" y="56" width="18" height="13" rx="3" fill="{a.gold()}"/><rect x="46" y="60" width="36" height="5" rx="2.5" fill="#fff" opacity=".85"/><rect x="46" y="69" width="22" height="4" rx="2" fill="#fff" opacity=".55"/></g>{sparkle(84, 20, 8)}')


def e_diamond(a):
    return (f'<path d="M26 18 H74 L94 42 L50 92 L6 42 Z" fill="{a.lin("#9CF0FF", "#00ACC1", "#006978")}"/><path d="M26 18 H74 L94 42 H6 Z" fill="#C8F8FF"/>'
            f'<path d="M26 18 L36 42 L50 18 L64 42 L74 18" fill="none" stroke="#00ACC1" stroke-width="2" stroke-linejoin="round"/><path d="M36 42 L50 92 L64 42 Z" fill="#fff" opacity=".35"/>{sparkle(80, 16, 10)}{sparkle(16, 66, 6)}')


def e_coins(a):
    out = ''
    for y in (74, 58, 42):
        out += f'<path d="M20 {y} v10 a30 10 0 0 0 60 0 v-10 Z" fill="#C97A00"/><ellipse cx="50" cy="{y}" rx="30" ry="10" fill="{a.gold()}" stroke="#FFF6C2" stroke-width="2"/>'
    return out + f'<text x="50" y="47" font-family="Poppins" font-weight="700" font-size="13" fill="#8A5200" text-anchor="middle">₹</text>{sparkle(82, 26, 8)}'


def e_two(a): return person(a, 34, 54, 1, '#7C4DFF') + person(a, 66, 54, 1, '#FF7A1A') + heart(50, 24, 9, '#E8203F')
def e_three(a): return person(a, 24, 50, .85, '#039BE5') + person(a, 76, 50, .85, '#22A861') + person(a, 50, 60, 1.1, '#3949AB')


def e_scale(a):
    g = a.gold()
    pans = ''.join(f'<path d="M{x} 26 L{x - 12} 54 M{x} 26 L{x + 12} 54" stroke="#C97A00" stroke-width="2"/><path d="M{x - 16} 54 H{x + 16} A16 12 0 0 1 {x - 16} 54 Z" fill="{g}"/>' for x in (20, 80))
    return f'<rect x="47" y="18" width="6" height="62" fill="{g}"/><path d="M32 80 H68 L74 90 H26 Z" fill="{g}"/><rect x="14" y="23" width="72" height="6" rx="3" fill="{g}"/>{pans}<circle cx="50" cy="18" r="7" fill="{g}"/>'


def e_bank(a):
    stone = a.lin('#FFFFFF', '#D5E3EA')
    cols = ''.join(f'<rect x="{x}" y="44" width="10" height="30" rx="2" fill="{stone}"/>' for x in (19, 37, 54, 71))
    return (f'<path d="M8 38 L50 10 L92 38 Z" fill="{a.lin("#4DD0C1", "#00897B")}"/><circle cx="50" cy="27" r="6" fill="{a.gold()}"/><rect x="12" y="36" width="76" height="8" rx="2" fill="{stone}"/>{cols}'
            f'<rect x="12" y="74" width="76" height="8" rx="2" fill="{stone}"/><rect x="6" y="82" width="88" height="9" rx="3" fill="{a.lin("#4DD0C1", "#00897B")}"/>')


def e_home_heart(a): return house(a, heart(50, 68, 15, '#E8203F'))
def e_home_star(a): return house(a, star(50, 64, 16, a.gold()))
def e_home(a): return house(a, f'<rect x="42" y="62" width="16" height="26" rx="4" fill="{a.lin("#B07A4A", "#7A4A1E")}"/><circle cx="54" cy="76" r="1.8" fill="#FFD23F"/><rect x="26" y="54" width="11" height="11" rx="2.5" fill="#7CC4FF"/><rect x="63" y="54" width="11" height="11" rx="2.5" fill="#7CC4FF"/>')


def e_calendar(a):
    return (f'<rect x="12" y="18" width="76" height="72" rx="12" fill="{a.lin("#FFFFFF", "#E8EEF6")}"/><path d="M12 30 Q12 18 24 18 H76 Q88 18 88 30 V40 H12 Z" fill="{a.lin("#5BB8FF", "#0277BD")}"/>'
            f'<rect x="28" y="9" width="8" height="18" rx="4" fill="#4A5362"/><rect x="64" y="9" width="8" height="18" rx="4" fill="#4A5362"/><path d="M30 64 L44 77 L70 50" fill="none" stroke="#22A861" stroke-width="9" stroke-linecap="round" stroke-linejoin="round"/>')


def e_target(a): return target(a)
def e_target3(a): return target(a, 50, 60, 30) + star(26, 16, 9, a.gold()) + star(50, 10, 10, a.gold()) + star(74, 16, 9, a.gold())


def e_shirt(a):
    return (f'<path d="M32 12 L10 26 L22 46 L32 40 V88 H68 V40 L78 46 L90 26 L68 12 C64 24 36 24 32 12 Z" fill="{a.lin("#FF8FC0", "#EC407A", "#B0125A")}" stroke="#8E0F47" stroke-width="2" stroke-linejoin="round"/>'
            f'<path d="M32 12 C36 24 64 24 68 12" fill="none" stroke="#fff" stroke-opacity=".7" stroke-width="4"/>{star(50, 56, 11, "#FFE58A")}')


def e_shades(a):
    lens = a.lin('#5A5A72', '#12121A')
    return (f'<path d="M12 40 L4 30 M88 40 L96 30" stroke="#8E24AA" stroke-width="5" stroke-linecap="round"/><path d="M44 46 Q50 38 56 46" fill="none" stroke="#8E24AA" stroke-width="5"/>'
            f'<rect x="8" y="36" width="38" height="30" rx="14" fill="{lens}" stroke="{a.lin("#D9A5FF", "#8E24AA")}" stroke-width="4"/><rect x="54" y="36" width="38" height="30" rx="14" fill="{lens}" stroke="{a.lin("#D9A5FF", "#8E24AA")}" stroke-width="4"/>'
            f'<path d="M18 58 L32 42 M64 58 L78 42" stroke="#fff" stroke-opacity=".55" stroke-width="4" stroke-linecap="round"/>{sparkle(84, 22, 8)}')


def e_palette(a):
    blobs = ''.join(f'<circle cx="{x}" cy="{y}" r="8" fill="{c}"/><circle cx="{x - 2.5}" cy="{y - 2.5}" r="2.5" fill="#fff" opacity=".6"/>' for x, y, c in ((30, 38, '#E8203F'), (50, 26, '#FFC83D'), (72, 38, '#1E88E5'), (26, 60, '#22A861')))
    return f'<path d="M50 8 C76 8 92 26 92 46 C92 62 80 66 68 63 C58 61 54 68 59 77 C64 87 56 92 48 92 C24 92 8 74 8 50 C8 26 26 8 50 8 Z" fill="{a.lin("#FBE3BC", "#D9A066")}"/>{blobs}'


def e_gift(a):
    return (f'<rect x="18" y="44" width="64" height="46" rx="6" fill="{a.lin("#FFB347", "#FB8C00")}"/><rect x="12" y="30" width="76" height="18" rx="6" fill="{a.lin("#FFD08A", "#FFA726")}"/><rect x="43" y="30" width="14" height="60" fill="{a.lin("#FF7A7A", "#C2152F")}"/>'
            f'<path d="M50 30 C38 6 14 14 24 28 C30 34 42 33 50 30 Z M50 30 C62 6 86 14 76 28 C70 34 58 33 50 30 Z" fill="{a.lin("#FF7A7A", "#E8203F")}"/>{sparkle(86, 16, 7)}')


def e_speech(a):
    return (f'<path d="M16 10 H56 Q66 10 66 20 V44 Q66 54 56 54 H36 L22 68 V54 H16 Q6 54 6 44 V20 Q6 10 16 10 Z" fill="{a.lin("#6C7BFF", "#3949AB")}"/><text x="36" y="43" font-family="Poppins" font-weight="700" font-size="28" fill="#fff" text-anchor="middle">A</text>'
            f'<path d="M48 40 H84 Q94 40 94 50 V72 Q94 82 84 82 H80 V94 L66 82 H48 Q38 82 38 72 V50 Q38 40 48 40 Z" fill="{a.lin("#FF8FC0", "#EC407A")}" stroke="#fff" stroke-width="3"/><text x="66" y="71" font-family="Poppins" font-weight="700" font-size="24" fill="#fff" text-anchor="middle">अ</text>')


def e_star(a): return star(50, 52, 44, a.gold(), extra='stroke="#B36A00" stroke-width="2.5"') + '<path d="M50 8 L60 40 L50 52 L8 39 L40 40 Z" fill="#fff" opacity=".35"/>'


def e_crown(a):
    g = a.gold()
    gems = ''.join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{c}" stroke="#fff" stroke-width="1.5"/>' for x, y, r, c in ((50, 20, 6, '#E8203F'), (12, 34, 5, '#1E88E5'), (88, 34, 5, '#22A861'), (34, 78, 3.5, '#1E88E5'), (50, 78, 3.5, '#E8203F'), (66, 78, 3.5, '#22A861')))
    return f'<path d="M12 34 L32 56 L50 20 L68 56 L88 34 L80 84 H20 Z" fill="{g}" stroke="#B36A00" stroke-width="2.5" stroke-linejoin="round"/><rect x="20" y="70" width="60" height="16" rx="4" fill="{a.lin("#FFC83D", "#C97A00")}"/>{gems}'


def e_plane(a):
    return (f'<path d="M10 78 C24 70 30 80 44 72" fill="none" stroke="#fff" stroke-width="4" stroke-linecap="round" stroke-dasharray="1 9"/>'
            f'<path d="M6 50 L94 12 L64 90 L48 60 Z" fill="{a.lin("#FFFFFF", "#CFE3FF")}"/><path d="M48 60 L94 12 L54 72 Z" fill="#8FB4EC"/><path d="M48 60 L54 72 L46 82 Z" fill="#6E96D6"/>')


def e_party(a):
    conf = ''.join(f'<rect x="{x}" y="{y}" width="7" height="7" rx="2" fill="{c}" transform="rotate({r} {x} {y})"/>' for x, y, c, r in ((58, 12, '#FFC83D', 20), (80, 30, '#22A861', 50), (70, 52, '#1E88E5', 10), (40, 16, '#EC407A', 40), (88, 58, '#FFC83D', 70)))
    return (f'<path d="M12 90 L36 30 L72 66 Z" fill="{a.lin("#C77DFF", "#7C4DFF", "#4A1FB8")}"/><path d="M22 66 L46 80 M30 46 L60 72" stroke="#FFE58A" stroke-width="5" stroke-linecap="round"/>'
            f'<ellipse cx="54" cy="48" rx="26" ry="8" transform="rotate(45 54 48)" fill="#4A1FB8"/>{conf}<path d="M60 40 C66 26 78 30 76 16 M66 48 C80 46 82 36 94 40" fill="none" stroke="#E8203F" stroke-width="3.5" stroke-linecap="round"/>{sparkle(52, 30, 6)}')


def e_pizza(a):
    tops = ''.join(f'<circle cx="{x}" cy="{y}" r="7.5" fill="{a.rad("#FF7A7A", "#C2152F")}"/>' for x, y in ((38, 38), (62, 42), (50, 62)))
    return (f'<path d="M50 94 L12 26 Q50 2 88 26 Z" fill="{a.lin("#E8A64A", "#C9792B")}"/><path d="M50 84 L20 30 Q50 12 80 30 Z" fill="{a.lin("#FFE58A", "#FFC83D")}"/>{tops}'
            f'<circle cx="50" cy="28" r="3" fill="#22A861"/><circle cx="42" cy="54" r="3" fill="#22A861"/><circle cx="62" cy="58" r="2.5" fill="#22A861"/>')


def e_beach(a):
    return (f'<circle cx="80" cy="22" r="11" fill="{a.rad("#FFF27A", "#FF9F1C")}"/><ellipse cx="50" cy="88" rx="40" ry="7" fill="{a.lin("#FBE3BC", "#E3B77A")}"/>'
            f'<g transform="rotate(-14 46 52)"><rect x="44" y="50" width="5" height="38" rx="2.5" fill="#7A4A1E"/><path d="M8 52 A38 38 0 0 1 84 52 Z" fill="#fff"/><path d="M8 52 A38 38 0 0 1 27 20 L33 52 Z M46 14 A38 38 0 0 1 65 20 L59 52 H33 L27 20 A38 38 0 0 1 46 14" fill="none"/>'
            f'<path d="M8 52 A38 38 0 0 1 28 19 Q24 36 26 52 Z M46 14 Q38 32 39 52 H53 Q54 32 46 14 Z M64 19 A38 38 0 0 1 84 52 H66 Q68 36 64 19 Z" fill="{a.lin("#FF7A7A", "#E8203F")}"/></g>')


def e_bag(a):
    return (f'<path d="M36 40 V28 A14 14 0 0 1 64 28 V40" fill="none" stroke="#14532D" stroke-width="5.5" stroke-linecap="round"/><path d="M20 34 H80 L88 84 Q89 92 81 92 H19 Q11 92 12 84 Z" fill="{a.lin("#5EE08A", "#22A861", "#14753F")}"/>'
            f'<path d="M20 34 H80 L81.5 44 H18.5 Z" fill="#fff" opacity=".25"/><circle cx="36" cy="44" r="3.5" fill="#14532D"/><circle cx="64" cy="44" r="3.5" fill="#14532D"/>{heart(50, 68, 13, "#fff")}')


def e_car(a):
    wheels = ''.join(f'<circle cx="{x}" cy="74" r="12" fill="#2B2F38"/><circle cx="{x}" cy="74" r="5" fill="#C9D3E0"/>' for x in (28, 72))
    return (f'<path d="M6 64 Q6 52 18 50 L27 32 Q30 26 37 26 H63 Q70 26 73 32 L82 50 Q94 52 94 64 V72 Q94 76 90 76 H10 Q6 76 6 72 Z" fill="{a.lin("#FF7A7A", "#E8203F", "#B0122E")}"/>'
            f'<path d="M34 33 H47 V50 H26 Z M53 33 H66 L74 50 H53 Z" fill="{a.lin("#D6EEFF", "#8CCBFF")}"/><rect x="82" y="56" width="9" height="6" rx="3" fill="#FFE58A"/><rect x="9" y="56" width="7" height="6" rx="3" fill="#FFB3B3"/>{wheels}')


def e_cap(a):
    return (f'<path d="M24 50 V70 Q50 86 76 70 V50 L50 62 Z" fill="#1F2A5C"/><path d="M50 18 L96 40 L50 62 L4 40 Z" fill="{a.lin("#5C6BC0", "#3949AB", "#283593")}"/><path d="M50 22 L86 40 L50 44 Z" fill="#fff" opacity=".18"/>'
            f'<path d="M50 40 L84 44 V66" fill="none" stroke="{a.gold()}" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"/><rect x="80" y="64" width="8" height="16" rx="3" fill="{a.gold()}"/><circle cx="50" cy="40" r="4" fill="{a.gold()}"/>')


def e_milk(a):
    return (f'<path d="M39 14 H61 V26 L72 42 V84 Q72 92 64 92 H36 Q28 92 28 84 V42 L39 26 Z" fill="{a.lin("#FFFFFF", "#DCEBFA", x2=1, y2=0)}" stroke="#9DBEF0" stroke-width="2"/><rect x="36" y="6" width="28" height="10" rx="4" fill="{a.lin("#5BB8FF", "#0277BD")}"/>'
            f'<rect x="28" y="52" width="44" height="24" fill="{a.lin("#5BB8FF", "#1E88E5")}"/><path d="M50 56 C55 62 57 65 57 68 A7 7 0 0 1 43 68 C43 65 45 62 50 56 Z" fill="#fff"/><rect x="34" y="32" width="5" height="16" rx="2.5" fill="#fff"/>')


def e_paper(a):
    lines = ''.join(f'<rect x="{x}" y="{y}" width="{w}" height="4" rx="2" fill="#B8C4D4"/>' for x, y, w in ((52, 46, 26), (52, 54, 26), (52, 62, 18), (22, 74, 56), (22, 82, 40)))
    return (f'<rect x="12" y="14" width="76" height="80" rx="8" fill="{a.lin("#FFFFFF", "#E8EEF6")}"/><rect x="22" y="24" width="56" height="12" rx="3" fill="#34495E"/>'
            f'<rect x="22" y="44" width="24" height="22" rx="3" fill="{a.lin("#7CC4FF", "#1E88E5")}"/><path d="M22 62 L30 54 L38 60 L46 52 V63 Q46 66 43 66 H25 Q22 66 22 63 Z" fill="#22A861"/>{lines}')


def e_drop(a):
    return (f'<path d="M50 6 C70 32 82 46 82 62 A32 32 0 0 1 18 62 C18 46 30 32 50 6 Z" fill="{a.lin("#9BE4FF", "#29B6F6", "#0277BD")}"/>'
            f'<path d="M36 46 C30 54 28 60 30 68" fill="none" stroke="#fff" stroke-opacity=".75" stroke-width="6" stroke-linecap="round"/>{sparkle(80, 22, 8)}')


def e_broom(a):
    bristles = ''.join(f'<path d="M{x} 58 L{x - 3 + i} 90" stroke="#C9792B" stroke-width="2"/>' for i, x in enumerate(range(32, 70, 6)))
    return (f'<g transform="rotate(18 50 50)"><rect x="46" y="4" width="8" height="48" rx="4" fill="{a.lin("#C99A6B", "#8A5A2B", x2=1, y2=0)}"/><path d="M30 56 H70 L78 92 H22 Z" fill="{a.lin("#FFE58A", "#F5B32F")}"/>{bristles}'
            f'<rect x="28" y="48" width="44" height="12" rx="4" fill="{a.lin("#FF7A7A", "#C2152F")}"/></g>{sparkle(18, 24, 7)}{sparkle(84, 70, 5)}')


def e_chef(a):
    return (f'<path d="M26 54 C6 50 8 22 30 24 C34 4 66 4 70 24 C92 22 94 50 74 54 V72 H26 Z" fill="{a.lin("#FFFFFF", "#E3EAF3")}" stroke="#B8C4D4" stroke-width="2"/>'
            f'<path d="M38 36 V56 M50 32 V56 M62 36 V56" stroke="#B8C4D4" stroke-width="3" stroke-linecap="round"/><rect x="24" y="68" width="52" height="18" rx="6" fill="{a.lin("#FFFFFF", "#CBD5E1")}" stroke="#B8C4D4" stroke-width="2"/>')


def e_wheel(a):
    return (f'<circle cx="50" cy="50" r="38" fill="none" stroke="{a.lin("#5A6474", "#20242C")}" stroke-width="12"/><path d="M14 46 H38 M62 46 H86 M50 62 V86" stroke="#3A414D" stroke-width="9" stroke-linecap="round"/>'
            f'<circle cx="50" cy="50" r="13" fill="{a.lin("#FF7A7A", "#C2152F")}"/><path d="M24 26 A36 36 0 0 1 50 14" fill="none" stroke="#fff" stroke-opacity=".5" stroke-width="4" stroke-linecap="round"/>')


def e_bill(a):
    lines = ''.join(f'<rect x="32" y="{y}" width="{w}" height="5" rx="2.5" fill="#C9D3E0"/>' for y, w in ((26, 36), (38, 24), (50, 30)))
    return f'<path d="M22 10 H78 V90 L70 83 L62 90 L54 83 L46 90 L38 83 L30 90 L22 83 Z" fill="{a.lin("#FFFFFF", "#E8EEF6")}"/>{lines}<rect x="32" y="64" width="36" height="9" rx="4.5" fill="{a.lin("#5EE08A", "#22A861")}"/>'


def e_shop(a):
    awning = ''.join(f'<path d="M{12 + i * 15.2:.1f} 22 h15.2 v20 a7.6 7.6 0 0 1 -15.2 0 Z" fill="{"#E8203F" if i % 2 == 0 else "#FFFFFF"}"/>' for i in range(5))
    return (f'<rect x="16" y="40" width="68" height="50" rx="5" fill="{a.lin("#FFF3E0", "#F3D9B5")}"/><rect x="26" y="56" width="20" height="34" rx="3" fill="{a.lin("#B07A4A", "#7A4A1E")}"/>'
            f'<rect x="54" y="56" width="22" height="18" rx="3" fill="{a.lin("#D6EEFF", "#8CCBFF")}"/><rect x="10" y="14" width="80" height="10" rx="4" fill="#8D6E63"/>{awning}')


def e_gold(a):
    bar = lambda x, y: f'<path d="M{x + 8} {y} H{x + 36} L{x + 44} {y + 20} H{x} Z" fill="{a.gold()}" stroke="#B36A00" stroke-width="1.5" stroke-linejoin="round"/><path d="M{x + 10} {y + 3} H{x + 34} L{x + 36} {y + 8} H{x + 8} Z" fill="#fff" opacity=".45"/>'
    return bar(6, 66) + bar(50, 66) + bar(28, 42) + sparkle(78, 26, 10) + sparkle(22, 30, 6)


def e_chart(a):
    bars = ''.join(f'<rect x="{x}" y="{y}" width="16" height="{88 - y}" rx="5" fill="{a.lin(light(c, .35), c)}"/>' for x, y, c in ((14, 56, '#7C4DFF'), (42, 36, '#EC407A'), (70, 18, '#FF9F1C')))
    return f'{bars}<path d="M14 40 L40 22 L58 30 L88 6" fill="none" stroke="#fff" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M76 6 H88 V18" fill="none" stroke="#fff" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>'


def e_bulb(a):
    rays = ''.join(f'<path d="M{50 + 40 * math.cos(math.radians(t)):.1f} {40 + 40 * math.sin(math.radians(t)):.1f} L{50 + 48 * math.cos(math.radians(t)):.1f} {40 + 48 * math.sin(math.radians(t)):.1f}" stroke="#FFE58A" stroke-width="4" stroke-linecap="round"/>' for t in (200, 235, 270, 305, 340))
    return (f'{rays}<path d="M50 8 A30 30 0 0 1 68 62 V70 H32 V62 A30 30 0 0 1 50 8 Z" fill="{a.rad("#FFFBD6", "#FFD23F", "#F5A300")}"/><rect x="34" y="70" width="32" height="8" rx="3" fill="#8892A0"/><rect x="38" y="80" width="24" height="7" rx="3" fill="#6B7482"/>'
            f'<path d="M42 62 V48 L50 40 L58 48 V62" fill="none" stroke="#C97A00" stroke-width="3" stroke-linejoin="round"/><path d="M36 26 A18 18 0 0 1 48 16" fill="none" stroke="#fff" stroke-opacity=".8" stroke-width="4" stroke-linecap="round"/>')


def e_bell(a):
    return (f'<circle cx="50" cy="86" r="8" fill="#C97A00"/><path d="M50 10 C70 10 76 28 76 46 C76 62 84 68 88 76 H12 C16 68 24 62 24 46 C24 28 30 10 50 10 Z" fill="{a.gold()}"/><rect x="10" y="72" width="80" height="9" rx="4.5" fill="{a.lin("#FFC83D", "#C97A00")}"/>'
            f'<path d="M36 24 C32 32 31 40 31 50" fill="none" stroke="#fff" stroke-opacity=".7" stroke-width="5" stroke-linecap="round"/><circle cx="78" cy="22" r="11" fill="#E8203F" stroke="#fff" stroke-width="3"/>')


def e_lock(a):
    return (f'<path d="M30 46 V32 A20 20 0 0 1 70 32 V46" fill="none" stroke="{a.steel()}" stroke-width="10" stroke-linecap="round"/><rect x="18" y="44" width="64" height="48" rx="12" fill="{a.gold()}"/>'
            f'<circle cx="50" cy="64" r="7" fill="#7A4A00"/><rect x="47" y="66" width="6" height="14" rx="3" fill="#7A4A00"/><rect x="24" y="50" width="52" height="8" rx="4" fill="#fff" opacity=".35"/>')


# ---------------------------------------------------------------------------------------------------------------------

METALS = {
    'bronze': ('#FFE0C2', '#E8A26A', '#B8693A', '#7A3F1D'),
    'silver': ('#FFFFFF', '#DCE3EC', '#A9B4C2', '#6B7482'),
    'gold': ('#FFF6C2', '#FFD23F', '#F5A300', '#B36A00'),
}


def outline(shape, cx, cy, r):
    if shape == 'round':
        return f'<circle cx="{cx}" cy="{cy}" r="{r}"'
    if shape == 'shield':
        return f'<path d="M{cx - r} {cy - r * .86} Q{cx} {cy - r * 1.12} {cx + r} {cy - r * .86} V{cy + r * .12} Q{cx + r} {cy + r * .82} {cx} {cy + r * 1.1} Q{cx - r} {cy + r * .82} {cx - r} {cy + r * .12} Z"'
    count, depth, turn = (6, 1.0, -math.pi / 2) if shape == 'hex' else (32, .9, 0)
    pts = []
    for k in range(count):
        rr = r * (1.06 if shape == 'hex' or k % 2 == 0 else depth)
        ang = 2 * math.pi * k / count + turn
        pts.append(f'{cx + rr * math.cos(ang):.1f},{cy + rr * math.sin(ang):.1f}')
    return f'<polygon points="{" ".join(pts)}" stroke-linejoin="round"'


def medal(emblem, colour, shape, metal, stars):
    """A 200 x 236 medal: two ribbon tails, a bevelled metal body, an enamel disc and the emblem."""
    a = Art()
    hi, mid, low, edge = METALS[metal]
    cx, cy, r = 100, 96, 78
    rim = a.lin(hi, mid, low, edge, x2=.6)
    rim_back = a.lin(edge, low, mid, hi, x2=.6)
    enamel = a.rad(light(colour, .45), colour, dark(colour, .45), cx=.4, cy=.3, r=.85)
    tail = a.lin(light(colour, .15), colour, dark(colour, .35))
    tail_dark = a.lin(colour, dark(colour, .5))
    rays = ''.join(f'<path d="M{cx} {cy} L{cx + 60 * math.cos(math.radians(t)):.1f} {cy + 60 * math.sin(math.radians(t)):.1f} A60 60 0 0 1 {cx + 60 * math.cos(math.radians(t + 15)):.1f} {cy + 60 * math.sin(math.radians(t + 15)):.1f} Z" fill="#fff" opacity=".1"/>' for t in range(0, 360, 30))
    dots = ''.join(f'<circle cx="{cx + 65 * math.cos(math.radians(t)):.1f}" cy="{cy + 65 * math.sin(math.radians(t)):.1f}" r="1.8" fill="{hi}" opacity=".9"/>' for t in range(0, 360, 15))
    rank = ''.join(star(cx + (k - (stars - 1) / 2) * 17, 176, 7.5, hi, extra=f'stroke="{edge}" stroke-width="1"') for k in range(stars))
    body = (
        f'<path d="M58 132 L34 226 L62 210 L80 232 L104 150 Z" fill="{tail_dark}"/><path d="M142 132 L166 226 L138 210 L120 232 L96 150 Z" fill="{tail}"/>'
        f'<path d="M132 150 L152 214 L160 218 L138 140 Z" fill="#fff" opacity=".22"/>'
        f'<ellipse cx="{cx}" cy="{cy + 8}" rx="{r}" ry="{r}" fill="#000" opacity=".18" filter="url(#sh)"/>'
        f'{outline(shape, cx, cy, r)} fill="{rim}" stroke="{edge}" stroke-width="2.5"/>'
        f'{outline(shape, cx, cy, r * .9)} fill="{rim_back}"/>'
        f'{outline(shape, cx, cy, r * .86)} fill="{rim}"/>'
        f'<circle cx="{cx}" cy="{cy}" r="60" fill="{enamel}" stroke="{edge}" stroke-width="2.5"/>{rays}{dots}'
        f'<circle cx="{cx}" cy="{cy}" r="56" fill="none" stroke="#000" stroke-opacity=".16" stroke-width="5"/>'
        f'<g transform="translate({cx - 39} {cy - 41}) scale(.78)" filter="url(#sh)">{emblem(a)}</g>'
        f'<path d="M{cx - 54} {cy - 20} A56 56 0 0 1 {cx + 54} {cy - 20} A74 60 0 0 0 {cx - 54} {cy - 20} Z" fill="#fff" opacity=".22"/>'
        f'<path d="M62 160 Q100 178 138 160 L134 184 Q100 198 66 184 Z" fill="{rim}" stroke="{edge}" stroke-width="2"/>{rank}'
        f'{sparkle(158, 38, 11)}{sparkle(40, 52, 7, "#fff", .9)}'
    )
    return a.svg(200, 236, body)


def sticker(emblem, colour):
    """A 160 x 160 glossy tile with an illustrated object sitting on it."""
    a = Art()
    tile = a.lin(light(colour, .38), colour, dark(colour, .3), x2=.7)
    body = (
        f'<rect x="12" y="16" width="136" height="136" rx="42" fill="{dark(colour, .45)}" opacity=".35"/>'
        f'<rect x="12" y="8" width="136" height="136" rx="42" fill="{tile}"/>'
        f'<path d="M54 8 H106 Q148 8 148 50 V60 Q96 30 12 66 V50 Q12 8 54 8 Z" fill="#fff" opacity=".2"/>'
        f'<circle cx="126" cy="122" r="46" fill="#fff" opacity=".08"/>'
        f'<g transform="translate(30 24) scale(1)" filter="url(#sh)">{emblem(a)}</g>'
    )
    return a.svg(160, 160, body)


BADGES = {
    'badge_first_step': (e_flag, '#22A861', 'round'), 'badge_ten_logged': (e_receipt, '#039BE5', 'round'), 'badge_century': (e_hundred, '#7C4DFF', 'round'),
    'badge_half_k': (e_rocket, '#3949AB', 'round'), 'badge_week_warrior': (e_flame, '#5D2A8C', 'burst'), 'badge_month_master': (e_trophy, '#C2152F', 'burst'),
    'badge_streak_60': (e_bolt, '#7C4DFF', 'burst'), 'badge_streak_100': (e_flame_star, '#1F2A5C', 'burst'), 'badge_early_bird': (e_sunrise, '#4FC3F7', 'hex'),
    'badge_night_owl': (e_moon, '#283593', 'hex'), 'badge_voice': (e_mic, '#EC407A', 'hex'), 'badge_notes': (e_notes, '#00897B', 'hex'),
    'badge_explorer': (e_compass, '#0277BD', 'hex'), 'badge_custom_cat': (e_tag, '#FFB300', 'hex'), 'badge_payment_pro': (e_card, '#5E35B1', 'hex'),
    'badge_big_spender': (e_diamond, '#AD1457', 'hex'), 'badge_penny': (e_coins, '#2E7D32', 'hex'), 'badge_team_player': (e_two, '#FFC83D', 'shield'),
    'badge_group_guru': (e_three, '#FF8A3D', 'shield'), 'badge_fair_share': (e_scale, '#22A861', 'shield'), 'badge_settler': (e_bank, '#00695C', 'shield'),
    'badge_family_first': (e_home_heart, '#FF9F1C', 'shield'), 'badge_full_house': (e_home_star, '#7C4DFF', 'shield'), 'badge_bill_planner': (e_calendar, '#FF7A1A', 'shield'),
    'badge_budget_boss': (e_target, '#22A861', 'burst'), 'badge_budget_hattrick': (e_target3, '#1F2A5C', 'burst'), 'badge_stylist': (e_shirt, '#7E57C2', 'round'),
    'badge_accessorized': (e_shades, '#FFC83D', 'round'), 'badge_new_look': (e_palette, '#00ACC1', 'round'), 'badge_collector': (e_gift, '#3949AB', 'round'),
    'badge_polyglot': (e_speech, '#FFC83D', 'hex'), 'badge_level_5': (e_star, '#C2152F', 'burst'), 'badge_level_10': (e_crown, '#5D2A8C', 'burst'),
}
# Bonus points decide the metal and the number of rank stars.
BONUS = {'badge_first_step': 20, 'badge_ten_logged': 40, 'badge_century': 150, 'badge_half_k': 500, 'badge_week_warrior': 60, 'badge_month_master': 250, 'badge_streak_60': 400, 'badge_streak_100': 1000,
         'badge_early_bird': 30, 'badge_night_owl': 30, 'badge_voice': 40, 'badge_notes': 60, 'badge_explorer': 60, 'badge_custom_cat': 50, 'badge_payment_pro': 80, 'badge_big_spender': 100, 'badge_penny': 80,
         'badge_team_player': 30, 'badge_group_guru': 100, 'badge_fair_share': 40, 'badge_settler': 300, 'badge_family_first': 50, 'badge_full_house': 150, 'badge_bill_planner': 100, 'badge_budget_boss': 200,
         'badge_budget_hattrick': 600, 'badge_stylist': 30, 'badge_accessorized': 120, 'badge_new_look': 50, 'badge_collector': 80, 'badge_polyglot': 30, 'badge_level_5': 300, 'badge_level_10': 1000}

ICONS = {
    'group_home': (e_home, '#7C4DFF'), 'group_trip': (e_plane, '#039BE5'), 'group_party': (e_party, '#FFC83D'), 'group_food': (e_pizza, '#FF7A1A'), 'group_beach': (e_beach, '#26C6DA'),
    'group_shop': (e_bag, '#FF8FA3'), 'group_ride': (e_car, '#5C6BC0'), 'group_study': (e_cap, '#FFB300'),
    'svc_milk': (e_milk, '#7CC4FF'), 'svc_paper': (e_paper, '#8892A0'), 'svc_water': (e_drop, '#B3E5FC'), 'svc_maid': (e_broom, '#26A69A'), 'svc_cook': (e_chef, '#FF7A1A'),
    'svc_driver': (e_wheel, '#FFC83D'), 'svc_other': (e_bill, '#7E57C2'),
    'shop': (e_shop, '#4DB6AC'), 'gold': (e_gold, '#5D2A8C'), 'forecast': (e_chart, '#1F2A5C'), 'idea': (e_bulb, '#3949AB'), 'bell': (e_bell, '#FF7A1A'), 'lock': (e_lock, '#5C6BC0'),
    'receipt': (e_bill, '#22A861'), 'friends': (e_two, '#26C6DA'), 'trophy': (e_trophy, '#E8203F'),
}


# Website feature cards, by feature key.
WEB = {
    'log': (e_bolt, '#3949AB'), 'voice': (e_mic, '#EC407A'), 'budgets': (e_target, '#22A861'), 'groups': (e_three, '#FFC83D'), 'family': (e_home_heart, '#7C4DFF'), 'insights': (e_chart, '#1F2A5C'),
    'khata': (e_shop, '#4DB6AC'), 'reminders': (e_bell, '#FF7A1A'), 'rewards': (e_trophy, '#E8203F'), 'avatar': (e_shades, '#FFC83D'), 'sounds': (e_party, '#26C6DA'), 'data': (e_lock, '#5C6BC0'),
    'share': (e_gift, '#3949AB'), 'categories': (e_tag, '#FFB300'), 'languages': (e_speech, '#26A69A'),
}


def tier(bonus): return ('bronze', 1) if bonus < 60 else ('silver', 2) if bonus < 200 else ('gold', 3)


def render(svg, path, width):
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile('w', suffix='.svg', delete=False) as f:
        f.write(svg)
    subprocess.run(['rsvg-convert', '-w', str(width), f.name, '-o', str(path)], check=True)
    pathlib.Path(f.name).unlink()


if __name__ == '__main__':
    for key, (emblem, colour, shape) in BADGES.items():
        render(medal(emblem, colour, shape, *tier(BONUS[key])), OUT / 'badges' / f'{key}.png', 300)
    for key, (emblem, colour) in ICONS.items():
        render(sticker(emblem, colour), OUT / 'icons' / f'{key}.png', 240)
    site = ROOT / 'website' / 'public' / 'art'
    for key, (emblem, colour, shape) in BADGES.items():
        render(medal(emblem, colour, shape, *tier(BONUS[key])), site / f'{key}.png', 140)
    for key, (emblem, colour) in WEB.items():
        render(sticker(emblem, colour), site / f'feature_{key}.png', 144)
    print(f'{len(BADGES)} badges, {len(ICONS)} icons, {len(WEB)} website icons')
