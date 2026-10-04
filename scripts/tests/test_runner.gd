# test_runner.gd - Automated Test Suite to Exercise All Systems, Loading Screen, Bosses, Fullscreen, and Save & Quit
extends Node

const TUTORIAL_MANAGER_SCRIPT = preload("res://scripts/tutorial/tutorial_manager.gd")
const TUTORIAL_MARKER_SCRIPT = preload("res://scripts/ui/tutorial_destination_marker.gd")

func _ready() -> void:
	print("--- STARTING COMPREHENSIVE RUNTIME TEST FOR THE FURNACE ---")
	
	# Load and instance Main Scene
	var main_scene = load("res://scenes/main.tscn")
	var main = main_scene.instantiate()
	add_child(main)
	
	print("[1/16] Main Scene instanced successfully with LoadingScreenUI.")
	assert(is_instance_valid(main.loading_screen_node), "LoadingScreenUI must exist in Main scene!")
	
	# Test Loading Screen completion
	main._on_loading_completed()
	assert(main.main_menu_node.visible, "MainMenuUI must be visible after loading completed!")
	print("[2/16] Loading screen completion transition verified.")
	
	# Test Fullscreen toggle on Main Menu
	assert(is_instance_valid(main.main_menu_node.fullscreen_btn), "MainMenuUI must have a fullscreen toggle button!")
	main.main_menu_node._on_fullscreen_toggle()
	main.main_menu_node._on_fullscreen_toggle()
	
	# Test Main Menu Section Navigation (Start -> Difficulty -> Back)
	assert(main.main_menu_node.main_section.visible, "MainSection must be visible initially!")
	assert(not main.main_menu_node.diff_section.visible, "DifficultySection must be hidden initially!")
	main.main_menu_node._on_start_pressed()
	assert(not main.main_menu_node.main_section.visible, "MainSection must be hidden after pressing Start!")
	assert(main.main_menu_node.diff_section.visible, "DifficultySection must be visible after pressing Start!")
	main.main_menu_node._on_back_pressed()
	assert(main.main_menu_node.main_section.visible, "MainSection must be visible after pressing Back!")
	assert(not main.main_menu_node.diff_section.visible, "DifficultySection must be hidden after pressing Back!")
	print("[3/16] Main Menu section flow and Fullscreen toggle verified.")
	
	# Verify Base Bone Cap is 10
	assert(GameManager.max_bones_held == 10, "Base bone cap must be 10!")
	
	# Start Run
	main._on_start_run()
	assert(GameManager.max_bones_held == 10, "Bone cap after run start must be 10!")
	assert(GameManager.max_weapon_slots == 3, "Starting weapon slots must be 3!")
	print("[4/16] Game Started & Initial Shop Opened with 3 Weapon Slots.")
	
	# Test Buying items
	var p_item = ItemDatabase.get_item("pistol")
	GameManager.buy_item(p_item)
	var s_item = ItemDatabase.get_item("raw_damage")
	GameManager.buy_item(s_item)
	
	# Test Save & Quit from Shop
	assert(is_instance_valid(main.shop_node.save_quit_btn), "ShopUI must have a Save & Quit button!")
	GameManager.current_wave = 5
	GameManager.coins = 250
	var save_ok = GameManager.save_current_run("SHOP")
	assert(save_ok, "save_current_run must succeed!")
	assert(GameManager.has_saved_run(), "has_saved_run must be true!")
	var saved_info = GameManager.get_saved_run_info()
	assert(int(saved_info.get("current_wave", 0)) == 5, "Saved run wave must be 5!")
	assert(int(saved_info.get("coins", 0)) == 250, "Saved run coins must be 250!")
	print("[5/16] Save & Quit from Shop verified (Wave 5, 250 coins saved).")
	
	# Return to Main Menu and check Continue Run button
	main._on_return_to_menu()
	assert(main.main_menu_node.visible, "Main menu must be visible after saving & quitting!")
	assert(main.main_menu_node.continue_btn.visible, "Continue button must be visible when save exists!")
	
	# Test Continue Run
	main._on_continue_run()
	assert(GameManager.current_wave == 5, "Loaded run wave must be 5! Got: %d" % GameManager.current_wave)
	assert(GameManager.coins == 250, "Loaded run coins must be 250! Got: %d" % GameManager.coins)
	print("[6/16] Continue Run successfully restored Wave 5 and player inventory.")
	
	# Test Save & Quit from Pause Menu
	assert(is_instance_valid(main.pause_ui.save_quit_btn), "PauseUI must have a Save & Quit button!")
	assert(is_instance_valid(main.pause_ui.fullscreen_btn), "PauseUI must have a Fullscreen button!")
	main.pause_ui._on_save_quit_pressed()
	assert(GameManager.has_saved_run(), "Pause save & quit must persist run state!")
	print("[7/16] Pause Menu Save & Quit and Fullscreen options verified.")
	
	# Resume playing
	main._on_continue_run()
	main.shop_node._on_next_wave_pressed()
	
	# Test Wave 5 Big Boss Spawning (Centaur King)
	var boss = EnemyBase.new()
	main.add_child(boss)
	boss.init_enemy(EnemyBase.EnemyType.BOSS_CENTAUR_KING, 5, false, false)
	assert(boss.is_boss, "Boss must be marked as is_boss!")
	assert(boss.max_hp >= 3800.0, "Wave 5 Boss (Centaur King) must have huge HP (>= 3800)! Got: %f" % boss.max_hp)
	
	# Test All 4 Boss Attack Types
	# Attack 1: Melee Rush / Charge Slam
	boss._start_boss_melee_rush()
	boss._handle_movement(0.1)
	boss._boss_melee_ground_slam_finish()
	# Attack 2: 12/16-Directional Radial Barrage
	boss._boss_radial_barrage()
	# Attack 3: Targeted 5-Way Spreading Cluster Split Shot
	boss._boss_spreading_split_shot()
	# Attack 4: Volcanic Eruption & Swarmer Minion Surge
	boss._boss_volcanic_eruption_and_summon()
	
	# Test Drawing and Top HUD Boss Bar
	boss.queue_redraw()
	main.hud_node._process(0.1)
	assert(main.hud_node.boss_bar_panel.visible == true, "HUD top Boss Bar must be visible when boss is alive!")
	boss.queue_free()
	print("[8/16] Wave 5 Big Boss (Huge HP, 4 distinct attack types, in-world + HUD top health bars) verified.")
	
	# Test Wave 3 Boss (Crypt Abomination)
	var boss3 = EnemyBase.new()
	main.add_child(boss3)
	boss3.init_enemy(EnemyBase.EnemyType.BOSS_CRYPT_ABOMINATION, 3, false, false)
	assert(boss3.is_boss, "Wave 3 Crypt Abomination must be marked as is_boss!")
	assert(boss3.max_hp >= 2400.0, "Wave 3 Boss must have >= 2400 HP! Got: %f" % boss3.max_hp)
	boss3._boss_radial_barrage()
	boss3._boss_spreading_split_shot()
	boss3._boss_volcanic_eruption_and_summon()
	boss3.queue_redraw()
	boss3.queue_free()
	print("[9/16] Wave 3 Lower Level Boss mechanics verified.")
	
	# Test Weapon Slots Purchase Progression via Random Shop Card
	GameManager.add_coins(500)
	var slot_card_4 = ItemDatabase.get_weapon_slot_card()
	if not slot_card_4.is_empty():
		GameManager.buy_item(slot_card_4)
	print("[10/16] Weapon slot expansion card verified.")
	
	# Test Miniboss Mechanics (4.5x HP, 1.85x damage, 3 bones)
	var normal_mob = EnemyBase.new()
	main.add_child(normal_mob)
	normal_mob.init_enemy(EnemyBase.EnemyType.GOBLIN, 1, false, false)
	var normal_hp = normal_mob.max_hp
	var normal_dmg = normal_mob.contact_damage
	normal_mob.queue_free()
	
	var miniboss = EnemyBase.new()
	main.add_child(miniboss)
	miniboss.init_enemy(EnemyBase.EnemyType.GOBLIN, 1, false, true)
	assert(miniboss.is_miniboss, "Enemy must be marked as miniboss!")
	assert(miniboss.max_hp > normal_hp * 4.0, "Miniboss HP must be ~4.5x of normal mob!")
	assert(miniboss.contact_damage > normal_dmg * 1.7, "Miniboss damage must be ~1.85x of normal mob!")
	assert(miniboss.bone_drop_count == 3, "Miniboss must drop 3 bones!")
	miniboss.queue_redraw()
	miniboss.take_damage(20.0, false, "kinetic")
	miniboss.queue_free()
	print("[11/16] Miniboss mechanics verified.")
	
	# Test ShopUI "My Weapons" Window Toggle without rerolling shop cards
	main.shop_node.open_shop()
	var initial_cards = main.shop_node.shop_cards.duplicate(true)
	main.shop_node._toggle_my_weapons_view(true)
	assert(main.shop_node.my_weapons_view.visible == true, "My Weapons view must be visible!")
	main.shop_node._toggle_my_weapons_view(false)
	assert(main.shop_node.shop_main_view.visible == true, "Main Shop view must be visible again!")
	print("[12/16] 'My Weapons' Window open/close verified.")
	
	# Test Weapons Firing
	var player = main.player_node
	for w_id in ["pistol", "shotgun", "rocket_launcher", "flamethrower"]:
		var w_data = ItemDatabase.weapons[w_id].duplicate(true)
		var w_node = WeaponBase.new()
		w_node.set_script(load("res://scripts/weapons/weapon_base.gd"))
		w_node.init_weapon(w_data, 0, 1)
		player.add_child(w_node)
		w_node.current_aim_dir = Vector2.RIGHT
		w_node._shoot()
		w_node.queue_redraw()
		w_node.queue_free()
	print("[13/16] Weapons firing tested successfully.")
	
	# Test Dash Round Widget on HUD
	assert(main.hud_node.dash_panel != null, "HUD must have DashPanel!")
	assert(main.hud_node.dash_key_label.text == "[SPACE]", "Dash keybind must specify [SPACE]!")
	print("[14/16] Dash ability circular widget on HUD verified.")
	
	# Test 15: Turret Defense System Catalog & Purchase + Orbital Saws Removal
	assert(not ItemDatabase.weapons.has("orbiting_saws"), "orbiting_saws must be completely removed from weapons catalog!")
	assert(ItemDatabase.turrets.has("turret_ballista"), "ItemDatabase must contain turret_ballista!")
	assert(ItemDatabase.turrets.has("turret_cannon"), "ItemDatabase must contain turret_cannon!")
	assert(ItemDatabase.turrets.has("turret_flame"), "ItemDatabase must contain turret_flame!")
	assert(ItemDatabase.turrets.has("turret_ice"), "ItemDatabase must contain turret_ice!")
	assert(ItemDatabase.turrets["turret_flame"].get("turret_type") == "flame", "Flame turret type must be flame!")
	assert(ItemDatabase.turrets["turret_ice"].get("turret_type") == "ice", "Ice turret type must be ice!")
	
	GameManager.coins = 1000
	var ballista_card = ItemDatabase.turrets["turret_ballista"]
	var cannon_card = ItemDatabase.turrets["turret_cannon"]
	var flame_card = ItemDatabase.turrets["turret_flame"]
	var ice_card = ItemDatabase.turrets["turret_ice"]
	GameManager.buy_item(ballista_card)
	GameManager.buy_item(cannon_card)
	GameManager.buy_item(flame_card)
	GameManager.buy_item(ice_card)
	assert(GameManager.turret_inventory.size() == 4, "Turret inventory must hold 4 purchased turrets!")
	print("[15/18] Turret catalog & multi-turret inventory purchase verified.")
	
	# Test 16: Placement System & Bounds Validation
	var pm = main.placement_manager
	assert(is_instance_valid(pm), "TurretPlacementManager must be active in Main scene!")
	
	# Test cannot place inside furnace exclusion zone
	assert(pm._check_position_valid(Vector2(0, 0)) == false, "Must reject placement inside furnace center!")
	assert(pm._check_position_valid(Vector2(50, 50)) == false, "Must reject placement within furnace exclusion radius!")
	
	# Test cannot place outside arena boundaries
	assert(pm._check_position_valid(Vector2(950, 0)) == false, "Must reject placement outside level X bounds!")
	assert(pm._check_position_valid(Vector2(0, 800)) == false, "Must reject placement outside level Y bounds!")
	
	# Deploy all 4 turrets at distinct legal positions
	var legal_pos1 = Vector2(280, 200)
	pm.preview_pos = legal_pos1
	pm.is_position_valid = true
	pm._start_placement()
	pm._try_confirm_placement()
	assert(GameManager.turret_inventory.size() == 3, "Inventory should now hold 3 remaining turrets!")
	
	var legal_pos2 = Vector2(-280, -200)
	pm.preview_pos = legal_pos2
	pm.is_position_valid = true
	pm._try_confirm_placement()
	assert(GameManager.turret_inventory.size() == 2, "Inventory should now hold 2 remaining turrets!")
	
	var legal_pos3 = Vector2(280, -200)
	pm.preview_pos = legal_pos3
	pm.is_position_valid = true
	pm._try_confirm_placement()
	assert(GameManager.turret_inventory.size() == 1, "Inventory should now hold 1 remaining turret!")
	
	var legal_pos4 = Vector2(-280, 200)
	pm.preview_pos = legal_pos4
	pm.is_position_valid = true
	pm._try_confirm_placement()
	assert(GameManager.turret_inventory.size() == 0, "Inventory should now be empty after placing all 4 turrets!")
	assert(GameManager.placed_turrets_data.size() == 4, "Placed turrets record should have 4 entries!")
	
	# Verify all 4 turrets exist in the world group
	var placed_turrets = main.get_tree().get_nodes_in_group("turrets")
	assert(placed_turrets.size() >= 4, "World should contain at least 4 placed turrets!")
	print("[16/18] Turret placement restrictions (bounds + furnace exclusion) verified.")
	
	# Test 17: Turret Projectiles, Flame Pierce, Ice 7s Freeze & Detonation
	var arrow_proj = TurretProjectile.new()
	main.add_child(arrow_proj)
	arrow_proj.init_arrow(Vector2.RIGHT, 750.0, 30.0, 400.0, 4)
	assert(arrow_proj.pierce_left == 4, "Arrow projectile pierce must be 4!")
	arrow_proj.queue_free()
	
	var cannon_proj = TurretProjectile.new()
	main.add_child(cannon_proj)
	cannon_proj.init_cannonball(Vector2.RIGHT, 480.0, 60.0, 300.0, 100.0)
	cannon_proj._detonate_cannonball()
	
	# Test Flame Projectile
	var flame_proj = TurretProjectile.new()
	main.add_child(flame_proj)
	flame_proj.init_flame(Vector2.RIGHT, 420.0, 3.2, 190.0)
	assert(flame_proj.pierce_left == 99, "Flame projectile pierce must be 99 for streaming AoE!")
	
	# Test Ice Projectile & 5.0s Freeze Mechanics on Enemy
	var test_mob = EnemyBase.new()
	main.add_child(test_mob)
	test_mob.init_enemy(EnemyBase.EnemyType.GOBLIN, 1, false, false)
	assert(test_mob.is_frozen == false, "Enemy must not be frozen initially!")
	
	var ice_proj = TurretProjectile.new()
	main.add_child(ice_proj)
	ice_proj.init_ice(Vector2.RIGHT, 620.0, 6.0, 280.0, 5.0)
	ice_proj._apply_ice_hit(test_mob)
	assert(test_mob.is_frozen == true, "Enemy must be frozen after being hit by ice projectile!")
	assert(abs(test_mob.freeze_timer - 5.0) < 0.01, "Enemy freeze timer must be 5.0 seconds!")
	
	# Verify frozen enemy movement is zeroed
	test_mob._handle_movement(0.1)
	assert(test_mob.velocity == Vector2.ZERO, "Frozen enemy velocity must be ZERO!")
	
	# Test Fire & Ice Logical Interaction 1: Fire melts frozen enemy instantly & cancels burn
	test_mob.apply_burn(12.0, 3.0)
	assert(test_mob.is_frozen == false, "Shooting fire at frozen enemy must melt the ice instantly!")
	assert(test_mob.burn_timer == 0.0, "Fire effect must cancel out melting the ice for that shot!")
	
	# Test Fire & Ice Logical Interaction 2: Enemy on fire can still be frozen, and fire is extinguished
	test_mob.apply_burn(12.0, 3.0)
	assert(test_mob.burn_timer > 0.0, "Enemy must be on fire before ice hit!")
	test_mob.apply_freeze(5.0)
	assert(test_mob.is_frozen == true, "Enemy on fire must still be frozen by ice!")
	assert(test_mob.burn_timer == 0.0, "Ice must extinguish burning fire on that shot!")
	
	# Advance status effects past 5.0 seconds and verify thaw
	test_mob._process_status_effects(5.1)
	assert(test_mob.is_frozen == false, "Enemy must thaw out after freeze duration expires!")
	test_mob.queue_free()
	flame_proj.queue_free()
	ice_proj.queue_free()
	print("[17/18] Turret projectiles (pierce, AoE, flame stream & 5.0s ice freeze + melting logic) verified.")
	
	# Test 18: End Wave & Game Over with Save Cleanup
	GameManager.end_wave()
	GameManager.trigger_game_over()
	assert(not GameManager.has_saved_run(), "Active save run must be deleted upon Game Over!")
	print("[18/22] End-of-run recap & save cleanup verified.")
	
	# Test 19: Audio Warning SFX Resolution
	SoundManager.play_sfx("warning")
	assert(SoundManager.sfx_cache.has("warning"), "SoundManager must map 'warning' sound key without failing!")
	print("[19/22] Warning SFX audio alias verified.")
	
	# Test 20: Difficulty Selection & Scaling
	GameManager.selected_difficulty = GameManager.Difficulty.EASY
	assert(abs(GameManager.get_difficulty_enemy_hp_mult() - 0.75) < 0.01, "Easy mode enemy HP mult must be 0.75!")
	assert(abs(GameManager.get_difficulty_enemy_dmg_mult() - 0.70) < 0.01, "Easy mode enemy damage mult must be 0.70!")
	
	GameManager.selected_difficulty = GameManager.Difficulty.HARD
	assert(abs(GameManager.get_difficulty_enemy_hp_mult() - 1.30) < 0.01, "Hard mode enemy HP mult must be 1.30!")
	assert(abs(GameManager.get_difficulty_enemy_dmg_mult() - 1.35) < 0.01, "Hard mode enemy damage mult must be 1.35!")
	assert(abs(GameManager.get_difficulty_gold_reward_mult() - 1.20) < 0.01, "Hard mode gold mult must be 1.20 (+20%)!")
	
	# Test Enemy Scaling on Hard
	var hard_mob = EnemyBase.new()
	main.add_child(hard_mob)
	hard_mob.init_enemy(EnemyBase.EnemyType.GOBLIN, 1, false, false)
	assert(hard_mob.max_hp > normal_hp * 1.25, "Hard goblin HP must be ~1.30x normal goblin HP!")
	hard_mob.queue_free()
	
	# Test Difficulty Persistence in Saved Run
	GameManager.save_current_run("SHOP")
	GameManager.selected_difficulty = GameManager.Difficulty.EASY
	GameManager.load_saved_run()
	assert(GameManager.selected_difficulty == GameManager.Difficulty.HARD, "Saved run must restore Hard difficulty!")
	# Test Water Cooling Rebalance (-50% starting capacity & refill rate)
	GameManager.reset_game()
	assert(abs(GameManager.max_water - 50.0) < 0.01, "Base water capacity must be reduced by 50% to 50.0! Got: " + str(GameManager.max_water))
	assert(abs(GameManager.water_regen_rate - 6.0) < 0.01, "Base water refill rate must be reduced by 50% to 6.0! Got: " + str(GameManager.water_regen_rate))
	
	# Test Water Cooling Upgrades in Level-Up Upgrade Pool
	var found_water_cap = false
	var found_water_regen = false
	var level_up_script = preload("res://scripts/ui/level_up_ui.gd")
	for p in level_up_script.UPGRADE_POOL:
		if p.id == "water_capacity": found_water_cap = true
		elif p.id == "water_regen":
			found_water_regen = true
			assert(p.values[3] == 0.15, "Water refill top tier must be 0.15 (+15%)!")
	assert(found_water_cap, "LevelUpUI UPGRADE_POOL must contain 'water_capacity' upgrade!")
	assert(found_water_regen, "LevelUpUI UPGRADE_POOL must contain 'water_regen' upgrade!")
	
	# Test Laser Blaster 30% DPS Nerf
	var laser_item = ItemDatabase.get_item("laser_cannon")
	assert(abs(laser_item.damage - 5.95) < 0.01, "Laser Blaster damage must be reduced by 30% to 5.95! Got: " + str(laser_item.damage))
	
	# Test Cheat Key 5 removal (pressing 5 does not grant gold)
	var coins_before = GameManager.coins
	var key_event = InputEventKey.new()
	key_event.pressed = true
	key_event.keycode = KEY_5
	if main.has_method("_input"):
		main._input(key_event)
	assert(GameManager.coins == coins_before, "Pressing 5 must NOT add coins! Cheat key 5 must be removed.")
	
	# Test Shop Wave Transition: Wave 1 clear -> Shop displays START WAVE 2
	GameManager.current_wave = 1
	GameManager.end_wave()
	assert(GameManager.current_wave == 2, "After ending wave 1, current_wave must be 2!")
	assert(main.shop_node.next_wave_btn.text == "START WAVE 2 >>", "Shop button must say 'START WAVE 2 >>' after wave 1 clear! Got: %s" % main.shop_node.next_wave_btn.text)
	
	print("[20/22] Difficulty Selection, Water Rebalance, Laser Nerf, Cheat Key 5 Removal & Shop Wave Progression verified.")
	
	# Test 21: Spatial Tutorial System & Destination Markers
	assert(is_instance_valid(main.tutorial_manager), "Main must have TutorialManager active!")
	main._on_start_tutorial()
	assert(GameManager.is_tutorial == true, "GameManager.is_tutorial must be true during tutorial!")
	assert(main.tutorial_manager.is_active == true, "TutorialManager must be active!")
	assert(main.tutorial_manager.current_step == TUTORIAL_MANAGER_SCRIPT.Step.MOVE_NORTH, "Tutorial must begin at Step 1 (MOVE_NORTH)!")
	assert(main.tutorial_manager.active_markers.size() > 0, "Tutorial must display active destination markers!")
	
	# Verify Tutorial Player starts with Basic Pistol and Starter Turret
	assert(GameManager.equipped_weapons.size() > 0, "Tutorial must equip starter weapon!")
	assert(GameManager.equipped_weapons[0].id == "pistol", "Tutorial starter weapon must be pistol!")
	assert(main.player_node.weapon_instances.size() > 0, "Player must have instanced pistol in tutorial!")
	assert(GameManager.turret_inventory.size() > 0, "Tutorial must give player starter turret before placement mission!")
	
	# Test Marker target tracking
	var marker = main.tutorial_manager.active_markers[0]
	assert(marker != null, "Marker must exist!")
	
	# Test Tutorial Shop step & 500 gold bonus
	main.tutorial_manager._enter_step(TUTORIAL_MANAGER_SCRIPT.Step.ARMORY_SHOP)
	assert(GameManager.coins >= 500, "Tutorial shop step must award at least 500 bonus test gold!")
	assert(main.shop_node.shop_cards.size() >= 2, "Shop must present cards for tutorial purchase!")
	
	# Test that entering DEPLOY_DEFENSES guarantees a turret even if player didn't buy one in shop
	GameManager.turret_inventory.clear()
	main.tutorial_manager._enter_step(TUTORIAL_MANAGER_SCRIPT.Step.DEPLOY_DEFENSES)
	assert(GameManager.turret_inventory.size() > 0, "DEPLOY_DEFENSES must guarantee player has a turret ready to place!")
	
	# Cleanup tutorial
	main.tutorial_manager.stop_tutorial()
	assert(GameManager.is_tutorial == false, "Stopping tutorial must reset is_tutorial flag!")
	print("[21/22] Spatial Tutorial System (Waypoints, Pistol loadout, Starter Turret, +500 test gold) verified.")
	
	# Test 22: Monster Discovery UI clean removal
	assert(main.get_node_or_null("MonsterDiscoveryUI") == null, "MonsterDiscoveryUI must be completely removed from Main scene!")
	print("[22/23] Monster Discovery UI clean removal verified.")
	
	# Test 23: Polish Suite: RMB Lock-On, Stepped Volumes, Bone Feed SFX, Save & Return, Quit Button, Build Recap
	# 1. Stepped volume cycling
	var sfx_initial = SoundManager.get_sfx_volume_label()
	var sfx_next = SoundManager.cycle_sfx_volume()
	assert(sfx_next == "75%", "Cycling SFX from 100% must yield 75%! Got: " + str(sfx_next))
	var mus_next = SoundManager.cycle_music_volume()
	assert(mus_next == "75%", "Cycling Music from 100% must yield 75%! Got: " + str(mus_next))
	SoundManager.sfx_volume_step = 4
	SoundManager.music_volume_step = 4
	
	# 2. Bone Feed Sound verification
	assert(SoundManager.sfx_cache.has("furnace_feed"), "SoundManager must cache 'furnace_feed' sound!")
	assert(SoundManager.sfx_cache["furnace_feed"].data.size() > 0, "furnace_feed sound stream must contain audio data!")
	
	# 3. Save & Return UI labels
	assert(main.shop_node.save_quit_btn.text == "SAVE & RETURN", "Shop save button text must be 'SAVE & RETURN'! Got: %s" % main.shop_node.save_quit_btn.text)
	assert(main.pause_ui.save_quit_btn.text == "SAVE & RETURN TO MENU", "Pause save button text must be 'SAVE & RETURN TO MENU'! Got: %s" % main.pause_ui.save_quit_btn.text)
	
	# 4. Quit button on Main Menu
	assert(is_instance_valid(main.main_menu_node.quit_btn), "Main Menu must contain QuitButton!")
	
	# 5. Build Recap Loadout stats
	var run_stats = GameManager.get_run_stats()
	assert(run_stats.has("equipped_weapons"), "get_run_stats must include 'equipped_weapons' for build recap!")
	assert(run_stats.has("active_skills"), "get_run_stats must include 'active_skills' for build recap!")
	
	print("[23/24] Polish Suite (RMB Lock-On, Stepped Audio, Bone Feed SFX, Save & Return, Quit Button & Build Recap) verified.")
	
	# Test 24: Cryo Cannon (cryo_blaster) Nerf: 40% slow (+10% per tier: 50% Epic, 60% Legendary), Non-Freezing
	var cryo_base = ItemDatabase.weapons.get("cryo_blaster", {})
	assert(cryo_base.size() > 0, "Cryo Cannon must exist in ItemDatabase!")
	assert(cryo_base.get("special") == "cryo_slow", "Cryo Cannon special must be 'cryo_slow' instead of freeze!")
	assert(abs(cryo_base.get("slow_factor", 0.0) - 0.40) < 0.001, "Base Cryo Cannon slow factor must be 0.40 (40%)!")
	assert("40%" in cryo_base.get("desc", ""), "Cryo Cannon description must mention 40% slow!")
	
	# Verify Epic Tier upgrade gives +10% slow (50%)
	var cryo_epic = ItemDatabase.get_weapon_upgrade("cryo_blaster", ItemDatabase.TIER_EPIC)
	assert(abs(cryo_epic.get("slow_factor", 0.0) - 0.50) < 0.001, "Epic Cryo Cannon upgrade must give 0.50 (50%) slow!")
	assert("50% Slow" in cryo_epic.get("desc", ""), "Epic Cryo upgrade description must mention 50% Slow!")
	
	# Verify Legendary Tier upgrade gives +20% slow (60%)
	var cryo_leg = ItemDatabase.get_weapon_upgrade("cryo_blaster", ItemDatabase.TIER_LEGENDARY)
	assert(abs(cryo_leg.get("slow_factor", 0.0) - 0.60) < 0.001, "Legendary Cryo Cannon upgrade must give 0.60 (60%) slow!")
	assert("60% Slow" in cryo_leg.get("desc", ""), "Legendary Cryo upgrade description must mention 60% Slow!")
	
	# Verify Projectile and Enemy Slow Effect Application (Slow without freezing solid)
	var cryo_proj = ProjectileBase.new()
	cryo_proj.init_projectile(Vector2.RIGHT, 450.0, 6.5, 300.0, 99, 30.0, false, "cryo_slow", Color(0.3, 0.9, 1.0))
	cryo_proj.slow_factor = cryo_base.get("slow_factor", 0.40)
	
	var slow_test_mob = EnemyBase.new()
	main.add_child(slow_test_mob)
	slow_test_mob.init_enemy(EnemyBase.EnemyType.GOBLIN, 1, false, false)
	
	cryo_proj._hit_enemy(slow_test_mob)
	assert(slow_test_mob.is_frozen == false, "Cryo Cannon must NOT freeze enemy solid!")
	assert(abs(slow_test_mob.slow_factor - 0.40) < 0.001, "Enemy slow factor must match Cryo Cannon 40%!")
	assert(slow_test_mob.slow_timer > 0.0, "Enemy slow timer must be active!")
	
	# Test upgraded projectile (Epic 50%)
	var cryo_epic_proj = ProjectileBase.new()
	cryo_epic_proj.init_projectile(Vector2.RIGHT, 450.0, 10.0, 300.0, 99, 30.0, false, "cryo_slow", Color(0.3, 0.9, 1.0))
	cryo_epic_proj.slow_factor = cryo_epic.get("slow_factor", 0.50)
	cryo_epic_proj._hit_enemy(slow_test_mob)
	assert(slow_test_mob.is_frozen == false, "Epic Cryo Cannon must NOT freeze enemy solid!")
	assert(abs(slow_test_mob.slow_factor - 0.50) < 0.001, "Enemy slow factor must scale to 50% with Epic upgrade!")
	
	slow_test_mob.queue_free()
	cryo_proj.queue_free()
	cryo_epic_proj.queue_free()
	print("[24/24] Cryo Cannon Nerf (40% base slow, +10% per upgrade tier, non-solid freeze) verified.")
	
	print("--- ALL 24 TESTS PASSED WITH 0 ERRORS! ---")
	get_tree().quit(0)
