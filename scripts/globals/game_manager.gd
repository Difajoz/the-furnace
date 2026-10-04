# game_manager.gd - Central State, Progression, Stats, Economy, and Event Dispatcher
extends Node

enum GameState {
	MENU,
	PLAYING,
	WAVE_CLEARED,
	SHOP,
	GAME_OVER,
	VICTORY,
	PAUSED
}

enum Difficulty {
	EASY,
	NORMAL,
	HARD
}

signal state_changed(new_state: GameState)
signal coins_changed(amount: int, delta: int)
signal bones_changed(bones: int)
signal wave_started(wave_num: int)
signal wave_time_updated(time_remaining: float, total_time: float)
signal wave_cleared(wave_num: int)
signal player_hp_changed(current: float, max_val: float)
signal player_water_changed(current: float, max_val: float)
signal weapons_updated()
signal game_ended(is_victory: bool, stats: Dictionary)
signal furnace_status_updated(temp: float, max_temp: float, state_name: String, multiplier: float)
signal screen_shake_requested(intensity: float, duration: float)
signal show_damage_number(pos: Vector2, text: String, color: Color, is_crit: bool)
signal level_up_ready(level: int)
signal xp_changed(current: int, max_val: int, level: int)
signal target_lock_changed(target: Node2D)
signal active_skills_updated()
signal combo_updated(combo_count: int, multiplier: float, is_active: bool, time_left: float, max_time: float)
signal turret_inventory_updated()
signal placement_mode_toggled(active: bool)

# Difficulty & Mode Settings
var selected_difficulty: Difficulty = Difficulty.NORMAL
var is_tutorial: bool = false

# Turret Defense System
var turret_inventory: Array[Dictionary] = []
var placed_turrets_data: Array[Dictionary] = []

# Current run status
var current_state: GameState = GameState.MENU
var current_wave: int = 1
var max_waves: int = 20
var wave_timer: float = 0.0
var wave_duration: float = 45.0
var is_wave_running: bool = false

# Target Lock-On Feature
var locked_target: Node2D = null

# Combo Kill System
var current_combo: int = 0
var max_combo: int = 0
var combo_timer: float = 0.0
const COMBO_MAX_TIME: float = 3.8

# High Scores & Records Persistence
const SAVE_PATH = "user://high_scores.json"
const SAVE_RUN_PATH = "user://saved_run.json"
var high_scores: Dictionary = {
	"best_wave": 1,
	"most_kills": 0,
	"most_coins": 40,
	"best_combo": 0,
	"best_time": 0.0,
	"total_runs": 0,
	"total_victories": 0
}

# Active Skills System
var active_skills: Array[Dictionary] = []
var active_damage_boost_timer: float = 0.0
var active_shield_timer: float = 0.0

# Player Level & XP Progression
var player_level: int = 1
var current_xp: int = 0
var xp_to_next_level: int = 40
var pending_level_ups: int = 0

# Economy
var coins: int = 40 # Starting bonus coins for initial loadout
var bones_held: int = 0
var max_bones_held: int = 10 # Base maximum carrying capacity reduced to 10
var total_bones_collected: int = 0
var total_bones_processed: int = 0
var total_coins_earned: int = 40
var total_zombies_killed: int = 0
var max_temp_reached: float = 0.0
var overheat_count: int = 0
var run_time_elapsed: float = 0.0
var is_in_furnace_zone: bool = false # Proximity to furnace where HP regen is disabled

# Player runtime & base stats
var max_hp: float = 100.0
var current_hp: float = 100.0
var hp_regen: float = 0.0
var move_speed_base: float = 230.0
var move_speed_mult: float = 1.0
var damage_mult: float = 1.0
var attack_speed_mult: float = 1.0
var crit_chance: float = 0.05
var crit_mult: float = 1.5
var armor: float = 0.0
var lifesteal: float = 0.0
var pickup_radius_base: float = 130.0
var pickup_radius_mult: float = 1.0
var luck: float = 0.0
var max_water: float = 50.0
var current_water: float = 50.0
var water_regen_rate: float = 6.0
var cooling_efficiency: float = 1.0
var spray_range_mult: float = 1.0
var heat_frenzy_bonus: float = 0.0
var dash_cooldown_mult: float = 1.0

# Inventory
const MAX_WEAPONS = 6
var max_weapon_slots: int = 3
var equipped_weapons: Array[Dictionary] = []
var owned_skills: Array[Dictionary] = []
var owned_furnace_upgrades: Array[Dictionary] = []
var owned_abilities: Array[Dictionary] = []

# Furnace Upgrades aggregated stats
var furnace_max_bones: int = 50
var furnace_process_speed_mult: float = 1.0
var furnace_coin_yield_mult: float = 1.0
var furnace_heat_per_bone_mult: float = 1.0
var furnace_max_temp_bonus: float = 0.0
var furnace_cooling_absorption_mult: float = 1.0
var furnace_emergency_cool_charges: int = 0
var furnace_critical_multiplier_bonus: float = 0.0
var furnace_steam_blast_unlocked: bool = false

# Nodes references
var player_node: Node2D = null
var furnace_node: Node2D = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_high_scores()

var last_emitted_wave_sec: int = -1
var last_emitted_hp_int: int = -1
var last_emitted_water_int: int = -1

func _process(delta: float) -> void:
	if get_tree().paused:
		return
		
	# Check locked target validity
	if is_instance_valid(locked_target):
		if locked_target.is_queued_for_deletion():
			locked_target = null
			emit_signal("target_lock_changed", null)
	elif locked_target != null:
		locked_target = null
		emit_signal("target_lock_changed", null)
		
	# Combo system decay timer
	if current_combo > 0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			current_combo = 0
			combo_timer = 0.0
			emit_signal("combo_updated", 0, 1.0, false, 0.0, COMBO_MAX_TIME)
		else:
			emit_signal("combo_updated", current_combo, get_combo_gold_mult(), true, combo_timer, COMBO_MAX_TIME)
		
	# Active skill timers
	if active_damage_boost_timer > 0.0:
		active_damage_boost_timer = max(0.0, active_damage_boost_timer - delta)
	if active_shield_timer > 0.0:
		active_shield_timer = max(0.0, active_shield_timer - delta)
		
	for s in active_skills:
		if s.get("active_timer", 0.0) > 0.0:
			s["active_timer"] = max(0.0, s["active_timer"] - delta)
		if s.get("cooldown_timer", 0.0) > 0.0:
			s["cooldown_timer"] = max(0.0, s["cooldown_timer"] - delta)
		
	if current_state == GameState.PLAYING and is_wave_running:
		run_time_elapsed += delta
		wave_timer -= delta
		
		var cur_sec = int(max(0.0, wave_timer))
		if cur_sec != last_emitted_wave_sec:
			last_emitted_wave_sec = cur_sec
			emit_signal("wave_time_updated", max(0.0, wave_timer), wave_duration)
		
		# Check Furnace Zone (within 200px of furnace)
		if is_instance_valid(player_node) and is_instance_valid(furnace_node):
			var dist_f_sq = player_node.global_position.distance_squared_to(furnace_node.global_position)
			is_in_furnace_zone = (dist_f_sq <= 40000.0)
		else:
			is_in_furnace_zone = false
		
		# Passive HP regen - STRICTLY DISABLED in Furnace Area!
		if hp_regen > 0.0 and current_hp < max_hp and not is_in_furnace_zone:
			heal_player(hp_regen * delta)
			
		# Water recharge
		if current_water < max_water:
			current_water = min(max_water, current_water + water_regen_rate * delta)
			var w_int = int(current_water)
			if w_int != last_emitted_water_int:
				last_emitted_water_int = w_int
				emit_signal("player_water_changed", current_water, max_water)
			
		if wave_timer <= 0.0:
			end_wave()

func get_difficulty_name(diff: int = -1) -> String:
	var d = selected_difficulty if diff < 0 else diff
	match d:
		Difficulty.EASY: return "EASY"
		Difficulty.NORMAL: return "NORMAL"
		Difficulty.HARD: return "HARD"
	return "NORMAL"

func get_difficulty_color(diff: int = -1) -> Color:
	var d = selected_difficulty if diff < 0 else diff
	match d:
		Difficulty.EASY: return Color8(80, 235, 120)
		Difficulty.NORMAL: return Color8(255, 205, 50)
		Difficulty.HARD: return Color8(255, 75, 75)
	return Color.WHITE

func get_difficulty_desc(diff: int = -1) -> String:
	var d = selected_difficulty if diff < 0 else diff
	match d:
		Difficulty.EASY:
			return "Relaxed crypt pace. Forgiving monster damage (-30%), lower enemy HP (-25%), slower horde density, and gentle crucible heat. Ideal for learning."
		Difficulty.NORMAL:
			return "The standard tactical foundry experience. Balanced spawns, escalating boss encounters, and strategic crucible management."
		Difficulty.HARD:
			return "Crypt Nightmare! Relentless swarming hordes (+25%), lethal damage (+35%), tankier monsters (+30%), rapid crucible heat, but +20% bonus gold!"
	return ""

func get_difficulty_enemy_hp_mult() -> float:
	if is_tutorial: return 0.50
	match selected_difficulty:
		Difficulty.EASY: return 0.75
		Difficulty.NORMAL: return 1.00
		Difficulty.HARD: return 1.30
	return 1.0

func get_difficulty_enemy_dmg_mult() -> float:
	if is_tutorial: return 0.40
	match selected_difficulty:
		Difficulty.EASY: return 0.70
		Difficulty.NORMAL: return 1.00
		Difficulty.HARD: return 1.35
	return 1.0

func get_difficulty_density_mult() -> float:
	if is_tutorial: return 0.40
	match selected_difficulty:
		Difficulty.EASY: return 0.80
		Difficulty.NORMAL: return 1.00
		Difficulty.HARD: return 1.25
	return 1.0

func get_difficulty_boss_hp_mult() -> float:
	if is_tutorial: return 0.50
	match selected_difficulty:
		Difficulty.EASY: return 0.75
		Difficulty.NORMAL: return 1.00
		Difficulty.HARD: return 1.35
	return 1.0

func get_difficulty_furnace_heat_mult() -> float:
	if is_tutorial: return 0.60
	match selected_difficulty:
		Difficulty.EASY: return 0.80
		Difficulty.NORMAL: return 1.00
		Difficulty.HARD: return 1.15
	return 1.0

func get_difficulty_gold_reward_mult() -> float:
	match selected_difficulty:
		Difficulty.EASY: return 1.00
		Difficulty.NORMAL: return 1.00
		Difficulty.HARD: return 1.20
	return 1.0

func get_effective_damage_mult() -> float:
	var mult = damage_mult
	if active_damage_boost_timer > 0.0:
		mult *= 2.0
	return mult

func get_combo_gold_mult() -> float:
	if current_combo <= 1:
		return 1.0
	# +1.5% bonus gold yield per combo count above 1, capped at +60% max (1.60x)
	return min(1.60, 1.0 + float(current_combo) * 0.015)

func add_combo(amount: int = 1, kill_pos: Vector2 = Vector2.ZERO) -> void:
	if current_state != GameState.PLAYING:
		return
	current_combo += amount
	combo_timer = COMBO_MAX_TIME
	if current_combo > max_combo:
		max_combo = current_combo
	total_zombies_killed += amount
	
	var mult = get_combo_gold_mult()
	emit_signal("combo_updated", current_combo, mult, true, combo_timer, COMBO_MAX_TIME)
	
	# Pitch-shifting audio reward on kill streaks
	var pitch_boost = clamp(float(current_combo) * 0.03, 0.0, 3.5)
	SoundManager.play_sfx("coin_pickup", 0.04, pitch_boost)
	
	# Show juicy combo milestone popups
	if current_combo == 5 or current_combo == 10 or current_combo == 15 or current_combo == 20 or current_combo == 30 or current_combo == 50 or (current_combo > 10 and current_combo % 10 == 0):
		var combo_color = Color8(255, 230, 70) # Gold
		if current_combo >= 50:
			combo_color = Color8(255, 90, 240) # Neon Magenta
		elif current_combo >= 25:
			combo_color = Color8(255, 120, 30) # Flaming Orange
		elif current_combo >= 10:
			combo_color = Color8(80, 220, 255) # Electric Cyan
			
		var popup_pos = kill_pos if kill_pos != Vector2.ZERO else (player_node.global_position if is_instance_valid(player_node) else Vector2.ZERO)
		emit_signal("show_damage_number", popup_pos + Vector2(randf_range(-15, 15), -45), "%d COMBO! (+%.0f%% G)" % [current_combo, (mult - 1.0) * 100.0], combo_color, true)
		if current_combo >= 15:
			emit_signal("screen_shake_requested", 3.0, 0.12)
			SoundManager.play_sfx("level_up", 0.1, 4.0)

func reset_combo_on_damage() -> void:
	if current_combo > 0:
		var lost = current_combo
		current_combo = 0
		combo_timer = 0.0
		emit_signal("combo_updated", 0, 1.0, false, 0.0, COMBO_MAX_TIME)
		if lost >= 5 and is_instance_valid(player_node):
			emit_signal("show_damage_number", player_node.global_position + Vector2(0, -50), "COMBO LOST! (%d)" % lost, Color8(255, 75, 75), true)

func load_high_scores() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(json_str) == OK and json.data is Dictionary:
			for k in json.data.keys():
				high_scores[k] = json.data[k]

func save_high_scores() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(high_scores, "\t"))
		file.close()

func check_and_update_high_scores(stats: Dictionary) -> Dictionary:
	var new_records = {}
	var w = stats.get("wave_reached", 1)
	var k = stats.get("zombies_killed", 0)
	var g = stats.get("total_coins", 0)
	var c = stats.get("max_combo", 0)
	var t = stats.get("run_time", 0.0)
	
	high_scores["total_runs"] = high_scores.get("total_runs", 0) + 1
	if stats.get("is_victory", false):
		high_scores["total_victories"] = high_scores.get("total_victories", 0) + 1
		
	if w > high_scores.get("best_wave", 1):
		high_scores["best_wave"] = w
		new_records["best_wave"] = true
	if k > high_scores.get("most_kills", 0):
		high_scores["most_kills"] = k
		new_records["most_kills"] = true
	if g > high_scores.get("most_coins", 0):
		high_scores["most_coins"] = g
		new_records["most_coins"] = true
	if c > high_scores.get("best_combo", 0):
		high_scores["best_combo"] = c
		new_records["best_combo"] = true
		
	save_high_scores()
	return new_records

func lock_target(target: Node2D) -> void:
	if is_instance_valid(target) and not target.is_queued_for_deletion():
		locked_target = target
		emit_signal("target_lock_changed", locked_target)
		SoundManager.play_sfx("shoot_shuriken", 0.1, 4.0)

func unlock_target() -> void:
	if locked_target != null:
		locked_target = null
		emit_signal("target_lock_changed", null)
		SoundManager.play_sfx("button_click", 0.1, 2.0)

func add_active_skill(skill_data: Dictionary) -> bool:
	if active_skills.size() >= 3:
		return false
	var s_copy = skill_data.duplicate(true)
	s_copy["active_timer"] = 0.0
	s_copy["cooldown_timer"] = 0.0
	var key_names = ["1", "2", "3"]
	var slot_idx = active_skills.size()
	s_copy["key_name"] = key_names[min(slot_idx, 2)]
	active_skills.append(s_copy)
	emit_signal("active_skills_updated")
	return true

func activate_skill(slot_index: int) -> bool:
	if current_state != GameState.PLAYING:
		return false
	if slot_index < 0 or slot_index >= active_skills.size():
		return false
	var s = active_skills[slot_index]
	if s.get("cooldown_timer", 0.0) > 0.0 or s.get("active_timer", 0.0) > 0.0:
		return false
		
	var id = s.get("id", "")
	var dur = s.get("duration", 0.0)
	var cd = s.get("cooldown", 20.0)
	
	s["active_timer"] = dur
	s["cooldown_timer"] = cd
	
	match id:
		"active_damage_boost":
			active_damage_boost_timer = dur
			SoundManager.play_sfx("level_up", 0.2, 3.0)
			emit_signal("screen_shake_requested", 6.0, 0.25)
			if is_instance_valid(player_node):
				emit_signal("show_damage_number", player_node.global_position + Vector2(0, -40), "DMG BOOST!", Color8(255, 100, 30), true)
		"active_shield":
			active_shield_timer = dur
			SoundManager.play_sfx("steam_hiss", 0.2, 5.0)
			emit_signal("screen_shake_requested", 5.0, 0.2)
			if is_instance_valid(player_node):
				emit_signal("show_damage_number", player_node.global_position + Vector2(0, -40), "SHIELD UP!", Color8(60, 220, 255), true)
		"active_frost_nova":
			SoundManager.play_sfx("steam_hiss", 0.2, 3.0)
			emit_signal("screen_shake_requested", 8.0, 0.35)
			if is_instance_valid(player_node):
				emit_signal("show_damage_number", player_node.global_position + Vector2(0, -40), "FROST NOVA!", Color8(100, 220, 255), true)
				var enemies = get_tree().get_nodes_in_group("enemies")
				for e in enemies:
					if is_instance_valid(e) and not e.is_queued_for_deletion():
						var dist = player_node.global_position.distance_to(e.global_position)
						if dist <= 420.0:
							if e.has_method("apply_slow"):
								e.apply_slow(0.80, 5.0)
							if e.has_method("take_damage"):
								e.take_damage(40.0 * damage_mult, false, "freeze")
	emit_signal("active_skills_updated")
	return true

func start_new_run(diff: int = -1) -> void:
	if diff >= 0:
		selected_difficulty = diff as Difficulty
	is_tutorial = false
	current_wave = 1
	wave_timer = 0.0
	is_wave_running = false
	coins = 40
	bones_held = 0
	max_bones_held = 10
	is_in_furnace_zone = false
	total_bones_collected = 0
	total_bones_processed = 0
	total_coins_earned = 40
	total_zombies_killed = 0
	max_temp_reached = 0.0
	overheat_count = 0
	run_time_elapsed = 0.0
	current_combo = 0
	max_combo = 0
	combo_timer = 0.0
	emit_signal("combo_updated", 0, 1.0, false, 0.0, COMBO_MAX_TIME)
	
	dash_cooldown_mult = 1.0
	locked_target = null
	active_skills.clear()
	active_damage_boost_timer = 0.0
	active_shield_timer = 0.0
	last_emitted_wave_sec = -1
	last_emitted_hp_int = -1
	last_emitted_water_int = -1
	
	SoundManager.reset_audio_state()
	
	# Reset Level Progression
	player_level = 1
	current_xp = 0
	xp_to_next_level = 40
	pending_level_ups = 0
	
	# Reset stats
	max_hp = 100.0
	current_hp = 100.0
	hp_regen = 0.0
	move_speed_base = 230.0
	move_speed_mult = 1.0
	damage_mult = 1.0
	attack_speed_mult = 1.0
	crit_chance = 0.05
	crit_mult = 1.5
	armor = 0.0
	lifesteal = 0.0
	pickup_radius_base = 130.0
	pickup_radius_mult = 1.0
	luck = 0.0
	max_water = 50.0
	current_water = 50.0
	water_regen_rate = 6.0
	cooling_efficiency = 1.0
	spray_range_mult = 1.0
	heat_frenzy_bonus = 0.0
	
	# Reset inventory
	max_weapon_slots = 3
	equipped_weapons.clear()
	owned_skills.clear()
	owned_furnace_upgrades.clear()
	owned_abilities.clear()
	turret_inventory.clear()
	placed_turrets_data.clear()
	emit_signal("turret_inventory_updated")
	
	# Reset furnace stats
	furnace_max_bones = 50
	furnace_process_speed_mult = 1.0
	furnace_coin_yield_mult = 1.0
	furnace_heat_per_bone_mult = 1.0
	furnace_max_temp_bonus = 0.0
	furnace_cooling_absorption_mult = 1.0
	furnace_emergency_cool_charges = 0
	furnace_critical_multiplier_bonus = 0.0
	furnace_steam_blast_unlocked = false
	
	# Reset Physical Furnace Node if present
	if is_instance_valid(furnace_node) and furnace_node.has_method("reset_furnace"):
		furnace_node.reset_furnace()
	
	# Give starter weapon (Kinetic Pistol)
	var starter_pistol = ItemDatabase.get_item("pistol").duplicate(true)
	equipped_weapons.append(starter_pistol)
	
	# Give starter ability (Dash)
	var starter_dash = ItemDatabase.get_item("dash").duplicate(true)
	owned_abilities.append(starter_dash)
	
	emit_signal("coins_changed", coins, 0)
	emit_signal("bones_changed", bones_held)
	emit_signal("weapons_updated")
	emit_signal("player_hp_changed", current_hp, max_hp)
	emit_signal("player_water_changed", current_water, max_water)
	emit_signal("xp_changed", current_xp, xp_to_next_level, player_level)
	emit_signal("target_lock_changed", null)
	emit_signal("active_skills_updated")

func reset_game() -> void:
	start_new_run()

func add_xp(amount: int) -> void:
	if amount <= 0: return
	current_xp += amount
	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		player_level += 1
		xp_to_next_level = int(40 * pow(1.22, player_level))
		pending_level_ups += 1
		SoundManager.play_sfx("level_up", 0.0, -2.0)
		emit_signal("level_up_ready", player_level)
	emit_signal("xp_changed", current_xp, xp_to_next_level, player_level)

func apply_attribute_upgrade(upgrade: Dictionary) -> void:
	var stat = upgrade.get("stat", "")
	var val = upgrade.get("value", 0.0)
	var is_furnace = upgrade.get("is_furnace", false)
	
	if is_furnace:
		_modify_furnace_stat(stat, val)
	else:
		_modify_stat(stat, val)
		
	# Apply secondary advantage if present
	if upgrade.has("stat2"):
		if upgrade.get("is_furnace2", is_furnace):
			_modify_furnace_stat(upgrade.get("stat2"), upgrade.get("value2", 0.0))
		else:
			_modify_stat(upgrade.get("stat2"), upgrade.get("value2", 0.0))
			
	# Apply disadvantage / drawback effect if present
	if upgrade.has("drawback_stat"):
		var db_stat = upgrade.get("drawback_stat", "")
		var db_val = upgrade.get("drawback_value", 0.0)
		var is_db_furnace = upgrade.get("is_drawback_furnace", false)
		if is_db_furnace:
			_modify_furnace_stat(db_stat, db_val)
		else:
			_modify_stat(db_stat, db_val)
			
	if is_instance_valid(furnace_node) and furnace_node.has_method("_update_stats_from_manager"):
		furnace_node._update_stats_from_manager()
			
	SoundManager.play_sfx("buy_item", 0.2)

func start_wave() -> void:
	current_state = GameState.PLAYING
	emit_signal("state_changed", current_state)
	
	# Reset Health & Water to full at the start of every wave
	current_hp = max_hp
	current_water = max_water
	emit_signal("player_hp_changed", current_hp, max_hp)
	emit_signal("player_water_changed", current_water, max_water)
	
	# Clear status effects on player when starting new wave
	if is_instance_valid(player_node) and player_node.has_method("clear_status_effects"):
		player_node.clear_status_effects()
	
	wave_duration = 35.0 + (current_wave * 2.0)
	wave_timer = wave_duration
	is_wave_running = true
	
	SoundManager.play_sfx("wave_start")
	emit_signal("wave_started", current_wave)
	emit_signal("wave_time_updated", wave_timer, wave_duration)

func end_wave() -> void:
	is_wave_running = false
	unlock_target()
	
	# Clear status effects on wave completion
	if is_instance_valid(player_node) and player_node.has_method("clear_status_effects"):
		player_node.clear_status_effects()
		
	SoundManager.play_sfx("wave_clear")
	
	if current_wave >= max_waves:
		trigger_victory()
		return
		
	var cleared_wave = current_wave
	current_wave += 1
	emit_signal("wave_cleared", cleared_wave)
	current_state = GameState.SHOP
	emit_signal("state_changed", current_state)

func advance_to_next_wave() -> void:
	start_wave()

func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	coins += amount
	total_coins_earned += amount
	emit_signal("coins_changed", coins, amount)
	SoundManager.play_sfx("coin_pickup", 0.15)

func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		emit_signal("coins_changed", coins, -amount)
		return true
	return false

func can_pickup_bone() -> bool:
	return bones_held < max_bones_held

func add_bones(amount: int) -> int:
	var space = max_bones_held - bones_held
	if space <= 0:
		return 0
	var to_add = min(space, amount)
	bones_held += to_add
	total_bones_collected += to_add
	emit_signal("bones_changed", bones_held)
	SoundManager.play_sfx("bone_pickup", 0.1)
	return to_add

func remove_bones(amount: int) -> int:
	var to_remove = min(bones_held, amount)
	bones_held -= to_remove
	emit_signal("bones_changed", bones_held)
	return to_remove

func damage_player(raw_damage: float) -> void:
	if current_state != GameState.PLAYING:
		return
	if active_shield_timer > 0.0:
		# Active Aegis Shield is protecting the player!
		return
	if is_instance_valid(player_node):
		if player_node.is_invulnerable or player_node.invulnerability_timer > 0.0 or player_node.is_dashing:
			return
		player_node.invulnerability_timer = 0.35
		
	var net_damage = max(1.0, raw_damage - armor)
	current_hp = max(0.0, current_hp - net_damage)
	
	reset_combo_on_damage()
	
	emit_signal("player_hp_changed", current_hp, max_hp)
	emit_signal("screen_shake_requested", 6.0, 0.2)
	SoundManager.play_sfx("player_hit")
	
	if player_node:
		emit_signal("show_damage_number", player_node.global_position + Vector2(randf_range(-15, 15), -20), "-%d" % int(net_damage), Color(1.0, 0.2, 0.2), false)
		
	if current_hp <= 0.0:
		trigger_game_over()

func heal_player(amount: float) -> void:
	if amount <= 0: return
	var prev_int = int(current_hp)
	current_hp = min(max_hp, current_hp + amount)
	var cur_int = int(current_hp)
	if cur_int != prev_int or amount >= 1.0:
		emit_signal("player_hp_changed", current_hp, max_hp)
		if amount >= 1.0 and player_node:
			emit_signal("show_damage_number", player_node.global_position + Vector2(0, -25), "+%d" % int(amount), Color(0.2, 1.0, 0.3), false)

func consume_water(amount: float) -> bool:
	if current_water >= amount:
		var prev_int = int(current_water)
		current_water = max(0.0, current_water - amount)
		var cur_int = int(current_water)
		if cur_int != prev_int:
			emit_signal("player_water_changed", current_water, max_water)
		return true
	return false

func buy_item(item_data: Dictionary) -> bool:
	var cost = item_data.get("cost", 10)
	if not spend_coins(cost):
		return false
		
	SoundManager.play_sfx("buy_item")
	var type = item_data.get("type", "")
	
	match type:
		"weapon":
			var is_up = item_data.get("is_weapon_upgrade", false)
			var base_id = item_data.get("base_weapon_id", item_data.get("id", ""))
			var upgraded_in_place = false
			if is_up:
				for i in range(equipped_weapons.size()):
					var eq = equipped_weapons[i]
					var eq_base = eq.get("base_weapon_id", eq.get("id", ""))
					if eq_base == base_id:
						equipped_weapons[i] = item_data.duplicate(true)
						upgraded_in_place = true
						emit_signal("weapons_updated")
						break
			if not upgraded_in_place:
				if equipped_weapons.size() < max_weapon_slots:
					equipped_weapons.append(item_data.duplicate(true))
					emit_signal("weapons_updated")
				else:
					# Inventory full for current unlocked slots, check if mergeable or refund
					var merged = try_merge_weapon(item_data)
					if not merged:
						add_coins(cost) # Refund
						return false
		"skill":
			owned_skills.append(item_data.duplicate(true))
			_apply_skill_stat(item_data)
		"furnace":
			owned_furnace_upgrades.append(item_data.duplicate(true))
			_apply_furnace_stat(item_data)
		"ability":
			owned_abilities.append(item_data.duplicate(true))
		"active_skill":
			return add_active_skill(item_data)
		"turret":
			turret_inventory.append(item_data.duplicate(true))
			emit_signal("turret_inventory_updated")
			return true
		"weapon_slot":
			if max_weapon_slots < MAX_WEAPONS:
				max_weapon_slots = min(MAX_WEAPONS, max_weapon_slots + 1)
				emit_signal("weapons_updated")
				SoundManager.play_sfx("level_up")
				return true
			else:
				add_coins(cost)
				return false
			
	return true

func record_placed_turret(turret_type: String, pos: Vector2) -> void:
	placed_turrets_data.append({
		"turret_type": turret_type,
		"x": pos.x,
		"y": pos.y
	})

func consume_turret_from_inventory() -> Dictionary:
	if turret_inventory.is_empty():
		return {}
	var item = turret_inventory.pop_front()
	emit_signal("turret_inventory_updated")
	return item

func get_next_weapon_slot_cost() -> int:
	match max_weapon_slots:
		3: return 70
		4: return 140
		5: return 210
		_: return -1

func buy_weapon_slot() -> bool:
	var cost = get_next_weapon_slot_cost()
	if cost > 0 and spend_coins(cost):
		max_weapon_slots = min(MAX_WEAPONS, max_weapon_slots + 1)
		emit_signal("weapons_updated")
		SoundManager.play_sfx("level_up")
		return true
	return false

func try_merge_weapon(new_weapon: Dictionary) -> bool:
	var weapon_id = new_weapon.get("id", "")
	var weapon_tier = new_weapon.get("tier", ItemDatabase.TIER_COMMON)
	
	# Find identical tier weapon in equipped list
	for i in range(equipped_weapons.size()):
		var eq = equipped_weapons[i]
		if eq.get("id") == weapon_id and eq.get("tier") == weapon_tier:
			# Merge! Upgrade tier
			if weapon_tier < ItemDatabase.TIER_LEGENDARY:
				eq["tier"] += 1
				eq["damage"] = eq.get("damage", 10.0) * 1.35
				eq["fire_rate"] = eq.get("fire_rate", 1.0) * 1.15
				eq["crit_chance"] = eq.get("crit_chance", 0.05) + 0.05
				emit_signal("weapons_updated")
				SoundManager.play_sfx("level_up")
				return true
	return false

func sell_weapon(index: int) -> void:
	if index >= 0 and index < equipped_weapons.size():
		var w = equipped_weapons[index]
		var cost = w.get("cost", 20)
		var refund = int(cost * 0.7)
		equipped_weapons.remove_at(index)
		add_coins(refund)
		emit_signal("weapons_updated")
		SoundManager.play_sfx("button_click")

func _apply_skill_stat(item: Dictionary) -> void:
	var stat = item.get("stat", "")
	var val = item.get("value", 0.0)
	_modify_stat(stat, val)
	
	if item.has("stat2"):
		_modify_stat(item.get("stat2"), item.get("value2", 0.0))
		
	if item.has("drawback_stat"):
		_modify_stat(item.get("drawback_stat"), item.get("drawback_value", 0.0))

func _modify_stat(stat_name: String, val: float) -> void:
	match stat_name:
		"damage_mult": damage_mult = max(0.2, damage_mult + val)
		"attack_speed_mult": attack_speed_mult = max(0.25, attack_speed_mult + val)
		"crit_chance": crit_chance = max(0.0, crit_chance + val)
		"crit_mult": crit_mult = max(1.1, crit_mult + val)
		"move_speed_mult": move_speed_mult = max(0.35, move_speed_mult + val)
		"armor": armor += val
		"lifesteal": lifesteal = max(0.0, lifesteal + val)
		"pickup_radius_mult": pickup_radius_mult = max(0.3, pickup_radius_mult + val)
		"max_hp":
			max_hp = max(20.0, max_hp + val)
			current_hp = min(current_hp, max_hp)
			if val > 0:
				heal_player(val)
			emit_signal("player_hp_changed", current_hp, max_hp)
		"hp_regen": hp_regen = max(0.0, hp_regen + val)
		"luck": luck = max(-0.5, luck + val)
		"max_bones_held":
			max_bones_held = max(5, max_bones_held + int(val))
			emit_signal("bones_changed", bones_held)
		"max_water":
			max_water = max(15.0, max_water + val)
			current_water = min(current_water, max_water)
			emit_signal("player_water_changed", current_water, max_water)
		"spray_range_mult": spray_range_mult = max(0.4, spray_range_mult + val)
		"cooling_efficiency": cooling_efficiency = max(0.2, cooling_efficiency + val)
		"water_regen_rate": water_regen_rate = max(1.0, water_regen_rate * (1.0 + val))
		"heat_frenzy_bonus": heat_frenzy_bonus += val
		"dash_cooldown_mult": dash_cooldown_mult = max(0.2, dash_cooldown_mult + val)

func _apply_furnace_stat(item: Dictionary) -> void:
	var stat = item.get("furnace_stat", "")
	var val = item.get("value", 0.0)
	_modify_furnace_stat(stat, val)
	
	if item.has("furnace_stat2"):
		_modify_furnace_stat(item.get("furnace_stat2"), item.get("value2", 0.0))
		
	if item.has("drawback_furnace_stat"):
		_modify_furnace_stat(item.get("drawback_furnace_stat"), item.get("drawback_value", 0.0))
	elif item.has("drawback_stat"):
		_modify_stat(item.get("drawback_stat"), item.get("drawback_value", 0.0))
		
	if is_instance_valid(furnace_node) and furnace_node.has_method("_update_stats_from_manager"):
		furnace_node._update_stats_from_manager()

func _modify_furnace_stat(stat_name: String, val: float) -> void:
	match stat_name:
		"max_bone_capacity": furnace_max_bones = max(10, furnace_max_bones + int(val))
		"process_speed_mult": furnace_process_speed_mult = max(0.2, furnace_process_speed_mult + val)
		"coin_yield_mult": furnace_coin_yield_mult = max(0.2, furnace_coin_yield_mult + val)
		"heat_per_bone_mult": furnace_heat_per_bone_mult = max(0.2, furnace_heat_per_bone_mult + val)
		"max_temp_bonus": furnace_max_temp_bonus += val
		"cooling_absorption_mult": furnace_cooling_absorption_mult = max(0.2, furnace_cooling_absorption_mult + val)
		"emergency_cool_charges": furnace_emergency_cool_charges += int(val)
		"critical_multiplier_bonus": furnace_critical_multiplier_bonus += val
		"steam_blast_unlocked": furnace_steam_blast_unlocked = true

func get_run_stats() -> Dictionary:
	return {
		"wave_reached": current_wave,
		"total_coins": total_coins_earned,
		"bones_collected": total_bones_collected,
		"bones_processed": total_bones_processed,
		"zombies_killed": total_zombies_killed,
		"max_combo": max_combo,
		"combo_gold_bonus": int((get_combo_gold_mult() - 1.0) * 100.0),
		"max_temp": max_temp_reached,
		"overheats": overheat_count,
		"run_time": run_time_elapsed,
		"difficulty": get_difficulty_name(),
		"difficulty_color": get_difficulty_color(),
		"equipped_weapons": equipped_weapons.duplicate(true),
		"active_skills": active_skills.duplicate(true),
		"placed_turrets_count": placed_turrets_data.size()
	}

func trigger_game_over() -> void:
	current_state = GameState.GAME_OVER
	is_wave_running = false
	delete_saved_run()
	var stats = get_run_stats()
	stats["is_victory"] = false
	var new_records = check_and_update_high_scores(stats)
	stats["new_records"] = new_records
	emit_signal("state_changed", current_state)
	emit_signal("game_ended", false, stats)

func trigger_victory() -> void:
	current_state = GameState.VICTORY
	is_wave_running = false
	delete_saved_run()
	var stats = get_run_stats()
	stats["is_victory"] = true
	var new_records = check_and_update_high_scores(stats)
	stats["new_records"] = new_records
	emit_signal("state_changed", current_state)
	emit_signal("game_ended", true, stats)

func has_saved_run() -> bool:
	return FileAccess.file_exists(SAVE_RUN_PATH)

func get_saved_run_info() -> Dictionary:
	if not has_saved_run():
		return {}
	var file = FileAccess.open(SAVE_RUN_PATH, FileAccess.READ)
	if not file:
		return {}
	var text = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(text) == OK and json.data is Dictionary:
		return json.data
	return {}

func save_current_run(target_state: String = "") -> bool:
	if is_tutorial:
		return false
	var state_to_save = target_state
	if state_to_save == "":
		state_to_save = "SHOP" if current_state == GameState.SHOP else "PLAYING"
		
	var data: Dictionary = {
		"version": 1,
		"save_timestamp": Time.get_unix_time_from_system(),
		"selected_difficulty": int(selected_difficulty),
		"current_wave": current_wave,
		"saved_state": state_to_save,
		"run_time_elapsed": run_time_elapsed,
		"player_level": player_level,
		"current_xp": current_xp,
		"xp_to_next_level": xp_to_next_level,
		"pending_level_ups": pending_level_ups,
		"coins": coins,
		"bones_held": bones_held,
		"max_bones_held": max_bones_held,
		"total_bones_collected": total_bones_collected,
		"total_bones_processed": total_bones_processed,
		"total_coins_earned": total_coins_earned,
		"total_zombies_killed": total_zombies_killed,
		"max_temp_reached": max_temp_reached,
		"overheat_count": overheat_count,
		"max_combo": max_combo,
		"max_hp": max_hp,
		"current_hp": current_hp,
		"hp_regen": hp_regen,
		"move_speed_base": move_speed_base,
		"move_speed_mult": move_speed_mult,
		"damage_mult": damage_mult,
		"attack_speed_mult": attack_speed_mult,
		"crit_chance": crit_chance,
		"crit_mult": crit_mult,
		"armor": armor,
		"lifesteal": lifesteal,
		"pickup_radius_base": pickup_radius_base,
		"pickup_radius_mult": pickup_radius_mult,
		"luck": luck,
		"max_water": max_water,
		"current_water": current_water,
		"water_regen_rate": water_regen_rate,
		"cooling_efficiency": cooling_efficiency,
		"spray_range_mult": spray_range_mult,
		"heat_frenzy_bonus": heat_frenzy_bonus,
		"dash_cooldown_mult": dash_cooldown_mult,
		"max_weapon_slots": max_weapon_slots,
		"equipped_weapons": equipped_weapons,
		"owned_skills": owned_skills,
		"owned_furnace_upgrades": owned_furnace_upgrades,
		"owned_abilities": owned_abilities,
		"active_skills": active_skills,
		"furnace_max_bones": furnace_max_bones,
		"furnace_process_speed_mult": furnace_process_speed_mult,
		"furnace_coin_yield_mult": furnace_coin_yield_mult,
		"furnace_heat_per_bone_mult": furnace_heat_per_bone_mult,
		"furnace_max_temp_bonus": furnace_max_temp_bonus,
		"furnace_cooling_absorption_mult": furnace_cooling_absorption_mult,
		"furnace_emergency_cool_charges": furnace_emergency_cool_charges,
		"furnace_critical_multiplier_bonus": furnace_critical_multiplier_bonus,
		"furnace_steam_blast_unlocked": furnace_steam_blast_unlocked,
		"turret_inventory": turret_inventory,
		"placed_turrets_data": placed_turrets_data
	}
	
	var file = FileAccess.open(SAVE_RUN_PATH, FileAccess.WRITE)
	if not file:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true

func load_saved_run() -> bool:
	if not has_saved_run():
		return false
	var info = get_saved_run_info()
	if info.is_empty():
		return false
		
	is_tutorial = false
	selected_difficulty = int(info.get("selected_difficulty", Difficulty.NORMAL)) as Difficulty
	current_wave = int(info.get("current_wave", 1))
	run_time_elapsed = float(info.get("run_time_elapsed", 0.0))
	player_level = int(info.get("player_level", 1))
	current_xp = int(info.get("current_xp", 0))
	xp_to_next_level = int(info.get("xp_to_next_level", 40))
	pending_level_ups = int(info.get("pending_level_ups", 0))
	coins = int(info.get("coins", 40))
	bones_held = int(info.get("bones_held", 0))
	max_bones_held = int(info.get("max_bones_held", 10))
	total_bones_collected = int(info.get("total_bones_collected", 0))
	total_bones_processed = int(info.get("total_bones_processed", 0))
	total_coins_earned = int(info.get("total_coins_earned", 40))
	total_zombies_killed = int(info.get("total_zombies_killed", 0))
	max_temp_reached = float(info.get("max_temp_reached", 0.0))
	overheat_count = int(info.get("overheat_count", 0))
	max_combo = int(info.get("max_combo", 0))
	current_combo = 0
	combo_timer = 0.0
	
	max_hp = float(info.get("max_hp", 100.0))
	current_hp = float(info.get("current_hp", max_hp))
	hp_regen = float(info.get("hp_regen", 0.0))
	move_speed_base = float(info.get("move_speed_base", 230.0))
	move_speed_mult = float(info.get("move_speed_mult", 1.0))
	damage_mult = float(info.get("damage_mult", 1.0))
	attack_speed_mult = float(info.get("attack_speed_mult", 1.0))
	crit_chance = float(info.get("crit_chance", 0.05))
	crit_mult = float(info.get("crit_mult", 1.5))
	armor = float(info.get("armor", 0.0))
	lifesteal = float(info.get("lifesteal", 0.0))
	pickup_radius_base = float(info.get("pickup_radius_base", 130.0))
	pickup_radius_mult = float(info.get("pickup_radius_mult", 1.0))
	luck = float(info.get("luck", 0.0))
	max_water = float(info.get("max_water", 50.0))
	current_water = float(info.get("current_water", max_water))
	water_regen_rate = float(info.get("water_regen_rate", 6.0))
	cooling_efficiency = float(info.get("cooling_efficiency", 1.0))
	spray_range_mult = float(info.get("spray_range_mult", 1.0))
	heat_frenzy_bonus = float(info.get("heat_frenzy_bonus", 0.0))
	dash_cooldown_mult = float(info.get("dash_cooldown_mult", 1.0))
	
	max_weapon_slots = int(info.get("max_weapon_slots", 3))
	equipped_weapons.clear()
	for w in info.get("equipped_weapons", []):
		if w is Dictionary:
			equipped_weapons.append(w.duplicate(true))
			
	owned_skills.clear()
	for s in info.get("owned_skills", []):
		if s is Dictionary:
			owned_skills.append(s.duplicate(true))
			
	owned_furnace_upgrades.clear()
	for u in info.get("owned_furnace_upgrades", []):
		if u is Dictionary:
			owned_furnace_upgrades.append(u.duplicate(true))
			
	owned_abilities.clear()
	for a in info.get("owned_abilities", []):
		if a is Dictionary:
			owned_abilities.append(a.duplicate(true))
			
	active_skills.clear()
	for act in info.get("active_skills", []):
		if act is Dictionary:
			var act_c = act.duplicate(true)
			act_c["active_timer"] = 0.0
			act_c["cooldown_timer"] = 0.0
			active_skills.append(act_c)
			
	turret_inventory.clear()
	for t in info.get("turret_inventory", []):
		if t is Dictionary:
			turret_inventory.append(t.duplicate(true))
			
	placed_turrets_data.clear()
	for pt in info.get("placed_turrets_data", []):
		if pt is Dictionary:
			placed_turrets_data.append(pt.duplicate(true))
	emit_signal("turret_inventory_updated")
			
	furnace_max_bones = int(info.get("furnace_max_bones", 50))
	furnace_process_speed_mult = float(info.get("furnace_process_speed_mult", 1.0))
	furnace_coin_yield_mult = float(info.get("furnace_coin_yield_mult", 1.0))
	furnace_heat_per_bone_mult = float(info.get("furnace_heat_per_bone_mult", 1.0))
	furnace_max_temp_bonus = float(info.get("furnace_max_temp_bonus", 0.0))
	furnace_cooling_absorption_mult = float(info.get("furnace_cooling_absorption_mult", 1.0))
	furnace_emergency_cool_charges = int(info.get("furnace_emergency_cool_charges", 0))
	furnace_critical_multiplier_bonus = float(info.get("furnace_critical_multiplier_bonus", 0.0))
	furnace_steam_blast_unlocked = bool(info.get("furnace_steam_blast_unlocked", false))
	
	if is_instance_valid(furnace_node) and furnace_node.has_method("_update_stats_from_manager"):
		furnace_node._update_stats_from_manager()
		
	# Broadcast state updates
	emit_signal("coins_changed", coins, 0)
	emit_signal("bones_changed", bones_held)
	emit_signal("weapons_updated")
	emit_signal("player_hp_changed", current_hp, max_hp)
	emit_signal("player_water_changed", current_water, max_water)
	emit_signal("xp_changed", current_xp, xp_to_next_level, player_level)
	emit_signal("target_lock_changed", null)
	emit_signal("active_skills_updated")
	emit_signal("combo_updated", 0, 1.0, false, 0.0, COMBO_MAX_TIME)
	return true

func delete_saved_run() -> void:
	if has_saved_run():
		DirAccess.remove_absolute(SAVE_RUN_PATH)

func toggle_fullscreen() -> void:
	var mode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
