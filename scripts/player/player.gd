# player.gd - 8-Bit Minifantasy Survivor Player Controller
class_name Player
extends CharacterBody2D

# Movement & Combat
var move_direction: Vector2 = Vector2.ZERO
var facing_angle: float = 0.0
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_duration: float = 0.22
var dash_speed_mult: float = 3.2
var dash_cooldown_timer: float = 0.0
var dash_cooldown: float = 2.0
var is_invulnerable: bool = false
var invulnerability_timer: float = 0.0

# Status Effects on Player
var is_frozen: bool = false
var freeze_timer: float = 0.0
var player_burn_dps: float = 0.0
var player_burn_timer: float = 0.0
var player_burn_tick: float = 0.0
var player_slow_factor: float = 0.0
var player_slow_timer: float = 0.0
var player_poison_dps: float = 0.0
var player_poison_timer: float = 0.0
var player_poison_tick: float = 0.0

# Bone feed repeat timer
var feed_hold_timer: float = 0.0

# Node references & Weapon mounts
var weapon_instances: Array[WeaponBase] = []
var water_spray_node: WaterSpray = null
var ghost_trail_timer: float = 0.0
var ghost_trails: Array[Dictionary] = []

# Sprite & Animation
var sprite_node: Sprite2D = null
var idle_tex: Texture2D = null
var walk_tex: Texture2D = null
var dmg_tex: Texture2D = null
var anim_timer: float = 0.0
var is_moving: bool = false

# Preloaded Assets
const UI_FONT: Font = preload("res://assets/Ultrapixel.ttf")
const IDLE_TEX_PRELOAD = preload("res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Base_Humanoids/Human/Base_Human/HumanIdle.png")
const WALK_TEX_PRELOAD = preload("res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Base_Humanoids/Human/Base_Human/HumanWalk.png")
const DMG_TEX_PRELOAD = preload("res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Base_Humanoids/Human/Base_Human/HumanDmg.png")

func _ready() -> void:
	GameManager.player_node = self
	add_to_group("player")
	collision_layer = 1
	collision_mask = 3
	
	var col = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not col:
		col = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 24.0
		col.shape = shape
		add_child(col)
	elif col.shape is CircleShape2D:
		col.shape.radius = 24.0
	
	_setup_sprites()
	
	# Create Water Spray child
	water_spray_node = WaterSpray.new()
	water_spray_node.name = "WaterSpray"
	add_child(water_spray_node)
	
	# Connect manager signals
	GameManager.weapons_updated.connect(_rebuild_weapons)
	_rebuild_weapons()

func clear_status_effects() -> void:
	is_frozen = false
	freeze_timer = 0.0
	player_burn_dps = 0.0
	player_burn_timer = 0.0
	player_burn_tick = 0.0
	player_slow_factor = 0.0
	player_slow_timer = 0.0
	player_poison_dps = 0.0
	player_poison_timer = 0.0
	player_poison_tick = 0.0
	knockback_push_velocity = Vector2.ZERO
	is_dashing = false
	invulnerability_timer = 0.0

var knockback_push_velocity: Vector2 = Vector2.ZERO

func apply_knockback_push(force: Vector2) -> void:
	knockback_push_velocity += force

func take_damage_hit(dmg: float) -> void:
	var final_dmg = dmg
	# Balanced Freeze: When frozen, player gains 40% damage resistance so they are not instantly killed
	if is_frozen:
		final_dmg *= 0.60
	GameManager.damage_player(final_dmg)

func apply_freeze(duration: float) -> void:
	if player_burn_timer > 0.0:
		player_burn_timer = 0.0
		player_burn_dps = 0.0
		SoundManager.play_sfx("steam_hiss", 0.15, -4.0)
	is_frozen = true
	freeze_timer = max(freeze_timer, duration)
	SoundManager.play_sfx("shoot_shuriken", 0.15, 2.0)
	GameManager.emit_signal("show_damage_number", global_position + Vector2(0, -35), "FROZEN!", Color8(90, 210, 255), true)

func apply_burn(dps: float, duration: float) -> void:
	if is_frozen:
		is_frozen = false
		freeze_timer = 0.0
		player_burn_timer = 0.0
		player_burn_dps = 0.0
		SoundManager.play_sfx("steam_hiss", 0.2, -2.0)
		GameManager.emit_signal("show_damage_number", global_position + Vector2(0, -35), "MELTED!", Color(1.0, 0.65, 0.2), true)
		return
	player_burn_dps = max(player_burn_dps, dps)
	player_burn_timer = max(player_burn_timer, duration)

func apply_slow(factor: float, duration: float) -> void:
	player_slow_factor = max(player_slow_factor, factor)
	player_slow_timer = max(player_slow_timer, duration)

func apply_poison(dps: float, duration: float) -> void:
	player_poison_dps = max(player_poison_dps, dps)
	player_poison_timer = max(player_poison_timer, duration)

func _setup_sprites() -> void:
	idle_tex = IDLE_TEX_PRELOAD
	walk_tex = WALK_TEX_PRELOAD
	dmg_tex = DMG_TEX_PRELOAD
	
	sprite_node = Sprite2D.new()
	sprite_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite_node.texture = idle_tex
	sprite_node.hframes = max(1, int(idle_tex.get_width() / 32)) if idle_tex else 16
	sprite_node.vframes = max(1, int(idle_tex.get_height() / 32)) if idle_tex else 4
	sprite_node.frame_coords = Vector2i(0, 0)
	sprite_node.scale = Vector2(4.5, 4.5)
	add_child(sprite_node)

func reset_player() -> void:
	clear_status_effects()
	velocity = Vector2.ZERO
	knockback_push_velocity = Vector2.ZERO
	dash_cooldown_timer = 0.0
	feed_hold_timer = 0.0
	ghost_trails.clear()
	facing_angle = 0.0
	if is_instance_valid(water_spray_node):
		water_spray_node.stop_spray()
	if is_instance_valid(sprite_node):
		sprite_node.modulate = Color.WHITE
		if idle_tex:
			sprite_node.texture = idle_tex
			sprite_node.frame_coords = Vector2i(0, 0)
	global_position = Vector2(0, 140)
	_rebuild_weapons()

func _unhandled_input(event: InputEvent) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
		
	# Mouse Click Handling: Left-Click for Water Spray, Right-Click for Target Lock-On
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and not is_frozen:
				water_spray_node.start_spray()
			else:
				water_spray_node.stop_spray()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed and not is_frozen:
				# Check if an enemy monster was right-clicked to lock-on!
				var m_pos = get_global_mouse_position()
				var clicked_enemy: Node2D = null
				var enemies = get_tree().get_nodes_in_group("enemies")
				for e in enemies:
					if is_instance_valid(e) and not e.is_queued_for_deletion():
						var e_rad = e.radius if "radius" in e else 30.0
						if m_pos.distance_to(e.global_position) <= e_rad + 22.0:
							clicked_enemy = e
							break
				if clicked_enemy:
					GameManager.lock_target(clicked_enemy)
				else:
					# Clicking open arena ground unlocks current target
					GameManager.unlock_target()
				
	# Key Actions (Target Unlock via Q, Active Skills via 1 / 2 / 3)
	if event is InputEventKey and event.pressed and not event.is_echo():
		var code = event.keycode if event.keycode != KEY_NONE else event.physical_keycode
		if code == KEY_Q:
			GameManager.unlock_target()
		elif code == KEY_1 or code == KEY_KP_1:
			GameManager.activate_skill(0)
		elif code == KEY_2 or code == KEY_KP_2:
			GameManager.activate_skill(1)
		elif code == KEY_3 or code == KEY_KP_3:
			GameManager.activate_skill(2)

func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
		
	_process_player_status_effects(delta)
	_handle_input_timers(delta)
	_handle_magnet_pickups(delta)
	_update_ghost_trails(delta)
	_update_sprite_animation(delta)
	
	# Mouse aim angle
	facing_angle = (get_global_mouse_position() - global_position).angle()
	
	# Update weapon hardpoints position
	_update_weapon_positions()
	queue_redraw()

func _process_player_status_effects(delta: float) -> void:
	# Freeze timer
	if freeze_timer > 0.0:
		freeze_timer -= delta
		if freeze_timer <= 0.0:
			is_frozen = false
			
	# Slow timer
	if player_slow_timer > 0.0:
		player_slow_timer -= delta
		if player_slow_timer <= 0.0:
			player_slow_factor = 0.0
			
	# Burn DoT
	if player_burn_timer > 0.0:
		player_burn_timer -= delta
		player_burn_tick += delta
		if player_burn_tick >= 0.5:
			player_burn_tick = 0.0
			GameManager.damage_player(player_burn_dps * 0.5)
			
	# Poison DoT
	if player_poison_timer > 0.0:
		player_poison_timer -= delta
		player_poison_tick += delta
		if player_poison_tick >= 0.5:
			player_poison_tick = 0.0
			GameManager.damage_player(player_poison_dps * 0.5)

func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		velocity = Vector2.ZERO
		return
		
	_handle_movement(delta)
	move_and_slide()

func _handle_movement(delta: float) -> void:
	if knockback_push_velocity.length_squared() > 1.0:
		velocity = knockback_push_velocity
		knockback_push_velocity = knockback_push_velocity.move_toward(Vector2.ZERO, 1200.0 * delta)
		return
		
	if is_frozen:
		velocity = Vector2.ZERO
		is_moving = false
		return
		
	var input_x = Input.get_axis("move_left", "move_right")
	var input_y = Input.get_axis("move_up", "move_down")
	var input_vec = Vector2(input_x, input_y)
	if input_vec.length() > 1.0:
		input_vec = input_vec.normalized()
		
	is_moving = input_vec.length_squared() > 0.01
	
	if is_dashing:
		dash_timer -= delta
		ghost_trail_timer += delta
		if ghost_trail_timer >= 0.04:
			ghost_trail_timer = 0.0
			ghost_trails.append({"pos": global_position, "angle": facing_angle, "alpha": 0.6})
			
		if dash_timer <= 0.0:
			is_dashing = false
			is_invulnerable = false
	else:
		if is_moving:
			move_direction = input_vec
			var speed = GameManager.move_speed_base * GameManager.move_speed_mult * (1.0 - player_slow_factor)
			velocity = input_vec * speed
		else:
			velocity = velocity.move_toward(Vector2.ZERO, 1400.0 * delta)

func _update_sprite_animation(delta: float) -> void:
	if not sprite_node or not is_instance_valid(sprite_node):
		return
		
	anim_timer += delta
	if invulnerability_timer > 0.0:
		invulnerability_timer -= delta
		
	# Select Sprite Texture
	var target_tex = idle_tex
	var target_fps = 5.0
	
	if invulnerability_timer > 0.15 and dmg_tex:
		target_tex = dmg_tex
		target_fps = 8.0
	elif is_moving and walk_tex and not is_frozen:
		target_tex = walk_tex
		target_fps = 8.0
	elif idle_tex:
		target_tex = idle_tex
		target_fps = 5.0
		
	if sprite_node.texture != target_tex and target_tex:
		sprite_node.texture = target_tex
		sprite_node.hframes = max(1, int(target_tex.get_width() / 32))
		sprite_node.vframes = max(1, int(target_tex.get_height() / 32))
		
	var hf = sprite_node.hframes
	var current_col = int(anim_timer * target_fps) % max(1, hf)
	# Row 0 is facing the screen!
	sprite_node.frame_coords = Vector2i(current_col, 0)
	
	# 2-Direction screen-facing horizontal flip
	if is_moving and abs(velocity.x) > 5.0:
		sprite_node.flip_h = velocity.x < 0
	else:
		# Flip based on mouse aim
		sprite_node.flip_h = (cos(facing_angle) < 0)
		
	# Status Modulation
	if invulnerability_timer > 0.0:
		var flash = int(invulnerability_timer * 25.0) % 2 == 0
		sprite_node.modulate = Color(1.0, 1.0, 1.0, 0.35 if flash else 1.0)
	elif is_frozen:
		sprite_node.modulate = Color8(100, 220, 255) # Frozen Cyan
	elif is_dashing:
		sprite_node.modulate = Color(0.4, 0.85, 1.0, 0.7)
	elif player_burn_timer > 0.0:
		sprite_node.modulate = Color(1.3, 0.5, 0.2) # Burning Orange
	elif player_poison_timer > 0.0:
		sprite_node.modulate = Color(0.4, 1.2, 0.3) # Poison Green
	elif player_slow_timer > 0.0:
		sprite_node.modulate = Color(0.6, 0.8, 1.1) # Slow Blue
	else:
		sprite_node.modulate = Color.WHITE

func _handle_input_timers(delta: float) -> void:
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
		
	# Dash Input (Space / Shift)
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0 and not is_dashing:
		_trigger_dash()
		
	# Furnace Feed Interaction (Press/Hold E near furnace)
	if is_instance_valid(GameManager.furnace_node):
		var dist_to_furnace = global_position.distance_to(GameManager.furnace_node.global_position)
		if dist_to_furnace <= 150.0:
			if Input.is_action_pressed("interact"):
				feed_hold_timer += delta
				if feed_hold_timer >= 0.10 and GameManager.bones_held > 0:
					feed_hold_timer = 0.0
					var to_feed = min(5, GameManager.bones_held)
					var accepted = GameManager.furnace_node.feed_bones(to_feed)
					if accepted > 0:
						GameManager.remove_bones(accepted)
			else:
				feed_hold_timer = 0.15

func _trigger_dash() -> void:
	is_dashing = true
	is_invulnerable = true
	dash_timer = dash_duration
	dash_cooldown_timer = max(0.4, dash_cooldown * GameManager.dash_cooldown_mult)
	
	var dash_dir = move_direction if move_direction != Vector2.ZERO else Vector2.from_angle(facing_angle)
	var speed = GameManager.move_speed_base * GameManager.move_speed_mult * dash_speed_mult
	velocity = dash_dir * speed
	
	SoundManager.play_sfx("dash", 0.15)
	GameManager.emit_signal("screen_shake_requested", 3.5, 0.15)

func _handle_magnet_pickups(delta: float) -> void:
	var magnet_radius = GameManager.pickup_radius_base * GameManager.pickup_radius_mult
	var magnet_radius_sq = magnet_radius * magnet_radius
	var pickups = get_tree().get_nodes_in_group("pickups")
	if pickups.is_empty():
		return
	
	for p in pickups:
		if is_instance_valid(p) and not p.is_queued_for_deletion():
			var dist_sq = global_position.distance_squared_to(p.global_position)
			if dist_sq <= magnet_radius_sq:
				if p.has_method("attract_to"):
					p.attract_to(global_position, delta)

func _rebuild_weapons() -> void:
	for w in weapon_instances:
		if is_instance_valid(w):
			w.queue_free()
	weapon_instances.clear()
	
	var count = GameManager.equipped_weapons.size()
	for i in range(count):
		var w_data = GameManager.equipped_weapons[i]
		var w_node = WeaponBase.new()
		w_node.init_weapon(w_data, i, count)
		add_child(w_node)
		weapon_instances.append(w_node)

func _update_weapon_positions() -> void:
	var count = weapon_instances.size()
	if count == 0: return
	
	var radius_val = 56.0
	for i in range(count):
		var w = weapon_instances[i]
		if is_instance_valid(w):
			var angle = (float(i) / float(count)) * TAU + (anim_timer * 0.8)
			w.position = Vector2(cos(angle), sin(angle)) * radius_val

func _update_ghost_trails(delta: float) -> void:
	var i = ghost_trails.size() - 1
	while i >= 0:
		var g = ghost_trails[i]
		g["alpha"] -= delta * 3.5
		if g["alpha"] <= 0.0:
			ghost_trails.remove_at(i)
		i -= 1

func _draw() -> void:
	# Active Aegis Barrier Visual
	if GameManager.active_shield_timer > 0.0:
		var bubble_r = 44.0 + sin(anim_timer * 12.0) * 3.0
		draw_circle(Vector2.ZERO, bubble_r, Color(0.1, 0.7, 1.0, 0.25))
		draw_arc(Vector2.ZERO, bubble_r, anim_timer * 3.0, anim_timer * 3.0 + TAU * 0.85, 24, Color8(80, 220, 255), 3.5)
		draw_arc(Vector2.ZERO, bubble_r - 5.0, -anim_timer * 4.0, -anim_timer * 4.0 + TAU * 0.6, 20, Color8(180, 240, 255), 2.0)
		
	# Active Overdrive Surge Visual
	if GameManager.active_damage_boost_timer > 0.0:
		var pulse_r = 40.0 + sin(anim_timer * 16.0) * 4.0
		draw_arc(Vector2.ZERO, pulse_r, -anim_timer * 5.0, -anim_timer * 5.0 + TAU, 20, Color8(255, 120, 30, 200), 3.0)
		for k in range(4):
			var spark_a = anim_timer * 6.0 + (float(k) / 4.0) * TAU
			var spark_pt = Vector2.from_angle(spark_a) * (pulse_r + 6.0)
			draw_rect(Rect2(spark_pt - Vector2(3, 3), Vector2(6, 6)), Color8(255, 220, 60), true)
	
	# Prompt indicator when near furnace
	if is_instance_valid(GameManager.furnace_node):
		var dist_sq = global_position.distance_squared_to(GameManager.furnace_node.global_position)
		if dist_sq <= 40000.0: # 200.0 * 200.0
			if UI_FONT:
				draw_rect(Rect2(-45, -82, 90, 32), Color8(15, 15, 20, 240), true)
				draw_rect(Rect2(-45, -82, 90, 32), Color8(250, 200, 40), false, 2.5)
				draw_string(UI_FONT, Vector2(-42, -60), "[E] FEED", HORIZONTAL_ALIGNMENT_CENTER, 84, 20, Color8(255, 220, 60))
				if GameManager.hp_regen > 0.0:
					draw_rect(Rect2(-55, -108, 110, 22), Color8(40, 10, 10, 220), true)
					draw_rect(Rect2(-55, -108, 110, 22), Color8(255, 60, 60), false, 1.5)
					draw_string(UI_FONT, Vector2(-52, -92), "! NO HP REGEN !", HORIZONTAL_ALIGNMENT_CENTER, 104, 15, Color8(255, 100, 100))
