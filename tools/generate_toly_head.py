"""
Generate Toly head rotation sprite sheet using Gemini image generation.

Downloads the reference cartoon of Toly, then generates individual rotation
frames (front, 3/4, side, back, etc.) and assembles into a sprite sheet.
"""

import base64
import json
import math
import os
import sys
import urllib.request
import urllib.error
from io import BytesIO

try:
    from PIL import Image, ImageDraw
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

# Sprite sheet config
CELL = 256  # pixels per frame
COLS = 8
ROWS = 4
TOTAL_FRAMES = COLS * ROWS  # 32 frames for full 360 rotation


def download_reference():
    """Download the reference image of Toly."""
    print("Downloading reference image...")
    req = urllib.request.Request(REFERENCE_URL, headers={
        "User-Agent": "Mozilla/5.0"
    })
    with urllib.request.urlopen(req, timeout=30) as resp:
        data = resp.read()
    img = Image.open(BytesIO(data))
    print(f"  Reference image: {img.size}")
    return img


def image_to_base64(img, fmt="JPEG"):
    """Convert PIL Image to base64 string."""
    buf = BytesIO()
    img.save(buf, format=fmt)
    return base64.b64encode(buf.getvalue()).decode("utf-8")


def call_gemini_with_image(prompt, ref_image, api_key):
    """Call Gemini API with a reference image and text prompt."""
    ref_b64 = image_to_base64(ref_image)

    payload = {
        "contents": [{
            "parts": [
                {
                    "inlineData": {
                        "mimeType": "image/jpeg",
                        "data": ref_b64,
                    }
                },
                {"text": prompt},
            ]
        }],
        "generationConfig": {
            "responseModalities": ["IMAGE", "TEXT"],
            "temperature": 0.6,
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
    """Remove white/light background to transparency."""
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
    """Crop to non-transparent content."""
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
    """Center image on a square transparent canvas."""
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    scale = min(size / img.width, size / img.height) * 0.88
    new_w = int(img.width * scale)
    new_h = int(img.height * scale)
    resized = img.resize((new_w, new_h), Image.LANCZOS)
    x = (size - new_w) // 2
    y = (size - new_h) // 2
    canvas.paste(resized, (x, y), resized)
    return canvas


# The rotation angles we need and their descriptions
# 0° = front, 90° = left side, 180° = back, 270° = right side
VIEWS = [
    (0,   "front view, looking directly at camera"),
    (45,  "3/4 view turned slightly to the left, showing left side of face"),
    (90,  "left profile view, showing left side of face"),
    (135, "3/4 back view turned away to the left, showing back-left of head"),
    (180, "back of head view, showing hair/hat from behind"),
    (225, "3/4 back view turned away to the right, showing back-right of head"),
    (270, "right profile view, showing right side of face"),
    (315, "3/4 view turned slightly to the right, showing right side of face"),
]


def generate_view(ref_img, angle, view_desc, idx):
    """Generate a single view of the Toly head at a given angle."""
    is_back = 135 <= angle <= 225

    if is_back:
        back_detail = (
            "Show the BACK of the head - no face visible. Show the back of the cap/hat, "
            "the back of the hair, the back of the neck. This is what someone sees when "
            "looking at the back of this character's head."
        )
    else:
        back_detail = ""

    prompt = (
        f"Look at the cartoon character on the LEFT side of this reference image. "
        f"Generate a NEW image of JUST this character's head and upper shoulders, "
        f"drawn in the same cartoon art style, same colors, same outfit (cap, etc). "
        f"\n\nGenerate the character from this angle: {view_desc}. "
        f"The character is rotating around the Y-axis (like standing on a turntable). "
        f"{back_detail}"
        f"\n\nIMPORTANT RULES:"
        f"\n- Draw ONLY the head/shoulders, centered on a plain white background"
        f"\n- Keep the EXACT same art style, colors, and proportions as the reference"
        f"\n- The head should fill most of the image"
        f"\n- No text, no labels, no extra objects"
        f"\n- Clean, crisp cartoon style with bold outlines"
    )

    print(f"  Generating view {idx+1}/8: {angle}° ({view_desc[:40]}...)")

    for key in [API_KEY, BACKUP_KEY]:
        try:
            result = call_gemini_with_image(prompt, ref_img, key)
            print(f"    Got image: {result.size}")
            return result
        except Exception as e:
            print(f"    Error with key ...{key[-6:]}: {e}")

    return None


def interpolate_frames(frame_a, frame_b, steps):
    """Create intermediate frames by cross-fading between two key frames."""
    frames = []
    for i in range(steps):
        t = (i + 1) / (steps + 1)
        blended = Image.blend(frame_a.convert("RGBA"), frame_b.convert("RGBA"), t)
        frames.append(blended)
    return frames


def main():
    os.makedirs(DEBUG_DIR, exist_ok=True)

    # Download reference
    ref_img = download_reference()
    ref_path = os.path.join(DEBUG_DIR, "reference.jpg")
    ref_img.save(ref_path)
    print(f"  Saved reference to {ref_path}")

    # Generate 8 key views
    key_frames = []
    for idx, (angle, desc) in enumerate(VIEWS):
        result = generate_view(ref_img, angle, desc, idx)
        if result is None:
            print(f"  FAILED to generate {angle}° view, will interpolate")
            key_frames.append(None)
            continue

        # Post-process
        processed = remove_background(result)
        processed = crop_to_content(processed)
        processed = center_on_canvas(processed, CELL)

        # Save debug frame
        debug_path = os.path.join(DEBUG_DIR, f"frame_{idx:02d}_{angle}deg.png")
        processed.save(debug_path, "PNG")

        key_frames.append(processed)

    # Fill any failed frames by duplicating nearest
    for i in range(len(key_frames)):
        if key_frames[i] is None:
            # Find nearest non-None frame
            for offset in range(1, len(key_frames)):
                if key_frames[(i + offset) % len(key_frames)] is not None:
                    key_frames[i] = key_frames[(i + offset) % len(key_frames)]
                    break

    if all(f is None for f in key_frames):
        print("ERROR: No frames generated at all!")
        sys.exit(1)

    # Interpolate between key frames to get 32 total frames
    # 8 key frames -> 3 interpolated frames between each pair + key frame = 32
    all_frames = []
    interp_per_gap = (TOTAL_FRAMES // len(key_frames)) - 1  # 3 between each

    for i in range(len(key_frames)):
        all_frames.append(key_frames[i])
        next_i = (i + 1) % len(key_frames)
        tweens = interpolate_frames(key_frames[i], key_frames[next_i], interp_per_gap)
        all_frames.extend(tweens)

    # Trim to exact frame count if needed
    all_frames = all_frames[:TOTAL_FRAMES]
    print(f"\nTotal frames: {len(all_frames)}")

    # Assemble sprite sheet
    sheet = Image.new("RGBA", (COLS * CELL, ROWS * CELL), (0, 0, 0, 0))
    for i, frame in enumerate(all_frames):
        col = i % COLS
        row = i // COLS
        sheet.paste(frame, (col * CELL, row * CELL), frame)

    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    sheet.save(OUTPUT_PATH, "PNG")
    print(f"\nSprite sheet saved: {OUTPUT_PATH} ({sheet.size[0]}x{sheet.size[1]})")
    print("Done!")


if __name__ == "__main__":
    main()
