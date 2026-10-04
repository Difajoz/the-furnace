# tutorial_manager.gd - Spatial Step-by-Step Training Academy Controller
class_name TutorialManager
extends Node2D

signal tutorial_completed()
signal return_to_menu_requested()

enum Step {
	MOVE_NORTH,
	SLAY_SLIMES,
	COLLECT_BONES,
	SMELT_BONES,
	COOL_FURNACE,
	DASH_EVADE,
	TARGET_LOCK,
	ARMORY_SHOP,
	DEPLOY_DEFENSES,
	GRADUATION_TRIAL,
	COMPLETED
}

const MARKER_SCRIPT = preload("res://scripts/ui/tutorial_destination_marker.gd")

var current_step: Step = Step.MOVE_NORTH
var is_active: bool = false
var step_timer: float = 0.0

# Active markers
var active_markers: Array = []

# References
var main_ref: Node2D = null
var hud_banner: PanelContainer = null
var hud_banner_title: Label = null
var hud_banner_desc: Label = null
var victory_dialog: PanelContainer = null

# Step Tracking data
var spawned_monsters: Array[Node2D] = []
var training_dummy: Node2D = null
var target_was_locked: bool = false
var turret_was_placed: bool = false
var skill_was_used: bool = false

# Spatial Waypoint Coordinates
const POS_NORTH_CAMP: Vector2 = Vector2(0, -360)
const POS_WEST_CRYPT: Vector2 = Vector2(-420, -120)
const POS_SOUTH_RANGE: Vector2 = Vector2(0, 360)
const POS_EAST_RANGE: Vector2 = Vector2(420, 0)
const POS_FURNACE: Vector2 = Vector2(0, 0)

func _ready() -> void:
	z_index = 30
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_tutorial(main_node: Node2D) -> void:
	main_ref = main_node
	is_active = true
	current_step = Step.MOVE_NORTH
	step_timer = 0.0
	target_was_locked = false
	turret_was_placed = false
	skill_was_used = false
	
	GameManager.is_tutorial = true
	GameManager.current_state = GameManager.GameState.PLAYING
	GameManager.is_wave_running = true
	GameManager.wave_timer = 9999.0
	GameManager.wave_duration = 9999.0
	
	# Ensure player has starter pistol for combat training
	if GameManager.equipped_weapons.is_empty():
		var starter_pistol = ItemDatabase.get_item("pistol").duplicate(true)
		GameManager.equipped_weapons.append(starter_pistol)
		GameManager.emit_signal("weapons_updated")
		
	# Ensure player already has a turret ready for defense deployment mission
	if GameManager.turret_inventory.is_empty():
		var starter_turret = ItemDatabase.turrets["turret_ballista"].duplicate(true)
		GameManager.turret_inventory.append(starter_turret)
		GameManager.emit_signal("turret_inventory_updated")
	
	_clear_all_markers()
	_setup_hud_banner()
	
	# Connect manager signals
	if not GameManager.target_lock_changed.is_connected(_on_target_lock_changed):
		GameManager.target_lock_changed.connect(_on_target_lock_changed)
	if not GameManager.placement_mode_toggled.is_connected(_on_placement_toggled):
		GameManager.placement_mode_toggled.connect(_on_placement_toggled)
		
	# Put player at start pos and rebuild weapons
	if is_instance_valid(GameManager.player_node):
		GameManager.player_node.global_position = Vector2(0, 140)
		GameManager.player_node.velocity = Vector2.ZERO
		if GameManager.player_node.weapon_instances.is_empty() and GameManager.player_node.has_method("_rebuild_weapons"):
			GameManager.player_node._rebuild_weapons()
		
	_enter_step(Step.MOVE_NORTH)

func stop_tutorial() -> void:
	is_active = false
	GameManager.is_tutorial = false
	_clear_all_markers()
	if is_instance_valid(hud_banner):
		hud_banner.visible = false
	if is_instance_valid(victory_dialog):
		victory_dialog.visible = false
	for m in spawned_monsters:
		if is_instance_valid(m): m.queue_free()
	spawned_monsters.clear()
	if is_instance_valid(training_dummy):
		training_dummy.queue_free()
		training_dummy = null

func _process(delta: float) -> void:
	if not is_active or GameManager.current_state != GameManager.GameState.PLAYING:
		return
		
	step_timer += delta
	
	# Protective Ward: Keep player alive during lessons
	if GameManager.current_hp <= 25.0:
		GameManager.heal_player(80.0)
		if is_instance_valid(GameManager.player_node):
			GameManager.emit_signal("show_damage_number", GameManager.player_node.global_position + Vector2(0, -45), "TUTORIAL WARD!", Color8(80, 230, 255), true)
			
	match current_step:
		Step.MOVE_NORTH:
			_process_move_north()
		Step.SLAY_SLIMES:
			_process_slay_slimes()
		Step.COLLECT_BONES:
			_process_collect_bones()
		Step.SMELT_BONES:
			_process_smelt_bones()
		Step.COOL_FURNACE:
			_process_cool_furnace()
		Step.DASH_EVADE:
			_process_dash_evade()
		Step.TARGET_LOCK:
			_process_target_lock()
		Step.DEPLOY_DEFENSES:
			_process_deploy_defenses()
		Step.GRADUATION_TRIAL:
			_process_graduation_trial()

# --- STEP IMPLEMENTATIONS ---

func _enter_step(step: Step) -> void:
	current_step = step
	step_timer = 0.0
	_clear_all_markers()
	SoundManager.play_sfx("coin_pickup", 0.05, 1.0)
	
	match step:
		Step.MOVE_NORTH:
			_update_banner("STEP 1/9: EXPLORATION", "Move with [WASD] to the North Training Camp.")
			var m = _create_marker_at_pos(POS_NORTH_CAMP, "▼ [GO TO NORTH TRAINING CAMP]", Color8(80, 235, 120), -40.0)
			m.show_distance = true
			
		Step.SLAY_SLIMES:
			_update_banner("STEP 2/9: COMBAT & AUTO-AIM", "Move West and destroy the Slimes! Weapons auto-target nearby enemies.")
			_spawn_training_slimes()
			
		Step.COLLECT_BONES:
			_update_banner("STEP 3/9: RESOURCE GATHERING", "Collect the fallen bones! (Carrying Bag limit: 10 bones)")
			_mark_fallen_bones()
			
		Step.SMELT_BONES:
			_update_banner("STEP 4/9: THE CRUCIBLE", "Return to the central furnace and HOLD [E] to smelt bones into gold!")
			if is_instance_valid(GameManager.furnace_node):
				_create_marker_on_node(GameManager.furnace_node, "▼ [HOLD [E] TO SMELT BONES]", Color8(255, 205, 50), -85.0)
				
		Step.COOL_FURNACE:
			_update_banner("STEP 5/9: THERMAL CONTROL", "Crucible heat is critical! Aim at the furnace and HOLD [LMB] to spray water!")
			if is_instance_valid(GameManager.furnace_node):
				GameManager.furnace_node.temperature = 55.0 # Spike temperature to demonstrate
				_create_marker_on_node(GameManager.furnace_node, "▼ [HOLD [LMB] TO SPRAY WATER & COOL]", Color8(60, 220, 255), -85.0)
			# Refill water tank for the test
			GameManager.current_water = GameManager.max_water
			GameManager.emit_signal("player_water_changed", GameManager.current_water, GameManager.max_water)
				
		Step.DASH_EVADE:
			_update_banner("STEP 6/9: MOBILITY & DASH", "Move South to the Dash Range and press [SPACE] to dash!")
			var m = _create_marker_at_pos(POS_SOUTH_RANGE, "▼ [GO TO SOUTH RANGE]", Color8(80, 235, 120), -40.0)
			m.show_distance = true
			
		Step.TARGET_LOCK:
			_update_banner("STEP 7/9: TARGET LOCK-ON", "Head East. Right-Click the monster with [RMB] to lock on, then press [Q] to unlock!")
			_spawn_training_dummy()
			
		Step.ARMORY_SHOP:
			_update_banner("STEP 8/9: THE FOUNDRY ARMORY", "Spend your +500 test gold on Turrets & Skills, then click 'START WAVE >>'!")
			_open_tutorial_shop()
			
		Step.DEPLOY_DEFENSES:
			_update_banner("STEP 9/9: DEFENSES & SKILLS", "Press [T] then Left-Click to deploy your Turret! Press [1] to trigger your skill!")
			# Ensure player has a turret before placing turret objective even if not bought in shop
			if GameManager.turret_inventory.is_empty():
				var starter_turret = ItemDatabase.turrets["turret_ballista"].duplicate(true)
				GameManager.turret_inventory.append(starter_turret)
				GameManager.emit_signal("turret_inventory_updated")
			if GameManager.active_skills.is_empty():
				var starter_skill = ItemDatabase.active_skills["active_damage_boost"].duplicate(true)
				GameManager.add_active_skill(starter_skill)
			_prompt_turret_and_skill()
			
		Step.GRADUATION_TRIAL:
			_update_banner("FINAL TRIAL: DEFEND THE FOUNDRY", "Defend the crucible alongside your turret against the test horde!")
			_spawn_graduation_horde()
			
		Step.COMPLETED:
			_show_victory_dialog()

func _process_move_north() -> void:
	if not is_instance_valid(GameManager.player_node): return
	var dist = GameManager.player_node.global_position.distance_to(POS_NORTH_CAMP)
	if dist <= 95.0:
		_enter_step(Step.SLAY_SLIMES)

func _spawn_training_slimes() -> void:
	spawned_monsters.clear()
	var parent_n = main_ref if is_instance_valid(main_ref) else self
	var positions = [Vector2(-430, -140), Vector2(-390, -100)]
	for p in positions:
		var slime = EnemyBase.new()
		parent_n.add_child(slime)
		slime.global_position = p
		slime.init_enemy(EnemyBase.EnemyType.SLIME, 1, false, false)
		slime.max_hp = 18.0
		slime.hp = 18.0
		slime.base_speed = 65.0 # Slower for training
		spawned_monsters.append(slime)
		var m = _create_marker_on_node(slime, "▼ [SLAY SLIME]", Color8(255, 90, 90), -45.0)
		m.show_distance = true

func _process_slay_slimes() -> void:
	var alive_count = 0
	for m in spawned_monsters:
		if is_instance_valid(m) and not m.is_queued_for_deletion():
			alive_count += 1
	if alive_count == 0:
		_enter_step(Step.COLLECT_BONES)

func _mark_fallen_bones() -> void:
	var pickups = get_tree().get_nodes_in_group("pickups")
	for p in pickups:
		if is_instance_valid(p) and p is BonePickup:
			_create_marker_on_node(p, "▼ [COLLECT BONE]", Color8(255, 235, 140), -35.0)

func _process_collect_bones() -> void:
	# If no bone pickups left or bones collected
	var bone_pickups = 0
	var pickups = get_tree().get_nodes_in_group("pickups")
	for p in pickups:
		if is_instance_valid(p) and p is BonePickup:
			bone_pickups += 1
			
	if bone_pickups == 0 or GameManager.bones_held >= 2:
		# Guarantee player has at least 5 bones to smelt
		if GameManager.bones_held < 5:
			GameManager.add_bones(5 - GameManager.bones_held)
		_enter_step(Step.SMELT_BONES)

func _process_smelt_bones() -> void:
	if GameManager.bones_held == 0:
		# Mark any coins ejected
		var pickups = get_tree().get_nodes_in_group("pickups")
		var coin_count = 0
		for p in pickups:
			if is_instance_valid(p) and p is CoinPickup:
				coin_count += 1
				_create_marker_on_node(p, "▼ [COLLECT COIN]", Color8(255, 215, 40), -30.0)
				
		if coin_count == 0:
			_enter_step(Step.COOL_FURNACE)

func _process_cool_furnace() -> void:
	if is_instance_valid(GameManager.furnace_node):
		if GameManager.furnace_node.temperature <= 25.0:
			_enter_step(Step.DASH_EVADE)

func _process_dash_evade() -> void:
	if not is_instance_valid(GameManager.player_node): return
	var p = GameManager.player_node
	var dist = p.global_position.distance_to(POS_SOUTH_RANGE)
	if dist <= 110.0:
		# Player reached South range, tell them to dash!
		_clear_all_markers()
		_create_marker_on_node(p, "▼ [PRESS [SPACE] TO DASH]", Color8(44, 245, 120), -65.0)
		_update_banner("STEP 6/9: DASH EVADE", "Press [SPACE]! Dash grants brief invulnerability and high burst speed.")
		if p.is_dashing or p.dash_timer > 0.0:
			_enter_step(Step.TARGET_LOCK)

func _spawn_training_dummy() -> void:
	var parent_n = main_ref if is_instance_valid(main_ref) else self
	training_dummy = EnemyBase.new()
	parent_n.add_child(training_dummy)
	training_dummy.global_position = POS_EAST_RANGE
	training_dummy.init_enemy(EnemyBase.EnemyType.GOBLIN, 1, false, false)
	training_dummy.max_hp = 350.0 # High HP so it doesn't immediately die before locking
	training_dummy.hp = 350.0
	training_dummy.base_speed = 0.0 # Stationary dummy
	
	var m = _create_marker_on_node(training_dummy, "▼ [RIGHT CLICK TO LOCK-ON]", Color8(255, 80, 80), -50.0)
	m.show_distance = true
	target_was_locked = false

func _on_target_lock_changed(target: Node2D) -> void:
	if not is_active: return
	if current_step == Step.TARGET_LOCK:
		if is_instance_valid(target):
			target_was_locked = true
			_clear_all_markers()
			if is_instance_valid(GameManager.player_node):
				_create_marker_on_node(GameManager.player_node, "▼ [PRESS [Q] TO UNLOCK]", Color8(255, 205, 50), -65.0)
			_update_banner("STEP 7/9: TARGET FOCUS", "Locked in! All weapons focus this target. Now press [Q] to unlock!")
		elif target_was_locked:
			# Target unlocked successfully!
			if is_instance_valid(training_dummy):
				training_dummy.queue_free()
				training_dummy = null
			_enter_step(Step.ARMORY_SHOP)

func _process_target_lock() -> void:
	# If dummy died accidentally before unlocking
	if not is_instance_valid(training_dummy) and not target_was_locked:
		_spawn_training_dummy()

func _open_tutorial_shop() -> void:
	# Grant +500 test gold!
	GameManager.add_coins(500)
	SoundManager.play_sfx("level_up", 0.1, 2.0)
	
	if is_instance_valid(main_ref) and "shop_node" in main_ref and is_instance_valid(main_ref.shop_node):
		var shop = main_ref.shop_node
		GameManager.current_state = GameManager.GameState.SHOP
		shop.open_shop()
		
		# Force inject guaranteed Turrets & Active Skill into shop cards
		shop.shop_cards[0] = ItemDatabase.turrets["turret_ballista"].duplicate(true)
		shop.shop_cards[1] = ItemDatabase.turrets["turret_cannon"].duplicate(true)
		shop.shop_cards[2] = ItemDatabase.active_skills["active_damage_boost"].duplicate(true)
		shop.shop_cards[3] = ItemDatabase.weapons["assault_rifle"].duplicate(true)
		shop._render_cards()
		
		# Connect to shop start wave button
		if shop.next_wave_btn and not shop.next_wave_btn.pressed.is_connected(_on_shop_wave_started):
			shop.next_wave_btn.pressed.connect(_on_shop_wave_started, CONNECT_ONE_SHOT)

func _on_shop_wave_started() -> void:
	if not is_active: return
	_enter_step(Step.DEPLOY_DEFENSES)

func _prompt_turret_and_skill() -> void:
	_clear_all_markers()
	if is_instance_valid(GameManager.player_node):
		_create_marker_on_node(GameManager.player_node, "▼ [PRESS [T] TO PLACE TURRET]", Color8(255, 195, 40), -65.0)

func _on_placement_toggled(active: bool) -> void:
	if not is_active: return
	if current_step == Step.DEPLOY_DEFENSES and active:
		_clear_all_markers()
		_update_banner("STEP 9/9: TURRET DEPLOYMENT", "Aim with cursor outside furnace and LEFT CLICK to construct. Press [1] for Skill!")

func _process_deploy_defenses() -> void:
	var placed_turrets = get_tree().get_nodes_in_group("turrets")
	if not turret_was_placed and placed_turrets.size() > 0:
		turret_was_placed = true
		_clear_all_markers()
		if is_instance_valid(GameManager.player_node):
			_create_marker_on_node(GameManager.player_node, "▼ [PRESS [1] TO ACTIVATE SKILL]", Color8(255, 110, 40), -65.0)
		_update_banner("STEP 9/9: ACTIVE SKILL", "Turret deployed! Now press [1] on your keyboard to trigger Overdrive Surge!")
		
	# Check if active skill was activated
	if GameManager.active_damage_boost_timer > 0.0 or skill_was_used:
		skill_was_used = true
		if turret_was_placed:
			_enter_step(Step.GRADUATION_TRIAL)

func _spawn_graduation_horde() -> void:
	spawned_monsters.clear()
	var parent_n = main_ref if is_instance_valid(main_ref) else self
	var offsets = [Vector2(-120, -420), Vector2(-40, -440), Vector2(40, -440), Vector2(120, -420)]
	for off in offsets:
		var mob = EnemyBase.new()
		parent_n.add_child(mob)
		mob.global_position = off
		mob.init_enemy(EnemyBase.EnemyType.GOBLIN, 1, false, false)
		mob.max_hp = 35.0
		mob.hp = 35.0
		spawned_monsters.append(mob)
		
	_create_marker_at_pos(Vector2(0, -430), "▼ [DEFEND THE FOUNDRY!]", Color8(255, 75, 75), -20.0)

func _process_graduation_trial() -> void:
	var alive = 0
	for m in spawned_monsters:
		if is_instance_valid(m) and not m.is_queued_for_deletion():
			alive += 1
	if alive == 0 and step_timer >= 2.0:
		_enter_step(Step.COMPLETED)

# --- VISUALS & HUD ---

func _setup_hud_banner() -> void:
	if is_instance_valid(hud_banner):
		hud_banner.visible = true
		return
		
	var hud = main_ref.hud_node if is_instance_valid(main_ref) and "hud_node" in main_ref else null
	if not hud: return
	
	hud_banner = PanelContainer.new()
	hud_banner.name = "TutorialBanner"
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color8(14, 18, 26, 245)
	sb.border_color = Color8(55, 200, 255)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	hud_banner.add_theme_stylebox_override("panel", sb)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 10)
	hud_banner.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)
	
	hud_banner_title = Label.new()
	hud_banner_title.add_theme_font_size_override("font_size", 24)
	hud_banner_title.add_theme_color_override("font_color", Color8(55, 220, 255))
	hud_banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hud_banner_title)
	
	hud_banner_desc = Label.new()
	hud_banner_desc.add_theme_font_size_override("font_size", 18)
	hud_banner_desc.add_theme_color_override("font_color", Color8(230, 235, 245))
	hud_banner_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hud_banner_desc)
	
	hud.get_node("Root").add_child(hud_banner)
	hud_banner.anchor_left = 0.5
	hud_banner.anchor_right = 0.5
	hud_banner.anchor_top = 0.0
	hud_banner.anchor_bottom = 0.0
	hud_banner.offset_left = -380
	hud_banner.offset_right = 380
	hud_banner.offset_top = 16
	hud_banner.offset_bottom = 90

func _update_banner(title: String, desc: String) -> void:
	if is_instance_valid(hud_banner_title):
		hud_banner_title.text = "[ %s ]" % title
	if is_instance_valid(hud_banner_desc):
		hud_banner_desc.text = desc

func _show_victory_dialog() -> void:
	SoundManager.play_victory_music()
	_clear_all_markers()
	if is_instance_valid(hud_banner):
		hud_banner.visible = false
		
	var hud = main_ref.hud_node if is_instance_valid(main_ref) and "hud_node" in main_ref else null
	if not hud: return
	
	victory_dialog = PanelContainer.new()
	victory_dialog.name = "TutorialVictoryDialog"
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color8(10, 12, 18, 250)
	sb.border_color = Color8(255, 215, 50)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(8)
	victory_dialog.add_theme_stylebox_override("panel", sb)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_bottom", 28)
	victory_dialog.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "[ FOUNDRY MASTER: TUTORIAL COMPLETE! ]"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color8(255, 215, 60))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var body = RichTextLabel.new()
	body.bbcode_enabled = true
	body.custom_minimum_size = Vector2(650, 160)
	body.text = "[center][font_size=20]You have mastered all essential crucible defense systems:\n\n" + \
		"[color=#50eb78]* Movement & Auto-Targeting[/color]  |  [color=#ffd700]* Smelting Bones & Coin Forge[/color]\n" + \
		"[color=#38c8ff]* Water Cooling (Anti-Meltdown)[/color]  |  [color=#ff5555]* Target Lock-On [Q][/color]\n" + \
		"[color=#ff7828]* Dash Mobility [SPACE][/color]  |  [color=#a064ff]* Active Skills & Deployable Turrets [T][/color]\n\n" + \
		"[color=#ffffff]Select your challenge rating and conquer the horde![/color][/font_size][/center]"
	vbox.add_child(body)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 24)
	vbox.add_child(hbox)
	
	var start_run_btn = Button.new()
	start_run_btn.custom_minimum_size = Vector2(280, 52)
	start_run_btn.text = "START SURVIVAL RUN >>"
	start_run_btn.add_theme_font_size_override("font_size", 22)
	_style_dialog_button(start_run_btn, Color8(44, 245, 120), Color8(15, 45, 25))
	start_run_btn.pressed.connect(func():
		stop_tutorial()
		emit_signal("tutorial_completed")
	)
	hbox.add_child(start_run_btn)
	
	var menu_btn = Button.new()
	menu_btn.custom_minimum_size = Vector2(240, 52)
	menu_btn.text = "RETURN TO MENU"
	menu_btn.add_theme_font_size_override("font_size", 22)
	_style_dialog_button(menu_btn, Color8(55, 200, 255), Color8(18, 38, 55))
	menu_btn.pressed.connect(func():
		stop_tutorial()
		emit_signal("return_to_menu_requested")
	)
	hbox.add_child(menu_btn)
	
	hud.get_node("Root").add_child(victory_dialog)
	victory_dialog.anchor_left = 0.5
	victory_dialog.anchor_right = 0.5
	victory_dialog.anchor_top = 0.5
	victory_dialog.anchor_bottom = 0.5
	victory_dialog.offset_left = -380
	victory_dialog.offset_right = 380
	victory_dialog.offset_top = -180
	victory_dialog.offset_bottom = 180

func _style_dialog_button(btn: Button, border_col: Color, bg_col: Color) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("focus", sb)

# --- MARKER HELPERS ---

func _create_marker_at_pos(pos: Vector2, text: String, color: Color, offset_y: float = -40.0) -> Node2D:
	var m = MARKER_SCRIPT.new()
	add_child(m)
	m.setup_target_position(pos, text, color, offset_y)
	active_markers.append(m)
	return m

func _create_marker_on_node(node: Node2D, text: String, color: Color, offset_y: float = -60.0) -> Node2D:
	var m = MARKER_SCRIPT.new()
	add_child(m)
	m.setup_target_node(node, text, color, offset_y)
	active_markers.append(m)
	return m

func _clear_all_markers() -> void:
	for m in active_markers:
		if is_instance_valid(m):
			m.queue_free()
	active_markers.clear()
