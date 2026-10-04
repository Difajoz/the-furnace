# furnace.gd - The Central Furnace Risk/Reward and Economy System
class_name Furnace
extends CharacterBody2D

signal furnace_fed(bones_added: int)
signal furnace_overheated()
signal furnace_cooled(amount: float)
signal coin_produced(amount: int, pos: Vector2)

enum FurnaceStage {
	LOW,
	MEDIUM,
	HIGH,
	CRITICAL,
	OVERHEATED
}

const COIN_PICKUP_SCRIPT = preload("res://scripts/pickups/coin_pickup.gd")
const UI_FONT: Font = preload("res://assets/Ultrapixel.ttf")

# Current Status
var current_stage: FurnaceStage = FurnaceStage.LOW
var temperature: float = 0.0
var max_temperature: float = 100.0
var bones_stored: int = 0
var max_bones: int = 50

# Timers & Processing
var process_timer: float = 0.0
var base_process_interval: float = 0.6
var feed_cooldown: float = 0.0
var overheat_timer: float = 0.0
var overheat_duration: float = 10.0
var is_overheated: bool = false
var emergency_charges_left: int = 0

# Meltdown & Explosion Animation State
var meltdown_active: bool = false
var meltdown_timer: float = 0.0
var meltdown_stage: int = 0
var is_blown_up: bool = false
var shockwaves: Array[Dictionary] = []
var shrapnel_particles: Array[Dictionary] = []

# Visuals & Animation
var visual_time: float = 0.0
var shake_offset: Vector2 = Vector2.ZERO
var steam_particles: Array[Dictionary] = []
var spark_particles: Array[Dictionary] = []
var smoke_particles: Array[Dictionary] = []

func _ready() -> void:
	GameManager.furnace_node = self
	add_to_group("furnace")
	_update_stats_from_manager()
	GameManager.wave_started.connect(_on_wave_started)

func reset_furnace() -> void:
	temperature = 0.0
	bones_stored = 0
	process_timer = 0.0
	feed_cooldown = 0.0
	overheat_timer = 0.0
	is_overheated = false
	meltdown_active = false
	meltdown_timer = 0.0
	meltdown_stage = 0
	is_blown_up = false
	shake_offset = Vector2.ZERO
	steam_particles.clear()
	spark_particles.clear()
	smoke_particles.clear()
	shockwaves.clear()
	shrapnel_particles.clear()
	_update_stats_from_manager()
	SoundManager.update_furnace_audio(0.0, false)
	queue_redraw()

func _update_stats_from_manager() -> void:
	max_bones = GameManager.furnace_max_bones
	max_temperature = 100.0 + GameManager.furnace_max_temp_bonus
	emergency_charges_left = GameManager.furnace_emergency_cool_charges

func _on_wave_started(_wave_num: int) -> void:
	_update_stats_from_manager()
	if is_overheated and not is_blown_up:
		is_overheated = false
		overheat_timer = 0.0

func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		if meltdown_active:
			_process_meltdown_animation(delta)
			_update_particles(delta)
			queue_redraw()
		else:
			SoundManager.update_furnace_audio(0.0, false)
		return
		
	visual_time += delta
	
	if meltdown_active:
		_process_meltdown_animation(delta)
	elif is_overheated:
		_process_overheated_state(delta)
	else:
		_process_normal_state(delta)
		
	_update_particles(delta)
	_update_stage()
	_update_audio_and_hud()
	queue_redraw()

func _process_meltdown_animation(delta: float) -> void:
	meltdown_timer += delta
	
	# Update Shockwaves
	var sw_i = shockwaves.size() - 1
	while sw_i >= 0:
		var sw = shockwaves[sw_i]
		sw["radius"] += sw["speed"] * delta
		sw["alpha"] = clamp(1.0 - (sw["radius"] / sw["max_radius"]), 0.0, 1.0)
		if sw["radius"] >= sw["max_radius"]:
			shockwaves.remove_at(sw_i)
		sw_i -= 1
		
	# Update Shrapnel Pieces
	var sh_i = shrapnel_particles.size() - 1
	while sh_i >= 0:
		var sh = shrapnel_particles[sh_i]
		sh["pos"] += sh["vel"] * delta
		sh["vel"] *= (1.0 - delta * 1.5)
		sh["rot"] += sh["rot_speed"] * delta
		sh["life"] -= delta
		if sh["life"] <= 0.0:
			shrapnel_particles.remove_at(sh_i)
		sh_i -= 1
		
	# Stage 1: Critical Meltdown Rumble & Sparks (< 0.75s)
	if meltdown_stage == 1:
		shake_offset = Vector2(randf_range(-14, 14), randf_range(-14, 14))
		_spawn_sparks(6, Color(1.0, 0.2, 0.1))
		_spawn_smoke(4)
		if meltdown_timer >= 0.75:
			# Stage 2: Cataclysmic Detonation!
			meltdown_stage = 2
			is_blown_up = true
			SoundManager.play_sfx("explosion", 0.0, 8.0)
			SoundManager.play_sfx("furnace_crash", 0.0, 8.0)
			GameManager.emit_signal("screen_shake_requested", 32.0, 1.6)
			
			# Create multiple shockwave rings
			shockwaves.append({"radius": 10.0, "max_radius": 480.0, "speed": 550.0, "alpha": 1.0, "color": Color8(255, 230, 80)})
			shockwaves.append({"radius": 5.0, "max_radius": 360.0, "speed": 400.0, "alpha": 1.0, "color": Color8(255, 80, 20)})
			shockwaves.append({"radius": 0.0, "max_radius": 240.0, "speed": 300.0, "alpha": 1.0, "color": Color8(200, 30, 10)})
			
			# Spawn 60 flying flaming shrapnel chunks
			for i in range(60):
				var ang = randf() * TAU
				var spd = randf_range(180.0, 500.0)
				shrapnel_particles.append({
					"pos": Vector2.ZERO,
					"vel": Vector2.from_angle(ang) * spd,
					"size": randf_range(8.0, 22.0),
					"rot": randf() * TAU,
					"rot_speed": randf_range(-8.0, 8.0),
					"color": Color8(45, 48, 55) if randf() < 0.6 else Color8(255, 120, 20),
					"life": randf_range(1.2, 2.0),
					"max_life": 2.0
				})
			_spawn_sparks(50, Color(1.0, 0.4, 0.1))
			_spawn_smoke(40)
			
	# Stage 3: After explosion concludes, trigger Game Over (at 2.4s)
	elif meltdown_stage == 2:
		shake_offset = Vector2(randf_range(-4, 4), randf_range(-4, 4)) * max(0.0, (2.4 - meltdown_timer))
		if meltdown_timer >= 2.4:
			meltdown_active = false
			GameManager.trigger_game_over()

func _process_normal_state(delta: float) -> void:
	# Natural cooling
	var natural_cool_rate = 1.2
	if bones_stored == 0:
		natural_cool_rate = 3.5 # Cools faster when idle
	temperature = max(0.0, temperature - natural_cool_rate * delta)
	
	# Process bones into coins
	if bones_stored > 0:
		var effective_interval = base_process_interval / max(0.1, GameManager.furnace_process_speed_mult)
		process_timer += delta
		if process_timer >= effective_interval:
			process_timer = 0.0
			_process_single_bone()
			
	# Update max temp stat achieved
	if temperature > GameManager.max_temp_reached:
		GameManager.max_temp_reached = temperature
		
	# Check for emergency valve trigger at 98%
	var temp_ratio = temperature / max_temperature
	if temp_ratio >= 0.98 and emergency_charges_left > 0:
		_trigger_emergency_cool()
	elif temperature >= max_temperature:
		_trigger_overheat()

func _process_overheated_state(delta: float) -> void:
	overheat_timer -= delta
	# Cool down rapidly during lockdown
	temperature = max(0.0, temperature - (max_temperature / overheat_duration) * delta)
	
	if overheat_timer <= 0.0:
		is_overheated = false
		process_timer = 0.0
		SoundManager.play_sfx("wave_start")
		GameManager.emit_signal("show_damage_number", global_position + Vector2(0, -60), "FURNACE ONLINE!", Color(0.2, 1.0, 0.4), true)

func _process_single_bone() -> void:
	bones_stored -= 1
	GameManager.total_bones_processed += 1
	
	# Calculate coin yield based on heat stage multiplier, combo streak, and difficulty reward
	var mult = get_current_multiplier() * GameManager.get_combo_gold_mult() * GameManager.get_difficulty_gold_reward_mult()
	var base_coins = 1.0 * GameManager.furnace_coin_yield_mult * mult
	var bonus_luck_roll = randf() < (GameManager.luck * 0.3)
	if bonus_luck_roll:
		base_coins += 1.0
		
	var final_coins = int(round(base_coins))
	if final_coins < 1:
		final_coins = 1
		
	# Eject physical coins onto the arena floor
	_eject_coins(final_coins)
	
	# Generate heat scaled by difficulty
	var heat_gain = 4.5 * GameManager.furnace_heat_per_bone_mult * GameManager.get_difficulty_furnace_heat_mult()
	temperature += heat_gain
	
	# Small visual spark burst
	_spawn_sparks(4, Color(1.0, 0.6, 0.1))

func get_current_multiplier() -> float:
	var temp_ratio = temperature / max_temperature
	var base_mult = 1.0
	
	if temp_ratio < 0.35:
		base_mult = 1.0 # Low
	elif temp_ratio < 0.65:
		base_mult = 1.25 # Medium
	elif temp_ratio < 0.85:
		base_mult = 1.75 # High
	else:
		# Critical Max Yield!
		base_mult = 2.5 + GameManager.furnace_critical_multiplier_bonus
		
	return base_mult

func _update_stage() -> void:
	if is_overheated:
		current_stage = FurnaceStage.OVERHEATED
		return
		
	var temp_ratio = temperature / max_temperature
	if temp_ratio < 0.35:
		current_stage = FurnaceStage.LOW
	elif temp_ratio < 0.65:
		current_stage = FurnaceStage.MEDIUM
	elif temp_ratio < 0.85:
		current_stage = FurnaceStage.HIGH
	else:
		current_stage = FurnaceStage.CRITICAL
		
	# Apply screen shake in critical
	if current_stage == FurnaceStage.CRITICAL:
		shake_offset = Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))
	elif current_stage == FurnaceStage.HIGH:
		shake_offset = Vector2(randf_range(-0.8, 0.8), randf_range(-0.8, 0.8))
	else:
		shake_offset = Vector2.ZERO

func _update_audio_and_hud() -> void:
	var ratio = temperature / max_temperature
	SoundManager.update_furnace_audio(ratio, is_overheated)
	
	var stage_name = "STABLE"
	match current_stage:
		FurnaceStage.LOW: stage_name = "STABLE"
		FurnaceStage.MEDIUM: stage_name = "WARMING"
		FurnaceStage.HIGH: stage_name = "HIGH HEAT"
		FurnaceStage.CRITICAL: stage_name = "CRITICAL HEAT"
		FurnaceStage.OVERHEATED: stage_name = "MELTDOWN LOCKDOWN"
		
	GameManager.emit_signal("furnace_status_updated", temperature, max_temperature, stage_name, get_current_multiplier())

func feed_bones(count: int) -> int:
	if is_overheated:
		return 0
	var space = max_bones - bones_stored
	if space <= 0:
		return 0
	var accepted = min(space, count)
	bones_stored += accepted
	SoundManager.play_sfx("furnace_feed", 0.15)
	
	_spawn_sparks(6, Color(1.0, 0.8, 0.2))
	GameManager.emit_signal("show_damage_number", global_position + Vector2(0, -50), "+%d BONES" % accepted, Color(0.9, 0.85, 0.7), false)
	emit_signal("furnace_fed", accepted)
	return accepted

func apply_water_cooling(amount: float, player_efficiency: float) -> void:
	if is_overheated or temperature <= 0.0:
		return
		
	var effective_cooling = amount * player_efficiency * GameManager.furnace_cooling_absorption_mult
	var prev_temp = temperature
	temperature = max(0.0, temperature - effective_cooling)
	var cooled_amount = prev_temp - temperature
	
	# Spawn steam particles
	var steam_count = int(clamp((temperature / max_temperature) * 6.0 + 2.0, 2.0, 8.0))
	_spawn_steam(steam_count)
	SoundManager.play_sfx("steam_hiss", 0.2, -5.0)
	
	# Steam shockwave upgrade check
	if GameManager.furnace_steam_blast_unlocked and cooled_amount >= 15.0:
		_trigger_steam_blast()
		
	emit_signal("furnace_cooled", cooled_amount)

func _trigger_steam_blast() -> void:
	SoundManager.play_sfx("explosion", 0.3, -4.0)
	GameManager.emit_signal("screen_shake_requested", 5.0, 0.25)
	_spawn_steam(25)
	
	# Knockback nearby enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and e is CharacterBody2D:
			var dist = global_position.distance_to(e.global_position)
			if dist < 220.0:
				var push_dir = (e.global_position - global_position).normalized()
				if e.has_method("apply_knockback"):
					e.apply_knockback(push_dir * 450.0)
				if e.has_method("take_damage"):
					e.take_damage(25.0, false, "steam")

func _trigger_emergency_cool() -> void:
	emergency_charges_left -= 1
	temperature = max_temperature * 0.45
	SoundManager.play_sfx("steam_hiss", 0.1, 5.0)
	GameManager.emit_signal("screen_shake_requested", 8.0, 0.4)
	_spawn_steam(30)
	GameManager.emit_signal("show_damage_number", global_position + Vector2(0, -60), "EMERGENCY VALVE TRIGGERED!", Color(0.2, 0.9, 1.0), true)

func _trigger_overheat() -> void:
	if meltdown_active or is_blown_up:
		return
	meltdown_active = true
	meltdown_timer = 0.0
	meltdown_stage = 1
	is_overheated = true
	
	SoundManager.play_sfx("warning", 0.0, 4.0)
	GameManager.emit_signal("show_damage_number", global_position + Vector2(0, -90), "CRUCIBLE MELTDOWN IMMINENT!", Color(1.0, 0.2, 0.1), true)
	emit_signal("furnace_overheated")

func take_damage(_amount: float) -> void:
	if is_blown_up or meltdown_active: return
	SoundManager.play_sfx("enemy_hit", 0.2)
	for i in range(3):
		spark_particles.append({
			"pos": Vector2(randf_range(-20, 20), randf_range(-20, 20)),
			"vel": Vector2(randf_range(-80, 80), randf_range(-80, 10)),
			"life": randf_range(0.2, 0.45)
		})

func _eject_coins(amount: int) -> void:
	var target_parent = get_parent()
	if not is_instance_valid(target_parent): return
	
	for i in range(amount):
		var angle = randf() * TAU
		var dist = randf_range(40.0, 110.0)
		var target_loc = global_position + Vector2(cos(angle), sin(angle)) * dist
		
		# Instantiate Coin Pickup
		var coin = COIN_PICKUP_SCRIPT.new()
		target_parent.add_child(coin)
		coin.global_position = global_position + Vector2(randf_range(-10, 10), -20)
		if coin.has_method("launch_towards"):
			coin.launch_towards(target_loc)

func _spawn_steam(count: int) -> void:
	for i in range(count):
		steam_particles.append({
			"pos": Vector2(randf_range(-25, 25), randf_range(-20, 10)),
			"vel": Vector2(randf_range(-40, 40), randf_range(-90, -150)),
			"size": randf_range(6.0, 14.0),
			"life": randf_range(0.5, 0.9),
			"max_life": 0.8,
			"alpha": 0.85
		})

func _spawn_sparks(count: int, color: Color) -> void:
	for i in range(count):
		spark_particles.append({
			"pos": Vector2(randf_range(-25, 25), randf_range(-20, 15)),
			"vel": Vector2(randf_range(-120, 120), randf_range(-100, -220)),
			"size": randf_range(3.0, 7.0),
			"life": randf_range(0.4, 0.9),
			"max_life": 0.8,
			"color": color
		})

func _spawn_smoke(count: int) -> void:
	for i in range(count):
		smoke_particles.append({
			"pos": Vector2(randf_range(-30, 30), -35),
			"vel": Vector2(randf_range(-40, 40), randf_range(-50, -110)),
			"size": randf_range(12.0, 32.0),
			"life": randf_range(0.9, 1.6),
			"max_life": 1.5,
			"alpha": 0.8
		})

func _update_particles(delta: float) -> void:
	var temp_ratio = temperature / max_temperature
	if temp_ratio > 0.15 and randf() < temp_ratio * 0.5:
		_spawn_smoke(1)
	if temp_ratio > 0.65 and randf() < (temp_ratio - 0.5) * 0.8:
		_spawn_sparks(2, Color(1.0, 0.7, 0.2))
		
	# Update Steam
	var i = steam_particles.size() - 1
	while i >= 0:
		var p = steam_particles[i]
		p["life"] -= delta
		p["pos"] += p["vel"] * delta
		p["size"] += delta * 12.0
		if p["life"] <= 0:
			steam_particles.remove_at(i)
		i -= 1
		
	# Update Sparks
	i = spark_particles.size() - 1
	while i >= 0:
		var p = spark_particles[i]
		p["life"] -= delta
		p["pos"] += p["vel"] * delta
		p["vel"].y += 180.0 * delta
		if p["life"] <= 0:
			spark_particles.remove_at(i)
		i -= 1
		
	# Update Smoke
	i = smoke_particles.size() - 1
	while i >= 0:
		var p = smoke_particles[i]
		p["life"] -= delta
		p["pos"] += p["vel"] * delta
		p["size"] += delta * 8.0
		if p["life"] <= 0:
			smoke_particles.remove_at(i)
		i -= 1

func _draw() -> void:
	var temp_ratio = clamp(temperature / max_temperature, 0.0, 1.0)
	var pos = shake_offset
	
	# Draw Shockwaves
	for sw in shockwaves:
		var c = sw["color"]
		c.a = sw["alpha"]
		draw_arc(pos, sw["radius"], 0, TAU, 32, c, 10.0 * sw["alpha"])
		draw_arc(pos, sw["radius"] * 0.95, 0, TAU, 32, Color(1.0, 1.0, 1.0, sw["alpha"] * 0.8), 4.0)
		
	# Draw Flying Exploded Shrapnel Pieces
	for sh in shrapnel_particles:
		var alpha_val = clamp(sh["life"] / sh["max_life"], 0.0, 1.0)
		var c = sh["color"]
		c.a = alpha_val
		draw_set_transform(pos + sh["pos"], sh["rot"], Vector2.ONE)
		draw_rect(Rect2(-sh["size"]*0.5, -sh["size"]*0.5, sh["size"], sh["size"]), c, true)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	
	if is_blown_up:
		# Draw Shattered Smoking Basalt Crater Ruin
		draw_circle(pos + Vector2(0, 10), 90.0, Color8(15, 12, 10))
		draw_circle(pos + Vector2(0, 10), 65.0, Color8(28, 20, 18))
		draw_circle(pos + Vector2(0, 10), 40.0, Color8(255, 60, 20, 160))
		draw_circle(pos + Vector2(0, 10), 20.0, Color8(255, 200, 40, 200))
		
		# Draw Smoke over crater
		for sm in smoke_particles:
			var t = sm["life"] / sm["max_life"]
			draw_circle(pos + sm["pos"] * 1.5, sm["size"] * 1.8, Color(0.2, 0.2, 0.22, t * sm["alpha"]))
		for sp in spark_particles:
			draw_circle(pos + sp["pos"] * 1.5, sp["size"] * 1.5, sp["color"])
		return

	# Furnace Heat Zone Boundary Ring (200px radius - No HP Regen Zone)
	var ring_color = Color8(255, 80, 20, 45 if not GameManager.is_in_furnace_zone else 80)
	draw_arc(pos, 200.0, 0, TAU, 48, ring_color, 2.0)
	draw_arc(pos, 200.0, 0, TAU, 16, Color8(255, 140, 40, 25), 6.0)

	# Heat Radiance Aura (2x scaled)
	if temp_ratio > 0.35 and not is_overheated:
		var aura_radius = 85.0 + temp_ratio * 65.0 + sin(visual_time * 8.0) * 8.0
		var aura_alpha = clamp((temp_ratio - 0.3) * 0.45, 0.0, 0.5)
		draw_circle(pos + Vector2(0, 8), aura_radius, Color(1.0, 0.4, 0.1, aura_alpha))
		
	# Draw 8-Bit Pixel Art Furnace Texture (160x160 px - 2x Bigger)
	var stage_idx = int(current_stage)
	var anim_frame = int(visual_time * 6.0)
	var furnace_tex = VisualFactory.get_furnace_texture(stage_idx, anim_frame)
	if furnace_tex:
		var dest_rect = Rect2(pos + Vector2(-80, -96), Vector2(160, 160))
		draw_texture_rect(furnace_tex, dest_rect, false)
		
	# Meltdown Flash Strobe (white hot / red alert)
	if meltdown_active and meltdown_stage == 1:
		var strobe = int(visual_time * 20.0) % 2 == 0
		draw_circle(pos + Vector2(0, 8), 95.0, Color(1.0, 1.0, 1.0 if strobe else 0.2, 0.4))
		
	# Draw Smoke Particles
	for sm in smoke_particles:
		var t = sm["life"] / sm["max_life"]
		draw_circle(pos + sm["pos"] * 1.5, sm["size"] * 1.5, Color(0.3, 0.3, 0.32, t * sm["alpha"]))
		
	# Draw Steam Particles
	for st in steam_particles:
		var t = st["life"] / st["max_life"]
		draw_circle(pos + st["pos"] * 1.5, st["size"] * 1.5, Color(0.9, 0.95, 1.0, t * st["alpha"]))
		
	# Draw Sparks
	for sp in spark_particles:
		draw_circle(pos + sp["pos"] * 1.5, sp["size"] * 1.5, sp["color"])
		
	# 8-Bit Overhead Mini Status Bars (2x scaled):
	# 1. Bones Stored Indicator
	var bar_w = 120.0
	var bar_h = 10.0
	var bone_ratio = clamp(float(bones_stored) / float(max_bones), 0.0, 1.0)
	draw_rect(Rect2(pos + Vector2(-bar_w * 0.5 - 2, -112), Vector2(bar_w + 4, bar_h + 4)), Color8(10, 11, 15), true)
	draw_rect(Rect2(pos + Vector2(-bar_w * 0.5, -110), Vector2(bar_w, bar_h)), Color8(45, 45, 52), true)
	draw_rect(Rect2(pos + Vector2(-bar_w * 0.5, -110), Vector2(bar_w * bone_ratio, bar_h)), Color8(245, 240, 230), true)
	
	# 2. Temperature Heat Gauge
	var temp_w = 120.0
	var temp_h = 10.0
	var bar_col = Color8(55, 215, 65)
	if temp_ratio > 0.85:
		bar_col = Color8(255, 45, 45) if int(visual_time * 8.0) % 2 == 0 else Color8(255, 255, 255)
	elif temp_ratio > 0.65:
		bar_col = Color8(255, 140, 30)
	elif temp_ratio > 0.35:
		bar_col = Color8(245, 210, 45)
		
	draw_rect(Rect2(pos + Vector2(-temp_w * 0.5 - 2, -128), Vector2(temp_w + 4, temp_h + 4)), Color8(10, 11, 15), true)
	draw_rect(Rect2(pos + Vector2(-temp_w * 0.5, -126), Vector2(temp_w, temp_h)), Color8(45, 45, 52), true)
	draw_rect(Rect2(pos + Vector2(-temp_w * 0.5, -126), Vector2(temp_w * temp_ratio, temp_h)), bar_col, true)
