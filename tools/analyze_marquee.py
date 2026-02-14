"""Analyze the marquee image to find the decorative area boundaries."""
from PIL import Image
import json

img = Image.open(r'D:\dev\seeker-pinball\packages\pinball_components\assets\images\backbox\marquee.png')
img_rgba = img.convert('RGBA')

w, h = img.size
print(f'Image size: {w}x{h}')

# Sample pixels along horizontal center to find vertical boundaries
cx = w // 2
print(f'\nVertical scan at x={cx}:')
for y in range(0, h, 50):
    r, g, b, a = img_rgba.getpixel((cx, y))
    print(f'  y={y:4d}: rgba({r},{g},{b},{a})')

# Sample pixels along vertical center to find horizontal boundaries
cy = h // 3  # Sample in the upper third where the decorative image is
print(f'\nHorizontal scan at y={cy}:')
for x in range(0, w, 50):
    r, g, b, a = img_rgba.getpixel((x, cy))
    print(f'  x={x:4d}: rgba({r},{g},{b},{a})')

# Check corners and key points for frame detection
print('\nCorner samples:')
for label, pos in [
    ('top-left', (100, 100)),
    ('top-center', (w//2, 50)),
    ('frame-inner-top-left', (150, 150)),
    ('sky-area', (w//2, 300)),
    ('mid-height', (w//2, h//2)),
    ('display-area', (w//2, h*3//4)),
    ('bottom', (w//2, h-50)),
]:
    r, g, b, a = img_rgba.getpixel(pos)
    print(f'  {label} {pos}: rgba({r},{g},{b},{a})')

# Find the sky-blue region (the decorative area has bright blue sky)
# Scan from center outward to find where blue sky starts/ends
print('\nDetailed vertical scan at center:')
for y in range(0, h, 20):
    r, g, b, a = img_rgba.getpixel((cx, y))
    is_blue = b > 150 and r < 200
    is_dark = r < 50 and g < 50 and b < 50
    is_transparent = a < 128
    label = 'BLUE' if is_blue else ('DARK' if is_dark else ('TRANS' if is_transparent else ''))
    print(f'  y={y:4d}: rgba({r:3d},{g:3d},{b:3d},{a:3d}) {label}')
