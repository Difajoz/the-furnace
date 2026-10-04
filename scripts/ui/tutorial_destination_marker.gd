# tutorial_destination_marker.gd - Floating In-World Waypoint & Objective Indicator
class_name TutorialDestinationMarker
extends Node2D

var target_node: Node2D = null
var target_pos: Vector2 = Vector2.ZERO
var marker_text: String = "OBJECTIVE"
var marker_color: Color = Color8(255, 215, 50)
var vertical_offset: float = -60.0
var show_distance: bool = false

var anim_timer: float = 0.0

func setup_target_node(node: Node2D, text: String, color: Color = Color8(255, 215, 50), offset_y: float = -60.0) -> void:
	target_node = node
	marker_text = text
	marker_color = color
	vertical_offset = offset_y
	if is_instance_valid(target_node):
		global_position = target_node.global_position + Vector2(0, vertical_offset)

func setup_target_position(pos: Vector2, text: String, color: Color = Color8(255, 215, 50), offset_y: float = -40.0) -> void:
	target_node = null
	target_pos = pos
	marker_text = text
	marker_color = color
	vertical_offset = offset_y
	global_position = target_pos + Vector2(0, vertical_offset)

func set_text(text: String, color: Color = Color.WHITE) -> void:
	marker_text = text
	if color != Color.WHITE:
		marker_color = color

func _process(delta: float) -> void:
	anim_timer += delta
	
	var desired_pos = target_pos
	if is_instance_valid(target_node) and not target_node.is_queued_for_deletion():
		desired_pos = target_node.global_position
	elif target_node != null and target_node.is_queued_for_deletion():
		queue_free()
		return
		
	var dest = desired_pos + Vector2(0, vertical_offset)
	global_position = global_position.lerp(dest, 14.0 * delta)
	
	queue_redraw()

func _draw() -> void:
	var font = ThemeDB.fallback_font
	if not font: return
	
	var bounce = sin(anim_timer * 6.5) * 6.0
	var pulse = 0.9 + sin(anim_timer * 8.0) * 0.1
	
	# Determine distance to player if requested
	var display_str = marker_text
	if show_distance and is_instance_valid(GameManager.player_node):
		var d = int(global_position.distance_to(GameManager.player_node.global_position) / 10.0)
		if d > 12:
			display_str += " (%dm)" % d
			
	var font_size = 20
	var text_w = font.get_string_size(display_str, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
	var pad_x = 14.0
	var pad_y = 6.0
	var box_w = max(100.0, text_w + pad_x * 2)
	var box_h = 32.0
	var box_rect = Rect2(-box_w * 0.5, -box_h + bounce - 14.0, box_w, box_h)
	
	# 1. Dark Shadow / Backing
	draw_rect(box_rect.grow(3.0), Color8(10, 12, 16, 220), true)
	
	# 2. Main Box with Highlight Border
	var bg_col = Color8(18, 22, 32, 245)
	draw_rect(box_rect, bg_col, true)
	
	# Glowing Border
	var border_col = Color(marker_color.r, marker_color.g, marker_color.b, pulse)
	draw_rect(box_rect, border_col, false, 2.5)
	
	# 3. Label Text
	var text_pos = Vector2(-box_w * 0.5 + pad_x, box_rect.position.y + 22.0)
	draw_string(font, text_pos, display_str, HORIZONTAL_ALIGNMENT_CENTER, box_w - pad_x * 2, font_size, marker_color)
	
	# 4. Animated Bouncing Arrow (Pointing downward at the target)
	var arrow_tip_y = bounce - 4.0
	var p1 = Vector2(0, arrow_tip_y)
	var p2 = Vector2(-9.0, arrow_tip_y - 10.0)
	var p3 = Vector2(9.0, arrow_tip_y - 10.0)
	
	# Shadow
	draw_colored_polygon(PackedVector2Array([p1 + Vector2(0, 1), p2 + Vector2(0, 1), p3 + Vector2(0, 1)]), Color.BLACK)
	# Glowing Arrow
	draw_colored_polygon(PackedVector2Array([p1, p2, p3]), marker_color)
	# Outline
	draw_polyline(PackedVector2Array([p2, p1, p3]), Color.WHITE, 1.5)
