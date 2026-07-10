from PIL import Image
import collections

try:
    img = Image.open('assets/main_menu_bg.jpg')
    img_small = img.resize((16, 16), Image.Resampling.LANCZOS)
    
    print("--- 16x16 Color Grid (RGB) ---")
    for y in range(16):
        row = []
        for x in range(16):
            r, g, b = img_small.getpixel((x, y))
            row.append(f"({r:3},{g:3},{b:3})")
        print(" ".join(row))
        
    # Get dominant colors
    pixels = list(img.resize((100, 100)).getdata())
    counter = collections.Counter(pixels)
    most_common = counter.most_common(10)
    print("\n--- Top 10 Dominant Colors (RGB) ---")
    for color, count in most_common:
        print(f"Color: {color}, Count: {count}")
        
except Exception as e:
    print("Error:", e)
