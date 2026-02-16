"""
Generate a 3D-rendered Toly bust/figurine for the pinball table.
Uses Gemini to create a proper 3D object viewed from above at an angle,
like it's sitting on the pinball surface.
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

REFERENCE_URL = "https://pbs.twimg.com/media/G71jKB4XEAAtIaV.jpg"

ASSETS_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "packages", "pinball_components", "assets", "images"
)
OUTPUT_PATH = os.path.join(ASSETS_DIR, "android", "spaceship", "toly_head.png")
DEBUG_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "toly_debug")


def download_reference():
    print("Downloading reference image...")
    req = urllib.request.Request(REFERENCE_URL, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        data = resp.read()
    img = Image.open(BytesIO(data))
    print(f"  Reference: {img.size}")
    return img


def image_to_base64(img, fmt="JPEG"):
    buf = BytesIO()
    img.save(buf, format=fmt)
    return base64.b64encode(buf.getvalue()).decode("utf-8")


def call_gemini_with_image(prompt, ref_image, api_key):
    ref_b64 = image_to_base64(ref_image)
    payload = {
        "contents": [{
            "parts": [
                {"inlineData": {"mimeType": "image/jpeg", "data": ref_b64}},
                {"text": prompt},
            ]
        }],
        "generationConfig": {
            "responseModalities": ["IMAGE", "TEXT"],
            "temperature": 0.7,
        },
    }
    url = f"{API_URL}?key={api_key}"
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"})

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
    img = img.convert("RGBA")
    pixels = list(img.getdata())
    new_data = []
    for r, g, b, a in pixels:
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


def crop_to_content(img, padding=10):
    bbox = img.getbbox()
    if bbox is None:
        return img
    x0, y0, x1, y1 = bbox
    x0 = max(0, x0 - padding)
    y0 = max(0, y0 - padding)
    x1 = min(img.width, x1 + padding)
    y1 = min(img.height, y1 + padding)
    return img.crop((x0, y0, x1, y1))


def center_on_canvas(img, size):
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    scale = min(size / img.width, size / img.height) * 0.9
    new_w = int(img.width * scale)
    new_h = int(img.height * scale)
    resized = img.resize((new_w, new_h), Image.LANCZOS)
    x = (size - new_w) // 2
    y = (size - new_h) // 2
    canvas.paste(resized, (x, y), resized)
    return canvas


def main():
    os.makedirs(DEBUG_DIR, exist_ok=True)
    ref_img = download_reference()

    prompt = (
        "Look at the cartoon character on the LEFT side of this reference image. "
        "Now create a 3D FIGURINE / BUST of this character's head and shoulders. "
        "\n\n"
        "CRITICAL REQUIREMENTS:\n"
        "- This must look like an actual 3D PHYSICAL OBJECT, like a vinyl toy or bobblehead\n"
        "- It should be a bust/figurine sitting on a small round base/pedestal\n"
        "- The figurine is viewed from SLIGHTLY ABOVE and in front (about 30 degrees down), "
        "as if looking down at it on a table\n"
        "- The head should be a 3D CYLINDER/ROUNDED SHAPE, NOT flat\n"
        "- The hat brim should stick out from the head as a 3D element\n"
        "- Show realistic 3D lighting with shadows - lit from the top-left\n"
        "- The base should have a subtle purple/teal glow (Solana colors)\n"
        "- Keep the same cartoon art style and colors as the reference\n"
        "- Plain white background\n"
        "- The figurine should be centered and fill most of the image\n"
        "\n"
        "Think of it like a high-quality 3D rendered game collectible figure "
        "or a character select bust from a video game."
    )

    print("\nGenerating 3D Toly figurine...")
    result = None
    for key in [API_KEY, BACKUP_KEY]:
        try:
            result = call_gemini_with_image(prompt, ref_img, key)
            print(f"  Got image: {result.size}")
            break
        except Exception as e:
            print(f"  Error with key ...{key[-6:]}: {e}")

    if result is None:
        print("FAILED to generate image!")
        sys.exit(1)

    # Save raw result
    raw_path = os.path.join(DEBUG_DIR, "toly_3d_raw.png")
    result.save(raw_path, "PNG")
    print(f"  Raw saved: {raw_path}")

    # Post-process
    processed = remove_background(result)
    processed = crop_to_content(processed)
    processed = center_on_canvas(processed, 512)

    debug_path = os.path.join(DEBUG_DIR, "toly_3d_processed.png")
    processed.save(debug_path, "PNG")
    print(f"  Processed saved: {debug_path}")

    # Save as the game asset (single static image, not spritesheet)
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    processed.save(OUTPUT_PATH, "PNG")
    print(f"  Asset saved: {OUTPUT_PATH} ({processed.size[0]}x{processed.size[1]})")
    print("\nDone!")


if __name__ == "__main__":
    main()
