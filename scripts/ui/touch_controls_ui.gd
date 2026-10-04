# touch_controls_ui.gd - Mobile Virtual Joystick and On-Screen Action Controls
class_name TouchControlsUI
extends CanvasLayer

signal pause_requested()

# Virtual Joystick Variables
var joystick_active: bool = false
var joystick_touch_index: int = -1
var joystick_center: Vector2 = Vector2.ZERO
var joystick_current_pos: Vector2 = Vector2.ZERO
const JOYSTICK_MAX_RADIUS: float = 75.0

# Node References
@onready var root_control: Control = $Root
@onready var joystick_base: Control = $Root/LeftZone/JoystickBase
@onready var joystick_knob: Control = $Root/LeftZone/JoystickBase/Knob

@onready var dash_btn: Button = $Root/RightZone/DashButton
@onready var cool_btn: Button = $Root/RightZone/CoolButton
@onready var feed_btn: Button = $Root/RightZone/FeedButton
@onready var lock_btn: Button = $Root/RightZone/LockButton
@onready var pause_btn: Button = $Root/TopRightZone/PauseButton

@onready var skill_btn_0: Button = $Root/SkillsZone/Skill0
@onready var skill_btn_1: Button = $Root/SkillsZone/Skill1
@onready var skill_btn_2: Button = $Root/SkillsZone/Skill2

var is_mobile_environment: bool = false

func _ready() -> void:
	is_mobile_environment = OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available()
	
	visible = false
	
	_style_touch_buttons()
	_connect_button_signals()
	
	if joystick_base:
		joystick_center = joystick_base.size * 0.5
		_reset_joystick_knob()

func _style_touch_buttons() -> void:
	_style_round_btn(dash_btn, Color8(44, 245, 120), Color8(15, 45, 25, 210), Color8(120, 255, 170), Color8(25, 80, 45, 240))
	_style_round_btn(cool_btn, Color8(55, 200, 255), Color8(16, 38, 58, 210), Color8(150, 235, 255), Color8(30, 75, 115, 240))
	_style_round_btn(feed_btn, Color8(255, 195, 35), Color8(50, 32, 10, 210), Color8(255, 235, 120), Color8(85, 55, 15, 240))
	_style_round_btn(lock_btn, Color8(255, 75, 75), Color8(50, 15, 15, 210), Color8(255, 150, 150), Color8(85, 25, 25, 240))
	_style_round_btn(pause_btn, Color8(200, 210, 230), Color8(25, 28, 38, 210), Color8(255, 255, 255), Color8(45, 50, 68, 240))
	
	_style_round_btn(skill_btn_0, Color8(255, 120, 40), Color8(45, 22, 10, 210), Color8(255, 180, 100), Color8(75, 35, 15, 240))
	_style_round_btn(skill_btn_1, Color8(60, 220, 255), Color8(15, 40, 55, 210), Color8(150, 240, 255), Color8(25, 70, 95, 240))
	_style_round_btn(skill_btn_2, Color8(180, 100, 255), Color8(35, 18, 55, 210), Color8(220, 160, 255), Color8(60, 30, 95, 240))

func _style_round_btn(btn: Button, border_col: Color, bg_col: Color, hover_border_col: Color, hover_bg_col: Color) -> void:
	if not btn: return
	var sb_norm = StyleBoxFlat.new()
	sb_norm.bg_color = bg_col
	sb_norm.border_color = border_col
	sb_norm.set_border_width_all(3)
	sb_norm.set_corner_radius_all(32)
	
	var sb_pressed = StyleBoxFlat.new()
	sb_pressed.bg_color = hover_bg_col
	sb_pressed.border_color = hover_border_col
	sb_pressed.set_border_width_all(4)
	sb_pressed.set_corner_radius_all(32)
	
	btn.add_theme_stylebox_override("normal", sb_norm)
	btn.add_theme_stylebox_override("hover", sb_norm)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_stylebox_override("focus", sb_norm)

func _connect_button_signals() -> void:
	if dash_btn:
		dash_btn.button_down.connect(_on_dash_down)
	if cool_btn:
		cool_btn.button_down.connect(_on_cool_down)
		cool_btn.button_up.connect(_on_cool_up)
	if feed_btn:
		feed_btn.button_down.connect(_on_feed_down)
		feed_btn.button_up.connect(_on_feed_up)
	if lock_btn:
		lock_btn.button_down.connect(_on_lock_down)
	if pause_btn:
		pause_btn.pressed.connect(_on_pause_pressed)
		
	if skill_btn_0:
		skill_btn_0.pressed.connect(func(): GameManager.activate_skill(0))
	if skill_btn_1:
		skill_btn_1.pressed.connect(func(): GameManager.activate_skill(1))
	if skill_btn_2:
		skill_btn_2.pressed.connect(func(): GameManager.activate_skill(2))

func _process(_delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		if visible: visible = false
		return
	elif not visible:
		visible = true
		
	_update_skills_buttons()

func _update_skills_buttons() -> void:
	var btns = [skill_btn_0, skill_btn_1, skill_btn_2]
	for i in range(3):
		var b = btns[i]
		if not b: continue
		if i < GameManager.active_skills.size():
			var s = GameManager.active_skills[i]
			b.visible = true
			var tag = s.get("icon_tag", "SKL")
			var cd_cur = s.get("cooldown_timer", 0.0)
			var act_cur = s.get("active_timer", 0.0)
			if act_cur > 0.0:
				b.text = "%s\n%.1fs" % [tag, act_cur]
			elif cd_cur > 0.0:
				b.text = "%s\n%.1fs" % [tag, cd_cur]
			else:
				b.text = "%s\nREADY" % tag
		else:
			b.visible = false

func _on_dash_down() -> void:
	if is_instance_valid(GameManager.player_node) and GameManager.player_node.has_method("trigger_touch_dash"):
		GameManager.player_node.trigger_touch_dash()

func _on_cool_down() -> void:
	if is_instance_valid(GameManager.player_node) and GameManager.player_node.has_method("start_cooling"):
		GameManager.player_node.start_cooling()

func _on_cool_up() -> void:
	if is_instance_valid(GameManager.player_node) and GameManager.player_node.has_method("stop_cooling"):
		GameManager.player_node.stop_cooling()

func _on_feed_down() -> void:
	if is_instance_valid(GameManager.player_node) and GameManager.player_node.has_method("trigger_touch_feed"):
		GameManager.player_node.trigger_touch_feed(true)

func _on_feed_up() -> void:
	if is_instance_valid(GameManager.player_node) and GameManager.player_node.has_method("trigger_touch_feed"):
		GameManager.player_node.trigger_touch_feed(false)

func _on_lock_down() -> void:
	if is_instance_valid(GameManager.player_node) and GameManager.player_node.has_method("trigger_touch_lock_toggle"):
		GameManager.player_node.trigger_touch_lock_toggle()

func _on_pause_pressed() -> void:
	SoundManager.play_sfx("button_click")
	emit_signal("pause_requested")

# Joystick Touch Events
func _input(event: InputEvent) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING or not visible:
		return
		
	if event is InputEventScreenTouch:
		if event.pressed:
			var vp_size = get_viewport().get_visible_rect().size
			if event.position.x < vp_size.x * 0.45 and not joystick_active:
				joystick_active = true
				joystick_touch_index = event.index
				if joystick_base:
					joystick_base.global_position = event.position - (joystick_base.size * 0.5)
					joystick_center = joystick_base.size * 0.5
				_update_joystick_position(event.position)
		else:
			if event.index == joystick_touch_index:
				_release_joystick()
				
	elif event is InputEventScreenDrag:
		if event.index == joystick_touch_index and joystick_active:
			_update_joystick_position(event.position)

func _update_joystick_position(touch_global_pos: Vector2) -> void:
	if not joystick_base or not joystick_knob: return
	var base_center_global = joystick_base.global_position + joystick_center
	var offset = touch_global_pos - base_center_global
	var dist = offset.length()
	var dir = offset.normalized() if dist > 0.001 else Vector2.ZERO
	
	var clamped_dist = min(dist, JOYSTICK_MAX_RADIUS)
	var knob_local_pos = joystick_center + (dir * clamped_dist) - (joystick_knob.size * 0.5)
	joystick_knob.position = knob_local_pos
	
	var move_strength = clamp(dist / JOYSTICK_MAX_RADIUS, 0.0, 1.0)
	var final_move_vec = dir * move_strength
	if is_instance_valid(GameManager.player_node) and GameManager.player_node.has_method("set_touch_move_vector"):
		GameManager.player_node.set_touch_move_vector(final_move_vec)

func _release_joystick() -> void:
	joystick_active = false
	joystick_touch_index = -1
	_reset_joystick_knob()
	if is_instance_valid(GameManager.player_node) and GameManager.player_node.has_method("set_touch_move_vector"):
		GameManager.player_node.set_touch_move_vector(Vector2.ZERO)

func _reset_joystick_knob() -> void:
	if joystick_knob and joystick_base:
		joystick_knob.position = joystick_center - (joystick_knob.size * 0.5)
