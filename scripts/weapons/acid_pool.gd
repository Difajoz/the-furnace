# acid_pool.gd - Lingering Acid / Toxic Slime Hazard for Enemies and Player
class_name AcidPool
extends Node2D

var duration: float = 5.0
var damage_per_sec: float = 18.0
var radius: float = 48.0
var visual_time: float = 0.0
var tick_timer: float = 0.0
var is_enemy_hazard: bool = false

func _ready() -> void:
	add_to_group("hazards")

func _process(delta: float) -> void:
	visual_time += delta
	duration -= delta
	tick_timer += delta
	
	if tick_timer >= 0.2:
		tick_timer = 0.0
		_tick_damage(0.2)
		
	if duration <= 0.0:
		queue_free()
		
	queue_redraw()

func _tick_damage(amount_time: float) -> void:
	if is_enemy_hazard:
		# Hazard affects Player
		if is_instance_valid(GameManager.player_node):
			var dist = global_position.distance_to(GameManager.player_node.global_position)
			if dist <= radius + 15.0:
				GameManager.damage_player(damage_per_sec * amount_time)
				if GameManager.player_node.has_method("apply_slow"):
					GameManager.player_node.apply_slow(0.35, 0.4)
				if GameManager.player_node.has_method("apply_poison"):
					GameManager.player_node.apply_poison(damage_per_sec * 0.4, 2.0)
	else:
		# Player weapon pool affects Enemies
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if is_instance_valid(e) and e.has_method("take_damage"):
				var dist = global_position.distance_to(e.global_position)
				if dist <= radius:
					if e.has_method("apply_slow"):
						e.apply_slow(0.35, 0.4)
					e.take_damage(damage_per_sec * amount_time, false, "acid")

func _draw() -> void:
	var alpha = clamp(duration / 1.0, 0.0, 1.0)
	var bubble = sin(visual_time * 8.0) * 3.0
	
	if is_enemy_hazard:
		# Toxic Purple / Slime Green Hazard puddle from monsters & bosses
		draw_circle(Vector2.ZERO, radius + bubble, Color(0.45, 0.1, 0.55, 0.40 * alpha))
		draw_circle(Vector2.ZERO, radius * 0.75, Color(0.25, 0.75, 0.15, 0.35 * alpha))
		for pt in [Vector2(-10, -6), Vector2(12, 5), Vector2(-5, 10), Vector2(8, -8)]:
			var b_size = 2.5 + sin(visual_time * 9.0 + pt.x) * 2.0
			draw_circle(pt, b_size, Color(0.8, 0.3, 0.9, 0.7 * alpha))
	else:
		# Player Acid pool
		draw_circle(Vector2.ZERO, radius + bubble, Color(0.2, 0.85, 0.1, 0.35 * alpha))
		draw_circle(Vector2.ZERO, radius * 0.7, Color(0.3, 0.95, 0.2, 0.25 * alpha))
		for pt in [Vector2(-12, -8), Vector2(14, 6), Vector2(-6, 12)]:
			var b_size = 3.0 + sin(visual_time * 10.0 + pt.x) * 2.0
			draw_circle(pt, b_size, Color(0.6, 1.0, 0.4, 0.6 * alpha))

