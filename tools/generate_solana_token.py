"""
Generate a 3D Solana token sprite using Gemini image generation.
Produces idle, lit, and flip sprite sheets for the pinball board.
"""

import base64
import json
import os
import sys
import math
import urllib.request
import urllib.error
from io import BytesIO

try:
    from PIL import Image, ImageEnhance, ImageFilter
except ImportError:
    print("ERROR: Pillow not installed. Run: pip install Pillow")
    sys.exit(1)

# Gemini API config
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
if not API_KEY:
    print("ERROR: GEMINI_API_KEY not set. Add it to tools/.env or export it.")
    sys.exit(1)
API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent"

ASSETS_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "packages", "pinball_components", "assets", "images", "solana_coin"
)
DEBUG_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "solana_debug")

CELL_W = 256
CELL_H = 256


def call_gemini(prompt):
    """Call Gemini API to generate an image."""
    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "responseModalities": ["IMAGE", "TEXT"],
            "temperature": 0.7,
        },
    }

    url = f"{API_URL}?key={API_KEY}"
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


def remove_background(img, threshold=215):
    """Remove white/light background, replacing with transparency."""
    img = img.convert("RGBA")
    data = img.getdata()
    new_data = []
    for r, g, b, a in data:
        if r > threshold and g > threshold and b > threshold:
            new_data.append((r, g, b, 0))
        else:
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


def center_on_canvas(img, width, height, scale_factor=0.88):
    """Center an image on a transparent canvas of given size."""
    canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    scale = min(width / img.width, height / img.height) * scale_factor
    new_w = int(img.width * scale)
    new_h = int(img.height * scale)
    resized = img.resize((new_w, new_h), Image.LANCZOS)
    x = (width - new_w) // 2
    y = (height - new_h) // 2
    canvas.paste(resized, (x, y), resized)
    return canvas


def make_idle_sheet(base_img, cols=4):
    """Create idle sheet with subtle glint animation."""
    sheet = Image.new("RGBA", (cols * CELL_W, CELL_H), (0, 0, 0, 0))
    brightnesses = [1.0, 1.06, 1.12, 1.06]

    for i in range(cols):
        frame = base_img.copy()
        enhancer = ImageEnhance.Brightness(frame)
        frame = enhancer.enhance(brightnesses[i])
        sheet.paste(frame, (i * CELL_W, 0), frame)

    return sheet


def make_lit_sheet(base_img, cols=4):
    """Create lit/glowing version of the token."""
    sheet = Image.new("RGBA", (cols * CELL_W, CELL_H), (0, 0, 0, 0))
    brightnesses = [1.25, 1.35, 1.45, 1.35]

    for i in range(cols):
        frame = base_img.copy()
        enhancer = ImageEnhance.Brightness(frame)
        frame = enhancer.enhance(brightnesses[i])
        # Add color boost
        enhancer2 = ImageEnhance.Color(frame)
        frame = enhancer2.enhance(1.3)
        sheet.paste(frame, (i * CELL_W, 0), frame)

    return sheet


def make_flip_sheet(base_img, cols=8, rows=1):
    """Create coin flip by squishing horizontally to simulate Y-axis rotation."""
    total = cols * rows
    sheet = Image.new("RGBA", (cols * CELL_W, rows * CELL_H), (0, 0, 0, 0))

    for i in range(total):
        t = i / total
        squeeze = abs(math.cos(t * 2 * math.pi))
        squeeze = max(squeeze, 0.08)  # don't go fully flat

        new_w = max(1, int(CELL_W * squeeze))
        frame = base_img.resize((new_w, CELL_H), Image.LANCZOS)

        canvas = Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
        x = (CELL_W - new_w) // 2
        canvas.paste(frame, (x, 0), frame)

        col = i % cols
        row = i // cols
        sheet.paste(canvas, (col * CELL_W, row * CELL_H), canvas)

    return sheet


def generate_token():
    """Generate the 3D Solana token using Gemini."""
    os.makedirs(DEBUG_DIR, exist_ok=True)
    os.makedirs(ASSETS_DIR, exist_ok=True)

    prompt = """Generate a single high-quality 3D rendering of a Solana cryptocurrency token/coin.

Requirements:
- Viewed from a 3/4 top-down perspective angle (about 30 degrees from above), as if looking down at a coin on a pinball table
- The coin should be a thick metallic disc/token shape with visible rim/edge
- The face of the coin shows the REAL Solana logo: three parallel horizontal bars that form an angular "S" shape, with pointed/angled ends. The top bar angles down-right on left, middle bar angles down-left on right, bottom bar angles down-right on left.
- Color scheme: dark coin face (near black), the Solana logo bars have a gradient from teal/green (#14F195) at top to purple (#9945FF) at bottom
- Metallic silver/chrome rim edge with subtle reflections
- The coin should have a subtle teal-purple glow/light emanating from it
- Clean white background for easy extraction
- The coin should look premium, shiny, and 3D with specular highlights
- Size: the coin should fill most of the frame
- NO text, NO extra objects, just the single coin
- Photorealistic 3D render style"""

    print("Generating 3D Solana token with Gemini...")
    raw_img = call_gemini(prompt)
    raw_img.save(os.path.join(DEBUG_DIR, "token_raw.png"))
    print(f"  Raw image: {raw_img.size}")

    # Process: remove background, crop, center
    processed = remove_background(raw_img)
    processed = crop_to_content(processed)
    processed = center_on_canvas(processed, CELL_W, CELL_H)
    processed.save(os.path.join(DEBUG_DIR, "token_processed.png"))
    print(f"  Processed: {processed.size}")

    # Generate sprite sheets
    print("Creating idle sprite sheet...")
    idle = make_idle_sheet(processed)
    idle.save(os.path.join(ASSETS_DIR, "idle.png"))
    print(f"  idle.png: {idle.size}")

    print("Creating lit sprite sheet...")
    lit = make_lit_sheet(processed)
    lit.save(os.path.join(ASSETS_DIR, "lit.png"))
    print(f"  lit.png: {lit.size}")

    print("Creating flip sprite sheet...")
    flip = make_flip_sheet(processed)
    flip.save(os.path.join(ASSETS_DIR, "flip.png"))
    print(f"  flip.png: {flip.size}")

    print("\nDone! Assets saved to:", ASSETS_DIR)
    print("Debug images saved to:", DEBUG_DIR)


if __name__ == "__main__":
    generate_token()
