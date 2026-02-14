"""
Replace marquee artwork with Solana-themed design.
Fills the exact inner frame polygon with a dark gradient,
Solana logo, and text. Frame, display panel, speakers preserved.
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np

MARQUEE_PATH = r'D:\dev\seeker-pinball\packages\pinball_components\assets\images\backbox\marquee.png'

PURPLE = (153, 69, 255)
GREEN = (20, 241, 149)

orig = Image.open(MARQUEE_PATH).convert('RGBA')
W, H = orig.size
orig_arr = np.array(orig)
brightness = np.max(orig_arr[:,:,:3], axis=2)

# ---- Map exact inner frame edges ----
# Scan each row for first/last bright pixel (artwork boundary)
top_y = 133
bot_y = 1143
INSET = 3  # pixels inset from frame edge for clean boundary

edges = {}
for y in range(top_y, bot_y + 1):
    row_bright = brightness[y, :] > 100
    indices = np.where(row_bright)[0]
    if len(indices) > 0:
        edges[y] = (indices[0] + INSET, indices[-1] - INSET)

# ---- Create artwork mask (exact trapezoid shape) ----
mask = Image.new('L', (W, H), 0)
md = ImageDraw.Draw(mask)
# Build polygon from edges
left_pts = [(edges[y][0], y) for y in range(top_y, bot_y + 1) if y in edges]
right_pts = [(edges[y][1], y) for y in range(bot_y, top_y - 1, -1) if y in edges]
polygon = left_pts + right_pts
md.polygon(polygon, fill=255)
mask_arr = np.array(mask)

print(f"Artwork polygon: {len(polygon)} points, y={top_y}-{bot_y}")

# ---- Create new artwork layer ----
art = Image.new('RGBA', (W, H), (0, 0, 0, 0))
art_arr = np.array(art)

# Dark gradient background: deep navy-purple
# Top: darker, Bottom: slightly lighter, with radial center glow
for y in range(top_y, bot_y + 1):
    if y not in edges:
        continue
    left, right = edges[y]
    t_y = (y - top_y) / max(bot_y - top_y, 1)  # 0=top, 1=bottom

    for x in range(left, right + 1):
        t_x = (x - left) / max(right - left, 1)  # 0=left, 1=right

        # Base dark gradient (top to bottom)
        base_r = int(8 + 12 * t_y)
        base_g = int(5 + 10 * t_y)
        base_b = int(25 + 20 * t_y)

        # Radial center glow (subtle purple)
        cx = (left + right) / 2
        cy = (top_y + bot_y) * 0.42  # slightly above center
        dx = (x - cx) / ((right - left) / 2)
        dy = (y - cy) / ((bot_y - top_y) / 2)
        dist = (dx*dx + dy*dy) ** 0.5
        glow = max(0, 1 - dist * 0.9) * 0.3

        r = min(255, int(base_r + 40 * glow))
        g = min(255, int(base_g + 15 * glow))
        b = min(255, int(base_b + 60 * glow))

        art_arr[y, x] = [r, g, b, 255]

art = Image.fromarray(art_arr, 'RGBA')
ad = ImageDraw.Draw(art)
print("Background gradient painted")

# ---- Add subtle stars ----
import random
random.seed(42)
for _ in range(80):
    sy = random.randint(top_y + 20, bot_y - 20)
    if sy not in edges:
        continue
    left, right = edges[sy]
    sx = random.randint(left + 20, right - 20)
    size = random.choice([1, 1, 1, 2, 2, 3])
    alpha = random.randint(60, 180)
    ad.ellipse([sx-size, sy-size, sx+size, sy+size],
               fill=(255, 255, 255, alpha))

print("Stars added")

# ---- Solana logo (large, centered) ----
overlay = Image.new('RGBA', (W, H), (0, 0, 0, 0))
od = ImageDraw.Draw(overlay)

center_x = W // 2
logo_w = 500
logo_x = center_x - logo_w // 2
logo_y = 320
bar_h = int(logo_w * 0.10)
gap = int(bar_h * 0.6)
slant = int(logo_w * 0.14)

def draw_bar(draw_obj, yp, fwd=True):
    if fwd:
        p = [(logo_x+slant,yp),(logo_x+logo_w,yp),
             (logo_x+logo_w-slant,yp+bar_h),(logo_x,yp+bar_h)]
    else:
        p = [(logo_x,yp),(logo_x+logo_w-slant,yp),
             (logo_x+logo_w,yp+bar_h),(logo_x+slant,yp+bar_h)]
    draw_obj.polygon(p, fill=(255,255,255,255))

b1y = logo_y
b2y = logo_y + bar_h + gap
b3y = logo_y + 2 * (bar_h + gap)

draw_bar(od, b1y, True)
draw_bar(od, b2y, False)
draw_bar(od, b3y, True)

# Apply gradient to logo
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

# Logo glow (soft light behind logo)
glow_layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow_layer)
for yp, fwd in [(b1y, True), (b2y, False), (b3y, True)]:
    if fwd:
        p = [(logo_x+slant,yp),(logo_x+logo_w,yp),
             (logo_x+logo_w-slant,yp+bar_h),(logo_x,yp+bar_h)]
    else:
        p = [(logo_x,yp),(logo_x+logo_w-slant,yp),
             (logo_x+logo_w,yp+bar_h),(logo_x+slant,yp+bar_h)]
    gd.polygon(p, fill=(PURPLE[0], PURPLE[1], PURPLE[2], 80))
glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(radius=25))

# Drop shadow
shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
sd = ImageDraw.Draw(shadow)
for yp, fwd in [(b1y, True), (b2y, False), (b3y, True)]:
    off = 5
    if fwd:
        p = [(logo_x+slant+off,yp+off),(logo_x+logo_w+off,yp+off),
             (logo_x+logo_w-slant+off,yp+bar_h+off),(logo_x+off,yp+bar_h+off)]
    else:
        p = [(logo_x+off,yp+off),(logo_x+logo_w-slant+off,yp+off),
             (logo_x+logo_w+off,yp+bar_h+off),(logo_x+slant+off,yp+bar_h+off)]
    sd.polygon(p, fill=(0, 0, 0, 100))
shadow = shadow.filter(ImageFilter.GaussianBlur(radius=8))

art = Image.alpha_composite(art, glow_layer)
art = Image.alpha_composite(art, shadow)
art = Image.alpha_composite(art, overlay)
ad = ImageDraw.Draw(art)
print("Solana logo added")

# ---- Text ----
ft = None
for fp in ['C:/Windows/Fonts/segoeuib.ttf', 'C:/Windows/Fonts/arialbd.ttf']:
    try:
        ft = ImageFont.truetype(fp, 100)
        fs = ImageFont.truetype(fp, 50)
        print(f'Font: {fp}')
        break
    except:
        continue

text_y = b3y + bar_h + 40

# "SEEKER" shadow
ad.text((center_x + 3, text_y + 3), 'SEEKER', font=ft,
        fill=(0, 0, 0, 120), anchor='mt')
# "SEEKER" white base
ad.text((center_x, text_y), 'SEEKER', font=ft,
        fill=(255, 255, 255, 255), anchor='mt')

# Apply gradient to SEEKER text
bb = ft.getbbox('SEEKER')
tw, th = bb[2] - bb[0], bb[3] - bb[1]
tl = center_x - tw // 2
art_arr = np.array(art)
for y in range(max(0, int(text_y) - 5), min(H, int(text_y) + th + 15)):
    for x in range(max(0, tl - 10), min(W, tl + tw + 10)):
        r, g, b, a = art_arr[y, x]
        if r > 220 and g > 220 and b > 220 and a > 200:
            t = max(0.0, min(1.0, (x - tl) / max(tw, 1)))
            art_arr[y, x] = [
                int(PURPLE[0]*(1-t) + GREEN[0]*t),
                int(PURPLE[1]*(1-t) + GREEN[1]*t),
                int(PURPLE[2]*(1-t) + GREEN[2]*t), 255]
art = Image.fromarray(art_arr, 'RGBA')
ad = ImageDraw.Draw(art)

# "PINBALL" below
ty2 = int(text_y) + th + 12
ad.text((center_x + 2, ty2 + 2), 'PINBALL', font=fs,
        fill=(0, 0, 0, 80), anchor='mt')
ad.text((center_x, ty2), 'PINBALL', font=fs,
        fill=(GREEN[0], GREEN[1], GREEN[2], 220), anchor='mt')

# ---- Subtle horizontal line accents ----
line_y1 = logo_y - 60
line_y2 = ty2 + 80
for ly in [line_y1, line_y2]:
    if ly not in edges:
        continue
    left, right = edges[ly]
    mid = (left + right) // 2
    line_w = (right - left) // 3
    ad.line([(mid - line_w, ly), (mid + line_w, ly)],
            fill=(PURPLE[0], PURPLE[1], PURPLE[2], 40), width=1)

print("Text and accents added")

# ---- Composite: original + new artwork (masked to inner area) ----
# Apply mask to artwork layer
art_arr = np.array(art)
# Zero out artwork outside the mask
for c in range(4):
    art_arr[:, :, c] = (art_arr[:, :, c].astype(float) * (mask_arr / 255.0)).astype(np.uint8)
art_masked = Image.fromarray(art_arr, 'RGBA')

# Start with original, paste artwork over the inner area
result = orig.copy()
# First, clear the inner area in original to transparent (so artwork replaces it)
result_arr = np.array(result)
# Set inner area pixels to black transparent
result_arr[mask_arr > 0] = [0, 0, 0, 0]
result = Image.fromarray(result_arr, 'RGBA')

# Composite
result = Image.alpha_composite(result, art_masked)

result.save(MARQUEE_PATH, 'PNG')
print('Done!')
