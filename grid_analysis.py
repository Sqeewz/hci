from PIL import Image

try:
    img = Image.open('assets/main_menu_bg.jpg')
    width, height = img.size
    
    # Let's count pixels matching different color categories
    # 1. Skin tone: typical caucasian / asian skin (R > 150, G between 100 and 200, B between 80 and 170, R > G > B)
    skin_pixels = []
    # 2. Bright eyes/hair/clothes:
    # Let's analyze regions. We'll divide the image into a 10x10 grid and find the average color of each grid cell.
    grid_size = 10
    cell_w = width // grid_size
    cell_h = height // grid_size
    
    print("--- 10x10 Average Grid Colors ---")
    for gy in range(grid_size):
        row_str = []
        for gx in range(grid_size):
            r_sum = g_sum = b_sum = count = 0
            for y in range(gy * cell_h, (gy + 1) * cell_h):
                for x in range(gx * cell_w, (gx + 1) * cell_w):
                    r, g, b = img.getpixel((x, y))
                    r_sum += r
                    g_sum += g
                    b_sum += b
                    count += 1
            avg_r = r_sum // count
            avg_g = g_sum // count
            avg_b = b_sum // count
            row_str.append(f"[{avg_r:3},{avg_g:3},{avg_b:3}]")
        print(" ".join(row_str))
        
except Exception as e:
    print("Error:", e)
