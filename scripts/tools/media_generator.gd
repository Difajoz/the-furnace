# media_generator.gd - Master itch.io Screenshots & Pixel Art Cover Thumbnail Generator
extends Node

const TURRET_SCRIPT = preload("res://scripts/turrets/turret_base.gd")
const ENEMY_SCRIPT = preload("res://scripts/enemies/enemy_base.gd")
const PROJECTILE_SCRIPT = preload("res://scripts/weapons/projectile_base.gd")
const TURRET_PROJ_SCRIPT = preload("res://scripts/turrets/turret_projectile.gd")
const BONE_SCRIPT = preload("res://scripts/pickups/bone_pickup.gd")
const COIN_SCRIPT = preload("res://scripts/pickups/coin_pickup.gd")
const UI_FONT: Font = preload("res://assets/Ultrapixel.ttf")

var main: Main = null

func _ready() -> void:
	print("=== STARTING MASTER ITCH.IO MEDIA & THUMBNAIL GENERATOR ===")
	DirAccess.make_dir_absolute("res://media")
	
	# Instantiate Main Game Scene
	var main_scene = load("res://scenes/main.tscn")
	main = main_scene.instantiate()
	add_child(main)
	
	# Cleanly remove loading screen
	if is_instance_valid(main.loading_screen_node):
		main.loading_screen_node.visible = false
		main.loading_screen_node.queue_free()
		
	main._on_loading_completed()
	for i in range(15): await get_tree().process_frame
	
	# 1. Capture Main Menu
	await _capture_main_menu()
	
	# 2. Capture Armory Shop
	await _capture_armory_shop()
	
	# 3. Capture Furnace Defense (Gameplay Action)
	await _capture_furnace_defense()
	
	# 4. Capture Boss Battle (Wave 5 Crypt Abomination)
	await _capture_boss_battle()
	
	# 5. Capture Turret Defense Network
	await _capture_turret_network()
	
	# 6. Capture Critical Heat Frenzy
	await _capture_heat_frenzy()
	
	# 7. Generate Master Pixel Art Cover Thumbnail (630x500 & 1260x1000 HD)
	await _generate_cover_thumbnail()
	
	print("=== MASTER ITCH.IO MEDIA SUITE GENERATED SUCCESSFULLY IN res://media/ ===")
	get_tree().quit(0)

func _capture_viewport_to_file(path: String) -> void:
	for i in range(10): await get_tree().process_frame
	var img = get_viewport().get_texture().get_image()
	if img:
		img.save_png(path)
		print("Saved: ", path, " (", img.get_width(), "x", img.get_height(), ")")
	else:
		push_error("Failed to capture image for: " + path)

func _capture_main_menu() -> void:
	print("Capturing Main Menu...")
	main.main_menu_node.visible = true
	main.hud_node.visible = false
	main.shop_node.close_shop()
	main.game_over_node.visible = false
	main.main_menu_node.update_records_display()
	await _capture_viewport_to_file("res://media/screenshot_6_main_menu.png")

func _capture_armory_shop() -> void:
	print("Capturing Armory Shop...")
	main.main_menu_node.visible = false
	main._on_start_run()
	
	GameManager.coins = 245
	GameManager.current_wave = 3
	GameManager.equipped_weapons = [
		ItemDatabase.weapons["shotgun"].duplicate(true),
		ItemDatabase.weapons["cryo_blaster"].duplicate(true),
		ItemDatabase.weapons["fire_spell"].duplicate(true)
	]
	
	main.shop_node.open_shop()
	main.shop_node.shop_cards = [
		ItemDatabase.weapons["cryo_blaster"].duplicate(true),
		ItemDatabase.weapons["meteor_staff"].duplicate(true),
		ItemDatabase.weapons["saw_launcher"].duplicate(true),
		ItemDatabase.get_weapon_upgrade("shotgun", ItemDatabase.TIER_EPIC)
	]
	main.shop_node._update_gold_display()
	main.shop_node._update_stats_display()
	main.shop_node._update_slot_buttons()
	main.shop_node._render_cards()
	
	await _capture_viewport_to_file("res://media/screenshot_4_armory_shop.png")

func _capture_furnace_defense() -> void:
	print("Capturing Furnace Defense Gameplay...")
	main.shop_node.close_shop()
	main._cleanup_world_entities()
	GameManager.current_state = GameManager.GameState.PLAYING
	main.hud_node.visible = true
	
	GameManager.current_wave = 2
	GameManager.current_hp = 88.0
	GameManager.max_hp = 100.0
	GameManager.current_water = 38.0
	GameManager.max_water = 50.0
	GameManager.coins = 175
	GameManager.bones_held = 7
	GameManager.current_combo = 14
	GameManager.combo_timer = 2.8
	GameManager.emit_signal("player_water_changed", GameManager.current_water, GameManager.max_water)
	
	main.furnace_node.temperature = 52.0
	main.furnace_node.bones_stored = 18
	main.player_node.global_position = Vector2(80, 70)
	main.camera_node.global_position = Vector2(40, 30)
	
	# Rebuild player weapons
	main.player_node._rebuild_weapons()
	
	# Spawn attacking monsters around the crucible
	var enemy_configs = [
		[EnemyBase.EnemyType.GOBLIN, Vector2(-220, -110)],
		[EnemyBase.EnemyType.GOBLIN, Vector2(-190, 60)],
		[EnemyBase.EnemyType.SKELETON_ARCHER, Vector2(-280, 140)],
		[EnemyBase.EnemyType.SKELETON_ARCHER, Vector2(-250, -180)],
		[EnemyBase.EnemyType.WOLF, Vector2(210, -140)],
		[EnemyBase.EnemyType.WOLF, Vector2(260, 20)],
		[EnemyBase.EnemyType.BAT, Vector2(170, 190)],
		[EnemyBase.EnemyType.BAT, Vector2(-80, 240)],
		[EnemyBase.EnemyType.GIANT_RAT, Vector2(60, -220)],
		[EnemyBase.EnemyType.GIANT_RAT, Vector2(-120, -240)],
		[EnemyBase.EnemyType.MINOTAUR, Vector2(320, 110)],
		[EnemyBase.EnemyType.WILDFIRE_WISP, Vector2(-310, -40)],
		[EnemyBase.EnemyType.CYCLOPS, Vector2(230, -60)],
		[EnemyBase.EnemyType.GOBLIN, Vector2(-160, 210)]
	]
	
	for cfg in enemy_configs:
		var mob = ENEMY_SCRIPT.new()
		main.add_child(mob)
		mob.init_enemy(cfg[0], 1, false, false)
		mob.global_position = cfg[1]
	
	# Place two active turrets
	var t1 = TURRET_SCRIPT.new()
	main.add_child(t1)
	t1.global_position = Vector2(-140, 50)
	t1.configure_turret("flame")
	
	var t2 = TURRET_SCRIPT.new()
	main.add_child(t2)
	t2.global_position = Vector2(160, -90)
	t2.configure_turret("ice")
	
	# Add ground coins and bones
	for i in range(14):
		var cp = COIN_SCRIPT.new()
		cp.value = 5
		main.add_child(cp)
		cp.global_position = Vector2(randf_range(-190, 190), randf_range(-150, 150))
		
	for i in range(9):
		var bp = BONE_SCRIPT.new()
		main.add_child(bp)
		bp.global_position = Vector2(randf_range(-170, 170), randf_range(-140, 140))
		
	# Spawn active player projectile spread
	for ang in [-0.5, -0.2, 0.1, 0.4, 2.7, 3.0]:
		var dir = Vector2.from_angle(ang)
		var proj = PROJECTILE_SCRIPT.new()
		proj.init_projectile(dir, 550.0, 18.0, 450.0, 2, 60.0, false, "slash", Color8(255, 220, 80))
		main.add_child(proj)
		proj.global_position = main.player_node.global_position + dir * 45.0
		
	# Spawn cryo slow projectile
	var ice_proj = PROJECTILE_SCRIPT.new()
	ice_proj.init_projectile(Vector2(1, -0.2).normalized(), 450.0, 8.0, 300.0, 99, 30.0, false, "cryo_slow", Color(0.3, 0.9, 1.0))
	ice_proj.slow_factor = 0.50
	main.add_child(ice_proj)
	ice_proj.global_position = Vector2(190, -90)
	
	# Add dynamic combat popups
	GameManager.emit_signal("show_damage_number", Vector2(-180, 50), "CRIT! 48", Color(1.0, 0.85, 0.1), true)
	GameManager.emit_signal("show_damage_number", Vector2(200, -120), "22", Color.WHITE, false)
	GameManager.emit_signal("show_damage_number", Vector2(-210, -100), "SLOWED 50%", Color(0.3, 0.85, 1.0), false)
	
	await _capture_viewport_to_file("res://media/screenshot_1_furnace_defense.png")

func _capture_boss_battle() -> void:
	print("Capturing Boss Battle...")
	main.shop_node.close_shop()
	main._cleanup_world_entities()
	GameManager.current_wave = 5
	GameManager.current_state = GameManager.GameState.PLAYING
	main.hud_node.visible = true
	
	GameManager.current_hp = 72.0
	GameManager.max_hp = 100.0
	GameManager.current_water = 42.0
	GameManager.max_water = 50.0
	GameManager.coins = 380
	GameManager.current_combo = 22
	GameManager.combo_timer = 3.5
	GameManager.emit_signal("player_water_changed", GameManager.current_water, GameManager.max_water)
	
	main.furnace_node.temperature = 68.0
	main.player_node.global_position = Vector2(0, 180)
	main.camera_node.global_position = Vector2(0, 40)
	
	# Spawn Wave 5 Big Boss: Crypt Abomination
	var boss = ENEMY_SCRIPT.new()
	main.add_child(boss)
	boss.init_enemy(EnemyBase.EnemyType.BOSS_CRYPT_ABOMINATION, 5, true, false)
	boss.global_position = Vector2(0, -180)
	boss.hp = boss.max_hp * 0.65
	
	# Activate Boss HUD top health bar
	main.hud_node.boss_bar_panel.visible = true
	main.hud_node.boss_name_label.text = "CRYPT ABOMINATION - CRUCIBLE CORRUPTOR"
	main.hud_node.boss_bar.max_value = boss.max_hp
	main.hud_node.boss_bar.value = boss.hp
	main.hud_node.boss_hp_label.text = "%d / %d (65%%)" % [int(boss.hp), int(boss.max_hp)]
	
	# Spawn boss radial projectile barrage
	var bullet_angles = 16
	for b in range(bullet_angles):
		var ang = (float(b) / float(bullet_angles)) * TAU
		var p_dir = Vector2.from_angle(ang)
		var b_proj = PROJECTILE_SCRIPT.new()
		b_proj.is_enemy_projectile = true
		b_proj.init_projectile(p_dir, 190.0, 18.0, 600.0, 1, 40.0, false, "shadow_bolt", Color8(190, 60, 255))
		main.add_child(b_proj)
		b_proj.global_position = boss.global_position + p_dir * 70.0
		
	# Spawn boss minions
	var minion_pos = [Vector2(-160, -120), Vector2(160, -120), Vector2(-220, -40), Vector2(220, -40)]
	for mp in minion_pos:
		var minion = ENEMY_SCRIPT.new()
		main.add_child(minion)
		minion.init_enemy(EnemyBase.EnemyType.BAT, 5, false, false)
		minion.global_position = mp
		
	# Floating boss damage numbers
	GameManager.emit_signal("show_damage_number", boss.global_position + Vector2(-30, -45), "CRIT! 96", Color(1.0, 0.85, 0.1), true)
	GameManager.emit_signal("show_damage_number", boss.global_position + Vector2(35, -30), "CRIT! 112", Color(1.0, 0.85, 0.1), true)
	
	await _capture_viewport_to_file("res://media/screenshot_2_boss_battle.png")

func _capture_turret_network() -> void:
	print("Capturing Turret Network...")
	main.shop_node.close_shop()
	main._cleanup_world_entities()
	GameManager.current_wave = 4
	GameManager.current_hp = 95.0
	GameManager.max_hp = 100.0
	GameManager.current_water = 50.0
	GameManager.max_water = 50.0
	GameManager.coins = 310
	GameManager.bones_held = 10
	GameManager.current_combo = 8
	GameManager.emit_signal("player_water_changed", GameManager.current_water, GameManager.max_water)
	
	main.furnace_node.temperature = 45.0
	main.player_node.global_position = Vector2(0, 100)
	main.camera_node.global_position = Vector2(0, 20)
	
	# Place 4 specialized defense turrets around the furnace
	var t_flame = TURRET_SCRIPT.new()
	main.add_child(t_flame)
	t_flame.global_position = Vector2(-180, -90)
	t_flame.configure_turret("flame")
	
	var t_ice = TURRET_SCRIPT.new()
	main.add_child(t_ice)
	t_ice.global_position = Vector2(180, -90)
	t_ice.configure_turret("ice")
	
	var t_cannon = TURRET_SCRIPT.new()
	main.add_child(t_cannon)
	t_cannon.global_position = Vector2(-180, 110)
	t_cannon.configure_turret("cannon")
	
	var t_ballista = TURRET_SCRIPT.new()
	main.add_child(t_ballista)
	t_ballista.global_position = Vector2(180, 110)
	t_ballista.configure_turret("ballista")
	
	# Spawn incoming monster corridor
	var positions = [
		Vector2(-280, -120), Vector2(-320, -70), Vector2(-260, 30),
		Vector2(280, -120), Vector2(330, -80), Vector2(270, 40),
		Vector2(-120, -250), Vector2(120, -250), Vector2(0, -280)
	]
	for pos in positions:
		var m = ENEMY_SCRIPT.new()
		main.add_child(m)
		m.init_enemy(EnemyBase.EnemyType.CYCLOPS if pos.x > 0 else EnemyBase.EnemyType.MINOTAUR, 3, false, false)
		m.global_position = pos
		if pos.x > 0:
			m.apply_slow(0.60, 4.0) # Tinted cyan
		else:
			m.apply_burn(15.0, 3.0) # Burning
			
	# Turret shooting streams
	var flame_p = TURRET_PROJ_SCRIPT.new()
	main.add_child(flame_p)
	flame_p.init_flame(Vector2(-1, -0.2).normalized(), 420.0, 5.0, 200.0)
	flame_p.global_position = t_flame.global_position + Vector2(-30, 0)
	
	var ice_p = TURRET_PROJ_SCRIPT.new()
	main.add_child(ice_p)
	ice_p.init_ice(Vector2(1, -0.1).normalized(), 600.0, 7.0, 260.0, 5.0)
	ice_p.global_position = t_ice.global_position + Vector2(30, 0)
	
	GameManager.emit_signal("show_damage_number", Vector2(-280, -110), "BURN 18", Color(1.0, 0.45, 0.1), false)
	GameManager.emit_signal("show_damage_number", Vector2(280, -110), "EXTINGUISHED!", Color(0.4, 0.85, 1.0), false)
	
	await _capture_viewport_to_file("res://media/screenshot_3_turret_network.png")

func _capture_heat_frenzy() -> void:
	print("Capturing Critical Heat Frenzy...")
	main.shop_node.close_shop()
	main._cleanup_world_entities()
	GameManager.current_wave = 4
	GameManager.current_hp = 64.0
	GameManager.current_water = 12.0
	GameManager.max_water = 50.0
	main.furnace_node.temperature = 89.0 # Critical Heat!
	main.furnace_node.is_overheated = false
	GameManager.heat_frenzy_bonus = 0.50
	GameManager.emit_signal("player_water_changed", GameManager.current_water, GameManager.max_water)
	
	main.player_node.global_position = Vector2(0, 70)
	main.camera_node.global_position = Vector2(0, 30)
	
	# Dense horde closing in
	for i in range(24):
		var ang = (float(i) / 24.0) * TAU
		var m = ENEMY_SCRIPT.new()
		main.add_child(m)
		m.init_enemy(EnemyBase.EnemyType.GOBLIN if i % 2 == 0 else EnemyBase.EnemyType.SKELETON_ARCHER, 4, false, false)
		m.global_position = Vector2.from_angle(ang) * randf_range(200.0, 320.0)
		
	# Huge bullet spread from player
	for b in range(12):
		var ang = (float(b) / 12.0) * TAU
		var p = PROJECTILE_SCRIPT.new()
		p.init_projectile(Vector2.from_angle(ang), 600.0, 35.0, 400.0, 3, 90.0, true, "fire_spell", Color8(255, 140, 30))
		main.add_child(p)
		p.global_position = main.player_node.global_position + Vector2.from_angle(ang) * 40.0
		
	GameManager.emit_signal("show_damage_number", Vector2(0, -60), "HEAT FRENZY +75% DMG!", Color(1.0, 0.7, 0.1), true)
	GameManager.emit_signal("show_damage_number", Vector2(-120, 40), "CRIT! 85", Color(1.0, 0.9, 0.2), true)
	GameManager.emit_signal("show_damage_number", Vector2(130, -30), "CRIT! 92", Color(1.0, 0.9, 0.2), true)
	
	await _capture_viewport_to_file("res://media/screenshot_5_heat_frenzy.png")

func _generate_cover_thumbnail() -> void:
	print("Generating 100% Authentic Pixel Art Cover Thumbnail...")
	var vp = SubViewport.new()
	vp.size = Vector2i(1260, 1000)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	
	var cover_root = Node2D.new()
	vp.add_child(cover_root)
	
	# 1. Background Foundry Arena Floor
	var bg = Node2D.new()
	cover_root.add_child(bg)
	bg.draw.connect(func():
		bg.draw_rect(Rect2(0, 0, 1260, 1000), Color8(10, 11, 15), true)
		
		# Basalt paving stones
		var tsize = 48.0
		for y in range(0, 1000, int(tsize)):
			for x in range(0, 1260, int(tsize)):
				var sv = int(abs(x * 17 + y * 31)) % 10
				var col = Color8(18, 20, 26)
				if sv == 1: col = Color8(24, 26, 35)
				elif sv == 2: col = Color8(14, 15, 20)
				elif sv == 3: col = Color8(28, 30, 42)
				bg.draw_rect(Rect2(x + 2, y + 2, tsize - 4, tsize - 4), col, true)
				
		# Radiant Infernal Hearth Glows (Warm Oranges & Magma Amber)
		var center = Vector2(630, 500)
		bg.draw_circle(center, 490.0, Color8(255, 60, 10, 26))
		bg.draw_circle(center, 390.0, Color8(255, 90, 15, 42))
		bg.draw_circle(center, 290.0, Color8(255, 130, 25, 65))
		bg.draw_circle(center, 190.0, Color8(255, 180, 40, 85))
		
		# Crucible Heat Zone Ring
		bg.draw_arc(center, 340.0, 0, TAU, 64, Color8(255, 110, 30, 95), 6.0)
		bg.draw_arc(center, 340.0, 0, TAU, 32, Color8(255, 210, 60, 50), 14.0)
		
		# Top and Bottom Dark Vignette Borders
		bg.draw_rect(Rect2(0, 0, 1260, 75), Color8(4, 4, 7, 240), true)
		bg.draw_rect(Rect2(0, 925, 1260, 75), Color8(4, 4, 7, 240), true)
	)
	
	# 2. Central High-Stage Furnace (Scale 10.0x for bold presence)
	var furnace_spr = Sprite2D.new()
	furnace_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	furnace_spr.texture = VisualFactory.get_furnace_texture(3, 1)
	furnace_spr.scale = Vector2(10.0, 10.0)
	furnace_spr.position = Vector2(630, 430)
	cover_root.add_child(furnace_spr)
	
	# 3. Flanking Defense Turrets (Scale 7.0x)
	# Flame Turret (Left)
	var flame_base = Sprite2D.new()
	flame_base.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	flame_base.texture = preload("res://assets/turrets/flame_turret_base.png")
	flame_base.scale = Vector2(6.5, 6.5)
	flame_base.position = Vector2(210, 750)
	cover_root.add_child(flame_base)
	
	var flame_head = Sprite2D.new()
	flame_head.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	flame_head.texture = preload("res://assets/turrets/flame_turret_head.png")
	flame_head.scale = Vector2(6.5, 6.5)
	flame_head.position = Vector2(210, 750)
	flame_head.rotation = 0.35
	cover_root.add_child(flame_head)
	
	# Ice Turret (Right)
	var ice_base = Sprite2D.new()
	ice_base.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ice_base.texture = preload("res://assets/turrets/ice_turret_base.png")
	ice_base.scale = Vector2(6.5, 6.5)
	ice_base.position = Vector2(1050, 750)
	cover_root.add_child(ice_base)
	
	var ice_head = Sprite2D.new()
	ice_head.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ice_head.texture = preload("res://assets/turrets/ice_turret_head.png")
	ice_head.scale = Vector2(6.5, 6.5)
	ice_head.position = Vector2(1050, 750)
	ice_head.rotation = -0.35
	cover_root.add_child(ice_head)
	
	# 4. Encroaching Minifantasy Monster Lineup (Prominent Scale 10x-12x)
	# Left Flank:
	# Heavy Minotaur (hf=6, vf=4, scale 11.5x)
	var minotaur_spr = Sprite2D.new()
	minotaur_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	minotaur_spr.texture = preload("res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Monsters/Minotaur/MinotaurWalk.png")
	minotaur_spr.hframes = 6
	minotaur_spr.vframes = 4
	minotaur_spr.frame_coords = Vector2i(0, 0)
	minotaur_spr.scale = Vector2(11.5, 11.5)
	minotaur_spr.position = Vector2(290, 480)
	cover_root.add_child(minotaur_spr)
	
	# Skeleton Archer (hf=2, vf=4, scale 8.5x)
	var skel_spr = Sprite2D.new()
	skel_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	skel_spr.texture = preload("res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Undead/Skeleton/SkeletonWalk.png")
	skel_spr.hframes = 2
	skel_spr.vframes = 4
	skel_spr.frame_coords = Vector2i(0, 0)
	skel_spr.scale = Vector2(8.5, 8.5)
	skel_spr.position = Vector2(430, 340)
	cover_root.add_child(skel_spr)
	
	# Goblin Cutthroat (hf=4, vf=4, scale 7.5x)
	var gob_spr = Sprite2D.new()
	gob_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	gob_spr.texture = preload("res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Base_Humanoids/Goblin/GoblinWalk.png")
	gob_spr.hframes = 4
	gob_spr.vframes = 4
	gob_spr.frame_coords = Vector2i(0, 0)
	gob_spr.scale = Vector2(7.5, 7.5)
	gob_spr.position = Vector2(420, 630)
	cover_root.add_child(gob_spr)
	
	# Right Flank:
	# Gargoyle Sovereign (hf=4, vf=4, scale 11.5x, flip_h)
	var garg_spr = Sprite2D.new()
	garg_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	garg_spr.texture = preload("res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Gargoyle/GargoyleWalk.png")
	garg_spr.hframes = 4
	garg_spr.vframes = 4
	garg_spr.frame_coords = Vector2i(0, 0)
	garg_spr.scale = Vector2(11.5, 11.5)
	garg_spr.flip_h = true
	garg_spr.position = Vector2(970, 480)
	cover_root.add_child(garg_spr)
	
	# Shadow Wolf (hf=4, vf=4, scale 8.5x, flip_h)
	var wolf_spr = Sprite2D.new()
	wolf_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	wolf_spr.texture = preload("res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Beasts/Wolf/WolfWalk.png")
	wolf_spr.hframes = 4
	wolf_spr.vframes = 4
	wolf_spr.frame_coords = Vector2i(0, 0)
	wolf_spr.scale = Vector2(8.5, 8.5)
	wolf_spr.flip_h = true
	wolf_spr.position = Vector2(830, 340)
	cover_root.add_child(wolf_spr)
	
	# Vampiric Bat (hf=2, vf=4, scale 7.5x)
	var bat_spr = Sprite2D.new()
	bat_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bat_spr.texture = preload("res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Beasts/Bat/BatFlyIdle.png")
	bat_spr.hframes = 2
	bat_spr.vframes = 4
	bat_spr.frame_coords = Vector2i(0, 0)
	bat_spr.scale = Vector2(7.5, 7.5)
	bat_spr.position = Vector2(840, 630)
	cover_root.add_child(bat_spr)
	
	# 5. Central Hero (Foreground Legend, Scale 14.0x)
	var hero_node = Node2D.new()
	hero_node.position = Vector2(630, 700)
	cover_root.add_child(hero_node)
	
	var hero_spr = Sprite2D.new()
	hero_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hero_spr.texture = preload("res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Base_Humanoids/Human/Base_Human/HumanWalk.png")
	hero_spr.hframes = 4
	hero_spr.vframes = 4
	hero_spr.frame_coords = Vector2i(0, 0)
	hero_spr.scale = Vector2(14.0, 14.0)
	hero_node.add_child(hero_spr)
	
	# Dual Pixel Weapons in Hero Hands (Scale 8.0x)
	var w1_spr = Sprite2D.new()
	w1_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	w1_spr.texture = VisualFactory.get_weapon_texture("shotgun")
	w1_spr.scale = Vector2(8.0, 8.0)
	w1_spr.position = Vector2(-80, 0)
	w1_spr.rotation = -0.35
	hero_node.add_child(w1_spr)
	
	var w2_spr = Sprite2D.new()
	w2_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	w2_spr.texture = VisualFactory.get_weapon_texture("cryo_blaster")
	w2_spr.scale = Vector2(8.0, 8.0)
	w2_spr.position = Vector2(80, 0)
	w2_spr.rotation = 0.35
	hero_node.add_child(w2_spr)
	
	# 6. Action Overlay (Water Stream, Projectiles, Sparks, Dropped Coins, Damage Pops, Title Plate)
	var overlay = Node2D.new()
	cover_root.add_child(overlay)
	overlay.draw.connect(func():
		var coin_tex = VisualFactory.get_pixel_coin()
		var bone_tex = VisualFactory.get_pixel_bone()
		
		# Scattered Coins
		for pt in [Vector2(490, 775), Vector2(550, 805), Vector2(710, 795), Vector2(770, 765), Vector2(410, 740), Vector2(850, 730)]:
			overlay.draw_set_transform(pt, 0, Vector2(5.0, 5.0))
			overlay.draw_texture(coin_tex, Vector2(-4, -4))
			
		# Scattered Bones
		for pt in [Vector2(460, 805), Vector2(610, 825), Vector2(650, 815), Vector2(800, 795)]:
			overlay.draw_set_transform(pt, randf_range(-0.5, 0.5), Vector2(4.5, 4.5))
			overlay.draw_texture(bone_tex, Vector2(-4, -4))
			
		overlay.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		
		# Water Cooling Spray from Hero towards Furnace
		for w in range(14):
			var t = float(w) / 14.0
			var wp = Vector2(630, 660).lerp(Vector2(630, 480), t) + Vector2(sin(t * 12.0) * 16.0, 0)
			overlay.draw_circle(wp, 8.0 + (1.0 - t) * 6.0, Color8(80, 200, 255, int(200 * (1.0 - t))))
			overlay.draw_circle(wp, 4.0, Color.WHITE)
			
		# Muzzle Flashes
		# Shotgun Flash (Left)
		var s_muzzle = Vector2(630 - 145, 700 - 20)
		overlay.draw_circle(s_muzzle, 32.0, Color8(255, 120, 20, 160))
		overlay.draw_circle(s_muzzle, 20.0, Color8(255, 230, 60))
		overlay.draw_circle(s_muzzle, 9.0, Color.WHITE)
		
		# Cryo Flash (Right)
		var c_muzzle = Vector2(630 + 145, 700 - 20)
		overlay.draw_circle(c_muzzle, 30.0, Color8(60, 200, 255, 160))
		overlay.draw_circle(c_muzzle, 18.0, Color8(180, 240, 255))
		overlay.draw_circle(c_muzzle, 8.0, Color.WHITE)
		
		# Turret Projectile Streams
		# Flame stream from left turret
		for f in range(8):
			var fp = Vector2(280 + f * 44, 740 - f * 6)
			overlay.draw_circle(fp, 18.0 + f * 2.5, Color8(255, 110, 20, 180))
			overlay.draw_circle(fp, 10.0 + f * 1.5, Color8(255, 220, 40, 240))
			overlay.draw_circle(fp, 5.0, Color.WHITE)
			
		# Ice crystals from right turret
		for c in range(8):
			var cp = Vector2(980 - c * 44, 740 - c * 6)
			overlay.draw_circle(cp, 17.0 + c * 2.0, Color8(50, 200, 255, 170))
			overlay.draw_circle(cp, 9.0 + c * 1.2, Color8(200, 245, 255, 240))
			overlay.draw_circle(cp, 4.5, Color.WHITE)
			
		# Floating Damage Numbers
		_draw_pixel_text(overlay, "CRIT! 140", Vector2(240, 360), Color8(255, 215, 30), 32)
		_draw_pixel_text(overlay, "CRIT! 185", Vector2(940, 360), Color8(255, 215, 30), 32)
		_draw_pixel_text(overlay, "SLOWED 50%", Vector2(860, 660), Color8(70, 210, 255), 26)
		_draw_pixel_text(overlay, "BURN 28", Vector2(320, 660), Color8(255, 130, 30), 26)
		
		# ==========================================
		# TYPOGRAPHY & TITLE LOGO BANNER (PIXEL ART)
		# ==========================================
		var banner_rect = Rect2(160, 35, 940, 175)
		overlay.draw_rect(banner_rect, Color8(10, 11, 16, 230), true)
		overlay.draw_rect(banner_rect, Color8(190, 115, 35), false, 4.0)
		overlay.draw_rect(Rect2(166, 41, 928, 163), Color8(255, 170, 50, 50), false, 2.0)
		
		# Corner Bronze Rivets
		overlay.draw_rect(Rect2(172, 47, 12, 12), Color8(255, 210, 80), true)
		overlay.draw_rect(Rect2(1076, 47, 12, 12), Color8(255, 210, 80), true)
		overlay.draw_rect(Rect2(172, 191, 12, 12), Color8(255, 210, 80), true)
		overlay.draw_rect(Rect2(1076, 191, 12, 12), Color8(255, 210, 80), true)
		
		# Main Title: THE FURNACE (Size 92, 3D Layered Pixel Shadow)
		var title_text = "THE FURNACE"
		var t_pos = Vector2(290, 132)
		# Deep Drop Shadows
		_draw_pixel_text(overlay, title_text, t_pos + Vector2(6, 6), Color8(8, 6, 6), 92)
		_draw_pixel_text(overlay, title_text, t_pos + Vector2(4, 4), Color8(40, 15, 8), 92)
		# Warm Outline
		_draw_pixel_text(overlay, title_text, t_pos + Vector2(-3, 0), Color8(130, 40, 10), 92)
		_draw_pixel_text(overlay, title_text, t_pos + Vector2(3, 0), Color8(130, 40, 10), 92)
		_draw_pixel_text(overlay, title_text, t_pos + Vector2(0, -3), Color8(130, 40, 10), 92)
		_draw_pixel_text(overlay, title_text, t_pos + Vector2(0, 3), Color8(130, 40, 10), 92)
		# Fiery Inner Face
		_draw_pixel_text(overlay, title_text, t_pos, Color8(255, 130, 25), 92)
		_draw_pixel_text(overlay, title_text, t_pos + Vector2(0, -2), Color8(255, 220, 80), 90)
		
		# Subtitle Tagline
		var sub_text = "COOL THE CRUCIBLE  •  SURVIVE THE CRYPT INFERNO"
		var sub_pos = Vector2(235, 185)
		_draw_pixel_text(overlay, sub_text, sub_pos + Vector2(2, 2), Color.BLACK, 24)
		_draw_pixel_text(overlay, sub_text, sub_pos, Color8(255, 225, 160), 24)
		
		# Bottom Genre Badge Pill
		var badge_rect = Rect2(350, 865, 560, 54)
		overlay.draw_rect(badge_rect, Color8(14, 15, 22, 235), true)
		overlay.draw_rect(badge_rect, Color8(240, 160, 40), false, 3.0)
		var badge_text = "ACTION ROGUELITE  ×  FOUNDRY DEFENSE"
		_draw_pixel_text(overlay, badge_text, Vector2(385, 902), Color8(255, 230, 180), 24)
	)
	
	# Wait for rendering to complete
	for i in range(12): await get_tree().process_frame
	
	# Capture HD 1260x1000
	var hd_img = vp.get_texture().get_image()
	if hd_img:
		hd_img.save_png("res://media/cover_thumbnail_hd.png")
		print("Saved: res://media/cover_thumbnail_hd.png (1260x1000)")
		
		# Downscale to itch.io standard 630x500
		var std_img = hd_img.duplicate()
		std_img.resize(630, 500, Image.INTERPOLATE_LANCZOS)
		std_img.save_png("res://media/cover_thumbnail.png")
		print("Saved: res://media/cover_thumbnail.png (630x500)")
	else:
		push_error("Failed to capture Cover Thumbnail!")
		
	vp.queue_free()

func _draw_pixel_text(canvas: Node2D, text: String, pos: Vector2, col: Color, font_sz: int = 24) -> void:
	if UI_FONT:
		canvas.draw_string(UI_FONT, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_sz, col)
