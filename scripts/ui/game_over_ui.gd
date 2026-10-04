# game_over_ui.gd - Victory / Defeat Screen with Detailed Run Statistics
class_name GameOverUI
extends CanvasLayer

signal restart_requested()
signal menu_requested()

@onready var title_label: Label = $Root/Center/Panel/Margin/VBox/TitleLabel
@onready var stats_label: RichTextLabel = $Root/Center/Panel/Margin/VBox/StatsLabel
@onready var restart_btn: Button = $Root/Center/Panel/Margin/VBox/BtnBox/RestartButton
@onready var menu_btn: Button = $Root/Center/Panel/Margin/VBox/BtnBox/MenuButton

func _ready() -> void:
	visible = false
	if restart_btn:
		_style_button(restart_btn, Color8(44, 245, 120), Color8(15, 45, 25), Color8(120, 255, 170), Color8(25, 75, 40))
		restart_btn.pressed.connect(_on_restart_pressed)
	if menu_btn:
		_style_button(menu_btn, Color8(55, 200, 255), Color8(20, 36, 54), Color8(150, 235, 255), Color8(35, 70, 110))
		menu_btn.pressed.connect(_on_menu_pressed)
	GameManager.game_ended.connect(_on_game_ended)

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

func _on_game_ended(is_victory: bool, stats: Dictionary) -> void:
	visible = true
	if is_victory:
		if title_label:
			title_label.text = "[ SURVIVAL VICTORY! ]"
			title_label.modulate = Color8(255, 215, 60)
		SoundManager.play_victory_music()
	else:
		if title_label:
			title_label.text = "[ DEFEAT - RUN OVER ]"
			title_label.modulate = Color8(240, 50, 50)
		SoundManager.play_defeat_music()
		
	var new_recs = stats.get("new_records", {})
	
	var s = "[font_size=20]"
	var diff_str = stats.get("difficulty", "NORMAL")
	s += "[b]Difficulty:[/b] %s\n" % diff_str
	var wave_rec = " [color=#ffd700][NEW RECORD!][/color]" if new_recs.get("best_wave", false) else ""
	var combo_rec = " [color=#ffd700][NEW RECORD!][/color]" if new_recs.get("best_combo", false) else ""
	var kill_rec = " [color=#ffd700][NEW RECORD!][/color]" if new_recs.get("most_kills", false) else ""
	var coin_rec = " [color=#ffd700][NEW RECORD!][/color]" if new_recs.get("most_coins", false) else ""
	
	s += "[b]Wave Reached:[/b] %d / %d%s\n" % [stats.get("wave_reached", 1), GameManager.max_waves, wave_rec]
	s += "[b]Max Combo Streak:[/b] %d%s\n" % [stats.get("max_combo", 0), combo_rec]
	s += "[b]Zombies Defeated:[/b] %d%s\n" % [stats.get("zombies_killed", 0), kill_rec]
	s += "[b]Total Gold Earned:[/b] %d%s\n" % [stats.get("total_coins", 0), coin_rec]
	s += "[b]Bones Smelted:[/b] %d / %d Collected\n" % [stats.get("bones_processed", 0), stats.get("bones_collected", 0)]
	s += "[b]Peak Furnace Heat:[/b] %.0f C\n" % stats.get("max_temp", 0.0)
	var mins = int(stats.get("run_time", 0.0)) / 60
	var secs = int(stats.get("run_time", 0.0)) % 60
	s += "[b]Survive Duration:[/b] %02d:%02d\n" % [mins, secs]
	
	# Run Arsenal & Loadout Recap
	var weps = stats.get("equipped_weapons", [])
	if not weps.is_empty():
		s += "\n[color=#ffd700][b]--- RUN ARSENAL & WEAPONS ---[/b][/color]\n"
		var wep_strings = []
		for w in weps:
			if w is Dictionary:
				var w_name = w.get("name", "Weapon")
				var w_lvl = w.get("level", 1)
				var w_tier = w.get("tier", ItemDatabase.TIER_COMMON)
				var tier_col = ItemDatabase.TIER_COLORS.get(w_tier, Color.WHITE).to_html(false)
				wep_strings.append("[color=#%s][b]%s[/b] (Lv.%d)[/color]" % [tier_col, w_name, w_lvl])
		s += "  " + "   |   ".join(wep_strings) + "\n"
		
	var skls = stats.get("active_skills", [])
	if not skls.is_empty():
		var skl_strings = []
		for sk in skls:
			if sk is Dictionary:
				skl_strings.append("[color=#38c8ff][b]%s[/b][/color]" % sk.get("name", "Skill"))
		s += "[b]Active Skills:[/b] " + "  •  ".join(skl_strings) + "\n"
		
	var turrets_count = stats.get("placed_turrets_count", 0)
	if turrets_count > 0:
		s += "[b]Defenses Deployed:[/b] %d Turrets Guarded the Furnace\n" % turrets_count
		
	s += "[/font_size]"
	if stats_label:
		stats_label.text = s

func _on_restart_pressed() -> void:
	visible = false
	emit_signal("restart_requested")

func _on_menu_pressed() -> void:
	visible = false
	emit_signal("menu_requested")
