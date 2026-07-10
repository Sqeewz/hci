from PIL import Image
from PIL.ExifTags import TAGS

try:
    img = Image.open('assets/main_menu_bg.jpg')
    print("Format:", img.format)
    print("Size:", img.size)
    print("Mode:", img.mode)
    
    # Check for EXIF data
    exif = img.getexif()
    if exif:
        print("\n--- EXIF ---")
        for tag_id in exif:
            tag = TAGS.get(tag_id, tag_id)
            data = exif.get(tag_id)
            if isinstance(data, bytes):
                data = data.decode(errors='replace')
            print(f"{tag}: {data}")
            
    # Check info dictionary
    if img.info:
        print("\n--- INFO ---")
        for k, v in img.info.items():
            print(f"{k}: {v}")
            
except Exception as e:
    print("Error:", e)
