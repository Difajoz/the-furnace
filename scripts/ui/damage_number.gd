# damage_number.gd - Floating Combat Text for Hits, Crits, Heals, and Resources
class_name DamageNumber
extends Node2D

var text_content: String = ""
var text_color: Color = Color.WHITE
var is_crit: bool = false
var velocity: Vector2 = Vector2.ZERO
var life_timer: float = 0.0
var max_life: float = 0.75
var scale_val: float = 1.0

func init_number(pos: Vector2, text: String, color: Color, crit: bool = false) -> void:
	global_position = pos
	text_content = text
	text_color = color
	is_crit = crit
	
	velocity = Vector2(randf_range(-30, 30), randf_range(-70, -110))
	scale_val = 1.4 if crit else 1.0
	z_index = 50

func _process(delta: float) -> void:
	life_timer += delta
	global_position += velocity * delta
	velocity.y += 140.0 * delta # Gravity
	
	if life_timer >= max_life:
		queue_free()
		
	queue_redraw()

func _draw() -> void:
	var alpha = clamp(1.0 - (life_timer / max_life), 0.0, 1.0)
	var font = ThemeDB.fallback_font
	if not font:
		return
	var font_size = 18*2 if is_crit else 14*2
	var col = Color(text_color.r, text_color.g, text_color.b, alpha)
	var outline_col = Color(0, 0, 0, alpha * 0.8)
	
	draw_string_outline(font, Vector2(-40, 0), text_content, HORIZONTAL_ALIGNMENT_CENTER, 80, font_size, 3, outline_col)
	draw_string(font, Vector2(-40, 0), text_content, HORIZONTAL_ALIGNMENT_CENTER, 80, font_size, col)
