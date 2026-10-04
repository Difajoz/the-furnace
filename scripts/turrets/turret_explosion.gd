# turret_explosion.gd - 6-Frame animated pixel art explosion effect for cannonballs
class_name TurretExplosion
extends Node2D

const EXPLOSION_TEX = preload("res://assets/turrets/explosion_spritesheet.png")

var sprite: Sprite2D = null
var anim_timer: float = 0.0
var current_frame: int = 0
const TOTAL_FRAMES: int = 6
const FRAME_DURATION: float = 0.065 # ~0.39s total animation duration

func _ready() -> void:
	add_to_group("turret_effects")
	z_index = 15 # Render over entities and floor
	sprite = Sprite2D.new()
	sprite.texture = EXPLOSION_TEX
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.hframes = TOTAL_FRAMES
	sprite.vframes = 1
	sprite.frame = 0
	sprite.scale = Vector2(2.8, 2.8)
	add_child(sprite)

func _process(delta: float) -> void:
	anim_timer += delta
	if anim_timer >= FRAME_DURATION:
		anim_timer -= FRAME_DURATION
		current_frame += 1
		if current_frame >= TOTAL_FRAMES:
			queue_free()
			return
		sprite.frame = current_frame
