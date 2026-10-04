# water_spray.gd - Pressurized Water Stream & Furnace Cooling Physics
class_name WaterSpray
extends Node2D

var is_spraying: bool = false
var spray_range: float = 360.0
var spray_angle_cone: float = 0.65
var water_consumption_rate: float = 20.0
var base_cooling_power: float = 20.0

var particles: Array[Dictionary] = []
var visual_time: float = 0.0

func _process(delta: float) -> void:
	if not is_spraying and particles.is_empty():
		return
		
	visual_time += delta
	var range_mult = GameManager.spray_range_mult
	var current_reach = spray_range * range_mult
	
	if is_spraying:
		var has_water = GameManager.consume_water(water_consumption_rate * delta)
		if has_water:
			_spawn_spray_particles(6, current_reach)
			_check_cooling_and_hit(current_reach, delta)
			SoundManager.play_sfx("water_spray", 0.3, -10.0)
		else:
			is_spraying = false
			
	_update_spray_particles(delta)
	queue_redraw()

func start_spray() -> void:
	is_spraying = true

func stop_spray() -> void:
	is_spraying = false

func _spawn_spray_particles(count: int, reach: float) -> void:
	var mouse_p = get_global_mouse_position()
	var diff = mouse_p - global_position
	var aim_dir = diff.normalized() if diff.length_squared() > 0.001 else Vector2.RIGHT
	var base_angle = aim_dir.angle()
	
	for i in range(count):
		var spread = randf_range(-spray_angle_cone * 0.5, spray_angle_cone * 0.5)
		var dir = Vector2.from_angle(base_angle + spread)
		var speed = randf_range(reach * 1.6, reach * 2.5)
		
		particles.append({
			"pos": Vector2.ZERO,
			"vel": dir * speed,
			"life": randf_range(0.35, 0.60),
			"max_life": 0.60,
			"size": randf_range(14.0, 28.0),
			"color": Color(0.25, 0.75, 1.0, 0.90)
		})

func _check_cooling_and_hit(reach: float, delta: float) -> void:
	var mouse_p = get_global_mouse_position()
	var diff = mouse_p - global_position
	var aim_dir = diff.normalized() if diff.length_squared() > 0.001 else Vector2.RIGHT
	
	# Check Furnace Cooling - Strictly require close proximity (<= 175px) AND aiming directly at furnace
	if is_instance_valid(GameManager.furnace_node):
		var furnace = GameManager.furnace_node
		var dist_to_furnace_sq = global_position.distance_squared_to(furnace.global_position)
		if dist_to_furnace_sq <= 30625.0: # 175.0 * 175.0
			var to_furnace = (furnace.global_position - global_position).normalized()
			var dot = aim_dir.dot(to_furnace)
			if dot > 0.45:
				var cool_amt = base_cooling_power * delta
				furnace.apply_water_cooling(cool_amt, GameManager.cooling_efficiency)
				
	# Check Enemy Slow / Hydro Damage
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty(): return
	var reach_sq = reach * reach
	for e in enemies:
		if is_instance_valid(e) and e is CharacterBody2D:
			var to_enemy = e.global_position - global_position
			var dist_sq = to_enemy.length_squared()
			if dist_sq <= reach_sq:
				var dist = sqrt(dist_sq)
				var dot = aim_dir.dot(to_enemy / max(0.001, dist))
				if dot > 0.50:
					if e.has_method("apply_slow"):
						e.apply_slow(0.5, 0.4)
					if e.has_method("take_damage"):
						e.take_damage(10.0 * delta, false, "water")

func _update_spray_particles(delta: float) -> void:
	var i = particles.size() - 1
	while i >= 0:
		var p = particles[i]
		p["life"] -= delta
		p["pos"] += p["vel"] * delta
		p["vel"] *= 0.95
		p["size"] += delta * 12.0
		if p["life"] <= 0:
			particles.remove_at(i)
		i -= 1

func _draw() -> void:
	var water_tex = VisualFactory.get_water_drop_texture()
	for p in particles:
		var t = p["life"] / p["max_life"]
		if water_tex:
			var s = p["size"] * 1.8
			draw_texture_rect(water_tex, Rect2(p["pos"] - Vector2(s*0.5, s*0.5), Vector2(s, s)), false, Color(1, 1, 1, t * 0.95))
		else:
			var c = p["color"]
			c.a *= t
			draw_circle(p["pos"], p["size"], c)
