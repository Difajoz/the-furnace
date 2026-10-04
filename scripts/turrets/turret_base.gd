# turret_base.gd - Autonomous Defense Turret Entity (Ballista & Heavy Cannon)
class_name TurretBase
extends StaticBody2D

const ARROW_BASE_TEX = preload("res://assets/turrets/arrow_turret_base.png")
const ARROW_HEAD_TEX = preload("res://assets/turrets/arrow_turret_head.png")
const CANNON_BASE_TEX = preload("res://assets/turrets/cannon_turret_base.png")
const CANNON_HEAD_TEX = preload("res://assets/turrets/cannon_turret_head.png")
const FLAME_BASE_TEX = preload("res://assets/turrets/flame_turret_base.png")
const FLAME_HEAD_TEX = preload("res://assets/turrets/flame_turret_head.png")
const ICE_BASE_TEX = preload("res://assets/turrets/ice_turret_base.png")
const ICE_HEAD_TEX = preload("res://assets/turrets/ice_turret_head.png")

const PROJECTILE_SCRIPT = preload("res://scripts/turrets/turret_projectile.gd")
const SHOOT_EFFECT_SCRIPT = preload("res://scripts/turrets/turret_shoot_effect.gd")

@export var turret_type: String = "ballista" # "ballista", "cannon", "flame", "ice"

# Visual Nodes
var base_sprite: Sprite2D = null
var head_sprite: Sprite2D = null
var col_shape: CollisionShape2D = null

# Combat Stats
var detection_range: float = 380.0
var fire_rate: float = 1.15
var fire_timer: float = 0.0
var damage: float = 28.0
var projectile_speed: float = 780.0
var pierce_count: int = 4
var aoe_radius: float = 105.0
var knockback_force: float = 280.0

# Animation & Recoil state
var current_target: Node2D = null
var is_recoiling: bool = false
var recoil_timer: float = 0.0

func _ready() -> void:
	add_to_group("turrets")
	collision_layer = 1
	collision_mask = 0
	
	_configure_stats()
	_setup_nodes()

func configure_turret(type_name: String) -> void:
	turret_type = type_name
	_configure_stats()
	if is_instance_valid(base_sprite) and is_instance_valid(head_sprite):
		_update_textures()

func _configure_stats() -> void:
	if turret_type == "cannon":
		detection_range = 290.0
		fire_rate = 2.2
		damage = 55.0
		projectile_speed = 460.0
		aoe_radius = 105.0
		knockback_force = 280.0
	elif turret_type == "flame":
		detection_range = 190.0
		fire_rate = 0.12
		damage = 3.2
		projectile_speed = 420.0
		pierce_count = 99
	elif turret_type == "ice":
		detection_range = 280.0
		fire_rate = 2.5
		damage = 6.0
		projectile_speed = 620.0
		pierce_count = 1
	else: # ballista
		detection_range = 380.0
		fire_rate = 1.15
		damage = 28.0
		projectile_speed = 780.0
		pierce_count = 4

func _setup_nodes() -> void:
	# Circular physical collision so monsters and player don't phase through
	col_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 18.0
	col_shape.shape = shape
	add_child(col_shape)
	
	# Base Sprite (Stationary turntable)
	base_sprite = Sprite2D.new()
	base_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	base_sprite.scale = Vector2(2.5, 2.5)
	add_child(base_sprite)
	
	# Head Sprite (Rotates 360 degrees to track enemies)
	head_sprite = Sprite2D.new()
	head_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	head_sprite.scale = Vector2(2.5, 2.5)
	head_sprite.hframes = 4
	head_sprite.vframes = 1
	head_sprite.frame = 0
	head_sprite.z_index = 1
	add_child(head_sprite)
	
	_update_textures()

func _update_textures() -> void:
	if turret_type == "cannon":
		base_sprite.texture = CANNON_BASE_TEX
		head_sprite.texture = CANNON_HEAD_TEX
	elif turret_type == "flame":
		base_sprite.texture = FLAME_BASE_TEX
		head_sprite.texture = FLAME_HEAD_TEX
	elif turret_type == "ice":
		base_sprite.texture = ICE_BASE_TEX
		head_sprite.texture = ICE_HEAD_TEX
	else:
		base_sprite.texture = ARROW_BASE_TEX
		head_sprite.texture = ARROW_HEAD_TEX

func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
		
	if fire_timer > 0.0:
		fire_timer -= delta
		
	_process_recoil_animation(delta)
	_track_and_fire(delta)

func _process_recoil_animation(delta: float) -> void:
	if not is_recoiling or not is_instance_valid(head_sprite):
		return
		
	recoil_timer += delta
	# 4-frame animation timeline:
	# 0.00 -> Frame 1 (Recoil kickback)
	# 0.08 -> Frame 2 (Max recoil compression & smoke)
	# 0.20 -> Frame 3 (Slide forward recovery)
	# 0.35 -> Frame 0 (Rest / Battery)
	if recoil_timer < 0.08:
		head_sprite.frame = 1
	elif recoil_timer < 0.20:
		head_sprite.frame = 2
	elif recoil_timer < 0.35:
		head_sprite.frame = 3
	else:
		head_sprite.frame = 0
		is_recoiling = false

func _track_and_fire(delta: float) -> void:
	# Find closest alive enemy within detection range
	var best_enemy: Node2D = null
	var best_dist: float = detection_range
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for e in enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			var dist = global_position.distance_to(e.global_position)
			if dist <= best_dist:
				best_dist = dist
				best_enemy = e
				
	current_target = best_enemy
	
	if not is_instance_valid(current_target):
		return
		
	var target_vec = (current_target.global_position - global_position)
	var target_angle = target_vec.angle()
	
	# Smoothly rotate head towards target
	head_sprite.rotation = lerp_angle(head_sprite.rotation, target_angle, delta * 14.0)
	
	# Check firing condition: aimed close to target and cooldown ready
	var angle_diff = abs(angle_difference(head_sprite.rotation, target_angle))
	if angle_diff < 0.45 and fire_timer <= 0.0:
		_fire_turret(target_vec.normalized())

func _fire_turret(fire_dir: Vector2) -> void:
	fire_timer = fire_rate
	is_recoiling = true
	recoil_timer = 0.0
	head_sprite.frame = 1
	
	var scene_root = get_tree().current_scene
	if not is_instance_valid(scene_root):
		scene_root = get_parent()
		
	# Muzzle offset in local firing direction
	var muzzle_offset = fire_dir * 22.0
	var muzzle_pos = global_position + muzzle_offset
	
	# Spawn Shoot Effect (Muzzle Flash / String Snap)
	var effect = SHOOT_EFFECT_SCRIPT.new()
	scene_root.add_child(effect)
	effect.global_position = muzzle_pos
	effect.setup(turret_type, head_sprite.rotation)
	
	# Spawn Projectile
	var proj = PROJECTILE_SCRIPT.new()
	scene_root.add_child(proj)
	proj.global_position = muzzle_pos
	
	if turret_type == "cannon":
		proj.init_cannonball(fire_dir, projectile_speed, damage, detection_range * 1.15, aoe_radius, knockback_force)
		SoundManager.play_sfx("shoot_shotgun", 0.25, 0.70)
	elif turret_type == "flame":
		proj.init_flame(fire_dir, projectile_speed, damage, detection_range * 1.1)
		SoundManager.play_sfx("steam_hiss", 0.25, -4.0)
	elif turret_type == "ice":
		proj.init_ice(fire_dir, projectile_speed, damage, detection_range * 1.2, 5.0)
		SoundManager.play_sfx("shoot_laser", 0.18, 1.4)
	else:
		proj.init_arrow(fire_dir, projectile_speed, damage, detection_range * 1.2, pierce_count)
		SoundManager.play_sfx("shoot_shuriken", 0.18, 1.25)
