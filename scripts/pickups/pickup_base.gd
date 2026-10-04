# pickup_base.gd - Base Class for Ground Pickups with Magnet Physics and Bounce
class_name PickupBase
extends Node2D

var pickup_type: String = "bone"
var value: int = 1
var is_attracting: bool = false
var target_pos: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var visual_time: float = 0.0
var bounce_offset: float = 0.0

# Launch physics
var is_launching: bool = false
var launch_target: Vector2 = Vector2.ZERO
var launch_timer: float = 0.0
var launch_duration: float = 0.4
var start_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("pickups")
	visual_time = randf() * TAU

func launch_towards(target: Vector2) -> void:
	is_launching = true
	start_pos = global_position
	launch_target = target
	launch_timer = 0.0

func attract_to(player_pos: Vector2, delta: float) -> void:
	is_attracting = true
	var dir = (player_pos - global_position).normalized()
	var dist = global_position.distance_to(player_pos)
	var pull_speed = clamp(400.0 + (300.0 - dist) * 2.0, 300.0, 900.0)
	
	global_position += dir * pull_speed * delta
	
	# Collection radius check
	if dist < 48.0:
		_on_collected()

func _process(delta: float) -> void:
	visual_time += delta
	bounce_offset = sin(visual_time * 6.0) * 3.0
	
	if is_launching:
		launch_timer += delta
		var t = clamp(launch_timer / launch_duration, 0.0, 1.0)
		var arc = sin(t * PI) * -40.0 # Parabolic arc height
		global_position = start_pos.lerp(launch_target, t) + Vector2(0, arc)
		if t >= 1.0:
			is_launching = false
			
	queue_redraw()

func _on_collected() -> void:
	pass
