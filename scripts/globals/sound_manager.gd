# SoundManager.gd - Procedural Synthesizer for Retro Arcade SFX & Dynamic Soundtrack
extends Node

# Audio buses / players
var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_players: int = 16
var current_player_idx: int = 0
var music_player: AudioStreamPlayer
var furnace_hum_player: AudioStreamPlayer
var alarm_player: AudioStreamPlayer

var sfx_cache: Dictionary = {}
var sound_enabled: bool = true
var music_enabled: bool = true

var cached_bgm_track: AudioStreamWAV = null
var cached_victory_music: AudioStreamWAV = null
var cached_defeat_music: AudioStreamWAV = null

var sfx_volume_step: int = 4 # 4=100%, 3=75%, 2=50%, 1=25%, 0=MUTED
var music_volume_step: int = 4
const VOLUME_STEPS = [0.0, 0.25, 0.50, 0.75, 1.0]
const VOLUME_LABELS = ["MUTED", "25%", "50%", "75%", "100%"]

func cycle_sfx_volume() -> String:
	sfx_volume_step = (sfx_volume_step - 1) if sfx_volume_step > 0 else 4
	sound_enabled = (sfx_volume_step > 0)
	if not sound_enabled:
		for p in sfx_players:
			if is_instance_valid(p): p.stop()
		if is_instance_valid(furnace_hum_player):
			furnace_hum_player.stop()
			furnace_hum_player.volume_db = -80.0
		if is_instance_valid(alarm_player):
			alarm_player.stop()
	return get_sfx_volume_label()

func cycle_music_volume() -> String:
	music_volume_step = (music_volume_step - 1) if music_volume_step > 0 else 4
	music_enabled = (music_volume_step > 0)
	_update_music_volume()
	return get_music_volume_label()

func get_sfx_volume_label() -> String:
	return VOLUME_LABELS[sfx_volume_step]

func get_music_volume_label() -> String:
	return VOLUME_LABELS[music_volume_step]

func _update_music_volume() -> void:
	if not is_instance_valid(music_player): return
	if not music_enabled or music_volume_step == 0:
		music_player.stop()
		music_player.volume_db = -80.0
	else:
		var mult = VOLUME_STEPS[music_volume_step]
		music_player.volume_db = -12.0 + linear_to_db(mult)
		if not music_player.playing:
			start_gameplay_music()

func toggle_sound() -> bool:
	cycle_sfx_volume()
	return sound_enabled

func toggle_music() -> bool:
	cycle_music_volume()
	return music_enabled

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Create pool of AudioStreamPlayers for SFX
	for i in range(max_sfx_players):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sfx_players.append(p)
		
	# Music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	music_player.volume_db = -12.0
	add_child(music_player)
	
	# Furnace continuous hum
	furnace_hum_player = AudioStreamPlayer.new()
	furnace_hum_player.bus = "Master"
	furnace_hum_player.volume_db = -80.0
	add_child(furnace_hum_player)
	
	# Alarm player
	alarm_player = AudioStreamPlayer.new()
	alarm_player.bus = "Master"
	alarm_player.volume_db = -12.0
	add_child(alarm_player)
	
	_generate_all_sfx()
	cached_bgm_track = _synth_bgm_track()
	cached_victory_music = _synth_calm_victory_music()
	cached_defeat_music = _synth_calm_defeat_music()
	_start_bgm()

func play_sfx(sfx_name: String, pitch_rnd: float = 0.1, volume_offset: float = 0.0) -> void:
	if not sound_enabled or sfx_volume_step == 0 or not sfx_cache.has(sfx_name):
		return
	var player = sfx_players[current_player_idx]
	current_player_idx = (current_player_idx + 1) % max_sfx_players
	
	player.stream = sfx_cache[sfx_name]
	player.pitch_scale = randf_range(1.0 - pitch_rnd, 1.0 + pitch_rnd)
	var mult = VOLUME_STEPS[sfx_volume_step]
	player.volume_db = volume_offset + linear_to_db(mult)
	player.play()

func _generate_all_sfx() -> void:
	sfx_cache["shoot_pistol"] = _synth_tone(0.12, 600, 150, "square", 0.25)
	sfx_cache["shoot_smg"] = _synth_tone(0.08, 750, 200, "noise_mix", 0.22)
	sfx_cache["shoot_shotgun"] = _synth_noise(0.25, 400, 80, 0.40)
	sfx_cache["shoot_rifle"] = _synth_tone(0.14, 520, 180, "saw", 0.25)
	sfx_cache["shoot_sniper"] = _synth_tone(0.35, 900, 80, "saw", 0.45)
	sfx_cache["shoot_laser"] = _synth_tone(0.15, 1200, 300, "sine", 0.22)
	sfx_cache["shoot_rocket"] = _synth_noise(0.35, 300, 60, 0.45)
	sfx_cache["shoot_plasma"] = _synth_tone(0.2, 800, 200, "sine", 0.30)
	sfx_cache["shoot_lightning"] = _synth_tone(0.18, 1500, 100, "noise_mix", 0.25)
	sfx_cache["shoot_bone"] = _synth_tone(0.15, 450, 120, "triangle", 0.25)
	sfx_cache["shoot_minigun"] = _synth_tone(0.06, 680, 220, "square", 0.20)
	sfx_cache["shoot_boomerang"] = _synth_tone(0.18, 320, 560, "triangle", 0.25)
	sfx_cache["shoot_vortex"] = _synth_tone(0.3, 180, 40, "saw", 0.35)
	sfx_cache["shoot_shuriken"] = _synth_tone(0.09, 850, 400, "sine", 0.22)
	sfx_cache["shoot_revolver"] = _synth_noise(0.22, 500, 90, 0.45)
	sfx_cache["shoot_arcane"] = _synth_arpeggio([659, 880, 1046], 0.04, "sine", 0.25)
	sfx_cache["monster_charge"] = _synth_noise(0.4, 250, 60, 0.40)
	sfx_cache["monster_roll"] = _synth_tone(0.25, 200, 400, "saw", 0.25)
	sfx_cache["monster_spit"] = _synth_tone(0.12, 380, 120, "triangle", 0.25)
	sfx_cache["melee_swing"] = _synth_tone(0.15, 300, 80, "sine", 0.30)
	sfx_cache["explosion"] = _synth_noise(0.5, 180, 30, 0.50)
	sfx_cache["water_spray"] = _synth_noise(0.1, 1000, 600, 0.12)
	sfx_cache["steam_hiss"] = _synth_noise(0.3, 1400, 700, 0.35)
	sfx_cache["coin_pickup"] = _synth_arpeggio([880, 1174, 1760], 0.05, "sine", 0.25)
	sfx_cache["bone_pickup"] = _synth_tone(0.08, 300, 500, "triangle", 0.20)
	sfx_cache["furnace_feed"] = _synth_furnace_feed_crunch()
	sfx_cache["furnace_crash"] = _synth_noise(0.8, 250, 40, 0.65)
	sfx_cache["player_hit"] = _synth_tone(0.18, 350, 100, "saw", 0.35)
	sfx_cache["dash"] = _synth_noise(0.18, 800, 200, 0.25)
	sfx_cache["enemy_hit"] = _synth_tone(0.06, 400, 150, "square", 0.18)
	sfx_cache["enemy_die"] = _synth_tone(0.14, 250, 70, "triangle", 0.22)
	# Soft, gentle, ear-pleasing soothing chime for level up!
	sfx_cache["level_up"] = _synth_calm_levelup()
	sfx_cache["buy_item"] = _synth_arpeggio([600, 900, 1200], 0.06, "sine", 0.25)
	sfx_cache["button_click"] = _synth_tone(0.05, 700, 900, "sine", 0.16)
	sfx_cache["wave_start"] = _synth_arpeggio([440, 554, 659, 880], 0.1, "saw", 0.30)
	sfx_cache["wave_clear"] = _synth_arpeggio([523, 659, 784, 1046, 1318], 0.12, "sine", 0.35)
	sfx_cache["alarm_warning"] = _synth_alarm(0.4, 600, 900, 0.25)
	sfx_cache["warning"] = sfx_cache["alarm_warning"]
	sfx_cache["alarm_overheat"] = _synth_alarm(0.2, 900, 1200, 0.35)
	sfx_cache["furnace_loop"] = _synth_rumble_loop(2.0, 0.25)

func update_furnace_audio(temp_ratio: float, is_overheated: bool) -> void:
	if not sound_enabled or temp_ratio <= 0.0:
		if is_instance_valid(furnace_hum_player):
			furnace_hum_player.stop()
			furnace_hum_player.volume_db = -80.0
		if is_instance_valid(alarm_player):
			alarm_player.stop()
		return
		
	if is_overheated:
		if is_instance_valid(furnace_hum_player):
			furnace_hum_player.volume_db = -80.0
			furnace_hum_player.stop()
		if is_instance_valid(alarm_player):
			if not alarm_player.playing or alarm_player.stream != sfx_cache.get("alarm_overheat"):
				alarm_player.stream = sfx_cache.get("alarm_overheat")
				alarm_player.play()
		return
	else:
		if is_instance_valid(alarm_player) and alarm_player.playing and alarm_player.stream == sfx_cache.get("alarm_overheat"):
			alarm_player.stop()
		
	if temp_ratio > 0.05:
		if is_instance_valid(furnace_hum_player):
			if not furnace_hum_player.playing:
				furnace_hum_player.stream = sfx_cache.get("furnace_loop")
				furnace_hum_player.play()
			furnace_hum_player.volume_db = lerp(-25.0, -6.0, temp_ratio)
			furnace_hum_player.pitch_scale = lerp(0.8, 1.6, temp_ratio)
	else:
		if is_instance_valid(furnace_hum_player):
			furnace_hum_player.volume_db = -80.0
			furnace_hum_player.stop()
		
	if temp_ratio > 0.85:
		if is_instance_valid(alarm_player):
			if not alarm_player.playing:
				alarm_player.stream = sfx_cache.get("alarm_warning")
				alarm_player.play()
			alarm_player.pitch_scale = lerp(1.0, 1.4, (temp_ratio - 0.85) / 0.15)
	else:
		if is_instance_valid(alarm_player) and alarm_player.playing and alarm_player.stream == sfx_cache.get("alarm_warning"):
			alarm_player.stop()

func reset_audio_state() -> void:
	# Stop all active SFX voices
	for p in sfx_players:
		if is_instance_valid(p):
			p.stop()
			p.stream = null
	# Stop furnace hum loop and alarm sirens
	if is_instance_valid(furnace_hum_player):
		furnace_hum_player.stop()
		furnace_hum_player.volume_db = -80.0
	if is_instance_valid(alarm_player):
		alarm_player.stop()
	# Start gameplay background music
	start_gameplay_music()

func start_gameplay_music() -> void:
	if not music_enabled:
		if is_instance_valid(music_player):
			music_player.stop()
		return
	if is_instance_valid(music_player):
		if music_player.playing and music_player.stream == cached_bgm_track:
			return
		music_player.stop()
		if not cached_bgm_track:
			cached_bgm_track = _synth_bgm_track()
		music_player.stream = cached_bgm_track
		music_player.volume_db = -10.0
		music_player.play()

func stop_all_audio_for_game_end() -> void:
	# Stop all active SFX voices
	for p in sfx_players:
		if is_instance_valid(p):
			p.stop()
			p.stream = null
	# Stop background music, furnace hum loop, and alarms
	if is_instance_valid(music_player):
		music_player.stop()
	if is_instance_valid(furnace_hum_player):
		furnace_hum_player.stop()
		furnace_hum_player.volume_db = -80.0
	if is_instance_valid(alarm_player):
		alarm_player.stop()

func play_victory_music() -> void:
	stop_all_audio_for_game_end()
	if not music_enabled: return
	if not cached_victory_music:
		cached_victory_music = _synth_calm_victory_music()
	music_player.stream = cached_victory_music
	music_player.volume_db = -10.0
	music_player.play()

func play_defeat_music() -> void:
	stop_all_audio_for_game_end()
	if not music_enabled: return
	if not cached_defeat_music:
		cached_defeat_music = _synth_calm_defeat_music()
	music_player.stream = cached_defeat_music
	music_player.volume_db = -10.0
	music_player.play()

func _synth_calm_levelup() -> AudioStreamWAV:
	# Soft, peaceful, gentle crystal chime (F4, A4, C5, F5, A5)
	var sample_rate = 22050
	var freqs = [349.23, 440.00, 523.25, 698.46, 880.00]
	var duration = 0.85
	var total_samples = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	var note_stagger = 0.08
	
	for i in range(total_samples):
		var t = float(i) / float(sample_rate)
		var sample_sum = 0.0
		
		for n in range(freqs.size()):
			var start_t = n * note_stagger
			if t >= start_t:
				var nt = t - start_t
				var f = freqs[n]
				# Pure gentle sine tone with soft bell harmonics
				var s1 = sin(nt * f * TAU)
				var s2 = sin(nt * f * 2.0 * TAU) * 0.25
				var env = (1.0 - exp(-nt * 30.0)) * exp(-nt * 3.8)
				sample_sum += (s1 + s2) * env * 0.18
				
		var clamped = clamp(sample_sum, -0.95, 0.95)
		data.encode_s16(i * 2, int(clamped * 32767.0))
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.data = data
	return stream

func _synth_furnace_feed_crunch() -> AudioStreamWAV:
	# Layered multi-timbre sound: Crisp bone click/snap + resonant forged iron chime + hearth ember whoosh
	var sample_rate = 22050
	var duration = 0.32
	var total_samples = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	var bone_clicks = [0.0, 0.024, 0.052]
	var iron_freqs = [285.0, 570.0, 855.0]
	var last_noise = 0.0
	
	for i in range(total_samples):
		var t = float(i) / float(sample_rate)
		var sample_sum = 0.0
		
		# 1. Crisp bone clicks & crunch transient
		for bc in bone_clicks:
			if t >= bc:
				var bt = t - bc
				var b_env = exp(-bt * 95.0)
				var b_snap = (sin(bt * 1450.0 * TAU) + (randf() * 2.0 - 1.0) * 0.75) * b_env * 0.28
				sample_sum += b_snap
				
		# 2. Resonant cast-iron crucible chime
		if t >= 0.012:
			var it = t - 0.012
			var iron_env = (1.0 - exp(-it * 110.0)) * exp(-it * 15.0)
			var iron_wave = sin(it * iron_freqs[0] * TAU) * 0.6 + sin(it * iron_freqs[1] * TAU) * 0.32 + sin(it * iron_freqs[2] * TAU) * 0.16
			sample_sum += iron_wave * iron_env * 0.38
			
		# 3. Hearth fiery surge / whoosh
		if t >= 0.035:
			var ft = t - 0.035
			var flame_env = sin(clamp(ft / 0.26, 0.0, 1.0) * PI)
			var raw_n = randf() * 2.0 - 1.0
			last_noise = lerp(last_noise, raw_n, 0.14) # Warm low-pass filter
			sample_sum += last_noise * flame_env * 0.26
			
		var final_v = clamp(sample_sum * 0.90, -0.95, 0.95)
		data.encode_s16(i * 2, int(final_v * 32767.0))
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.data = data
	return stream

func _synth_calm_victory_music() -> AudioStreamWAV:
	# 9-Second Serene, Calming Harp & Warm Pad Victory Theme (Cmaj7 -> Fmaj7 -> Gsus4 -> C)
	var sample_rate = 22050
	var duration = 9.0
	var total_samples = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	# Gentle melodic harp notes (C4, E4, G4, B4, C5, E5, D5, G5, C6)
	var notes = [261.63, 329.63, 392.00, 493.88, 523.25, 659.25, 587.33, 783.99, 1046.50]
	var starts = [0.0, 0.45, 0.9, 1.4, 2.0, 2.8, 3.6, 4.5, 5.6]
	var sub_roots = [130.81, 174.61, 196.00, 130.81]
	
	for i in range(total_samples):
		var t = float(i) / float(sample_rate)
		var mix = 0.0
		
		# Warm background pad (soft sine waves)
		var pad_idx = clamp(int(t / 2.25), 0, 3)
		var pad_freq = sub_roots[pad_idx]
		var pad_env = min(1.0, t * 0.8) * min(1.0, (duration - t) * 0.8)
		var pad_val = (sin(t * pad_freq * TAU) * 0.5 + sin(t * pad_freq * 1.5 * TAU) * 0.3) * pad_env * 0.15
		mix += pad_val
		
		# Gentle acoustic harp arpeggio
		for n in range(notes.size()):
			var st = starts[n]
			if t >= st:
				var nt = t - st
				var f = notes[n]
				var s_harp = sin(nt * f * TAU) + sin(nt * f * 2.0 * TAU) * 0.2
				var h_env = (1.0 - exp(-nt * 35.0)) * exp(-nt * (1.2 if n == notes.size() - 1 else 2.2))
				mix += s_harp * h_env * 0.22
				
		var final_v = clamp(mix * 0.85, -0.95, 0.95)
		data.encode_s16(i * 2, int(final_v * 32767.0))
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.data = data
	return stream

func _synth_calm_defeat_music() -> AudioStreamWAV:
	# 8-Second Calming, Peaceful Lullaby Defeat Theme (Soft Ambient Chords)
	var sample_rate = 22050
	var duration = 8.0
	var total_samples = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	# Gentle soft music box notes (D4, F4, A4, C5, A4, F4, D4, Low D3)
	var notes = [293.66, 349.23, 440.00, 523.25, 440.00, 349.23, 293.66, 146.83]
	var starts = [0.0, 0.6, 1.2, 2.0, 3.0, 4.0, 5.0, 6.0]
	
	for i in range(total_samples):
		var t = float(i) / float(sample_rate)
		var mix = 0.0
		
		# Calming ambient low pad
		var pad_env = min(1.0, t * 0.7) * min(1.0, (duration - t) * 0.6)
		var pad_val = (sin(t * 146.83 * TAU) * 0.6 + sin(t * 220.00 * TAU) * 0.4) * pad_env * 0.16
		mix += pad_val
		
		for n in range(notes.size()):
			var st = starts[n]
			if t >= st:
				var nt = t - st
				var f = notes[n]
				var s_note = sin(nt * f * TAU) * 0.85 + sin(nt * f * 2.0 * TAU) * 0.15
				var n_env = (1.0 - exp(-nt * 25.0)) * exp(-nt * (1.1 if n == notes.size() - 1 else 2.0))
				mix += s_note * n_env * 0.20
				
		var final_v = clamp(mix * 0.85, -0.95, 0.95)
		data.encode_s16(i * 2, int(final_v * 32767.0))
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.data = data
	return stream

func _synth_tone(duration: float, start_freq: float, end_freq: float, wave_type: String, volume: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var total_samples = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	var phase = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var freq = lerp(start_freq, end_freq, t)
		var phase_step = (freq * 2.0 * PI) / sample_rate
		phase += phase_step
		
		var sample_val = 0.0
		match wave_type:
			"sine":
				sample_val = sin(phase)
			"square":
				sample_val = 1.0 if sin(phase) >= 0 else -1.0
			"saw":
				sample_val = (fposmod(phase, 2.0 * PI) / PI) - 1.0
			"triangle":
				sample_val = 2.0 * abs(2.0 * (phase / (2.0 * PI) - floor(phase / (2.0 * PI) + 0.5))) - 1.0
			"noise_mix":
				sample_val = sin(phase) * 0.7 + (randf() * 2.0 - 1.0) * 0.3
		
		var env = (1.0 - t) * (1.0 if i > 50 else float(i) / 50.0)
		var final_val = clamp(sample_val * env * volume, -1.0, 1.0)
		var int_sample = int(final_val * 32767.0)
		data.encode_s16(i * 2, int_sample)
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

func _synth_noise(duration: float, start_cutoff: float, end_cutoff: float, volume: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var total_samples = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	var last_val = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var cutoff = lerp(start_cutoff, end_cutoff, t)
		var alpha = clamp(cutoff / sample_rate, 0.01, 0.95)
		
		var raw_noise = randf() * 2.0 - 1.0
		last_val = last_val + alpha * (raw_noise - last_val)
		
		var env = (1.0 - t) * (1.0 if i > 100 else float(i) / 100.0)
		var final_val = clamp(last_val * env * volume * 2.0, -1.0, 1.0)
		var int_sample = int(final_val * 32767.0)
		data.encode_s16(i * 2, int_sample)
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

func _synth_arpeggio(freqs: Array, note_duration: float, wave_type: String, volume: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var total_samples = int(freqs.size() * note_duration * sample_rate)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	var samples_per_note = int(note_duration * sample_rate)
	var phase = 0.0
	
	for n in range(freqs.size()):
		var freq = freqs[n]
		var phase_step = (freq * 2.0 * PI) / sample_rate
		for i in range(samples_per_note):
			phase += phase_step
			var t_note = float(i) / float(samples_per_note)
			var sample_val = sin(phase) if wave_type == "sine" else (1.0 if sin(phase) >= 0 else -1.0)
			if wave_type == "saw":
				sample_val = (fposmod(phase, 2.0 * PI) / PI) - 1.0
			var env = (1.0 - t_note * 0.4) * (1.0 if i > 30 else float(i) / 30.0)
			var global_idx = n * samples_per_note + i
			var final_val = clamp(sample_val * env * volume, -1.0, 1.0)
			data.encode_s16(global_idx * 2, int(final_val * 32767.0))
			
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

func _synth_alarm(duration: float, f1: float, f2: float, volume: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var total_samples = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	var phase = 0.0
	for i in range(total_samples):
		var t = float(i) / float(total_samples)
		var freq = f1 if fposmod(t * 8.0, 1.0) < 0.5 else f2
		phase += (freq * 2.0 * PI) / sample_rate
		var sample_val = 1.0 if sin(phase) >= 0 else -1.0
		var final_val = clamp(sample_val * volume, -1.0, 1.0)
		data.encode_s16(i * 2, int(final_val * 32767.0))
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = total_samples
	stream.data = data
	return stream

func _synth_rumble_loop(duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var total_samples = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	var last_val = 0.0
	var phase = 0.0
	for i in range(total_samples):
		phase += (55.0 * 2.0 * PI) / sample_rate
		var raw_noise = randf() * 2.0 - 1.0
		last_val = last_val + 0.08 * (raw_noise - last_val)
		var sample_val = sin(phase) * 0.6 + last_val * 0.4
		var final_val = clamp(sample_val * volume, -1.0, 1.0)
		data.encode_s16(i * 2, int(final_val * 32767.0))
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = total_samples
	stream.data = data
	return stream

func _start_bgm() -> void:
	if not music_enabled:
		return
	if not cached_bgm_track:
		cached_bgm_track = _synth_bgm_track()
	music_player.stream = cached_bgm_track
	music_player.volume_db = -10.0
	music_player.play()

func _synth_bgm_track() -> AudioStreamWAV:
	# 32-Second Engaging, Atmospheric Retro-Chiptune Synth Soundtrack
	var sample_rate = 22050
	var duration = 32.0
	var total_samples = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	# 120 BPM -> 0.5s per beat, 64 beats total in 32 seconds (16 measures of 4/4)
	var beat_sec = 0.5
	var samples_per_beat = int(beat_sec * sample_rate)
	var samples_per_16th = int(samples_per_beat / 4.0)
	
	# Chord progression roots (D2, Bb1, F2, C2, D2, G1, Bb1, A1, D2, F2, G2, A1, Bb1, C2, D2, D2)
	var chord_roots = [
		73.42, 58.27, 87.31, 65.41,
		73.42, 49.00, 58.27, 55.00,
		73.42, 87.31, 98.00, 55.00,
		58.27, 65.41, 73.42, 73.42
	]
	
	# Chord triads for arpeggio (intervals in semitones above root)
	var chord_triads = [
		[0, 3, 7, 12, 15, 12, 7, 3], # Dm
		[0, 4, 7, 12, 14, 12, 7, 4], # Bb
		[0, 4, 7, 12, 16, 12, 7, 4], # F
		[0, 4, 7, 12, 14, 12, 7, 4], # C
		[0, 3, 7, 12, 15, 12, 7, 3], # Dm
		[0, 3, 7, 10, 15, 10, 7, 3], # Gm
		[0, 4, 7, 11, 14, 11, 7, 4], # Bbmaj7
		[0, 4, 7, 10, 12, 10, 7, 4], # A7
		[0, 3, 7, 12, 15, 12, 7, 3], # Dm
		[0, 4, 7, 12, 16, 12, 7, 4], # F
		[0, 3, 7, 12, 15, 12, 7, 3], # Gm
		[0, 4, 7, 10, 12, 10, 7, 4], # A7
		[0, 4, 7, 12, 14, 12, 7, 4], # Bb
		[0, 4, 7, 12, 14, 12, 7, 4], # C
		[0, 3, 7, 12, 15, 12, 7, 3], # Dm
		[0, 3, 7, 12, 15, 19, 15, 12] # Dm high flourish
	]
	
	# Melody notes per beat (in Hz)
	var melody_notes = [
		# Measures 1-4 (Intro Motive)
		293.66, 329.63, 349.23, 440.00,  466.16, 440.00, 349.23, 293.66,
		349.23, 392.00, 440.00, 523.25,  523.25, 466.16, 440.00, 392.00,
		# Measures 5-8 (Rise & Tension)
		392.00, 440.00, 466.16, 587.33,  587.33, 523.25, 440.00, 349.23,
		466.16, 523.25, 587.33, 698.46,  659.25, 587.33, 554.37, 440.00,
		# Measures 9-12 (Heroic Peak)
		587.33, 587.33, 659.25, 698.46,  698.46, 659.25, 587.33, 523.25,
		466.16, 523.25, 587.33, 698.46,  659.25, 587.33, 554.37, 440.00,
		# Measures 13-16 (Resolution & Loop Transition)
		466.16, 466.16, 523.25, 587.33,  523.25, 466.16, 440.00, 392.00,
		349.23, 392.00, 440.00, 523.25,  587.33, 440.00, 349.23, 293.66
	]
	
	var phase_bass = 0.0
	var phase_arp = 0.0
	var phase_lead = 0.0
	var noise_seed_val = 0.0
	
	for i in range(total_samples):
		var total_t = float(i) / float(sample_rate)
		var beat_idx = int(total_t / beat_sec) % 64
		var measure_idx = int(beat_idx / 4) % 16
		var beat_in_measure = beat_idx % 4
		var t_in_beat = fposmod(total_t, beat_sec) / beat_sec
		var t_in_16th = fposmod(total_t, beat_sec / 4.0) / (beat_sec / 4.0)
		var sixteenth_idx = int(total_t / (beat_sec / 4.0)) % 8
		
		# 1. Warm Bassline (Smooth Triangle + Low Sub Sine)
		var root_freq = chord_roots[measure_idx]
		# 8th note bounce: root on beat, octave on offbeat
		var is_offbeat = (t_in_beat > 0.5)
		var active_bass_freq = root_freq * (2.0 if is_offbeat and (beat_in_measure % 2 == 1) else 1.0)
		phase_bass += (active_bass_freq * 2.0 * PI) / sample_rate
		
		var bass_triangle = 2.0 * abs(2.0 * (phase_bass / (2.0 * PI) - floor(phase_bass / (2.0 * PI) + 0.5))) - 1.0
		var bass_sub = sin(phase_bass)
		var bass_env = (1.0 - fposmod(t_in_beat * 2.0, 1.0) * 0.4)
		var bass_out = (bass_triangle * 0.6 + bass_sub * 0.4) * bass_env * 0.32
		
		# 2. Arpeggio Harmony (Warm Sine Polyphony)
		var triad = chord_triads[measure_idx]
		var semi_offset = triad[sixteenth_idx]
		var arp_freq = root_freq * 4.0 * pow(2.0, semi_offset / 12.0)
		phase_arp += (arp_freq * 2.0 * PI) / sample_rate
		var arp_env = exp(-t_in_16th * 3.5)
		var arp_out = sin(phase_arp) * arp_env * 0.16
		
		# 3. Expressive Melody Lead (Smooth Chiptune with soft attack & vibrato)
		var melody_freq = melody_notes[beat_idx]
		var vibrato = sin(total_t * 6.0 * TAU) * 0.015
		var lead_freq_mod = melody_freq * (1.0 + vibrato)
		phase_lead += (lead_freq_mod * 2.0 * PI) / sample_rate
		
		var lead_sine = sin(phase_lead)
		var lead_pulse = (1.0 if sin(phase_lead) >= 0.2 else -1.0) * 0.3 + lead_sine * 0.7
		var lead_env = clamp(t_in_beat * 18.0, 0.0, 1.0) * (1.0 - t_in_beat * 0.35)
		var lead_out = lead_pulse * lead_env * 0.22
		
		# 4. Drums / Percussion (Gentle Kick, Snare, and Hats)
		var kick = 0.0
		if (beat_in_measure == 0 or beat_in_measure == 2):
			if t_in_beat < 0.25:
				var kick_freq = lerp(130.0, 42.0, t_in_beat / 0.25)
				kick = sin(t_in_beat * kick_freq * TAU) * exp(-t_in_beat * 16.0) * 0.45
				
		var snare = 0.0
		if (beat_in_measure == 1 or beat_in_measure == 3):
			if t_in_beat < 0.2:
				var raw_n = randf() * 2.0 - 1.0
				noise_seed_val = noise_seed_val + 0.35 * (raw_n - noise_seed_val)
				snare = noise_seed_val * exp(-t_in_beat * 20.0) * 0.28
				
		var hihat = 0.0
		if t_in_16th < 0.08:
			var hat_n = randf() * 2.0 - 1.0
			hihat = hat_n * exp(-t_in_16th * 60.0) * 0.10
			
		# Final Master Mix with Soft Limiting
		var master_mix = (bass_out + arp_out + lead_out + kick + snare + hihat) * 0.75
		var clamped_val = clamp(master_mix, -0.95, 0.95)
		data.encode_s16(i * 2, int(clamped_val * 32767.0))
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = total_samples
	stream.data = data
	return stream

