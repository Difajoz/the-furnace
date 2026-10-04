# zombie_spawner.gd - Dynamic Wave Progression, 27 Monster Variants, Shooting Hordes, and Boss Encounters
class_name ZombieSpawner
extends Node2D

const ARENA_MIN_X: float = -720.0
const ARENA_MAX_X: float = 720.0
const ARENA_MIN_Y: float = -520.0
const ARENA_MAX_Y: float = 520.0

const MONSTER_LORE = {
	EnemyBase.EnemyType.SLIME: {
		"name": "Green Slime",
		"role": "Jumping Swarmer",
		"desc": "Leaping acidic biter",
		"texture": "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Slimes/Green_Slime/SlimeGreenJumpAttack.png"
	},
	EnemyBase.EnemyType.GIANT_RAT: {
		"name": "Giant Sewer Rat",
		"role": "Fast Rusher",
		"desc": "Fast gnawing swarm runner",
		"texture": "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Giant_Rat/RatWalk.png"
	},
	EnemyBase.EnemyType.BAT: {
		"name": "Vampiric Bat",
		"role": "Erratic Flyer",
		"desc": "Fast swooping aerial biter",
		"texture": "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Beasts/Bat/BatFlyIdle.png"
	},
	EnemyBase.EnemyType.GOBLIN: {
		"name": "Goblin Cutthroat",
		"role": "Melee Brawler",
		"desc": "Crypt blade slasher",
		"texture": "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Base_Humanoids/Goblin/GoblinWalk.png"
	},
	EnemyBase.EnemyType.WOLF: {
		"name": "Shadow Wolf",
		"role": "Pack Flanker",
		"desc": "Fast predatory flanker",
		"texture": "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Beasts/Wolf/WolfWalk.png"
	},
	EnemyBase.EnemyType.SKELETON_ARCHER: {
		"name": "Skeleton Archer",
		"role": "Ranged Sniper",
		"desc": "Fires piercing bone arrows",
		"texture": "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Undead/Skeleton/SkeletonWalk.png"
	},
	EnemyBase.EnemyType.WILDFIRE_WISP: {
		"name": "Wildfire Wisp",
		"role": "Fire Spitter",
		"desc": "Shoots seeking burning fireballs",
		"texture": "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Undead/Wildfire/WildfireFly.png"
	},
	EnemyBase.EnemyType.EVIL_SNOWMAN: {
		"name": "Frost Snowman",
		"role": "Ice Spitter",
		"desc": "Hurls slowing snowballs",
		"texture": "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Monsters/Evil_Snowman/EvilSnowmanActivation.png"
	},
	EnemyBase.EnemyType.TRASGO: {
		"name": "Trasgo Imp",
		"role": "Spinning Roller",
		"desc": "Fast rolling spinning tackle",
		"texture": "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Monsters/Trasgo/TrasgoWalk.png"
	},
	EnemyBase.EnemyType.GNOLL: {
		"name": "Gnoll Marauder",
		"role": "Heavy Cleaver",
		"desc": "Heavy curved scimitar slasher",
		"texture": "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Gnoll/GnollWalk.png"
	},
	EnemyBase.EnemyType.WILD_ORC: {
		"name": "Wild Orc",
		"role": "Aggressive Rusher",
		"desc": "Berserker melee charger",
		"texture": "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Base_Humanoids/Orc/Wild Orc/WildOrcWalk.png"
	},
	EnemyBase.EnemyType.PUMPKIN_HORROR: {
		"name": "Pumpkin Horror",
		"role": "Pyromancer",
		"desc": "Shoots cursed fire embers",
		"texture": "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Monsters/Pumpkin_Horror/PumpkinHorrorBaseWalk.png"
	},
	EnemyBase.EnemyType.PREDATORY_MUSHROOM: {
		"name": "Spore Spitter",
		"role": "Toxic Mortar",
		"desc": "Lobs caustic acid pools",
		"texture": "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Predatory_Mushroom/PredatoryMushroomWalk.png"
	},
	EnemyBase.EnemyType.DEMON_SPIDER: {
		"name": "Demon Spider",
		"role": "Leaping Assassin",
		"desc": "Pounces for venomous slam",
		"texture": "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Demon_Spider/DemonSpiderWalk.png"
	},
	EnemyBase.EnemyType.WEREWOLF: {
		"name": "Werewolf",
		"role": "Claw Lunger",
		"desc": "Rapid multi-claw frenzy",
		"texture": "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Werewolf/WerewolfWalk.png"
	},
	EnemyBase.EnemyType.CHEST_MIMIC: {
		"name": "Crucible Mimic",
		"role": "Furnace Devourer",
		"desc": "Spikes furnace heat",
		"texture": "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Chest_Mimic/Agressive Chest Mimic/AggressiveChestMimicWalk.png"
	},
	EnemyBase.EnemyType.MINOTAUR: {
		"name": "Minotaur",
		"role": "Charging Pusher",
		"desc": "Heavy charging ram & knockback",
		"texture": "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Monsters/Minotaur/MinotaurWalk.png"
	},
	EnemyBase.EnemyType.TROLL: {
		"name": "Forest Troll",
		"role": "Regenerating Heavy",
		"desc": "Regenerates HP over time",
		"texture": "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Monsters/Troll/TrollWalk.png"
	},
	EnemyBase.EnemyType.CYCLOPS: {
		"name": "Cyclops",
		"role": "Boulder Hurler",
		"desc": "Hurls heavy stone boulders",
		"texture": "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Monsters/Cyclop/CyclopWalk.png"
	},
	EnemyBase.EnemyType.DEEP_ONE: {
		"name": "Deep One",
		"role": "Armored Juggernaut",
		"desc": "Armored trident brute",
		"texture": "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Deep_One/DeepOneWalk.png"
	},
	EnemyBase.EnemyType.BRAIN_SLAYER: {
		"name": "Brain Slayer",
		"role": "Psionic Caster",
		"desc": "Channels piercing energy bolts",
		"texture": "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Brain_Slayer/BrainSlayerWalk.png"
	},
	EnemyBase.EnemyType.GARGOYLE: {
		"name": "Gargoyle",
		"role": "Flying Tank",
		"desc": "Armored flying stone tank",
		"texture": "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Gargoyle/GargoyleFly.png"
	},
	EnemyBase.EnemyType.RAT_ROYALTY: {
		"name": "Rat Shaman",
		"role": "Cultist Healer",
		"desc": "Heals nearby horde allies",
		"texture": "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Rat_People_Royalty/RatPeopleRoyaltyWalk.png"
	},
	EnemyBase.EnemyType.CHAOS_EYE: {
		"name": "Chaos Eye",
		"role": "Shooter - Tri-Split",
		"desc": "Projectiles split into 3 in flight",
		"texture": "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Undead/Wildfire/WildfireFly.png"
	},
	EnemyBase.EnemyType.RICOCHET_CULTIST: {
		"name": "Void Cultist",
		"role": "Shooter - Ricochet",
		"desc": "Orbs bounce off arena walls",
		"texture": "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Rat_People_Royalty/RatPeopleRoyaltyWalk.png"
	},
	EnemyBase.EnemyType.BOSS_CRYPT_ABOMINATION: {
		"name": "Crypt Abomination",
		"role": "Boss - Necrotic Titan",
		"desc": "Toxic ground slams & minion surge",
		"texture": "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Undead/Zombie/ZombieWalk.png"
	},
	EnemyBase.EnemyType.BOSS_CENTAUR_KING: {
		"name": "Centaur King",
		"role": "Boss - Cleaver",
		"desc": "Charging shockwave slashes",
		"texture": "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Centaur_King/CentaurKingWalk.png"
	},
	EnemyBase.EnemyType.BOSS_IRONHORN_MINOTAUR: {
		"name": "Ironhorn Minotaur",
		"role": "Boss - Foundry Crusher",
		"desc": "Seismic ram & flaming rock quakes",
		"texture": "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Monsters/Minotaur/MinotaurWalk.png"
	},
	EnemyBase.EnemyType.BOSS_PSIONIC_OVERLORD: {
		"name": "Psionic Overlord",
		"role": "Boss - Void Arch-Demon",
		"desc": "Psychic beam barrage & warp orbs",
		"texture": "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Brain_Slayer/BrainSlayerWalk.png"
	},
	EnemyBase.EnemyType.BOSS_GIANT_TITAN: {
		"name": "Giant Titan",
		"role": "Boss - Earth Stomper",
		"desc": "8-way seismic rock stomps",
		"texture": "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Giant/GiantWalk.png"
	},
	EnemyBase.EnemyType.BOSS_YETI_BEHEMOTH: {
		"name": "Yeti Behemoth",
		"role": "Boss - Frost Colossus",
		"desc": "Radial blizzard & snow boulders",
		"texture": "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Monsters/Yeti/YetiWalk.png"
	},
	EnemyBase.EnemyType.BOSS_GARGOYLE_SOVEREIGN: {
		"name": "Gargoyle Sovereign",
		"role": "Boss - Obsidian Dread",
		"desc": "Aerial dive slams & stone shrapnel",
		"texture": "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Gargoyle/GargoyleFly.png"
	},
	EnemyBase.EnemyType.BOSS_ANGEL_OF_DEATH: {
		"name": "Angel of Death",
		"role": "Supreme Boss",
		"desc": "Death blades & homing souls",
		"texture": "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Angel_of_Death/AngelOfDeathFly.png"
	}
}

var spawn_timer: float = 0.0
var base_spawn_interval: float = 2.0
var max_concurrent_enemies: int = 14
var minibosses_spawned_this_wave: int = 0
var target_minibosses_this_wave: int = 0

func _ready() -> void:
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.wave_cleared.connect(_on_wave_cleared)

func reset_spawner() -> void:
	clear_all_wave_enemies()
	spawn_timer = 0.0
	minibosses_spawned_this_wave = 0
	target_minibosses_this_wave = 0

func clear_all_wave_enemies() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e):
			e.queue_free()

func _get_miniboss_target_for_wave(wave: int) -> int:
	match wave:
		1: return 0
		2: return 1
		3: return 4
		4: return 8
		5: return 12
		6: return 16
		7: return 20 # By wave 7, spawn 20 minibosses randomly in the wave
		8: return 24
		9: return 28
		10: return 32
		11: return 36
		12: return 40
		13: return 44
		14: return 48
		15: return 52
		_: return int(20 + (wave - 7) * 4)

func _on_wave_started(wave_num: int) -> void:
	clear_all_wave_enemies()
	spawn_timer = 0.4
	minibosses_spawned_this_wave = 0
	var base_target = _get_miniboss_target_for_wave(wave_num)
	if GameManager.selected_difficulty == GameManager.Difficulty.HARD:
		target_minibosses_this_wave = int(ceil(base_target * 1.35))
	elif GameManager.selected_difficulty == GameManager.Difficulty.EASY:
		target_minibosses_this_wave = int(base_target * 0.75)
	else:
		target_minibosses_this_wave = base_target
		
	var lvl_bonus = GameManager.player_level * 0.9
	var density_mult = GameManager.get_difficulty_density_mult()
	max_concurrent_enemies = int(clamp((14 + wave_num * 1.65 + lvl_bonus) * density_mult, 10, 60))
	base_spawn_interval = clamp((1.6 - (wave_num * 0.03) - (GameManager.player_level * 0.009)) / density_mult, 0.28, 1.8)
	
	# Spawn Bosses starting early (Wave 3) and recurring every 2 waves!
	match wave_num:
		3:
			_spawn_boss(EnemyBase.EnemyType.BOSS_CRYPT_ABOMINATION, wave_num)
		5:
			_spawn_boss(EnemyBase.EnemyType.BOSS_CENTAUR_KING, wave_num)
		7:
			_spawn_boss(EnemyBase.EnemyType.BOSS_IRONHORN_MINOTAUR, wave_num)
		9:
			_spawn_boss(EnemyBase.EnemyType.BOSS_PSIONIC_OVERLORD, wave_num)
		11:
			_spawn_boss(EnemyBase.EnemyType.BOSS_GIANT_TITAN, wave_num)
		13:
			_spawn_boss(EnemyBase.EnemyType.BOSS_YETI_BEHEMOTH, wave_num)
		15:
			_spawn_boss(EnemyBase.EnemyType.BOSS_GARGOYLE_SOVEREIGN, wave_num)
		17:
			_spawn_boss(EnemyBase.EnemyType.BOSS_CENTAUR_KING, wave_num)
			_spawn_boss(EnemyBase.EnemyType.BOSS_IRONHORN_MINOTAUR, wave_num)
		19:
			_spawn_boss(EnemyBase.EnemyType.BOSS_GIANT_TITAN, wave_num)
			_spawn_boss(EnemyBase.EnemyType.BOSS_YETI_BEHEMOTH, wave_num)
		20:
			_spawn_boss(EnemyBase.EnemyType.BOSS_ANGEL_OF_DEATH, wave_num)
			_spawn_boss(EnemyBase.EnemyType.BOSS_PSIONIC_OVERLORD, wave_num)
			_spawn_boss(EnemyBase.EnemyType.BOSS_GARGOYLE_SOVEREIGN, wave_num)

func _on_wave_cleared(_wave_num: int) -> void:
	clear_all_wave_enemies()

func _process(delta: float) -> void:
	if not GameManager.is_wave_running or GameManager.current_state != GameManager.GameState.PLAYING:
		return
		
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = base_spawn_interval
		_spawn_monster_group()

func _spawn_monster_group() -> void:
	var current_enemies = get_tree().get_nodes_in_group("enemies").size()
	if current_enemies >= max_concurrent_enemies:
		return
		
	var parent_node = get_parent()
	if not is_instance_valid(parent_node): return
	
	var wave = GameManager.current_wave
	var group_size = 1
	if wave >= 3 and randf() < 0.25:
		group_size = randi_range(2, 3)
	if wave >= 7 and randf() < 0.30:
		group_size = randi_range(2, 3)
	if wave >= 12 and randf() < 0.35:
		group_size = randi_range(3, 4)
		
	var spawn_pos = _get_safe_arena_spawn_pos()
	var m_type = _pick_monster_type_for_wave(wave)
	
	# Determine if a miniboss should spawn in this group
	var remaining_minibosses = target_minibosses_this_wave - minibosses_spawned_this_wave
	var spawn_miniboss = false
	if remaining_minibosses > 0:
		var time_ratio = clamp(GameManager.wave_timer / max(1.0, GameManager.wave_duration), 0.05, 1.0)
		var spawn_chance = clamp(float(remaining_minibosses) / (float(max(1, target_minibosses_this_wave)) * time_ratio), 0.25, 0.90)
		if randf() < spawn_chance:
			spawn_miniboss = true
			minibosses_spawned_this_wave += 1
	elif wave >= 7 and randf() < 0.22:
		spawn_miniboss = true
	
	var is_elite = (randf() < clamp(0.05 + wave * 0.032, 0.05, 0.35)) and wave >= 3
	
	for i in range(group_size):
		var offset = Vector2(randf_range(-30, 30), randf_range(-30, 30))
		var monster = EnemyBase.new()
		parent_node.add_child(monster)
		
		# Clamp strictly inside arena
		var final_pos = Vector2(
			clamp(spawn_pos.x + offset.x, ARENA_MIN_X + 20, ARENA_MAX_X - 20),
			clamp(spawn_pos.y + offset.y, ARENA_MIN_Y + 20, ARENA_MAX_Y - 20)
		)
		monster.global_position = final_pos
		
		if i == 0 and spawn_miniboss:
			monster.init_enemy(m_type, wave, false, true)
		else:
			monster.init_enemy(m_type, wave, is_elite if i == 0 else false, false)

func _spawn_boss(boss_type: EnemyBase.EnemyType, wave: int) -> void:
	var parent_node = get_parent()
	if not is_instance_valid(parent_node): return
	
	var spawn_pos = _get_safe_arena_spawn_pos()
	var boss = EnemyBase.new()
	parent_node.add_child(boss)
	boss.global_position = spawn_pos
	boss.init_enemy(boss_type, wave, false, false)
	
	SoundManager.play_sfx("wave_start", 0.1, 4.0)
	GameManager.emit_signal("screen_shake_requested", 14.0, 0.6)
	GameManager.emit_signal("show_damage_number", spawn_pos + Vector2(0, -60), "BOSS SPAWNED!", Color(1.0, 0.1, 0.1), true)

func _pick_monster_type_for_wave(wave: int) -> EnemyBase.EnemyType:
	# 25% Shooters / 75% Melee and Special monsters balance across all waves
	var is_shooter_roll = (randf() < 0.25)
	
	if is_shooter_roll:
		# Available shooters unlocking progressively by wave
		var available_shooters: Array[EnemyBase.EnemyType] = []
		available_shooters.append(EnemyBase.EnemyType.SKELETON_ARCHER)
		
		if wave >= 2:
			available_shooters.append(EnemyBase.EnemyType.WILDFIRE_WISP)
		if wave >= 4:
			available_shooters.append(EnemyBase.EnemyType.EVIL_SNOWMAN)
			available_shooters.append(EnemyBase.EnemyType.PUMPKIN_HORROR)
		if wave >= 6:
			available_shooters.append(EnemyBase.EnemyType.PREDATORY_MUSHROOM)
			available_shooters.append(EnemyBase.EnemyType.CHAOS_EYE)
		if wave >= 8:
			available_shooters.append(EnemyBase.EnemyType.CYCLOPS)
			available_shooters.append(EnemyBase.EnemyType.BRAIN_SLAYER)
			available_shooters.append(EnemyBase.EnemyType.RICOCHET_CULTIST)
			
		return available_shooters[randi() % available_shooters.size()]
	else:
		# Available melee, chargers, leapers, and tanks
		var available_melee: Array[EnemyBase.EnemyType] = []
		available_melee.append(EnemyBase.EnemyType.SLIME)
		available_melee.append(EnemyBase.EnemyType.GIANT_RAT)
		available_melee.append(EnemyBase.EnemyType.BAT)
		
		if wave >= 2:
			available_melee.append(EnemyBase.EnemyType.GOBLIN)
			available_melee.append(EnemyBase.EnemyType.WOLF)
		if wave >= 4:
			available_melee.append(EnemyBase.EnemyType.TRASGO)
			available_melee.append(EnemyBase.EnemyType.WILD_ORC)
			available_melee.append(EnemyBase.EnemyType.GNOLL)
			available_melee.append(EnemyBase.EnemyType.DEMON_SPIDER)
		if wave >= 6:
			available_melee.append(EnemyBase.EnemyType.WEREWOLF)
			available_melee.append(EnemyBase.EnemyType.CHEST_MIMIC)
			available_melee.append(EnemyBase.EnemyType.MINOTAUR)
		if wave >= 9:
			available_melee.append(EnemyBase.EnemyType.TROLL)
			available_melee.append(EnemyBase.EnemyType.DEEP_ONE)
			available_melee.append(EnemyBase.EnemyType.GARGOYLE)
			available_melee.append(EnemyBase.EnemyType.RAT_ROYALTY)
			
		return available_melee[randi() % available_melee.size()]

static func get_new_monsters_for_wave(wave: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var types_to_add: Array[EnemyBase.EnemyType] = []
	
	match wave:
		1:
			types_to_add = [EnemyBase.EnemyType.SLIME, EnemyBase.EnemyType.GIANT_RAT, EnemyBase.EnemyType.BAT, EnemyBase.EnemyType.SKELETON_ARCHER]
		2:
			types_to_add = [EnemyBase.EnemyType.GOBLIN, EnemyBase.EnemyType.WOLF, EnemyBase.EnemyType.WILDFIRE_WISP]
		3:
			types_to_add = [EnemyBase.EnemyType.BOSS_CRYPT_ABOMINATION]
		4:
			types_to_add = [EnemyBase.EnemyType.TRASGO, EnemyBase.EnemyType.WILD_ORC, EnemyBase.EnemyType.GNOLL, EnemyBase.EnemyType.DEMON_SPIDER, EnemyBase.EnemyType.EVIL_SNOWMAN, EnemyBase.EnemyType.PUMPKIN_HORROR]
		5:
			types_to_add = [EnemyBase.EnemyType.BOSS_CENTAUR_KING]
		6:
			types_to_add = [EnemyBase.EnemyType.WEREWOLF, EnemyBase.EnemyType.CHEST_MIMIC, EnemyBase.EnemyType.MINOTAUR, EnemyBase.EnemyType.PREDATORY_MUSHROOM, EnemyBase.EnemyType.CHAOS_EYE]
		7:
			types_to_add = [EnemyBase.EnemyType.BOSS_IRONHORN_MINOTAUR]
		8:
			types_to_add = [EnemyBase.EnemyType.CYCLOPS, EnemyBase.EnemyType.BRAIN_SLAYER, EnemyBase.EnemyType.RICOCHET_CULTIST]
		9:
			types_to_add = [EnemyBase.EnemyType.BOSS_PSIONIC_OVERLORD, EnemyBase.EnemyType.TROLL, EnemyBase.EnemyType.DEEP_ONE, EnemyBase.EnemyType.GARGOYLE, EnemyBase.EnemyType.RAT_ROYALTY]
		11:
			types_to_add = [EnemyBase.EnemyType.BOSS_GIANT_TITAN]
		13:
			types_to_add = [EnemyBase.EnemyType.BOSS_YETI_BEHEMOTH]
		15:
			types_to_add = [EnemyBase.EnemyType.BOSS_GARGOYLE_SOVEREIGN]
		20:
			types_to_add = [EnemyBase.EnemyType.BOSS_ANGEL_OF_DEATH]
			
	for m_type in types_to_add:
		if MONSTER_LORE.has(m_type):
			var lore = MONSTER_LORE[m_type].duplicate(true)
			lore["type"] = m_type
			result.append(lore)
			
	return result


func _get_safe_arena_spawn_pos() -> Vector2:
	var side = randi() % 4
	var pos = Vector2.ZERO
	match side:
		0: # Top edge
			pos = Vector2(randf_range(ARENA_MIN_X + 40, ARENA_MAX_X - 40), ARENA_MIN_Y + 30)
		1: # Bottom edge
			pos = Vector2(randf_range(ARENA_MIN_X + 40, ARENA_MAX_X - 40), ARENA_MAX_Y - 30)
		2: # Left edge
			pos = Vector2(ARENA_MIN_X + 30, randf_range(ARENA_MIN_Y + 40, ARENA_MAX_Y - 40))
		3: # Right edge
			pos = Vector2(ARENA_MAX_X - 30, randf_range(ARENA_MIN_Y + 40, ARENA_MAX_Y - 40))
			
	return pos
