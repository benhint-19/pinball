"""Find the exact inner edge of the frame (where the dark bevel meets bright artwork)."""
from PIL import Image
import numpy as np

img = Image.open(r'D:\dev\seeker-pinball\packages\pinball_components\assets\images\backbox\marquee.png').convert('RGBA')
arr = np.array(img)
W, H = img.size

# The inner frame has a dark bevel (brightness < 50) right before the bright artwork.
# Find where we cross from dark bevel INTO bright artwork.
# This gives us the true inner edge.

blue_ch = arr[:, :, 2]  # Blue channel - sky is very blue
brightness = np.max(arr[:, :, :3], axis=2)

# For detecting sky: blue > 150 AND brightness > 160
is_sky = (blue_ch > 150) & (brightness > 160) & (arr[:, :, 3] > 200)

print("Inner edge of artwork (first sky pixel per row):")
print("Scanning rows 140-1150...")
for y in range(140, 1155, 10):
    row = is_sky[y, :]
    indices = np.where(row)[0]
    if len(indices) > 0:
        left = indices[0]
        right = indices[-1]
        print(f'  y={y:4d}: left={left:4d}, right={right:4d}, width={right-left:4d}')
    else:
        print(f'  y={y:4d}: NO SKY')

# Also check the very top to find where artwork starts
print("\nTop edge scan at center:")
cx = W // 2
for y in range(100, 200):
    is_bright = is_sky[y, cx]
    r, g, b, a = arr[y, cx]
    print(f'  y={y}: rgb({r},{g},{b}) sky={is_bright}')
