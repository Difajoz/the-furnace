# coin_pickup.gd - Physical Gold Coin ejected from the Furnace
class_name CoinPickup
extends PickupBase

func _ready() -> void:
	super._ready()
	pickup_type = "coin"

func _on_collected() -> void:
	GameManager.add_coins(value)
	if is_instance_valid(GameManager.player_node):
		GameManager.emit_signal("show_damage_number", global_position + Vector2(0, -12), "+%d COIN" % value, Color(1.0, 0.85, 0.1), false)
	queue_free()

func _draw() -> void:
	var pos = Vector2(0, bounce_offset)
	VisualFactory.draw_ellipse_shape(self, Vector2(0, 8), 8.0, 3.0, Color(0, 0, 0, 0.4))
	var tex = VisualFactory.get_pixel_coin()
	if tex:
		draw_texture_rect(tex, Rect2(pos - Vector2(8, 8), Vector2(16, 16)), false)
	else:
		draw_circle(pos, 6.0, Color(1.0, 0.82, 0.1))
