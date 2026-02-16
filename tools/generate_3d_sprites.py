"""
Generate 3D-rendered sprite sheets for pinball board components using Gemini API.

Strategy: Generate ONE high-quality frame per sprite, then use PIL to create
sprite sheets by duplicating/transforming that frame. This avoids the problem
of AI models producing poorly-aligned grids.

Post-processing: automatic white/light background removal to transparent.
"""

import base64
import json
import os
import sys
import urllib.request
import urllib.error
from io import BytesIO

try:
    from PIL import Image, ImageDraw, ImageFilter, ImageEnhance
except ImportError:
    print("ERROR: Pillow not installed. Run: pip install Pillow")
    sys.exit(1)

# Gemini API config — keys loaded from tools/.env or environment
def _load_env():
    env_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")
    if os.path.exists(env_path):
        with open(env_path) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    k, v = line.split("=", 1)
                    os.environ.setdefault(k.strip(), v.strip())

_load_env()
API_KEY = os.environ.get("GEMINI_API_KEY", "")
BACKUP_KEY = os.environ.get("GEMINI_BACKUP_KEY", "")
if not API_KEY:
    print("ERROR: GEMINI_API_KEY not set. Add it to tools/.env or export it.")
    sys.exit(1)
API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent"

ASSETS_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "packages", "pinball_components", "assets", "images"
)


def call_gemini(prompt, api_key):
    """Call Gemini API to generate an image."""
    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "responseModalities": ["IMAGE", "TEXT"],
            "temperature": 0.8,
        },
    }

    url = f"{API_URL}?key={api_key}"
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url, data=data,
        headers={"Content-Type": "application/json"},
    )

    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            result = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8") if e.fp else ""
        raise RuntimeError(f"HTTP {e.code}: {body[:500]}") from e

    for candidate in result.get("candidates", []):
        for part in candidate.get("content", {}).get("parts", []):
            if "inlineData" in part:
                img_data = base64.b64decode(part["inlineData"]["data"])
                return Image.open(BytesIO(img_data))

    raise RuntimeError(f"No image in response: {json.dumps(result)[:500]}")


def remove_background(img, threshold=220):
    """Remove white/light background, replacing with transparency."""
    img = img.convert("RGBA")
    data = img.getdata()
    new_data = []
    for r, g, b, a in data:
        # If pixel is close to white, make transparent
        if r > threshold and g > threshold and b > threshold:
            new_data.append((r, g, b, 0))
        else:
            # Partial transparency for near-white pixels (antialiasing)
            brightness = (r + g + b) / 3
            if brightness > threshold - 30:
                fade = int(255 * (1 - (brightness - (threshold - 30)) / 30))
                new_data.append((r, g, b, min(a, fade)))
            else:
                new_data.append((r, g, b, a))
    img.putdata(new_data)
    return img


def crop_to_content(img, padding=5):
    """Crop image to its non-transparent content with padding."""
    bbox = img.getbbox()
    if bbox is None:
        return img
    x0, y0, x1, y1 = bbox
    x0 = max(0, x0 - padding)
    y0 = max(0, y0 - padding)
    x1 = min(img.width, x1 + padding)
    y1 = min(img.height, y1 + padding)
    return img.crop((x0, y0, x1, y1))


def center_on_canvas(img, width, height):
    """Center an image on a transparent canvas of given size."""
    canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    # Scale to fit
    scale = min(width / img.width, height / img.height) * 0.85
    new_w = int(img.width * scale)
    new_h = int(img.height * scale)
    resized = img.resize((new_w, new_h), Image.LANCZOS)
    x = (width - new_w) // 2
    y = (height - new_h) // 2
    canvas.paste(resized, (x, y), resized)
    return canvas


def make_rotation_sheet(base_img, cols, rows, cell_w, cell_h):
    """Create a rotation sprite sheet by rotating a single frame."""
    total = cols * rows
    sheet = Image.new("RGBA", (cols * cell_w, rows * cell_h), (0, 0, 0, 0))

    for i in range(total):
        angle = -360 * i / total  # negative = clockwise
        rotated = base_img.rotate(angle, resample=Image.BICUBIC, expand=False)
        col = i % cols
        row = i // cols
        sheet.paste(rotated, (col * cell_w, row * cell_h), rotated)

    return sheet


def make_coin_idle_sheet(base_img, cols, cell_w, cell_h):
    """Create idle coin sheet with subtle brightness variation (glint effect)."""
    sheet = Image.new("RGBA", (cols * cell_w, cell_h), (0, 0, 0, 0))
    brightnesses = [1.0, 1.08, 1.15, 1.08]

    for i in range(cols):
        frame = base_img.copy()
        enhancer = ImageEnhance.Brightness(frame)
        frame = enhancer.enhance(brightnesses[i % len(brightnesses)])
        col = i % cols
        sheet.paste(frame, (col * cell_w, 0), frame)

    return sheet


def make_coin_flip_sheet(base_img, cols, rows, cell_w, cell_h):
    """Create coin flip by squishing horizontally to simulate rotation on vertical axis."""
    total = cols * rows
    sheet = Image.new("RGBA", (cols * cell_w, rows * cell_h), (0, 0, 0, 0))
    import math

    for i in range(total):
        t = i / total
        # Cosine gives the foreshortening: 1.0 = face-on, 0 = edge-on
        scale_x = abs(math.cos(t * 2 * math.pi))
        scale_x = max(scale_x, 0.05)  # never fully zero

        new_w = max(1, int(cell_w * scale_x))
        frame = base_img.resize((new_w, cell_h), Image.LANCZOS)

        canvas = Image.new("RGBA", (cell_w, cell_h), (0, 0, 0, 0))
        x = (cell_w - new_w) // 2
        canvas.paste(frame, (x, 0), frame)

        col = i % cols
        row = i // cols
        sheet.paste(canvas, (col * cell_w, row * cell_h), canvas)

    return sheet


def make_phone_slide_sheet(base_img, cols, rows, cell_w, cell_h):
    """Create phone sliding in from right by shifting position across frames."""
    total = cols * rows
    sheet = Image.new("RGBA", (cols * cell_w, rows * cell_h), (0, 0, 0, 0))

    for i in range(total):
        t = i / (total - 1)  # 0 to 1
        # Ease-out cubic
        t_ease = 1 - (1 - t) ** 3
        # Start fully off-right, end centered
        x_offset = int((1 - t_ease) * cell_w)

        canvas = Image.new("RGBA", (cell_w, cell_h), (0, 0, 0, 0))
        canvas.paste(base_img, (x_offset, 0), base_img)

        col = i % cols
        row = i // cols
        sheet.paste(canvas, (col * cell_w, row * cell_h), canvas)

    return sheet


def generate_and_save(name, prompt, output_path, build_sheet_fn, cell_w, cell_h):
    """Generate a single image with Gemini, post-process, and build sprite sheet."""
    print(f"\nGenerating: {name}")

    raw_img = None
    for key in [API_KEY, BACKUP_KEY]:
        try:
            raw_img = call_gemini(prompt, key)
            print(f"  Got image: {raw_img.size}")
            break
        except Exception as e:
            print(f"  Error with key ...{key[-6:]}: {e}")

    if raw_img is None:
        print(f"  FAILED - skipping {name}")
        return False

    # Post-process: remove background, crop, center
    processed = remove_background(raw_img)
    processed = crop_to_content(processed)
    processed = center_on_canvas(processed, cell_w, cell_h)

    # Save the base frame for debugging
    debug_path = output_path.replace(".png", "_base.png")
    processed.save(debug_path, "PNG")
    print(f"  Base frame saved: {debug_path}")

    # Build sprite sheet
    sheet = build_sheet_fn(processed)

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    sheet.save(output_path, "PNG")
    print(f"  Sheet saved: {output_path} ({sheet.size[0]}x{sheet.size[1]})")
    return True


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Generate 3D sprite sheets")
    parser.add_argument("--sprites", nargs="*",
                        choices=["toly_head", "coin_idle", "coin_flip", "phone_slide", "mineshaft", "all"],
                        default=["all"],
                        help="Specific sprites to generate")
    args = parser.parse_args()

    targets = args.sprites
    if "all" in targets:
        targets = ["toly_head", "coin_idle", "coin_flip", "phone_slide", "mineshaft"]

    CELL = 200

    # --- TOLY HEAD ---
    if "toly_head" in targets:
        generate_and_save(
            "toly_head",
            "A 3D rendered cartoon portrait of Anatoly Yakovenko, the founder of Solana blockchain. "
            "He has dark hair and wears a red baseball cap. Friendly expression, slightly stylized "
            "like a video game character. Rendered in colorful isometric game art style with smooth "
            "shading and clean outlines. Single centered portrait on a plain white background. "
            "Head and shoulders only, front-facing view.",
            os.path.join(ASSETS_DIR, "android", "spaceship", "toly_head.png"),
            lambda img: make_rotation_sheet(img, 8, 4, CELL, CELL),
            CELL, CELL,
        )

    # --- COIN IDLE ---
    if "coin_idle" in targets:
        generate_and_save(
            "coin_idle",
            "A single 3D rendered gold coin with the Solana cryptocurrency logo on its face. "
            "The Solana logo is a tilted S shape made of 3 parallel bars in purple/violet color. "
            "The coin is thick, metallic gold with beveled edges and a subtle shine highlight. "
            "Viewed straight-on from the front. Plain white background. Game asset style.",
            os.path.join(ASSETS_DIR, "solana_coin", "idle.png"),
            lambda img: make_coin_idle_sheet(img, 4, CELL, CELL),
            CELL, CELL,
        )

    # --- COIN FLIP ---
    if "coin_flip" in targets:
        generate_and_save(
            "coin_flip",
            "A single 3D rendered gold coin with the Solana cryptocurrency logo on its face. "
            "The Solana logo is a tilted S shape made of 3 parallel bars in purple/violet color. "
            "The coin is thick, metallic gold with beveled edges and a subtle shine highlight. "
            "Viewed straight-on from the front. Plain white background. Game asset style.",
            os.path.join(ASSETS_DIR, "solana_coin", "flip.png"),
            lambda img: make_coin_flip_sheet(img, 6, 4, CELL, CELL),
            CELL, CELL,
        )

    # --- PHONE SLIDE ---
    if "phone_slide" in targets:
        generate_and_save(
            "phone_slide",
            "A 3D rendered modern smartphone held by a cartoon hand, viewed from the front. "
            "The phone screen displays a glowing Solana logo (tilted S in purple/teal gradient). "
            "The hand grips the phone from the right side. Clean game asset style with smooth "
            "shading, colorful, on a plain white background.",
            os.path.join(ASSETS_DIR, "seeker_phone", "slide.png"),
            lambda img: make_phone_slide_sheet(img, 8, 2, CELL, 300),
            CELL, 300,
        )

    # --- MINESHAFT (static, no sheet needed) ---
    if "mineshaft" in targets:
        print("\nGenerating: mineshaft")
        raw_img = None
        for key in [API_KEY, BACKUP_KEY]:
            try:
                raw_img = call_gemini(
                    "A 3D rendered mine entrance in isometric game art style. Dark cave opening "
                    "framed by wooden support beams with gold ore veins visible in the surrounding rock. "
                    "A rustic wooden sign reading 'ORE' hangs above the entrance. Small lanterns on the "
                    "beams cast warm light. Gold nuggets scattered at the base. Colorful, polished, "
                    "clean outlines, on a plain white background.",
                    key,
                )
                print(f"  Got image: {raw_img.size}")
                break
            except Exception as e:
                print(f"  Error with key ...{key[-6:]}: {e}")

        if raw_img:
            processed = remove_background(raw_img)
            processed = crop_to_content(processed)
            processed = center_on_canvas(processed, CELL, 300)
            out = os.path.join(ASSETS_DIR, "android", "mineshaft.png")
            os.makedirs(os.path.dirname(out), exist_ok=True)
            processed.save(out, "PNG")
            print(f"  Saved: {out}")

    print("\nDone!")


if __name__ == "__main__":
    main()
