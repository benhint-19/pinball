"""Generate Solana-themed sprites for Seeker Pinball using PIL.

Tasks 4-8 and 10:
  4. Loading screen (618x270)
  5. Backbox marquee (2129x1765)
  6. SEEKER letter sprites (47x44 x 12)
  7. Boundary text + signpost sprites
  8. Board background (1019x1440)
 10. Animatronic sprite sheets + character backgrounds
"""

import math
import os
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
COMP_ASSETS = os.path.join(ROOT, "packages", "pinball_components", "assets", "images")
THEME_ASSETS = os.path.join(ROOT, "packages", "pinball_theme", "assets", "images")

# Solana colors
PURPLE = (153, 69, 255)
TEAL = (20, 241, 149)
CYAN = (0, 209, 255)
DARK_PURPLE = (30, 10, 60)
MID_PURPLE = (80, 30, 140)
DEEP_BG = (18, 6, 42)
WHITE = (255, 255, 255)


def lerp(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(min(len(c1), len(c2))))


def save(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print(f"  -> {os.path.relpath(path, ROOT)}")


# ── 5x7 pixel font ──────────────────────────────────────────────────
FONT = {
    'A': ["01110","10001","10001","11111","10001","10001","10001"],
    'B': ["11110","10001","10001","11110","10001","10001","11110"],
    'C': ["01110","10001","10000","10000","10000","10001","01110"],
    'D': ["11110","10001","10001","10001","10001","10001","11110"],
    'E': ["11111","10000","10000","11110","10000","10000","11111"],
    'F': ["11111","10000","10000","11110","10000","10000","10000"],
    'G': ["01110","10001","10000","10111","10001","10001","01110"],
    'H': ["10001","10001","10001","11111","10001","10001","10001"],
    'I': ["11111","00100","00100","00100","00100","00100","11111"],
    'J': ["00111","00010","00010","00010","00010","10010","01100"],
    'K': ["10001","10010","10100","11000","10100","10010","10001"],
    'L': ["10000","10000","10000","10000","10000","10000","11111"],
    'M': ["10001","11011","10101","10101","10001","10001","10001"],
    'N': ["10001","11001","10101","10011","10001","10001","10001"],
    'O': ["01110","10001","10001","10001","10001","10001","01110"],
    'P': ["11110","10001","10001","11110","10000","10000","10000"],
    'R': ["11110","10001","10001","11110","10100","10010","10001"],
    'S': ["01110","10001","10000","01110","00001","10001","01110"],
    'T': ["11111","00100","00100","00100","00100","00100","00100"],
    'U': ["10001","10001","10001","10001","10001","10001","01110"],
    'W': ["10001","10001","10001","10101","10101","11011","10001"],
    'Y': ["10001","10001","01010","00100","00100","00100","00100"],
    ' ': ["00000","00000","00000","00000","00000","00000","00000"],
    '0': ["01110","10001","10011","10101","11001","10001","01110"],
    '1': ["00100","01100","00100","00100","00100","00100","11111"],
    '2': ["01110","10001","00001","00110","01000","10000","11111"],
    '3': ["01110","10001","00001","00110","00001","10001","01110"],
}


def draw_text(draw, text, x0, y0, scale, color):
    """Draw pixel font text onto an ImageDraw."""
    cx = x0
    for ch in text.upper():
        glyph = FONT.get(ch, FONT[' '])
        for gy, row in enumerate(glyph):
            for gx, bit in enumerate(row):
                if bit == '1':
                    px = cx + gx * scale
                    py = y0 + gy * scale
                    draw.rectangle([px, py, px + scale - 1, py + scale - 1], fill=color)
        cx += 6 * scale


def text_width(text, scale):
    return len(text) * 6 * scale - scale


def draw_solana_logo(draw, cx, cy, size):
    """Draw simplified Solana logo - three horizontal bars with arrow tips."""
    bar_h = max(size // 6, 3)
    bar_w = size
    skew = size // 4
    colors = [PURPLE, lerp(PURPLE, TEAL, 0.5), TEAL]
    offsets = [-size // 3, 0, size // 3]

    for i, (off_y, color) in enumerate(zip(offsets, colors)):
        by = cy + off_y
        # Draw parallelogram as polygon
        if i == 0:  # Top bar: left-leaning, right arrow
            pts = [(cx - bar_w//2 + skew, by),
                   (cx + bar_w//2 + skew, by),
                   (cx + bar_w//2, by + bar_h),
                   (cx - bar_w//2, by + bar_h)]
        elif i == 2:  # Bottom bar: right-leaning, left arrow
            pts = [(cx - bar_w//2, by),
                   (cx + bar_w//2, by),
                   (cx + bar_w//2 - skew, by + bar_h),
                   (cx - bar_w//2 - skew, by + bar_h)]
        else:  # Middle bar
            pts = [(cx - bar_w//2, by),
                   (cx + bar_w//2 + skew//2, by),
                   (cx + bar_w//2, by + bar_h),
                   (cx - bar_w//2 - skew//2, by + bar_h)]
        draw.polygon(pts, fill=color)


# ═══════════════════════════════════════════════════════════════════════
# TASK 4: Loading Screen (618x270)
# ═══════════════════════════════════════════════════════════════════════
def task4():
    print("\n[Task 4] Loading screen...")
    W, H = 618, 270
    img = Image.new("RGBA", (W, H), DEEP_BG + (255,))
    draw = ImageDraw.Draw(img)

    # Gradient background
    for y in range(H):
        t = y / H
        c = lerp(DARK_PURPLE, DEEP_BG, t)
        draw.line([(0, y), (W, y)], fill=c + (255,))

    # Central glow
    for r in range(200, 0, -2):
        alpha = int(30 * (1 - r / 200))
        c = PURPLE + (alpha,)
        draw.ellipse([W//2 - r, H//3 - r//2, W//2 + r, H//3 + r//2], fill=c)

    # Solana logo
    draw_solana_logo(draw, W // 2, 75, 100)

    # "SEEKER PINBALL" title
    text = "SEEKER PINBALL"
    s = 5
    tw = text_width(text, s)
    tx = (W - tw) // 2
    draw_text(draw, text, tx + 2, 162, s, (20, 5, 40, 255))
    draw_text(draw, text, tx, 160, s, TEAL + (255,))

    # Subtitle
    sub = "POWERED BY SOLANA"
    ss = 2
    stw = text_width(sub, ss)
    draw_text(draw, sub, (W - stw) // 2, 218, ss, PURPLE + (180,))

    # Decorative dots
    for i in range(30):
        dx = int(W * 0.08 + (W * 0.84) * (i / 29))
        draw.rectangle([dx, 248, dx + 1, 249], fill=TEAL + (120,))

    save(img, os.path.join(ROOT, "assets", "images", "loading_game", "io_pinball.png"))


# ═══════════════════════════════════════════════════════════════════════
# TASK 5: Backbox Marquee (2129x1765)
# ═══════════════════════════════════════════════════════════════════════
def task5():
    print("\n[Task 5] Backbox marquee...")
    W, H = 2129, 1765
    img = Image.new("RGBA", (W, H), DEEP_BG + (255,))
    draw = ImageDraw.Draw(img)

    # Gradient background
    for y in range(H):
        t = y / H
        c = lerp(DARK_PURPLE, (10, 20, 35), t)
        draw.line([(0, y), (W, y)], fill=c + (255,))

    # Central glow
    for r in range(600, 0, -4):
        alpha = int(20 * (1 - r / 600))
        draw.ellipse([W//2 - r, H//3 - r, W//2 + r, H//3 + r], fill=PURPLE + (alpha,))

    # Solana logo (large)
    draw_solana_logo(draw, W // 2, H // 3, 350)

    # Ring decorations
    for ring_r in [480, 530]:
        draw.ellipse([W//2 - ring_r, H//3 - ring_r, W//2 + ring_r, H//3 + ring_r],
                     outline=PURPLE + (60,), width=4)

    # "SEEKER PINBALL" title
    text = "SEEKER PINBALL"
    s = 18
    tw = text_width(text, s)
    tx = (W - tw) // 2
    draw_text(draw, text, tx + 4, H//2 + 104, s, (20, 5, 40, 255))
    draw_text(draw, text, tx, H//2 + 100, s, TEAL + (255,))

    # Corner diamonds
    diamond_size = 50
    for cx, cy in [(180, 180), (W-180, 180), (180, H-180), (W-180, H-180)]:
        pts = [(cx, cy - diamond_size), (cx + diamond_size, cy),
               (cx, cy + diamond_size), (cx - diamond_size, cy)]
        draw.polygon(pts, fill=PURPLE + (120,))

    # Stars along top
    for i in range(9):
        sx = int(W * 0.12 + (W * 0.76) * (i / 8))
        sz = 20
        draw.polygon([(sx, 120-sz), (sx+sz//3, 120-sz//3), (sx+sz, 120),
                       (sx+sz//3, 120+sz//3), (sx, 120+sz), (sx-sz//3, 120+sz//3),
                       (sx-sz, 120), (sx-sz//3, 120-sz//3)], fill=TEAL + (100,))

    # Bottom accent line
    for x in range(W//4, 3*W//4):
        t = (x - W//4) / (W//2)
        c = lerp(PURPLE, TEAL, t)
        draw.rectangle([x, H-90, x, H-86], fill=c + (200,))

    # "POWERED BY SOLANA"
    sub = "POWERED BY SOLANA"
    ss = 7
    stw = text_width(sub, ss)
    draw_text(draw, sub, (W - stw) // 2, H - 220, ss, PURPLE + (180,))

    save(img, os.path.join(COMP_ASSETS, "backbox", "marquee.png"))


# ═══════════════════════════════════════════════════════════════════════
# TASK 6: SEEKER Letters (47x44 x 12)
# ═══════════════════════════════════════════════════════════════════════
def task6():
    print("\n[Task 6] SEEKER letters...")
    letters = "SEEKER"
    W, H = 47, 44
    cx, cy = W // 2, H // 2
    r = min(W, H) // 2 - 2

    for i, letter in enumerate(letters):
        for mode in ("lit", "dimmed"):
            img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            draw = ImageDraw.Draw(img)

            if mode == "lit":
                # Bright circle with glow
                draw.ellipse([cx-r-2, cy-r-2, cx+r+2, cy+r+2], fill=PURPLE + (80,))
                draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=(180, 100, 255, 255))
                # Inner highlight
                draw.ellipse([cx-r+4, cy-r+4, cx+r-4, cy+r-4], fill=(200, 130, 255, 255))
                # Letter
                ls = 3
                lw = 5 * ls
                lh = 7 * ls
                draw_text(draw, letter, cx - lw//2, cy - lh//2, ls, WHITE + (255,))
            else:
                draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=(40, 20, 60, 200))
                ls = 3
                lw = 5 * ls
                lh = 7 * ls
                draw_text(draw, letter, cx - lw//2, cy - lh//2, ls, (80, 50, 100, 180))

            path = os.path.join(COMP_ASSETS, "google_word", f"letter{i+1}", f"{mode}.png")
            save(img, path)


# ═══════════════════════════════════════════════════════════════════════
# TASK 7: Boundaries + Signpost
# ═══════════════════════════════════════════════════════════════════════
def task7():
    print("\n[Task 7] Boundaries & signpost...")

    # ── bottom.png (957x322) ──
    W, H = 957, 322
    img = Image.new("RGBA", (W, H), DARK_PURPLE + (255,))
    draw = ImageDraw.Draw(img)

    for y in range(H):
        c = lerp((35, 15, 55), (20, 8, 35), y / H)
        draw.line([(0, y), (W, y)], fill=c + (255,))

    # Edge lines
    for x in range(W):
        c = lerp(PURPLE, TEAL, x / W)
        draw.rectangle([x, 0, x, 2], fill=c + (200,))
        draw.rectangle([x, H-3, x, H-1], fill=c + (200,))

    # Text
    text = "SEEKER PINBALL"
    s = 6
    tw = text_width(text, s)
    tx, ty = (W - tw) // 2, (H - 7*s) // 2
    draw_text(draw, text, tx + 2, ty + 2, s, (10, 3, 20, 255))
    draw_text(draw, text, tx, ty, s, TEAL + (255,))

    save(img, os.path.join(COMP_ASSETS, "boundary", "bottom.png"))

    # ── outer.png (1189x1600) ──
    W2, H2 = 1189, 1600
    img2 = Image.new("RGBA", (W2, H2), (0, 0, 0, 0))
    draw2 = ImageDraw.Draw(img2)

    # Frame border
    bw = 25
    draw2.rectangle([0, 0, W2-1, H2-1], outline=MID_PURPLE + (255,), width=bw)
    draw2.rectangle([bw, bw, W2-1-bw, H2-1-bw], outline=DARK_PURPLE + (200,), width=3)

    # Sticker area
    sw, sh = 500, 160
    sx, sy = (W2 - sw) // 2, 80
    draw2.rectangle([sx, sy, sx+sw, sy+sh], fill=DARK_PURPLE + (230,), outline=TEAL + (200,), width=2)

    text1 = "SEEKER PINBALL"
    s1 = 4
    tw1 = text_width(text1, s1)
    draw_text(draw2, text1, (W2 - tw1)//2, sy + 25, s1, TEAL + (255,))

    text2 = "RULES"
    tw2 = text_width(text2, s1)
    draw_text(draw2, text2, (W2 - tw2)//2, sy + 80, s1, PURPLE + (255,))

    save(img2, os.path.join(COMP_ASSETS, "boundary", "outer.png"))

    # ── Signpost sprites (106x156) ──
    SW, SH = 106, 156
    names = ["inactive", "active1", "active2", "active3"]

    for idx, name in enumerate(names):
        img_s = Image.new("RGBA", (SW, SH), (0, 0, 0, 0))
        draw_s = ImageDraw.Draw(img_s)

        # Post
        draw_s.rectangle([SW//2 - 5, SH//3, SW//2 + 5, SH - 1], fill=(50, 25, 70, 255))

        # Sign board
        bt, bb = 8, SH//3 + 8
        bl, br = 6, SW - 6
        active = name != "inactive"

        if active:
            brightness = 0.3 + 0.23 * idx
            fill_c = lerp(DARK_PURPLE, PURPLE, brightness)
            border_c = TEAL
        else:
            fill_c = (40, 20, 55)
            border_c = (60, 35, 80)

        draw_s.rectangle([bl, bt, br, bb], fill=fill_c + (240,), outline=border_c + (200,), width=2)

        # Number
        num = str(idx) if idx > 0 else "0"
        ns = 4
        nw = 5 * ns
        text_c = TEAL if active else (70, 45, 90)
        draw_text(draw_s, num, (SW - nw)//2, bt + 8, ns, text_c + (255,))

        save(img_s, os.path.join(COMP_ASSETS, "signpost", f"{name}.png"))


# ═══════════════════════════════════════════════════════════════════════
# TASK 8: Board Background (1019x1440)
# ═══════════════════════════════════════════════════════════════════════
def task8():
    print("\n[Task 8] Board background...")
    W, H = 1019, 1440
    img = Image.new("RGBA", (W, H), DEEP_BG + (180,))
    draw = ImageDraw.Draw(img)

    # Subtle gradient
    for y in range(H):
        t = y / H
        c = lerp((25, 10, 45), DEEP_BG, t)
        draw.line([(0, y), (W, y)], fill=c + (180,))

    # Central glow
    for r in range(400, 0, -5):
        alpha = int(12 * (1 - r / 400))
        draw.ellipse([W//2 - r, H//2 - r, W//2 + r, H//2 + r], fill=PURPLE + (alpha,))

    # Zone emblems (4 quadrants)
    # Top-left: diamond
    diamond_pts = [(W//4, H//4 - 70), (W//4 + 70, H//4),
                   (W//4, H//4 + 70), (W//4 - 70, H//4)]
    draw.polygon(diamond_pts, fill=PURPLE + (50,), outline=PURPLE + (80,))

    # Top-right: star
    sx, sy, sz = 3*W//4, H//4, 60
    star_pts = [(sx, sy-sz), (sx+sz//3, sy-sz//3), (sx+sz, sy), (sx+sz//3, sy+sz//3),
                (sx, sy+sz), (sx-sz//3, sy+sz//3), (sx-sz, sy), (sx-sz//3, sy-sz//3)]
    draw.polygon(star_pts, fill=TEAL + (40,), outline=TEAL + (70,))

    # Bottom-left: ring
    draw.ellipse([W//4-70, 3*H//4-70, W//4+70, 3*H//4+70], outline=CYAN + (60,), width=8)
    draw.ellipse([W//4-45, 3*H//4-45, W//4+45, 3*H//4+45], outline=CYAN + (40,), width=5)

    # Bottom-right: circle
    draw.ellipse([3*W//4-55, 3*H//4-55, 3*W//4+55, 3*H//4+55], fill=PURPLE + (40,))
    draw.ellipse([3*W//4-70, 3*H//4-70, 3*W//4+70, 3*H//4+70], outline=PURPLE + (60,), width=4)

    # Small Solana logo in center
    draw_solana_logo(draw, W // 2, H // 2, 80)

    # Subtle rays
    for angle_deg in range(0, 360, 15):
        angle = math.radians(angle_deg)
        x1 = int(W//2 + 100 * math.cos(angle))
        y1 = int(H//2 + 100 * math.sin(angle))
        x2 = int(W//2 + 450 * math.cos(angle))
        y2 = int(H//2 + 450 * math.sin(angle))
        draw.line([(x1, y1), (x2, y2)], fill=PURPLE + (8,), width=2)

    save(img, os.path.join(COMP_ASSETS, "board_background.png"))


# ═══════════════════════════════════════════════════════════════════════
# TASK 10: Animatronic Sprite Sheets
# ═══════════════════════════════════════════════════════════════════════
def make_animatronic(width, height, cols, rows, total_frames, color, shape, path):
    """Generate an animatronic sprite sheet with animated emblem."""
    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    fw = width // cols
    fh = height // rows

    frame = 0
    for row in range(rows):
        for col in range(cols):
            if frame >= total_frames:
                break
            ox = col * fw
            oy = row * fh
            cx = ox + fw // 2
            cy = oy + fh // 2

            t = frame / max(total_frames - 1, 1)
            pulse = 0.8 + 0.2 * math.sin(t * math.pi * 4)
            sz = int(min(fw, fh) * 0.25 * pulse)

            # Glow ring
            gr = int(sz * 1.6)
            alpha = int(50 * pulse)
            draw.ellipse([cx-gr, cy-gr, cx+gr, cy+gr], fill=color + (alpha,))

            if shape == "diamond":
                pts = [(cx, cy-sz), (cx+sz, cy), (cx, cy+sz), (cx-sz, cy)]
                draw.polygon(pts, fill=color + (200,))
            elif shape == "star":
                pts = [(cx, cy-sz), (cx+sz//3, cy-sz//3), (cx+sz, cy), (cx+sz//3, cy+sz//3),
                       (cx, cy+sz), (cx-sz//3, cy+sz//3), (cx-sz, cy), (cx-sz//3, cy-sz//3)]
                draw.polygon(pts, fill=color + (200,))
            elif shape == "circle":
                draw.ellipse([cx-sz, cy-sz, cx+sz, cy+sz], fill=color + (200,))
            elif shape == "ring":
                draw.ellipse([cx-sz, cy-sz, cx+sz, cy+sz], outline=color + (200,), width=max(3, sz//5))

            frame += 1

    save(img, path)


def task10_animatronics():
    print("\n[Task 10] Animatronic sprite sheets...")

    sheets = [
        (2035, 1422, 11, 9, 98, PURPLE, "diamond", "dino/animatronic/head.png"),
        (2035, 1422, 11, 9, 98, TEAL, "star", "dino/animatronic/mouth.png"),
        (1950, 900, 13, 6, 78, TEAL, "circle", "dash/animatronic.png"),
        (1800, 400, 18, 4, 72, CYAN, "diamond", "android/spaceship/animatronic.png"),
        (1800, 1400, 9, 7, 62, PURPLE, "star", "sparky/animatronic.png"),
    ]

    for w, h, cols, rows, frames, color, shape, rel in sheets:
        make_animatronic(w, h, cols, rows, frames, color, shape,
                        os.path.join(COMP_ASSETS, rel))


def task10_backgrounds():
    print("\n[Task 10] Character backgrounds...")
    W, H = 4000, 2750

    chars = {
        "android": (PURPLE, DARK_PURPLE),
        "dash": (TEAL, (5, 30, 25)),
        "dino": (CYAN, (5, 25, 35)),
        "sparky": (PURPLE, (25, 5, 45)),
    }

    for name, (accent, dark) in chars.items():
        img = Image.new("RGB", (W, H))
        draw = ImageDraw.Draw(img)

        # Vertical gradient
        for y in range(H):
            c = lerp(dark, DEEP_BG, y / H)
            draw.line([(0, y), (W, y)], fill=c)

        # Central glow
        for r in range(800, 0, -10):
            alpha_pct = (1 - r / 800) * 0.15
            c = tuple(min(255, int(DEEP_BG[i] + accent[i] * alpha_pct)) for i in range(3))
            draw.ellipse([W//2 - r, H//2 - r, W//2 + r, H//2 + r], fill=c)

        # Central emblem
        sz = 250
        if name == "android":
            pts = [(W//2, H//2-sz), (W//2+sz, H//2), (W//2, H//2+sz), (W//2-sz, H//2)]
            draw.polygon(pts, fill=accent, outline=lerp(accent, WHITE, 0.3))
        elif name == "dash":
            draw.ellipse([W//2-sz, H//2-sz, W//2+sz, H//2+sz], fill=accent)
        elif name == "dino":
            pts = [(W//2, H//2-sz), (W//2+sz//3, H//2-sz//3), (W//2+sz, H//2),
                   (W//2+sz//3, H//2+sz//3), (W//2, H//2+sz), (W//2-sz//3, H//2+sz//3),
                   (W//2-sz, H//2), (W//2-sz//3, H//2-sz//3)]
            draw.polygon(pts, fill=accent)
        elif name == "sparky":
            draw.ellipse([W//2-sz, H//2-sz, W//2+sz, H//2+sz], outline=accent, width=30)
            draw.ellipse([W//2-sz+60, H//2-sz+60, W//2+sz-60, H//2+sz-60], outline=accent, width=15)

        # Solana logo above
        draw_solana_logo(draw, W // 2, H // 2 - 500, 180)

        path = os.path.join(THEME_ASSETS, name, "background.jpg")
        save(img, path)


# ═══════════════════════════════════════════════════════════════════════
if __name__ == "__main__":
    print("=" * 60)
    print("Seeker Pinball - Solana Sprite Generator (PIL)")
    print("=" * 60)

    task4()
    task5()
    task6()
    task7()
    task8()
    task10_animatronics()
    task10_backgrounds()

    print("\n" + "=" * 60)
    print("All sprites generated!")
    print("=" * 60)
