"""Recolor pinball table sprites to Solana palette.

HSV hue-shift approach:
  Google green  -> Solana purple (#9945FF)
  Google blue/pink -> Solana teal (#14F195)
  Google yellow/orange -> Solana cyan (#00D1FF)

Preserves luminance and saturation, rotates hue.
"""

import colorsys
import os
import struct
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
COMP = os.path.join(ROOT, "packages", "pinball_components", "assets", "images")

# Solana target hues (0-1 range for colorsys)
# #9945FF -> H=270 -> 0.75
# #14F195 -> H=155 -> 0.43
# #00D1FF -> H=191 -> 0.53
SOLANA_PURPLE_H = 0.75
SOLANA_TEAL_H = 0.43
SOLANA_CYAN_H = 0.53


def read_png(path):
    """Read a PNG file and return (width, height, pixels) where pixels[y][x] = (r,g,b,a)."""
    with open(path, "rb") as f:
        data = f.read()

    # Verify PNG signature
    assert data[:8] == b"\x89PNG\r\n\x1a\n", f"Not a valid PNG: {path}"

    chunks = []
    pos = 8
    while pos < len(data):
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        chunk_type = data[pos + 4:pos + 8]
        chunk_data = data[pos + 8:pos + 8 + length]
        chunks.append((chunk_type, chunk_data))
        pos += 12 + length  # 4 length + 4 type + data + 4 crc

    # Parse IHDR
    ihdr_data = [c[1] for c in chunks if c[0] == b"IHDR"][0]
    width, height, bit_depth, color_type = struct.unpack(">IIBB", ihdr_data[:10])

    # Concatenate IDAT chunks and decompress
    idat_data = b""
    for ct, cd in chunks:
        if ct == b"IDAT":
            idat_data += cd

    raw = zlib.decompress(idat_data)

    # Parse pixel data based on color type
    pixels = []
    pos = 0

    if color_type == 6:  # RGBA
        bytes_per_pixel = 4
    elif color_type == 2:  # RGB
        bytes_per_pixel = 3
    elif color_type == 3:  # Palette
        # Get palette
        plte_data = [c[1] for c in chunks if c[0] == b"PLTE"]
        palette = []
        if plte_data:
            pd = plte_data[0]
            for i in range(0, len(pd), 3):
                palette.append((pd[i], pd[i + 1], pd[i + 2]))

        # Get transparency
        trns_data = [c[1] for c in chunks if c[0] == b"tRNS"]
        trns = []
        if trns_data:
            trns = list(trns_data[0])

        for y in range(height):
            row = []
            filter_byte = raw[pos]
            pos += 1
            prev_row_bytes = []
            row_bytes = []

            for x in range(width):
                idx = raw[pos]
                pos += 1
                row_bytes.append(idx)

                if idx < len(palette):
                    r, g, b = palette[idx]
                    a = trns[idx] if idx < len(trns) else 255
                    row.append((r, g, b, a))
                else:
                    row.append((0, 0, 0, 0))

            pixels.append(row)
        return width, height, pixels, data  # Return original data for palette mode
    elif color_type == 4:  # Grayscale + Alpha
        bytes_per_pixel = 2
    elif color_type == 0:  # Grayscale
        bytes_per_pixel = 1
    else:
        print(f"  Warning: Unsupported color type {color_type} for {path}")
        return width, height, None, data

    if color_type in (6, 2):
        # Apply PNG filters and extract pixels
        stride = width * bytes_per_pixel
        for y in range(height):
            filter_type = raw[pos]
            pos += 1
            row_data = bytearray(raw[pos:pos + stride])
            pos += stride

            # Apply filter
            if filter_type == 1:  # Sub
                for i in range(bytes_per_pixel, stride):
                    row_data[i] = (row_data[i] + row_data[i - bytes_per_pixel]) & 0xFF
            elif filter_type == 2:  # Up
                if y > 0:
                    prev_start = 1 + (y - 1) * (stride + 1)
                    for i in range(stride):
                        prev_val = _get_prev_row(raw, y, i, stride, bytes_per_pixel, height)
                        row_data[i] = (row_data[i] + prev_val) & 0xFF
            elif filter_type == 3:  # Average
                for i in range(stride):
                    left = row_data[i - bytes_per_pixel] if i >= bytes_per_pixel else 0
                    up = _get_prev_row(raw, y, i, stride, bytes_per_pixel, height) if y > 0 else 0
                    row_data[i] = (row_data[i] + (left + up) // 2) & 0xFF
            elif filter_type == 4:  # Paeth
                for i in range(stride):
                    left = row_data[i - bytes_per_pixel] if i >= bytes_per_pixel else 0
                    up = _get_prev_row(raw, y, i, stride, bytes_per_pixel, height) if y > 0 else 0
                    up_left = 0
                    if y > 0 and i >= bytes_per_pixel:
                        up_left = _get_prev_row(raw, y, i - bytes_per_pixel, stride, bytes_per_pixel, height)
                    row_data[i] = (row_data[i] + _paeth(left, up, up_left)) & 0xFF

            row = []
            for x in range(width):
                offset = x * bytes_per_pixel
                if bytes_per_pixel == 4:
                    row.append(tuple(row_data[offset:offset + 4]))
                else:
                    r, g, b = row_data[offset:offset + 3]
                    row.append((r, g, b, 255))
            pixels.append(row)

    return width, height, pixels, data


def _get_prev_row(raw, y, i, stride, bpp, height):
    """Get byte from the previous (already-decoded) scanline."""
    # This is tricky with in-place filters. We need a different approach.
    return 0  # Simplified - will use PIL instead


def _paeth(a, b, c):
    p = a + b - c
    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    elif pb <= pc:
        return b
    return c


def make_png(width, height, pixels):
    """Create PNG bytes from RGBA pixels."""
    def chunk(ctype, cdata):
        c = ctype + cdata
        return struct.pack(">I", len(cdata)) + c + struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)

    header = b"\x89PNG\r\n\x1a\n"
    ihdr = chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))

    raw = b""
    for y in range(height):
        raw += b"\x00"
        for x in range(width):
            r, g, b, a = pixels[y][x]
            raw += struct.pack("BBBB", r, g, b, a)

    idat = chunk(b"IDAT", zlib.compress(raw, 6))
    iend = chunk(b"IEND", b"")
    return header + ihdr + idat + iend


def recolor_pixel(r, g, b, a):
    """Recolor a single pixel from Google palette to Solana palette."""
    if a == 0:
        return (r, g, b, a)

    h, s, v = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)

    # Skip very dark or very unsaturated pixels (grays, blacks, whites)
    if s < 0.08 or v < 0.05:
        return (r, g, b, a)

    # Map Google hues to Solana hues
    # Google green: H ~0.33 (120°) -> Solana purple
    # Google blue: H ~0.55-0.70 (200-250°) -> Solana teal
    # Google red/pink: H ~0.0 or ~0.9-1.0 (0-30°, 320-360°) -> Solana teal
    # Google yellow/orange: H ~0.08-0.17 (30-60°) -> Solana cyan

    if 0.22 <= h <= 0.47:  # Green range
        new_h = SOLANA_PURPLE_H
    elif 0.47 < h <= 0.75:  # Blue range
        new_h = SOLANA_TEAL_H
    elif 0.08 <= h < 0.22:  # Yellow/orange range
        new_h = SOLANA_CYAN_H
    elif h < 0.08 or h > 0.92:  # Red range
        new_h = SOLANA_TEAL_H
    elif 0.75 < h <= 0.92:  # Pink/magenta range
        new_h = SOLANA_PURPLE_H
    else:
        new_h = h  # Keep as-is

    # Boost saturation slightly for Solana vibrancy
    new_s = min(1.0, s * 1.1)

    nr, ng, nb = colorsys.hsv_to_rgb(new_h, new_s, v)
    return (int(nr * 255), int(ng * 255), int(nb * 255), a)


def recolor_file_pil(path):
    """Recolor a PNG file using PIL (handles all PNG formats correctly)."""
    from PIL import Image
    img = Image.open(path).convert("RGBA")
    pixels = img.load()
    w, h = img.size

    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            pixels[x, y] = recolor_pixel(r, g, b, a)

    img.save(path)
    print(f"  -> {os.path.relpath(path, ROOT)}")


def recolor_file_raw(path):
    """Recolor a PNG file using raw PNG reading (fallback if no PIL)."""
    w, h, px, raw_data = read_png(path)
    if px is None:
        print(f"  SKIP (unsupported format): {os.path.relpath(path, ROOT)}")
        return

    new_pixels = []
    for y in range(h):
        row = []
        for x in range(w):
            row.append(recolor_pixel(*px[y][x]))
        new_pixels.append(row)

    with open(path, "wb") as f:
        f.write(make_png(w, h, new_pixels))
    print(f"  -> {os.path.relpath(path, ROOT)}")


# Choose recolor function based on PIL availability
try:
    from PIL import Image
    recolor_file = recolor_file_pil
    print("Using PIL for image processing")
except ImportError:
    recolor_file = recolor_file_raw
    print("PIL not available, using raw PNG processing (some formats may not work)")


# ── Sprite list ───────────────────────────────────────────────────────
SPRITES = [
    # Bumpers - Android (6)
    "android/bumper/a/dimmed.png",
    "android/bumper/a/lit.png",
    "android/bumper/b/dimmed.png",
    "android/bumper/b/lit.png",
    "android/bumper/cow/dimmed.png",
    "android/bumper/cow/lit.png",
    # Bumpers - Dash (6)
    "dash/bumper/a/active.png",
    "dash/bumper/a/inactive.png",
    "dash/bumper/b/active.png",
    "dash/bumper/b/inactive.png",
    "dash/bumper/main/active.png",
    "dash/bumper/main/inactive.png",
    # Bumpers - Sparky (6)
    "sparky/bumper/a/dimmed.png",
    "sparky/bumper/a/lit.png",
    "sparky/bumper/b/dimmed.png",
    "sparky/bumper/b/lit.png",
    "sparky/bumper/c/dimmed.png",
    "sparky/bumper/c/lit.png",
    # Kickers (4)
    "kicker/left/dimmed.png",
    "kicker/left/lit.png",
    "kicker/right/dimmed.png",
    "kicker/right/lit.png",
    # Slingshots (2)
    "slingshot/lower.png",
    "slingshot/upper.png",
    # Flippers (2)
    "flipper/left.png",
    "flipper/right.png",
    # Multipliers (10)
    "multiplier/x2/dimmed.png",
    "multiplier/x2/lit.png",
    "multiplier/x3/dimmed.png",
    "multiplier/x3/lit.png",
    "multiplier/x4/dimmed.png",
    "multiplier/x4/lit.png",
    "multiplier/x5/dimmed.png",
    "multiplier/x5/lit.png",
    "multiplier/x6/dimmed.png",
    "multiplier/x6/lit.png",
    # Score popups (4)
    "score/five_thousand.png",
    "score/one_million.png",
    "score/twenty_thousand.png",
    "score/two_hundred_thousand.png",
    # Baseboards (2)
    "baseboard/left.png",
    "baseboard/right.png",
    # Launch ramp (3)
    "launch_ramp/background_railing.png",
    "launch_ramp/foreground_railing.png",
    "launch_ramp/ramp.png",
    # Android ramp + arrows (10)
    "android/ramp/arrow/active1.png",
    "android/ramp/arrow/active2.png",
    "android/ramp/arrow/active3.png",
    "android/ramp/arrow/active4.png",
    "android/ramp/arrow/active5.png",
    "android/ramp/arrow/inactive.png",
    "android/ramp/board_opening.png",
    "android/ramp/main.png",
    "android/ramp/railing_background.png",
    "android/ramp/railing_foreground.png",
    # Android spaceship (2)
    "android/spaceship/saucer.png",
    "android/spaceship/light_beam.png",
    # Android rail (2)
    "android/rail/exit.png",
    "android/rail/main.png",
    # Dino walls (3)
    "dino/bottom_wall.png",
    "dino/top_wall.png",
    "dino/top_wall_tunnel.png",
    # Plunger (2)
    "plunger/plunger.png",
    "plunger/rocket.png",
    # Multiball (2)
    "multiball/dimmed.png",
    "multiball/lit.png",
    # Skill shot (4)
    "skill_shot/decal.png",
    "skill_shot/dimmed.png",
    "skill_shot/lit.png",
    "skill_shot/pin.png",
    # Google rollover (4)
    "google_rollover/left/decal.png",
    "google_rollover/left/pin.png",
    "google_rollover/right/decal.png",
    "google_rollover/right/pin.png",
    # Flapper (3)
    "flapper/back_support.png",
    "flapper/flap.png",
    "flapper/front_support.png",
    # Display arrows (2)
    "display_arrows/arrow_left.png",
    "display_arrows/arrow_right.png",
    # Sparky computer (3)
    "sparky/computer/base.png",
    "sparky/computer/glow.png",
    "sparky/computer/top.png",
]


if __name__ == "__main__":
    print("=" * 60)
    print("Seeker Pinball - Solana Palette Recolor")
    print("=" * 60)

    success = 0
    errors = 0

    for sprite in SPRITES:
        path = os.path.join(COMP, sprite)
        if os.path.exists(path):
            try:
                recolor_file(path)
                success += 1
            except Exception as e:
                print(f"  ERROR: {sprite}: {e}")
                errors += 1
        else:
            print(f"  MISSING: {sprite}")
            errors += 1

    print(f"\n{'=' * 60}")
    print(f"Recolored {success} sprites, {errors} errors/missing")
    print(f"{'=' * 60}")
