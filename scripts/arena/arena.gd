# arena.gd - Survivor Arena Environment, Boundaries, and Floor Rendering
class_name Arena
extends Node2D

var arena_size: Vector2 = Vector2(1600, 1200)

var anim_time: float = 0.0

# Ember Particle Simulation for Foundry Braziers
var embers: Array[Dictionary] = []

func _ready() -> void:
	z_index = -10
	_init_embers()
	_setup_arena_walls()

func _init_embers() -> void:
	embers.clear()
	for i in range(30):
		embers.append({
			"pos": Vector2(randf_range(-700, 700), randf_range(-500, 500)),
			"speed": randf_range(25.0, 60.0),
			"size": randf_range(2.0, 4.5),
			"life": randf_range(0.0, 3.0),
			"max_life": randf_range(2.0, 4.0),
			"color": Color8(255, randi_range(120, 220), 30)
		})

func _process(delta: float) -> void:
	anim_time += delta
	# Update ember particles
	for emb in embers:
		emb["life"] += delta
		emb["pos"].y -= emb["speed"] * delta
		emb["pos"].x += sin(anim_time * 2.0 + emb["speed"]) * 12.0 * delta
		if emb["life"] >= emb["max_life"]:
			emb["life"] = 0.0
			emb["pos"] = Vector2(randf_range(-750, 750), randf_range(-550, 550))
	queue_redraw()

func _setup_arena_walls() -> void:
	# StaticBody2D boundaries around arena perimeter
	var bounds_body = StaticBody2D.new()
	bounds_body.collision_layer = 1
	bounds_body.collision_mask = 3
	add_child(bounds_body)
	
	var half_w = arena_size.x * 0.5
	var half_h = arena_size.y * 0.5
	var wall_thickness = 48.0
	
	# Top Wall
	_add_wall_col(bounds_body, Vector2(0, -half_h - wall_thickness * 0.5), Vector2(arena_size.x + wall_thickness * 2, wall_thickness))
	# Bottom Wall
	_add_wall_col(bounds_body, Vector2(0, half_h + wall_thickness * 0.5), Vector2(arena_size.x + wall_thickness * 2, wall_thickness))
	# Left Wall
	_add_wall_col(bounds_body, Vector2(-half_w - wall_thickness * 0.5, 0), Vector2(wall_thickness, arena_size.y + wall_thickness * 2))
	# Right Wall
	_add_wall_col(bounds_body, Vector2(half_w + wall_thickness * 0.5, 0), Vector2(wall_thickness, arena_size.y + wall_thickness * 2))

func _add_wall_col(body: StaticBody2D, pos: Vector2, size: Vector2) -> void:
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	col.position = pos
	body.add_child(col)

func _draw() -> void:
	var half_w = arena_size.x * 0.5
	var half_h = arena_size.y * 0.5
	
	# Pure Void Outside Arena
	draw_rect(Rect2(-2600, -2000, 5200, 1400), Color.BLACK, true)
	draw_rect(Rect2(-2600, half_h, 5200, 1400), Color.BLACK, true)
	draw_rect(Rect2(-2600, -half_h, 1800, arena_size.y), Color.BLACK, true)
	draw_rect(Rect2(half_w, -half_h, 1800, arena_size.y), Color.BLACK, true)
	
	# Base Obsidian Foundry Floor
	var arena_rect = Rect2(-half_w, -half_h, arena_size.x, arena_size.y)
	draw_rect(arena_rect, Color8(14, 15, 20), true)
	
	# 8-Bit Interlocking Iron & Granite Flagstones (64x64)
	var tile_size = 64.0
	for ty in range(int(-half_h), int(half_h), int(tile_size)):
		for tx in range(int(-half_w), int(half_w), int(tile_size)):
			var seed_v = int(abs(tx * 31 + ty * 57)) % 12
			var tile_col = Color8(22, 24, 32)
			if seed_v == 1 or seed_v == 2:
				tile_col = Color8(28, 30, 40) # Dark basalt paver
			elif seed_v == 3:
				tile_col = Color8(34, 37, 48) # Chiseled iron stone
			elif seed_v == 4:
				tile_col = Color8(18, 20, 26) # Weathered stone
			elif seed_v == 5:
				tile_col = Color8(24, 28, 36)
				
			draw_rect(Rect2(tx + 2, ty + 2, tile_size - 4, tile_size - 4), tile_col, true)
			
			# Iron rivet & masonry cracks on certain pavers
			if seed_v == 6:
				draw_rect(Rect2(tx + 6, ty + 6, 6, 6), Color8(55, 60, 75), true)
				draw_rect(Rect2(tx + tile_size - 12, ty + 6, 6, 6), Color8(55, 60, 75), true)
				draw_rect(Rect2(tx + 6, ty + tile_size - 12, 6, 6), Color8(55, 60, 75), true)
				draw_rect(Rect2(tx + tile_size - 12, ty + tile_size - 12, 6, 6), Color8(55, 60, 75), true)
			elif seed_v == 7:
				draw_line(Vector2(tx + 8, ty + 12), Vector2(tx + 28, ty + 38), Color8(12, 13, 18), 2.0)
				
	# 4 Corner Heavy Anvil Pedestals & Molten Cauldrons
	var corner_spots = [
		Vector2(-half_w + 120, -half_h + 120),
		Vector2(half_w - 120, -half_h + 120),
		Vector2(-half_w + 120, half_h - 120),
		Vector2(half_w - 120, half_h - 120)
	]
	for cp in corner_spots:
		# Stone anvil base
		draw_rect(Rect2(cp.x - 36, cp.y - 36, 72, 72), Color8(10, 11, 14), true)
		draw_rect(Rect2(cp.x - 30, cp.y - 30, 60, 60), Color8(45, 48, 62), true)
		draw_rect(Rect2(cp.x - 20, cp.y - 20, 40, 40), Color8(65, 70, 90), true)
		# Molten bronze fire bowl
		draw_rect(Rect2(cp.x - 14, cp.y - 14, 28, 28), Color8(240, 90, 20), true)
		draw_rect(Rect2(cp.x - 8, cp.y - 8, 16, 16), Color8(255, 220, 40), true)
		
	# Perimeter Wall Grates & Foundry Wall Sconces
	var sconce_spots = [
		Vector2(-half_w + 20, 0),
		Vector2(half_w - 20, 0),
		Vector2(0, -half_h + 20),
		Vector2(0, half_h - 20)
	]
	for sp in sconce_spots:
		draw_rect(Rect2(sp.x - 24, sp.y - 24, 48, 48), Color8(20, 22, 28), true)
		draw_rect(Rect2(sp.x - 16, sp.y - 16, 32, 32), Color8(245, 140, 20), true)
		draw_rect(Rect2(sp.x - 8, sp.y - 8, 16, 16), Color8(255, 235, 80), true)
		
	# Rising Ember Particles
	for emb in embers:
		var alpha = clamp(1.0 - (emb["life"] / emb["max_life"]), 0.0, 1.0)
		var c = emb["color"]
		c.a = alpha
		draw_rect(Rect2(emb["pos"].x, emb["pos"].y, emb["size"], emb["size"]), c, true)

	# 8-BIT STEPPED HAZARD BORDER AROUND CRUCIBLE
	var hazard_size = 200.0
	var step = 55.0
	var hz_col_gold = Color8(255, 195, 25)
	var hz_col_black = Color8(15, 16, 20)
	
	var octagon_points = [
		Vector2(-hazard_size + step, -hazard_size),
		Vector2(hazard_size - step, -hazard_size),
		Vector2(hazard_size, -hazard_size + step),
		Vector2(hazard_size, hazard_size - step),
		Vector2(hazard_size - step, hazard_size),
		Vector2(-hazard_size + step, hazard_size),
		Vector2(-hazard_size, hazard_size - step),
		Vector2(-hazard_size, -hazard_size + step)
	]
	
	# Inner hazard floor fill
	draw_colored_polygon(PackedVector2Array(octagon_points), Color8(12, 13, 18, 220))
	
	# Stepped alternating 8-bit caution striping
	for i in range(octagon_points.size()):
		var p1 = octagon_points[i]
		var p2 = octagon_points[(i + 1) % octagon_points.size()]
		var edge_vec = p2 - p1
		var edge_len = edge_vec.length()
		var num_stripes = int(edge_len / 22.0)
		for s in range(num_stripes):
			var t0 = float(s) / float(num_stripes)
			var t1 = float(s + 1) / float(num_stripes)
			var sp0 = p1.lerp(p2, t0)
			var sp1 = p1.lerp(p2, t1)
			var stripe_col = hz_col_gold if s % 2 == 0 else hz_col_black
			draw_line(sp0, sp1, stripe_col, 10.0)
			
	# Central Iron Crucible Plate
	var inner_box = Rect2(-72, -72, 144, 144)
	draw_rect(inner_box, Color8(10, 11, 15), true)
	draw_rect(inner_box, Color8(240, 110, 20), false, 5.0)
	
	# Foundry Perimeter Wall (Reinforced Bronze & Riveted Iron Frame)
	draw_rect(arena_rect, Color8(65, 70, 85), false, 20.0)
	draw_rect(arena_rect, Color8(210, 145, 35), false, 6.0)
	draw_rect(Rect2(-half_w - 10, -half_h - 10, arena_size.x + 20, arena_size.y + 20), Color8(10, 11, 15), false, 12.0)
