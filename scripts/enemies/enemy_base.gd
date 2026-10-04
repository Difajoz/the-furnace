# enemy_base.gd - Minifantasy 8-Bit Monster Class with 27 Variants, Shooting AI, Charging/Rolling, and Balanced Drops
class_name EnemyBase
extends CharacterBody2D

signal enemy_died(enemy: EnemyBase)

enum EnemyType {
	SLIME,
	GIANT_RAT,
	BAT,
	GOBLIN,
	WOLF,
	SKELETON_ARCHER,
	WILDFIRE_WISP,
	EVIL_SNOWMAN,
	TRASGO,
	GNOLL,
	WILD_ORC,
	PUMPKIN_HORROR,
	PREDATORY_MUSHROOM,
	DEMON_SPIDER,
	WEREWOLF,
	CHEST_MIMIC,
	MINOTAUR,
	TROLL,
	CYCLOPS,
	DEEP_ONE,
	BRAIN_SLAYER,
	GARGOYLE,
	RAT_ROYALTY,
	CHAOS_EYE,
	RICOCHET_CULTIST,
	BOSS_CRYPT_ABOMINATION,
	BOSS_CENTAUR_KING,
	BOSS_IRONHORN_MINOTAUR,
	BOSS_PSIONIC_OVERLORD,
	BOSS_GIANT_TITAN,
	BOSS_YETI_BEHEMOTH,
	BOSS_GARGOYLE_SOVEREIGN,
	BOSS_ANGEL_OF_DEATH
}

# Preloaded assets & texture cache
static var texture_cache: Dictionary = {}
const FONT: Font = preload("res://assets/Ultrapixel.ttf")
const ACID_POOL_SCRIPT = preload("res://scripts/weapons/acid_pool.gd")
const BONE_PICKUP_SCRIPT = preload("res://scripts/pickups/bone_pickup.gd")
const PROJECTILE_SCRIPT = preload("res://scripts/weapons/projectile_base.gd")

# Configuration & Stats
var enemy_type: EnemyType = EnemyType.SLIME
var is_elite: bool = false
var is_miniboss: bool = false
var is_boss: bool = false
var max_hp: float = 25.0
var hp: float = 25.0
var base_speed: float = 110.0
var contact_damage: float = 12.0
var knockback_resist: float = 0.1
var bone_drop_count: int = 1
var radius: float = 16.0
var monster_name: String = "Slime"

# Physics & Motion
var knockback_velocity: Vector2 = Vector2.ZERO
var target_node: Node2D = null
var is_targeting_furnace: bool = false

# Combat & Attack cooldowns
var attack_cooldown_timer: float = 0.0
var attack_cooldown_interval: float = 0.55

# Status Effects
var slow_factor: float = 0.0
var slow_timer: float = 0.0
var burn_dps: float = 0.0
var burn_timer: float = 0.0
var burn_tick_timer: float = 0.0
var is_frozen: bool = false
var freeze_timer: float = 0.0
var hit_flash_timer: float = 0.0

# Special Type Behaviors
var spitter_shoot_timer: float = 0.0
var leaper_state: int = 0 # 0=stalk, 1=windup, 2=leap
var leaper_timer: float = 0.0
var leap_target_pos: Vector2 = Vector2.ZERO
var charge_state: int = 0 # 0=stalk, 1=windup, 2=charging
var charge_timer: float = 0.0
var charge_dir: Vector2 = Vector2.ZERO
var healer_pulse_timer: float = 0.0
var poison_trail_timer: float = 0.0
var boss_special_timer: float = 0.0

# Boss 3-Attack Pattern System
var boss_attack_cycle_timer: float = 2.0
var boss_attack_cycle_index: int = 0
var boss_charge_state: int = 0 # 0=idle/stalk, 1=windup/telegraph, 2=charging rush
var boss_charge_timer: float = 0.0
var boss_charge_dir: Vector2 = Vector2.ZERO

# Sprite & Animation
var sprite_node: Sprite2D = null
var anim_timer: float = 0.0
var anim_fps: float = 6.0
var h_frames: int = 4
var v_frames: int = 4
var sprite_scale: float = 1.0
var walk_tex_path: String = ""
var attack_tex_path: String = ""
var is_attacking_anim: bool = false
var attack_anim_duration: float = 0.0
var col_shape: CollisionShape2D = null

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 3
	
	_setup_stats_and_sprite()
	
	col_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius
	col_shape.shape = shape
	add_child(col_shape)

func init_enemy(type: EnemyType, wave: int, elite: bool = false, miniboss: bool = false) -> void:
	enemy_type = type
	is_elite = elite
	is_miniboss = miniboss
	_setup_stats_and_sprite()
	
	# Wave Scaling & Difficulty Scaling
	var wave_scaling = 1.0 + (wave - 1) * 0.16
	max_hp *= wave_scaling * GameManager.get_difficulty_enemy_hp_mult()
	contact_damage *= (1.0 + (wave - 1) * 0.07) * GameManager.get_difficulty_enemy_dmg_mult()
	base_speed *= min(1.35, 1.0 + (wave - 1) * 0.015)
	
	if is_boss:
		# Extra boss wave scaling & difficulty scaling
		max_hp *= (1.0 + (wave - 1) * 0.12) * GameManager.get_difficulty_boss_hp_mult()
		knockback_resist = 0.96
	elif is_miniboss:
		# Miniboss: significantly more health, higher damage, drops 3 bones, visual scale/aura
		max_hp *= 4.5
		contact_damage *= 1.85
		bone_drop_count = 3
		knockback_resist = clamp(knockback_resist + 0.35, 0.45, 0.85)
		radius *= 1.35
		sprite_scale *= 1.40
		if sprite_node:
			sprite_node.scale = Vector2(sprite_scale * 4.5, sprite_scale * 4.5)
			sprite_node.modulate = Color(1.35, 0.7, 1.3) # Sinister glowing purple
	elif is_elite:
		max_hp *= 2.4
		contact_damage *= 1.3
		bone_drop_count += 1
		radius *= 1.2
		sprite_scale *= 1.15
		if sprite_node:
			sprite_node.scale = Vector2(sprite_scale * 4.5, sprite_scale * 4.5)
			sprite_node.modulate = Color(1.2, 0.9, 0.6)
			
	hp = max_hp
	if is_instance_valid(col_shape) and col_shape.shape is CircleShape2D:
		(col_shape.shape as CircleShape2D).radius = radius

func _setup_stats_and_sprite() -> void:
	is_boss = false
	is_targeting_furnace = false
	
	match enemy_type:
		EnemyType.SLIME:
			monster_name = "Green Slime"
			max_hp = 20.0
			base_speed = 105.0
			contact_damage = 10.0
			knockback_resist = 0.0
			bone_drop_count = 1
			radius = 28.0
			sprite_scale = 1.0
			walk_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Slimes/Green_Slime/SlimeGreenJumpAttack.png"
			attack_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Slimes/Green_Slime/SlimeGreenJumpAttack.png"
		EnemyType.GIANT_RAT:
			monster_name = "Giant Rat"
			max_hp = 18.0
			base_speed = 175.0
			contact_damage = 9.0
			knockback_resist = 0.0
			bone_drop_count = 1
			radius = 26.0
			sprite_scale = 1.0
			walk_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Giant_Rat/RatWalk.png"
			attack_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Giant_Rat/RatAttack.png"
		EnemyType.BAT:
			monster_name = "Vampiric Bat"
			max_hp = 16.0
			base_speed = 195.0
			contact_damage = 9.0
			knockback_resist = 0.0
			bone_drop_count = 1
			radius = 24.0
			sprite_scale = 1.0
			walk_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Beasts/Bat/BatFlyIdle.png"
			attack_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Beasts/Bat/BatAttack.png"
		EnemyType.GOBLIN:
			monster_name = "Goblin Cutthroat"
			max_hp = 35.0
			base_speed = 125.0
			contact_damage = 12.0
			knockback_resist = 0.1
			bone_drop_count = 1
			radius = 28.0
			sprite_scale = 1.0
			walk_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Base_Humanoids/Goblin/GoblinWalk.png"
			attack_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Base_Humanoids/Goblin/GoblinAttack.png"
		EnemyType.WOLF:
			monster_name = "Shadow Wolf"
			max_hp = 32.0
			base_speed = 180.0
			contact_damage = 14.0
			knockback_resist = 0.1
			bone_drop_count = 1
			radius = 28.0
			sprite_scale = 1.05
			walk_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Beasts/Wolf/WolfWalk.png"
			attack_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Beasts/Wolf/WolfAttack.png"
		EnemyType.SKELETON_ARCHER:
			monster_name = "Skeleton Archer"
			max_hp = 36.0
			base_speed = 95.0
			contact_damage = 11.0
			knockback_resist = 0.1
			bone_drop_count = 1
			radius = 28.0
			sprite_scale = 1.05
			spitter_shoot_timer = randf_range(1.5, 2.5)
			walk_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Undead/Skeleton/SkeletonWalk.png"
			attack_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Undead/Skeleton/SkeletonAttack.png"
		EnemyType.WILDFIRE_WISP:
			monster_name = "Wildfire Wisp"
			max_hp = 30.0
			base_speed = 130.0
			contact_damage = 13.0
			knockback_resist = 0.05
			bone_drop_count = 1
			radius = 26.0
			sprite_scale = 1.05
			spitter_shoot_timer = randf_range(1.8, 2.8)
			walk_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Undead/Wildfire/WildfireFly.png"
			attack_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Undead/Wildfire/WildfireFly.png"
		EnemyType.EVIL_SNOWMAN:
			monster_name = "Frost Snowman"
			max_hp = 42.0
			base_speed = 85.0
			contact_damage = 12.0
			knockback_resist = 0.2
			bone_drop_count = 1
			radius = 30.0
			sprite_scale = 1.1
			spitter_shoot_timer = randf_range(2.0, 3.2)
			walk_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Monsters/Evil_Snowman/EvilSnowmanActivation.png"
			attack_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Monsters/Evil_Snowman/EvilSnowmanAttack.png"
		EnemyType.TRASGO:
			monster_name = "Trasgo Rolling Imp"
			max_hp = 38.0
			base_speed = 110.0
			contact_damage = 14.0
			knockback_resist = 0.15
			bone_drop_count = 1
			radius = 28.0
			sprite_scale = 1.05
			charge_timer = randf_range(2.5, 4.0)
			walk_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Monsters/Trasgo/TrasgoWalk.png"
			attack_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Monsters/Trasgo/TrasgoChargedAttack.png"
		EnemyType.GNOLL:
			monster_name = "Gnoll Marauder"
			max_hp = 55.0
			base_speed = 110.0
			contact_damage = 15.0
			knockback_resist = 0.25
			bone_drop_count = 1
			radius = 32.0
			sprite_scale = 1.15
			walk_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Gnoll/GnollWalk.png"
			attack_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Gnoll/GnollAttack.png"
		EnemyType.WILD_ORC:
			monster_name = "Wild Orc Brawler"
			max_hp = 65.0
			base_speed = 135.0
			contact_damage = 16.0
			knockback_resist = 0.3
			bone_drop_count = 2
			radius = 32.0
			sprite_scale = 1.15
			walk_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Base_Humanoids/Orc/Wild Orc/WildOrcWalk.png"
			attack_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Base_Humanoids/Orc/Wild Orc/WildOrcAttack.png"
		EnemyType.PUMPKIN_HORROR:
			monster_name = "Pumpkin Horror"
			max_hp = 50.0
			base_speed = 90.0
			contact_damage = 14.0
			knockback_resist = 0.2
			bone_drop_count = 1
			radius = 30.0
			sprite_scale = 1.15
			spitter_shoot_timer = randf_range(2.0, 3.2)
			walk_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Monsters/Pumpkin_Horror/PumpkinHorrorBaseWalk.png"
			attack_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Monsters/Pumpkin_Horror/PumpkinHorrorBaseAttack.png"
		EnemyType.PREDATORY_MUSHROOM:
			monster_name = "Spore Spitter"
			max_hp = 45.0
			base_speed = 85.0
			contact_damage = 10.0
			knockback_resist = 0.15
			bone_drop_count = 1
			radius = 30.0
			sprite_scale = 1.15
			spitter_shoot_timer = randf_range(1.5, 3.0)
			walk_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Predatory_Mushroom/PredatoryMushroomWalk.png"
			attack_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Predatory_Mushroom/PredatoryMushroomAttack.png"
		EnemyType.DEMON_SPIDER:
			monster_name = "Demon Spider"
			max_hp = 44.0
			base_speed = 95.0
			contact_damage = 16.0
			knockback_resist = 0.2
			bone_drop_count = 1
			radius = 32.0
			sprite_scale = 1.15
			leaper_timer = randf_range(2.0, 3.5)
			walk_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Demon_Spider/DemonSpiderWalk.png"
			attack_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Demon_Spider/DemonSpiderAttack.png"
		EnemyType.WEREWOLF:
			monster_name = "Frenzied Werewolf"
			max_hp = 52.0
			base_speed = 165.0
			contact_damage = 18.0
			knockback_resist = 0.2
			bone_drop_count = 1
			radius = 32.0
			sprite_scale = 1.15
			walk_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Werewolf/WerewolfWalk.png"
			attack_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Werewolf/WerewolfAttack.png"
		EnemyType.CHEST_MIMIC:
			monster_name = "Crucible Mimic"
			max_hp = 70.0
			base_speed = 125.0
			contact_damage = 16.0
			knockback_resist = 0.3
			bone_drop_count = 1
			radius = 32.0
			sprite_scale = 1.1
			is_targeting_furnace = true
			walk_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Chest_Mimic/Agressive Chest Mimic/AggressiveChestMimicWalk.png"
			attack_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Chest_Mimic/Agressive Chest Mimic/AggressiveChestMimicActivation.png"
		EnemyType.MINOTAUR:
			monster_name = "Minotaur Juggernaut"
			max_hp = 110.0
			base_speed = 90.0
			contact_damage = 22.0
			knockback_resist = 0.7
			bone_drop_count = 2 # Heavy enemy: drops 2 bones
			radius = 38.0
			sprite_scale = 1.3
			charge_timer = randf_range(3.0, 4.5)
			walk_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Monsters/Minotaur/MinotaurWalk.png"
			attack_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Monsters/Minotaur/MinotaurAttack.png"
		EnemyType.TROLL:
			monster_name = "Forest Troll"
			max_hp = 130.0
			base_speed = 80.0
			contact_damage = 20.0
			knockback_resist = 0.65
			bone_drop_count = 2 # Heavy enemy: drops 2 bones
			radius = 38.0
			sprite_scale = 1.3
			walk_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Monsters/Troll/TrollWalk.png"
			attack_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Monsters/Troll/TrollAttack.png"
		EnemyType.CYCLOPS:
			monster_name = "Ancient Cyclops"
			max_hp = 100.0
			base_speed = 80.0
			contact_damage = 18.0
			knockback_resist = 0.5
			bone_drop_count = 2 # Heavy enemy: drops 2 bones
			radius = 36.0
			sprite_scale = 1.3
			spitter_shoot_timer = randf_range(2.5, 4.0)
			walk_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Monsters/Cyclop/CyclopWalk.png"
			attack_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Monsters/Cyclop/CyclopAttack.png"
		EnemyType.DEEP_ONE:
			monster_name = "Deep One Brute"
			max_hp = 95.0
			base_speed = 90.0
			contact_damage = 18.0
			knockback_resist = 0.5
			bone_drop_count = 2
			radius = 34.0
			sprite_scale = 1.2
			walk_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Deep_One/DeepOneWalk.png"
			attack_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Deep_One/DeepOneAttack.png"
		EnemyType.BRAIN_SLAYER:
			monster_name = "Brain Slayer"
			max_hp = 55.0
			base_speed = 90.0
			contact_damage = 14.0
			knockback_resist = 0.2
			bone_drop_count = 2
			radius = 32.0
			sprite_scale = 1.2
			spitter_shoot_timer = randf_range(2.0, 3.5)
			walk_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Brain_Slayer/BrainSlayerWalk.png"
			attack_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Brain_Slayer/BrainSlayerOrthogonalAttack.png"
		EnemyType.GARGOYLE:
			monster_name = "Stone Gargoyle"
			max_hp = 140.0
			base_speed = 80.0
			contact_damage = 22.0
			knockback_resist = 0.85
			bone_drop_count = 2
			radius = 36.0
			sprite_scale = 1.25
			walk_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Gargoyle/GargoyleFly.png"
			attack_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Gargoyle/GargoyleAttack.png"
		EnemyType.RAT_ROYALTY:
			monster_name = "Rat Shaman"
			max_hp = 80.0
			base_speed = 85.0
			contact_damage = 10.0
			knockback_resist = 0.3
			bone_drop_count = 2
			radius = 32.0
			sprite_scale = 1.2
			healer_pulse_timer = 2.5
			walk_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Rat_People_Royalty/RatPeopleRoyaltyWalk.png"
			attack_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Rat_People_Royalty/RatPeopleRoyaltyAttack.png"
		EnemyType.CHAOS_EYE:
			monster_name = "Chaos Eye"
			max_hp = 55.0
			base_speed = 95.0
			contact_damage = 14.0
			knockback_resist = 0.15
			bone_drop_count = 2
			radius = 30.0
			sprite_scale = 1.15
			spitter_shoot_timer = randf_range(2.0, 3.2)
			walk_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Undead/Wildfire/WildfireFly.png"
			attack_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Undead/Wildfire/WildfireFly.png"
		EnemyType.RICOCHET_CULTIST:
			monster_name = "Void Cultist"
			max_hp = 65.0
			base_speed = 90.0
			contact_damage = 15.0
			knockback_resist = 0.25
			bone_drop_count = 2
			radius = 32.0
			sprite_scale = 1.15
			spitter_shoot_timer = randf_range(2.2, 3.5)
			walk_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Rat_People_Royalty/RatPeopleRoyaltyWalk.png"
			attack_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Rat_People_Royalty/RatPeopleRoyaltyAttack.png"
		EnemyType.BOSS_CRYPT_ABOMINATION:
			monster_name = "Crypt Abomination"
			is_boss = true
			max_hp = 2400.0
			base_speed = 82.0
			contact_damage = 50.0
			knockback_resist = 0.96
			bone_drop_count = 6
			radius = 80.0
			sprite_scale = 2.15
			spitter_shoot_timer = 2.8
			walk_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Undead/Zombie/ZombieWalk.png"
			attack_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Undead/Zombie/ZombieAttack.png"
		EnemyType.BOSS_CENTAUR_KING:
			monster_name = "Centaur King"
			is_boss = true
			max_hp = 3800.0
			base_speed = 98.0
			contact_damage = 58.0
			knockback_resist = 0.96
			bone_drop_count = 6
			radius = 85.0
			sprite_scale = 2.25
			walk_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Centaur_King/CentaurKingWalk.png"
			attack_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Centaur_King/CentaurKingAttack.png"
		EnemyType.BOSS_IRONHORN_MINOTAUR:
			monster_name = "Ironhorn Minotaur"
			is_boss = true
			max_hp = 4800.0
			base_speed = 90.0
			contact_damage = 64.0
			knockback_resist = 0.96
			bone_drop_count = 7
			radius = 88.0
			sprite_scale = 2.30
			spitter_shoot_timer = 3.0
			walk_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Monsters/Minotaur/MinotaurWalk.png"
			attack_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Monsters/Minotaur/MinotaurAttack.png"
		EnemyType.BOSS_PSIONIC_OVERLORD:
			monster_name = "Psionic Overlord"
			is_boss = true
			max_hp = 5800.0
			base_speed = 88.0
			contact_damage = 60.0
			knockback_resist = 0.96
			bone_drop_count = 7
			radius = 84.0
			sprite_scale = 2.25
			spitter_shoot_timer = 2.6
			walk_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Brain_Slayer/BrainSlayerWalk.png"
			attack_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Brain_Slayer/BrainSlayerOrthogonalAttack.png"
		EnemyType.BOSS_GIANT_TITAN:
			monster_name = "Giant Titan"
			is_boss = true
			max_hp = 7000.0
			base_speed = 76.0
			contact_damage = 72.0
			knockback_resist = 0.97
			bone_drop_count = 8
			radius = 92.0
			sprite_scale = 2.35
			walk_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Giant/GiantWalk.png"
			attack_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Giant/GiantAttack.png"
		EnemyType.BOSS_YETI_BEHEMOTH:
			monster_name = "Yeti Behemoth"
			is_boss = true
			max_hp = 8200.0
			base_speed = 85.0
			contact_damage = 76.0
			knockback_resist = 0.97
			bone_drop_count = 8
			radius = 92.0
			sprite_scale = 2.35
			walk_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Monsters/Yeti/YetiWalk.png"
			attack_tex_path = "res://assets/Minifantasy_Creatures_v3.3_Free_Version/Minifantasy_Creatures_Assets/Monsters/Yeti/YetiAttack.png"
		EnemyType.BOSS_GARGOYLE_SOVEREIGN:
			monster_name = "Gargoyle Sovereign"
			is_boss = true
			max_hp = 9600.0
			base_speed = 88.0
			contact_damage = 70.0
			knockback_resist = 0.97
			bone_drop_count = 9
			radius = 90.0
			sprite_scale = 2.35
			spitter_shoot_timer = 3.0
			walk_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Gargoyle/GargoyleFly.png"
			attack_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Gargoyle/GargoyleAttack.png"
		EnemyType.BOSS_ANGEL_OF_DEATH:
			monster_name = "Angel of Death"
			is_boss = true
			max_hp = 12500.0
			base_speed = 98.0
			contact_damage = 85.0
			knockback_resist = 0.98
			bone_drop_count = 10
			radius = 90.0
			sprite_scale = 2.40
			walk_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Angel_of_Death/AngelOfDeathFly.png"
			attack_tex_path = "res://assets/Minifantasy_Monster_Creatures_v1.0/Minifantasy_Monster_Creatures_Assets/Angel_of_Death/AngelOfDeathAttack.png"

	_build_sprite()

func _build_sprite() -> void:
	if not sprite_node:
		sprite_node = Sprite2D.new()
		sprite_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite_node)
		
	var target_path = attack_tex_path if is_attacking_anim and attack_tex_path != "" else walk_tex_path
	if target_path == "": return
	if not texture_cache.has(target_path):
		texture_cache[target_path] = load(target_path)
	var tex = texture_cache[target_path]
	if tex and tex is Texture2D:
		sprite_node.texture = tex
		h_frames = max(1, int(tex.get_width() / 32))
		v_frames = max(1, int(tex.get_height() / 32))
		sprite_node.hframes = h_frames
		sprite_node.vframes = v_frames
		sprite_node.frame_coords = Vector2i(0, 0)
		sprite_node.scale = Vector2(sprite_scale * 4.5, sprite_scale * 4.5)

func trigger_attack_anim(duration: float = 0.35) -> void:
	is_attacking_anim = true
	attack_anim_duration = duration
	_build_sprite()

func _process(delta: float) -> void:
	if not is_frozen:
		anim_timer += delta
	_process_status_effects(delta)
	_process_special_ai(delta)
	
	# Toxic slime puddle trail for slimes, mushrooms, and bosses
	if (enemy_type in [EnemyType.SLIME, EnemyType.PREDATORY_MUSHROOM, EnemyType.BOSS_ANGEL_OF_DEATH, EnemyType.BOSS_GIANT_TITAN] or is_elite) and not is_frozen:
		poison_trail_timer += delta
		if poison_trail_timer >= 0.85 and velocity.length_squared() > 100.0:
			poison_trail_timer = 0.0
			_drop_poison_trail_pool()
	
	if attack_anim_duration > 0.0 and not is_frozen:
		attack_anim_duration -= delta
		if attack_anim_duration <= 0.0:
			is_attacking_anim = false
			_build_sprite()
			
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta
		
	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
		
	# Sprite Animation & Horizontal Flip
	if sprite_node and is_instance_valid(sprite_node):
		var col = int(anim_timer * anim_fps) % max(1, h_frames)
		sprite_node.frame_coords = Vector2i(col, 0)
		
		# Flip left / right based on velocity or aim
		if abs(velocity.x) > 5.0:
			sprite_node.flip_h = velocity.x < 0
		elif is_instance_valid(target_node):
			sprite_node.flip_h = (target_node.global_position.x < global_position.x)
			
		if hit_flash_timer > 0.0:
			sprite_node.modulate = Color(3.0, 3.0, 3.0, 1.0) # Bright white flash
		elif is_frozen:
			sprite_node.modulate = Color(0.2, 0.9, 1.8, 1.0) # Frozen cyan ice tint
		elif slow_factor > 0.3:
			sprite_node.modulate = Color(0.4, 0.8, 1.2, 1.0) # Ice blue tint
		elif burn_timer > 0.0:
			sprite_node.modulate = Color(1.3, 0.5, 0.2, 1.0) # Fire tint
		elif is_miniboss:
			sprite_node.modulate = Color(1.35, 0.7, 1.3) # Glowing sinister purple
		elif is_elite:
			sprite_node.modulate = Color(1.2, 0.9, 0.6)
		else:
			sprite_node.modulate = Color.WHITE

func _drop_poison_trail_pool() -> void:
	var parent_scene = get_tree().current_scene
	if not is_instance_valid(parent_scene): return
	var pool = ACID_POOL_SCRIPT.new()
	pool.is_enemy_hazard = true
	pool.damage_per_sec = max(6.0, contact_damage * 0.4)
	pool.duration = 4.0
	pool.radius = radius * 1.1
	parent_scene.add_child(pool)
	pool.global_position = global_position

func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
		
	_determine_target()
	_handle_movement(delta)
	_check_contact_damage(delta)
	move_and_slide()

func _determine_target() -> void:
	if is_targeting_furnace and is_instance_valid(GameManager.furnace_node):
		target_node = GameManager.furnace_node
	elif is_instance_valid(GameManager.player_node):
		target_node = GameManager.player_node
	else:
		target_node = null

func _handle_movement(delta: float) -> void:
	if is_frozen:
		velocity = Vector2.ZERO
		return
		
	if knockback_velocity.length_squared() > 1.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 850.0 * delta)
		return
		
	if not is_instance_valid(target_node):
		velocity = Vector2.ZERO
		return
		
	# Boss Melee Charge Rush
	if is_boss and boss_charge_state == 2:
		velocity = boss_charge_dir * 460.0
		return
	if is_boss and boss_charge_state == 1:
		velocity = Vector2.ZERO
		return
		
	# Demon Spider Leap
	if enemy_type == EnemyType.DEMON_SPIDER and leaper_state == 2:
		var to_leap = leap_target_pos - global_position
		if to_leap.length() < 20.0:
			leaper_state = 0
			leaper_timer = 2.5
			SoundManager.play_sfx("explosion", 0.3, -8.0)
			_deal_landing_damage()
		else:
			velocity = to_leap.normalized() * 520.0
		return
		
	if enemy_type == EnemyType.DEMON_SPIDER and leaper_state == 1:
		velocity = Vector2.ZERO
		return
		
	# Minotaur / Trasgo Charge & Roll
	if charge_state == 2:
		velocity = charge_dir * (450.0 if enemy_type == EnemyType.MINOTAUR else 480.0)
		return
	if charge_state == 1:
		velocity = Vector2.ZERO
		return
		
	var to_target = target_node.global_position - global_position
	var dist = to_target.length()
	var dir = to_target.normalized()
	
	# Ranged / Shooter AI: Maintain standoff distance and strafe laterally without blindly charging player
	var is_shooter_type = enemy_type in [
		EnemyType.PREDATORY_MUSHROOM,
		EnemyType.BRAIN_SLAYER,
		EnemyType.SKELETON_ARCHER,
		EnemyType.WILDFIRE_WISP,
		EnemyType.EVIL_SNOWMAN,
		EnemyType.PUMPKIN_HORROR,
		EnemyType.CYCLOPS,
		EnemyType.CHAOS_EYE,
		EnemyType.RICOCHET_CULTIST
	]
	
	if is_shooter_type:
		if dist < 240.0:
			# Player is too close: back away smoothly
			dir = -dir * 1.15
		elif dist < 430.0:
			# In ideal shooting range: strafe sideways instead of rushing in
			var strafe_side = 1.0 if int(anim_timer * 0.8) % 2 == 0 else -1.0
			dir = dir.orthogonal() * strafe_side * 0.55
		else:
			# Player is far: approach into shooting range
			dir = dir * 0.75
			
	# Bat sinusoidal wobble
	if enemy_type == EnemyType.BAT:
		dir = dir.rotated(sin(anim_timer * 8.0) * 0.4)
		
	var current_spd = base_speed * (1.0 - slow_factor)
	velocity = dir * current_spd

func _deal_landing_damage() -> void:
	if is_instance_valid(GameManager.player_node):
		var dist = global_position.distance_to(GameManager.player_node.global_position)
		if dist <= radius + 75.0:
			GameManager.damage_player(contact_damage * 1.5)

func _check_contact_damage(_delta: float) -> void:
	if is_frozen or attack_cooldown_timer > 0.0:
		return
		
	# Hit Player
	if is_instance_valid(GameManager.player_node):
		var dist = global_position.distance_to(GameManager.player_node.global_position)
		if dist <= radius + 60.0:
			attack_cooldown_timer = attack_cooldown_interval
			trigger_attack_anim(0.35)
			
			var dmg = contact_damage
			if is_boss and boss_charge_state == 2:
				dmg *= 1.5
				if GameManager.player_node.has_method("apply_knockback_push"):
					GameManager.player_node.apply_knockback_push(boss_charge_dir * 700.0)
				GameManager.emit_signal("screen_shake_requested", 12.0, 0.45)
			elif charge_state == 2:
				dmg *= 1.8
				# Massive push knockback from Minotaur / Trasgo charging ram
				if GameManager.player_node.has_method("apply_knockback_push"):
					GameManager.player_node.apply_knockback_push(charge_dir * 600.0)
				GameManager.emit_signal("screen_shake_requested", 9.0, 0.3)
				
			GameManager.damage_player(dmg)
			SoundManager.play_sfx("player_hit", 0.15)
			
	# Hit Furnace
	if is_instance_valid(GameManager.furnace_node):
		var dist_f = global_position.distance_to(GameManager.furnace_node.global_position)
		if dist_f <= radius + 70.0:
			if is_targeting_furnace or enemy_type == EnemyType.CHEST_MIMIC:
				attack_cooldown_timer = attack_cooldown_interval
				trigger_attack_anim(0.4)
				GameManager.furnace_node.take_damage(contact_damage * 1.5)

func _process_special_ai(delta: float) -> void:
	if is_frozen:
		return
		
	# Troll HP regeneration
	if enemy_type == EnemyType.TROLL and hp < max_hp:
		hp = min(max_hp, hp + delta * 3.5)
		
	# Boss 3-Attack Pattern AI (Melee Rush/Slam, 8-Way Radial Barrage, Targeted Spreading Split Shot)
	if is_boss:
		if boss_charge_state == 1:
			boss_charge_timer -= delta
			if boss_charge_timer <= 0.0:
				boss_charge_state = 2
				boss_charge_timer = 0.85
				trigger_attack_anim(0.85)
				SoundManager.play_sfx("monster_charge", 0.15, 2.0)
		elif boss_charge_state == 2:
			boss_charge_timer -= delta
			if boss_charge_timer <= 0.0:
				boss_charge_state = 0
				_boss_melee_ground_slam_finish()
		else:
			boss_attack_cycle_timer -= delta
			if boss_attack_cycle_timer <= 0.0 and is_instance_valid(GameManager.player_node):
				boss_attack_cycle_timer = randf_range(2.6, 3.2)
				var dist_to_p = global_position.distance_to(GameManager.player_node.global_position)
				
				# If player is very close (< 200px), prioritize heavy melee slam / rush (Attack 1)
				if dist_to_p < 200.0 and randf() < 0.65:
					_start_boss_melee_rush()
				else:
					boss_attack_cycle_index = (boss_attack_cycle_index + 1) % 4
					match boss_attack_cycle_index:
						0:
							# Attack Type 3: Targeted 5-Way Spreading / Cluster Split Shot
							trigger_attack_anim(0.5)
							_boss_spreading_split_shot()
						1:
							# Attack Type 2: 12/16-Directional Radial Barrage
							trigger_attack_anim(0.6)
							_boss_radial_barrage()
						2:
							# Attack Type 1: Heavy Melee Charge / Slam
							_start_boss_melee_rush()
						3:
							# Attack Type 4: Volcanic Eruption & Swarmer Minion Surge
							_boss_volcanic_eruption_and_summon()
		
	# Charging AI for Minotaur and Trasgo
	if enemy_type in [EnemyType.MINOTAUR, EnemyType.TRASGO]:
		if charge_state == 0:
			charge_timer -= delta
			if charge_timer <= 0.0 and is_instance_valid(GameManager.player_node):
				var dist = global_position.distance_to(GameManager.player_node.global_position)
				if dist < 450.0:
					charge_state = 1
					charge_timer = 0.55
					charge_dir = (GameManager.player_node.global_position - global_position).normalized()
					trigger_attack_anim(0.55)
					SoundManager.play_sfx("monster_charge", 0.2)
		elif charge_state == 1:
			charge_timer -= delta
			if charge_timer <= 0.0:
				charge_state = 2
				charge_timer = 1.1 if enemy_type == EnemyType.MINOTAUR else 1.3
				trigger_attack_anim(1.2)
				SoundManager.play_sfx("monster_roll" if enemy_type == EnemyType.TRASGO else "monster_charge", 0.2)
		elif charge_state == 2:
			charge_timer -= delta
			if charge_timer <= 0.0:
				charge_state = 0
				charge_timer = randf_range(3.0, 4.5)

	match enemy_type:
		EnemyType.SKELETON_ARCHER:
			spitter_shoot_timer -= delta
			if spitter_shoot_timer <= 0.0 and is_instance_valid(GameManager.player_node):
				spitter_shoot_timer = randf_range(1.8, 2.8)
				trigger_attack_anim(0.4)
				_skeleton_shoot()
		EnemyType.WILDFIRE_WISP:
			spitter_shoot_timer -= delta
			if spitter_shoot_timer <= 0.0 and is_instance_valid(GameManager.player_node):
				spitter_shoot_timer = randf_range(2.0, 3.0)
				trigger_attack_anim(0.4)
				_wildfire_shoot()
		EnemyType.EVIL_SNOWMAN:
			spitter_shoot_timer -= delta
			if spitter_shoot_timer <= 0.0 and is_instance_valid(GameManager.player_node):
				spitter_shoot_timer = randf_range(2.2, 3.2)
				trigger_attack_anim(0.4)
				_snowman_shoot()
		EnemyType.PUMPKIN_HORROR:
			spitter_shoot_timer -= delta
			if spitter_shoot_timer <= 0.0 and is_instance_valid(GameManager.player_node):
				spitter_shoot_timer = randf_range(2.2, 3.2)
				trigger_attack_anim(0.4)
				_pumpkin_shoot()
		EnemyType.CYCLOPS:
			spitter_shoot_timer -= delta
			if spitter_shoot_timer <= 0.0 and is_instance_valid(GameManager.player_node):
				spitter_shoot_timer = randf_range(2.8, 4.2)
				trigger_attack_anim(0.5)
				_cyclops_rock_throw()
		EnemyType.PREDATORY_MUSHROOM:
			spitter_shoot_timer -= delta
			if spitter_shoot_timer <= 0.0 and is_instance_valid(GameManager.player_node):
				spitter_shoot_timer = randf_range(2.0, 3.2)
				trigger_attack_anim(0.4)
				_spore_shoot()
		EnemyType.BRAIN_SLAYER:
			spitter_shoot_timer -= delta
			if spitter_shoot_timer <= 0.0 and is_instance_valid(GameManager.player_node):
				spitter_shoot_timer = randf_range(2.2, 3.4)
				trigger_attack_anim(0.4)
				_psionic_shoot()
		EnemyType.CHAOS_EYE:
			spitter_shoot_timer -= delta
			if spitter_shoot_timer <= 0.0 and is_instance_valid(GameManager.player_node):
				spitter_shoot_timer = randf_range(2.0, 3.2)
				trigger_attack_anim(0.4)
				_chaos_eye_shoot()
		EnemyType.RICOCHET_CULTIST:
			spitter_shoot_timer -= delta
			if spitter_shoot_timer <= 0.0 and is_instance_valid(GameManager.player_node):
				spitter_shoot_timer = randf_range(2.2, 3.5)
				trigger_attack_anim(0.4)
				_ricochet_cultist_shoot()
		EnemyType.DEMON_SPIDER:
			if leaper_state == 0:
				leaper_timer -= delta
				if leaper_timer <= 0.0 and is_instance_valid(GameManager.player_node):
					leaper_state = 1
					leaper_timer = 0.45
					trigger_attack_anim(0.45)
					leap_target_pos = GameManager.player_node.global_position
			elif leaper_state == 1:
				leaper_timer -= delta
				if leaper_timer <= 0.0:
					leaper_state = 2
					trigger_attack_anim(0.5)
					SoundManager.play_sfx("dash", 0.2)
		EnemyType.RAT_ROYALTY:
			healer_pulse_timer -= delta
			if healer_pulse_timer <= 0.0:
				healer_pulse_timer = 2.5
				trigger_attack_anim(0.5)
				_pulse_heal()

func _skeleton_shoot() -> void:
	if not is_instance_valid(GameManager.player_node): return
	var dir = (GameManager.player_node.global_position - global_position).normalized()
	var arrow = PROJECTILE_SCRIPT.new()
	arrow.is_enemy_projectile = true
	arrow.init_projectile(dir, 224.0, contact_damage * 1.1, 580.0, 2, 45.0, false, "bone_scaling", Color(0.95, 0.9, 0.85), 0, 0.0)
	get_tree().current_scene.add_child(arrow)
	arrow.global_position = global_position + dir * (radius + 22.0)
	SoundManager.play_sfx("shoot_bone", 0.2)

func _wildfire_shoot() -> void:
	if not is_instance_valid(GameManager.player_node): return
	var dir = (GameManager.player_node.global_position - global_position).normalized()
	var ember = PROJECTILE_SCRIPT.new()
	ember.is_enemy_projectile = true
	ember.init_projectile(dir, 166.0, contact_damage * 1.0, 520.0, 1, 30.0, false, "burn", Color8(255, 120, 20), 0, 0.0)
	get_tree().current_scene.add_child(ember)
	ember.global_position = global_position + dir * (radius + 20.0)
	SoundManager.play_sfx("shoot_plasma", 0.2, -3.0)

func _snowman_shoot() -> void:
	if not is_instance_valid(GameManager.player_node): return
	var dir = (GameManager.player_node.global_position - global_position).normalized()
	var ball = PROJECTILE_SCRIPT.new()
	ball.is_enemy_projectile = true
	ball.init_projectile(dir, 156.0, contact_damage * 0.9, 500.0, 1, 40.0, false, "freeze", Color8(100, 220, 255), 0, 0.0)
	get_tree().current_scene.add_child(ball)
	ball.global_position = global_position + dir * (radius + 22.0)
	SoundManager.play_sfx("shoot_pistol", 0.2, -4.0)

func _pumpkin_shoot() -> void:
	if not is_instance_valid(GameManager.player_node): return
	var dir = (GameManager.player_node.global_position - global_position).normalized()
	for angle_offset in [-0.28, 0.28]:
		var p_dir = dir.rotated(angle_offset)
		var flame = PROJECTILE_SCRIPT.new()
		flame.is_enemy_projectile = true
		flame.init_projectile(p_dir, 152.0, contact_damage * 1.0, 500.0, 1, 35.0, false, "burn", Color8(255, 150, 30), 0, 0.0)
		get_tree().current_scene.add_child(flame)
		flame.global_position = global_position + p_dir * (radius + 22.0)
	SoundManager.play_sfx("shoot_plasma", 0.2)

func _cyclops_rock_throw() -> void:
	if not is_instance_valid(GameManager.player_node): return
	var dir = (GameManager.player_node.global_position - global_position).normalized()
	var rock = PROJECTILE_SCRIPT.new()
	rock.is_enemy_projectile = true
	rock.init_projectile(dir, 137.0, contact_damage * 1.5, 540.0, 1, 160.0, false, "rock", Color8(150, 130, 105), 0, 50.0)
	get_tree().current_scene.add_child(rock)
	rock.global_position = global_position + dir * (radius + 28.0)
	SoundManager.play_sfx("explosion", 0.2, -6.0)

func _chaos_eye_shoot() -> void:
	if not is_instance_valid(GameManager.player_node): return
	var dir = (GameManager.player_node.global_position - global_position).normalized()
	var proj = PROJECTILE_SCRIPT.new()
	proj.is_enemy_projectile = true
	proj.init_projectile(dir, 161.0, contact_damage * 1.1, 520.0, 1, 40.0, false, "split_chaos", Color8(210, 80, 255), 0, 0.0)
	proj.configure_split(3, 180.0)
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position + dir * (radius + 22.0)
	SoundManager.play_sfx("shoot_plasma", 0.2, 1.0)

func _ricochet_cultist_shoot() -> void:
	if not is_instance_valid(GameManager.player_node): return
	var dir = (GameManager.player_node.global_position - global_position).normalized()
	var proj = PROJECTILE_SCRIPT.new()
	proj.is_enemy_projectile = true
	proj.init_projectile(dir, 175.0, contact_damage * 1.1, 650.0, 2, 40.0, false, "ricochet", Color8(255, 215, 60), 2, 0.0)
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position + dir * (radius + 22.0)
	SoundManager.play_sfx("shoot_shuriken", 0.2, -2.0)

func _get_boss_projectile_theme() -> Dictionary:
	match enemy_type:
		EnemyType.BOSS_CRYPT_ABOMINATION:
			return {"type": "poison", "color": Color8(80, 245, 60), "sfx": "explosion", "speed": 170.0}
		EnemyType.BOSS_CENTAUR_KING:
			return {"type": "slash", "color": Color8(255, 140, 40), "sfx": "shoot_shotgun", "speed": 180.0}
		EnemyType.BOSS_IRONHORN_MINOTAUR:
			return {"type": "burn", "color": Color8(255, 100, 20), "sfx": "monster_charge", "speed": 175.0}
		EnemyType.BOSS_PSIONIC_OVERLORD:
			return {"type": "plasma", "color": Color8(190, 50, 255), "sfx": "shoot_plasma", "speed": 185.0}
		EnemyType.BOSS_GIANT_TITAN:
			return {"type": "rock", "color": Color8(180, 150, 110), "sfx": "explosion", "speed": 165.0}
		EnemyType.BOSS_YETI_BEHEMOTH:
			return {"type": "freeze", "color": Color8(140, 220, 255), "sfx": "shoot_plasma", "speed": 170.0}
		EnemyType.BOSS_GARGOYLE_SOVEREIGN:
			return {"type": "rock", "color": Color8(160, 165, 180), "sfx": "explosion", "speed": 175.0}
		EnemyType.BOSS_ANGEL_OF_DEATH:
			return {"type": "soul", "color": Color8(160, 40, 240), "sfx": "shoot_plasma", "speed": 190.0}
		_:
			return {"type": "plasma", "color": Color8(255, 100, 50), "sfx": "shoot_plasma", "speed": 175.0}

# Boss Attack Type 1: High-Damage Melee Charge Rush & Seismic Ground Slam
func _start_boss_melee_rush() -> void:
	if not is_instance_valid(GameManager.player_node): return
	boss_charge_state = 1
	boss_charge_timer = 0.40
	boss_charge_dir = (GameManager.player_node.global_position - global_position).normalized()
	trigger_attack_anim(0.40)
	SoundManager.play_sfx("monster_charge", 0.15, 1.0)
	GameManager.emit_signal("screen_shake_requested", 6.0, 0.2)

func _boss_melee_ground_slam_finish() -> void:
	SoundManager.play_sfx("explosion", 0.15, 2.0)
	GameManager.emit_signal("screen_shake_requested", 10.0, 0.35)
	if is_instance_valid(GameManager.player_node):
		var dist = global_position.distance_to(GameManager.player_node.global_position)
		if dist <= radius + 90.0:
			# High melee damage from seismic slam
			GameManager.damage_player(contact_damage * 1.3)
			if GameManager.player_node.has_method("apply_knockback_push"):
				var push_dir = (GameManager.player_node.global_position - global_position).normalized()
				GameManager.player_node.apply_knockback_push(push_dir * 550.0)

# Boss Attack Type 2: 12/16-Directional Radial Barrage
func _boss_radial_barrage() -> void:
	if not is_instance_valid(GameManager.player_node): return
	var theme = _get_boss_projectile_theme()
	SoundManager.play_sfx(theme.sfx, 0.15, 2.0)
	GameManager.emit_signal("screen_shake_requested", 8.0, 0.3)
	
	var bullet_dmg = 12.0 + (GameManager.current_wave * 0.4)
	var count = 16 if (GameManager.current_wave >= 10 or enemy_type == EnemyType.BOSS_ANGEL_OF_DEATH) else 12
	
	for i in range(count):
		var a = (float(i) / float(count)) * TAU
		var p_dir = Vector2.from_angle(a)
		var proj = PROJECTILE_SCRIPT.new()
		proj.is_enemy_projectile = true
		proj.init_projectile(p_dir, theme.speed, bullet_dmg, 580.0, 1, 50.0, false, theme.type, theme.color, 0, 0.0)
		get_tree().current_scene.add_child(proj)
		proj.global_position = global_position + p_dir * (radius + 26.0)

# Boss Attack Type 3: Targeted 5-Way Spreading Cluster Split Shot
func _boss_spreading_split_shot() -> void:
	if not is_instance_valid(GameManager.player_node): return
	var theme = _get_boss_projectile_theme()
	SoundManager.play_sfx(theme.sfx, 0.15, 1.0)
	GameManager.emit_signal("screen_shake_requested", 7.0, 0.3)
	
	var bullet_dmg = 11.0 + (GameManager.current_wave * 0.35)
	var dir = (GameManager.player_node.global_position - global_position).normalized()
	
	for angle_offset in [-0.42, -0.21, 0.0, 0.21, 0.42]:
		var f_dir = dir.rotated(angle_offset)
		var proj = PROJECTILE_SCRIPT.new()
		proj.is_enemy_projectile = true
		proj.init_projectile(f_dir, theme.speed, bullet_dmg, 560.0, 1, 45.0, false, theme.type, theme.color, 0, 0.0)
		if angle_offset == 0.0 or abs(angle_offset) == 0.42:
			proj.configure_split(3, 160.0)
		get_tree().current_scene.add_child(proj)
		proj.global_position = global_position + f_dir * (radius + 26.0)

# Boss Attack Type 4: Volcanic Ground Eruption & Swarmer Minion Surge
func _boss_volcanic_eruption_and_summon() -> void:
	if not is_instance_valid(GameManager.player_node): return
	trigger_attack_anim(0.7)
	SoundManager.play_sfx("explosion", 0.15, -4.0)
	GameManager.emit_signal("screen_shake_requested", 12.0, 0.4)
	GameManager.emit_signal("show_damage_number", global_position + Vector2(0, -60), "INFERNAL SURGE!", Color(1.0, 0.4, 0.1), true)
	
	var parent_scene = get_tree().current_scene
	if not is_instance_valid(parent_scene): return
	
	# Spawn 3 hazardous magma / toxic eruption pools around player
	var p_pos = GameManager.player_node.global_position
	for i in range(3):
		var offset = Vector2(randf_range(-120, 120), randf_range(-120, 120))
		var pool = ACID_POOL_SCRIPT.new()
		pool.is_enemy_hazard = true
		pool.damage_per_sec = 14.0 + (GameManager.current_wave * 0.5)
		pool.duration = 4.5
		pool.radius = 45.0
		parent_scene.add_child(pool)
		pool.global_position = p_pos + offset
		
	# Summon 2 minion swarmers to assist the boss if enemy count allows
	var current_enemies = get_tree().get_nodes_in_group("enemies").size()
	if current_enemies < 35:
		for i in range(2):
			var minion = EnemyBase.new()
			parent_scene.add_child(minion)
			var minion_pos = global_position + Vector2(randf_range(-60, 60), randf_range(-60, 60))
			minion.global_position = minion_pos
			var minion_type = EnemyType.WILDFIRE_WISP if enemy_type in [EnemyType.BOSS_CENTAUR_KING, EnemyType.BOSS_IRONHORN_MINOTAUR] else EnemyType.SLIME
			minion.init_enemy(minion_type, GameManager.current_wave, false, false)

func _spore_shoot() -> void:
	if not is_instance_valid(GameManager.player_node): return
	var dir = (GameManager.player_node.global_position - global_position).normalized()
	var spit = PROJECTILE_SCRIPT.new()
	spit.is_enemy_projectile = true
	spit.init_projectile(dir, 152.0, contact_damage, 440.0, 1, 30.0, false, "poison", Color8(60, 230, 50), 0, 40.0)
	get_tree().current_scene.add_child(spit)
	spit.global_position = global_position + dir * (radius + 20.0)
	SoundManager.play_sfx("shoot_smg", 0.3, -4.0)

func _psionic_shoot() -> void:
	if not is_instance_valid(GameManager.player_node): return
	var dir = (GameManager.player_node.global_position - global_position).normalized()
	var proj = PROJECTILE_SCRIPT.new()
	proj.is_enemy_projectile = true
	proj.init_projectile(dir, 205.0, contact_damage * 1.2, 560.0, 2, 40.0, false, "plasma", Color8(180, 50, 255), 0, 0.0)
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position + dir * (radius + 20.0)
	SoundManager.play_sfx("shoot_plasma", 0.2, -2.0)

func _pulse_heal() -> void:
	var allies = get_tree().get_nodes_in_group("enemies")
	for a in allies:
		if is_instance_valid(a) and a != self:
			var dist = global_position.distance_to(a.global_position)
			if dist < 200.0 and a.has_method("heal"):
				a.heal(22.0)

func heal(amount: float) -> void:
	hp = min(max_hp, hp + amount)
	GameManager.emit_signal("show_damage_number", global_position + Vector2(0, -20), "+%d" % int(amount), Color(0.2, 0.95, 0.3), false)
	queue_redraw()

func apply_knockback(force: Vector2) -> void:
	if is_frozen:
		return
	var effective_force = force * (1.0 - knockback_resist)
	knockback_velocity += effective_force

func apply_slow(factor: float, duration: float) -> void:
	slow_factor = max(slow_factor, factor)
	slow_timer = max(slow_timer, duration)

func apply_freeze(duration: float) -> void:
	if burn_timer > 0.0:
		# If enemy is on fire, it can still be frozen, but fire is extinguished (effects cancel out for that shot)
		burn_timer = 0.0
		burn_dps = 0.0
		burn_tick_timer = 0.0
		SoundManager.play_sfx("steam_hiss", 0.15, -4.0)
		GameManager.emit_signal("show_damage_number", global_position + Vector2(randf_range(-10, 10), -28), "EXTINGUISHED!", Color(0.4, 0.85, 1.0), false)
		
	is_frozen = true
	freeze_timer = max(freeze_timer, duration)

func apply_burn(dps: float, duration: float) -> void:
	if is_frozen:
		# If enemy was frozen, fire melts the ice instantly!
		# The effects cancel out for this shot (ice melts, fire is extinguished).
		is_frozen = false
		freeze_timer = 0.0
		burn_timer = 0.0
		burn_dps = 0.0
		burn_tick_timer = 0.0
		SoundManager.play_sfx("steam_hiss", 0.2, -2.0)
		GameManager.emit_signal("show_damage_number", global_position + Vector2(randf_range(-10, 10), -28), "MELTED!", Color(1.0, 0.65, 0.2), true)
		return
		
	burn_dps = max(burn_dps, dps)
	burn_timer = max(burn_timer, duration)
	if burn_tick_timer <= 0.0:
		burn_tick_timer = 1.5

func _process_status_effects(delta: float) -> void:
	if is_frozen:
		freeze_timer -= delta
		if freeze_timer <= 0.0:
			is_frozen = false
			freeze_timer = 0.0
			
	if slow_timer > 0.0:
		slow_timer -= delta
		if slow_timer <= 0.0:
			slow_factor = 0.0
			
	if burn_timer > 0.0:
		burn_timer -= delta
		burn_tick_timer -= delta
		if burn_tick_timer <= 0.0:
			burn_tick_timer = 1.5
			take_damage(3.0, false, "burn")
	else:
		burn_tick_timer = 0.0
		burn_dps = 0.0

func take_damage(dmg: float, crit: bool = false, source: String = "") -> void:
	# Logical fire vs ice interactions on direct hits:
	if is_frozen and source in ["burn", "fire", "flame", "fire_spell", "magma"]:
		# Direct fire hit melts the ice instantly!
		is_frozen = false
		freeze_timer = 0.0
		burn_timer = 0.0
		burn_dps = 0.0
		burn_tick_timer = 0.0
		SoundManager.play_sfx("steam_hiss", 0.2, -2.0)
		GameManager.emit_signal("show_damage_number", global_position + Vector2(randf_range(-10, 10), -28), "MELTED!", Color(1.0, 0.65, 0.2), true)
	elif burn_timer > 0.0 and source in ["freeze", "ice", "ice_spell", "cryo", "cryo_slow"]:
		# Direct ice hit extinguishes burning fire!
		burn_timer = 0.0
		burn_dps = 0.0
		burn_tick_timer = 0.0
		SoundManager.play_sfx("steam_hiss", 0.15, -4.0)
		GameManager.emit_signal("show_damage_number", global_position + Vector2(randf_range(-10, 10), -28), "EXTINGUISHED!", Color(0.4, 0.85, 1.0), false)
	var actual_dmg = dmg
	if enemy_type == EnemyType.DEEP_ONE and source != "plasma" and source != "explosion":
		actual_dmg *= 0.65
	elif enemy_type == EnemyType.GARGOYLE:
		actual_dmg *= 0.75
		
	hp -= actual_dmg
	hit_flash_timer = 0.1
	queue_redraw()
	
	var text_col = Color.WHITE
	if crit:
		text_col = Color(1.0, 0.85, 0.1)
	elif source == "burn":
		text_col = Color(1.0, 0.45, 0.1)
	elif source == "freeze" or source == "cryo_slow":
		text_col = Color(0.3, 0.85, 1.0)
	elif source == "acid":
		text_col = Color(0.4, 0.95, 0.2)
		
	GameManager.emit_signal("show_damage_number", global_position + Vector2(randf_range(-12, 12), -22), "%d" % int(actual_dmg), text_col, crit)
	
	if hp <= 0.0:
		die(true)

func die(drop_loot: bool = true) -> void:
	if GameManager.locked_target == self:
		GameManager.unlock_target()
		
	GameManager.add_combo(1, global_position)
	SoundManager.play_sfx("enemy_die", 0.15)
	
	# Award XP based on enemy tier
	var xp_reward = 6
	if is_boss:
		xp_reward = 80
	elif is_miniboss:
		xp_reward = 25
	elif is_elite:
		xp_reward = 20
	elif enemy_type in [EnemyType.DEEP_ONE, EnemyType.GARGOYLE, EnemyType.RAT_ROYALTY, EnemyType.DEMON_SPIDER, EnemyType.MINOTAUR, EnemyType.TROLL]:
		xp_reward = 12
	GameManager.add_xp(xp_reward)
	
	if drop_loot:
		_spawn_bone_drops()
		
	emit_signal("enemy_died", self)
	queue_free()

func _spawn_bone_drops() -> void:
	var count = bone_drop_count
	var luck_bonus = randf() < (GameManager.luck * 0.4)
	if luck_bonus and not is_boss:
		count += 1
		
	var parent_node = get_parent()
	if not is_instance_valid(parent_node): return
	
	for i in range(count):
		var bone = BONE_PICKUP_SCRIPT.new()
		parent_node.add_child(bone)
		bone.global_position = global_position
		
		var angle = randf() * TAU
		var scatter_dist = randf_range(20.0, 55.0)
		var target_loc = global_position + Vector2(cos(angle), sin(angle)) * scatter_dist
		if bone.has_method("launch_towards"):
			bone.launch_towards(target_loc)

func _draw() -> void:
	# Target Lock Reticle (When locked by player click)
	if GameManager.locked_target == self:
		var lock_r = radius + 22.0 + sin(anim_timer * 10.0) * 3.0
		var lock_col = Color8(255, 60, 60) if int(anim_timer * 8.0) % 2 == 0 else Color8(255, 220, 40)
		
		# Draw 4 Corner Target Brackets
		var b_len = 14.0
		# Top-Left
		draw_line(Vector2(-lock_r, -lock_r), Vector2(-lock_r + b_len, -lock_r), lock_col, 3.5)
		draw_line(Vector2(-lock_r, -lock_r), Vector2(-lock_r, -lock_r + b_len), lock_col, 3.5)
		# Top-Right
		draw_line(Vector2(lock_r, -lock_r), Vector2(lock_r - b_len, -lock_r), lock_col, 3.5)
		draw_line(Vector2(lock_r, -lock_r), Vector2(lock_r, -lock_r + b_len), lock_col, 3.5)
		# Bottom-Left
		draw_line(Vector2(-lock_r, lock_r), Vector2(-lock_r + b_len, lock_r), lock_col, 3.5)
		draw_line(Vector2(-lock_r, lock_r), Vector2(-lock_r, lock_r - b_len), lock_col, 3.5)
		# Bottom-Right
		draw_line(Vector2(lock_r, lock_r), Vector2(lock_r - b_len, lock_r), lock_col, 3.5)
		draw_line(Vector2(lock_r, lock_r), Vector2(lock_r, lock_r - b_len), lock_col, 3.5)
		
		# Center Target Crosshair diamond
		draw_arc(Vector2.ZERO, lock_r * 0.7, anim_timer * 4.0, anim_timer * 4.0 + TAU, 16, Color(1.0, 0.2, 0.2, 0.6), 2.0)
		
		# Overhead Locked Banner Text
		if FONT:
			var txt_y = -lock_r - 26.0
			draw_rect(Rect2(Vector2(-65, txt_y - 2), Vector2(130, 22)), Color8(10, 10, 15, 230), true)
			draw_rect(Rect2(Vector2(-65, txt_y - 2), Vector2(130, 22)), lock_col, false, 2.0)
			draw_string(FONT, Vector2(-65, txt_y + 14), "<< LOCKED >>", HORIZONTAL_ALIGNMENT_CENTER, 130, 16, lock_col)

	# In-World Boss Rendering (Demonic Summoning Ring, Warning Telegraph, Overhead Boss Health Bar)
	if is_boss:
		# Molten Ground Aura
		var aura_r = radius + 14.0 + sin(anim_timer * 4.0) * 4.0
		draw_arc(Vector2.ZERO, aura_r, 0, TAU, 32, Color8(255, 60, 20, 150), 3.5)
		draw_arc(Vector2.ZERO, radius + 24.0, anim_timer * 2.0, anim_timer * 2.0 + TAU * 0.7, 24, Color8(255, 180, 40, 110), 2.0)
		
		# Telegraph directional charge arrow if winding up charge attack
		if boss_charge_state == 1:
			var arrow_len = 160.0
			var arrow_end = boss_charge_dir * arrow_len
			draw_line(Vector2.ZERO, arrow_end, Color8(255, 50, 50, 200), 5.0)
			draw_circle(arrow_end, 12.0, Color8(255, 80, 40, 220))
			
		# Overhead In-World Boss Health Bar
		var bar_w = max(180.0, radius * 2.4)
		var bar_h = 12.0
		var bar_y = -radius - 34.0
		var ratio = clamp(hp / max_hp, 0.0, 1.0)
		
		# Bar border & background
		draw_rect(Rect2(Vector2(-bar_w * 0.5 - 2, bar_y - 2), Vector2(bar_w + 4, bar_h + 4)), Color8(255, 190, 40, 230), false, 2.0)
		draw_rect(Rect2(Vector2(-bar_w * 0.5, bar_y), Vector2(bar_w, bar_h)), Color8(25, 8, 8, 220), true)
		# Health fill
		draw_rect(Rect2(Vector2(-bar_w * 0.5, bar_y), Vector2(bar_w * ratio, bar_h)), Color8(255, 45, 45, 240), true)
		
		if FONT:
			var title_str = "[ BOSS ] " + monster_name.to_upper()
			draw_string(FONT, Vector2(-bar_w * 0.5, bar_y - 8), title_str, HORIZONTAL_ALIGNMENT_CENTER, int(bar_w), 18, Color8(255, 215, 60))
			var hp_str = "%d / %d" % [int(max(0.0, hp)), int(max_hp)]
			draw_string(FONT, Vector2(-bar_w * 0.5, bar_y + 10), hp_str, HORIZONTAL_ALIGNMENT_CENTER, int(bar_w), 14, Color(1, 1, 1, 0.95))

	elif hp < max_hp:
		# Minimalist In-World Damaged Health Bar for Regular Mobs & Minibosses
		var bar_w = radius * 2.0
		var bar_h = 6.0 if is_miniboss else 5.0
		var ratio = clamp(hp / max_hp, 0.0, 1.0)
		var y_off = -radius - 12.0
		
		# Background
		draw_rect(Rect2(Vector2(-bar_w * 0.5, y_off), Vector2(bar_w, bar_h)), Color8(30, 10, 10, 180), true)
		# Health fill (orange-red for miniboss, red for normal mobs)
		var fill_col = Color8(255, 80, 50, 240) if is_miniboss else Color8(230, 45, 45, 220)
		draw_rect(Rect2(Vector2(-bar_w * 0.5, y_off), Vector2(bar_w * ratio, bar_h)), fill_col, true)

