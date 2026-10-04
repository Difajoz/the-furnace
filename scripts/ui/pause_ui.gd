# pause_ui.gd - Retro 8-Bit Pause Menu with Save & Quit and Options
class_name PauseUI
extends CanvasLayer

signal resume_requested()
signal restart_requested()
signal menu_requested()
signal save_and_quit_requested()

@onready var title_label: Label = $Root/Center/Panel/Margin/VBox/TitleLabel
@onready var subtitle_label: Label = $Root/Center/Panel/Margin/VBox/SubtitleLabel
@onready var resume_btn: Button = $Root/Center/Panel/Margin/VBox/ResumeButton
@onready var save_quit_btn: Button = $Root/Center/Panel/Margin/VBox/SaveQuitButton
@onready var restart_btn: Button = $Root/Center/Panel/Margin/VBox/RestartButton
@onready var menu_btn: Button = $Root/Center/Panel/Margin/VBox/MenuButton
@onready var sfx_btn: Button = $Root/Center/Panel/Margin/VBox/AudioHBox/SfxButton
@onready var music_btn: Button = $Root/Center/Panel/Margin/VBox/AudioHBox/MusicButton
@onready var fullscreen_btn: Button = $Root/Center/Panel/Margin/VBox/AudioHBox/FullscreenButton

func _ready() -> void:
	visible = false
	if resume_btn:
		_style_button(resume_btn, Color8(44, 245, 120), Color8(15, 45, 25), Color8(120, 255, 170), Color8(25, 75, 40))
		resume_btn.pressed.connect(_on_resume_pressed)
	if save_quit_btn:
		_style_button(save_quit_btn, Color8(55, 200, 255), Color8(15, 38, 55), Color8(150, 235, 255), Color8(25, 65, 95))
		save_quit_btn.pressed.connect(_on_save_quit_pressed)
	if restart_btn:
		_style_button(restart_btn, Color8(255, 195, 35), Color8(45, 30, 10), Color8(255, 235, 100), Color8(75, 50, 15))
		restart_btn.pressed.connect(_on_restart_pressed)
	if menu_btn:
		_style_button(menu_btn, Color8(220, 100, 80), Color8(45, 20, 15), Color8(255, 150, 130), Color8(70, 30, 22))
		menu_btn.pressed.connect(_on_menu_pressed)
	if sfx_btn:
		_style_button(sfx_btn, Color8(55, 200, 255), Color8(20, 36, 54), Color8(150, 235, 255), Color8(35, 70, 110))
		sfx_btn.pressed.connect(_on_sfx_toggle)
	if music_btn:
		_style_button(music_btn, Color8(180, 100, 255), Color8(35, 20, 55), Color8(220, 160, 255), Color8(60, 35, 95))
		music_btn.pressed.connect(_on_music_toggle)
	if fullscreen_btn:
		_style_button(fullscreen_btn, Color8(255, 160, 40), Color8(40, 25, 10), Color8(255, 200, 80), Color8(65, 40, 15))
		fullscreen_btn.pressed.connect(_on_fullscreen_toggle)
		
	_update_audio_buttons()
	_update_fullscreen_button()

func _update_fullscreen_button() -> void:
	if fullscreen_btn:
		var mode = DisplayServer.window_get_mode()
		var is_full = (mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		fullscreen_btn.text = "SCREEN: FULL" if is_full else "SCREEN: WINDOW"

func _on_fullscreen_toggle() -> void:
	GameManager.toggle_fullscreen()
	SoundManager.play_sfx("button_click")
	_update_fullscreen_button()

func _update_audio_buttons() -> void:
	if sfx_btn:
		sfx_btn.text = "SFX: %s" % SoundManager.get_sfx_volume_label()
	if music_btn:
		music_btn.text = "MUSIC: %s" % SoundManager.get_music_volume_label()

func _on_sfx_toggle() -> void:
	SoundManager.cycle_sfx_volume()
	SoundManager.play_sfx("button_click")
	_update_audio_buttons()

func _on_music_toggle() -> void:
	SoundManager.cycle_music_volume()
	SoundManager.play_sfx("button_click")
	_update_audio_buttons()

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

func open_pause() -> void:
	if subtitle_label:
		var diff_name = GameManager.get_difficulty_name()
		subtitle_label.text = "DIFFICULTY: %s (LOCKED)  |  WAVE %d / 20  |  GOLD: %d  |  BONES: %d" % [diff_name, GameManager.current_wave, GameManager.coins, GameManager.bones_held]
		subtitle_label.modulate = GameManager.get_difficulty_color()
	_update_fullscreen_button()
	_update_audio_buttons()
	visible = true
	get_tree().paused = true
	SoundManager.play_sfx("button_click")

func close_pause() -> void:
	visible = false
	get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen") or (event is InputEventKey and event.pressed and not event.is_echo() and (event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed))):
		_on_fullscreen_toggle()
		get_viewport().set_input_as_handled()
		return
		
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		var main_node = get_tree().current_scene
		if main_node and "level_up_ui" in main_node and is_instance_valid(main_node.level_up_ui) and main_node.level_up_ui.is_active:
			return
			
		if visible:
			_on_resume_pressed()
			get_viewport().set_input_as_handled()
		elif GameManager.current_state == GameManager.GameState.PLAYING:
			open_pause()
			get_viewport().set_input_as_handled()

func _on_resume_pressed() -> void:
	SoundManager.play_sfx("button_click")
	close_pause()
	emit_signal("resume_requested")

func _on_save_quit_pressed() -> void:
	SoundManager.play_sfx("buy_item")
	GameManager.save_current_run("PLAYING")
	close_pause()
	emit_signal("save_and_quit_requested")

func _on_restart_pressed() -> void:
	SoundManager.play_sfx("button_click")
	GameManager.delete_saved_run()
	close_pause()
	emit_signal("restart_requested")

func _on_menu_pressed() -> void:
	SoundManager.play_sfx("button_click")
	close_pause()
	emit_signal("menu_requested")
