# turret_shoot_effect.gd - Animated muzzle flash and string snap visual effect
class_name TurretShootEffect
extends Node2D

const CANNON_MUZZLE_TEX = preload("res://assets/turrets/cannon_muzzle_flash.png")
const ARROW_SNAP_TEX = preload("res://assets/turrets/arrow_shoot_effect.png")

var sprite: Sprite2D = null
var anim_timer: float = 0.0
var current_frame: int = 0
var total_frames: int = 4
var frame_duration: float = 0.045 # ~0.18s total

func setup(effect_type: String, dir_angle: float) -> void:
	add_to_group("turret_effects")
	z_index = 12
	rotation = dir_angle
	sprite = Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	if effect_type == "cannon":
		sprite.texture = CANNON_MUZZLE_TEX
		sprite.hframes = 4
		sprite.scale = Vector2(2.4, 2.4)
		sprite.offset = Vector2(16, 0)
	elif effect_type == "flame":
		sprite.texture = CANNON_MUZZLE_TEX
		sprite.hframes = 4
		sprite.scale = Vector2(1.8, 1.8)
		sprite.offset = Vector2(14, 0)
		sprite.modulate = Color(1.0, 0.5, 0.1, 0.9)
	elif effect_type == "ice":
		sprite.texture = ARROW_SNAP_TEX
		sprite.hframes = 4
		sprite.scale = Vector2(2.2, 2.2)
		sprite.offset = Vector2(10, 0)
		sprite.modulate = Color(0.3, 0.9, 1.0, 0.9)
	else:
		sprite.texture = ARROW_SNAP_TEX
		sprite.hframes = 4
		sprite.scale = Vector2(2.0, 2.0)
		sprite.offset = Vector2(8, 0)
		
	sprite.frame = 0
	add_child(sprite)

func _process(delta: float) -> void:
	anim_timer += delta
	if anim_timer >= frame_duration:
		anim_timer -= frame_duration
		current_frame += 1
		if current_frame >= total_frames:
			queue_free()
			return
		if is_instance_valid(sprite):
			sprite.frame = current_frame
