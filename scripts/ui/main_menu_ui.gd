# main_menu_ui.gd - Main Menu with Clean Section Transitions, Difficulty Selection & Spatial Tutorial Entry
class_name MainMenuUI
extends CanvasLayer

signal start_game_requested()
signal continue_game_requested()
signal tutorial_requested()

var pending_difficulty: GameManager.Difficulty = GameManager.Difficulty.NORMAL

# Sections
@onready var main_section: VBoxContainer = $Root/Center/Panel/Margin/VBox/MainSection
@onready var diff_section: VBoxContainer = $Root/Center/Panel/Margin/VBox/DifficultySection

# Main Section Controls
@onready var record_label: Label = $Root/Center/Panel/Margin/VBox/RecordLabel
@onready var continue_btn: Button = $Root/Center/Panel/Margin/VBox/MainSection/ContinueButton
@onready var start_btn: Button = $Root/Center/Panel/Margin/VBox/MainSection/StartButton
@onready var tutorial_btn: Button = $Root/Center/Panel/Margin/VBox/MainSection/TutorialButton
@onready var quit_btn: Button = $Root/Center/Panel/Margin/VBox/MainSection.get_node_or_null("QuitButton")
@onready var sfx_btn: Button = $Root/Center/Panel/Margin/VBox/MainSection/AudioHBox/SfxButton
@onready var music_btn: Button = $Root/Center/Panel/Margin/VBox/MainSection/AudioHBox/MusicButton
@onready var fullscreen_btn: Button = $Root/Center/Panel/Margin/VBox/MainSection/AudioHBox/FullscreenButton

# Difficulty Section Controls
@onready var easy_btn: Button = $Root/Center/Panel/Margin/VBox/DifficultySection/DiffHBox/EasyButton
@onready var norm_btn: Button = $Root/Center/Panel/Margin/VBox/DifficultySection/DiffHBox/NormalButton
@onready var hard_btn: Button = $Root/Center/Panel/Margin/VBox/DifficultySection/DiffHBox/HardButton
@onready var diff_desc_panel: PanelContainer = $Root/Center/Panel/Margin/VBox/DifficultySection/DiffDescPanel
@onready var diff_title_label: Label = $Root/Center/Panel/Margin/VBox/DifficultySection/DiffDescPanel/Margin/VBox/DiffTitleLabel
@onready var diff_desc_label: Label = $Root/Center/Panel/Margin/VBox/DifficultySection/DiffDescPanel/Margin/VBox/DiffDescLabel
@onready var launch_btn: Button = $Root/Center/Panel/Margin/VBox/DifficultySection/DiffActionsVBox/LaunchButton
@onready var back_btn: Button = $Root/Center/Panel/Margin/VBox/DifficultySection/DiffActionsVBox/BackButton

func _ready() -> void:
	pending_difficulty = GameManager.selected_difficulty
	
	# Main Section Buttons
	if continue_btn:
		_style_button(continue_btn, Color8(44, 245, 120), Color8(15, 45, 25), Color8(120, 255, 170), Color8(25, 75, 40))
		continue_btn.pressed.connect(_on_continue_pressed)
	if start_btn:
		_style_button(start_btn, Color8(255, 195, 35), Color8(45, 30, 10), Color8(255, 235, 100), Color8(75, 50, 15))
		start_btn.pressed.connect(_on_start_pressed)
	if tutorial_btn:
		_style_button(tutorial_btn, Color8(55, 200, 255), Color8(18, 38, 55), Color8(150, 235, 255), Color8(30, 65, 95))
		tutorial_btn.pressed.connect(_on_tutorial_pressed)
	if quit_btn:
		_style_button(quit_btn, Color8(255, 75, 75), Color8(45, 18, 18), Color8(255, 130, 130), Color8(75, 25, 25))
		quit_btn.pressed.connect(_on_quit_pressed)
		if OS.has_feature("web"):
			quit_btn.visible = false
		
	# Difficulty Section Buttons
	if easy_btn:
		easy_btn.pressed.connect(func(): _select_difficulty(GameManager.Difficulty.EASY))
	if norm_btn:
		norm_btn.pressed.connect(func(): _select_difficulty(GameManager.Difficulty.NORMAL))
	if hard_btn:
		hard_btn.pressed.connect(func(): _select_difficulty(GameManager.Difficulty.HARD))
	if launch_btn:
		launch_btn.pressed.connect(_on_launch_run_pressed)
	if back_btn:
		_style_button(back_btn, Color8(100, 110, 130), Color8(25, 28, 35), Color8(160, 175, 200), Color8(45, 50, 60))
		back_btn.pressed.connect(_on_back_pressed)
		
	# Audio & Screen Options
	if sfx_btn:
		_style_button(sfx_btn, Color8(55, 200, 255), Color8(20, 36, 54), Color8(150, 235, 255), Color8(35, 70, 110))
		sfx_btn.pressed.connect(_on_sfx_toggle)
	if music_btn:
		_style_button(music_btn, Color8(180, 100, 255), Color8(35, 20, 55), Color8(220, 160, 255), Color8(60, 35, 95))
		music_btn.pressed.connect(_on_music_toggle)
	if fullscreen_btn:
		_style_button(fullscreen_btn, Color8(255, 160, 40), Color8(40, 25, 10), Color8(255, 200, 80), Color8(65, 40, 15))
		fullscreen_btn.pressed.connect(_on_fullscreen_toggle)
		
	show_main_section()
	_update_diff_display()
	update_records_display()
	_update_audio_buttons()
	_update_fullscreen_button()

func show_main_section() -> void:
	if main_section: main_section.visible = true
	if diff_section: diff_section.visible = false

func show_difficulty_section() -> void:
	if main_section: main_section.visible = false
	if diff_section: diff_section.visible = true
	_update_diff_display()

func _select_difficulty(diff: GameManager.Difficulty) -> void:
	pending_difficulty = diff
	SoundManager.play_sfx("button_click")
	_update_diff_display()

func _update_diff_display() -> void:
	# Easy Button
	if easy_btn:
		if pending_difficulty == GameManager.Difficulty.EASY:
			_style_button(easy_btn, Color8(80, 235, 120), Color8(20, 55, 30), Color8(120, 255, 160), Color8(30, 80, 45))
			easy_btn.text = "[ EASY ]"
		else:
			_style_button(easy_btn, Color8(60, 70, 80), Color8(20, 24, 30), Color8(100, 115, 130), Color8(35, 40, 50))
			easy_btn.text = "EASY"
			
	# Normal Button
	if norm_btn:
		if pending_difficulty == GameManager.Difficulty.NORMAL:
			_style_button(norm_btn, Color8(255, 205, 50), Color8(55, 40, 15), Color8(255, 235, 110), Color8(80, 60, 22))
			norm_btn.text = "[ NORMAL ]"
		else:
			_style_button(norm_btn, Color8(60, 70, 80), Color8(20, 24, 30), Color8(100, 115, 130), Color8(35, 40, 50))
			norm_btn.text = "NORMAL"
			
	# Hard Button
	if hard_btn:
		if pending_difficulty == GameManager.Difficulty.HARD:
			_style_button(hard_btn, Color8(255, 75, 75), Color8(55, 18, 18), Color8(255, 140, 140), Color8(85, 28, 28))
			hard_btn.text = "[ HARD ]"
		else:
			_style_button(hard_btn, Color8(60, 70, 80), Color8(20, 24, 30), Color8(100, 115, 130), Color8(35, 40, 50))
			hard_btn.text = "HARD"
			
	# Update description panel
	var col = GameManager.get_difficulty_color(pending_difficulty)
	var title = ""
	var desc = GameManager.get_difficulty_desc(pending_difficulty)
	
	match pending_difficulty:
		GameManager.Difficulty.EASY:
			title = "[ DIFFICULTY: EASY - RECRUIT FOUNDRY ]"
		GameManager.Difficulty.NORMAL:
			title = "[ DIFFICULTY: NORMAL - STANDARD CRUCIBLE ]"
		GameManager.Difficulty.HARD:
			title = "[ DIFFICULTY: HARD - CRYPT NIGHTMARE ]"
			
	if diff_title_label:
		diff_title_label.text = title
		diff_title_label.modulate = col
	if diff_desc_label:
		diff_desc_label.text = desc
		
	if diff_desc_panel:
		var sb = diff_desc_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if sb:
			sb.border_color = col
			diff_desc_panel.add_theme_stylebox_override("panel", sb)
			
	# Update Launch Button text and styling
	if launch_btn:
		var diff_name = GameManager.get_difficulty_name(pending_difficulty)
		if GameManager.has_saved_run():
			launch_btn.text = "LAUNCH NEW RUN [%s] (OVERWRITE SAVE)" % diff_name
			_style_button(launch_btn, Color8(220, 90, 70), Color8(45, 20, 15), Color8(255, 130, 110), Color8(75, 30, 22))
		else:
			launch_btn.text = "LAUNCH RUN [%s] (40 GOLD)" % diff_name
			match pending_difficulty:
				GameManager.Difficulty.EASY:
					_style_button(launch_btn, Color8(80, 235, 120), Color8(20, 55, 30), Color8(120, 255, 160), Color8(30, 80, 45))
				GameManager.Difficulty.NORMAL:
					_style_button(launch_btn, Color8(255, 195, 35), Color8(45, 30, 10), Color8(255, 235, 100), Color8(75, 50, 15))
				GameManager.Difficulty.HARD:
					_style_button(launch_btn, Color8(255, 75, 75), Color8(55, 18, 18), Color8(255, 140, 140), Color8(85, 28, 28))

func update_records_display() -> void:
	if record_label:
		var hs = GameManager.high_scores
		record_label.text = "BEST WAVE: %d  |  MAX COMBO: %d  |  MAX KILLS: %d  |  MAX GOLD: %d" % [
			hs.get("best_wave", 1),
			hs.get("best_combo", 0),
			hs.get("most_kills", 0),
			hs.get("most_coins", 40)
		]
		
	# Check if saved run exists
	if GameManager.has_saved_run():
		var info = GameManager.get_saved_run_info()
		var wave = int(info.get("current_wave", 1))
		var lvl = int(info.get("player_level", 1))
		var gold = int(info.get("coins", 0))
		var weps = info.get("equipped_weapons", []).size()
		var diff_idx = int(info.get("selected_difficulty", GameManager.Difficulty.NORMAL))
		var diff_name = GameManager.get_difficulty_name(diff_idx)
		
		if continue_btn:
			continue_btn.visible = true
			continue_btn.text = "CONTINUE RUN [%s] (WAVE %d  |  LV.%d  |  %d GOLD  |  %d WEP)" % [diff_name, wave, lvl, gold, weps]
	else:
		if continue_btn:
			continue_btn.visible = false
			
	show_main_section()
	_update_diff_display()
	_update_fullscreen_button()

func _update_audio_buttons() -> void:
	if sfx_btn:
		sfx_btn.text = "SFX: %s" % SoundManager.get_sfx_volume_label()
	if music_btn:
		music_btn.text = "MUSIC: %s" % SoundManager.get_music_volume_label()

func _update_fullscreen_button() -> void:
	if fullscreen_btn:
		var mode = DisplayServer.window_get_mode()
		var is_full = (mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		fullscreen_btn.text = "SCREEN: FULL" if is_full else "SCREEN: WINDOW"

func _on_fullscreen_toggle() -> void:
	GameManager.toggle_fullscreen()
	SoundManager.play_sfx("button_click")
	_update_fullscreen_button()

func _on_sfx_toggle() -> void:
	SoundManager.cycle_sfx_volume()
	SoundManager.play_sfx("button_click")
	_update_audio_buttons()

func _on_music_toggle() -> void:
	SoundManager.cycle_music_volume()
	SoundManager.play_sfx("button_click")
	_update_audio_buttons()

func _on_quit_pressed() -> void:
	SoundManager.play_sfx("button_click")
	get_tree().quit()

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

func _on_continue_pressed() -> void:
	SoundManager.play_sfx("button_click")
	visible = false
	emit_signal("continue_game_requested")

func _on_start_pressed() -> void:
	SoundManager.play_sfx("button_click")
	show_difficulty_section()

func _on_back_pressed() -> void:
	SoundManager.play_sfx("button_click")
	show_main_section()

func _on_launch_run_pressed() -> void:
	SoundManager.play_sfx("button_click")
	GameManager.selected_difficulty = pending_difficulty
	visible = false
	emit_signal("start_game_requested")

func _on_tutorial_pressed() -> void:
	SoundManager.play_sfx("button_click")
	visible = false
	emit_signal("tutorial_requested")
