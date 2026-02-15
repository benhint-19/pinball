"""
Generate 3D-rendered sprite sheets for pinball board components using Gemini API.

Generates 5 sprite assets:
1. Toly Head - 32-frame 360° rotation (8x4 grid, 200x200 per frame)
2. Solana Coin Idle - 4-frame glint loop (4x1 grid, 200x200)
3. Solana Coin Flip - 24-frame end-over-end flip (6x4 grid, 200x200)
4. Seeker Phone Slide - 16-frame hand slide (8x2 grid, 200x300)
5. Mineshaft - 1 static frame (200x300)

Art direction: 3D rendered, smooth shading, clean edges, top-left lighting,
transparent backgrounds, matching the board's pre-rendered isometric style.
"""

import base64
import json
import os
import sys
import urllib.request
import urllib.error
from io import BytesIO

try:
    from PIL import Image
except ImportError:
    print("ERROR: Pillow not installed. Run: pip install Pillow")
    sys.exit(1)

# Gemini API config
API_KEY = "AIzaSyCLOcmfFw9R1e0qMu8V_BQDGOfHwcmTaUE"
BACKUP_KEY = "AIzaSyClik2guz5ArqyQH_fGEzw7_UbRbmnkrD4"
API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent"

ASSETS_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "packages", "pinball_components", "assets", "images"
)

SPRITES = {
    "toly_head": {
        "prompt": (
            "Generate a sprite sheet grid of a 3D rendered cartoon head of a man with dark hair, "
            "wearing a baseball cap, seen rotating 360 degrees. The grid should be 8 columns by 4 rows "
            "(32 frames total), each cell exactly 200x200 pixels. The head should be 3D rendered with "
            "smooth shading, clean edges, top-left lighting, on a transparent/white background. "
            "The style should match pre-rendered isometric game art - polished, colorful, slightly stylized. "
            "The rotation goes from front view through right side, back, left side, and back to front. "
            "Sheet size: 1600x800 pixels total."
        ),
        "output": os.path.join(ASSETS_DIR, "android", "spaceship", "toly_head.png"),
        "grid": (8, 4),
        "cell_size": (200, 200),
    },
    "coin_idle": {
        "prompt": (
            "Generate a sprite sheet of a 3D rendered gold coin with the Solana cryptocurrency logo "
            "(a tilted 'S' shape made of 3 bars) on its face. The grid is 4 columns by 1 row "
            "(4 frames), each cell 200x200 pixels. The coin should have a subtle glint/shine effect "
            "that moves across frames. Gold and purple metallic colors. 3D rendered with smooth shading, "
            "clean edges, top-left lighting, transparent/white background. Polished isometric game art style. "
            "Sheet size: 800x200 pixels."
        ),
        "output": os.path.join(ASSETS_DIR, "solana_coin", "idle.png"),
        "grid": (4, 1),
        "cell_size": (200, 200),
    },
    "coin_flip": {
        "prompt": (
            "Generate a sprite sheet of a 3D rendered gold coin flipping end-over-end on its "
            "horizontal axis. The coin has the Solana cryptocurrency logo (a tilted 'S' made of 3 bars). "
            "The grid is 6 columns by 4 rows (24 frames), each cell 200x200 pixels. "
            "The flip goes from face-on through edge view to back and around again. "
            "Gold and purple metallic colors. 3D rendered, smooth shading, clean edges, "
            "top-left lighting, transparent/white background. Polished isometric game art style. "
            "Sheet size: 1200x800 pixels."
        ),
        "output": os.path.join(ASSETS_DIR, "solana_coin", "flip.png"),
        "grid": (6, 4),
        "cell_size": (200, 200),
    },
    "phone_slide": {
        "prompt": (
            "Generate a sprite sheet of a 3D rendered smartphone being pushed into frame from the right "
            "by a cartoon hand/arm. The grid is 8 columns by 2 rows (16 frames), each cell 200x300 pixels. "
            "Frame 1: just the hand emerging from right. Frames progress: hand pushes phone leftward until "
            "fully visible. The phone screen shows a glowing Solana logo. Modern smartphone design. "
            "3D rendered, smooth shading, clean edges, top-left lighting, transparent/white background. "
            "Polished isometric game art style. Sheet size: 1600x600 pixels."
        ),
        "output": os.path.join(ASSETS_DIR, "seeker_phone", "slide.png"),
        "grid": (8, 2),
        "cell_size": (200, 300),
    },
    "mineshaft": {
        "prompt": (
            "Generate a single 200x300 pixel image of a 3D rendered mine entrance/shaft. "
            "Features: dark cave opening framed by wooden support beams, gold ore veins visible in rock, "
            "a small sign or banner with 'ORE' text above the entrance, lanterns on the beams, "
            "scattered gold nuggets at the base. 3D rendered, smooth shading, clean edges, "
            "top-left lighting, transparent/white background. Polished isometric game art style "
            "matching a pinball board aesthetic."
        ),
        "output": os.path.join(ASSETS_DIR, "android", "mineshaft.png"),
        "grid": (1, 1),
        "cell_size": (200, 300),
    },
}


def call_gemini(prompt, api_key):
    """Call Gemini API to generate an image."""
    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "responseModalities": ["IMAGE", "TEXT"],
            "temperature": 1.0,
        },
    }

    url = f"{API_URL}?key={api_key}"
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={"Content-Type": "application/json"},
    )

    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            result = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8") if e.fp else ""
        raise RuntimeError(f"HTTP {e.code}: {body[:500]}") from e

    # Extract image from response
    for candidate in result.get("candidates", []):
        for part in candidate.get("content", {}).get("parts", []):
            if "inlineData" in part:
                img_data = base64.b64decode(part["inlineData"]["data"])
                return Image.open(BytesIO(img_data))

    raise RuntimeError(f"No image in response: {json.dumps(result)[:500]}")


def process_sprite(raw_img, grid, cell_size, output_path):
    """Resize/crop the AI-generated image to exact sprite sheet dimensions."""
    cols, rows = grid
    cw, ch = cell_size
    target_w = cols * cw
    target_h = rows * ch

    # Resize to target dimensions
    processed = raw_img.resize((target_w, target_h), Image.LANCZOS)

    # Convert to RGBA for transparency
    if processed.mode != "RGBA":
        processed = processed.convert("RGBA")

    # Ensure output directory exists
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    processed.save(output_path, "PNG")
    print(f"  Saved: {output_path} ({target_w}x{target_h})")
    return processed


def generate_placeholder(grid, cell_size, output_path, label=""):
    """Generate a colored placeholder sprite sheet if API fails."""
    cols, rows = grid
    cw, ch = cell_size
    target_w = cols * cw
    target_h = rows * ch

    img = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))

    try:
        from PIL import ImageDraw, ImageFont
        draw = ImageDraw.Draw(img)

        # Draw grid cells with colored backgrounds
        colors = [
            (153, 69, 255, 180),  # Solana purple
            (20, 241, 149, 180),  # Solana green
            (255, 200, 50, 180),  # Gold
            (100, 150, 255, 180), # Blue
        ]

        for row in range(rows):
            for col in range(cols):
                frame_idx = row * cols + col
                color = colors[frame_idx % len(colors)]
                x0, y0 = col * cw, row * ch
                x1, y1 = x0 + cw - 1, y0 + ch - 1
                draw.rectangle([x0, y0, x1, y1], fill=color, outline=(255, 255, 255, 255))
                text = f"{label}\n#{frame_idx}"
                draw.text((x0 + 10, y0 + 10), text, fill=(255, 255, 255, 255))
    except Exception:
        pass

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path, "PNG")
    print(f"  Placeholder saved: {output_path} ({target_w}x{target_h})")


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Generate 3D sprite sheets")
    parser.add_argument("--sprites", nargs="*", choices=list(SPRITES.keys()),
                        help="Specific sprites to generate (default: all)")
    parser.add_argument("--placeholder", action="store_true",
                        help="Generate colored placeholders instead of AI art")
    parser.add_argument("--key", default=API_KEY, help="Gemini API key")
    args = parser.parse_args()

    targets = args.sprites or list(SPRITES.keys())

    for name in targets:
        spec = SPRITES[name]
        print(f"\nGenerating: {name}")
        print(f"  Grid: {spec['grid'][0]}x{spec['grid'][1]}, Cell: {spec['cell_size']}")

        if args.placeholder:
            generate_placeholder(spec["grid"], spec["cell_size"], spec["output"], name)
            continue

        # Try primary key, then backup
        for key in [args.key, BACKUP_KEY]:
            try:
                raw_img = call_gemini(spec["prompt"], key)
                process_sprite(raw_img, spec["grid"], spec["cell_size"], spec["output"])
                break
            except Exception as e:
                print(f"  Error with key ...{key[-6:]}: {e}")
                if key == BACKUP_KEY:
                    print(f"  Both keys failed. Generating placeholder.")
                    generate_placeholder(spec["grid"], spec["cell_size"], spec["output"], name)

    print("\nDone! All sprite sheets generated.")


if __name__ == "__main__":
    main()
