# turret_projectile.gd - Projectiles fired by defense turrets (Piercing Arrow & Explosive Cannonball)
class_name TurretProjectile
extends Area2D

const ARROW_TEX = preload("res://assets/turrets/projectile_arrow.png")
const CANNONBALL_TEX = preload("res://assets/turrets/projectile_cannonball.png")
const FLAME_TEX = preload("res://assets/turrets/projectile_flame.png")
const ICE_TEX = preload("res://assets/turrets/projectile_ice.png")
const EXPLOSION_SCRIPT = preload("res://scripts/turrets/turret_explosion.gd")

var projectile_type: String = "arrow" # "arrow", "cannonball", "flame", "ice"
var direction: Vector2 = Vector2.RIGHT
var speed: float = 750.0
var damage: float = 25.0
var max_range: float = 400.0
var distance_traveled: float = 0.0
var pierce_left: int = 4
var aoe_radius: float = 100.0
var knockback_force: float = 180.0
var freeze_duration: float = 5.0

var sprite_node: Sprite2D = null
var col_shape: CollisionShape2D = null
var hit_enemies: Array[Node2D] = []

func _ready() -> void:
	add_to_group("turret_projectiles")
	collision_layer = 0
	collision_mask = 2 # Detect enemies (layer 2)
	
	body_entered.connect(_on_body_or_area_entered)
	area_entered.connect(_on_body_or_area_entered)
	
	_setup_visuals()

func init_arrow(dir: Vector2, spd: float, dmg: float, rng: float, prc: int = 4) -> void:
	projectile_type = "arrow"
	direction = dir.normalized()
	speed = spd
	damage = dmg
	max_range = rng
	pierce_left = prc
	rotation = direction.angle()

func init_cannonball(dir: Vector2, spd: float, dmg: float, rng: float, aoe: float = 100.0, kb: float = 240.0) -> void:
	projectile_type = "cannonball"
	direction = dir.normalized()
	speed = spd
	damage = dmg
	max_range = rng
	aoe_radius = aoe
	knockback_force = kb
	rotation = direction.angle()

func init_flame(dir: Vector2, spd: float, dmg: float, rng: float) -> void:
	projectile_type = "flame"
	direction = dir.normalized().rotated(randf_range(-0.10, 0.10))
	speed = spd * randf_range(0.9, 1.1)
	damage = dmg
	max_range = rng
	pierce_left = 99
	rotation = direction.angle()

func init_ice(dir: Vector2, spd: float, dmg: float, rng: float, freeze_time: float = 5.0) -> void:
	projectile_type = "ice"
	direction = dir.normalized()
	speed = spd
	damage = dmg
	max_range = rng
	freeze_duration = freeze_time
	pierce_left = 1
	rotation = direction.angle()

func _setup_visuals() -> void:
	sprite_node = Sprite2D.new()
	sprite_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	col_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	
	if projectile_type == "arrow":
		sprite_node.texture = ARROW_TEX
		sprite_node.scale = Vector2(2.2, 2.2)
		shape.radius = 10.0
	elif projectile_type == "flame":
		sprite_node.texture = FLAME_TEX
		sprite_node.scale = Vector2(2.0, 2.0)
		shape.radius = 14.0
	elif projectile_type == "ice":
		sprite_node.texture = ICE_TEX
		sprite_node.scale = Vector2(2.2, 2.2)
		shape.radius = 11.0
	else:
		sprite_node.texture = CANNONBALL_TEX
		sprite_node.scale = Vector2(2.2, 2.2)
		shape.radius = 12.0
		
	col_shape.shape = shape
	add_child(sprite_node)
	add_child(col_shape)
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	var move_vec = direction * speed * delta
	global_position += move_vec
	distance_traveled += move_vec.length()
	
	if projectile_type == "flame":
		var progress = clamp(distance_traveled / max_range, 0.0, 1.0)
		sprite_node.scale = Vector2(2.0, 2.0) * (1.0 + progress * 0.7)
		sprite_node.modulate = Color(1.0, 1.0, 1.0, 1.0 - progress * 0.5)
	elif projectile_type == "ice":
		rotation += delta * 10.0
	
	if projectile_type == "cannonball":
		# Cannonball explodes if it reaches maximum travel distance limit
		if distance_traveled >= max_range:
			_detonate_cannonball()
			return
	else:
		# Flame, Ice and Arrow expire after max range
		if distance_traveled >= max_range:
			queue_free()
			return

func _on_body_or_area_entered(other: Node) -> void:
	var target = other
	if other is Area2D and other.get_parent():
		target = other.get_parent()
		
	if not is_instance_valid(target) or not target.is_in_group("enemies"):
		return
		
	if target in hit_enemies:
		return
		
	hit_enemies.append(target)
	
	if projectile_type == "cannonball":
		# Cannonball explodes on impact with any enemy
		_detonate_cannonball()
	elif projectile_type == "flame":
		_apply_flame_hit(target)
	elif projectile_type == "ice":
		_apply_ice_hit(target)
	else:
		# Piercing arrow passes through enemies
		_apply_arrow_hit(target)

func _apply_flame_hit(target: Node2D) -> void:
	if target.has_method("take_damage"):
		target.take_damage(damage, false, "burn")
	if target.has_method("apply_burn"):
		target.apply_burn(3.0, 1.5)
	if target.has_method("apply_knockback"):
		target.apply_knockback(direction * 40.0)
		
	GameManager.emit_signal("show_damage_number", global_position + Vector2(randf_range(-8, 8), -18), str(int(damage)), Color(1.0, 0.45, 0.1), false)

func _apply_ice_hit(target: Node2D) -> void:
	if target.has_method("take_damage"):
		target.take_damage(damage, false, "freeze")
	if target.has_method("apply_freeze"):
		target.apply_freeze(freeze_duration)
	if target.has_method("apply_slow"):
		target.apply_slow(0.8, freeze_duration + 1.0)
		
	SoundManager.play_sfx("enemy_hit", 0.12, 1.5)
	GameManager.emit_signal("show_damage_number", global_position + Vector2(randf_range(-10, 10), -24), "FROZEN 5s!", Color(0.2, 0.9, 1.0), true)
	
	pierce_left -= 1
	if pierce_left <= 0:
		queue_free()

func _apply_arrow_hit(target: Node2D) -> void:
	if target.has_method("take_damage"):
		target.take_damage(damage, false, "pierce")
	if target.has_method("apply_knockback"):
		target.apply_knockback(direction * 120.0)
		
	SoundManager.play_sfx("enemy_hit", 0.12)
	GameManager.emit_signal("show_damage_number", global_position + Vector2(randf_range(-10, 10), -20), str(int(damage)), Color(0.9, 0.9, 1.0), false)
	
	pierce_left -= 1
	if pierce_left <= 0:
		queue_free()

func _detonate_cannonball() -> void:
	# Spawn AoE explosion effect
	var parent_node = get_parent()
	if is_instance_valid(parent_node):
		var expl = EXPLOSION_SCRIPT.new()
		parent_node.add_child(expl)
		expl.global_position = global_position
		
	# Play explosion sound and screenshake
	SoundManager.play_sfx("explosion", 0.25)
	GameManager.emit_signal("screen_shake_requested", 7.0, 0.28)
	
	# Damage all enemies in AoE radius
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			var dist = global_position.distance_to(e.global_position)
			if dist <= aoe_radius:
				var falloff = clamp(1.0 - (dist / aoe_radius) * 0.4, 0.6, 1.0)
				var final_dmg = damage * falloff
				var push_dir = (e.global_position - global_position).normalized()
				if push_dir == Vector2.ZERO: push_dir = direction
				
				if e.has_method("apply_knockback"):
					e.apply_knockback(push_dir * knockback_force)
				if e.has_method("take_damage"):
					e.take_damage(final_dmg, false, "explosion")
					
				GameManager.emit_signal("show_damage_number", e.global_position + Vector2(randf_range(-10, 10), -25), str(int(final_dmg)), Color(1.0, 0.5, 0.1), true)
				
	queue_free()
