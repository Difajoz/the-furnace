# level_up_ui.gd - Minimalist Level Up & Upgrade Selection UI
class_name LevelUpUI
extends CanvasLayer

signal upgrade_selected(upgrade_data: Dictionary)

var current_upgrades: Array[Dictionary] = []
var reroll_cost: int = 5
var is_active: bool = false

# UI Node References
@onready var gold_label: Label = $Root/TopLeft/GoldLabel
@onready var bones_label: Label = $Root/TopLeft/BonesLabel
@onready var level_title_label: Label = $Root/TitleLabel
@onready var card_container: HBoxContainer = $Root/CardContainer
@onready var reroll_btn: Button = $Root/RerollCenter/RerollButton
@onready var stats_label: RichTextLabel = $Root/StatsPanel/StatsMargin/StatsVBox/StatsLabel

# Minimalist Upgrade Definitions
# Balanced Roguelite Upgrade Definitions (Fair Gains & Meaningful Trade-offs)
const UPGRADE_POOL = [
	# Player Stat Upgrades (All advantages boosted by +30%, drawbacks applied only on high tiers)
	{
		"id": "max_hp", "name": "Max HP", "stat": "max_hp",
		"values": [13.0, 24.0, 37.0, 52.0], "unit": "HP", "type": "player", "icon": "heart",
		"drawback_stat": "damage_mult", "drawback_values": [-0.08, -0.12, -0.16, -0.20], "drawback_unit": "Dmg", "drawback_percent": true
	},
	{
		"id": "damage_mult", "name": "Damage", "stat": "damage_mult",
		"values": [0.10, 0.18, 0.29, 0.39], "unit": "Dmg", "type": "player", "icon": "fist", "percent": true,
		"drawback_stat": "attack_speed_mult", "drawback_values": [-0.05, -0.09, -0.13, -0.17], "drawback_unit": "Atk Spd", "drawback_percent": true
	},
	{
		"id": "attack_speed", "name": "Atk Speed", "stat": "attack_speed_mult",
		"values": [0.10, 0.18, 0.29, 0.39], "unit": "Atk Spd", "type": "player", "icon": "lightning", "percent": true,
		"drawback_stat": "damage_mult", "drawback_values": [-0.05, -0.09, -0.13, -0.17], "drawback_unit": "Dmg", "drawback_percent": true
	},
	{
		"id": "hp_regen", "name": "HP Regen", "stat": "hp_regen",
		"values": [0.4, 0.8, 1.3, 2.0], "unit": "HP/s", "type": "player", "icon": "cross",
		"drawback_stat": "armor", "drawback_values": [-1.0, -2.0, -3.0, -4.0], "drawback_unit": "Armor"
	},
	{
		"id": "crit_chance", "name": "Crit Chance", "stat": "crit_chance",
		"values": [0.05, 0.10, 0.17, 0.24], "unit": "Crit", "type": "player", "icon": "target", "percent": true,
		"drawback_stat": "max_hp", "drawback_values": [-6.0, -12.0, -18.0, -25.0], "drawback_unit": "HP"
	},
	{
		"id": "crit_mult", "name": "Crit Dmg", "stat": "crit_mult",
		"values": [0.26, 0.46, 0.72, 1.05], "unit": "Crit Dmg", "type": "player", "icon": "sparkle",
		"drawback_stat": "attack_speed_mult", "drawback_values": [-0.05, -0.08, -0.12, -0.16], "drawback_unit": "Atk Spd", "drawback_percent": true
	},
	{
		"id": "armor", "name": "Armor", "stat": "armor",
		"values": [3.0, 5.0, 8.0, 12.0], "unit": "Armor", "type": "player", "icon": "shield",
		"drawback_stat": "move_speed_mult", "drawback_values": [-0.04, -0.07, -0.10, -0.14], "drawback_unit": "Speed", "drawback_percent": true
	},
	{
		"id": "move_speed", "name": "Speed", "stat": "move_speed_mult",
		"values": [0.08, 0.14, 0.21, 0.29], "unit": "Speed", "type": "player", "icon": "boot", "percent": true,
		"drawback_stat": "max_hp", "drawback_values": [-8.0, -14.0, -20.0, -28.0], "drawback_unit": "HP"
	},
	{
		"id": "lifesteal", "name": "Lifesteal", "stat": "lifesteal",
		"values": [0.02, 0.04, 0.06, 0.085], "unit": "Lifesteal", "type": "player", "icon": "drop", "percent": true,
		"drawback_stat": "hp_regen", "drawback_values": [-0.2, -0.4, -0.7, -1.0], "drawback_unit": "HP/s"
	},
	{
		"id": "luck", "name": "Luck", "stat": "luck",
		"values": [0.08, 0.16, 0.24, 0.33], "unit": "Luck", "type": "player", "icon": "dice", "percent": true,
		"drawback_stat": "armor", "drawback_values": [-1.0, -2.0, -3.0, -4.0], "drawback_unit": "Armor"
	},
	{
		"id": "pickup_radius", "name": "Magnet", "stat": "pickup_radius_mult",
		"values": [0.26, 0.46, 0.72, 1.05], "unit": "Magnet", "type": "player", "icon": "magnet", "percent": true,
		"drawback_stat": "max_hp", "drawback_values": [-4.0, -8.0, -12.0, -16.0], "drawback_unit": "HP"
	},
	{
		"id": "cooling_efficiency", "name": "Cooling", "stat": "cooling_efficiency",
		"values": [0.20, 0.37, 0.55, 0.78], "unit": "Cooling", "type": "player", "icon": "water", "percent": true,
		"drawback_stat": "move_speed_mult", "drawback_values": [-0.04, -0.07, -0.10, -0.14], "drawback_unit": "Speed", "drawback_percent": true
	},
	{
		"id": "water_capacity", "name": "Water Tank", "stat": "max_water",
		"values": [25.0, 50.0, 80.0, 120.0], "unit": "Water Tank", "type": "player", "icon": "water_tank",
		"drawback_stat": "move_speed_mult", "drawback_values": [-0.03, -0.05, -0.08, -0.11], "drawback_unit": "Speed", "drawback_percent": true
	},
	{
		"id": "water_regen", "name": "Hydro Pump", "stat": "water_regen_rate",
		"values": [0.05, 0.08, 0.12, 0.15], "unit": "Refill Rate", "type": "player", "icon": "pump", "percent": true,
		"drawback_stat": "armor", "drawback_values": [-1.0, -2.0, -3.0, -4.0], "drawback_unit": "Armor"
	},
	{
		"id": "bone_capacity", "name": "Bone Bag", "stat": "max_bones_held",
		"values": [7.0, 13.0, 21.0, 32.0], "unit": "Bone Cap", "type": "player", "icon": "bone",
		"drawback_stat": "move_speed_mult", "drawback_values": [-0.03, -0.06, -0.09, -0.12], "drawback_unit": "Speed", "drawback_percent": true
	},
	{
		"id": "dash_delay", "name": "Dash Delay", "stat": "dash_cooldown_mult",
		"values": [-0.15, -0.25, -0.35, -0.45], "unit": "Dash Delay", "type": "player", "icon": "boot", "percent": true,
		"drawback_stat": "move_speed_mult", "drawback_values": [-0.03, -0.05, -0.08, -0.10], "drawback_unit": "Speed", "drawback_percent": true
	},
	
	# Furnace Upgrades
	{
		"id": "crucible_bones", "name": "Crucible", "stat": "max_bone_capacity",
		"values": [11.0, 21.0, 33.0, 47.0], "unit": "Crucible", "type": "furnace", "is_furnace": true, "icon": "bone",
		"drawback_stat": "heat_per_bone_mult", "drawback_values": [0.06, 0.11, 0.16, 0.22], "drawback_unit": "Heat", "drawback_percent": true, "is_drawback_furnace": true
	},
	{
		"id": "furnace_speed", "name": "Smelt Speed", "stat": "process_speed_mult",
		"values": [0.13, 0.24, 0.37, 0.52], "unit": "Smelt", "type": "furnace", "is_furnace": true, "icon": "flame", "percent": true,
		"drawback_stat": "coin_yield_mult", "drawback_values": [-0.05, -0.09, -0.13, -0.18], "drawback_unit": "Gold", "drawback_percent": true, "is_drawback_furnace": true
	},
	{
		"id": "furnace_coins", "name": "Gold Alchemy", "stat": "coin_yield_mult",
		"values": [0.16, 0.26, 0.39, 0.55], "unit": "Gold", "type": "furnace", "is_furnace": true, "icon": "coin", "percent": true,
		"drawback_stat": "heat_per_bone_mult", "drawback_values": [0.08, 0.14, 0.20, 0.28], "drawback_unit": "Heat", "drawback_percent": true, "is_drawback_furnace": true
	},
	{
		"id": "furnace_heat", "name": "Heat Buffer", "stat": "max_temp_bonus",
		"values": [16.0, 29.0, 46.0, 65.0], "unit": "Safe Heat", "type": "furnace", "is_furnace": true, "icon": "insulation",
		"drawback_stat": "heat_per_bone_mult", "drawback_values": [0.05, 0.09, 0.14, 0.19], "drawback_unit": "Heat", "drawback_percent": true, "is_drawback_furnace": true
	}
]

const ROMAN_NUMERALS = ["I", "II", "III", "IV"]
const TIER_COLORS = [
	Color8(90, 170, 255),   # Tier 1 - Cyan/Blue
	Color8(180, 90, 255),   # Tier 2 - Neon Purple
	Color8(255, 130, 40),   # Tier 3 - Molten Orange
	Color8(255, 215, 30)    # Tier 4 - Radiant Gold
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if reroll_btn:
		_style_button(reroll_btn, Color8(255, 195, 35), Color8(45, 30, 10), Color8(255, 235, 100), Color8(75, 50, 15))
		reroll_btn.pressed.connect(_on_reroll_pressed)
	GameManager.level_up_ready.connect(_on_level_up_triggered)
	
	# Connect and style card buttons
	for i in range(4):
		var card_panel = card_container.get_node_or_null("Card%d" % i)
		if card_panel:
			var choose_btn = card_panel.get_node_or_null("Margin/VBox/ChooseButton") as Button
			var idx = i
			if choose_btn:
				_style_button(choose_btn, Color8(55, 200, 255), Color8(20, 36, 54), Color8(150, 235, 255), Color8(35, 70, 110))
				choose_btn.pressed.connect(func(): _on_card_chosen(idx))

func _style_button(btn: Button, border_col: Color, bg_col: Color, hover_border_col: Color, hover_bg_col: Color) -> void:
	if not btn: return
	var sb_norm = StyleBoxFlat.new()
	sb_norm.bg_color = bg_col
	sb_norm.border_color = border_col
	sb_norm.set_border_width_all(3)
	sb_norm.set_corner_radius_all(6)
	
	var sb_hover = StyleBoxFlat.new()
	sb_hover.bg_color = hover_bg_col
	sb_hover.border_color = hover_border_col
	sb_hover.set_border_width_all(3)
	sb_hover.set_corner_radius_all(6)
	
	var sb_pressed = StyleBoxFlat.new()
	sb_pressed.bg_color = bg_col.darkened(0.2)
	sb_pressed.border_color = Color.WHITE
	sb_pressed.set_border_width_all(3)
	sb_pressed.set_corner_radius_all(6)
	
	btn.add_theme_stylebox_override("normal", sb_norm)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_stylebox_override("focus", sb_hover)

func _on_level_up_triggered(_level: int) -> void:
	if not is_active:
		open_level_up()

func reset_level_up() -> void:
	current_upgrades.clear()
	reroll_cost = 5
	is_active = false
	visible = false

func open_level_up() -> void:
	is_active = true
	visible = true
	get_tree().paused = true
	_generate_upgrades()
	_update_stats_display()
	_update_resources()
	SoundManager.play_sfx("level_up", 0.0, -2.0)

func close_level_up() -> void:
	is_active = false
	visible = false
	if GameManager.pending_level_ups > 0:
		GameManager.pending_level_ups -= 1
		if GameManager.pending_level_ups > 0:
			open_level_up()
			return
			
	get_tree().paused = false

func _generate_upgrades() -> void:
	current_upgrades.clear()
	var pool_copy = UPGRADE_POOL.duplicate(true)
	pool_copy.shuffle()
	
	for i in range(min(4, pool_copy.size())):
		var base = pool_copy[i]
		var tier_roll = randf() + (GameManager.luck * 0.3) + (GameManager.current_wave * 0.02)
		var tier_idx = 0
		if tier_roll > 1.35:
			tier_idx = 3 # Tier IV (Gold)
		elif tier_roll > 0.95:
			tier_idx = 2 # Tier III (Orange)
		elif tier_roll > 0.55:
			tier_idx = 1 # Tier II (Purple)
		else:
			tier_idx = 0 # Tier I (Blue)
			
		var val = base["values"][tier_idx]
		var up_data = base.duplicate(true)
		up_data["tier"] = tier_idx
		up_data["value"] = val
		
		# Only give drawback when advantage is large / high tier (Tier III & IV)
		if tier_idx >= 2 and base.has("drawback_stat") and base.has("drawback_values"):
			up_data["drawback_stat"] = base["drawback_stat"]
			up_data["drawback_value"] = base["drawback_values"][tier_idx]
			up_data["is_drawback_furnace"] = base.get("is_drawback_furnace", false)
		else:
			up_data.erase("drawback_stat")
			up_data.erase("drawback_values")
			up_data.erase("drawback_unit")
			up_data.erase("drawback_percent")
			
		current_upgrades.append(up_data)
		
	_render_cards()
		
	_render_cards()

func _render_cards() -> void:
	if not card_container: return
	
	for i in range(4):
		var card_panel = card_container.get_node_or_null("Card%d" % i)
		if not card_panel: continue
		
		if i >= current_upgrades.size():
			card_panel.visible = false
			continue
			
		card_panel.visible = true
		var up = current_upgrades[i]
		var tier_idx = up.get("tier", 0)
		var tier_col = TIER_COLORS[tier_idx]
		var tier_roman = ROMAN_NUMERALS[tier_idx]
		
		var sb = card_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if sb:
			sb.border_color = tier_col
			card_panel.add_theme_stylebox_override("panel", sb)
			
		var icon_lbl = card_panel.get_node_or_null("Margin/VBox/TopRow/IconPanel/IconLabel") as Label
		if icon_lbl:
			icon_lbl.text = _get_icon_character(up.get("icon", "heart"))
			icon_lbl.modulate = tier_col
			
		var title_lbl = card_panel.get_node_or_null("Margin/VBox/TopRow/TitleVBox/TitleLabel") as Label
		if title_lbl:
			title_lbl.text = "%s %s" % [up.get("name", "Stat"), tier_roman]
			title_lbl.modulate = tier_col
			
		var sub_lbl = card_panel.get_node_or_null("Margin/VBox/TopRow/TitleVBox/SubLabel") as Label
		if sub_lbl:
			sub_lbl.visible = false
			
		var val_num = up.get("value", 0.0)
		var is_pct = up.get("percent", false)
		var formatted_val = ("%d%%" % int(val_num * 100.0) if val_num < 0 else "+%d%%" % int(val_num * 100.0)) if is_pct else ("%.1f" % val_num if abs(val_num) < 10.0 and val_num != int(val_num) else ("%d" % int(val_num) if val_num < 0 else "+%d" % int(val_num)))
		var buff_text = "%s %s" % [formatted_val, up.get("unit", "")]
		
		# Build drawback text (if any)
		var drawback_text = ""
		if up.has("drawback_stat"):
			var db_val = up.get("drawback_value", 0.0)
			var db_pct = up.get("drawback_percent", false)
			var db_num = ("%d%%" % int(db_val * 100.0) if db_pct else ("%.1f" % db_val if abs(db_val) < 10.0 and db_val != int(db_val) else "%d" % int(db_val)))
			if db_val > 0: db_num = "+" + db_num
			drawback_text = "\n[ %s %s ]" % [db_num, up.get("drawback_unit", "")]
			
		var desc_lbl = card_panel.get_node_or_null("Margin/VBox/DescLabel") as Label
		if desc_lbl:
			desc_lbl.text = buff_text + drawback_text
			desc_lbl.modulate = Color8(44, 245, 78)
			
		var choose_btn = card_panel.get_node_or_null("Margin/VBox/ChooseButton") as Button
		if choose_btn:
			_style_button(choose_btn, tier_col, Color8(18, 24, 36), Color.WHITE, Color8(35, 55, 80))

func _get_icon_character(icon_name: String) -> String:
	match icon_name:
		"heart": return "[+]"
		"cross": return "[H]"
		"fist": return "[D]"
		"lightning": return "[S]"
		"target": return "[C]"
		"sparkle": return "[*]"
		"shield": return "[A]"
		"boot": return "[>V]"
		"drop": return "[L]"
		"dice": return "[?]"
		"magnet": return "[U]"
		"water", "water_tank": return "[~]"
		"pump": return "[P]"
		"bone": return "[B]"
		"flame": return "[F]"
		"coin": return "[$]"
		"insulation": return "[#]"
		_: return "[+]"

func _on_card_chosen(idx: int) -> void:
	if idx < 0 or idx >= current_upgrades.size(): return
	var up = current_upgrades[idx]
	GameManager.apply_attribute_upgrade(up)
	emit_signal("upgrade_selected", up)
	close_level_up()

func _on_reroll_pressed() -> void:
	if GameManager.spend_coins(reroll_cost):
		SoundManager.play_sfx("button_click")
		_generate_upgrades()
		_update_resources()

func _update_resources() -> void:
	if gold_label: gold_label.text = "GOLD: %d" % GameManager.coins
	if bones_label: bones_label.text = "BONES: %d / %d" % [GameManager.bones_held, GameManager.max_bones_held]

func _update_stats_display() -> void:
	if not stats_label: return
	var s = "[font_size=22]"
	s += "[color=#ffffff][b]LVL %d[/b][/color]\n\n" % GameManager.player_level
	s += "[color=#55ff55]HP:[/color] %d\n" % int(GameManager.max_hp)
	s += "[color=#55ff55]Regen:[/color] +%.1f/s\n" % GameManager.hp_regen
	s += "[color=#ff5555]Dmg:[/color] +%.0f%%\n" % ((GameManager.damage_mult - 1.0) * 100.0)
	s += "[color=#ffff55]Atk Spd:[/color] +%.0f%%\n" % ((GameManager.attack_speed_mult - 1.0) * 100.0)
	s += "[color=#ffcc33]Crit:[/color] %.0f%%\n" % (GameManager.crit_chance * 100.0)
	s += "[color=#ffcc33]Crit Dmg:[/color] %.1fx\n" % GameManager.crit_mult
	s += "[color=#55aaff]Armor:[/color] %d\n" % int(GameManager.armor)
	s += "[color=#ff9933]Speed:[/color] +%.0f%%\n" % ((GameManager.move_speed_mult - 1.0) * 100.0)
	s += "[color=#cc88ff]Luck:[/color] +%.0f%%\n" % (GameManager.luck * 100.0)
	s += "[color=#f0ecc0]Bone Cap:[/color] %d\n" % GameManager.max_bones_held
	s += "[color=#33ccff]Water Cap:[/color] %d\n" % int(GameManager.max_water)
	s += "[color=#33ccff]Refill:[/color] +%.1f/s\n" % GameManager.water_regen_rate
	s += "\n[color=#ff9933][b]--- CRUCIBLE ---[/b][/color]\n"
	s += "[color=#ffffff]Cap:[/color] %d\n" % GameManager.furnace_max_bones
	s += "[color=#ff8833]Smelt:[/color] +%.0f%%\n" % ((GameManager.furnace_process_speed_mult - 1.0) * 100.0)
	s += "[color=#ffd21e]Gold:[/color] +%.0f%%\n" % ((GameManager.furnace_coin_yield_mult - 1.0) * 100.0)
	s += "[color=#33ccff]Cooling:[/color] +%.0f%%\n" % ((GameManager.cooling_efficiency - 1.0) * 100.0)
	s += "[/font_size]"
	stats_label.text = s
