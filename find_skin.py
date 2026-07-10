from PIL import Image

try:
    img = Image.open('assets/main_menu_bg.jpg')
    width, height = img.size
    
    skin_coords = []
    
    for y in range(0, height, 4):
        for x in range(0, width, 4):
            r, g, b = img.getpixel((x, y))
            # Typical skin color ranges
            if r > 120 and g > 80 and b > 60 and r > g + 10 and g > b + 5:
                # exclude very bright white/yellow
                if r < 255 and (r - b) > 15:
                    skin_coords.append((x, y, r, g, b))
                    
    print("Found skin-like pixels:", len(skin_coords))
    if skin_coords:
        xs = [c[0] for c in skin_coords]
        ys = [c[1] for c in skin_coords]
        print(f"X range: {min(xs)} to {max(xs)}, Average X: {sum(xs)//len(xs)}")
        print(f"Y range: {min(ys)} to {max(ys)}, Average Y: {sum(ys)//len(ys)}")
        
        # Print sample colors
        print("Sample skin colors:")
        for c in skin_coords[:10]:
            print(f"coord: ({c[0]}, {c[1]}), color: ({c[2]}, {c[3]}, {c[4]})")
            
except Exception as e:
    print("Error:", e)
