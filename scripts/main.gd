# main.gd - Root Game Controller Assembling World, Entities, Systems, and UI
class_name Main
extends Node2D

@onready var arena_node: Arena = $Arena
@onready var furnace_node: Furnace = $Furnace
@onready var player_node: Player = $Player
@onready var spawner_node: ZombieSpawner = $ZombieSpawner
@onready var camera_node: GameCamera = $GameCamera
@onready var hud_node: GameHUD = $HUD

@onready var shop_node: ShopUI = $ShopUI
@onready var game_over_node: GameOverUI = $GameOverUI
@onready var main_menu_node: MainMenuUI = $MainMenuUI
@onready var pause_ui: PauseUI = $PauseUI
@onready var level_up_ui: LevelUpUI = $LevelUpUI
@onready var loading_screen_node: CanvasLayer = $LoadingScreenUI

const TURRET_PLACEMENT_MANAGER_SCRIPT = preload("res://scripts/turrets/turret_placement_manager.gd")
const TUTORIAL_MANAGER_SCRIPT = preload("res://scripts/tutorial/tutorial_manager.gd")

var placement_manager: Node2D = null
var tutorial_manager: Node2D = null

func _ready() -> void:
	placement_manager = TURRET_PLACEMENT_MANAGER_SCRIPT.new()
	placement_manager.name = "TurretPlacementManager"
	add_child(placement_manager)
	
	tutorial_manager = TUTORIAL_MANAGER_SCRIPT.new()
	tutorial_manager.name = "TutorialManager"
	add_child(tutorial_manager)
	tutorial_manager.tutorial_completed.connect(_on_tutorial_completed)
	tutorial_manager.return_to_menu_requested.connect(_on_return_to_menu)
	
	pause_ui.restart_requested.connect(_on_restart_run)
	pause_ui.menu_requested.connect(_on_return_to_menu)
	pause_ui.save_and_quit_requested.connect(_on_return_to_menu)
	shop_node.save_and_quit_requested.connect(_on_return_to_menu)
	
	_connect_events()
	_setup_initial_state()

func _connect_events() -> void:
	main_menu_node.start_game_requested.connect(_on_start_run)
	main_menu_node.continue_game_requested.connect(_on_continue_run)
	main_menu_node.tutorial_requested.connect(_on_start_tutorial)
	game_over_node.restart_requested.connect(_on_restart_run)
	game_over_node.menu_requested.connect(_on_return_to_menu)
	GameManager.state_changed.connect(_on_game_state_changed)
	GameManager.wave_started.connect(_on_wave_started)
	
	if is_instance_valid(loading_screen_node):
		loading_screen_node.loading_completed.connect(_on_loading_completed)

func _on_wave_started(_wave: int) -> void:
	_cleanup_world_entities()

func _setup_initial_state() -> void:
	if is_instance_valid(loading_screen_node):
		loading_screen_node.visible = true
		main_menu_node.visible = false
	else:
		main_menu_node.visible = true
		main_menu_node.update_records_display()
		
	shop_node.visible = false
	game_over_node.visible = false
	hud_node.visible = false
	pause_ui.visible = false
	level_up_ui.visible = false
	player_node.global_position = Vector2(0, 140)
	furnace_node.global_position = Vector2.ZERO

func _on_loading_completed() -> void:
	main_menu_node.visible = true
	main_menu_node.update_records_display()

func _on_start_run() -> void:
	if is_instance_valid(tutorial_manager):
		tutorial_manager.stop_tutorial()
	get_tree().paused = false
	_cleanup_world_entities()
	
	SoundManager.reset_audio_state()
	
	if is_instance_valid(furnace_node) and furnace_node.has_method("reset_furnace"):
		furnace_node.reset_furnace()
	
	if is_instance_valid(player_node):
		if player_node.has_method("reset_player"):
			player_node.reset_player()
		else:
			player_node.global_position = Vector2(0, 140)
			player_node.velocity = Vector2.ZERO
		
	if is_instance_valid(spawner_node) and spawner_node.has_method("reset_spawner"):
		spawner_node.reset_spawner()
		
	if is_instance_valid(shop_node) and shop_node.has_method("reset_shop"):
		shop_node.reset_shop()
		
	if is_instance_valid(level_up_ui) and level_up_ui.has_method("reset_level_up"):
		level_up_ui.reset_level_up()
		
	if is_instance_valid(camera_node) and camera_node.has_method("reset_camera"):
		camera_node.reset_camera()
		
	# Delete previous save if starting fresh new run
	GameManager.delete_saved_run()
	GameManager.start_new_run()
	
	# Clear any previous turrets from the world
	var old_turrets = get_tree().get_nodes_in_group("turrets")
	for t in old_turrets:
		if is_instance_valid(t):
			t.queue_free()
	
	furnace_node.global_position = Vector2.ZERO
	
	hud_node.visible = true
	main_menu_node.visible = false
	game_over_node.visible = false
	if is_instance_valid(pause_ui) and pause_ui.has_method("close_pause"):
		pause_ui.close_pause()
	
	# Open initial shop so player can spend starting 40 gold on first upgrades!
	GameManager.current_state = GameManager.GameState.SHOP
	shop_node.open_shop()

func _on_continue_run() -> void:
	get_tree().paused = false
	_cleanup_world_entities()
	
	SoundManager.reset_audio_state()
	
	if is_instance_valid(furnace_node) and furnace_node.has_method("reset_furnace"):
		furnace_node.reset_furnace()
		
	if is_instance_valid(player_node):
		if player_node.has_method("reset_player"):
			player_node.reset_player()
		else:
			player_node.global_position = Vector2(0, 140)
			player_node.velocity = Vector2.ZERO
			
	if is_instance_valid(spawner_node) and spawner_node.has_method("reset_spawner"):
		spawner_node.reset_spawner()
		
	if is_instance_valid(shop_node) and shop_node.has_method("reset_shop"):
		shop_node.reset_shop()
		
	if is_instance_valid(level_up_ui) and level_up_ui.has_method("reset_level_up"):
		level_up_ui.reset_level_up()
		
	if is_instance_valid(camera_node) and camera_node.has_method("reset_camera"):
		camera_node.reset_camera()
		
	var info = GameManager.get_saved_run_info()
	var saved_state = info.get("saved_state", "SHOP")
	var success = GameManager.load_saved_run()
	
	if not success:
		_on_start_run()
		return
		
	# Restore placed turrets from saved run
	var old_turrets = get_tree().get_nodes_in_group("turrets")
	for t in old_turrets:
		if is_instance_valid(t):
			t.queue_free()
			
	for pt in GameManager.placed_turrets_data:
		if pt is Dictionary:
			var t_type = pt.get("turret_type", "ballista")
			var t_pos = Vector2(pt.get("x", 0.0), pt.get("y", 0.0))
			var turret = preload("res://scripts/turrets/turret_base.gd").new()
			add_child(turret)
			turret.global_position = t_pos
			turret.configure_turret(t_type)
		
	furnace_node.global_position = Vector2.ZERO
	hud_node.visible = true
	main_menu_node.visible = false
	game_over_node.visible = false
	if is_instance_valid(pause_ui) and pause_ui.has_method("close_pause"):
		pause_ui.close_pause()
		
	if saved_state == "SHOP":
		GameManager.current_state = GameManager.GameState.SHOP
		shop_node.open_shop()
	else:
		GameManager.start_wave()

func _on_start_tutorial() -> void:
	if is_instance_valid(tutorial_manager):
		tutorial_manager.stop_tutorial()
		
	get_tree().paused = false
	_cleanup_world_entities()
	SoundManager.reset_audio_state()
	
	GameManager.reset_game()
	GameManager.is_tutorial = true
	
	if is_instance_valid(furnace_node) and furnace_node.has_method("reset_furnace"):
		furnace_node.reset_furnace()
	if is_instance_valid(player_node) and player_node.has_method("reset_player"):
		player_node.reset_player()
	if is_instance_valid(spawner_node) and spawner_node.has_method("reset_spawner"):
		spawner_node.reset_spawner()
	if is_instance_valid(shop_node) and shop_node.has_method("reset_shop"):
		shop_node.reset_shop()
	if is_instance_valid(level_up_ui) and level_up_ui.has_method("reset_level_up"):
		level_up_ui.reset_level_up()
	if is_instance_valid(camera_node) and camera_node.has_method("reset_camera"):
		camera_node.reset_camera()
		
	var old_turrets = get_tree().get_nodes_in_group("turrets")
	for t in old_turrets:
		if is_instance_valid(t): t.queue_free()
		
	furnace_node.global_position = Vector2.ZERO
	hud_node.visible = true
	main_menu_node.visible = false
	game_over_node.visible = false
	if is_instance_valid(pause_ui) and pause_ui.has_method("close_pause"):
		pause_ui.close_pause()
		
	tutorial_manager.start_tutorial(self)

func _on_tutorial_completed() -> void:
	_on_start_run()

func _on_restart_run() -> void:
	_on_start_run()

func _on_return_to_menu() -> void:
	if is_instance_valid(tutorial_manager):
		tutorial_manager.stop_tutorial()
	get_tree().paused = false
	_cleanup_world_entities()
	SoundManager.reset_audio_state()
	
	if is_instance_valid(furnace_node) and furnace_node.has_method("reset_furnace"):
		furnace_node.reset_furnace()
		
	if is_instance_valid(player_node) and player_node.has_method("reset_player"):
		player_node.reset_player()
		
	if is_instance_valid(spawner_node) and spawner_node.has_method("reset_spawner"):
		spawner_node.reset_spawner()
		
	if is_instance_valid(shop_node) and shop_node.has_method("reset_shop"):
		shop_node.reset_shop()
		
	if is_instance_valid(level_up_ui) and level_up_ui.has_method("reset_level_up"):
		level_up_ui.reset_level_up()
		
	if is_instance_valid(camera_node) and camera_node.has_method("reset_camera"):
		camera_node.reset_camera()
		
	hud_node.visible = false
	shop_node.visible = false
	game_over_node.visible = false
	if is_instance_valid(pause_ui) and pause_ui.has_method("close_pause"):
		pause_ui.close_pause()
	if is_instance_valid(main_menu_node) and main_menu_node.has_method("update_records_display"):
		main_menu_node.update_records_display()
	main_menu_node.visible = true
	GameManager.current_state = GameManager.GameState.MENU

func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.PLAYING:
			shop_node.close_shop()
			hud_node.visible = true
		GameManager.GameState.SHOP:
			_cleanup_world_entities()
			player_node.global_position = Vector2(0, 140)
			shop_node.open_shop()
		GameManager.GameState.GAME_OVER, GameManager.GameState.VICTORY:
			shop_node.close_shop()
			hud_node.visible = false
			_cleanup_world_entities()

func _cleanup_world_entities() -> void:
	GameManager.unlock_target()
	if is_instance_valid(player_node) and player_node.has_method("clear_status_effects"):
		player_node.clear_status_effects()
		
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e):
			e.queue_free()
			
	var pickups = get_tree().get_nodes_in_group("pickups")
	for p in pickups:
		if is_instance_valid(p):
			p.queue_free()
			
	var hazards = get_tree().get_nodes_in_group("hazards")
	for h in hazards:
		if is_instance_valid(h):
			h.queue_free()
			
	# Remove active projectiles, pools, and floating damage numbers from root and main
	var scene_root = get_tree().current_scene
	if is_instance_valid(scene_root):
		for child in scene_root.get_children():
			if child is ProjectileBase or child is AcidPool or child is DamageNumber or child.is_in_group("turret_projectiles") or child.is_in_group("turret_effects"):
				child.queue_free()
				
	for child in get_children():
		if child is ProjectileBase or child is AcidPool or child is DamageNumber or child.is_in_group("turret_projectiles") or child.is_in_group("turret_effects"):
			child.queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen") or (event is InputEventKey and event.pressed and not event.is_echo() and (event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed))):
		GameManager.toggle_fullscreen()
