"""Analyze the frame taper by scanning per-row boundaries."""
from PIL import Image
import numpy as np

# Use git to get the original file
import subprocess
result = subprocess.run(
    ['git', 'show', 'HEAD~1:packages/pinball_components/assets/images/backbox/marquee.png'],
    capture_output=True, cwd=r'D:\dev\seeker-pinball'
)
from io import BytesIO
img = Image.open(BytesIO(result.stdout)).convert('RGBA')
arr = np.array(img)
W, H = img.size
print(f'Original: {W}x{H}')

brightness = np.max(arr[:, :, :3], axis=2)
alpha = arr[:, :, 3]

# Approximate artwork region (generous)
art_top, art_bottom = 120, 1160
art_left, art_right = 100, 2030

# For each row, find leftmost and rightmost bright pixel
print('\nPer-row boundaries (sampled every 50 rows):')
for y in range(art_top, art_bottom, 50):
    row_bright = brightness[y, art_left:art_right]
    row_alpha = alpha[y, art_left:art_right]
    bright_mask = (row_bright > 70) & (row_alpha > 200)
    indices = np.where(bright_mask)[0]
    if len(indices) > 0:
        left = indices[0] + art_left
        right = indices[-1] + art_left
        print(f'  y={y:4d}: left={left:4d}, right={right:4d}, width={right-left:4d}')
    else:
        print(f'  y={y:4d}: no bright pixels')
