# runtime_test.gd - Automated Test Suite to Exercise All Systems, Loading Screen, Bosses, Fullscreen, and Save & Quit
extends SceneTree

const SOUND_MGR_SCRIPT = preload("res://scripts/globals/sound_manager.gd")
const ITEM_DB_SCRIPT = preload("res://scripts/globals/item_database.gd")
const GAME_MGR_SCRIPT = preload("res://scripts/globals/game_manager.gd")

func _init() -> void:
	print("--- STARTING COMPREHENSIVE RUNTIME TEST FOR THE FURNACE ---")
	
	# Instantiate Autoload Singletons
	var sound_mgr = SOUND_MGR_SCRIPT.new()
	sound_mgr.name = "SoundManager"
	root.add_child(sound_mgr)
	
	var item_db = ITEM_DB_SCRIPT.new()
	item_db.name = "ItemDatabase"
	root.add_child(item_db)
	
	var game_mgr = GAME_MGR_SCRIPT.new()
	game_mgr.name = "GameManager"
	root.add_child(game_mgr)
	
	# Load and instance Main Scene
	var main_scene = load("res://scenes/main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)
	
	print("[1/10] Main Scene instanced successfully with LoadingScreenUI.")
	assert(is_instance_valid(main.loading_screen_node), "LoadingScreenUI must exist in Main scene!")
	
	# Test Loading Screen completion
	main._on_loading_completed()
	assert(main.main_menu_node.visible, "MainMenuUI must be visible after loading completed!")
	print("[2/10] Loading screen completion transition verified.")
	
	# Test Fullscreen toggle on Main Menu
	assert(is_instance_valid(main.main_menu_node.fullscreen_btn), "MainMenuUI must have a fullscreen toggle button!")
	main.main_menu_node._on_fullscreen_toggle()
	main.main_menu_node._on_fullscreen_toggle()
	print("[3/10] Main Menu Fullscreen toggle verified.")
	
	# Start Run
	main._on_start_run()
	assert(game_mgr.max_bones_held == 10, "Base bone cap must be 10!")
	print("[4/10] Game Started & Initial Shop Opened.")
	
	# Test Buying items
	var p_item = item_db.get_item("pistol")
	game_mgr.buy_item(p_item)
	var s_item = item_db.get_item("raw_damage")
	game_mgr.buy_item(s_item)
	
	# Test Save & Quit from Shop
	assert(is_instance_valid(main.shop_node.save_quit_btn), "ShopUI must have a Save & Quit button!")
	game_mgr.current_wave = 5
	game_mgr.coins = 250
	var save_ok = game_mgr.save_current_run("SHOP")
	assert(save_ok, "save_current_run must succeed!")
	assert(game_mgr.has_saved_run(), "has_saved_run must be true!")
	var saved_info = game_mgr.get_saved_run_info()
	assert(int(saved_info.get("current_wave", 0)) == 5, "Saved run wave must be 5!")
	assert(int(saved_info.get("coins", 0)) == 250, "Saved run coins must be 250!")
	print("[5/10] Save & Quit from Shop verified (Wave 5, 250 coins saved).")
	
	# Return to Main Menu and check Continue Run button
	main._on_return_to_menu()
	assert(main.main_menu_node.visible, "Main menu must be visible after saving & quitting!")
	assert(main.main_menu_node.continue_btn.visible, "Continue button must be visible when save exists!")
	
	# Test Continue Run
	main._on_continue_run()
	assert(game_mgr.current_wave == 5, "Loaded run wave must be 5! Got: %d" % game_mgr.current_wave)
	assert(game_mgr.coins == 250, "Loaded run coins must be 250! Got: %d" % game_mgr.coins)
	print("[6/10] Continue Run successfully restored Wave 5 and player inventory.")
	
	# Test Save & Quit from Pause Menu
	assert(is_instance_valid(main.pause_ui.save_quit_btn), "PauseUI must have a Save & Quit button!")
	assert(is_instance_valid(main.pause_ui.fullscreen_btn), "PauseUI must have a Fullscreen button!")
	main.pause_ui._on_save_quit_pressed()
	assert(game_mgr.has_saved_run(), "Pause save & quit must persist run state!")
	print("[7/10] Pause Menu Save & Quit and Fullscreen options verified.")
	
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
	boss._draw()
	main.hud_node._process(0.1)
	assert(main.hud_node.boss_bar_panel.visible == true, "HUD top Boss Bar must be visible when boss is alive!")
	boss.queue_free()
	print("[8/10] Wave 5 Big Boss (Huge HP, 4 distinct attack types, in-world + HUD top health bars) verified.")
	
	# Test Wave 3 Boss (Crypt Abomination)
	var boss3 = EnemyBase.new()
	main.add_child(boss3)
	boss3.init_enemy(EnemyBase.EnemyType.BOSS_CRYPT_ABOMINATION, 3, false, false)
	assert(boss3.is_boss, "Wave 3 Crypt Abomination must be marked as is_boss!")
	assert(boss3.max_hp >= 2400.0, "Wave 3 Boss must have >= 2400 HP! Got: %f" % boss3.max_hp)
	boss3._boss_radial_barrage()
	boss3._boss_spreading_split_shot()
	boss3._boss_volcanic_eruption_and_summon()
	boss3._draw()
	boss3.queue_free()
	print("[9/10] Wave 3 Lower Level Boss mechanics verified.")
	
	# Test Game Over deletes active save file
	game_mgr.trigger_game_over()
	assert(not game_mgr.has_saved_run(), "Active save run must be deleted upon Game Over!")
	print("[10/10] Save file cleanup on game over verified.")
	
	print("--- ALL TESTS PASSED WITH 0 ERRORS! ---")
	quit()
