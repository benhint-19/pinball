"""
Generate SEEKER letter sprites to replace GOOGLE letter sprites.

Each letter is rendered inside a circle matching the original sprite dimensions.
- Lit state: Solana-colored glowing circle with white letter
- Dimmed state: Dark muted circle with dim letter
"""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os

BASE_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "packages", "pinball_components", "assets", "images", "google_word"
)

# Letter assignments and per-slot dimensions (from originals)
LETTERS = [
    ("S", "letter1", (47, 44)),
    ("E", "letter2", (48, 43)),
    ("E", "letter3", (47, 43)),
    ("K", "letter4", (47, 43)),
    ("E", "letter5", (47, 43)),
    ("R", "letter6", (48, 44)),
]

# Solana palette
PURPLE = (153, 69, 255)       # #9945FF
GREEN = (20, 241, 149)        # #14F195
DARK_BG = (26, 26, 46)        # #1a1a2e
DIM_LETTER = (68, 68, 102)    # #444466
DIM_CIRCLE = (40, 40, 65)     # circle fill when dimmed
DIM_EDGE = (30, 30, 50)       # darker edge for dimmed


def radial_gradient(draw, cx, cy, radius, color_inner, color_outer):
    """Draw a filled radial gradient circle using concentric circles."""
    for r in range(int(radius), 0, -1):
        t = r / radius  # 1.0 at edge, 0.0 at center
        t2 = t * t
        c = tuple(int(color_inner[i] * (1 - t2) + color_outer[i] * t2) for i in range(3))
        draw.ellipse(
            [cx - r, cy - r, cx + r, cy + r],
            fill=c + (255,)
        )


def make_sprite(letter, size, lit=True):
    """Generate a single letter sprite."""
    w, h = size
    # Work at 4x for antialiasing
    scale = 4
    sw, sh = w * scale, h * scale
    img = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx, cy = sw // 2, sh // 2
    radius = min(sw, sh) // 2 - scale

    if lit:
        # Outer glow layer (purple, slightly larger)
        glow_img = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
        glow_draw = ImageDraw.Draw(glow_img)
        glow_r = radius + scale * 2
        glow_draw.ellipse(
            [cx - glow_r, cy - glow_r, cx + glow_r, cy + glow_r],
            fill=PURPLE + (100,)
        )
        glow_img = glow_img.filter(ImageFilter.GaussianBlur(radius=scale * 2))
        img = Image.alpha_composite(img, glow_img)
        draw = ImageDraw.Draw(img)

        # Main circle with gradient: green center fading to purple edge
        radial_gradient(draw, cx, cy, radius, GREEN, PURPLE)

        # Bevel highlight on top-left
        for offset in range(scale * 2):
            r = radius - offset
            alpha = int(80 * (1 - offset / (scale * 2)))
            overlay = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
            od = ImageDraw.Draw(overlay)
            od.arc(
                [cx - r, cy - r, cx + r, cy + r],
                start=200, end=340,
                fill=(255, 255, 255, alpha),
                width=scale
            )
            img = Image.alpha_composite(img, overlay)

        # Shadow arc on bottom-right
        for offset in range(scale * 2):
            r = radius - offset
            alpha = int(60 * (1 - offset / (scale * 2)))
            overlay = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
            od = ImageDraw.Draw(overlay)
            od.arc(
                [cx - r, cy - r, cx + r, cy + r],
                start=20, end=160,
                fill=(0, 0, 0, alpha),
                width=scale
            )
            img = Image.alpha_composite(img, overlay)

        draw = ImageDraw.Draw(img)
        letter_color = (255, 255, 255, 255)
    else:
        # Dimmed state: dark circle with subtle gradient
        radial_gradient(draw, cx, cy, radius, DIM_CIRCLE, DIM_EDGE)

        # Subtle bevel
        for offset in range(scale):
            r = radius - offset
            alpha = int(30 * (1 - offset / scale))
            overlay = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
            od = ImageDraw.Draw(overlay)
            od.arc(
                [cx - r, cy - r, cx + r, cy + r],
                start=200, end=340,
                fill=(80, 80, 100, alpha),
                width=scale
            )
            img = Image.alpha_composite(img, overlay)

        draw = ImageDraw.Draw(img)
        letter_color = DIM_LETTER + (255,)

    # Draw the letter
    font_size = int(radius * 1.15)
    try:
        font = ImageFont.truetype("arialbd.ttf", font_size)
    except OSError:
        font = ImageFont.truetype("arial.ttf", font_size)

    bbox = font.getbbox(letter)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    tx = cx - tw // 2 - bbox[0]
    ty = cy - th // 2 - bbox[1]

    if lit:
        # Text shadow for depth
        shadow = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
        sd = ImageDraw.Draw(shadow)
        sd.text((tx + scale, ty + scale), letter, font=font, fill=(0, 0, 0, 80))
        shadow = shadow.filter(ImageFilter.GaussianBlur(radius=scale))
        img = Image.alpha_composite(img, shadow)
        draw = ImageDraw.Draw(img)

    draw.text((tx, ty), letter, font=font, fill=letter_color)

    # Mask to circle
    mask = Image.new("L", (sw, sh), 0)
    mask_draw = ImageDraw.Draw(mask)
    clip_r = radius + scale * 2 if lit else radius
    mask_draw.ellipse(
        [cx - clip_r, cy - clip_r, cx + clip_r, cy + clip_r],
        fill=255
    )
    if lit:
        mask = mask.filter(ImageFilter.GaussianBlur(radius=scale))
    img.putalpha(Image.composite(img.split()[3], Image.new("L", (sw, sh), 0), mask))

    # Downscale with high-quality resampling
    img = img.resize((w, h), Image.LANCZOS)
    return img


def main():
    for letter, folder, size in LETTERS:
        out_dir = os.path.join(BASE_DIR, folder)
        os.makedirs(out_dir, exist_ok=True)

        for state in ("lit", "dimmed"):
            is_lit = state == "lit"
            sprite = make_sprite(letter, size, lit=is_lit)
            path = os.path.join(out_dir, f"{state}.png")
            sprite.save(path)
            print(f"  Saved {path} ({sprite.size[0]}x{sprite.size[1]})")

    print("\nDone! All SEEKER letter sprites generated.")


if __name__ == "__main__":
    main()
