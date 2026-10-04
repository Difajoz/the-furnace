# game_camera.gd - Dynamic Tracking Camera with Smooth Mouse Lookahead and Screen Shake
class_name GameCamera
extends Camera2D

var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var target_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	zoom = Vector2(1.15, 1.15)
	GameManager.screen_shake_requested.connect(add_screen_shake)

func reset_camera() -> void:
	shake_intensity = 0.0
	shake_duration = 0.0
	offset = Vector2.ZERO
	target_offset = Vector2.ZERO
	if is_instance_valid(GameManager.player_node):
		global_position = GameManager.player_node.global_position

func add_screen_shake(intensity: float, duration: float) -> void:
	shake_intensity = max(shake_intensity, intensity)
	shake_duration = max(shake_duration, duration)

func _process(delta: float) -> void:
	# Follow player with smooth lookahead
	if is_instance_valid(GameManager.player_node):
		var p_pos = GameManager.player_node.global_position
		var m_pos = get_global_mouse_position()
		var lookahead = (m_pos - p_pos) * 0.08
		var target_pos = p_pos + lookahead
		
		# Clamp camera comfortably within arena bounds
		var clamped_x = clamp(target_pos.x, -450.0, 450.0)
		var clamped_y = clamp(target_pos.y, -320.0, 320.0)
		var desired_pos = Vector2(clamped_x, clamped_y)
		
		global_position = global_position.lerp(desired_pos, 10.0 * delta)
		
	# Apply Screen Shake
	if shake_duration > 0.0:
		shake_duration -= delta
		offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
		shake_intensity = move_toward(shake_intensity, 0.0, 30.0 * delta)
	else:
		offset = Vector2.ZERO
