# projectile_base.gd - Projectile Motion, Collision, AoE, Chain Lightning, Boomerangs, Vortex, Ricochets, and Status Effects
class_name ProjectileBase
extends Area2D

const ARENA_MIN_X: float = -710.0
const ARENA_MAX_X: float = 710.0
const ARENA_MIN_Y: float = -510.0
const ARENA_MAX_Y: float = 510.0

const SLASH_TEX = preload("res://assets/Minifantasy_True_Heroes_III_v1.1/Minifantasy_True_Heroes_III_Assets/Fighter/General_Animations/Figther_Attack_Effect.png")
const FIRE_TEX = preload("res://assets/Minifantasy_Spell Effects_v1.0/Minifantasy_Spell_Effects_Assets/Fire/Tileable_Effect/Premade_Spell_Effects/Fire_Wave_E.png")
const ACID_POOL_SCRIPT = preload("res://scripts/weapons/acid_pool.gd")

var velocity: Vector2 = Vector2.ZERO
var damage: float = 10.0
var speed: float = 600.0
var max_range: float = 500.0
var distance_traveled: float = 0.0
var pierce_left: int = 1
var bounces_left: int = 0
var knockback_force: float = 80.0
var is_crit: bool = false
var special_type: String = ""
var aoe_radius: float = 0.0
var bullet_color: Color = Color(1.0, 0.9, 0.3)
var is_enemy_projectile: bool = false
var source_weapon_id: String = ""
var slow_factor: float = 0.40

# Split projectile logic
var split_count: int = 0
var split_distance: float = 0.0
var has_split: bool = false

# Boomerang state
var is_returning: bool = false
var initial_dir: Vector2 = Vector2.ZERO
var initial_speed: float = 500.0

# Homing state
var homing_target: Node2D = null

# Target hit tracking
var hit_entities: Array[Node2D] = []
var visual_time: float = 0.0
var spin_angle: float = 0.0
var trail_points: Array[Vector2] = []
var col_shape: CollisionShape2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	collision_layer = 0
	# Strict collision masks: Enemy projectiles ONLY check Player (1), Player projectiles ONLY check Enemies (2)
	if is_enemy_projectile:
		collision_mask = 1
	else:
		collision_mask = 2
	
	col_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 14.0
	col_shape.shape = shape
	add_child(col_shape)

func init_projectile(dir: Vector2, spd: float, dmg: float, rng: float, prc: int, kb: float, crit: bool, spec: String, col: Color, bnc: int = 0, aoe: float = 0.0) -> void:
	speed = spd
	initial_speed = spd
	initial_dir = dir.normalized()
	velocity = initial_dir * speed
	damage = dmg
	max_range = rng
	pierce_left = prc
	knockback_force = kb
	is_crit = crit
	special_type = spec
	bullet_color = col
	bounces_left = bnc
	aoe_radius = aoe
	rotation = dir.angle()
	
	if is_enemy_projectile:
		collision_mask = 1
	else:
		collision_mask = 2

func configure_split(count: int, dist: float) -> void:
	split_count = count
	split_distance = dist

func _process(delta: float) -> void:
	visual_time += delta
	spin_angle += delta * 15.0
	
	# Boomerang Return Logic
	if special_type == "bone_boomerang":
		if not is_returning:
			var return_point = max_range * 0.55
			if distance_traveled >= return_point:
				is_returning = true
				hit_entities.clear() # Allow hitting enemies again on return path
		if is_returning:
			if is_instance_valid(GameManager.player_node):
				var to_player = (GameManager.player_node.global_position - global_position).normalized()
				velocity = velocity.move_toward(to_player * initial_speed * 1.3, 1400.0 * delta)
				if global_position.distance_to(GameManager.player_node.global_position) < 35.0 and distance_traveled > 80.0:
					queue_free()
					return
					
	# Homing Logic for Arcane Missiles & Homing Souls (Player)
	elif special_type in ["arcane_homing", "split_arcane", "soul"] and not is_enemy_projectile:
		if not is_instance_valid(homing_target) or homing_target.is_queued_for_deletion():
			homing_target = _find_nearest_enemy()
		if is_instance_valid(homing_target):
			var desired_dir = (homing_target.global_position - global_position).normalized()
			var cur_dir = velocity.normalized()
			var new_dir = cur_dir.slerp(desired_dir, delta * 9.0)
			velocity = new_dir * speed
			rotation = new_dir.angle()
			
	# Enemy Homing Soul targeting player
	elif special_type in ["soul", "shadow_bolt"] and is_enemy_projectile:
		if is_instance_valid(GameManager.player_node):
			var desired_dir = (GameManager.player_node.global_position - global_position).normalized()
			var cur_dir = velocity.normalized()
			var new_dir = cur_dir.slerp(desired_dir, delta * 3.5)
			velocity = new_dir * speed
			rotation = new_dir.angle()
			
	# Vortex Pulling Effect while airborne
	if special_type == "void_vortex":
		_process_vortex_pull(delta)
		
	# Split shot trigger
	if split_count > 0 and not has_split and distance_traveled >= split_distance:
		_trigger_split()
		
	var move_step = velocity * delta
	global_position += move_step
	distance_traveled += move_step.length()
	
	# Arena Wall Ricochet Bounces
	if bounces_left > 0:
		_check_wall_bounce()
		
	trail_points.push_front(global_position)
	if trail_points.size() > 6:
		trail_points.pop_back()
		
	# Check Holy Water Sprinkler interaction with furnace
	if special_type == "furnace_cooling_shot" and is_instance_valid(GameManager.furnace_node):
		var dist_furnace = global_position.distance_to(GameManager.furnace_node.global_position)
		if dist_furnace < 60.0:
			GameManager.furnace_node.apply_water_cooling(14.0, GameManager.cooling_efficiency)
			_detonate_or_destroy()
			return
			
	if distance_traveled >= max_range and not (special_type == "bone_boomerang" and is_returning):
		_detonate_or_destroy()
		
	queue_redraw()

func _check_wall_bounce() -> void:
	var bounced = false
	if global_position.x < ARENA_MIN_X:
		global_position.x = ARENA_MIN_X
		velocity.x = -velocity.x
		bounced = true
	elif global_position.x > ARENA_MAX_X:
		global_position.x = ARENA_MAX_X
		velocity.x = -velocity.x
		bounced = true
		
	if global_position.y < ARENA_MIN_Y:
		global_position.y = ARENA_MIN_Y
		velocity.y = -velocity.y
		bounced = true
	elif global_position.y > ARENA_MAX_Y:
		global_position.y = ARENA_MAX_Y
		velocity.y = -velocity.y
		bounced = true
		
	if bounced:
		bounces_left -= 1
		rotation = velocity.angle()
		SoundManager.play_sfx("shoot_shuriken", 0.15, -6.0)

func _trigger_split() -> void:
	has_split = true
	var parent_scene = get_tree().current_scene
	if not is_instance_valid(parent_scene): return
	
	var base_ang = velocity.angle()
	var fan_angles: Array[float] = []
	if split_count == 2:
		fan_angles = [-0.35, 0.35]
	elif split_count == 3:
		fan_angles = [-0.45, 0.0, 0.45]
	elif split_count == 4:
		fan_angles = [-0.6, -0.2, 0.2, 0.6]
	else:
		for i in range(split_count):
			var a = (float(i) / float(split_count)) * TAU
			fan_angles.append(a)
			
	for ang_off in fan_angles:
		var sub_dir = Vector2.from_angle(base_ang + ang_off)
		var sub_proj = ProjectileBase.new()
		sub_proj.is_enemy_projectile = is_enemy_projectile
		var sub_spec = "arcane_homing" if special_type == "split_arcane" else ("explosive" if special_type == "cluster_bomb" else special_type)
		sub_proj.init_projectile(sub_dir, speed * 1.1, damage * 0.7, max_range * 0.7, 1, knockback_force * 0.7, is_crit, sub_spec, bullet_color, 1 if special_type == "ricochet" else 0, 70.0 if special_type == "cluster_bomb" else 0.0)
		parent_scene.add_child(sub_proj)
		sub_proj.global_position = global_position + sub_dir * 12.0
		
	SoundManager.play_sfx("shoot_plasma", 0.2, -4.0)
	if special_type in ["cluster_bomb", "split_arcane"]:
		queue_free()

func _find_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var best: Node2D = null
	var min_d = 550.0
	for e in enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			var d = global_position.distance_to(e.global_position)
			if d < min_d:
				min_d = d
				best = e
	return best

func _process_vortex_pull(delta: float) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and e.has_method("apply_knockback"):
			var d = global_position.distance_to(e.global_position)
			if d < 190.0 and d > 15.0:
				var pull_dir = (global_position - e.global_position).normalized()
				e.apply_knockback(pull_dir * 190.0 * delta * 8.0)

func _on_body_entered(body: Node2D) -> void:
	if body in hit_entities:
		return
		
	# Hit Player ONLY if fired by enemy
	if is_enemy_projectile:
		if body.is_in_group("player"):
			hit_entities.append(body)
			_hit_player(body)
			_detonate_or_destroy()
		return
		
	# Hit Enemy from player weapon projectile
	if not is_enemy_projectile and body.is_in_group("enemies") and body.has_method("take_damage"):
		hit_entities.append(body)
		_hit_enemy(body)
		
		# Lifesteal trigger
		if GameManager.lifesteal > 0.0:
			GameManager.heal_player(damage * GameManager.lifesteal)
			
		pierce_left -= 1
		if pierce_left <= 0 and special_type != "bone_boomerang":
			_detonate_or_destroy()

func _on_area_entered(_area: Area2D) -> void:
	pass

func _hit_player(player: Node2D) -> void:
	# Deal base damage
	if player.has_method("take_damage_hit"):
		player.take_damage_hit(damage)
	else:
		GameManager.damage_player(damage)
		
	# Apply Status Effects to Player
	match special_type:
		"freeze", "snowball", "glacier":
			if player.has_method("apply_freeze"):
				player.apply_freeze(1.0)
		"burn", "ember", "fire_spell", "magma":
			if player.has_method("apply_burn"):
				player.apply_burn(damage * 0.35, 3.0)
		"slow", "temporal_slow", "cryo_slow":
			if player.has_method("apply_slow"):
				player.apply_slow(slow_factor, 2.5)
		"poison", "acid_pool", "toxic":
			if player.has_method("apply_poison"):
				player.apply_poison(damage * 0.3, 3.5)
			_spawn_enemy_acid_pool(global_position)

func _hit_enemy(enemy: Node2D) -> void:
	var hit_dir = velocity.normalized()
	if enemy.has_method("apply_knockback"):
		enemy.apply_knockback(hit_dir * knockback_force)
		
	# Apply special elemental effects on Enemy
	match special_type:
		"burn", "magma", "fire_spell":
			if enemy.has_method("apply_burn"):
				enemy.apply_burn(damage * 0.45, 3.0)
		"freeze", "snowball", "glacier", "ice_spell":
			if enemy.has_method("apply_freeze"):
				enemy.apply_freeze(2.5)
			if enemy.has_method("apply_slow"):
				enemy.apply_slow(0.70, 3.0)
		"cryo_slow":
			if enemy.has_method("apply_slow"):
				enemy.apply_slow(slow_factor, 2.5)
		"temporal_slow":
			if enemy.has_method("apply_slow"):
				enemy.apply_slow(0.70, 3.5)
		"acid_pool", "toxic":
			_spawn_acid_pool(global_position)
		"lightning":
			_chain_lightning(enemy)
			
	enemy.take_damage(damage, is_crit, special_type)
	SoundManager.play_sfx("enemy_hit", 0.15)

func _chain_lightning(initial_target: Node2D) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var last_pos = initial_target.global_position
	var chain_count = 0
	
	for e in enemies:
		if is_instance_valid(e) and e != initial_target and not (e in hit_entities):
			var dist = last_pos.distance_to(e.global_position)
			if dist < 190.0:
				hit_entities.append(e)
				if e.has_method("take_damage"):
					e.take_damage(damage * 0.75, false, "lightning")
				last_pos = e.global_position
				chain_count += 1
				if chain_count >= 4:
					break

func _spawn_acid_pool(pos: Vector2) -> void:
	var parent_node = get_parent()
	if not is_instance_valid(parent_node): return
	var pool = ACID_POOL_SCRIPT.new()
	pool.is_enemy_hazard = false
	parent_node.add_child(pool)
	pool.global_position = pos

func _spawn_enemy_acid_pool(pos: Vector2) -> void:
	var parent_node = get_parent()
	if not is_instance_valid(parent_node): return
	var pool = ACID_POOL_SCRIPT.new()
	pool.is_enemy_hazard = true
	pool.damage_per_sec = max(6.0, damage * 0.4)
	parent_node.add_child(pool)
	pool.global_position = pos

func _detonate_or_destroy() -> void:
	if aoe_radius > 0.0 or special_type in ["explosive", "void_vortex", "meteor", "cluster_bomb"]:
		_trigger_aoe_explosion()
	queue_free()

func _trigger_aoe_explosion() -> void:
	SoundManager.play_sfx("explosion", 0.2)
	GameManager.emit_signal("screen_shake_requested", 8.0, 0.3)
	
	if is_enemy_projectile:
		if is_instance_valid(GameManager.player_node):
			var dist = global_position.distance_to(GameManager.player_node.global_position)
			var rad = aoe_radius if aoe_radius > 0.0 else 100.0
			if dist <= rad:
				GameManager.damage_player(damage * 0.8)
		return
		
	var enemies = get_tree().get_nodes_in_group("enemies")
	var rad = aoe_radius if aoe_radius > 0.0 else 110.0
	for e in enemies:
		if is_instance_valid(e) and e.has_method("take_damage"):
			var dist = global_position.distance_to(e.global_position)
			if dist <= rad:
				var falloff = 1.0 - (dist / rad) * 0.35
				var push_dir = (e.global_position - global_position).normalized()
				if e.has_method("apply_knockback"):
					e.apply_knockback(push_dir * knockback_force * 1.5)
				if special_type == "temporal_slow" and e.has_method("apply_slow"):
					e.apply_slow(0.75, 4.0)
				e.take_damage(damage * falloff, is_crit, "explosion")

func _draw() -> void:
	match special_type:
		"bone_boomerang":
			var b_tex = VisualFactory.get_weapon_texture("bone_boomerang")
			if b_tex:
				draw_set_transform(Vector2.ZERO, spin_angle, Vector2(1.5, 1.5))
				draw_texture(b_tex, -b_tex.get_size() * 0.5)
				draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
			else:
				draw_arc(Vector2.ZERO, 14.0, spin_angle, spin_angle + PI * 0.9, 12, Color8(240, 235, 220), 5.0)
		"shuriken", "sawblade":
			draw_set_transform(Vector2.ZERO, spin_angle * 1.5, Vector2.ONE)
			draw_circle(Vector2.ZERO, 10.0, Color8(210, 225, 240))
			draw_circle(Vector2.ZERO, 5.0, Color8(60, 70, 85))
			for i in range(4):
				var a = (float(i) / 4.0) * TAU
				draw_line(Vector2.ZERO, Vector2.from_angle(a) * 12.0, Color8(255, 255, 255), 3.0)
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		"void_vortex":
			draw_circle(Vector2.ZERO, 16.0, Color(0.3, 0.05, 0.5, 0.45))
			draw_arc(Vector2.ZERO, 18.0 + sin(visual_time * 10.0) * 3.0, spin_angle, spin_angle + PI * 1.5, 16, Color8(200, 80, 255), 3.0)
			draw_circle(Vector2.ZERO, 9.0, Color8(10, 5, 20))
			draw_circle(Vector2.ZERO, 5.0, Color8(140, 40, 220))
		"arcane_homing", "split_arcane":
			draw_circle(Vector2.ZERO, 9.0, Color(0.7, 0.3, 1.0, 0.45))
			draw_circle(Vector2.ZERO, 6.0, Color8(210, 110, 255))
			draw_circle(Vector2.ZERO, 3.0, Color.WHITE)
		"meteor":
			draw_circle(Vector2.ZERO, 18.0, Color(1.0, 0.3, 0.1, 0.5))
			draw_circle(Vector2.ZERO, 12.0, Color8(255, 120, 20))
			draw_circle(Vector2.ZERO, 7.0, Color8(255, 240, 80))
			draw_circle(Vector2.ZERO, 3.0, Color.WHITE)
		"slash":
			if SLASH_TEX:
				draw_texture_rect(SLASH_TEX, Rect2(Vector2(-16, -16), Vector2(32, 32)), false, bullet_color)
			else:
				draw_arc(Vector2.ZERO, 16.0, -0.6, 0.6, 8, bullet_color, 4.0)
		"frost_slash", "glacier":
			draw_arc(Vector2.ZERO, 20.0, -0.8, 0.8, 12, Color8(80, 220, 255), 5.0)
			draw_circle(Vector2(14, 0), 5.0, Color.WHITE)
		"fire_spell", "ember", "magma":
			if FIRE_TEX:
				draw_texture_rect(FIRE_TEX, Rect2(Vector2(-16, -16), Vector2(32, 32)), false, Color.WHITE)
			else:
				draw_circle(Vector2.ZERO, 11.0, Color8(255, 120, 20, 160))
				draw_circle(Vector2.ZERO, 7.0, Color8(255, 180, 40))
				draw_circle(Vector2.ZERO, 3.5, Color.WHITE)
		"ice_spell", "snowball", "freeze", "cryo_slow":
			draw_circle(Vector2.ZERO, 10.0, Color8(60, 200, 255, 140))
			draw_circle(Vector2.ZERO, 6.0, Color8(140, 235, 255))
			draw_circle(Vector2.ZERO, 3.0, Color.WHITE)
		"lightning_spell", "lightning":
			draw_circle(Vector2.ZERO, 9.0, Color8(255, 230, 60, 180))
			draw_circle(Vector2.ZERO, 5.0, Color8(255, 255, 180))
			draw_circle(Vector2.ZERO, 2.5, Color.WHITE)
		"poison_spell", "acid_pool", "toxic", "poison":
			draw_circle(Vector2.ZERO, 11.0, Color8(50, 200, 40, 150))
			draw_circle(Vector2.ZERO, 7.0, Color8(100, 245, 60))
			draw_circle(Vector2.ZERO, 3.5, Color8(220, 255, 120))
		"temporal_slow":
			draw_circle(Vector2.ZERO, 13.0, Color8(90, 160, 255, 120))
			draw_arc(Vector2.ZERO, 14.0 + sin(visual_time * 8.0) * 3.0, 0, TAU, 16, Color8(140, 210, 255), 2.5)
			draw_circle(Vector2.ZERO, 6.0, Color8(210, 235, 255))
		"ricochet":
			draw_circle(Vector2.ZERO, 9.0, Color8(255, 200, 50, 160))
			draw_circle(Vector2.ZERO, 6.0, Color8(255, 235, 90))
			draw_circle(Vector2.ZERO, 3.0, Color.WHITE)
		"rock":
			draw_circle(Vector2.ZERO, 12.0, Color8(130, 110, 90))
			draw_circle(Vector2(-2, -2), 7.0, Color8(170, 145, 120))
			draw_circle(Vector2(3, 3), 4.0, Color8(90, 75, 60))
		"soul", "shadow_bolt":
			draw_circle(Vector2.ZERO, 10.0, Color(0.7, 0.1, 0.9, 0.5))
			draw_circle(Vector2.ZERO, 7.0, Color8(180, 50, 240))
			draw_circle(Vector2.ZERO, 3.5, Color8(240, 180, 255))
		"explosive", "cluster_bomb":
			draw_rect(Rect2(-8, -3, 16, 6), Color(0.2, 0.2, 0.2), true)
			draw_circle(Vector2(8, 0), 5.0, Color(0.9, 0.2, 0.2))
			draw_circle(Vector2(-8, 0), 4.0 + sin(visual_time * 20.0), Color(1.0, 0.6, 0.1))
		"plasma", "twin_plasma":
			draw_circle(Vector2.ZERO, 10.0, Color(bullet_color.r, bullet_color.g, bullet_color.b, 0.45))
			draw_circle(Vector2.ZERO, 7.0, bullet_color)
			draw_circle(Vector2.ZERO, 3.5, Color.WHITE)
		"bone_scaling":
			draw_line(Vector2(-10, 0), Vector2(10, 0), bullet_color, 4.0)
			draw_line(Vector2(6, -4), Vector2(10, 0), bullet_color, 3.0)
			draw_line(Vector2(6, 4), Vector2(10, 0), bullet_color, 3.0)
		"furnace_cooling_shot":
			draw_circle(Vector2.ZERO, 8.0, Color(0.1, 0.8, 1.0, 0.8))
			draw_circle(Vector2.ZERO, 4.0, Color.WHITE)
		_:
			draw_line(Vector2(-8, 0), Vector2(8, 0), bullet_color, 4.5)
			draw_circle(Vector2(8, 0), 3.5, Color.WHITE)

