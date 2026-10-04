# hud.gd - Real-Time In-Game HUD: Health, Water, Bones, Coins, Waves, Weapon Slots, Target Lock, Active Skills
class_name GameHUD
extends CanvasLayer

@onready var hp_bar: ProgressBar = $Root/TopLeft/HPBox/HPFrame/HPBar
@onready var hp_label: Label = $Root/TopLeft/HPBox/HPLabel
@onready var water_bar: ProgressBar = $Root/TopLeft/WaterBox/WaterFrame/WaterBar
@onready var water_label: Label = $Root/TopLeft/WaterBox/WaterLabel
@onready var coin_label: Label = $Root/TopLeft/ResBox/GoldLabel
@onready var bone_label: Label = $Root/TopLeft/ResBox/BoneLabel
@onready var level_label: Label = $Root/TopLeft/XPBox/LevelLabel
@onready var xp_bar: ProgressBar = $Root/TopLeft/XPBox/XPFrame/XPBar

@onready var wave_label: Label = $Root/TopCenter/WaveLabel
@onready var timer_label: Label = $Root/TopCenter/TimerLabel

@onready var weapon_container: HBoxContainer = $Root/BottomLeft/Margin/WeaponVBox/WeaponContainer
@onready var target_lock_banner: PanelContainer = $Root/TargetLockBanner
@onready var target_lock_text: Label = $Root/TargetLockBanner/Margin/LockText
@onready var active_skills_panel: PanelContainer = $Root/ActiveSkillsPanel
@onready var skill_container: HBoxContainer = $Root/ActiveSkillsPanel/Margin/VBox/SkillContainer

@onready var combo_panel: PanelContainer = $Root/TopCenter/ComboPanel
@onready var combo_count_label: Label = $Root/TopCenter/ComboPanel/Margin/VBox/ComboCountLabel
@onready var combo_bonus_label: Label = $Root/TopCenter/ComboPanel/Margin/VBox/ComboBonusLabel
@onready var combo_bar: ProgressBar = $Root/TopCenter/ComboPanel/Margin/VBox/ComboBar

@onready var dash_panel: PanelContainer = $Root/DashPanel
@onready var dash_key_label: Label = $Root/DashPanel/Margin/VBox/Key
@onready var dash_tag_label: Label = $Root/DashPanel/Margin/VBox/Tag
@onready var dash_cd_bar: ProgressBar = $Root/DashPanel/Margin/VBox/CooldownBar
@onready var dash_status_label: Label = $Root/DashPanel/Margin/VBox/Status

@onready var boss_bar_panel: PanelContainer = $Root/BossBarPanel
@onready var boss_name_label: Label = $Root/BossBarPanel/Margin/VBox/HeaderHBox/BossNameLabel
@onready var boss_hp_label: Label = $Root/BossBarPanel/Margin/VBox/HeaderHBox/BossHPLabel
@onready var boss_bar: ProgressBar = $Root/BossBarPanel/Margin/VBox/BossBarFrame/BossBar

const SKILL_KEYS = ["[1]", "[2]", "[3]"]
var last_combo_count: int = 0

var turret_panel: PanelContainer = null
var turret_key_label: Label = null
var turret_tag_label: Label = null
var turret_status_label: Label = null
var is_placing_turret: bool = false

func _ready() -> void:
	_setup_turret_panel()
	_connect_signals()
	_update_initial_display()

func _connect_signals() -> void:
	GameManager.player_hp_changed.connect(_on_player_hp_changed)
	GameManager.player_water_changed.connect(_on_player_water_changed)
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.bones_changed.connect(_on_bones_changed)
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.wave_time_updated.connect(_on_wave_time_updated)
	GameManager.weapons_updated.connect(_on_weapons_updated)
	GameManager.show_damage_number.connect(_on_show_damage_number)
	GameManager.xp_changed.connect(_on_xp_changed)
	GameManager.target_lock_changed.connect(_on_target_lock_changed)
	GameManager.active_skills_updated.connect(_on_active_skills_updated)
	GameManager.combo_updated.connect(_on_combo_updated)
	GameManager.turret_inventory_updated.connect(_update_turret_display)
	GameManager.placement_mode_toggled.connect(_on_placement_mode_toggled)

func _update_initial_display() -> void:
	_on_player_hp_changed(GameManager.current_hp, GameManager.max_hp)
	_on_player_water_changed(GameManager.current_water, GameManager.max_water)
	_on_coins_changed(GameManager.coins, 0)
	_on_bones_changed(GameManager.bones_held)
	_on_xp_changed(GameManager.current_xp, GameManager.xp_to_next_level, GameManager.player_level)
	_on_weapons_updated()
	_on_active_skills_updated()
	_update_dash_display()
	_on_target_lock_changed(GameManager.locked_target)
	_on_combo_updated(GameManager.current_combo, GameManager.get_combo_gold_mult(), GameManager.current_combo > 1, GameManager.combo_timer, GameManager.COMBO_MAX_TIME)
	_update_boss_bar_display()
	_update_turret_display()
	_on_wave_started(GameManager.current_wave)

func _process(_delta: float) -> void:
	_update_active_skills_display()
	_update_dash_display()
	_update_target_lock_display()
	_update_boss_bar_display()

func _update_boss_bar_display() -> void:
	if not boss_bar_panel: return
	
	# Find any active boss in the arena
	var active_boss: Node2D = null
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			if "is_boss" in e and e.is_boss:
				active_boss = e
				break
				
	if active_boss:
		boss_bar_panel.visible = true
		if boss_name_label:
			boss_name_label.text = active_boss.monster_name.to_upper()
		if boss_hp_label:
			boss_hp_label.text = "%d / %d (%d%%)" % [int(max(0.0, active_boss.hp)), int(active_boss.max_hp), int((active_boss.hp / max(1.0, active_boss.max_hp)) * 100.0)]
		if boss_bar:
			boss_bar.max_value = active_boss.max_hp
			boss_bar.value = active_boss.hp
	else:
		boss_bar_panel.visible = false

func _on_target_lock_changed(target: Node2D) -> void:
	if not target_lock_banner: return
	if is_instance_valid(target) and not target.is_queued_for_deletion():
		target_lock_banner.visible = true
		if target_lock_text:
			target_lock_text.text = "LOCKED IN : UNLOCK [Q]"
	else:
		target_lock_banner.visible = false

func _on_combo_updated(combo_count: int, multiplier: float, is_active: bool, time_left: float, max_time: float) -> void:
	if not combo_panel: return
	
	if is_active and combo_count >= 2:
		combo_panel.visible = true
		if combo_count_label:
			combo_count_label.text = "%d COMBO!" % combo_count
			if combo_count != last_combo_count:
				combo_count_label.pivot_offset = combo_count_label.size * 0.5
				var tw = create_tween()
				tw.tween_property(combo_count_label, "scale", Vector2(1.22, 1.22), 0.04).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw.tween_property(combo_count_label, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
				
				if combo_count >= 50:
					combo_count_label.modulate = Color8(255, 90, 240)
				elif combo_count >= 25:
					combo_count_label.modulate = Color8(255, 120, 30)
				elif combo_count >= 10:
					combo_count_label.modulate = Color8(80, 220, 255)
				else:
					combo_count_label.modulate = Color8(255, 230, 70)
					
		if combo_bonus_label:
			var bonus_pct = (multiplier - 1.0) * 100.0
			combo_bonus_label.text = "+%.0f%% GOLD RATE" % bonus_pct
			
		if combo_bar:
			combo_bar.max_value = max_time
			combo_bar.value = time_left
			
		last_combo_count = combo_count
	else:
		combo_panel.visible = false
		last_combo_count = 0

func _update_target_lock_display() -> void:
	if not target_lock_banner: return
	if is_instance_valid(GameManager.locked_target) and not GameManager.locked_target.is_queued_for_deletion():
		if not target_lock_banner.visible:
			target_lock_banner.visible = true
	else:
		if target_lock_banner.visible:
			target_lock_banner.visible = false

func _on_active_skills_updated() -> void:
	_update_active_skills_display()

func _update_active_skills_display() -> void:
	if not skill_container: return
	
	for i in range(3):
		var slot_panel = skill_container.get_node_or_null("Slot%d" % i) as PanelContainer
		if not slot_panel: continue
		
		var key_lbl = slot_panel.get_node_or_null("VBox/HBox/Key") as Label
		var tag_lbl = slot_panel.get_node_or_null("VBox/HBox/Tag") as Label
		var cd_bar = slot_panel.get_node_or_null("VBox/CooldownBar") as ProgressBar
		var status_lbl = slot_panel.get_node_or_null("VBox/Status") as Label
		
		if key_lbl: key_lbl.text = SKILL_KEYS[i]
		
		if i < GameManager.active_skills.size():
			var skill = GameManager.active_skills[i]
			var icon_tag = skill.get("icon_tag", "SKL")
			var base_col = skill.get("color", Color8(255, 120, 40))
			var cd_max = skill.get("cooldown", 20.0)
			var cd_cur = skill.get("cooldown_timer", 0.0)
			var act_cur = skill.get("active_timer", 0.0)
			var is_active = (act_cur > 0.0)
			
			if tag_lbl:
				tag_lbl.text = icon_tag
				tag_lbl.modulate = base_col
				
			var sb_slot = slot_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
			if sb_slot:
				if is_active:
					sb_slot.border_color = Color8(255, 235, 100)
					sb_slot.bg_color = Color8(45, 30, 10, 240)
				elif cd_cur > 0.0:
					sb_slot.border_color = Color8(50, 60, 80)
					sb_slot.bg_color = Color8(14, 18, 26, 240)
				else:
					sb_slot.border_color = base_col
					sb_slot.bg_color = Color8(18, 24, 36, 240)
				slot_panel.add_theme_stylebox_override("panel", sb_slot)
				
			if cd_bar:
				var sb_fill = StyleBoxFlat.new()
				if is_active:
					cd_bar.max_value = 1.0
					cd_bar.value = 1.0
					sb_fill.bg_color = Color8(255, 215, 40)
					if status_lbl:
						status_lbl.text = "ACTIVE %.1fs" % act_cur
						status_lbl.modulate = Color8(255, 235, 100)
				elif cd_cur > 0.0:
					cd_bar.max_value = cd_max
					cd_bar.value = cd_max - cd_cur # fills up as it cools down!
					sb_fill.bg_color = Color8(60, 140, 200) # Distinct color when not filled / recharging
					if status_lbl:
						status_lbl.text = "%.1fs" % cd_cur
						status_lbl.modulate = Color8(150, 175, 200)
				else:
					cd_bar.max_value = 1.0
					cd_bar.value = 1.0
					sb_fill.bg_color = base_col # Distinct filled ready color
					if status_lbl:
						status_lbl.text = "READY"
						status_lbl.modulate = Color8(44, 245, 80)
				cd_bar.add_theme_stylebox_override("fill", sb_fill)
		else:
			# Empty slot
			if tag_lbl:
				tag_lbl.text = "---"
				tag_lbl.modulate = Color8(90, 95, 110)
			if status_lbl:
				status_lbl.text = "[SHOP]"
				status_lbl.modulate = Color8(80, 85, 100)
			if cd_bar:
				cd_bar.max_value = 1.0
				cd_bar.value = 0.0
				var sb_fill = StyleBoxFlat.new()
				sb_fill.bg_color = Color8(30, 35, 45)
				cd_bar.add_theme_stylebox_override("fill", sb_fill)
			var sb_slot = slot_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
			if sb_slot:
				sb_slot.border_color = Color8(40, 45, 55)
				sb_slot.bg_color = Color8(10, 12, 16, 200)
				slot_panel.add_theme_stylebox_override("panel", sb_slot)

func _update_dash_display() -> void:
	if not dash_panel: return
	
	var player = GameManager.player_node
	if not is_instance_valid(player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
			
	if not is_instance_valid(player):
		if dash_status_label:
			dash_status_label.text = "READY"
			dash_status_label.modulate = Color8(44, 245, 120)
		if dash_cd_bar:
			dash_cd_bar.max_value = 1.0
			dash_cd_bar.value = 1.0
		return
		
	var is_dashing = player.is_dashing if "is_dashing" in player else false
	var cd_cur = player.dash_cooldown_timer if "dash_cooldown_timer" in player else 0.0
	var cd_max = max(0.4, (player.dash_cooldown if "dash_cooldown" in player else 2.0) * GameManager.dash_cooldown_mult)
	
	var sb_slot = dash_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	var sb_fill = StyleBoxFlat.new()
	
	if is_dashing:
		if dash_status_label:
			dash_status_label.text = "DASHING"
			dash_status_label.modulate = Color8(255, 235, 100)
		if dash_cd_bar:
			dash_cd_bar.max_value = 1.0
			dash_cd_bar.value = 1.0
			sb_fill.bg_color = Color8(255, 235, 100)
			dash_cd_bar.add_theme_stylebox_override("fill", sb_fill)
		if sb_slot:
			sb_slot.border_color = Color8(255, 235, 100)
			sb_slot.bg_color = Color8(45, 35, 15, 240)
			dash_panel.add_theme_stylebox_override("panel", sb_slot)
	elif cd_cur > 0.0:
		if dash_status_label:
			dash_status_label.text = "%.1fs" % cd_cur
			dash_status_label.modulate = Color8(150, 180, 210)
		if dash_cd_bar:
			dash_cd_bar.max_value = cd_max
			dash_cd_bar.value = cd_max - cd_cur
			sb_fill.bg_color = Color8(60, 140, 200)
			dash_cd_bar.add_theme_stylebox_override("fill", sb_fill)
		if sb_slot:
			sb_slot.border_color = Color8(50, 65, 85)
			sb_slot.bg_color = Color8(14, 18, 26, 240)
			dash_panel.add_theme_stylebox_override("panel", sb_slot)
	else:
		if dash_status_label:
			dash_status_label.text = "READY"
			dash_status_label.modulate = Color8(44, 245, 120)
		if dash_cd_bar:
			dash_cd_bar.max_value = 1.0
			dash_cd_bar.value = 1.0
			sb_fill.bg_color = Color8(44, 245, 120)
			dash_cd_bar.add_theme_stylebox_override("fill", sb_fill)
		if sb_slot:
			sb_slot.border_color = Color8(44, 245, 120)
			sb_slot.bg_color = Color8(12, 28, 20, 240)
			dash_panel.add_theme_stylebox_override("panel", sb_slot)

func _on_player_hp_changed(current: float, max_val: float) -> void:
	if hp_bar:
		hp_bar.max_value = max_val
		hp_bar.value = current
	if hp_label:
		hp_label.text = "%d/%d" % [int(current), int(max_val)]

func _on_player_water_changed(current: float, max_val: float) -> void:
	if water_bar:
		water_bar.max_value = max_val
		water_bar.value = current
	if water_label:
		water_label.text = "%d%%" % int((current / max(1.0, max_val)) * 100.0)

func _on_coins_changed(amount: int, _delta: int) -> void:
	if coin_label:
		coin_label.text = "GOLD: %d" % amount

func _on_bones_changed(bones: int) -> void:
	if bone_label:
		bone_label.text = "BONES: %d/%d" % [bones, GameManager.max_bones_held]
		if bones >= GameManager.max_bones_held:
			bone_label.modulate = Color8(255, 80, 80)
		else:
			bone_label.modulate = Color(0.96, 0.94, 0.9, 1.0)

func _on_wave_started(wave_num: int) -> void:
	if wave_label:
		if GameManager.is_tutorial:
			wave_label.text = "TUTORIAL ACADEMY"
			wave_label.modulate = Color8(55, 220, 255)
		else:
			var diff_name = GameManager.get_difficulty_name()
			wave_label.text = "WAVE %d / %d [%s]" % [wave_num, GameManager.max_waves, diff_name]
			wave_label.modulate = GameManager.get_difficulty_color()

func _on_wave_time_updated(time_left: float, _total: float) -> void:
	if timer_label:
		var mins = int(time_left) / 60
		var secs = int(time_left) % 60
		timer_label.text = "%02d:%02d" % [mins, secs]

func _on_weapons_updated() -> void:
	if not weapon_container: return
	
	for i in range(GameManager.MAX_WEAPONS):
		var slot_node = weapon_container.get_node_or_null("Slot%d" % i)
		if not slot_node: continue
		
		# Show only unlocked slots
		slot_node.visible = (i < GameManager.max_weapon_slots)
		if not slot_node.visible: continue
		
		var icon_node = slot_node.get_node_or_null("Icon") as TextureRect
		var label_node = slot_node.get_node_or_null("Label") as Label
		
		if i < GameManager.equipped_weapons.size():
			var w = GameManager.equipped_weapons[i]
			var tier = w.get("tier", ItemDatabase.TIER_COMMON)
			var tier_col = ItemDatabase.TIER_COLORS.get(tier, Color.WHITE)
			
			var sb = slot_node.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
			if sb:
				sb.border_color = tier_col
				slot_node.add_theme_stylebox_override("panel", sb)
				
			var wep_id = w.get("base_weapon_id", w.get("id", "pistol"))
			var wep_tex = VisualFactory.get_weapon_texture(wep_id)
			if wep_tex and icon_node:
				icon_node.texture = wep_tex
				icon_node.visible = true
				if label_node: label_node.visible = false
			elif label_node:
				if icon_node: icon_node.visible = false
				label_node.text = w.get("name", "Gun").substr(0, 4)
				label_node.modulate = tier_col
				label_node.visible = true
		else:
			var sb = slot_node.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
			if sb:
				sb.border_color = Color8(45, 48, 60)
				slot_node.add_theme_stylebox_override("panel", sb)
			if icon_node: icon_node.visible = false
			if label_node:
				label_node.text = "-"
				label_node.modulate = Color8(70, 75, 90)
				label_node.visible = true

func _on_show_damage_number(pos: Vector2, text: String, color: Color, is_crit: bool) -> void:
	var num = DamageNumber.new()
	num.init_number(pos, text, color, is_crit)
	get_tree().current_scene.add_child(num)

func _on_xp_changed(current: int, max_val: int, level: int) -> void:
	if level_label:
		level_label.text = "LV. %d" % level
	if xp_bar:
		xp_bar.max_value = max_val
		xp_bar.value = current

func _setup_turret_panel() -> void:
	var root_node = get_node_or_null("Root")
	if not root_node: return
	
	turret_panel = PanelContainer.new()
	turret_panel.name = "TurretPanel"
	turret_panel.layout_mode = 1
	turret_panel.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	turret_panel.anchor_left = 1.0
	turret_panel.anchor_top = 1.0
	turret_panel.anchor_right = 1.0
	turret_panel.anchor_bottom = 1.0
	turret_panel.offset_left = -560.0
	turret_panel.offset_top = -144.0
	turret_panel.offset_right = -430.0
	turret_panel.offset_bottom = 0.0
	turret_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color8(18, 20, 28, 240)
	sb.border_color = Color8(245, 205, 80)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	turret_panel.add_theme_stylebox_override("panel", sb)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	turret_panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	turret_key_label = Label.new()
	turret_key_label.text = "[T]"
	turret_key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turret_key_label.modulate = Color8(255, 215, 60)
	turret_key_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(turret_key_label)
	
	turret_tag_label = Label.new()
	turret_tag_label.text = "TURRET"
	turret_tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turret_tag_label.modulate = Color8(100, 220, 255)
	turret_tag_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(turret_tag_label)
	
	turret_status_label = Label.new()
	turret_status_label.text = "0 READY"
	turret_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turret_status_label.modulate = Color8(180, 190, 210)
	turret_status_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(turret_status_label)
	
	turret_panel.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			var main_node = get_tree().current_scene
			if is_instance_valid(main_node) and "placement_manager" in main_node and is_instance_valid(main_node.placement_manager):
				main_node.placement_manager.toggle_placement_mode()
	)
	
	root_node.add_child(turret_panel)
	turret_panel.visible = false

func _update_turret_display() -> void:
	if not turret_panel or not turret_status_label: return
	var count = GameManager.turret_inventory.size()
	if count > 0:
		turret_panel.visible = true
		if is_placing_turret:
			turret_status_label.text = "PLACING"
			turret_status_label.modulate = Color8(255, 235, 100)
		else:
			turret_status_label.text = "%d READY" % count
			turret_status_label.modulate = Color8(44, 245, 120)
	else:
		turret_panel.visible = false

func _on_placement_mode_toggled(active: bool) -> void:
	is_placing_turret = active
	_update_turret_display()
