#!/usr/bin/env python3
"""Generate playing card SVGs for PokerTH QML (4-colour deck)."""

import os

OUTPUT_DIR = "src/gui/qt6-qml/resources/cards"

SUITS = [
    ("diamonds", "#1155CC"),   # 0-12
    ("hearts",   "#CC1111"),   # 13-25
    ("spades",   "#1A1A1A"),   # 26-38
    ("clubs",    "#007700"),   # 39-51
]

RANKS = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]

# Suit paths centered at origin, radius ≈ 8 units
SUIT_PATHS = {
    "diamonds": "M 0,-8 L 6.5,0 L 0,8 L -6.5,0 Z",
    "hearts":   ("M 0,7.5 C -1.5,6 -7.5,2.5 -7.5,-1.5 "
                 "C -7.5,-5.5 -4,-8.5 0,-5.5 "
                 "C 4,-8.5 7.5,-5.5 7.5,-1.5 "
                 "C 7.5,2.5 1.5,6 0,7.5 Z"),
    "spades":   ("M 0,-9 C 0,-4 -7.5,-2 -7.5,2.5 "
                 "C -7.5,6.5 -3.5,7.5 -1,5.5 "
                 "C -2,7.5 -3.5,10 -6,10.5 L 6,10.5 "
                 "C 3.5,10 2,7.5 1,5.5 "
                 "C 3.5,7.5 7.5,6.5 7.5,2.5 "
                 "C 7.5,-2 0,-4 0,-9 Z"),
    "clubs":    ("M 0,10 C -1.5,8 -4,7 -6,7 "
                 "C -10,7 -10,2 -6.5,0.5 "
                 "C -11,-0.5 -11,-8 -5,-8 "
                 "C -2.5,-8 -1,-6 0,-4.5 "
                 "C 1,-6 2.5,-8 5,-8 "
                 "C 11,-8 11,-0.5 6.5,0.5 "
                 "C 10,2 10,7 6,7 "
                 "C 4,7 1.5,8 0,10 Z"),
}


def pip(suit, cx, cy, scale, color, rotate=False):
    p = SUIT_PATHS[suit]
    rot = " rotate(180)" if rotate else ""
    return f'  <path fill="{color}" d="{p}" transform="translate({cx},{cy}) scale({scale}){rot}"/>\n'


# Pip layouts: (cx, cy, rotate_180)
# Card usable area: x 12-60, y 28-82
PIP_LAYOUTS = {
    "2":  [(36, 34, False), (36, 74, True)],
    "3":  [(36, 34, False), (36, 54, False), (36, 74, True)],
    "4":  [(23, 34, False), (49, 34, False),
           (23, 74, True),  (49, 74, True)],
    "5":  [(23, 34, False), (49, 34, False), (36, 54, False),
           (23, 74, True),  (49, 74, True)],
    "6":  [(23, 34, False), (49, 34, False),
           (23, 54, False), (49, 54, False),
           (23, 74, True),  (49, 74, True)],
    "7":  [(23, 34, False), (49, 34, False), (36, 43, False),
           (23, 54, False), (49, 54, False),
           (23, 74, True),  (49, 74, True)],
    "8":  [(23, 34, False), (49, 34, False), (36, 43, False),
           (23, 54, False), (49, 54, False),
           (36, 65, True),
           (23, 74, True),  (49, 74, True)],
    "9":  [(23, 34, False), (49, 34, False),
           (23, 44, False), (49, 44, False), (36, 54, False),
           (23, 64, True),  (49, 64, True),
           (23, 74, True),  (49, 74, True)],
    "10": [(23, 34, False), (49, 34, False), (36, 41, False),
           (23, 48, False), (49, 48, False),
           (23, 60, True),  (49, 60, True),
           (36, 67, True),
           (23, 74, True),  (49, 74, True)],
}


def corner_block(suit, rank, color):
    fs = 9 if rank == "10" else 11
    s = ""
    s += f'  <text x="4.5" y="13" font-family="Arial,Helvetica,sans-serif" font-size="{fs}" font-weight="bold" fill="{color}">{rank}</text>\n'
    s += pip(suit, 6.5, 22.5, 0.43, color)
    return s


def generate_svg(suit_name, rank, color):
    out = []
    out.append('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 72 108">')
    # Card background
    out.append('  <rect fill="white" stroke="#cccccc" stroke-width="0.5" '
               'x="0.5" y="0.5" width="71" height="107" rx="4"/>')

    # Top-left corner
    out.append(corner_block(suit_name, rank, color))

    # Bottom-right corner (rotated 180°)
    out.append('  <g transform="translate(72,108) rotate(180)">')
    out.append(corner_block(suit_name, rank, color))
    out.append('  </g>')

    # Center content
    if rank in PIP_LAYOUTS:
        for cx, cy, rot in PIP_LAYOUTS[rank]:
            out.append(pip(suit_name, cx, cy, 0.43, color, rot))
    elif rank == "A":
        out.append(pip(suit_name, 36, 56, 1.7, color))
    else:
        # Face card (J, Q, K): decorative inner frame + big letter + suit
        out.append(f'  <rect fill="none" stroke="{color}" stroke-width="0.6" '
                   f'x="4.5" y="4.5" width="63" height="99" rx="3" opacity="0.35"/>')
        out.append(f'  <text x="36" y="57" '
                   f'font-family="Arial,Helvetica,sans-serif" '
                   f'font-size="34" font-weight="bold" fill="{color}" '
                   f'text-anchor="middle" dominant-baseline="middle">{rank}</text>')
        out.append(pip(suit_name, 36, 82, 0.72, color))

    out.append('</svg>')
    return '\n'.join(out)


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    for suit_idx, (suit_name, color) in enumerate(SUITS):
        for rank_idx, rank in enumerate(RANKS):
            card_idx = suit_idx * 13 + rank_idx
            svg = generate_svg(suit_name, rank, color)
            with open(os.path.join(OUTPUT_DIR, f"{card_idx}.svg"), "w") as f:
                f.write(svg)
    print(f"Generated 52 SVGs → {OUTPUT_DIR}/")


if __name__ == "__main__":
    main()
