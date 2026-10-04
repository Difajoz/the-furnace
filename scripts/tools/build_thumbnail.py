import os
import math
import random
from PIL import Image, ImageDraw, ImageFont, ImageFilter

def create_pixel_furnace(scale=1):
    """Generates the authentic 32x32 8-bit furnace from VisualFactory logic at critical stage."""
    img = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
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
                img.putpixel((x, y), C_DARK)
            elif x == 12 or y == 2:
                img.putpixel((x, y), C_IRON_LIGHT)
            else:
                img.putpixel((x, y), C_IRON_MID)

    # Chimney rim cap
    for x in range(10, 22):
        img.putpixel((x, 1), C_BRONZE_MID)
        img.putpixel((x, 2), C_BRONZE_DARK)

    # Body (X: 4..27, Y: 8..29)
    for y in range(8, 30):
        for x in range(4, 28):
            if (x <= 5 and y <= 9) or (x >= 26 and y <= 9) or (x <= 4 and y >= 29) or (x >= 27 and y >= 29):
                continue
            if x == 4 or x == 27 or y == 8 or y == 29 or (x == 5 and y == 9) or (x == 26 and y == 9):
                img.putpixel((x, y), C_DARK)
            elif x == 5 or y == 9:
                img.putpixel((x, y), C_IRON_LIGHT)
            else:
                img.putpixel((x, y), C_IRON_MID)

    # Bronze Bands (Y: 11, 25)
    for y in [11, 25]:
        for x in range(5, 27):
            img.putpixel((x, y), C_BRONZE_MID)
            img.putpixel((x, y + 1), C_BRONZE_DARK)

    # Rivets
    for pt in [(6, 11), (25, 11), (6, 25), (25, 25), (15, 11), (16, 11)]:
        img.putpixel(pt, C_RIVET)

    # Central Crucible Fire Chamber (X: 9..22, Y: 14..23) - Critical Molten White-Hot
    glow_colors = [
        (255, 255, 255, 255),
        (255, 245, 140, 255),
        (255, 160, 35, 255),
        (220, 55, 18, 255),
        (160, 25, 12, 255)
    ]
    for y in range(14, 24):
        for x in range(9, 23):
            if x == 9 or x == 22 or y == 14 or y == 23:
                img.putpixel((x, y), C_DARK)
            else:
                dy = abs(y - 19)
                dx = abs(x - 15.5)
                dist = int(dx + dy)
                idx = min(dist, len(glow_colors) - 1)
                img.putpixel((x, y), glow_colors[idx])

    # Vertical Grate bars
    for gx in [12, 15, 19]:
        for gy in range(15, 23):
            img.putpixel((gx, gy), C_DARK)

    # Legs
    for y in range(29, 32):
        for x in range(5, 9):
            img.putpixel((x, y), C_DARK if y == 31 or x == 5 else C_IRON_DARK)
        for x in range(23, 27):
            img.putpixel((x, y), C_DARK if y == 31 or x == 26 else C_IRON_DARK)

    if scale > 1:
        img = img.resize((32 * scale, 32 * scale), Image.Resampling.NEAREST)
    return img

def create_pixel_coin(target_size=19):
    """Generates the authentic 8x8 gold coin from VisualFactory.gd, scaled cleanly to target size."""
    img = Image.new('RGBA', (8, 8), (0, 0, 0, 0))
    C_EDGE = (160, 105, 10, 255)
    C_GOLD = (250, 195, 30, 255)
    C_SHINE = (255, 255, 180, 255)
    for y in range(1, 7):
        for x in range(1, 7):
            if (x == 1 and y == 1) or (x == 6 and y == 1) or (x == 1 and y == 6) or (x == 6 and y == 6):
                continue
            if x == 1 or x == 6 or y == 1 or y == 6:
                img.putpixel((x, y), C_EDGE)
            else:
                img.putpixel((x, y), C_GOLD)
    img.putpixel((2, 2), C_SHINE)
    img.putpixel((3, 2), C_SHINE)
    if target_size != 8:
        img = img.resize((target_size, target_size), Image.Resampling.NEAREST)
    return img

def create_pixel_weapon(weapon_id, scale=1):
    """Exact 8x8 pixel art weapons from VisualFactory."""
    img = Image.new('RGBA', (8, 8), (0, 0, 0, 0))
    C_BLACK = (15, 15, 20, 255)
    C_DARK = (25, 25, 32, 255)
    C_GREY = (90, 95, 105, 255)
    C_SILVER = (175, 185, 200, 255)
    C_WHITE = (240, 245, 255, 255)
    C_BROWN = (115, 65, 30, 255)
    C_GOLD = (245, 190, 35, 255)
    C_RED = (230, 45, 45, 255)
    C_CYAN = (45, 210, 245, 255)
    C_BLUE = (40, 120, 240, 255)

    if weapon_id == "shotgun":
        img.putpixel((0, 5), C_BROWN); img.putpixel((1, 4), C_BROWN); img.putpixel((2, 4), C_BROWN)
        img.putpixel((3, 3), C_GREY); img.putpixel((4, 3), C_SILVER); img.putpixel((5, 3), C_SILVER); img.putpixel((6, 3), C_SILVER); img.putpixel((7, 3), C_BLACK)
        img.putpixel((4, 4), C_BROWN); img.putpixel((5, 4), C_GREY)
    elif weapon_id == "cryo_blaster":
        img.putpixel((1, 4), C_BLACK); img.putpixel((2, 5), C_BLACK)
        img.putpixel((2, 3), C_BLUE); img.putpixel((3, 3), C_CYAN); img.putpixel((4, 3), C_WHITE); img.putpixel((5, 3), C_CYAN); img.putpixel((6, 3), C_BLUE); img.putpixel((7, 3), C_CYAN)
        img.putpixel((3, 4), C_BLUE); img.putpixel((4, 4), C_CYAN)
    elif weapon_id == "greatsword":
        img.putpixel((1, 6), C_BROWN); img.putpixel((2, 5), C_GOLD); img.putpixel((3, 5), C_GOLD); img.putpixel((2, 4), C_GOLD)
        img.putpixel((3, 4), C_SILVER); img.putpixel((4, 3), C_WHITE); img.putpixel((5, 2), C_WHITE); img.putpixel((6, 1), C_WHITE)
        img.putpixel((4, 4), C_SILVER); img.putpixel((5, 3), C_SILVER); img.putpixel((6, 2), C_SILVER); img.putpixel((7, 1), C_SILVER)
    elif weapon_id == "plasma_blaster":
        img.putpixel((1, 4), C_BLACK); img.putpixel((2, 5), C_BLACK)
        img.putpixel((2, 3), C_GREY); img.putpixel((3, 3), C_CYAN); img.putpixel((4, 3), C_WHITE); img.putpixel((5, 3), C_CYAN); img.putpixel((6, 3), C_SILVER); img.putpixel((7, 3), C_CYAN)
        img.putpixel((3, 4), C_CYAN); img.putpixel((4, 4), C_CYAN)
    else:
        img.putpixel((1, 4), C_BROWN); img.putpixel((2, 5), C_BROWN); img.putpixel((2, 6), C_BLACK)
        img.putpixel((2, 3), C_GREY); img.putpixel((3, 3), C_SILVER); img.putpixel((4, 3), C_SILVER); img.putpixel((5, 3), C_SILVER); img.putpixel((6, 3), C_BLACK)

    if scale > 1:
        img = img.resize((8 * scale, 8 * scale), Image.Resampling.NEAREST)
    return img

def build_complete_thumbnail():
    print("Building Premium 100% Game Asset Pixel Art Thumbnail (Cleaned & Refined)...")
    
    # Standard itch.io dimensions: 630 x 500
    W, H = 630, 500
    canvas = Image.new('RGBA', (W, H), (14, 15, 20, 255))
    draw = ImageDraw.Draw(canvas)
    
    # =========================================================================
    # 1. MAIN LEVEL ARENA FLOOR (from scripts/arena/arena.gd)
    # =========================================================================
    tsize = 42 # 15 columns x 12 rows
    paver_colors = [
        (22, 24, 32, 255),
        (28, 30, 40, 255), # dark basalt paver
        (34, 37, 48, 255), # chiseled iron stone
        (18, 20, 26, 255), # weathered stone
        (24, 28, 36, 255),
        (26, 28, 38, 255)
    ]
    
    for row in range(H // tsize + 2):
        for col in range(W // tsize + 2):
            px = col * tsize
            py = row * tsize
            
            seed_v = (abs(col * 31 + row * 57)) % len(paver_colors)
            p_col = paver_colors[seed_v]
            
            # Paver stone body with 2px mortar gap
            draw.rectangle([px + 2, py + 2, px + tsize - 2, py + tsize - 2], fill=p_col)
            
            # Subtle stone highlight on top-left edge
            hi_col = tuple(min(255, c + 12) for c in p_col[:3]) + (255,)
            draw.line([(px + 3, py + 3), (px + tsize - 3, py + 3)], fill=hi_col, width=1)
            draw.line([(px + 3, py + 3), (px + 3, py + tsize - 3)], fill=hi_col, width=1)
            
            # Shadow on bottom-right edge
            sh_col = tuple(max(0, c - 10) for c in p_col[:3]) + (255,)
            draw.line([(px + 3, py + tsize - 3), (px + tsize - 3, py + tsize - 3)], fill=sh_col, width=1)
            draw.line([(px + tsize - 3, py + 3), (px + tsize - 3, py + tsize - 3)], fill=sh_col, width=1)
            
            # Iron rivets on corner pavers
            if (col * 7 + row * 11) % 8 == 0:
                rivet_c = (55, 60, 75, 255)
                draw.rectangle([px + 5, py + 5, px + 7, py + 7], fill=rivet_c)
                draw.rectangle([px + tsize - 8, py + 5, px + tsize - 6, py + 7], fill=rivet_c)
                draw.rectangle([px + 5, py + tsize - 8, px + 7, py + tsize - 6], fill=rivet_c)
                draw.rectangle([px + tsize - 8, py + tsize - 8, px + tsize - 6, py + tsize - 6], fill=rivet_c)
            # Masonry crack
            elif (col * 13 + row * 17) % 10 == 0:
                crack_c = (12, 13, 18, 255)
                draw.line([(px + 8, py + 12), (px + 20, py + 26)], fill=crack_c, width=1)
                draw.line([(px + 20, py + 26), (px + 28, py + 22)], fill=crack_c, width=1)

    # Corner Anvil Cauldrons with Molten Lava (from arena.gd)
    corner_spots = [(36, 110), (W - 36, 110), (36, H - 45), (W - 36, H - 45)]
    for cx, cy in corner_spots:
        draw.rectangle([cx - 24, cy - 24, cx + 24, cy + 24], fill=(10, 11, 14, 255))
        draw.rectangle([cx - 20, cy - 20, cx + 20, cy + 20], fill=(45, 48, 62, 255))
        draw.rectangle([cx - 14, cy - 14, cx + 14, cy + 14], fill=(65, 70, 90, 255))
        draw.rectangle([cx - 10, cy - 10, cx + 10, cy + 10], fill=(240, 90, 20, 255))
        draw.rectangle([cx - 5, cy - 5, cx + 5, cy + 5], fill=(255, 220, 40, 255))

    # =========================================================================
    # 2. GRADIENT CIRCLE IN THE MIDDLE (just like starting loading screen!)
    # =========================================================================
    glow_center = (315, 220)
    glow_layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_layer)
    
    # Molten radial gradient rings (orange, amber, hearth glow matching loading_screen_ui.gd)
    radii_and_colors = [
        (300, (255, 60, 10, 28)),
        (250, (255, 80, 15, 46)),
        (200, (255, 110, 20, 72)),
        (150, (255, 140, 30, 100)),
        (105, (255, 180, 45, 130)),
        (65,  (255, 215, 65, 165)),
        (35,  (255, 245, 110, 195))
    ]
    for r, col in radii_and_colors:
        glow_draw.ellipse(
            [glow_center[0] - r, glow_center[1] - r, glow_center[0] + r, glow_center[1] + r],
            fill=col
        )
    glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(radius=6))
    canvas = Image.alpha_composite(canvas, glow_layer)
    draw = ImageDraw.Draw(canvas)

    # =========================================================================
    # 3. STEPPED HAZARD BORDER & CRUCIBLE PLATE (from arena.gd)
    # =========================================================================
    hx, hy = glow_center
    h_radius = 145.0
    step = 45.0
    
    oct_pts = [
        (hx - h_radius + step, hy - h_radius),
        (hx + h_radius - step, hy - h_radius),
        (hx + h_radius, hy - h_radius + step),
        (hx + h_radius, hy + h_radius - step),
        (hx + h_radius - step, hy + h_radius),
        (hx - h_radius + step, hy + h_radius),
        (hx - h_radius, hy + h_radius - step),
        (hx - h_radius, hy - h_radius + step)
    ]
    
    draw.polygon(oct_pts, fill=(12, 13, 18, 215))
    
    hz_gold = (255, 195, 25, 255)
    hz_dark = (15, 16, 20, 255)
    for i in range(len(oct_pts)):
        p1 = oct_pts[i]
        p2 = oct_pts[(i + 1) % len(oct_pts)]
        dx = p2[0] - p1[0]
        dy = p2[1] - p1[1]
        dist = math.hypot(dx, dy)
        num_stripes = max(1, int(dist / 14.0))
        for s in range(num_stripes):
            t0 = s / float(num_stripes)
            t1 = (s + 1) / float(num_stripes)
            sp0 = (p1[0] + dx * t0, p1[1] + dy * t0)
            sp1 = (p1[0] + dx * t1, p1[1] + dy * t1)
            scol = hz_gold if (s % 2 == 0) else hz_dark
            draw.line([sp0, sp1], fill=scol, width=6)
            
    cr_w, cr_h = 106, 106
    cr_rect = [hx - cr_w // 2, hy - cr_h // 2, hx + cr_w // 2, hy + cr_h // 2]
    draw.rectangle(cr_rect, fill=(10, 11, 15, 255))
    draw.rectangle(cr_rect, outline=(240, 110, 20, 255), width=4)
    draw.ellipse([hx - 165, hy - 165, hx + 165, hy + 165], outline=(255, 90, 20, 75), width=3)

    # =========================================================================
    # 4. CENTRAL FURNACE IN THE MIDDLE (from VisualFactory.gd)
    # =========================================================================
    furnace_img = create_pixel_furnace(scale=3)
    fx = hx - 48
    fy = hy - 50
    
    fire_sheet_path = r'assets/Minifantasy_Spell Effects_v1.0/Minifantasy_Spell_Effects_Assets/Fire/Tileable_Effect/Tileable_Fire.png'
    fire_sheet = Image.open(fire_sheet_path).convert('RGBA')
    flame_sprite = fire_sheet.crop((0, 8, 16, 24)).resize((44, 44), Image.Resampling.NEAREST)
    flame_sparks = fire_sheet.crop((32, 0, 48, 16)).resize((40, 40), Image.Resampling.NEAREST)
    
    canvas.alpha_composite(flame_sprite, (hx - 22, fy - 32))
    canvas.alpha_composite(flame_sparks, (hx - 20, fy - 58))
    canvas.alpha_composite(furnace_img, (fx, fy))

    # =========================================================================
    # 5. COINS NEAR THE FURNACE (Decreased by 20% -> 19x19 px, naturally clustered)
    # =========================================================================
    # 24 * 0.8 = 19.2 px -> 19x19 px
    coin_tex = create_pixel_coin(target_size=19)
    
    # Natural organic loot cluster nestled tightly around the furnace hearth and feet
    furnace_coin_spots = [
        (hx - 58, hy + 24), # left foot flank
        (hx - 44, hy + 38), # left front apron
        (hx - 24, hy + 44), # bottom-left front
        (hx - 6,  hy + 46), # center front hearth
        (hx + 12, hy + 44), # bottom-right front
        (hx + 30, hy + 38), # right front apron
        (hx + 44, hy + 22), # right foot flank
        (hx - 62, hy + 2),  # lower-left side
        (hx + 46, hy + 2),  # lower-right side
        (hx - 56, hy - 24), # upper-left side
        (hx + 42, hy - 22), # upper-right side
        (hx - 36, hy + 28), # cluster tuck left
        (hx + 22, hy + 28), # cluster tuck right
    ]
    for cp in furnace_coin_spots:
        canvas.alpha_composite(coin_tex, cp)

    # =========================================================================
    # 6. CANNON TURRET (Upper-Left Flank, Stationed Defense)
    # =========================================================================
    # Clean turret stationed in defensive posture, strictly NO flying cannonballs or smoke blobs
    turret_x = 145
    turret_y = 150
    
    c_base = Image.open(r'assets/turrets/cannon_turret_base.png').convert('RGBA')
    c_base_sc = c_base.resize((54, 54), Image.Resampling.NEAREST)
    canvas.alpha_composite(c_base_sc, (turret_x, turret_y))
    
    c_head = Image.open(r'assets/turrets/cannon_turret_head.png').convert('RGBA')
    c_head_f0 = c_head.crop((0, 0, 16, 16)).resize((54, 54), Image.Resampling.NEAREST)
    canvas.alpha_composite(c_head_f0, (turret_x, turret_y - 4))

    # =========================================================================
    # 7. MONSTERS (Clean 16x16 Pixel Art, Zero Bullets or Projectile Lines)
    # =========================================================================
    
    # A. THAT WITCH MONSTER / TALL MAN (Brain Slayer) - Left Middle!
    # Taller silhouette in dark flowing robe, glowing eyes, slender stance
    bs_sheet = Image.open(r'assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Brain_Slayer/BrainSlayerWalk.png').convert('RGBA')
    # Bbox in frame 0: (7, 2, 25, 24) -> 18x22 px native, scaled to 76x94 px (tall imposing figure)
    bs_crop = bs_sheet.crop((7, 2, 25, 24)).resize((76, 94), Image.Resampling.NEAREST)
    bs_pos = (72, 215) # Exactly Left Middle!
    canvas.alpha_composite(bs_crop, bs_pos)
    
    # B. SKELETON ARCHER - Lower Left Flank (Ready with bow, NO arrows/bullets)
    skel_sheet = Image.open(r'assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Undead/Skeleton/SkeletonWalk.png').convert('RGBA')
    skel_crop = skel_sheet.crop((8, 8, 24, 24)).resize((80, 80), Image.Resampling.NEAREST)
    skel_pos = (68, 335)
    canvas.alpha_composite(skel_crop, skel_pos)
    
    # C. GOBLIN CUTTHROAT - Bottom Left / Front Flank
    gob_sheet = Image.open(r'assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Base_Humanoids/Goblin/GoblinWalk.png').convert('RGBA')
    gob_crop = gob_sheet.crop((8, 8, 24, 24)).resize((76, 76), Image.Resampling.NEAREST)
    gob_pos = (180, 395)
    canvas.alpha_composite(gob_crop, gob_pos)
    
    # D. MINOTAUR JUGGERNAUT - Right Middle Flank (Facing Crucible & Player)
    mino_sheet = Image.open(r'assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Monsters/Minotaur/MinotaurWalk.png').convert('RGBA')
    mino_crop = mino_sheet.crop((6, 4, 26, 24)).resize((92, 92), Image.Resampling.NEAREST).transpose(Image.FLIP_LEFT_RIGHT)
    mino_pos = (455, 245)
    canvas.alpha_composite(mino_crop, mino_pos)
    
    # E. STONE GARGOYLE - Upper Right Flank (Swooping Down)
    garg_sheet = Image.open(r'assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Gargoyle/GargoyleFly.png').convert('RGBA')
    garg_crop = garg_sheet.crop((7, 6, 25, 24)).resize((82, 82), Image.Resampling.NEAREST).transpose(Image.FLIP_LEFT_RIGHT)
    garg_pos = (485, 135)
    canvas.alpha_composite(garg_crop, garg_pos)

    # =========================================================================
    # 8. PLAYER ON THE BOTTOM WITH 3 WEAPONS (Clean, Crisp, NO Projectile Streaks)
    # =========================================================================
    hero_center_x = 315
    hero_center_y = 370
    
    hero_sheet = Image.open(r'assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Base_Humanoids/Human/Base_Human/HumanWalk.png').convert('RGBA')
    hero_crop = hero_sheet.crop((8, 8, 24, 24)).resize((80, 80), Image.Resampling.NEAREST)
    
    # WEAPON 3: Heavy Greatsword Slung Diagonally Across Hero's Back
    greatsword_img = create_pixel_weapon("greatsword", scale=1).resize((46, 46), Image.Resampling.NEAREST)
    greatsword_rot = greatsword_img.rotate(32, resample=Image.Resampling.NEAREST)
    canvas.alpha_composite(greatsword_rot, (hero_center_x - 36, hero_center_y - 36))
    
    # Orbiting Plasma Blaster Drone floating above shoulder
    plasma_img = create_pixel_weapon("plasma_blaster", scale=1).resize((32, 32), Image.Resampling.NEAREST)
    canvas.alpha_composite(plasma_img, (hero_center_x - 52, hero_center_y - 38))
    draw.ellipse([hero_center_x - 56, hero_center_y - 42, hero_center_x - 16, hero_center_y - 2], outline=(45, 210, 245, 180), width=2)
    
    # Composite Hero Sprite in Center Foreground
    canvas.alpha_composite(hero_crop, (hero_center_x - 40, hero_center_y - 25))
    
    # WEAPON 1: Shotgun in Right Hand (Aiming right toward Minotaur)
    shotgun_img = create_pixel_weapon("shotgun", scale=1).resize((40, 40), Image.Resampling.NEAREST)
    shotgun_rot = shotgun_img.rotate(-12, resample=Image.Resampling.NEAREST)
    canvas.alpha_composite(shotgun_rot, (hero_center_x + 22, hero_center_y + 4))
    
    # WEAPON 2: Cryo Blaster in Left Hand (Aiming left-down toward monsters)
    cryo_img = create_pixel_weapon("cryo_blaster", scale=1).resize((38, 38), Image.Resampling.NEAREST)
    cryo_rot = cryo_img.rotate(16, resample=Image.Resampling.NEAREST).transpose(Image.FLIP_LEFT_RIGHT)
    canvas.alpha_composite(cryo_rot, (hero_center_x - 58, hero_center_y + 6))

    # =========================================================================
    # 9. SUBTLE AMBIENT HEARTH EMBERS (Warm Ambient Atmosphere, Non-Intrusive)
    # =========================================================================
    ember_layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ember_draw = ImageDraw.Draw(ember_layer)
    random.seed(101)
    for _ in range(28):
        ex = random.randint(100, W - 100)
        ey = random.randint(85, H - 45)
        # Avoid placing embers near player's weapons
        if (ex > hero_center_x - 70 and ex < hero_center_x + 70 and ey > hero_center_y - 30):
            continue
        esize = random.randint(2, 4)
        ecol = random.choice([
            (255, 220, 60, 180),
            (255, 140, 30, 160),
            (255, 80, 20, 140),
            (255, 255, 200, 200)
        ])
        ember_draw.rectangle([ex, ey, ex + esize, ey + esize], fill=ecol)
    canvas = Image.alpha_composite(canvas, ember_layer)
    draw = ImageDraw.Draw(canvas)

    # =========================================================================
    # 10. ON TOP SAYING "THE FURNACE" (Strictly Just "THE FURNACE", No Description)
    # =========================================================================
    font_path = "assets/Ultrapixel.ttf"
    font_title = ImageFont.truetype(font_path, 54)
    title_text = "THE FURNACE"
    
    # Clean, perfectly proportioned plaque fitting just "THE FURNACE"
    bw, bh = 420, 60
    bx = (W - bw) // 2
    by = 14
    
    # Plaque Plate (Deep dark background with gold & bronze trim)
    draw.rectangle([bx + 4, by + 4, bx + bw + 4, by + bh + 4], fill=(4, 5, 8, 225))
    draw.rectangle([bx, by, bx + bw, by + bh], fill=(14, 15, 22, 245))
    draw.rectangle([bx, by, bx + bw, by + bh], outline=(210, 145, 40, 255), width=2)
    draw.rectangle([bx + 3, by + 3, bx + bw - 3, by + bh - 3], outline=(110, 65, 30, 255), width=1)
    
    # Corner Bronze Rivets
    for rx, ry in [(bx + 6, by + 6), (bx + bw - 8, by + 6), (bx + 6, by + bh - 8), (bx + bw - 8, by + bh - 8)]:
        draw.rectangle([rx, ry, rx + 2, ry + 2], fill=(255, 215, 85, 255))
        
    t_bbox = font_title.getbbox(title_text)
    tw = t_bbox[2] - t_bbox[0]
    th = t_bbox[3] - t_bbox[1]
    tx = (W - tw) // 2
    ty = by + (bh - th) // 2 - 4
    
    # 3D Layered Pixel Drop Shadows for "THE FURNACE"
    draw.text((tx + 3, ty + 3), title_text, font=font_title, fill=(8, 5, 5, 255))
    draw.text((tx + 2, ty + 2), title_text, font=font_title, fill=(60, 20, 10, 255))
    draw.text((tx + 1, ty + 1), title_text, font=font_title, fill=(140, 45, 12, 255))
    # Fiery Inner Face
    draw.text((tx, ty), title_text, font=font_title, fill=(255, 210, 65, 255))
    draw.text((tx, ty - 1), title_text, font=font_title, fill=(255, 245, 160, 220))

    # =========================================================================
    # 11. ATMOSPHERIC BORDER VIGNETTE
    # =========================================================================
    vignette = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    v_draw = ImageDraw.Draw(vignette)
    v_draw.rectangle([0, 0, W - 1, H - 1], outline=(10, 11, 16, 180), width=6)
    v_draw.rectangle([0, 0, W - 1, H - 1], outline=(5, 6, 8, 230), width=3)
    canvas = Image.alpha_composite(canvas, vignette)

    # =========================================================================
    # 12. EXPORT STANDARD (630x500) AND HD (1260x1000)
    # =========================================================================
    out_std = canvas
    out_hd = canvas.resize((1260, 1000), Image.Resampling.NEAREST)
    
    paths = [
        r'C:/Users/User/Desktop/Projects/the-furnace/media/cover_thumbnail.png',
        r'C:/Users/User/Desktop/Projects/the-furnace/media/cover_thumbnail_hd.png',
        r'C:/Users/User/Desktop/Projects/the-furnace/media/thumbnail.png',
        r'C:/Users/User/Desktop/Projects/the-furnace/thumbnail.png'
    ]
    
    out_std.save(paths[0])
    out_hd.save(paths[1])
    out_std.save(paths[2])
    out_std.save(paths[3])
    
    print("SUCCESS: Generated and saved polished thumbnails to:")
    for p in paths:
        print(" ->", p)

if __name__ == '__main__':
    build_complete_thumbnail()
