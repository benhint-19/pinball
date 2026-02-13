"""
Replace Google characters and I/O PINBALL text with Solana branding.
Keeps the sky, clouds, frame, speakers, display all intact.
Covers characters with sky-colored paint sampled from the actual image,
then overlays Solana logo + text.
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np

MARQUEE_PATH = r'D:\dev\seeker-pinball\packages\pinball_components\assets\images\backbox\marquee.png'

PURPLE = (153, 69, 255)
GREEN = (20, 241, 149)

orig = Image.open(MARQUEE_PATH).convert('RGBA')
W, H = orig.size
orig_arr = np.array(orig)

# Classify pixels
red_ch = orig_arr[:,:,0].astype(float)
green_ch = orig_arr[:,:,1].astype(float)
blue_ch = orig_arr[:,:,2].astype(float)
brightness = np.max(orig_arr[:,:,:3], axis=2).astype(float)

# Sky: blue-dominant and bright
is_sky = (blue_ch > 130) & ((blue_ch - red_ch) > 20) & (brightness > 120)
# Clouds: bright and low saturation
sat = brightness - np.min(orig_arr[:,:,:3], axis=2).astype(float)
is_cloud = (brightness > 190) & (sat < 60)
is_background = is_sky | is_cloud

# ---- Define cover regions (generous bounding boxes) ----
# Based on precise pixel analysis of character positions
cover_regions = [
    # "I/O" text top-left
    (195, 125, 300, 170),
    # "PINBALL" text top-right
    (1625, 125, 1940, 170),
    # Yellow flame / Sparky character (center-left) - expanded
    (430, 390, 840, 825),
    # Dino character (massive, right side) - expanded
    (1230, 530, 1865, 1105),
    # Android / ground elements (bottom-left) - expanded
    (215, 905, 645, 1105),
    # Light rays / effects (bottom-center)
    (880, 930, 1105, 1050),
    # Small floating elements near flame
    (710, 440, 775, 510),
    # Bird/Dash elements in center
    (825, 435, 885, 540),
]

# ---- Build a mask of all pixels to cover ----
cover_mask = np.zeros((H, W), dtype=bool)
MARGIN = 8
for x1, y1, x2, y2 in cover_regions:
    y1c = max(0, y1 - MARGIN)
    y2c = min(H, y2 + MARGIN)
    x1c = max(0, x1 - MARGIN)
    x2c = min(W, x2 + MARGIN)
    cover_mask[y1c:y2c, x1c:x2c] = True

# Mark safe sky pixels (background pixels NOT in any cover region)
safe_sky = is_background & ~cover_mask

# ---- Step 1: Fill covered pixels with interpolated sky colors ----
# For each row, use np.interp to interpolate sky colors across covered areas.
arr = orig_arr.copy()

print("Filling covered areas with sampled sky...")
for y in range(H):
    if not np.any(cover_mask[y, :]):
        continue

    # Get safe sky pixel positions and colors in this row
    safe_x = np.where(safe_sky[y, :])[0]
    ref_y = y
    if len(safe_x) < 2:
        # Try nearby rows
        for dy in range(1, 40):
            for yy in [y - dy, y + dy]:
                if 0 <= yy < H:
                    safe_x_try = np.where(safe_sky[yy, :])[0]
                    if len(safe_x_try) >= 2:
                        safe_x = safe_x_try
                        ref_y = yy
                        break
            if len(safe_x) >= 2:
                break
        if len(safe_x) < 2:
            continue

    safe_colors = orig_arr[ref_y, safe_x, :3].astype(float)

    # Vectorized interpolation for all covered pixels in this row
    covered_x = np.where(cover_mask[y, :])[0]
    if len(covered_x) == 0:
        continue

    # np.interp for each color channel
    for c in range(3):
        arr[y, covered_x, c] = np.interp(
            covered_x.astype(float),
            safe_x.astype(float),
            safe_colors[:, c]
        ).astype(np.uint8)
    arr[y, covered_x, 3] = 255

print("Covered areas filled")

# ---- Step 2: Feather edges ----
# Use Gaussian blur on just the boundary
FEATHER = 10
feather_mask = np.zeros((H, W), dtype=np.float32)
for x1, y1, x2, y2 in cover_regions:
    x1b = max(0, x1 - MARGIN)
    y1b = max(0, y1 - MARGIN)
    x2b = min(W, x2 + MARGIN)
    y2b = min(H, y2 + MARGIN)
    for y in range(max(0, y1b - FEATHER), min(H, y2b + FEATHER)):
        for x in range(max(0, x1b - FEATHER), min(W, x2b + FEATHER)):
            dx = max(0, x1b - x, x - x2b + 1)
            dy = max(0, y1b - y, y - y2b + 1)
            dist = (dx**2 + dy**2)**0.5
            if dist == 0:
                feather_mask[y, x] = 1.0
            elif dist < FEATHER:
                feather_mask[y, x] = max(feather_mask[y, x], 1.0 - dist / FEATHER)

# Blend: filled * mask + original * (1-mask)
for c in range(4):
    arr[:, :, c] = (arr[:, :, c].astype(float) * feather_mask +
                    orig_arr[:, :, c].astype(float) * (1 - feather_mask)).astype(np.uint8)

img = Image.fromarray(arr, 'RGBA')
draw = ImageDraw.Draw(img)
print("Edges feathered")

# ---- Step 3: Overlay Solana logo ----
overlay = Image.new('RGBA', (W, H), (0, 0, 0, 0))
od = ImageDraw.Draw(overlay)

center_x = W // 2
logo_w = 420
logo_x = center_x - logo_w // 2
logo_y = 350
bar_h = int(logo_w * 0.11)
gap = int(bar_h * 0.55)
slant = int(logo_w * 0.14)

def draw_bar(yp, fwd=True):
    if fwd:
        p = [(logo_x+slant,yp),(logo_x+logo_w,yp),
             (logo_x+logo_w-slant,yp+bar_h),(logo_x,yp+bar_h)]
    else:
        p = [(logo_x,yp),(logo_x+logo_w-slant,yp),
             (logo_x+logo_w,yp+bar_h),(logo_x+slant,yp+bar_h)]
    od.polygon(p, fill=(255,255,255,255))

b1y = logo_y
b2y = logo_y + bar_h + gap
b3y = logo_y + 2 * (bar_h + gap)

draw_bar(b1y, True)
draw_bar(b2y, False)
draw_bar(b3y, True)

# Apply gradient to logo (purple bottom-left -> green top-right)
ov_arr = np.array(overlay)
lt, lb = b1y - 2, b3y + bar_h + 2
ll, lr = logo_x - 2, logo_x + logo_w + 2
for y in range(max(0, lt), min(H, lb)):
    for x in range(max(0, ll), min(W, lr)):
        r, g, b, a = ov_arr[y, x]
        if r > 200 and a > 200:
            dm = (lr - ll) + (lb - lt)
            dp = (x - ll) + (lb - y)
            t = max(0.0, min(1.0, dp / dm))
            ov_arr[y, x] = [
                int(PURPLE[0]*(1-t) + GREEN[0]*t),
                int(PURPLE[1]*(1-t) + GREEN[1]*t),
                int(PURPLE[2]*(1-t) + GREEN[2]*t), 255]

overlay = Image.fromarray(ov_arr, 'RGBA')

# Drop shadow behind logo
shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
sd = ImageDraw.Draw(shadow)
for yp, fwd in [(b1y, True), (b2y, False), (b3y, True)]:
    if fwd:
        p = [(logo_x+slant+4,yp+4),(logo_x+logo_w+4,yp+4),
             (logo_x+logo_w-slant+4,yp+bar_h+4),(logo_x+4,yp+bar_h+4)]
    else:
        p = [(logo_x+4,yp+4),(logo_x+logo_w-slant+4,yp+4),
             (logo_x+logo_w+4,yp+bar_h+4),(logo_x+slant+4,yp+bar_h+4)]
    sd.polygon(p, fill=(0, 0, 0, 60))
shadow = shadow.filter(ImageFilter.GaussianBlur(radius=6))

img = Image.alpha_composite(img, shadow)
img = Image.alpha_composite(img, overlay)
draw = ImageDraw.Draw(img)
print("Solana logo overlaid")

# ---- Step 4: Text ----
for fp in ['C:/Windows/Fonts/segoeuib.ttf', 'C:/Windows/Fonts/arialbd.ttf']:
    try:
        ft = ImageFont.truetype(fp, 90)
        fs = ImageFont.truetype(fp, 45)
        print(f'Font: {fp}')
        break
    except:
        continue

text_y = b3y + bar_h + 30

# "SEEKER" - shadow then white, then gradient
draw.text((center_x + 3, text_y + 3), 'SEEKER', font=ft,
          fill=(0, 0, 0, 80), anchor='mt')
draw.text((center_x, text_y), 'SEEKER', font=ft,
          fill=(255, 255, 255, 255), anchor='mt')

# Apply gradient to SEEKER text
bb = ft.getbbox('SEEKER')
tw, th = bb[2] - bb[0], bb[3] - bb[1]
tl = center_x - tw // 2
arr = np.array(img)
for y in range(max(0, int(text_y) - 5), min(H, int(text_y) + th + 10)):
    for x in range(max(0, tl - 10), min(W, tl + tw + 10)):
        r, g, b, a = arr[y, x]
        if r > 220 and g > 220 and b > 220 and a > 200:
            t = max(0.0, min(1.0, (x - tl) / max(tw, 1)))
            arr[y, x] = [
                int(PURPLE[0]*(1-t) + GREEN[0]*t),
                int(PURPLE[1]*(1-t) + GREEN[1]*t),
                int(PURPLE[2]*(1-t) + GREEN[2]*t), 255]
img = Image.fromarray(arr, 'RGBA')
draw = ImageDraw.Draw(img)

# "PINBALL" below
ty2 = int(text_y) + th + 8
draw.text((center_x + 2, ty2 + 2), 'PINBALL', font=fs,
          fill=(0, 0, 0, 60), anchor='mt')
draw.text((center_x, ty2), 'PINBALL', font=fs,
          fill=(GREEN[0], GREEN[1], GREEN[2], 240), anchor='mt')

# ---- Save ----
img.save(MARQUEE_PATH, 'PNG')
print('Done!')
