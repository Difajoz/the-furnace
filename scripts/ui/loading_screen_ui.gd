# loading_screen_ui.gd - Atmospheric "The Furnace" Intro Splash & Loading Screen
class_name LoadingScreenUI
extends CanvasLayer

signal loading_completed()

@onready var root_control: Control = $Root
@onready var title_label: Label = $Root/Center/VBox/TitleContainer/TitleLabel
@onready var subtitle_label: Label = $Root/Center/VBox/TitleContainer/SubtitleLabel
@onready var progress_bar: ProgressBar = $Root/Center/VBox/LoadingBox/BarFrame/ProgressBar
@onready var progress_label: Label = $Root/Center/VBox/LoadingBox/HeaderHBox/ProgressLabel
@onready var status_label: Label = $Root/Center/VBox/LoadingBox/HeaderHBox/StatusLabel
@onready var prompt_label: Label = $Root/Center/VBox/PromptLabel
@onready var ember_canvas: Control = $Root/EmberCanvas

var progress_val: float = 0.0
var target_progress: float = 0.0
var is_loaded: bool = false
var anim_time: float = 0.0
var status_index: int = 0
var status_timer: float = 0.0

const STATUS_MESSAGES = [
	"IGNITING THE INFERNAL HEARTH...",
	"TEMPERING CRUCIBLE PLATES...",
	"GATHERING CRYPT HORDE ASHES...",
	"STOKING FORGE TEMPERATURE...",
	"FORGING ARSENAL WEAPONS...",
	"FURNACE ONLINE & PRIMED!"
]

# Embers particle system
var embers: Array[Dictionary] = []
const MAX_EMBERS = 65

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = true
	if prompt_label:
		prompt_label.visible = false
		prompt_label.modulate.a = 0.0
		
	if progress_bar:
		progress_bar.value = 0.0
		
	if ember_canvas:
		ember_canvas.draw.connect(_draw_embers)
		
	# Initialize glowing embers
	var vp_size = get_viewport().get_visible_rect().size
	if vp_size == Vector2.ZERO:
		vp_size = Vector2(1600, 920)
	for i in range(MAX_EMBERS):
		_spawn_ember(true, vp_size)
		
	# Play opening furnace roar / whoosh
	SoundManager.play_sfx("steam_hiss", 0.1, 4.0)

func _spawn_ember(random_y: bool, vp_size: Vector2) -> void:
	var x = randf_range(0.0, vp_size.x)
	var y = randf_range(0.0, vp_size.y) if random_y else vp_size.y + randf_range(10.0, 50.0)
	var speed = randf_range(45.0, 140.0)
	var size = randf_range(2.0, 6.5)
	var drift_speed = randf_range(1.0, 3.0)
	var drift_phase = randf_range(0.0, TAU)
	var life = randf_range(3.5, 7.0)
	var max_life = life
	# Molten color palette: yellow-white, golden-orange, flame-red
	var col_roll = randf()
	var color = Color8(255, 235, 120, 240)
	if col_roll < 0.35:
		color = Color8(255, 100, 30, 240)
	elif col_roll < 0.7:
		color = Color8(255, 175, 40, 240)
	else:
		color = Color8(255, 255, 210, 255)
		
	embers.append({
		"pos": Vector2(x, y),
		"speed": speed,
		"size": size,
		"drift_speed": drift_speed,
		"drift_phase": drift_phase,
		"life": life,
		"max_life": max_life,
		"color": color
	})

func _process(delta: float) -> void:
	anim_time += delta
	var vp_size = get_viewport().get_visible_rect().size
	if vp_size == Vector2.ZERO:
		vp_size = Vector2(1600, 920)
	
	# Update and redraw embers
	_update_embers(delta, vp_size)
	if ember_canvas:
		ember_canvas.queue_redraw()
		
	# Loading progress simulation (takes ~2.2 seconds to reach 100%)
	if not is_loaded:
		target_progress = min(100.0, target_progress + delta * 46.0)
		progress_val = lerp(progress_val, target_progress, delta * 8.0)
		
		if progress_bar:
			progress_bar.value = progress_val
		if progress_label:
			progress_label.text = "%d%%" % int(progress_val)
			
		status_timer += delta
		if status_timer >= 0.40 and status_index < STATUS_MESSAGES.size() - 1:
			status_timer = 0.0
			status_index += 1
			if status_label:
				status_label.text = STATUS_MESSAGES[status_index]
				
		if progress_val >= 99.5:
			progress_val = 100.0
			is_loaded = true
			if progress_bar: progress_bar.value = 100.0
			if progress_label: progress_label.text = "100%"
			if status_label: status_label.text = STATUS_MESSAGES[-1]
			_on_loading_finished()
			
	# Title pulse animation
	if title_label:
		var glow = 0.88 + sin(anim_time * 3.5) * 0.16
		var col_pulse = Color(1.0 * glow, 0.58 * glow, 0.14 * glow, 1.0)
		title_label.modulate = col_pulse
		
	# Prompt blinking animation when ready
	if is_loaded and prompt_label:
		prompt_label.modulate.a = 0.5 + sin(anim_time * 5.0) * 0.5

func _update_embers(delta: float, vp_size: Vector2) -> void:
	var to_remove = []
	for i in range(embers.size()):
		var emb = embers[i]
		emb["life"] -= delta
		if emb["life"] <= 0.0 or emb["pos"].y < -20.0:
			to_remove.append(i)
			continue
			
		emb["pos"].y -= emb["speed"] * delta
		emb["pos"].x += sin(anim_time * emb["drift_speed"] + emb["drift_phase"]) * 35.0 * delta
		
	# Remove dead embers in reverse
	for i in range(to_remove.size() - 1, -1, -1):
		embers.remove_at(to_remove[i])
		
	while embers.size() < MAX_EMBERS:
		_spawn_ember(false, vp_size)

func _draw_embers() -> void:
	if not ember_canvas: return
	
	# Draw ambient hearth background heat vignette
	var vp_size = get_viewport().get_visible_rect().size
	if vp_size == Vector2.ZERO:
		vp_size = Vector2(1600, 920)
	var center = Vector2(vp_size.x * 0.5, vp_size.y * 0.55)
	var glow_radius = vp_size.y * 0.65
	var heat_alpha = 0.18 + sin(anim_time * 2.5) * 0.05
	
	# Molten radial gradient
	ember_canvas.draw_circle(center, glow_radius, Color(1.0, 0.35, 0.05, heat_alpha * 0.45))
	ember_canvas.draw_circle(center, glow_radius * 0.6, Color(1.0, 0.55, 0.1, heat_alpha * 0.7))
	ember_canvas.draw_circle(center, glow_radius * 0.25, Color(1.0, 0.85, 0.3, heat_alpha * 0.9))
	
	# Draw particle embers
	for emb in embers:
		var life_ratio = clamp(emb["life"] / emb["max_life"], 0.0, 1.0)
		var a = sin(life_ratio * PI) # Smooth fade in and out
		var col = emb["color"]
		col.a = a * 0.95
		
		# Draw glowing halo & core spark
		ember_canvas.draw_circle(emb["pos"], emb["size"] * 1.8, Color(col.r, col.g, col.b, a * 0.25))
		ember_canvas.draw_circle(emb["pos"], emb["size"] * 0.8, col)
		ember_canvas.draw_circle(emb["pos"], emb["size"] * 0.35, Color(1.0, 1.0, 1.0, a))

func _on_loading_finished() -> void:
	SoundManager.play_sfx("wave_start", 0.05, 2.0)
	if prompt_label:
		prompt_label.visible = true
		var tw = create_tween()
		tw.tween_property(prompt_label, "modulate:a", 1.0, 0.35)
		
	# Automatically transition after brief pause if no input
	var auto_timer = get_tree().create_timer(1.2)
	auto_timer.timeout.connect(func():
		if visible and is_loaded:
			_dismiss_loading()
	)

func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
		if is_loaded:
			_dismiss_loading()
			get_viewport().set_input_as_handled()
		else:
			# Fast-forward loading
			target_progress = 100.0
			get_viewport().set_input_as_handled()

func _dismiss_loading() -> void:
	if not visible: return
	set_process_unhandled_input(false)
	SoundManager.play_sfx("button_click")
	
	var tw = create_tween()
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(root_control, "modulate:a", 0.0, 0.45)
	tw.tween_callback(func():
		visible = false
		emit_signal("loading_completed")
	)
