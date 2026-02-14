"""Generate SEEKER PINBALL logo to replace io_pinball.png."""
from PIL import Image, ImageDraw, ImageFont
import numpy as np

WIDTH, HEIGHT = 618, 270
OUTPUT = r"D:\dev\seeker-pinball\assets\images\loading_game\io_pinball.png"

# Solana gradient colors
PURPLE = (153, 69, 255)   # Solana purple
GREEN = (20, 241, 149)    # Solana green/teal

def make_gradient(width, height):
    arr = np.zeros((height, width, 4), dtype=np.uint8)
    for y in range(height):
        t = y / max(height - 1, 1)
        r = int(PURPLE[0] + (GREEN[0] - PURPLE[0]) * t)
        g = int(PURPLE[1] + (GREEN[1] - PURPLE[1]) * t)
        b = int(PURPLE[2] + (GREEN[2] - PURPLE[2]) * t)
        arr[y, :] = [r, g, b, 255]
    return Image.fromarray(arr, "RGBA")

# Create text mask image (white text on black)
text_img = Image.new("L", (WIDTH, HEIGHT), 0)
draw = ImageDraw.Draw(text_img)

font_path = r"C:\Windows\Fonts\impact.ttf"
font_top = ImageFont.truetype(font_path, 120)
font_bot = ImageFont.truetype(font_path, 100)

bbox_s = draw.textbbox((0, 0), "SEEKER", font=font_top)
bbox_p = draw.textbbox((0, 0), "PINBALL", font=font_bot)

w_s = bbox_s[2] - bbox_s[0]
h_s = bbox_s[3] - bbox_s[1]
w_p = bbox_p[2] - bbox_p[0]
h_p = bbox_p[3] - bbox_p[1]

gap = 10
total_h = h_s + gap + h_p
y_offset = (HEIGHT - total_h) // 2

x_s = (WIDTH - w_s) // 2
x_p = (WIDTH - w_p) // 2

draw.text((x_s - bbox_s[0], y_offset - bbox_s[1]), "SEEKER", fill=255, font=font_top)
draw.text((x_p - bbox_p[0], y_offset + h_s + gap - bbox_p[1]), "PINBALL", fill=255, font=font_bot)

# Create gradient and composite
gradient = make_gradient(WIDTH, HEIGHT)
gradient_pixels = np.array(gradient)
text_pixels = np.array(text_img)

output_arr = np.zeros((HEIGHT, WIDTH, 4), dtype=np.uint8)
output_arr[:, :, 0] = gradient_pixels[:, :, 0]
output_arr[:, :, 1] = gradient_pixels[:, :, 1]
output_arr[:, :, 2] = gradient_pixels[:, :, 2]
output_arr[:, :, 3] = text_pixels

result = Image.fromarray(output_arr, "RGBA")
result.save(OUTPUT)
print(f"Saved {OUTPUT} ({result.size[0]}x{result.size[1]}, mode={result.mode})")
