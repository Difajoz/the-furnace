# weapon_base.gd - Modular Auto-Targeting Weapon Mounted on Player
class_name WeaponBase
extends Node2D

var weapon_data: Dictionary = {}
var slot_index: int = 0
var orbit_radius: float = 38.0
var base_angle: float = 0.0

# Combat State
var fire_timer: float = 0.0
var target_enemy: Node2D = null
var current_aim_dir: Vector2 = Vector2.RIGHT
var recoil_offset: float = 0.0
var muzzle_flash_timer: float = 0.0
var laser_active: bool = false
var laser_hit_pos: Vector2 = Vector2.ZERO

# Melee swing state
var is_melee_swinging: bool = false
var melee_swing_t: float = 0.0
var melee_swing_angle: float = 0.0

# Orbital state
var orbital_angle: float = 0.0

func init_weapon(data: Dictionary, slot: int, total_slots: int) -> void:
	weapon_data = data
	slot_index = slot
	base_angle = (float(slot) / float(max(1, total_slots))) * TAU
	recoil_offset = 0.0
	fire_timer = randf_range(0.0, 0.2) # Stagger initial shots

func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
		
	var special = weapon_data.get("special", "")
	
	if special == "orbital":
		_process_orbital(delta)
	elif special in ["melee_swing", "slash", "frost_slash"]:
		_process_melee_swing(delta)
	else:
		_process_ranged(delta)
		
	# Recoil recovery
	if recoil_offset > 0.0:
		recoil_offset = max(0.0, recoil_offset - delta * 45.0)
	if muzzle_flash_timer > 0.0:
		muzzle_flash_timer -= delta
		
	queue_redraw()

var target_scan_timer: float = 0.0

func _process_ranged(delta: float) -> void:
	var special = weapon_data.get("special", "")
	var range_val = weapon_data.get("range", 400.0)
	var range_sq = range_val * range_val
	
	if is_instance_valid(GameManager.locked_target) and not GameManager.locked_target.is_queued_for_deletion():
		target_enemy = GameManager.locked_target
	else:
		# Throttled target scanning
		target_scan_timer -= delta
		var target_invalid = not is_instance_valid(target_enemy) or target_enemy.is_queued_for_deletion()
		if not target_invalid:
			if global_position.distance_squared_to(target_enemy.global_position) > range_sq:
				target_invalid = true
				
		if target_invalid or target_scan_timer <= 0.0:
			target_scan_timer = randf_range(0.08, 0.12)
			target_enemy = _find_best_target(range_val)
		
	if is_instance_valid(target_enemy):
		current_aim_dir = (target_enemy.global_position - global_position).normalized()
	
	# Compute effective fire rate
	var base_rate = weapon_data.get("fire_rate", 1.0)
	var effective_rate = base_rate * GameManager.attack_speed_mult
	var fire_interval = 1.0 / max(0.1, effective_rate)
	
	fire_timer += delta
	
	if special == "laser":
		_process_laser(delta)
	elif fire_timer >= fire_interval:
		if is_instance_valid(target_enemy):
			fire_timer = 0.0
			_shoot()

func _process_laser(delta: float) -> void:
	var range_val = weapon_data.get("range", 500.0)
	if is_instance_valid(target_enemy):
		laser_active = true
		var dmg = weapon_data.get("damage", 12.0) * GameManager.get_effective_damage_mult() * delta * 5.0
		var is_crit = randf() < (weapon_data.get("crit_chance", 0.05) + GameManager.crit_chance)
		if is_crit:
			dmg *= (weapon_data.get("crit_mult", 1.5) + GameManager.crit_mult)
		
		# Trace laser line to hit enemies
		var end_pos = global_position + current_aim_dir * range_val
		laser_hit_pos = end_pos
		
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if is_instance_valid(e) and e.has_method("take_damage"):
				var to_e = e.global_position - global_position
				var proj_len = to_e.dot(current_aim_dir)
				if proj_len > 0 and proj_len <= range_val:
					var perp_dist = (to_e - current_aim_dir * proj_len).length()
					if perp_dist < 30.0:
						e.take_damage(dmg, is_crit, "laser")
	else:
		laser_active = false

func _shoot() -> void:
	recoil_offset = 6.0
	muzzle_flash_timer = 0.08
	
	var special = weapon_data.get("special", "")
	var id = weapon_data.get("id", "pistol")
	var projectiles_count = weapon_data.get("projectiles", 1)
	var spread = weapon_data.get("spread", 0.05)
	var base_dmg = weapon_data.get("damage", 10.0) * GameManager.get_effective_damage_mult()
	
	# Bone scaling bonus
	if special == "bone_scaling":
		base_dmg *= (1.0 + GameManager.bones_held * 0.02)
		
	# Heat Frenzy bonus
	if GameManager.heat_frenzy_bonus > 0.0 and is_instance_valid(GameManager.furnace_node):
		if GameManager.furnace_node.temperature / GameManager.furnace_node.max_temperature >= 0.65:
			base_dmg *= (1.0 + GameManager.heat_frenzy_bonus * 0.3)
			
	var crit_chance = weapon_data.get("crit_chance", 0.05) + GameManager.crit_chance
	var crit_mult = weapon_data.get("crit_mult", 1.5) + GameManager.crit_mult
	var is_crit = randf() < crit_chance
	if is_crit:
		base_dmg *= crit_mult
		
	var spd = weapon_data.get("bullet_speed", 600.0)
	var rng = weapon_data.get("range", 450.0)
	var prc = weapon_data.get("pierce", 1)
	var kb = weapon_data.get("knockback", 80.0)
	var col = weapon_data.get("color", Color(1.0, 0.9, 0.3))
	var bnc = weapon_data.get("bounces", 0)
	var aoe = weapon_data.get("aoe_radius", 0.0)
	
	var base_angle_aim = current_aim_dir.angle()
	
	for i in range(projectiles_count):
		var angle_offset = 0.0
		if projectiles_count > 1:
			angle_offset = lerp(-spread, spread, float(i) / float(projectiles_count - 1))
		else:
			angle_offset = randf_range(-spread, spread)
			
		var shoot_dir = Vector2.from_angle(base_angle_aim + angle_offset)
		var proj = ProjectileBase.new()
		proj.init_projectile(shoot_dir, spd, base_dmg, rng, prc, kb, is_crit, special, col, bnc, aoe)
		proj.source_weapon_id = id
		if weapon_data.has("slow_factor"):
			proj.slow_factor = weapon_data.get("slow_factor", 0.40)
		
		# Configure special split weapons
		if special == "cluster_bomb":
			proj.configure_split(4, rng * 0.65)
		elif special == "split_arcane":
			proj.configure_split(3, 180.0)
			
		# Spawn at muzzle position
		var muzzle_pos = global_position + shoot_dir * 18.0
		get_tree().current_scene.add_child(proj)
		proj.global_position = muzzle_pos
		
	# Play sound
	_play_weapon_sfx(id)

func _process_melee_swing(delta: float) -> void:
	var special = weapon_data.get("special", "melee_swing")
	var id = weapon_data.get("id", "dagger")
	var is_dagger = (id == "dagger")
	var reach = 100.0 if is_dagger else (160.0 if id in ["frost_scythe", "greatsword"] else 130.0)
	
	# Aim at locked target or nearest enemy within reach
	var target = _find_best_target(reach + 30.0)
	if is_instance_valid(target):
		current_aim_dir = (target.global_position - global_position).normalized()
	
	var base_rate = weapon_data.get("fire_rate", 1.0) * GameManager.attack_speed_mult
	var swing_interval = 1.0 / max(0.1, base_rate)
	
	fire_timer += delta
	# ONLY swing / stab if there is actually an enemy within melee range!
	if fire_timer >= swing_interval:
		if is_instance_valid(target):
			fire_timer = 0.0
			is_melee_swinging = true
			melee_swing_t = 0.0
			SoundManager.play_sfx("melee_swing", 0.2)
			_execute_melee_hit()
		else:
			# Keep timer ready for immediate strike when enemy enters range
			fire_timer = swing_interval
		
	if is_melee_swinging:
		melee_swing_t += delta * 6.0
		if melee_swing_t >= 1.0:
			is_melee_swinging = false

func _execute_melee_hit() -> void:
	var special = weapon_data.get("special", "melee_swing")
	var id = weapon_data.get("id", "dagger")
	var is_dagger = (id == "dagger")
	var reach = 100.0 if is_dagger else (160.0 if id in ["frost_scythe", "greatsword"] else 130.0)
	var reach_sq = reach * reach
	var dmg = weapon_data.get("damage", 45.0) * GameManager.get_effective_damage_mult()
	var is_crit = randf() < (weapon_data.get("crit_chance", 0.1) + GameManager.crit_chance)
	if is_crit:
		dmg *= (weapon_data.get("crit_mult", 2.0) + GameManager.crit_mult)
		
	var kb = weapon_data.get("knockback", 400.0)
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty(): return
	
	for e in enemies:
		if is_instance_valid(e) and e.has_method("take_damage"):
			var dist_sq = global_position.distance_squared_to(e.global_position)
			if dist_sq <= reach_sq:
				var push_dir = (e.global_position - global_position).normalized()
				if e.has_method("apply_knockback"):
					e.apply_knockback(push_dir * kb)
				if special == "frost_slash" and e.has_method("apply_slow"):
					e.apply_slow(0.6, 3.0)
				e.take_damage(dmg, is_crit, "melee")
				if GameManager.lifesteal > 0.0:
					GameManager.heal_player(dmg * GameManager.lifesteal)

func _process_orbital(delta: float) -> void:
	orbital_angle += delta * 4.5
	var orbit_r = weapon_data.get("range", 110.0)
	var blades = weapon_data.get("projectiles", 3)
	var dmg = weapon_data.get("damage", 18.0) * GameManager.get_effective_damage_mult() * delta * 4.0
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty(): return
	for b in range(blades):
		var ang = orbital_angle + (float(b) / float(blades)) * TAU
		var blade_pos = global_position + Vector2.from_angle(ang) * orbit_r
		
		for e in enemies:
			if is_instance_valid(e) and e.has_method("take_damage"):
				var dist_sq = blade_pos.distance_squared_to(e.global_position)
				if dist_sq < 1024.0: # 32.0 * 32.0
					var push_dir = (e.global_position - global_position).normalized()
					if e.has_method("apply_knockback"):
						e.apply_knockback(push_dir * 120.0 * delta * 10.0)
					e.take_damage(dmg, false, "orbital")

func _find_best_target(max_range: float) -> Node2D:
	if is_instance_valid(GameManager.locked_target) and not GameManager.locked_target.is_queued_for_deletion():
		return GameManager.locked_target
		
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null
	var best_target: Node2D = null
	var min_dist_sq: float = max_range * max_range
	
	for e in enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			var dist_sq = global_position.distance_squared_to(e.global_position)
			if dist_sq < min_dist_sq:
				min_dist_sq = dist_sq
				best_target = e
	return best_target

func _play_weapon_sfx(id: String) -> void:
	match id:
		"pistol": SoundManager.play_sfx("shoot_pistol", 0.15)
		"smg": SoundManager.play_sfx("shoot_smg", 0.15)
		"shotgun", "magma_shotgun": SoundManager.play_sfx("shoot_shotgun", 0.2)
		"assault_rifle": SoundManager.play_sfx("shoot_rifle", 0.15)
		"sniper", "glacier_rifle": SoundManager.play_sfx("shoot_sniper", 0.1)
		"gatling_minigun": SoundManager.play_sfx("shoot_minigun", 0.12)
		"flamethrower": SoundManager.play_sfx("water_spray", 0.2, -6.0)
		"rocket_launcher", "cluster_mortar": SoundManager.play_sfx("shoot_rocket", 0.15)
		"plasma_blaster", "twin_dragon": SoundManager.play_sfx("shoot_plasma", 0.15)
		"void_black_hole_cannon", "chrono_blaster": SoundManager.play_sfx("shoot_vortex", 0.15)
		"tesla_coil", "thunder_bow", "chain_bolter": SoundManager.play_sfx("shoot_lightning", 0.2)
		"bone_crossbow": SoundManager.play_sfx("shoot_bone", 0.15)
		"bone_boomerang": SoundManager.play_sfx("shoot_boomerang", 0.15)
		"shuriken_spinner", "saw_launcher": SoundManager.play_sfx("shoot_shuriken", 0.15)
		"flame_revolver", "ricochet_revolver", "dragon_breath": SoundManager.play_sfx("shoot_revolver", 0.15)
		"arcane_missiles", "arcane_splitter", "arcane_railgun": SoundManager.play_sfx("shoot_arcane", 0.15)
		"toxic_needle", "inferno_repeater": SoundManager.play_sfx("shoot_smg", 0.2, 2.0)
		"plasma_blaster", "twin_dragon", "frostfire_cannon": SoundManager.play_sfx("shoot_plasma", 0.15)
		"void_black_hole_cannon", "chrono_blaster", "gravity_imploder": SoundManager.play_sfx("shoot_vortex", 0.15)
		"rocket_launcher", "cluster_mortar", "cluster_flak_cannon": SoundManager.play_sfx("shoot_rocket", 0.15)
		"meteor_staff": SoundManager.play_sfx("shoot_rocket", 0.2)
		"holy_sprinkler": SoundManager.play_sfx("water_spray", 0.2)
		"greatsword", "sledgehammer", "frost_scythe", "dagger": SoundManager.play_sfx("melee_swing", 0.2)
		_: SoundManager.play_sfx("shoot_pistol", 0.15)

func _draw() -> void:
	var special = weapon_data.get("special", "")
	var id = weapon_data.get("id", "pistol")
	var tier = weapon_data.get("tier", ItemDatabase.TIER_COMMON)
	var tier_col = ItemDatabase.TIER_COLORS.get(tier, Color.WHITE)
	
	if special == "orbital":
		var blades = weapon_data.get("projectiles", 3)
		var orbit_r = weapon_data.get("range", 100.0)
		var saw_tex = VisualFactory.get_weapon_texture(id)
		for b in range(blades):
			var ang = orbital_angle + (float(b) / float(blades)) * TAU
			var blade_pt = Vector2.from_angle(ang) * orbit_r
			if saw_tex:
				draw_set_transform(blade_pt, orbital_angle * 4.0, Vector2(5.5, 5.5))
				draw_texture(saw_tex, Vector2(-4, -4))
				draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
			else:
				draw_circle(blade_pt, 18.0, tier_col)
		return
		
	if special in ["melee_swing", "slash", "frost_slash"] and is_melee_swinging:
		var swing_ang = current_aim_dir.angle() + lerp(-1.2, 1.2, melee_swing_t)
		var is_dagger = (id == "dagger")
		var reach_dist = 60.0 if is_dagger else (100.0 if id == "frost_scythe" or id == "greatsword" else 85.0)
		var blade_head = Vector2.from_angle(swing_ang) * reach_dist
		var w_tex = VisualFactory.get_weapon_texture(id)
		
		# Crescent slash swoosh arc with special color
		var arc_alpha = sin(melee_swing_t * PI)
		var arc_col = Color(0.3, 0.9, 1.0, arc_alpha * 0.8) if special == "frost_slash" else Color(1.0, 1.0, 1.0, arc_alpha * 0.7)
		draw_arc(Vector2.ZERO, reach_dist, current_aim_dir.angle() - 1.2, current_aim_dir.angle() + 1.2, 16, arc_col, 7.0)
		
		if w_tex:
			var scale_size = 1.15 if is_dagger else 1.83
			draw_set_transform(blade_head, swing_ang + PI * 0.25, Vector2(scale_size, scale_size))
			draw_texture(w_tex, -w_tex.get_size() * 0.5)
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		return
		
	# Draw Ranged 8-Bit Pixel Art Weapon Mounted on Hardpoint
	var aim_ang = current_aim_dir.angle()
	var barrel_dir = Vector2.from_angle(aim_ang)
	var gun_pos = -barrel_dir * recoil_offset
	
	# Draw Weapon Sprite Rotated (2.17x scale for 24x24 texture)
	var wep_tex = VisualFactory.get_weapon_texture(id)
	if wep_tex:
		var flip_y = (cos(aim_ang) < 0)
		var sprite_scale = Vector2(2.17, -2.17 if flip_y else 2.17)
		draw_set_transform(gun_pos, aim_ang, sprite_scale)
		draw_texture(wep_tex, -wep_tex.get_size() * 0.5)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	else:
		draw_rect(Rect2(gun_pos + Vector2(-16, -10), Vector2(36, 20)), tier_col, true)
		
	# 8-Bit Muzzle Flash
	if muzzle_flash_timer > 0.0:
		var flash_pos = gun_pos + barrel_dir * 28.0
		draw_rect(Rect2(flash_pos - Vector2(12, 12), Vector2(24, 24)), Color8(255, 240, 60), true)
		draw_rect(Rect2(flash_pos - Vector2(6, 6), Vector2(12, 12)), Color.WHITE, true)
		
	# Continuous Laser Beam Visual
	if special == "laser" and laser_active:
		var end_local = to_local(laser_hit_pos)
		draw_line(gun_pos + barrel_dir * 24.0, end_local, Color8(255, 40, 60, 180), 14.0)
		draw_line(gun_pos + barrel_dir * 24.0, end_local, Color8(255, 240, 240, 255), 5.0)
