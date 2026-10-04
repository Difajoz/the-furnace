# visual_factory.gd - 8-Bit Pixel Art Texture Generator and Visual Helpers
class_name VisualFactory
extends RefCounted

static var texture_cache: Dictionary = {}

static func get_furnace_texture(stage: int, anim_frame: int = 0) -> ImageTexture:
	var key = "furnace_%d_%d" % [stage, anim_frame % 4]
	if texture_cache.has(key):
		return texture_cache[key]
		
	# 32x32 8-bit pixel art furnace
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var C_DARK = Color8(22, 23, 30)
	var C_IRON_DARK = Color8(38, 41, 52)
	var C_IRON_MID = Color8(58, 64, 82)
	var C_IRON_LIGHT = Color8(88, 97, 122)
	var C_BRONZE_DARK = Color8(105, 62, 32)
	var C_BRONZE_MID = Color8(166, 107, 50)
	var C_BRONZE_LIGHT = Color8(214, 150, 81)
	var C_RIVET = Color8(235, 192, 124)
	
	# Chimney (X: 11..20, Y: 1..8)
	for y in range(1, 9):
		for x in range(11, 21):
			if x == 11 or x == 20 or y == 1:
				img.set_pixel(x, y, C_DARK)
			elif x == 12 or y == 2:
				img.set_pixel(x, y, C_IRON_LIGHT)
			else:
				img.set_pixel(x, y, C_IRON_MID)
				
	# Chimney rim cap (X: 10..21, Y: 1..2)
	for x in range(10, 22):
		img.set_pixel(x, 1, C_BRONZE_MID)
		img.set_pixel(x, 2, C_BRONZE_DARK)
		
	# Main Furnace Body (X: 4..27, Y: 8..29)
	for y in range(8, 30):
		for x in range(4, 28):
			# Base shape with chamfered corners
			if (x <= 5 and y <= 9) or (x >= 26 and y <= 9) or (x <= 4 and y >= 29) or (x >= 27 and y >= 29):
				continue
				
			# Outline
			if x == 4 or x == 27 or y == 8 or y == 29 or (x == 5 and y == 9) or (x == 26 and y == 9):
				img.set_pixel(x, y, C_DARK)
			elif x == 5 or y == 9:
				img.set_pixel(x, y, C_IRON_LIGHT)
			else:
				img.set_pixel(x, y, C_IRON_MID)
				
	# Bronze Reinforced Bands (Horizontal stripes at Y: 11, 25)
	for y in [11, 25]:
		for x in range(5, 27):
			img.set_pixel(x, y, C_BRONZE_MID)
			img.set_pixel(x, y + 1, C_BRONZE_DARK)
			
	# Corner Rivets
	for pt in [Vector2i(6, 11), Vector2i(25, 11), Vector2i(6, 25), Vector2i(25, 25), Vector2i(15, 11), Vector2i(16, 11)]:
		img.set_pixel(pt.x, pt.y, C_RIVET)
		
	# Central Crucible Forge Chamber (X: 9..22, Y: 14..23)
	var glow_colors = _get_furnace_glow_palette(stage, anim_frame)
	for y in range(14, 24):
		for x in range(9, 23):
			# Hearth border
			if x == 9 or x == 22 or y == 14 or y == 23:
				img.set_pixel(x, y, C_DARK)
			else:
				# Internal fire core gradient
				var dy = abs(y - 19)
				var dx = abs(x - 15.5)
				var dist = dx + dy
				var col_idx = int(clamp(dist - (anim_frame % 2) * 0.5, 0, glow_colors.size() - 1))
				img.set_pixel(x, y, glow_colors[col_idx])
				
	# Hearth Vertical Iron Grill Bars (X: 12, 15, 19 at Y: 15..22)
	for gx in [12, 15, 19]:
		for gy in range(15, 23):
			img.set_pixel(gx, gy, C_DARK)
			
	# Heavy Furnace Base Legs (X: 5..8, 23..26 at Y: 29..31)
	for y in range(29, 32):
		for x in range(5, 9):
			img.set_pixel(x, y, C_DARK if y == 31 or x == 5 else C_IRON_DARK)
		for x in range(23, 27):
			img.set_pixel(x, y, C_DARK if y == 31 or x == 26 else C_IRON_DARK)
			
	var tex = ImageTexture.create_from_image(img)
	texture_cache[key] = tex
	return tex

static func _get_furnace_glow_palette(stage: int, frame: int) -> Array[Color]:
	match stage:
		0: # LOW / STABLE
			return [Color8(255, 220, 100), Color8(255, 150, 30), Color8(180, 60, 10), Color8(90, 20, 10)]
		1: # MEDIUM / WARMING
			return [Color8(255, 245, 150), Color8(255, 180, 40), Color8(220, 90, 20), Color8(130, 30, 10)]
		2: # HIGH HEAT
			return [Color8(255, 255, 200), Color8(255, 210, 60), Color8(255, 120, 20), Color8(180, 40, 10)]
		3: # CRITICAL / HIGH SURGE (Molten Blazing White-Hot)
			if frame % 2 == 0:
				return [Color8(255, 255, 255), Color8(255, 255, 160), Color8(255, 140, 40), Color8(220, 50, 20)]
			else:
				return [Color8(255, 255, 220), Color8(255, 230, 100), Color8(255, 100, 30), Color8(190, 30, 10)]
		4: # OVERHEATED / MELTDOWN (Cracked Smoking Ash)
			return [Color8(120, 40, 30), Color8(70, 25, 25), Color8(40, 20, 20), Color8(20, 15, 15)]
		_:
			return [Color8(255, 150, 30), Color8(180, 60, 10), Color8(90, 20, 10), Color8(40, 10, 10)]

static func get_weapon_texture(weapon_id: String) -> ImageTexture:
	var key = "wep_8bit_" + weapon_id
	if texture_cache.has(key):
		return texture_cache[key]
		
	var img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	var C_BLACK = Color8(15, 15, 20)
	var C_DARK = Color8(25, 25, 32)
	var C_GREY = Color8(90, 95, 105)
	var C_SILVER = Color8(175, 185, 200)
	var C_WHITE = Color8(240, 245, 255)
	var C_BROWN = Color8(115, 65, 30)
	var C_GOLD = Color8(245, 190, 35)
	var C_RED = Color8(230, 45, 45)
	var C_CYAN = Color8(45, 210, 245)
	var C_GREEN = Color8(55, 215, 65)
	var C_BLUE = Color8(40, 120, 240)
	
	match weapon_id:
		"pistol":
			img.set_pixel(1, 4, C_BROWN); img.set_pixel(2, 5, C_BROWN); img.set_pixel(2, 6, C_BLACK)
			img.set_pixel(2, 3, C_GREY); img.set_pixel(3, 3, C_SILVER); img.set_pixel(4, 3, C_SILVER); img.set_pixel(5, 3, C_SILVER); img.set_pixel(6, 3, C_BLACK)
			img.set_pixel(3, 4, C_BLACK)
		"smg":
			img.set_pixel(1, 4, C_BLACK); img.set_pixel(1, 5, C_GREY); img.set_pixel(1, 6, C_BLACK)
			img.set_pixel(2, 3, C_GREY); img.set_pixel(3, 3, C_SILVER); img.set_pixel(4, 3, C_SILVER); img.set_pixel(5, 3, C_GREY); img.set_pixel(6, 3, C_BLACK)
			img.set_pixel(4, 4, C_BLACK); img.set_pixel(4, 5, C_GREY); img.set_pixel(4, 6, C_BLACK)
		"shotgun":
			img.set_pixel(0, 5, C_BROWN); img.set_pixel(1, 4, C_BROWN); img.set_pixel(2, 4, C_BROWN)
			img.set_pixel(3, 3, C_GREY); img.set_pixel(4, 3, C_SILVER); img.set_pixel(5, 3, C_SILVER); img.set_pixel(6, 3, C_SILVER); img.set_pixel(7, 3, C_BLACK)
			img.set_pixel(4, 4, C_BROWN); img.set_pixel(5, 4, C_GREY)
		"assault_rifle":
			img.set_pixel(0, 5, C_BLACK); img.set_pixel(1, 4, C_GREY); img.set_pixel(2, 4, C_BLACK)
			img.set_pixel(2, 3, C_GREEN); img.set_pixel(3, 3, C_GREEN); img.set_pixel(4, 3, C_SILVER); img.set_pixel(5, 3, C_SILVER); img.set_pixel(6, 3, C_SILVER); img.set_pixel(7, 3, C_BLACK)
			img.set_pixel(3, 4, C_BLACK); img.set_pixel(3, 5, C_GREY)
		"sniper":
			img.set_pixel(0, 5, C_BLACK); img.set_pixel(1, 4, C_GREY)
			img.set_pixel(2, 3, C_GREY); img.set_pixel(3, 3, C_SILVER); img.set_pixel(4, 3, C_SILVER); img.set_pixel(5, 3, C_SILVER); img.set_pixel(6, 3, C_SILVER); img.set_pixel(7, 3, C_BLACK)
			img.set_pixel(3, 2, C_CYAN); img.set_pixel(4, 2, C_CYAN)
			img.set_pixel(2, 5, C_BLACK)
		"flamethrower":
			img.set_pixel(1, 4, C_BROWN); img.set_pixel(2, 5, C_BROWN)
			img.set_pixel(2, 3, C_GOLD); img.set_pixel(3, 3, C_GOLD); img.set_pixel(4, 3, C_RED); img.set_pixel(5, 3, C_RED); img.set_pixel(6, 3, C_BLACK)
			img.set_pixel(7, 3, C_GOLD); img.set_pixel(7, 2, C_RED)
			img.set_pixel(3, 4, C_RED); img.set_pixel(4, 4, C_RED)
		"rocket_launcher":
			img.set_pixel(0, 3, C_BLACK); img.set_pixel(1, 3, C_GREEN); img.set_pixel(2, 3, C_GREEN); img.set_pixel(3, 3, C_GREEN); img.set_pixel(4, 3, C_GREEN); img.set_pixel(5, 3, C_BLACK)
			img.set_pixel(1, 4, C_BLACK); img.set_pixel(2, 4, C_GREEN); img.set_pixel(3, 4, C_GREEN); img.set_pixel(4, 4, C_GREEN); img.set_pixel(5, 4, C_BLACK)
			img.set_pixel(6, 3, C_RED); img.set_pixel(6, 4, C_RED); img.set_pixel(7, 3, C_GOLD)
			img.set_pixel(2, 5, C_BLACK)
		"plasma_blaster":
			img.set_pixel(1, 4, C_BLACK); img.set_pixel(2, 5, C_BLACK)
			img.set_pixel(2, 3, C_GREY); img.set_pixel(3, 3, C_CYAN); img.set_pixel(4, 3, C_WHITE); img.set_pixel(5, 3, C_CYAN); img.set_pixel(6, 3, C_SILVER); img.set_pixel(7, 3, C_CYAN)
			img.set_pixel(3, 4, C_CYAN); img.set_pixel(4, 4, C_CYAN)
		"tesla_coil":
			img.set_pixel(3, 6, C_BROWN); img.set_pixel(3, 5, C_SILVER); img.set_pixel(3, 4, C_SILVER); img.set_pixel(3, 3, C_GOLD); img.set_pixel(3, 2, C_GOLD)
			img.set_pixel(2, 2, C_GOLD); img.set_pixel(4, 2, C_GOLD); img.set_pixel(3, 1, C_CYAN); img.set_pixel(2, 1, C_CYAN); img.set_pixel(4, 1, C_CYAN)
		"bone_crossbow":
			img.set_pixel(3, 7, C_BROWN); img.set_pixel(3, 6, C_BROWN); img.set_pixel(3, 5, C_SILVER); img.set_pixel(3, 4, C_WHITE); img.set_pixel(3, 3, C_WHITE); img.set_pixel(3, 2, C_WHITE)
			img.set_pixel(1, 4, C_WHITE); img.set_pixel(2, 3, C_WHITE); img.set_pixel(4, 3, C_WHITE); img.set_pixel(5, 4, C_WHITE)
			img.set_pixel(0, 4, C_GREY); img.set_pixel(6, 4, C_GREY)
		"laser_cannon":
			img.set_pixel(1, 4, C_BLACK); img.set_pixel(2, 5, C_BLACK)
			img.set_pixel(2, 3, C_GREY); img.set_pixel(3, 3, C_SILVER); img.set_pixel(4, 3, C_RED); img.set_pixel(5, 3, C_RED); img.set_pixel(6, 3, C_WHITE); img.set_pixel(7, 3, C_RED)
			img.set_pixel(4, 2, C_RED); img.set_pixel(5, 2, C_WHITE)
		"sledgehammer":
			img.set_pixel(1, 6, C_BROWN); img.set_pixel(2, 5, C_BROWN); img.set_pixel(3, 4, C_BROWN); img.set_pixel(4, 3, C_BROWN)
			img.set_pixel(4, 1, C_SILVER); img.set_pixel(5, 1, C_GREY); img.set_pixel(6, 1, C_BLACK)
			img.set_pixel(3, 2, C_WHITE); img.set_pixel(4, 2, C_SILVER); img.set_pixel(5, 2, C_GREY); img.set_pixel(6, 2, C_BLACK)
			img.set_pixel(3, 3, C_SILVER); img.set_pixel(4, 3, C_GREY); img.set_pixel(5, 3, C_BLACK)
		"cryo_blaster":
			img.set_pixel(1, 4, C_BLACK); img.set_pixel(2, 5, C_BLACK)
			img.set_pixel(2, 3, C_BLUE); img.set_pixel(3, 3, C_CYAN); img.set_pixel(4, 3, C_WHITE); img.set_pixel(5, 3, C_CYAN); img.set_pixel(6, 3, C_BLUE); img.set_pixel(7, 3, C_CYAN)
			img.set_pixel(3, 4, C_BLUE); img.set_pixel(4, 4, C_CYAN)
		"acid_mortar":
			img.set_pixel(1, 5, C_BLACK); img.set_pixel(2, 5, C_BLACK)
			img.set_pixel(2, 4, C_DARK); img.set_pixel(3, 3, C_GREEN); img.set_pixel(4, 3, C_GREEN); img.set_pixel(5, 2, C_GREEN); img.set_pixel(6, 2, C_DARK)
			img.set_pixel(3, 4, C_GREEN); img.set_pixel(4, 4, C_GREEN); img.set_pixel(5, 3, C_GREEN)
		"holy_sprinkler":
			img.set_pixel(1, 4, C_BLACK); img.set_pixel(2, 5, C_BLACK)
			img.set_pixel(2, 3, C_GOLD); img.set_pixel(3, 3, C_CYAN); img.set_pixel(4, 3, C_WHITE); img.set_pixel(5, 3, C_CYAN); img.set_pixel(6, 3, C_GOLD); img.set_pixel(7, 3, C_BLUE)
			img.set_pixel(3, 4, C_BLUE); img.set_pixel(4, 4, C_BLUE)
		"greatsword":
			img.set_pixel(1, 6, C_BROWN); img.set_pixel(2, 5, C_GOLD); img.set_pixel(3, 5, C_GOLD); img.set_pixel(2, 4, C_GOLD)
			img.set_pixel(3, 4, C_SILVER); img.set_pixel(4, 3, C_WHITE); img.set_pixel(5, 2, C_WHITE); img.set_pixel(6, 1, C_WHITE)
			img.set_pixel(4, 4, C_SILVER); img.set_pixel(5, 3, C_SILVER); img.set_pixel(6, 2, C_SILVER); img.set_pixel(7, 1, C_SILVER)
		"dagger":
			img.set_pixel(1, 6, C_BROWN); img.set_pixel(2, 5, C_GOLD); img.set_pixel(3, 4, C_WHITE); img.set_pixel(4, 3, C_WHITE)
			img.set_pixel(3, 5, C_SILVER); img.set_pixel(4, 4, C_SILVER); img.set_pixel(5, 3, C_SILVER)
		"fire_spell":
			img.set_pixel(1, 6, C_BROWN); img.set_pixel(2, 5, C_BROWN); img.set_pixel(3, 4, C_BROWN); img.set_pixel(4, 3, C_GOLD)
			img.set_pixel(4, 2, C_RED); img.set_pixel(5, 2, C_GOLD); img.set_pixel(5, 1, C_RED); img.set_pixel(6, 2, C_WHITE); img.set_pixel(6, 3, C_RED)
		"ice_spell":
			img.set_pixel(1, 6, C_BROWN); img.set_pixel(2, 5, C_BROWN); img.set_pixel(3, 4, C_BROWN); img.set_pixel(4, 3, C_SILVER)
			img.set_pixel(4, 2, C_BLUE); img.set_pixel(5, 2, C_CYAN); img.set_pixel(5, 1, C_WHITE); img.set_pixel(6, 2, C_CYAN); img.set_pixel(6, 3, C_BLUE)
		"lightning_spell":
			img.set_pixel(1, 6, C_BROWN); img.set_pixel(2, 5, C_BROWN); img.set_pixel(3, 4, C_BROWN); img.set_pixel(4, 3, C_GOLD)
			img.set_pixel(4, 2, C_GOLD); img.set_pixel(5, 2, C_WHITE); img.set_pixel(5, 1, C_CYAN); img.set_pixel(6, 2, C_GOLD); img.set_pixel(6, 3, C_CYAN)
		"poison_spell":
			img.set_pixel(2, 5, C_DARK); img.set_pixel(3, 5, C_GREEN); img.set_pixel(4, 5, C_DARK)
			img.set_pixel(2, 4, C_GREEN); img.set_pixel(3, 4, C_GREEN); img.set_pixel(4, 4, C_GREEN)
			img.set_pixel(2, 3, C_DARK); img.set_pixel(3, 3, C_WHITE); img.set_pixel(4, 3, C_DARK); img.set_pixel(3, 2, C_GREEN)
		"bone_boomerang":
			img.set_pixel(1, 1, C_WHITE); img.set_pixel(2, 2, C_WHITE); img.set_pixel(3, 3, C_WHITE); img.set_pixel(4, 3, C_WHITE)
			img.set_pixel(5, 2, C_WHITE); img.set_pixel(6, 1, C_WHITE); img.set_pixel(2, 3, C_GREY); img.set_pixel(5, 3, C_GREY)
		"gatling_minigun":
			img.set_pixel(0, 4, C_BLACK); img.set_pixel(1, 4, C_GREY); img.set_pixel(2, 4, C_BLACK)
			img.set_pixel(2, 2, C_DARK); img.set_pixel(3, 2, C_SILVER); img.set_pixel(4, 2, C_SILVER); img.set_pixel(5, 2, C_SILVER); img.set_pixel(6, 2, C_BLACK)
			img.set_pixel(2, 3, C_DARK); img.set_pixel(3, 3, C_SILVER); img.set_pixel(4, 3, C_SILVER); img.set_pixel(5, 3, C_SILVER); img.set_pixel(6, 3, C_BLACK)
			img.set_pixel(3, 5, C_GOLD); img.set_pixel(4, 5, C_GOLD)
		"void_black_hole_cannon":
			img.set_pixel(1, 4, C_DARK); img.set_pixel(2, 5, C_DARK)
			img.set_pixel(2, 3, C_DARK); img.set_pixel(3, 3, Color8(140, 40, 220)); img.set_pixel(4, 3, Color8(200, 80, 255)); img.set_pixel(5, 3, Color8(140, 40, 220)); img.set_pixel(6, 3, C_DARK)
			img.set_pixel(4, 2, Color8(200, 80, 255)); img.set_pixel(4, 4, Color8(200, 80, 255))
		"shuriken_spinner":
			img.set_pixel(3, 1, C_SILVER); img.set_pixel(4, 1, C_WHITE)
			img.set_pixel(1, 3, C_WHITE); img.set_pixel(2, 3, C_SILVER); img.set_pixel(3, 3, C_BLACK); img.set_pixel(4, 3, C_BLACK); img.set_pixel(5, 3, C_SILVER); img.set_pixel(6, 3, C_WHITE)
			img.set_pixel(3, 4, C_BLACK); img.set_pixel(4, 4, C_BLACK)
			img.set_pixel(3, 6, C_WHITE); img.set_pixel(4, 6, C_SILVER)
		"flame_revolver":
			img.set_pixel(1, 4, C_BROWN); img.set_pixel(2, 5, C_BROWN)
			img.set_pixel(2, 3, C_GOLD); img.set_pixel(3, 3, C_GOLD); img.set_pixel(4, 3, C_RED); img.set_pixel(5, 3, C_RED); img.set_pixel(6, 3, C_BLACK)
			img.set_pixel(3, 2, C_RED); img.set_pixel(3, 4, C_GOLD)
		"arcane_missiles":
			img.set_pixel(1, 6, C_BROWN); img.set_pixel(2, 5, C_BROWN); img.set_pixel(3, 4, C_GOLD)
			img.set_pixel(4, 2, Color8(180, 70, 255)); img.set_pixel(5, 2, C_WHITE); img.set_pixel(6, 2, Color8(180, 70, 255))
			img.set_pixel(5, 1, Color8(180, 70, 255)); img.set_pixel(5, 3, Color8(180, 70, 255))
		"frost_scythe":
			img.set_pixel(1, 6, C_BROWN); img.set_pixel(2, 5, C_BROWN); img.set_pixel(3, 4, C_BROWN); img.set_pixel(4, 3, C_BROWN); img.set_pixel(5, 2, C_CYAN)
			img.set_pixel(6, 1, C_CYAN); img.set_pixel(7, 1, C_WHITE); img.set_pixel(7, 2, C_CYAN); img.set_pixel(6, 3, C_BLUE)
		"meteor_staff":
			img.set_pixel(1, 6, C_BROWN); img.set_pixel(2, 5, C_BROWN); img.set_pixel(3, 4, C_BROWN); img.set_pixel(4, 3, C_GOLD)
			img.set_pixel(4, 1, C_RED); img.set_pixel(5, 1, C_GOLD); img.set_pixel(6, 1, C_RED); img.set_pixel(5, 2, C_RED)
		"magma_shotgun":
			img.set_pixel(0, 5, C_BROWN); img.set_pixel(1, 4, C_DARK); img.set_pixel(2, 4, C_DARK)
			img.set_pixel(3, 3, C_RED); img.set_pixel(4, 3, C_GOLD); img.set_pixel(5, 3, C_RED); img.set_pixel(6, 3, C_GOLD); img.set_pixel(7, 3, C_BLACK)
			img.set_pixel(4, 4, C_RED); img.set_pixel(5, 4, C_GOLD)
		"glacier_rifle":
			img.set_pixel(0, 5, C_DARK); img.set_pixel(1, 4, C_CYAN); img.set_pixel(2, 4, C_DARK)
			img.set_pixel(2, 3, C_BLUE); img.set_pixel(3, 3, C_CYAN); img.set_pixel(4, 3, C_WHITE); img.set_pixel(5, 3, C_CYAN); img.set_pixel(6, 3, C_WHITE); img.set_pixel(7, 3, C_CYAN)
			img.set_pixel(3, 2, C_WHITE); img.set_pixel(4, 2, C_CYAN)
		"twin_dragon":
			img.set_pixel(1, 5, C_DARK); img.set_pixel(2, 5, C_DARK)
			img.set_pixel(2, 2, C_RED); img.set_pixel(3, 2, C_GOLD); img.set_pixel(4, 2, C_RED); img.set_pixel(5, 2, C_GOLD); img.set_pixel(6, 2, C_BLACK)
			img.set_pixel(2, 4, C_BLUE); img.set_pixel(3, 4, C_CYAN); img.set_pixel(4, 4, C_BLUE); img.set_pixel(5, 4, C_CYAN); img.set_pixel(6, 4, C_BLACK)
			img.set_pixel(3, 3, C_DARK); img.set_pixel(4, 3, C_GOLD)
		"ricochet_revolver":
			img.set_pixel(1, 5, C_BROWN); img.set_pixel(2, 6, C_BROWN)
			img.set_pixel(2, 3, C_GOLD); img.set_pixel(3, 3, C_GOLD); img.set_pixel(4, 3, C_GOLD); img.set_pixel(5, 3, C_SILVER); img.set_pixel(6, 3, C_BLACK)
			img.set_pixel(3, 4, C_GOLD); img.set_pixel(4, 4, C_GOLD)
		"toxic_needle":
			img.set_pixel(1, 5, C_DARK); img.set_pixel(2, 5, C_DARK)
			img.set_pixel(2, 3, C_DARK); img.set_pixel(3, 3, C_GREEN); img.set_pixel(4, 3, C_GREEN); img.set_pixel(5, 3, C_WHITE); img.set_pixel(6, 3, C_GREEN); img.set_pixel(7, 3, C_GREEN)
			img.set_pixel(3, 2, C_GREEN); img.set_pixel(4, 4, C_GREEN)
		"saw_launcher":
			img.set_pixel(0, 4, C_DARK); img.set_pixel(1, 4, C_GREY)
			img.set_pixel(2, 3, C_GREY); img.set_pixel(3, 3, C_SILVER); img.set_pixel(4, 3, C_SILVER); img.set_pixel(5, 3, C_DARK)
			img.set_pixel(4, 1, C_WHITE); img.set_pixel(5, 1, C_SILVER); img.set_pixel(6, 2, C_WHITE); img.set_pixel(6, 3, C_SILVER); img.set_pixel(5, 4, C_WHITE)
		"cluster_mortar":
			img.set_pixel(0, 4, C_DARK); img.set_pixel(1, 4, C_GREY); img.set_pixel(2, 4, C_DARK)
			img.set_pixel(2, 2, C_RED); img.set_pixel(3, 2, C_RED); img.set_pixel(4, 2, C_RED); img.set_pixel(5, 2, C_BLACK)
			img.set_pixel(2, 3, C_GOLD); img.set_pixel(3, 3, C_RED); img.set_pixel(4, 3, C_RED); img.set_pixel(5, 3, C_BLACK)
			img.set_pixel(6, 2, C_GOLD); img.set_pixel(6, 3, C_GOLD)
		"chrono_blaster":
			img.set_pixel(1, 5, C_DARK); img.set_pixel(2, 5, C_DARK)
			img.set_pixel(2, 3, C_BLUE); img.set_pixel(3, 3, C_CYAN); img.set_pixel(4, 3, C_WHITE); img.set_pixel(5, 3, C_CYAN); img.set_pixel(6, 3, C_BLUE)
			img.set_pixel(4, 1, C_CYAN); img.set_pixel(4, 5, C_CYAN); img.set_pixel(3, 2, C_BLUE); img.set_pixel(5, 2, C_BLUE)
		"arcane_splitter":
			img.set_pixel(1, 6, C_BROWN); img.set_pixel(2, 5, C_BROWN); img.set_pixel(3, 4, C_GOLD)
			img.set_pixel(4, 2, Color8(210, 80, 255)); img.set_pixel(5, 2, C_WHITE); img.set_pixel(6, 2, Color8(210, 80, 255))
			img.set_pixel(5, 1, Color8(235, 140, 255)); img.set_pixel(5, 3, Color8(235, 140, 255))
		"thunder_bow":
			img.set_pixel(3, 7, C_BLUE); img.set_pixel(3, 6, C_CYAN); img.set_pixel(3, 5, C_CYAN); img.set_pixel(3, 4, C_WHITE); img.set_pixel(3, 3, C_GOLD); img.set_pixel(3, 2, C_CYAN)
			img.set_pixel(1, 4, C_GOLD); img.set_pixel(2, 3, C_CYAN); img.set_pixel(4, 3, C_CYAN); img.set_pixel(5, 4, C_GOLD)
			img.set_pixel(0, 4, C_WHITE); img.set_pixel(6, 4, C_WHITE)
		"inferno_repeater":
			img.set_pixel(1, 5, C_DARK); img.set_pixel(2, 5, C_DARK)
			img.set_pixel(2, 3, C_RED); img.set_pixel(3, 3, C_GOLD); img.set_pixel(4, 3, C_RED); img.set_pixel(5, 3, C_GOLD); img.set_pixel(6, 3, C_BLACK)
			img.set_pixel(3, 2, C_GOLD); img.set_pixel(5, 2, C_GOLD); img.set_pixel(3, 4, C_RED)
		"frostfire_cannon":
			img.set_pixel(1, 5, C_BLACK); img.set_pixel(2, 5, C_BLACK)
			img.set_pixel(2, 3, C_BLUE); img.set_pixel(3, 3, C_CYAN); img.set_pixel(4, 3, C_WHITE); img.set_pixel(5, 3, C_RED); img.set_pixel(6, 3, C_GOLD); img.set_pixel(7, 3, C_BLACK)
			img.set_pixel(3, 2, C_CYAN); img.set_pixel(5, 2, C_RED); img.set_pixel(3, 4, C_BLUE); img.set_pixel(5, 4, C_GOLD)
		"arcane_railgun":
			img.set_pixel(0, 5, C_BLACK); img.set_pixel(1, 4, C_DARK); img.set_pixel(2, 4, C_DARK)
			img.set_pixel(2, 3, Color8(180, 50, 255)); img.set_pixel(3, 3, Color8(230, 120, 255)); img.set_pixel(4, 3, C_WHITE); img.set_pixel(5, 3, C_WHITE); img.set_pixel(6, 3, Color8(230, 120, 255)); img.set_pixel(7, 3, Color8(180, 50, 255))
			img.set_pixel(3, 2, Color8(230, 120, 255)); img.set_pixel(5, 2, Color8(230, 120, 255)); img.set_pixel(3, 4, Color8(180, 50, 255)); img.set_pixel(5, 4, Color8(180, 50, 255))
		"cluster_flak_cannon":
			img.set_pixel(0, 5, C_BLACK); img.set_pixel(1, 4, C_GREY); img.set_pixel(2, 4, C_GREY)
			img.set_pixel(2, 2, C_DARK); img.set_pixel(3, 2, C_RED); img.set_pixel(4, 2, C_GOLD); img.set_pixel(5, 2, C_RED); img.set_pixel(6, 2, C_BLACK)
			img.set_pixel(2, 3, C_DARK); img.set_pixel(3, 3, C_RED); img.set_pixel(4, 3, C_WHITE); img.set_pixel(5, 3, C_GOLD); img.set_pixel(6, 3, C_BLACK)
			img.set_pixel(2, 4, C_DARK); img.set_pixel(3, 4, C_RED); img.set_pixel(4, 4, C_GOLD); img.set_pixel(5, 4, C_RED); img.set_pixel(6, 4, C_BLACK)
		"chain_bolter":
			img.set_pixel(0, 4, C_BLACK); img.set_pixel(1, 4, C_GREY); img.set_pixel(2, 4, C_BLACK)
			img.set_pixel(2, 3, C_GOLD); img.set_pixel(3, 3, C_CYAN); img.set_pixel(4, 3, C_WHITE); img.set_pixel(5, 3, C_CYAN); img.set_pixel(6, 3, C_GOLD); img.set_pixel(7, 3, C_BLACK)
			img.set_pixel(4, 2, C_GOLD); img.set_pixel(4, 4, C_GOLD); img.set_pixel(3, 5, C_GREY)
		"gravity_imploder":
			img.set_pixel(1, 5, C_DARK); img.set_pixel(2, 5, C_DARK)
			img.set_pixel(2, 3, Color8(120, 20, 200)); img.set_pixel(3, 3, Color8(170, 50, 255)); img.set_pixel(4, 3, Color8(220, 100, 255)); img.set_pixel(5, 3, Color8(170, 50, 255)); img.set_pixel(6, 3, Color8(120, 20, 200))
			img.set_pixel(4, 1, Color8(170, 50, 255)); img.set_pixel(4, 5, Color8(170, 50, 255)); img.set_pixel(3, 2, Color8(220, 100, 255)); img.set_pixel(5, 2, Color8(220, 100, 255))
		"dragon_breath":
			img.set_pixel(1, 5, C_BROWN); img.set_pixel(2, 6, C_BROWN)
			img.set_pixel(2, 3, C_GOLD); img.set_pixel(3, 3, C_RED); img.set_pixel(4, 3, C_GOLD); img.set_pixel(5, 3, C_RED); img.set_pixel(6, 3, C_GOLD); img.set_pixel(7, 3, C_BLACK)
			img.set_pixel(3, 2, C_RED); img.set_pixel(5, 2, C_GOLD); img.set_pixel(3, 4, C_GOLD); img.set_pixel(5, 4, C_RED)
		_:
			img.set_pixel(2, 4, C_BROWN); img.set_pixel(3, 3, C_SILVER); img.set_pixel(4, 3, C_SILVER); img.set_pixel(5, 3, C_BLACK)

	# 3x Crisp Pixel Art Upscale (8x8 -> 24x24)
	img.resize(24, 24, Image.INTERPOLATE_NEAREST)
	var tex = ImageTexture.create_from_image(img)
	texture_cache[key] = tex
	return tex

static func get_item_icon(item: Dictionary) -> Texture2D:
	var item_type = item.get("type", "")
	if item_type == "weapon":
		var wep_id = item.get("base_weapon_id", item.get("id", "pistol"))
		return get_weapon_texture(wep_id)
		
	if item_type == "turret":
		var icon_name = item.get("icon", "turret_arrow")
		var p = "res://assets/turrets/icon_%s.png" % icon_name
		if ResourceLoader.exists(p):
			return load(p)
	
	var icon_name = item.get("icon", item.get("id", "generic"))
	return get_icon_texture(icon_name, item_type)

static func get_icon_texture(icon_id: String, item_type: String = "") -> Texture2D:
	if icon_id.begins_with("turret_"):
		var p = "res://assets/turrets/icon_%s.png" % icon_id
		if ResourceLoader.exists(p):
			return load(p)
			
	var key = "icon_24x24_" + icon_id
	if texture_cache.has(key):
		return texture_cache[key]
		
	var img = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	var C_DARK = Color8(15, 16, 22)
	var C_BLACK = Color8(8, 8, 12)
	var C_WHITE = Color8(245, 250, 255)
	var C_GOLD = Color8(255, 205, 35)
	var C_GOLD_DARK = Color8(185, 120, 15)
	var C_RED = Color8(245, 45, 45)
	var C_RED_DARK = Color8(140, 20, 20)
	var C_CYAN = Color8(45, 220, 255)
	var C_CYAN_DARK = Color8(15, 110, 160)
	var C_BLUE = Color8(35, 125, 245)
	var C_GREEN = Color8(45, 235, 75)
	var C_GREEN_DARK = Color8(15, 120, 35)
	var C_PURPLE = Color8(210, 65, 255)
	var C_PURPLE_DARK = Color8(110, 20, 150)
	var C_ORANGE = Color8(255, 130, 25)
	var C_SILVER = Color8(180, 190, 205)
	var C_GREY = Color8(95, 105, 120)
	var C_BROWN = Color8(120, 70, 30)

	match icon_id:
		"heart", "max_hp", "vitality_surge":
			# 24x24 Glowing Ruby Heart
			for y in range(4, 21):
				for x in range(3, 21):
					var inside = false
					if y < 11:
						if (x >= 4 and x <= 10) or (x >= 13 and x <= 19):
							if not ((x == 4 or x == 10) and y == 4) and not ((x == 13 or x == 19) and y == 4):
								inside = true
					else:
						var shrink = (y - 10)
						if x >= 3 + shrink and x <= 20 - shrink:
							inside = true
					if inside:
						if x == 3 or x == 20 or y == 4 or (y >= 18 and (x == 3 + (y-10) or x == 20 - (y-10))):
							img.set_pixel(x, y, C_RED_DARK)
						elif x <= 8 and y <= 9:
							img.set_pixel(x, y, C_WHITE if (x == 6 and y == 6) else Color8(255, 140, 160))
						else:
							img.set_pixel(x, y, C_RED)

		"cross", "regen", "hp_regen", "nanite_repair":
			# 24x24 Emerald Medical Cross
			for y in range(3, 21):
				for x in range(3, 21):
					if (x >= 8 and x <= 15) or (y >= 8 and y <= 15):
						if x == 8 or x == 15 or y == 8 or y == 15 or x == 3 or x == 20 or y == 3 or y == 20:
							img.set_pixel(x, y, C_GREEN_DARK)
						elif x >= 10 and x <= 13 and y >= 5 and y <= 8:
							img.set_pixel(x, y, C_WHITE)
						else:
							img.set_pixel(x, y, C_GREEN)

		"fist", "damage", "raw_damage", "sword":
			# 24x24 Crossed Broadswords
			for i in range(4, 20):
				img.set_pixel(i, i, C_WHITE)
				img.set_pixel(i, i - 1, C_SILVER)
				img.set_pixel(i - 1, i, C_RED)
				img.set_pixel(23 - i, i, C_WHITE)
				img.set_pixel(23 - i, i - 1, C_SILVER)
				img.set_pixel(24 - i, i, C_GOLD)
			# Crossguards
			for d in range(-3, 4):
				img.set_pixel(7 + d, 7 - d, C_GOLD)
				img.set_pixel(16 + d, 7 + d, C_GOLD)
			# Hilts
			img.set_pixel(4, 4, C_BROWN); img.set_pixel(5, 5, C_BROWN)
			img.set_pixel(19, 4, C_BROWN); img.set_pixel(18, 5, C_BROWN)

		"lightning", "speed_atk", "rapid_fire", "attack_speed":
			# 24x24 Electric Lightning Bolt
			var bolt_pts = [
				Vector2i(14, 2), Vector2i(9, 10), Vector2i(13, 10),
				Vector2i(8, 22), Vector2i(17, 11), Vector2i(13, 11)
			]
			for y in range(2, 22):
				for x in range(6, 18):
					var cx = 15 - int(float(y) * 0.4)
					if y >= 10 and y <= 12: cx += 3
					if abs(x - cx) <= 2:
						if abs(x - cx) == 2:
							img.set_pixel(x, y, C_GOLD_DARK)
						elif x == cx:
							img.set_pixel(x, y, C_WHITE)
						else:
							img.set_pixel(x, y, C_GOLD)
			img.set_pixel(8, 21, C_CYAN); img.set_pixel(8, 22, C_WHITE); img.set_pixel(9, 21, C_CYAN)

		"target", "crit", "critical_eye", "crit_chance":
			# 24x24 Sniper Precision Scope
			for a in range(32):
				var ang = float(a) / 32.0 * TAU
				var sx = int(12.0 + cos(ang) * 8.0)
				var sy = int(12.0 + sin(ang) * 8.0)
				if sx >= 0 and sx < 24 and sy >= 0 and sy < 24:
					img.set_pixel(sx, sy, C_CYAN)
			for i in range(3, 21):
				if i < 9 or i > 14:
					img.set_pixel(12, i, C_RED)
					img.set_pixel(i, 12, C_RED)
			img.set_pixel(12, 12, C_WHITE)
			img.set_pixel(11, 12, C_RED); img.set_pixel(13, 12, C_RED)
			img.set_pixel(12, 11, C_RED); img.set_pixel(12, 13, C_RED)

		"sparkle", "crit_mult":
			# 24x24 Golden Star of Power
			for y in range(2, 22):
				for x in range(2, 22):
					var dx = abs(x - 12)
					var dy = abs(y - 12)
					if (dx + dy <= 8) or (dx <= 1 and dy <= 10) or (dy <= 1 and dx <= 10):
						if dx == 0 and dy == 0:
							img.set_pixel(x, y, C_WHITE)
						elif dx + dy <= 3:
							img.set_pixel(x, y, C_WHITE)
						elif dx + dy <= 6:
							img.set_pixel(x, y, C_GOLD)
						else:
							img.set_pixel(x, y, C_ORANGE)

		"shield", "armor", "reinforced_plate":
			# 24x24 Riveted Heraldic Shield
			for y in range(3, 22):
				for x in range(4, 20):
					var inside = false
					if y <= 13:
						if x >= 4 and x <= 19: inside = true
					else:
						var s = y - 13
						if x >= 4 + s and x <= 19 - s: inside = true
					if inside:
						if x == 4 or x == 19 or y == 3 or (y > 13 and (x == 4 + (y-13) or x == 19 - (y-13))):
							img.set_pixel(x, y, C_DARK)
						elif x == 5 or x == 18 or y == 4 or (y > 13 and (x == 5 + (y-13) or x == 18 - (y-13))):
							img.set_pixel(x, y, C_GOLD)
						elif x == 11 or x == 12 or y == 8 or y == 9:
							img.set_pixel(x, y, C_WHITE)
						else:
							img.set_pixel(x, y, C_CYAN_DARK if x < 12 else C_BLUE)

		"boot", "boots", "move_speed", "titan_boots":
			# 24x24 Winged Armored Greaves
			for y in range(5, 19):
				for x in range(7, 18):
					if (y <= 13 and x >= 10 and x <= 15) or (y > 13 and x >= 7 and x <= 18):
						if y == 18 or x == 7 or (y <= 13 and (x == 10 or x == 15)):
							img.set_pixel(x, y, C_DARK)
						elif y == 14 and x >= 10 and x <= 14:
							img.set_pixel(x, y, C_WHITE)
						else:
							img.set_pixel(x, y, C_SILVER if x < 13 else C_GREY)
			# Wing
			for w in range(5):
				img.set_pixel(9 - w, 7 - w, C_GOLD)
				img.set_pixel(10 - w, 7 - w, C_WHITE)
				img.set_pixel(11 - w, 8 - w, C_GOLD)

		"drop", "lifesteal", "vampiric_edge":
			# 24x24 Crimson Vampire Fang & Blood Leech
			for y in range(4, 20):
				for x in range(7, 18):
					var cx = 12
					var r = int(float(y - 4) * 0.5)
					if y > 14: r = int(float(20 - y) * 0.7)
					if abs(x - cx) <= r:
						if abs(x - cx) == r:
							img.set_pixel(x, y, C_RED_DARK)
						elif x == cx - 1 and y >= 8 and y <= 12:
							img.set_pixel(x, y, C_WHITE)
						else:
							img.set_pixel(x, y, C_RED)
			# Dual Fangs
			img.set_pixel(6, 6, C_WHITE); img.set_pixel(6, 7, C_WHITE); img.set_pixel(6, 8, C_SILVER)
			img.set_pixel(17, 6, C_WHITE); img.set_pixel(17, 7, C_WHITE); img.set_pixel(17, 8, C_SILVER)

		"magnet", "pickup_radius", "magneto_core":
			# 24x24 Red & Blue Horseshoe Magnet
			for y in range(4, 20):
				for x in range(4, 20):
					var in_outer = (x >= 4 and x <= 19 and y >= 4 and y <= 19)
					var in_inner = (x >= 9 and x <= 14 and y <= 14)
					if in_outer and not in_inner:
						if x == 4 or x == 19 or y == 19:
							img.set_pixel(x, y, C_DARK)
						elif y <= 8:
							img.set_pixel(x, y, C_SILVER if (y == 4 or y == 5) else (C_RED if x < 12 else C_BLUE))
						else:
							img.set_pixel(x, y, C_RED if x < 12 else C_BLUE)
			# Spark
			img.set_pixel(11, 6, C_GOLD); img.set_pixel(12, 6, C_WHITE); img.set_pixel(12, 7, C_GOLD)

		"dice", "clover", "luck", "clover_charm":
			# 24x24 Four-Leaf Lucky Clover
			var centers = [Vector2i(8, 8), Vector2i(15, 8), Vector2i(8, 15), Vector2i(15, 15)]
			for c in centers:
				for dy in range(-3, 4):
					for dx in range(-3, 4):
						if abs(dx) + abs(dy) <= 4:
							var px = c.x + dx; var py = c.y + dy
							if px >= 0 and px < 24 and py >= 0 and py < 24:
								if abs(dx) + abs(dy) == 4:
									img.set_pixel(px, py, C_GREEN_DARK)
								elif dx == 0 and dy == 0:
									img.set_pixel(px, py, C_WHITE)
								else:
									img.set_pixel(px, py, C_GREEN)
			# Stem
			for s in range(5):
				img.set_pixel(12 + s, 16 + s, C_GREEN_DARK)

		"bone", "bone_capacity", "bone_satchel_expand":
			# 24x24 Bone Satchel
			for y in range(8, 20):
				for x in range(5, 19):
					if x == 5 or x == 18 or y == 8 or y == 19:
						img.set_pixel(x, y, C_DARK)
					elif y == 12 or x == 11 or x == 12:
						img.set_pixel(x, y, C_GOLD)
					else:
						img.set_pixel(x, y, C_BROWN)
			# Bone sticking out
			for b in range(6):
				img.set_pixel(7 + b, 8 - b, C_WHITE)
				img.set_pixel(8 + b, 8 - b, C_SILVER)
			img.set_pixel(6, 2, C_WHITE); img.set_pixel(7, 3, C_WHITE)
			img.set_pixel(13, 2, C_WHITE); img.set_pixel(14, 3, C_WHITE)

		"water", "water_tank", "water_backpack":
			# 24x24 Pressurized Aqua Canister
			for y in range(4, 21):
				for x in range(6, 18):
					if (y <= 6 and (x < 9 or x > 14)): continue
					if x == 6 or x == 17 or y == 20 or (y == 4 and x >= 9 and x <= 14):
						img.set_pixel(x, y, C_DARK)
					elif x >= 10 and x <= 13 and y >= 8 and y <= 16:
						img.set_pixel(x, y, C_WHITE if x == 10 else C_CYAN)
					else:
						img.set_pixel(x, y, C_BLUE)
			# Brass cap
			img.set_pixel(11, 3, C_GOLD); img.set_pixel(12, 3, C_GOLD)

		"ice", "cooling_efficiency", "super_coolant", "frost_nova", "active_frost_nova":
			# 24x24 Azure Snowflake Crystal
			for i in range(3, 21):
				img.set_pixel(12, i, C_CYAN)
				img.set_pixel(i, 12, C_CYAN)
				img.set_pixel(i, i, C_CYAN)
				img.set_pixel(23 - i, i, C_CYAN)
			img.set_pixel(12, 12, C_WHITE)
			img.set_pixel(11, 12, C_WHITE); img.set_pixel(13, 12, C_WHITE)
			img.set_pixel(12, 11, C_WHITE); img.set_pixel(12, 13, C_WHITE)
			# Crystal spikes
			for s in [Vector2i(8, 8), Vector2i(16, 8), Vector2i(8, 16), Vector2i(16, 16)]:
				img.set_pixel(s.x, s.y, C_WHITE)

		"pump", "hydro_pump":
			# 24x24 Industrial Impeller Pump
			for a in range(24):
				var ang = float(a) / 24.0 * TAU
				var sx = int(12.0 + cos(ang) * 7.0)
				var sy = int(12.0 + sin(ang) * 7.0)
				img.set_pixel(sx, sy, C_CYAN_DARK)
			for b in range(4):
				var bang = float(b) * (TAU / 4.0)
				for r in range(2, 8):
					var bx = int(12.0 + cos(bang + float(r) * 0.3) * float(r))
					var by = int(12.0 + sin(bang + float(r) * 0.3) * float(r))
					img.set_pixel(bx, by, C_CYAN)
			img.set_pixel(12, 12, C_WHITE)

		"frenzy", "frenzy_catalyst", "active_damage_boost":
			# 24x24 Blazing Overdrive Flame Skull
			for y in range(4, 21):
				for x in range(5, 19):
					var cx = 12
					var r = 6
					if y < 10: r = 4
					if abs(x - cx) <= r:
						if y <= 7 and ((x % 3 == 0) or (x == 12)):
							img.set_pixel(x, y, C_ORANGE)
						elif abs(x - cx) == r or y == 20:
							img.set_pixel(x, y, C_RED_DARK)
						elif (x == 9 and y == 13) or (x == 15 and y == 13):
							img.set_pixel(x, y, C_DARK) # Eye holes
						elif x == cx and y <= 15:
							img.set_pixel(x, y, C_WHITE if y <= 10 else C_GOLD)
						else:
							img.set_pixel(x, y, C_RED if y > 12 else C_ORANGE)

		"hopper", "bone_hopper_1", "bone_hopper_2":
			# 24x24 Iron Bone Hopper Chute
			for y in range(4, 20):
				var left = 4 + int(float(y - 4) * 0.35)
				var right = 19 - int(float(y - 4) * 0.35)
				for x in range(left, right + 1):
					if x == left or x == right or y == 4 or y == 19:
						img.set_pixel(x, y, C_DARK)
					elif y <= 8:
						img.set_pixel(x, y, C_WHITE if (x + y) % 2 == 0 else C_SILVER) # Bones
					else:
						img.set_pixel(x, y, C_GREY)

		"turbo", "turbo_smelter_1", "turbo_smelter_2":
			# 24x24 Smelting Turbo Turbine
			for a in range(4):
				var ang = float(a) * (TAU / 4.0)
				for r in range(2, 9):
					var tx = int(12.0 + cos(ang) * float(r))
					var ty = int(12.0 + sin(ang) * float(r))
					img.set_pixel(tx, ty, C_SILVER)
					img.set_pixel(int(12.0 + cos(ang + 0.4) * float(r)), int(12.0 + sin(ang + 0.4) * float(r)), C_GOLD)
			img.set_pixel(12, 12, C_WHITE)

		"crucible", "golden_crucible_1", "golden_crucible_2":
			# 24x24 Golden Alchemy Crucible
			for y in range(6, 20):
				for x in range(5, 19):
					if x == 5 or x == 18 or y == 19:
						img.set_pixel(x, y, C_GOLD_DARK)
					elif y <= 10:
						img.set_pixel(x, y, C_WHITE if (x == 10 and y == 8) else C_GOLD)
					else:
						img.set_pixel(x, y, C_DARK)
			img.set_pixel(11, 4, C_GOLD); img.set_pixel(13, 3, C_GOLD) # Bubbles

		"insulation", "thermal_insulation":
			# 24x24 Ceramic Hexagonal Heat Tiles
			for y in range(4, 20):
				for x in range(4, 20):
					if (x + y) % 4 == 0:
						img.set_pixel(x, y, C_ORANGE)
					elif (x == 4 or x == 19 or y == 4 or y == 19):
						img.set_pixel(x, y, C_DARK)
					else:
						img.set_pixel(x, y, C_SILVER if (x + y) % 2 == 0 else C_GREY)

		"core", "reinforced_core":
			# 24x24 Reinforced Boiler Core
			for y in range(4, 20):
				for x in range(6, 18):
					if x == 6 or x == 17 or y == 4 or y == 19:
						img.set_pixel(x, y, C_DARK)
					elif x >= 10 and x <= 13 and y >= 9 and y <= 14:
						img.set_pixel(x, y, C_ORANGE) # Core furnace eye
					else:
						img.set_pixel(x, y, C_GREY)
			img.set_pixel(11, 11, C_WHITE)

		"injection", "water_injection_ports":
			# 24x24 Dual Coolant Injectors
			for y in range(4, 18):
				img.set_pixel(7, y, C_GOLD); img.set_pixel(8, y, C_GOLD_DARK)
				img.set_pixel(15, y, C_GOLD); img.set_pixel(16, y, C_GOLD_DARK)
			for s in range(5):
				img.set_pixel(7 + s, 18 + s, C_CYAN)
				img.set_pixel(16 - s, 18 + s, C_CYAN)

		"valve", "emergency_valve":
			# 24x24 Brass Valve Wheel
			for a in range(24):
				var ang = float(a) / 24.0 * TAU
				var vx = int(12.0 + cos(ang) * 7.0)
				var vy = int(12.0 + sin(ang) * 7.0)
				img.set_pixel(vx, vy, C_GOLD)
			for i in range(6, 19):
				img.set_pixel(12, i, C_GOLD_DARK)
				img.set_pixel(i, 12, C_GOLD_DARK)
			img.set_pixel(12, 12, C_RED)

		"greed", "greed_igniter":
			# 24x24 Golden Supercharger
			for y in range(6, 18):
				for x in range(6, 18):
					if x == 6 or x == 17 or y == 6 or y == 17:
						img.set_pixel(x, y, C_GOLD_DARK)
					else:
						img.set_pixel(x, y, C_GOLD)
			img.set_pixel(10, 10, C_DARK); img.set_pixel(14, 10, C_DARK)
			img.set_pixel(4, 8, C_ORANGE); img.set_pixel(19, 8, C_ORANGE)

		"steam_shock", "steam_blast_defense":
			# 24x24 Steam Shockwave Eruption
			for a in range(28):
				var ang = float(a) / 28.0 * TAU
				var rx = int(12.0 + cos(ang) * 8.0)
				var ry = int(12.0 + sin(ang) * 8.0)
				img.set_pixel(rx, ry, C_WHITE if a % 2 == 0 else C_CYAN)
			for i in range(8, 16):
				img.set_pixel(i, i, C_WHITE)
				img.set_pixel(23 - i, i, C_WHITE)

		"barricade", "furnace_iron_plating", "furnace_heat_sink":
			# 24x24 Fortified Barricade Wall
			for y in range(5, 19):
				for x in range(4, 20):
					if x == 4 or x == 19 or y == 5 or y == 18:
						img.set_pixel(x, y, C_DARK)
					elif (x + y) % 5 == 0:
						img.set_pixel(x, y, C_GOLD) # Hazard stripes
					else:
						img.set_pixel(x, y, C_SILVER)

		"dash", "dash_delay", "dash_booster":
			# 24x24 Speed Dash Silhouette
			for i in range(4, 20):
				img.set_pixel(i, 12, C_CYAN)
				img.set_pixel(i, 11, C_WHITE)
				img.set_pixel(i - 2, 7, C_CYAN_DARK)
				img.set_pixel(i - 2, 17, C_CYAN_DARK)
			img.set_pixel(19, 11, C_WHITE); img.set_pixel(18, 10, C_WHITE); img.set_pixel(18, 12, C_WHITE)

		"mortar", "mortar_strike":
			# 24x24 Artillery Missile
			for i in range(4, 18):
				img.set_pixel(i, i, C_SILVER)
				img.set_pixel(i + 1, i, C_GREY)
				img.set_pixel(i, i + 1, C_GREY)
			img.set_pixel(18, 18, C_RED); img.set_pixel(17, 18, C_RED) # Warhead
			img.set_pixel(4, 4, C_ORANGE); img.set_pixel(3, 3, C_GOLD) # Thruster flame

		"pulse", "repulsor_pulse":
			# 24x24 Concentric Kinetic Shockwave
			for a in range(24):
				var ang = float(a) / 24.0 * TAU
				var r1 = 4.0; var r2 = 9.0
				var p1x = int(12.0 + cos(ang) * r1); var p1y = int(12.0 + sin(ang) * r1)
				var p2x = int(12.0 + cos(ang) * r2); var p2y = int(12.0 + sin(ang) * r2)
				img.set_pixel(p1x, p1y, C_CYAN)
				if p2x >= 0 and p2x < 24 and p2y >= 0 and p2y < 24:
					img.set_pixel(p2x, p2y, C_BLUE)
			img.set_pixel(12, 12, C_WHITE)

		"active_shield":
			# 24x24 Aegis Barrier Hexagon
			for a in range(6):
				var a1 = float(a) * (TAU / 6.0)
				var a2 = float(a + 1) * (TAU / 6.0)
				for t in range(9):
					var frac = float(t) / 8.0
					var cur_a = lerp_angle(a1, a2, frac)
					var hx = int(12.0 + cos(cur_a) * 8.5)
					var hy = int(12.0 + sin(cur_a) * 8.5)
					if hx >= 0 and hx < 24 and hy >= 0 and hy < 24:
						img.set_pixel(hx, hy, C_CYAN)
			img.set_pixel(12, 12, C_WHITE)
			img.set_pixel(11, 12, C_CYAN); img.set_pixel(13, 12, C_CYAN)

		"slot_expansion", "weapon_slot_expansion", "weapon_slot":
			# 24x24 Weapon Holster / Slot Expansion
			for y in range(4, 20):
				for x in range(5, 19):
					if x == 5 or x == 18 or y == 4 or y == 19:
						img.set_pixel(x, y, C_GOLD)
					elif y >= 8 and y <= 10:
						img.set_pixel(x, y, C_GOLD_DARK)
					else:
						img.set_pixel(x, y, C_DARK)
			for i in range(8, 16):
				img.set_pixel(11, i, C_CYAN)
				img.set_pixel(12, i, C_CYAN)
			for i in range(8, 16):
				img.set_pixel(i, 11, C_CYAN)
				img.set_pixel(i, 12, C_CYAN)
			img.set_pixel(11, 11, C_WHITE); img.set_pixel(12, 11, C_WHITE)
			img.set_pixel(11, 12, C_WHITE); img.set_pixel(12, 12, C_WHITE)

		_:
			# Default 24x24 Runic Gem
			for y in range(5, 19):
				for x in range(5, 19):
					var d = abs(x - 12) + abs(y - 12)
					if d <= 7:
						if d == 7:
							img.set_pixel(x, y, C_GOLD_DARK)
						elif d == 0:
							img.set_pixel(x, y, C_WHITE)
						else:
							img.set_pixel(x, y, C_GOLD)

	var tex = ImageTexture.create_from_image(img)
	texture_cache[key] = tex
	return tex


static func get_pixel_bone() -> ImageTexture:
	var key = "pixel_bone_8x8"
	if texture_cache.has(key):
		return texture_cache[key]
		
	var img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	var C_WHITE = Color8(240, 235, 220)
	var C_GREY = Color8(180, 170, 160)
	
	img.set_pixel(1, 2, C_WHITE); img.set_pixel(2, 1, C_WHITE); img.set_pixel(1, 1, C_GREY)
	img.set_pixel(6, 5, C_WHITE); img.set_pixel(5, 6, C_WHITE); img.set_pixel(6, 6, C_GREY)
	img.set_pixel(2, 2, C_WHITE); img.set_pixel(3, 3, C_WHITE); img.set_pixel(4, 4, C_WHITE); img.set_pixel(5, 5, C_WHITE)
	img.set_pixel(3, 4, C_GREY); img.set_pixel(4, 3, C_WHITE)
	
	var tex = ImageTexture.create_from_image(img)
	texture_cache[key] = tex
	return tex

static func get_pixel_coin() -> ImageTexture:
	var key = "pixel_coin_8x8"
	if texture_cache.has(key):
		return texture_cache[key]
		
	var img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	var C_EDGE = Color8(160, 105, 10)
	var C_GOLD = Color8(250, 195, 30)
	var C_SHINE = Color8(255, 255, 180)
	
	for y in range(1, 7):
		for x in range(1, 7):
			if (x == 1 and y == 1) or (x == 6 and y == 1) or (x == 1 and y == 6) or (x == 6 and y == 6):
				continue
			if x == 1 or x == 6 or y == 1 or y == 6:
				img.set_pixel(x, y, C_EDGE)
			else:
				img.set_pixel(x, y, C_GOLD)
				
	img.set_pixel(2, 2, C_SHINE)
	img.set_pixel(3, 2, C_SHINE)
	
	var tex = ImageTexture.create_from_image(img)
	texture_cache[key] = tex
	return tex

static func get_water_drop_texture() -> ImageTexture:
	var key = "water_drop_8x8"
	if texture_cache.has(key):
		return texture_cache[key]
		
	var img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	var C_BLUE = Color8(30, 140, 240, 220)
	var C_CYAN = Color8(100, 220, 255, 240)
	var C_WHITE = Color8(255, 255, 255, 250)
	
	img.set_pixel(3, 1, C_CYAN); img.set_pixel(4, 1, C_CYAN)
	img.set_pixel(2, 2, C_BLUE); img.set_pixel(3, 2, C_WHITE); img.set_pixel(4, 2, C_CYAN); img.set_pixel(5, 2, C_BLUE)
	img.set_pixel(2, 3, C_BLUE); img.set_pixel(3, 3, C_CYAN); img.set_pixel(4, 3, C_CYAN); img.set_pixel(5, 3, C_BLUE)
	img.set_pixel(2, 4, C_BLUE); img.set_pixel(3, 4, C_CYAN); img.set_pixel(4, 4, C_BLUE); img.set_pixel(5, 4, C_BLUE)
	img.set_pixel(3, 5, C_BLUE); img.set_pixel(4, 5, C_BLUE)
	
	var tex = ImageTexture.create_from_image(img)
	texture_cache[key] = tex
	return tex

static func draw_ellipse_shape(ci: CanvasItem, center: Vector2, radius_x: float, radius_y: float, color: Color, segments: int = 16) -> void:
	var points = PackedVector2Array()
	points.resize(segments)
	for i in range(segments):
		var a = (float(i) / float(segments)) * TAU
		points[i] = center + Vector2(cos(a) * radius_x, sin(a) * radius_y)
	ci.draw_colored_polygon(points, color)
