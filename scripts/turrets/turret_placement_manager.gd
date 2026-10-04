# turret_placement_manager.gd - Real-time Turret Placement System with Bounds Validation & Hologram Preview
class_name TurretPlacementManager
extends Node2D

const TURRET_BASE_SCRIPT = preload("res://scripts/turrets/turret_base.gd")
const ARROW_BASE_TEX = preload("res://assets/turrets/arrow_turret_base.png")
const ARROW_HEAD_TEX = preload("res://assets/turrets/arrow_turret_head.png")
const CANNON_BASE_TEX = preload("res://assets/turrets/cannon_turret_base.png")
const CANNON_HEAD_TEX = preload("res://assets/turrets/cannon_turret_head.png")
const FLAME_BASE_TEX = preload("res://assets/turrets/flame_turret_base.png")
const FLAME_HEAD_TEX = preload("res://assets/turrets/flame_turret_head.png")
const ICE_BASE_TEX = preload("res://assets/turrets/ice_turret_base.png")
const ICE_HEAD_TEX = preload("res://assets/turrets/ice_turret_head.png")

# Boundaries
const ARENA_LIMIT_X: float = 710.0
const ARENA_LIMIT_Y: float = 510.0
const FURNACE_EXCLUSION_RADIUS: float = 135.0
const MIN_TURRET_SPACING: float = 38.0

var is_placement_active: bool = false
var current_turret_item: Dictionary = {}
var is_position_valid: bool = false
var preview_pos: Vector2 = Vector2.ZERO

# Ghost preview nodes
var ghost_container: Node2D = null
var ghost_base_sprite: Sprite2D = null
var ghost_head_sprite: Sprite2D = null

func _ready() -> void:
	z_index = 20
	_setup_ghost_preview()
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.turret_inventory_updated.connect(_on_inventory_updated)

func _setup_ghost_preview() -> void:
	ghost_container = Node2D.new()
	ghost_container.visible = false
	add_child(ghost_container)
	
	ghost_base_sprite = Sprite2D.new()
	ghost_base_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ghost_base_sprite.scale = Vector2(2.5, 2.5)
	ghost_container.add_child(ghost_base_sprite)
	
	ghost_head_sprite = Sprite2D.new()
	ghost_head_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ghost_head_sprite.scale = Vector2(2.5, 2.5)
	ghost_head_sprite.hframes = 4
	ghost_head_sprite.frame = 0
	ghost_head_sprite.z_index = 1
	ghost_container.add_child(ghost_head_sprite)

func _on_wave_started(_wave: int) -> void:
	# Keep turrets in inventory across waves; cancel placement mode if open
	if is_placement_active:
		_cancel_placement()

func _on_inventory_updated() -> void:
	if is_placement_active:
		if GameManager.turret_inventory.is_empty():
			_cancel_placement()
		else:
			_select_active_turret(GameManager.turret_inventory[0])

func toggle_placement_mode() -> void:
	if is_placement_active:
		_cancel_placement()
	else:
		_start_placement()

func _start_placement() -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
		
	if GameManager.turret_inventory.is_empty():
		SoundManager.play_sfx("button_click", 0.1, 0.6)
		if is_instance_valid(GameManager.player_node):
			GameManager.emit_signal("show_damage_number", GameManager.player_node.global_position + Vector2(0, -50), "NO TURRETS IN INVENTORY!", Color(1.0, 0.4, 0.4), true)
		return
		
	is_placement_active = true
	_select_active_turret(GameManager.turret_inventory[0])
	ghost_container.visible = true
	SoundManager.play_sfx("button_click", 0.1, 1.2)
	GameManager.emit_signal("placement_mode_toggled", true)

func _cancel_placement() -> void:
	is_placement_active = false
	ghost_container.visible = false
	current_turret_item = {}
	queue_redraw()
	GameManager.emit_signal("placement_mode_toggled", false)

func _select_active_turret(item: Dictionary) -> void:
	current_turret_item = item
	var t_type = item.get("turret_type", "ballista")
	
	if t_type == "cannon":
		ghost_base_sprite.texture = CANNON_BASE_TEX
		ghost_head_sprite.texture = CANNON_HEAD_TEX
	elif t_type == "flame":
		ghost_base_sprite.texture = FLAME_BASE_TEX
		ghost_head_sprite.texture = FLAME_HEAD_TEX
	elif t_type == "ice":
		ghost_base_sprite.texture = ICE_BASE_TEX
		ghost_head_sprite.texture = ICE_HEAD_TEX
	else:
		ghost_base_sprite.texture = ARROW_BASE_TEX
		ghost_head_sprite.texture = ARROW_HEAD_TEX

func _unhandled_input(event: InputEvent) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
		
	# Toggle placement via Key T
	if event is InputEventKey and event.pressed and not event.is_echo():
		var code = event.keycode if event.keycode != KEY_NONE else event.physical_keycode
		if code == KEY_T:
			toggle_placement_mode()
			get_viewport().set_input_as_handled()
			return
		elif code == KEY_ESCAPE and is_placement_active:
			_cancel_placement()
			get_viewport().set_input_as_handled()
			return

	if not is_placement_active:
		return
		
	# Confirm or cancel via Mouse
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_confirm_placement()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_placement()
			get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if not is_placement_active:
		return
		
	if GameManager.current_state != GameManager.GameState.PLAYING:
		_cancel_placement()
		return
		
	preview_pos = get_global_mouse_position()
	ghost_container.global_position = preview_pos
	
	# Validate position
	is_position_valid = _check_position_valid(preview_pos)
	
	# Update ghost tints
	var tint_color = Color(0.3, 1.0, 0.4, 0.75) if is_position_valid else Color(1.0, 0.25, 0.25, 0.75)
	ghost_base_sprite.modulate = tint_color
	ghost_head_sprite.modulate = tint_color
	
	queue_redraw()

func _check_position_valid(pos: Vector2) -> bool:
	# 1. Level Boundary Check: Inside arena limits
	if abs(pos.x) > ARENA_LIMIT_X or abs(pos.y) > ARENA_LIMIT_Y:
		return false
		
	# 2. Furnace Exclusion Zone: Cannot place inside the furnace
	var furnace_pos = Vector2.ZERO
	if is_instance_valid(GameManager.furnace_node):
		furnace_pos = GameManager.furnace_node.global_position
	if pos.distance_to(furnace_pos) < FURNACE_EXCLUSION_RADIUS:
		return false
		
	# 3. Turret Spacing Check: Cannot stack on existing turrets
	var existing_turrets = get_tree().get_nodes_in_group("turrets")
	for t in existing_turrets:
		if is_instance_valid(t) and not t.is_queued_for_deletion():
			if pos.distance_to(t.global_position) < MIN_TURRET_SPACING:
				return false
				
	return true

func _try_confirm_placement() -> void:
	if not is_position_valid:
		SoundManager.play_sfx("button_click", 0.1, 0.5)
		var reason = "OUTSIDE LEVEL!" if (abs(preview_pos.x) > ARENA_LIMIT_X or abs(preview_pos.y) > ARENA_LIMIT_Y) else "CANNOT PLACE IN FURNACE!"
		GameManager.emit_signal("show_damage_number", preview_pos + Vector2(0, -30), reason, Color(1.0, 0.2, 0.2), true)
		return
		
	# Spawn Turret Entity
	var t_type = current_turret_item.get("turret_type", "ballista")
	var turret = TURRET_BASE_SCRIPT.new()
	var parent_target = get_parent()
	if not is_instance_valid(parent_target):
		parent_target = get_tree().current_scene
		
	parent_target.add_child(turret)
	turret.global_position = preview_pos
	turret.configure_turret(t_type)
	
	# Record into placed turrets for run persistence
	GameManager.record_placed_turret(t_type, preview_pos)
	
	# Play placement audio & feedback
	SoundManager.play_sfx("bone_pickup", 0.15, 0.65)
	GameManager.emit_signal("show_damage_number", preview_pos + Vector2(0, -40), "%s PLACED!" % current_turret_item.get("name", "TURRET").to_upper(), Color(0.9, 0.8, 0.2), true)
	
	# Consume turret from inventory
	GameManager.consume_turret_from_inventory()
	
	# If player has another turret in inventory, stay in placement mode for the next one!
	if not GameManager.turret_inventory.is_empty():
		_select_active_turret(GameManager.turret_inventory[0])
	else:
		_cancel_placement()

func _draw() -> void:
	if not is_placement_active:
		return
		
	var t_type = current_turret_item.get("turret_type", "ballista")
	var range_radius = 380.0
	if t_type == "cannon":
		range_radius = 290.0
	elif t_type == "flame":
		range_radius = 190.0
	elif t_type == "ice":
		range_radius = 280.0
	var ring_col = Color(0.3, 1.0, 0.4, 0.4) if is_position_valid else Color(1.0, 0.25, 0.25, 0.4)
	
	# Draw range radius around cursor
	draw_arc(to_local(preview_pos), range_radius, 0, TAU, 48, ring_col, 2.5)
	draw_arc(to_local(preview_pos), range_radius * 0.98, 0, TAU, 32, ring_col.lightened(0.2), 1.0)
	
	# Draw Furnace exclusion ring to clearly show safe zone if cursor is close
	var furnace_pos = Vector2.ZERO
	if is_instance_valid(GameManager.furnace_node):
		furnace_pos = GameManager.furnace_node.global_position
	var f_dist = preview_pos.distance_to(furnace_pos)
	if f_dist < FURNACE_EXCLUSION_RADIUS * 2.2:
		var warn_col = Color(1.0, 0.2, 0.2, 0.5 + sin(Time.get_ticks_msec() * 0.01) * 0.2)
		draw_arc(to_local(furnace_pos), FURNACE_EXCLUSION_RADIUS, 0, TAU, 40, warn_col, 3.0)
