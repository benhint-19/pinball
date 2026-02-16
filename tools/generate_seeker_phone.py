"""
Generate a 3D smartphone being pushed out by a robotic arm for the pinball board.
The phone displays the Solana logo on its screen.
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

ASSETS_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "packages", "pinball_components", "assets", "images"
)
DEBUG_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "phone_debug")


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

    # Generate the 3D phone with robotic arm - retracted state
    retracted_prompt = (
        "Create a 3D rendered scene of a robotic mechanical arm holding a smartphone. "
        "\n\nCRITICAL REQUIREMENTS:\n"
        "- A metallic ROBOTIC ARM extends from the LEFT side, gripping a modern smartphone\n"
        "- The arm is mechanical/cyberpunk style with joints, pistons, and metallic segments\n"
        "- The arm is in a RETRACTED position, pulled back to the left\n"
        "- The smartphone screen faces the viewer and displays the SOLANA LOGO:\n"
        "  Three diagonal parallel bars forming an 'S', gradient from teal (#14F195) to purple (#9945FF)\n"
        "- The phone screen has a dark purple/black background with the glowing Solana logo\n"
        "- The phone has a sleek dark bezel with slight metallic edge highlights\n"
        "- The whole scene is viewed from ABOVE at about 30-40 degrees (like looking down at a pinball table)\n"
        "- The arm comes from the left edge heading right\n"
        "- Clean 3D render style like a video game asset\n"
        "- Plain white background\n"
        "- The composition should be WIDER than tall (landscape orientation)\n"
        "- Include subtle purple/teal glow emanating from the phone screen\n"
    )

    print("Generating 3D SeekerPhone with robotic arm (retracted)...")
    result = None
    for key in [API_KEY, BACKUP_KEY]:
        try:
            result = call_gemini(retracted_prompt, key)
            print(f"  Got image: {result.size}")
            break
        except Exception as e:
            print(f"  Error with key ...{key[-6:]}: {e}")

    if result is None:
        print("FAILED retracted version!")
        sys.exit(1)

    raw_path = os.path.join(DEBUG_DIR, "phone_retracted_raw.png")
    result.save(raw_path, "PNG")

    processed = remove_background(result)
    processed = crop_to_content(processed)
    processed = center_on_canvas(processed, 512, 512)

    debug_path = os.path.join(DEBUG_DIR, "phone_retracted_processed.png")
    processed.save(debug_path, "PNG")
    print(f"  Saved: {debug_path}")

    # Generate extended state (arm pushed out further)
    extended_prompt = (
        "Create a 3D rendered scene of a robotic mechanical arm FULLY EXTENDED holding a smartphone. "
        "\n\nCRITICAL REQUIREMENTS:\n"
        "- A metallic ROBOTIC ARM extends from the LEFT side, gripping a modern smartphone\n"
        "- The arm is mechanical/cyberpunk style with joints, pistons, and metallic segments\n"
        "- The arm is FULLY EXTENDED to the right, stretched out\n"
        "- The smartphone screen faces the viewer and displays the SOLANA LOGO:\n"
        "  Three diagonal parallel bars forming an 'S', gradient from teal (#14F195) to purple (#9945FF)\n"
        "- The phone screen has a dark purple/black background with the BRIGHTLY GLOWING Solana logo\n"
        "- The phone screen is glowing intensely with teal and purple light\n"
        "- The phone has a sleek dark bezel with slight metallic edge highlights\n"
        "- The whole scene is viewed from ABOVE at about 30-40 degrees (like looking down at a pinball table)\n"
        "- The arm comes from the left edge heading right\n"
        "- Clean 3D render style like a video game asset\n"
        "- Plain white background\n"
        "- The composition should be WIDER than tall (landscape orientation)\n"
        "- Strong teal/purple glow and bloom effect from the phone screen\n"
    )

    print("Generating 3D SeekerPhone with robotic arm (extended)...")
    result_ext = None
    for key in [API_KEY, BACKUP_KEY]:
        try:
            result_ext = call_gemini(extended_prompt, key)
            print(f"  Got image: {result_ext.size}")
            break
        except Exception as e:
            print(f"  Error with key ...{key[-6:]}: {e}")

    if result_ext is None:
        print("FAILED extended version, using retracted for both")
        result_ext = result

    processed_ext = remove_background(result_ext)
    processed_ext = crop_to_content(processed_ext)
    processed_ext = center_on_canvas(processed_ext, 512, 512)

    ext_debug = os.path.join(DEBUG_DIR, "phone_extended_processed.png")
    processed_ext.save(ext_debug, "PNG")
    print(f"  Saved: {ext_debug}")

    # Save assets
    phone_dir = os.path.join(ASSETS_DIR, "seeker_phone")
    os.makedirs(phone_dir, exist_ok=True)

    retracted_path = os.path.join(phone_dir, "retracted.png")
    extended_path = os.path.join(phone_dir, "extended.png")

    processed.save(retracted_path, "PNG")
    processed_ext.save(extended_path, "PNG")

    print(f"\n  Retracted asset: {retracted_path} ({processed.size})")
    print(f"  Extended asset: {extended_path} ({processed_ext.size})")
    print("\nDone!")


if __name__ == "__main__":
    main()
