"""
Generate a 3D Solana token for the pinball board.
Creates a proper 3D coin with the real Solana logo, viewed from above at an angle.
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

API_KEY = "AIzaSyCLOcmfFw9R1e0qMu8V_BQDGOfHwcmTaUE"
BACKUP_KEY = "AIzaSyClik2guz5ArqyQH_fGEzw7_UbRbmnkrD4"
API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent"

ASSETS_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "packages", "pinball_components", "assets", "images"
)
DEBUG_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "solana_debug")


def call_gemini(prompt, api_key):
    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
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


def center_on_canvas(img, width, height):
    canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    scale = min(width / img.width, height / img.height) * 0.9
    new_w = int(img.width * scale)
    new_h = int(img.height * scale)
    resized = img.resize((new_w, new_h), Image.LANCZOS)
    x = (width - new_w) // 2
    y = (height - new_h) // 2
    canvas.paste(resized, (x, y), resized)
    return canvas


def main():
    os.makedirs(DEBUG_DIR, exist_ok=True)

    # Generate the 3D token - idle state (hovering, front-facing)
    idle_prompt = (
        "Create a 3D rendered Solana cryptocurrency token/coin. "
        "\n\nCRITICAL REQUIREMENTS:\n"
        "- The coin must show the REAL Solana logo: three diagonal parallel bars "
        "forming an 'S' shape, with a gradient from teal (#14F195) to purple (#9945FF)\n"
        "- The coin is a thick 3D metallic disc, dark purple/black with the Solana gradient logo\n"
        "- Viewed from slightly above at about 30 degrees (like looking down at a table)\n"
        "- The coin appears to be HOVERING/FLOATING with a subtle glow beneath it\n"
        "- Purple and teal glow emanating from below the coin\n"
        "- The coin has a metallic rim/edge that catches the light\n"
        "- Clean, polished 3D render style like a game collectible\n"
        "- Plain white background\n"
        "- The coin should be centered and fill most of the image\n"
        "- The Solana logo should be clearly visible and recognizable\n"
    )

    print("Generating 3D Solana token (idle)...")
    result = None
    for key in [API_KEY, BACKUP_KEY]:
        try:
            result = call_gemini(idle_prompt, key)
            print(f"  Got image: {result.size}")
            break
        except Exception as e:
            print(f"  Error with key ...{key[-6:]}: {e}")

    if result is None:
        print("FAILED!")
        sys.exit(1)

    raw_path = os.path.join(DEBUG_DIR, "token_idle_raw.png")
    result.save(raw_path, "PNG")

    processed = remove_background(result)
    processed = crop_to_content(processed)
    processed = center_on_canvas(processed, 512, 512)

    debug_path = os.path.join(DEBUG_DIR, "token_idle_processed.png")
    processed.save(debug_path, "PNG")
    print(f"  Saved: {debug_path}")

    # Generate lit/active state (brighter glow when ball hits)
    lit_prompt = (
        "Create a 3D rendered Solana cryptocurrency token/coin that is GLOWING BRIGHTLY. "
        "\n\nCRITICAL REQUIREMENTS:\n"
        "- The coin shows the REAL Solana logo: three diagonal parallel bars "
        "forming an 'S' shape, with a gradient from teal (#14F195) to purple (#9945FF)\n"
        "- The coin is a thick 3D metallic disc, dark purple/black base\n"
        "- Viewed from slightly above at about 30 degrees\n"
        "- The coin is GLOWING INTENSELY - bright teal and purple light radiating outward\n"
        "- Strong lens flare / bloom effect around the coin\n"
        "- The Solana logo is lit up and pulsing with energy\n"
        "- Bright particles or energy emanating from the coin\n"
        "- Clean 3D render, plain white background\n"
        "- Same size and angle as a normal hovering coin but MUCH brighter\n"
    )

    print("Generating 3D Solana token (lit/active)...")
    result_lit = None
    for key in [API_KEY, BACKUP_KEY]:
        try:
            result_lit = call_gemini(lit_prompt, key)
            print(f"  Got image: {result_lit.size}")
            break
        except Exception as e:
            print(f"  Error with key ...{key[-6:]}: {e}")

    if result_lit is None:
        print("FAILED lit version, using idle for both")
        result_lit = result

    processed_lit = remove_background(result_lit)
    processed_lit = crop_to_content(processed_lit)
    processed_lit = center_on_canvas(processed_lit, 512, 512)

    lit_debug = os.path.join(DEBUG_DIR, "token_lit_processed.png")
    processed_lit.save(lit_debug, "PNG")
    print(f"  Saved: {lit_debug}")

    # Save assets
    idle_path = os.path.join(ASSETS_DIR, "solana_coin", "idle.png")
    lit_path = os.path.join(ASSETS_DIR, "solana_coin", "lit.png")

    os.makedirs(os.path.dirname(idle_path), exist_ok=True)
    processed.save(idle_path, "PNG")
    processed_lit.save(lit_path, "PNG")

    print(f"\n  Idle asset: {idle_path} ({processed.size})")
    print(f"  Lit asset: {lit_path} ({processed_lit.size})")
    print("\nDone!")


if __name__ == "__main__":
    main()
