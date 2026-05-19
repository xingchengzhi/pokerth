#!/usr/bin/env python3
import os
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

SUITS = [
    ("d", "#E30613"),
    ("h", "#E30613"),
    ("s", "#000000"),
    ("c", "#000000"),
]
RANKS = ["2","3","4","5","6","7","8","9","10","J","Q","K","A"]

SUIT_PATHS = {
    "d": "M0,-10 L9,0 L0,10 L-9,0 Z",
    "h": "M0,9 C-3,6 -10,1 -10,-4 C-10,-9 -6,-12 -2,-12 C-1,-12 0,-11 0,-10 C0,-11 1,-12 2,-12 C6,-12 10,-9 10,-4 C10,1 3,6 0,9 Z",
    "s": "M0,-12 C3,-15 10,-10 10,-5 C10,-1 7,3 2,5 C3,5 4,6 5,8 L-5,8 C-4,6 -3,5 -2,5 C-7,3 -10,-1 -10,-5 C-10,-10 -3,-15 0,-12 Z",
    "c": "M-5.5,1 A4,4 0 1,1 -5.5,-7 A4,4 0 1,1 -5.5,1 Z M5.5,1 A4,4 0 1,1 5.5,-7 A4,4 0 1,1 5.5,1 Z M0,7 A4,4 0 1,1 0,-1 A4,4 0 1,1 0,7 Z M-2.5,7 L2.5,7 L2.5,11 L-2.5,11 Z",
}

def char_to_path(font, char, height):
    cmap = font.getBestCmap()
    cp = ord(char)
    if cp not in cmap:
        return "", 0.0
    name = cmap[cp]
    em = font["head"].unitsPerEm
    asc = font["hhea"].ascender
    sc = height / em
    gset = font.getGlyphSet()
    pen = SVGPathPen(gset)
    tpen = TransformPen(pen, (sc, 0, 0, -sc, 0, asc * sc))
    gset[name].draw(tpen)
    d = pen.getCommands()
    adv = font["hmtx"].metrics[name][0] * sc
    return d, adv

def rank_paths(font, rank, x, y, color, size):
    out, cx = "", x
    for ch in rank:
        d, adv = char_to_path(font, ch, size)
        if d:
            out += f'  <path fill="{color}" transform="translate({cx:.3f},{y:.3f})" d="{d}"/>\n'
            cx += adv + 0.4
    return out

def suit_path(key, cx, cy, size, color):
    raw = SUIT_PATHS[key]
    sc = size / 22.0
    return f'  <path fill="{color}" transform="translate({cx:.3f},{cy:.3f}) scale({sc:.4f})" d="{raw}"/>\n'

def make_card(idx, font):
    si, ri = idx // 13, idx % 13
    skey, color = SUITS[si]
    rank = RANKS[ri]
    RH, SS, CS = 10.0, 10.0, 36.0
    MX, RY = 5.0, 2.5
    r = rank_paths(font, rank, MX, RY, color, RH)
    s = suit_path(skey, MX + SS*0.5, RY + RH + 2.0 + SS*0.5, SS, color)
    c = suit_path(skey, 36.0, 54.0, CS, color)
    svg  = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 72 108">\n'
    svg += '  <rect fill="white" stroke="#555" stroke-width="0.5" x="1" y="1" width="70" height="106" rx="3" ry="3"/>\n'
    svg += r + s + c
    svg += '  <g transform="translate(72,108) rotate(180)">\n' + r + s + '  </g>\n'
    svg += '</svg>\n'
    return svg

if __name__ == "__main__":
    sd = os.path.dirname(os.path.abspath(__file__))
    fp = os.path.join(sd, "..", "Rubik-VariableFont_wght.ttf")
    if not os.path.exists(fp):
        print(f"ERROR: {fp}"); exit(1)
    font = TTFont(fp)
    print(f"Rubik loaded, em={font['head'].unitsPerEm}")
    for i in range(52):
        with open(os.path.join(sd, f"{i}.svg"), "w") as f:
            f.write(make_card(i, font))
    print("ok 52 SVGs - no text elements")
