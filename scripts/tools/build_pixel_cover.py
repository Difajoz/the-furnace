import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

def create_pixel_cover():
    print("Building 100% authentic 2D pixel art cover thumbnail using real game assets...")
    
    # Base dimensions: 315 x 250 (Integer 2x scale -> 630 x 500, 4x scale -> 1260 x 1000)
    W, H = 315, 250
    
    # 1. Composite the crypt environment from separated layers
    layer_dir = r'assets/Minifantasy_Crypt_Of_The_Forgotten_v1.0/Minifantasy_Crypt_Of_The_Forgotten_Assets/Premade_Scene/Separate_Layers'
    
    bg = Image.open(f'{layer_dir}/h_bg.png').convert('RGBA')
    floor = Image.open(f'{layer_dir}/g_floor.png').convert('RGBA')
    walls = Image.open(f'{layer_dir}/f_walls.png').convert('RGBA')
    stairs = Image.open(f'{layer_dir}/d_stairs.png').convert('RGBA')
    engr = Image.open(f'{layer_dir}/e_wall_engravings.png').convert('RGBA')
    shad = Image.open(f'{layer_dir}/a_shadows.png').convert('RGBA')
    
    full_scene = Image.new('RGBA', bg.size, (8, 9, 13, 255))
    full_scene.alpha_composite(bg)
    full_scene.alpha_composite(floor)
    full_scene.alpha_composite(stairs)
    full_scene.alpha_composite(walls)
    full_scene.alpha_composite(engr)
    full_scene.alpha_composite(shad)
    
    # Exact 315x250 crop centered on the main sanctum chamber
    canvas = full_scene.crop((105, 95, 420, 345)).copy()
    
    # 2. Add torch / candle props from Props.png or Candles.png
    props_path = r'assets/Minifantasy_Crypt_Of_The_Forgotten_v1.0/Minifantasy_Crypt_Of_The_Forgotten_Assets/Props/Props.png'
    props_img = Image.open(props_path).convert('RGBA')
    
    # Wall Sconce / Torch (from Props sheet, let's take a nice skull/candle prop)
    # Candles sheet
    candles_path = r'assets/Minifantasy_Crypt_Of_The_Forgotten_v1.0/Minifantasy_Crypt_Of_The_Forgotten_Assets/Props/Animated_Candles/Candles.png'
    candles_img = Image.open(candles_path).convert('RGBA')
    # Stand candle: first candle stand is typically ~16x24
    # Let's crop a burning candle stand
    c_stand = candles_img.crop((0, 0, 16, 24))
    canvas.alpha_composite(c_stand, (118, 95))
    canvas.alpha_composite(c_stand, (198, 95))
    
    # 3. Build & Place the Central FURNACE on the Dais
    # We generate the 32x32 pixel furnace directly from the game's VisualFactory logic
    furnace_32 = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
    C_DARK = (22, 23, 30, 255)
    C_IRON_DARK = (38, 41, 52, 255)
    C_IRON_MID = (58, 64, 82, 255)
    C_IRON_LIGHT = (88, 97, 122, 255)
    C_BRONZE_DARK = (105, 62, 32, 255)
    C_BRONZE_MID = (166, 107, 50, 255)
    C_BRONZE_LIGHT = (214, 150, 81, 255)
    C_RIVET = (235, 192, 124, 255)
    
    # Chimney (X: 11..20, Y: 1..8)
    for y in range(1, 9):
        for x in range(11, 21):
            if x == 11 or x == 20 or y == 1:
                furnace_32.putpixel((x, y), C_DARK)
            elif x == 12 or y == 2:
                furnace_32.putpixel((x, y), C_IRON_LIGHT)
            else:
                furnace_32.putpixel((x, y), C_IRON_MID)
    # Chimney rim cap
    for x in range(10, 22):
        furnace_32.putpixel((x, 1), C_BRONZE_MID)
        furnace_32.putpixel((x, 2), C_BRONZE_DARK)
    # Body
    for y in range(8, 30):
        for x in range(4, 28):
            if (x <= 5 and y <= 9) or (x >= 26 and y <= 9) or (x <= 4 and y >= 29) or (x >= 27 and y >= 29):
                continue
            if x == 4 or x == 27 or y == 8 or y == 29 or (x == 5 and y == 9) or (x == 26 and y == 9):
                furnace_32.putpixel((x, y), C_DARK)
            elif x == 5 or y == 9:
                furnace_32.putpixel((x, y), C_IRON_LIGHT)
            else:
                furnace_32.putpixel((x, y), C_IRON_MID)
    # Bronze Bands
    for y in [11, 25]:
        for x in range(5, 27):
            furnace_32.putpixel((x, y), C_BRONZE_MID)
            furnace_32.putpixel((x, y + 1), C_BRONZE_DARK)
    # Rivets
    for pt in [(6, 11), (25, 11), (6, 25), (25, 25), (15, 11), (16, 11)]:
        furnace_32.putpixel(pt, C_RIVET)
    # Glowing Crucible Core
    glow_colors = [
        (255, 255, 240, 255),
        (255, 225, 90, 255),
        (255, 130, 25, 255),
        (210, 45, 15, 255)
    ]
    for y in range(14, 24):
        for x in range(9, 23):
            if x == 9 or x == 22 or y == 14 or y == 23:
                furnace_32.putpixel((x, y), C_DARK)
            else:
                dy = abs(y - 19)
                dx = abs(x - 15.5)
                dist = int(dx + dy)
                furnace_32.putpixel((x, y), glow_colors[min(dist, len(glow_colors) - 1)])
    # Grate bars
    for gx in [12, 15, 19]:
        for gy in range(15, 23):
            furnace_32.putpixel((gx, gy), C_DARK)
    # Legs
    for y in range(29, 32):
        for x in range(5, 9):
            furnace_32.putpixel((x, y), C_DARK if y == 31 or x == 5 else C_IRON_DARK)
        for x in range(23, 27):
            furnace_32.putpixel((x, y), C_DARK if y == 31 or x == 26 else C_IRON_DARK)
            
    # Scale furnace to 38x38 for prominent heroic size on the dais
    furnace_scaled = furnace_32.resize((40, 40), Image.Resampling.NEAREST)
    furnace_x = 157 - 20
    furnace_y = 52
    
    # 4. Roaring chimney flame from Tileable_Fire.png
    fire_sheet_path = r'assets/Minifantasy_Spell Effects_v1.0/Minifantasy_Spell_Effects_Assets/Fire/Tileable_Effect/Tileable_Fire.png'
    fire_sheet = Image.open(fire_sheet_path).convert('RGBA')
    # Pick vibrant fire sprites
    flame_1 = fire_sheet.crop((0, 8, 16, 24))
    flame_2 = fire_sheet.crop((16, 8, 32, 24))
    flame_big = flame_1.resize((24, 24), Image.Resampling.NEAREST)
    
    # Plume coming out of furnace chimney
    canvas.alpha_composite(flame_big, (furnace_x + 8, furnace_y - 18))
    # Place furnace over the plume base
    canvas.alpha_composite(furnace_scaled, (furnace_x, furnace_y))
    
    # 5. Flanking Turrets on the Dais (Flame & Cannon/Ice Turret)
    # Flame Turret (Left)
    flame_base = Image.open(r'assets/turrets/flame_turret_base.png').convert('RGBA')
    flame_head = Image.open(r'assets/turrets/flame_turret_head.png').convert('RGBA').crop((0, 0, 16, 16))
    canvas.alpha_composite(flame_base, (108, 64))
    canvas.alpha_composite(flame_head, (108, 62))
    
    # Cannon Turret (Right)
    cannon_full = Image.open(r'assets/turrets/cannon_turret_full.png').convert('RGBA').crop((0, 0, 16, 16))
    canvas.alpha_composite(cannon_full, (206, 64))
    
    # 6. Hero in Center Foreground
    # Using HumanWalk.png from player assets (Frame 0 facing forward)
    hero_sheet = Image.open(r'assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Base_Humanoids/Human/Base_Human/HumanWalk.png').convert('RGBA')
    hero_spr = hero_sheet.crop((0, 0, 32, 32))
    # Hero position: center, standing ready before the furnace
    hero_x = 157 - 16
    hero_y = 108
    canvas.alpha_composite(hero_spr, (hero_x, hero_y))
    
    # Add hero equipped weapons & muzzle flashes
    # Shotgun in right hand, cryo-spray in left hand
    # Pixel shotgun (8x8)
    shotgun_img = Image.new('RGBA', (8, 8), (0, 0, 0, 0))
    for p, c in [((1, 4), (115, 65, 30)), ((2, 5), (115, 65, 30)), ((2, 6), (15, 15, 20)),
                 ((2, 3), (90, 95, 105)), ((3, 3), (175, 185, 200)), ((4, 3), (175, 185, 200)),
                 ((5, 3), (175, 185, 200)), ((6, 3), (15, 15, 20)), ((3, 4), (15, 15, 20))]:
        shotgun_img.putpixel(p, (*c, 255))
    shotgun_scaled = shotgun_img.resize((12, 12), Image.Resampling.NEAREST)
    canvas.alpha_composite(shotgun_scaled, (hero_x + 20, hero_y + 12))
    
    # Little fire spark muzzle flash
    spark = fire_sheet.crop((48, 0, 56, 8))
    canvas.alpha_composite(spark, (hero_x + 28, hero_y + 10))
    
    # Water spray arc towards the furnace (Hero cooling the crucible)
    # Subtle blue cooling spray droplets
    draw = ImageDraw.Draw(canvas)
    for i in range(5):
        t = i / 5.0
        bx = int(hero_x + 10 + (furnace_x + 16 - (hero_x + 10)) * t + math.sin(t * 3.14) * 3)
        by = int(hero_y + 4 + (furnace_y + 26 - (hero_y + 4)) * t)
        draw.rectangle([bx, by, bx + 1, by + 1], fill=(100, 210, 255, 220))
        draw.rectangle([bx - 1, by, bx, by + 1], fill=(220, 245, 255, 240))
        
    # 7. Monsters Infiltrating the Crypt (Clean, dynamic 3-point standoff)
    # A. Minotaur (Enormous brute advancing from bottom entrance)
    mino_sheet = Image.open(r'assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Monsters/Minotaur/MinotaurWalk.png').convert('RGBA')
    # Row 1 is facing up (towards hero & furnace)
    mino_spr = mino_sheet.crop((0, 32, 32, 64))
    mino_scaled = mino_spr.resize((40, 40), Image.Resampling.NEAREST)
    canvas.alpha_composite(mino_scaled, (157 - 20, 188))
    
    # B. Skeleton Archer (Flanking from left corridor)
    skel_sheet = Image.open(r'assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Undead/Skeleton/SkeletonWalk.png').convert('RGBA')
    # Facing right (row 2 or 3)
    skel_spr = skel_sheet.crop((0, 64, 32, 96))
    canvas.alpha_composite(skel_spr, (78, 126))
    
    # C. Gargoyle (Perched on the right wall ready to pounce)
    garg_sheet = Image.open(r'assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Gargoyle/GargoyleWalk.png').convert('RGBA')
    garg_spr = garg_sheet.crop((0, 0, 32, 32)).transpose(Image.FLIP_LEFT_RIGHT)
    canvas.alpha_composite(garg_spr, (230, 120))
    
    # D. Vampiric Bat in the shadows
    bat_sheet = Image.open(r'assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Beasts/Bat/BatFlyIdle.png').convert('RGBA')
    bat_spr = bat_sheet.crop((0, 0, 32, 32))
    canvas.alpha_composite(bat_spr, (216, 175))
    
    # 8. Warm Volumetric Radiant Furnace Hearth Glow (Overlay pass)
    glow_overlay = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_overlay)
    
    fx_center = (furnace_x + 20, furnace_y + 22)
    # Concentric warm lighting gradient radiating across the stones
    for r, alpha in [(120, 12), (90, 22), (65, 38), (45, 60), (28, 90), (14, 130)]:
        glow_draw.ellipse(
            [fx_center[0] - r, fx_center[1] - r, fx_center[0] + r, fx_center[1] + r],
            fill=(255, 120, 20, alpha)
        )
    canvas = Image.alpha_composite(canvas, glow_overlay)
    
    # Rising embers
    draw = ImageDraw.Draw(canvas)
    ember_pts = [
        (furnace_x + 6, furnace_y - 4), (furnace_x + 14, furnace_y - 12),
        (furnace_x + 22, furnace_y - 8), (furnace_x + 28, furnace_y - 18),
        (furnace_x + 12, furnace_y - 24), (furnace_x + 32, furnace_y - 10),
        (hero_x + 32, hero_y + 14), (112, 58), (210, 58)
    ]
    for pt in ember_pts:
        draw.rectangle([pt[0], pt[1], pt[0] + 1, pt[1] + 1], fill=(255, 210, 50, 255))
        draw.rectangle([pt[0] - 1, pt[1], pt[0], pt[1] + 1], fill=(255, 110, 20, 180))
        
    # 9. Top Pixel Title Plaque
    # Elegant, clean, professional indie game banner
    font_path = r'assets/Ultrapixel.ttf'
    font_title = ImageFont.truetype(font_path, 22)
    font_sub = ImageFont.truetype(font_path, 11)
    
    # Banner Plate Dimensions
    bw, bh = 224, 40
    bx = (W - bw) // 2
    by = 8
    
    # Draw Banner Plaque
    # Drop shadow
    draw.rectangle([bx + 2, by + 2, bx + bw + 2, by + bh + 2], fill=(4, 5, 8, 200))
    # Background
    draw.rectangle([bx, by, bx + bw, by + bh], fill=(16, 17, 24, 245))
    # Outer Gold Border
    draw.rectangle([bx, by, bx + bw, by + bh], outline=(200, 140, 50, 255), width=1)
    # Inner Bronze Border
    draw.rectangle([bx + 2, by + 2, bx + bw - 2, by + bh - 2], outline=(95, 60, 30, 255), width=1)
    # Corner Rivets
    for rx, ry in [(bx + 4, by + 4), (bx + bw - 5, by + 4), (bx + 4, by + bh - 5), (bx + bw - 5, by + bh - 5)]:
        draw.rectangle([rx, ry, rx + 1, ry + 1], fill=(255, 215, 90, 255))
        
    # Title Text: [ THE FURNACE ]
    title_text = "THE FURNACE"
    t_bbox = font_title.getbbox(title_text)
    tw = t_bbox[2] - t_bbox[0]
    tx = (W - tw) // 2
    ty = by + 3
    
    # Glow / shadow for title
    draw.text((tx + 1, ty + 1), title_text, font=font_title, fill=(35, 12, 5, 255))
    draw.text((tx, ty + 1), title_text, font=font_title, fill=(150, 45, 10, 255))
    draw.text((tx, ty), title_text, font=font_title, fill=(255, 205, 75, 255))
    
    # Subtitle Text
    sub_text = "SURVIVE THE CRYPT * COOL THE CRUCIBLE"
    s_bbox = font_sub.getbbox(sub_text)
    sw = s_bbox[2] - s_bbox[0]
    sx = (W - sw) // 2
    sy = by + 24
    
    draw.text((sx + 1, sy + 1), sub_text, font=font_sub, fill=(10, 10, 15, 255))
    draw.text((sx, sy), sub_text, font=font_sub, fill=(215, 225, 240, 255))
    
    # 10. Atmospheric Edge Vignette
    vignette = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    v_draw = ImageDraw.Draw(vignette)
    v_draw.rectangle([0, 0, W, H], outline=(5, 6, 9, 140), width=4)
    v_draw.rectangle([0, 0, W, H], outline=(2, 3, 5, 220), width=2)
    canvas = Image.alpha_composite(canvas, vignette)
    
    # 11. Export directly to 630x500 (2x Crisp Nearest Neighbor) and 1260x1000 HD (4x Crisp Nearest Neighbor)
    out_630 = canvas.resize((630, 500), Image.Resampling.NEAREST)
    out_1260 = canvas.resize((1260, 1000), Image.Resampling.NEAREST)
    
    out_path_std = r'C:/Users/User/Desktop/Projects/the-furnace/media/cover_thumbnail.png'
    out_path_hd = r'C:/Users/User/Desktop/Projects/the-furnace/media/cover_thumbnail_hd.png'
    
    out_630.save(out_path_std)
    out_1260.save(out_path_hd)
    
    print(f"SUCCESS: Saved 100% 2D Asset Thumbnail to {out_path_std} (630x500)")
    print(f"SUCCESS: Saved 100% 2D Asset Thumbnail HD to {out_path_hd} (1260x1000)")

if __name__ == '__main__':
    create_pixel_cover()
