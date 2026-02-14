"""Fine-grained scan of the artwork boundaries."""
from PIL import Image
import numpy as np, subprocess
from io import BytesIO

result = subprocess.run(
    ['git', 'show', 'HEAD~1:packages/pinball_components/assets/images/backbox/marquee.png'],
    capture_output=True, cwd=r'D:\dev\seeker-pinball'
)
img = Image.open(BytesIO(result.stdout)).convert('RGBA')
arr = np.array(img)
W, H = img.size

brightness = np.max(arr[:, :, :3], axis=2)
alpha = arr[:, :, 3]

print('Every 10 rows from y=100 to y=1160:')
for y in range(100, 1160, 10):
    row_bright = brightness[y, 80:2050]
    row_alpha = alpha[y, 80:2050]
    bright_mask = (row_bright > 70) & (row_alpha > 200)
    indices = np.where(bright_mask)[0]
    if len(indices) > 0:
        left = indices[0] + 80
        right = indices[-1] + 80
        print(f'  y={y:4d}: left={left:4d}, right={right:4d}, width={right-left:4d}')
    else:
        print(f'  y={y:4d}: NONE')
