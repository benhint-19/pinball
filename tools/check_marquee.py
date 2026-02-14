from PIL import Image
img = Image.open(r'D:\dev\seeker-pinball\packages\pinball_components\assets\images\backbox\marquee.png')
print(f'Size: {img.size}, Mode: {img.mode}')
