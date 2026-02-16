"""Generate a glowing/lit version of the Solana token using Gemini."""

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
    print("ERROR: Pillow not installed.")
    sys.exit(1)

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
    print("ERROR: GEMINI_API_KEY not set.")
    sys.exit(1)
API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent"

ASSETS_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "packages", "pinball_components", "assets", "images", "solana_coin"
)
DEBUG_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "solana_debug")


def call_gemini(prompt):
    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "responseModalities": ["IMAGE", "TEXT"],
            "temperature": 0.7,
        },
    }
    url = f"{API_URL}?key={API_KEY}"
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


def remove_background(img, threshold=215):
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
    canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    scale = min(width / img.width, height / img.height) * scale_factor
    new_w = int(img.width * scale)
    new_h = int(img.height * scale)
    resized = img.resize((new_w, new_h), Image.LANCZOS)
    x = (width - new_w) // 2
    y = (height - new_h) // 2
    canvas.paste(resized, (x, y), resized)
    return canvas


if __name__ == "__main__":
    os.makedirs(DEBUG_DIR, exist_ok=True)
    os.makedirs(ASSETS_DIR, exist_ok=True)

    prompt = """Generate a single high-quality 3D rendering of a Solana cryptocurrency token/coin that is GLOWING BRIGHTLY.

Requirements:
- Same coin as the standard Solana token but it is ACTIVATED/LIT UP
- Viewed from a 3/4 top-down perspective angle (about 30 degrees from above)
- The coin is a thick metallic disc with visible rim/edge
- The face shows the Solana logo: three parallel bars forming an angular "S" shape
- The logo bars glow intensely with teal (#14F195) to purple (#9945FF) gradient, much brighter than normal
- Strong teal and purple light radiates outward from the coin in all directions
- The rim/edge glows with teal-purple light
- Energy/light particles or rays emanating from the coin
- Clean white background
- The coin should fill most of the frame
- NO text, NO extra objects
- Photorealistic 3D render style with dramatic lighting"""

    print("Generating glowing Solana token with Gemini...")
    raw = call_gemini(prompt)
    raw.save(os.path.join(DEBUG_DIR, "token_lit_raw.png"))

    processed = remove_background(raw)
    processed = crop_to_content(processed)
    processed = center_on_canvas(processed, 256, 256)
    processed.save(os.path.join(DEBUG_DIR, "token_lit_processed.png"))
    processed.save(os.path.join(ASSETS_DIR, "lit.png"))
    print(f"Saved lit.png: {processed.size}")
