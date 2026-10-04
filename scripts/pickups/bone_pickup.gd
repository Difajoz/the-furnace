# bone_pickup.gd - Bone resource dropped by slain monsters (5s Despawn, Compact 50% Scale, Bag Cap)
class_name BonePickup
extends PickupBase

const DESPAWN_TIME: float = 5.0
var decay_timer: float = DESPAWN_TIME
var full_bag_alert_timer: float = 0.0

func _ready() -> void:
	super._ready()
	pickup_type = "bone"
	decay_timer = DESPAWN_TIME

func attract_to(player_pos: Vector2, delta: float) -> void:
	# Only attract if player has carrying capacity space
	if not GameManager.can_pickup_bone():
		is_attracting = false
		return
	super.attract_to(player_pos, delta)

func _process(delta: float) -> void:
	super._process(delta)
	decay_timer -= delta
	
	if full_bag_alert_timer > 0.0:
		full_bag_alert_timer -= delta
	
	# Blink rapidly during the final 1.5 seconds before despawning
	if decay_timer <= 1.5:
		var blink = fposmod(decay_timer * 10.0, 1.0) > 0.5
		modulate = Color(1.0, 1.0, 1.0, 0.3 if blink else 1.0)
	else:
		modulate = Color.WHITE
		
	if decay_timer <= 0.0:
		queue_free()

func _on_collected() -> void:
	if not GameManager.can_pickup_bone():
		if full_bag_alert_timer <= 0.0 and is_instance_valid(GameManager.player_node):
			full_bag_alert_timer = 1.0
			GameManager.emit_signal("show_damage_number", global_position + Vector2(0, -16), "BAG FULL!", Color(1.0, 0.4, 0.4), false)
			SoundManager.play_sfx("button_click", 0.2, -4.0)
		return
		
	var added = GameManager.add_bones(value)
	if added > 0:
		if is_instance_valid(GameManager.player_node):
			GameManager.emit_signal("show_damage_number", global_position + Vector2(0, -12), "+%d BONE" % added, Color(0.9, 0.85, 0.7), false)
		queue_free()

func _draw() -> void:
	var pos = Vector2(0, bounce_offset)
	# 50% smaller pixel bone (24x24 px)
	var tex = VisualFactory.get_pixel_bone()
	if tex:
		draw_texture_rect(tex, Rect2(pos - Vector2(12, 12), Vector2(24, 24)), false)
	else:
		draw_line(pos + Vector2(-9, 0), pos + Vector2(9, 0), Color(0.95, 0.92, 0.85), 7.0)
		draw_circle(pos + Vector2(-9, -3), 3.0, Color(0.95, 0.92, 0.85))
		draw_circle(pos + Vector2(-9, 3), 3.0, Color(0.95, 0.92, 0.85))
		draw_circle(pos + Vector2(9, -3), 3.0, Color(0.95, 0.92, 0.85))
		draw_circle(pos + Vector2(9, 3), 3.0, Color(0.95, 0.92, 0.85))
