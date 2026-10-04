# item_database.gd - Catalog of Weapons, Skills, Furnace Upgrades, and Abilities with Minimalist Text
extends Node

const TIER_COMMON = 0
const TIER_RARE = 1
const TIER_EPIC = 2
const TIER_LEGENDARY = 3

const TIER_COLORS = {
	TIER_COMMON: Color(0.8, 0.8, 0.8),
	TIER_RARE: Color(0.2, 0.6, 1.0),
	TIER_EPIC: Color(0.7, 0.3, 0.95),
	TIER_LEGENDARY: Color(1.0, 0.75, 0.1)
}

const TIER_NAMES = {
	TIER_COMMON: "Common",
	TIER_RARE: "Rare",
	TIER_EPIC: "Epic",
	TIER_LEGENDARY: "Legendary"
}

var weapons: Dictionary = {}
var skills: Dictionary = {}
var furnace_upgrades: Dictionary = {}
var abilities: Dictionary = {}
var active_skills: Dictionary = {}
var turrets: Dictionary = {}

func _ready() -> void:
	_init_weapons()
	_init_skills()
	_init_furnace_upgrades()
	_init_abilities()
	_init_active_skills()
	_init_turrets()

func _init_turrets() -> void:
	turrets = {
		"turret_ballista": {
			"id": "turret_ballista",
			"name": "Ballista Turret",
			"type": "turret",
			"turret_type": "ballista",
			"tier": TIER_LEGENDARY,
			"cost": 65,
			"desc": "Deployable siege ballista.\nFires piercing bolts through up to 4 enemies.\n[color=#ffd700]Permanent placement[/color]",
			"icon": "turret_arrow",
			"color": Color(0.9, 0.75, 0.2)
		},
		"turret_cannon": {
			"id": "turret_cannon",
			"name": "Heavy Cannon Turret",
			"type": "turret",
			"turret_type": "cannon",
			"tier": TIER_LEGENDARY,
			"cost": 85,
			"desc": "Deployable fortress cannon.\nFires explosive cannonballs with AoE blast.\n[color=#ffd700]Permanent placement[/color]",
			"icon": "turret_cannon",
			"color": Color(1.0, 0.65, 0.15)
		},
		"turret_flame": {
			"id": "turret_flame",
			"name": "Flame Turret",
			"type": "turret",
			"turret_type": "flame",
			"tier": TIER_EPIC,
			"cost": 75,
			"desc": "Short-range flamethrower defense.\nSpews continuous burning fire at nearby monsters.\n[color=#ffd700]Permanent placement[/color]",
			"icon": "turret_flame",
			"color": Color(1.0, 0.45, 0.1)
		},
		"turret_ice": {
			"id": "turret_ice",
			"name": "Ice Turret",
			"type": "turret",
			"turret_type": "ice",
			"tier": TIER_EPIC,
			"cost": 70,
			"desc": "Cryogenic defense turret.\nShoots freezing bullets that freeze enemies solid for 5s.\n[color=#ffd700]Permanent placement[/color]",
			"icon": "turret_ice",
			"color": Color(0.2, 0.7, 1.0)
		}
	}

func _init_weapons() -> void:
	weapons = {
		"pistol": {
			"id": "pistol",
			"name": "Kinetic Pistol",
			"type": "weapon",
			"category": "kinetic",
			"tier": TIER_COMMON,
			"desc": "Balanced sidearm",
			"damage": 11.0,
			"fire_rate": 2.0,
			"range": 450.0,
			"bullet_speed": 650.0,
			"pierce": 1,
			"spread": 0.04,
			"projectiles": 1,
			"knockback": 70.0,
			"crit_chance": 0.05,
			"crit_mult": 1.5,
			"cost": 15,
			"color": Color(0.85, 0.85, 0.85),
			"icon": "pistol"
		},
		"smg": {
			"id": "smg",
			"name": "Rapid SMG",
			"type": "weapon",
			"category": "kinetic",
			"tier": TIER_COMMON,
			"desc": "Rapid fire spray\n[color=#ff5555]+Spread[/color]",
			"damage": 5.5,
			"fire_rate": 6.0,
			"range": 360.0,
			"bullet_speed": 700.0,
			"pierce": 1,
			"spread": 0.16,
			"projectiles": 1,
			"knockback": 30.0,
			"crit_chance": 0.03,
			"crit_mult": 1.5,
			"cost": 22,
			"color": Color(0.7, 0.85, 0.95),
			"icon": "smg"
		},
		"shotgun": {
			"id": "shotgun",
			"name": "Scatter Shotgun",
			"type": "weapon",
			"category": "kinetic",
			"tier": TIER_RARE,
			"desc": "5-pellet spread\n[color=#ff5555]Short range[/color]",
			"damage": 6.5,
			"fire_rate": 1.0,
			"range": 320.0,
			"bullet_speed": 600.0,
			"pierce": 1,
			"spread": 0.35,
			"projectiles": 5,
			"knockback": 180.0,
			"crit_chance": 0.08,
			"crit_mult": 1.6,
			"cost": 35,
			"color": Color(0.9, 0.6, 0.3),
			"icon": "shotgun"
		},
		"assault_rifle": {
			"id": "assault_rifle",
			"name": "Combat Rifle",
			"type": "weapon",
			"category": "kinetic",
			"tier": TIER_RARE,
			"desc": "High velocity burst\n[color=#ff5555]-5% Speed[/color]",
			"damage": 13.0,
			"fire_rate": 2.8,
			"range": 520.0,
			"bullet_speed": 800.0,
			"pierce": 2,
			"spread": 0.05,
			"projectiles": 1,
			"knockback": 90.0,
			"crit_chance": 0.1,
			"crit_mult": 1.75,
			"cost": 40,
			"color": Color(0.4, 0.75, 0.4),
			"icon": "rifle"
		},
		"sniper": {
			"id": "sniper",
			"name": "Heavy Anti-Material",
			"type": "weapon",
			"category": "precision",
			"tier": TIER_EPIC,
			"desc": "Heavy pierce & crit\n[color=#ff5555]-8% Speed[/color]",
			"damage": 48.0,
			"fire_rate": 0.65,
			"range": 750.0,
			"bullet_speed": 1200.0,
			"pierce": 5,
			"spread": 0.01,
			"projectiles": 1,
			"knockback": 280.0,
			"crit_chance": 0.25,
			"crit_mult": 2.2,
			"cost": 65,
			"color": Color(0.95, 0.3, 0.3),
			"icon": "sniper"
		},
		"gatling_minigun": {
			"id": "gatling_minigun",
			"name": "Vulcan Minigun",
			"type": "weapon",
			"category": "kinetic",
			"tier": TIER_EPIC,
			"desc": "12 shots/s bullet hose\n[color=#ff5555]-12% Speed[/color]",
			"damage": 4.5,
			"fire_rate": 12.0,
			"range": 420.0,
			"bullet_speed": 850.0,
			"pierce": 1,
			"spread": 0.22,
			"projectiles": 1,
			"knockback": 35.0,
			"crit_chance": 0.04,
			"crit_mult": 1.5,
			"special": "minigun",
			"cost": 68,
			"color": Color(1.0, 0.8, 0.2),
			"icon": "minigun"
		},
		"flamethrower": {
			"id": "flamethrower",
			"name": "Napalm Spewer",
			"type": "weapon",
			"category": "elemental",
			"tier": TIER_RARE,
			"desc": "Flame stream (3 dmg/1.5s burn)\n[color=#ff5555]+15% Heat[/color]",
			"damage": 2.5,
			"fire_rate": 4.0,
			"range": 260.0,
			"bullet_speed": 380.0,
			"pierce": 99,
			"spread": 0.26,
			"projectiles": 1,
			"knockback": 12.0,
			"crit_chance": 0.04,
			"crit_mult": 1.4,
			"special": "burn",
			"cost": 45,
			"color": Color(1.0, 0.45, 0.0),
			"icon": "flame"
		},
		"rocket_launcher": {
			"id": "rocket_launcher",
			"name": "Devastator RPG",
			"type": "weapon",
			"category": "explosive",
			"tier": TIER_EPIC,
			"desc": "Explosive rocket AoE\n[color=#ff5555]-10 HP[/color]",
			"damage": 38.0,
			"fire_rate": 0.70,
			"range": 580.0,
			"bullet_speed": 450.0,
			"pierce": 1,
			"spread": 0.06,
			"projectiles": 1,
			"knockback": 320.0,
			"aoe_radius": 90.0,
			"crit_chance": 0.10,
			"crit_mult": 1.8,
			"special": "explosive",
			"cost": 60,
			"color": Color(1.0, 0.2, 0.2),
			"icon": "rocket"
		},
		"plasma_blaster": {
			"id": "plasma_blaster",
			"name": "Plasma Blaster",
			"type": "weapon",
			"category": "energy",
			"tier": TIER_EPIC,
			"desc": "Bouncing plasma orb\n[color=#ff5555]-5% Atk Spd[/color]",
			"damage": 22.0,
			"fire_rate": 1.6,
			"range": 500.0,
			"bullet_speed": 550.0,
			"pierce": 2,
			"bounces": 2,
			"spread": 0.08,
			"projectiles": 1,
			"knockback": 110.0,
			"crit_chance": 0.12,
			"crit_mult": 1.8,
			"special": "plasma",
			"cost": 55,
			"color": Color(0.2, 0.8, 1.0),
			"icon": "plasma"
		},
		"void_black_hole_cannon": {
			"id": "void_black_hole_cannon",
			"name": "Vortex Cannon",
			"type": "weapon",
			"category": "energy",
			"tier": TIER_LEGENDARY,
			"desc": "Graviton vortex AoE\n[color=#ff5555]-15 HP[/color]",
			"damage": 42.0,
			"fire_rate": 0.50,
			"range": 550.0,
			"bullet_speed": 340.0,
			"pierce": 1,
			"spread": 0.04,
			"projectiles": 1,
			"knockback": -200.0,
			"aoe_radius": 110.0,
			"crit_chance": 0.15,
			"crit_mult": 2.0,
			"special": "void_vortex",
			"cost": 85,
			"color": Color(0.6, 0.1, 0.9),
			"icon": "void"
		},
		"tesla_coil": {
			"id": "tesla_coil",
			"name": "Lightning Rod",
			"type": "weapon",
			"category": "energy",
			"tier": TIER_EPIC,
			"desc": "Chain lightning (4 targets)",
			"damage": 15.0,
			"fire_rate": 2.0,
			"range": 420.0,
			"bullet_speed": 9999.0,
			"pierce": 4,
			"spread": 0.0,
			"projectiles": 1,
			"knockback": 50.0,
			"crit_chance": 0.1,
			"crit_mult": 1.7,
			"special": "lightning",
			"cost": 65,
			"color": Color(0.8, 0.9, 0.2),
			"icon": "tesla"
		},
		"bone_crossbow": {
			"id": "bone_crossbow",
			"name": "Bone Crossbow",
			"type": "weapon",
			"category": "synergy",
			"tier": TIER_RARE,
			"desc": "+1.5% Dmg per held bone",
			"damage": 16.0,
			"fire_rate": 1.6,
			"range": 550.0,
			"bullet_speed": 750.0,
			"pierce": 2,
			"spread": 0.03,
			"projectiles": 1,
			"knockback": 120.0,
			"crit_chance": 0.1,
			"crit_mult": 1.75,
			"special": "bone_scaling",
			"cost": 42,
			"color": Color(0.9, 0.85, 0.7),
			"icon": "crossbow"
		},
		"bone_boomerang": {
			"id": "bone_boomerang",
			"name": "Bone Boomerang",
			"type": "weapon",
			"category": "synergy",
			"tier": TIER_RARE,
			"desc": "Piercing return sickle\n[color=#ff5555]-5% Speed[/color]",
			"damage": 14.0,
			"fire_rate": 1.8,
			"range": 440.0,
			"bullet_speed": 500.0,
			"pierce": 99,
			"spread": 0.08,
			"projectiles": 1,
			"knockback": 110.0,
			"crit_chance": 0.10,
			"crit_mult": 1.7,
			"special": "bone_boomerang",
			"cost": 46,
			"color": Color(0.95, 0.9, 0.8),
			"icon": "boomerang"
		},
		"shuriken_spinner": {
			"id": "shuriken_spinner",
			"name": "Blade Shuriken",
			"type": "weapon",
			"category": "precision",
			"tier": TIER_COMMON,
			"desc": "3 ricochet stars\n[color=#ff5555]-1 Armor[/color]",
			"damage": 6.5,
			"fire_rate": 2.6,
			"range": 400.0,
			"bullet_speed": 620.0,
			"pierce": 2,
			"bounces": 2,
			"spread": 0.20,
			"projectiles": 3,
			"knockback": 35.0,
			"crit_chance": 0.08,
			"crit_mult": 1.6,
			"special": "shuriken",
			"cost": 28,
			"color": Color(0.85, 0.9, 0.95),
			"icon": "shuriken"
		},
		"flame_revolver": {
			"id": "flame_revolver",
			"name": "Flame Revolver",
			"type": "weapon",
			"category": "elemental",
			"tier": TIER_RARE,
			"desc": "High crit incendiary (3 dmg/1.5s burn)\n[color=#ff5555]-10 Water[/color]",
			"damage": 18.0,
			"fire_rate": 1.6,
			"range": 480.0,
			"bullet_speed": 850.0,
			"pierce": 2,
			"spread": 0.04,
			"projectiles": 1,
			"knockback": 140.0,
			"crit_chance": 0.18,
			"crit_mult": 2.0,
			"special": "burn",
			"cost": 48,
			"color": Color(1.0, 0.35, 0.1),
			"icon": "revolver"
		},
		"arcane_missiles": {
			"id": "arcane_missiles",
			"name": "Spirit Wand",
			"type": "weapon",
			"category": "spell",
			"tier": TIER_RARE,
			"desc": "3 homing spirit darts",
			"damage": 7.5,
			"fire_rate": 2.0,
			"range": 460.0,
			"bullet_speed": 550.0,
			"pierce": 1,
			"spread": 0.30,
			"projectiles": 3,
			"knockback": 40.0,
			"crit_chance": 0.08,
			"crit_mult": 1.6,
			"special": "arcane_homing",
			"cost": 48,
			"color": Color(0.8, 0.4, 1.0),
			"icon": "arcane"
		},
		"laser_cannon": {
			"id": "laser_cannon",
			"name": "Laser Blaster",
			"type": "weapon",
			"category": "energy",
			"tier": TIER_LEGENDARY,
			"desc": "Continuous beam\n[color=#ff5555]-12% Speed[/color]",
			"damage": 5.95,
			"fire_rate": 7.0,
			"range": 600.0,
			"bullet_speed": 9999.0,
			"pierce": 99,
			"spread": 0.0,
			"projectiles": 1,
			"knockback": 15.0,
			"crit_chance": 0.12,
			"crit_mult": 1.8,
			"special": "laser",
			"cost": 90,
			"color": Color(1.0, 0.1, 0.4),
			"icon": "laser"
		},
		"sledgehammer": {
			"id": "sledgehammer",
			"name": "War Hammer",
			"type": "weapon",
			"category": "melee",
			"tier": TIER_RARE,
			"desc": "Heavy smash knockback\n[color=#ff5555]-10% Atk Spd[/color]",
			"damage": 34.0,
			"fire_rate": 0.85,
			"range": 140.0,
			"bullet_speed": 0.0,
			"pierce": 99,
			"spread": 0.0,
			"projectiles": 1,
			"knockback": 380.0,
			"crit_chance": 0.15,
			"crit_mult": 2.0,
			"special": "melee_swing",
			"cost": 50,
			"color": Color(0.85, 0.5, 0.2),
			"icon": "hammer"
		},
		"frost_scythe": {
			"id": "frost_scythe",
			"name": "Frost Scythe",
			"type": "weapon",
			"category": "melee",
			"tier": TIER_EPIC,
			"desc": "220 frost cleave slow\n[color=#ff5555]-15 HP[/color]",
			"damage": 28.0,
			"fire_rate": 1.2,
			"range": 170.0,
			"bullet_speed": 400.0,
			"pierce": 99,
			"spread": 0.0,
			"projectiles": 1,
			"knockback": 200.0,
			"crit_chance": 0.14,
			"crit_mult": 1.8,
			"special": "frost_slash",
			"cost": 65,
			"color": Color(0.2, 0.85, 1.0),
			"icon": "scythe"
		},
		"cryo_blaster": {
			"id": "cryo_blaster",
			"name": "Cryo Cannon",
			"type": "weapon",
			"category": "elemental",
			"tier": TIER_RARE,
			"desc": "Cryogenic cone frost\n[color=#33ccff]Slows targets by 40%[/color]",
			"damage": 6.5,
			"fire_rate": 3.8,
			"range": 300.0,
			"bullet_speed": 450.0,
			"pierce": 99,
			"spread": 0.25,
			"projectiles": 1,
			"knockback": 30.0,
			"crit_chance": 0.06,
			"crit_mult": 1.5,
			"special": "cryo_slow",
			"slow_factor": 0.40,
			"cost": 52,
			"color": Color(0.3, 0.9, 1.0),
			"icon": "cryo"
		},
		"acid_mortar": {
			"id": "acid_mortar",
			"name": "Acid Mortar",
			"type": "weapon",
			"category": "elemental",
			"tier": TIER_EPIC,
			"desc": "Acid pool mortar\n[color=#ff5555]-6% Speed[/color]",
			"damage": 22.0,
			"fire_rate": 0.85,
			"range": 520.0,
			"bullet_speed": 400.0,
			"pierce": 1,
			"spread": 0.1,
			"projectiles": 1,
			"knockback": 80.0,
			"crit_chance": 0.1,
			"crit_mult": 1.7,
			"special": "acid_pool",
			"cost": 62,
			"color": Color(0.3, 1.0, 0.3),
			"icon": "acid"
		},
		"greatsword": {
			"id": "greatsword",
			"name": "Greatsword",
			"type": "weapon",
			"category": "melee",
			"tier": TIER_RARE,
			"desc": "180 cleave slash\n[color=#ff5555]-6% Speed[/color]",
			"damage": 26.0,
			"fire_rate": 1.3,
			"range": 160.0,
			"bullet_speed": 400.0,
			"pierce": 99,
			"spread": 0.0,
			"projectiles": 1,
			"knockback": 200.0,
			"crit_chance": 0.10,
			"crit_mult": 1.75,
			"special": "slash",
			"cost": 45,
			"color": Color8(255, 200, 100),
			"icon": "sword"
		},
		"dagger": {
			"id": "dagger",
			"name": "Shadow Dagger",
			"type": "weapon",
			"category": "melee",
			"tier": TIER_COMMON,
			"desc": "Fast thrusts, +30% Crit",
			"damage": 9.0,
			"fire_rate": 4.0,
			"range": 130.0,
			"bullet_speed": 550.0,
			"pierce": 2,
			"spread": 0.08,
			"projectiles": 1,
			"knockback": 50.0,
			"crit_chance": 0.30,
			"crit_mult": 2.0,
			"special": "slash",
			"cost": 25,
			"color": Color8(200, 220, 240),
			"icon": "dagger"
		},
		"fire_spell": {
			"id": "fire_spell",
			"name": "Pyromancer Wand",
			"type": "weapon",
			"category": "spell",
			"tier": TIER_EPIC,
			"desc": "Fire wave burn (3 dmg/1.5s)\n[color=#ff5555]+10% Heat[/color]",
			"damage": 22.0,
			"fire_rate": 1.5,
			"range": 480.0,
			"bullet_speed": 520.0,
			"pierce": 3,
			"spread": 0.10,
			"projectiles": 1,
			"knockback": 110.0,
			"crit_chance": 0.12,
			"crit_mult": 1.8,
			"special": "fire_spell",
			"cost": 65,
			"color": Color8(255, 100, 20),
			"icon": "fire_wand"
		},
		"meteor_staff": {
			"id": "meteor_staff",
			"name": "Meteor Staff",
			"type": "weapon",
			"category": "spell",
			"tier": TIER_LEGENDARY,
			"desc": "Meteor strike AoE\n[color=#ff5555]-10% Speed[/color]",
			"damage": 55.0,
			"fire_rate": 0.65,
			"range": 650.0,
			"bullet_speed": 480.0,
			"pierce": 1,
			"spread": 0.08,
			"projectiles": 1,
			"knockback": 280.0,
			"aoe_radius": 120.0,
			"crit_chance": 0.20,
			"crit_mult": 2.2,
			"special": "meteor",
			"cost": 95,
			"color": Color8(255, 60, 20),
			"icon": "meteor"
		},
		"ice_spell": {
			"id": "ice_spell",
			"name": "Frostbite Wand",
			"type": "weapon",
			"category": "spell",
			"tier": TIER_EPIC,
			"desc": "Ice lance freeze\n[color=#ff5555]-5% Atk Spd[/color]",
			"damage": 18.0,
			"fire_rate": 1.8,
			"range": 520.0,
			"bullet_speed": 620.0,
			"pierce": 3,
			"spread": 0.06,
			"projectiles": 1,
			"knockback": 90.0,
			"crit_chance": 0.10,
			"crit_mult": 1.7,
			"special": "ice_spell",
			"cost": 62,
			"color": Color8(60, 200, 255),
			"icon": "ice_wand"
		},
		"lightning_spell": {
			"id": "lightning_spell",
			"name": "Stormcaller Rod",
			"type": "weapon",
			"category": "spell",
			"tier": TIER_EPIC,
			"desc": "Chain lightning wave\n[color=#ff5555]-10 HP[/color]",
			"damage": 20.0,
			"fire_rate": 1.5,
			"range": 460.0,
			"bullet_speed": 700.0,
			"pierce": 4,
			"spread": 0.12,
			"projectiles": 1,
			"knockback": 80.0,
			"crit_chance": 0.12,
			"crit_mult": 1.75,
			"special": "lightning_spell",
			"cost": 68,
			"color": Color8(255, 235, 40),
			"icon": "lightning_wand"
		},
		"poison_spell": {
			"id": "poison_spell",
			"name": "Blight Venom Orb",
			"type": "weapon",
			"category": "spell",
			"tier": TIER_RARE,
			"desc": "Spore cloud poison\n[color=#ff5555]-0.5 HP/s[/color]",
			"damage": 14.0,
			"fire_rate": 2.0,
			"range": 440.0,
			"bullet_speed": 480.0,
			"pierce": 2,
			"spread": 0.15,
			"projectiles": 2,
			"knockback": 50.0,
			"crit_chance": 0.08,
			"crit_mult": 1.5,
			"special": "poison_spell",
			"cost": 46,
			"color": Color8(80, 230, 60),
			"icon": "poison_orb"
		},
		"holy_sprinkler": {
			"id": "holy_sprinkler",
			"name": "Cooling Mortar",
			"type": "weapon",
			"category": "utility",
			"tier": TIER_LEGENDARY,
			"desc": "Water blast, cools furnace",
			"damage": 24.0,
			"fire_rate": 1.2,
			"range": 580.0,
			"bullet_speed": 500.0,
			"pierce": 2,
			"spread": 0.12,
			"projectiles": 2,
			"knockback": 130.0,
			"crit_chance": 0.12,
			"crit_mult": 1.8,
			"special": "furnace_cooling_shot",
			"cost": 85,
			"color": Color(0.1, 0.8, 0.9),
			"icon": "hydro"
		},
		"magma_shotgun": {
			"id": "magma_shotgun",
			"name": "Magma Shotgun",
			"type": "weapon",
			"category": "elemental",
			"tier": TIER_EPIC,
			"desc": "5-slug incendiary spread (3 dmg/1.5s)\n[color=#ff5555]-5% Speed[/color]",
			"damage": 9.0,
			"fire_rate": 1.0,
			"range": 340.0,
			"bullet_speed": 580.0,
			"pierce": 2,
			"spread": 0.32,
			"projectiles": 5,
			"knockback": 150.0,
			"crit_chance": 0.10,
			"crit_mult": 1.7,
			"special": "magma",
			"cost": 62,
			"color": Color8(255, 120, 30),
			"icon": "magma_shotgun"
		},
		"glacier_rifle": {
			"id": "glacier_rifle",
			"name": "Glacier Rifle",
			"type": "weapon",
			"category": "elemental",
			"tier": TIER_EPIC,
			"desc": "Freezing ice lance\n[color=#33ccff]Freezes on hit[/color]\n[color=#ff5555]-8% Atk Spd[/color]",
			"damage": 30.0,
			"fire_rate": 1.2,
			"range": 580.0,
			"bullet_speed": 750.0,
			"pierce": 3,
			"spread": 0.03,
			"projectiles": 1,
			"knockback": 110.0,
			"crit_chance": 0.14,
			"crit_mult": 1.8,
			"special": "freeze",
			"cost": 65,
			"color": Color8(90, 220, 255),
			"icon": "glacier_rifle"
		},
		"twin_dragon": {
			"id": "twin_dragon",
			"name": "Twin Dragon",
			"type": "weapon",
			"category": "energy",
			"tier": TIER_EPIC,
			"desc": "Dual fire & lightning bolts\n[color=#ffff55]Dual trajectory[/color]",
			"damage": 14.0,
			"fire_rate": 2.5,
			"range": 480.0,
			"bullet_speed": 720.0,
			"pierce": 2,
			"spread": 0.14,
			"projectiles": 2,
			"knockback": 80.0,
			"crit_chance": 0.10,
			"crit_mult": 1.7,
			"special": "twin_plasma",
			"cost": 60,
			"color": Color8(255, 210, 60),
			"icon": "twin_dragon"
		},
		"ricochet_revolver": {
			"id": "ricochet_revolver",
			"name": "Bouncing Magnum",
			"type": "weapon",
			"category": "precision",
			"tier": TIER_RARE,
			"desc": "High-impact ricochet rounds\n[color=#ffcc33]Bounces 3x off walls[/color]",
			"damage": 24.0,
			"fire_rate": 1.6,
			"range": 600.0,
			"bullet_speed": 820.0,
			"pierce": 2,
			"bounces": 3,
			"spread": 0.04,
			"projectiles": 1,
			"knockback": 160.0,
			"crit_chance": 0.16,
			"crit_mult": 2.0,
			"special": "ricochet",
			"cost": 48,
			"color": Color8(255, 225, 80),
			"icon": "ricochet_revolver"
		},
		"toxic_needle": {
			"id": "toxic_needle",
			"name": "Toxic Needler",
			"type": "weapon",
			"category": "elemental",
			"tier": TIER_RARE,
			"desc": "Rapid venom darts\n[color=#55ff55]Poisons & creates acid[/color]",
			"damage": 8.0,
			"fire_rate": 4.5,
			"range": 420.0,
			"bullet_speed": 750.0,
			"pierce": 1,
			"spread": 0.09,
			"projectiles": 1,
			"knockback": 30.0,
			"crit_chance": 0.06,
			"crit_mult": 1.5,
			"special": "toxic",
			"cost": 44,
			"color": Color8(60, 230, 80),
			"icon": "toxic_needle"
		},
		"saw_launcher": {
			"id": "saw_launcher",
			"name": "Sawblade Cannon",
			"type": "weapon",
			"category": "kinetic",
			"tier": TIER_EPIC,
			"desc": "Hurls bouncing razor saws\n[color=#cccccc]Bounces 4x & cuts 6x[/color]",
			"damage": 25.0,
			"fire_rate": 1.3,
			"range": 650.0,
			"bullet_speed": 620.0,
			"pierce": 6,
			"bounces": 4,
			"spread": 0.06,
			"projectiles": 1,
			"knockback": 130.0,
			"crit_chance": 0.12,
			"crit_mult": 1.75,
			"special": "sawblade",
			"cost": 64,
			"color": Color8(210, 225, 245),
			"icon": "saw_launcher"
		},
		"cluster_mortar": {
			"id": "cluster_mortar",
			"name": "Cluster Mortar",
			"type": "weapon",
			"category": "explosive",
			"tier": TIER_LEGENDARY,
			"desc": "Splits into 4 bomblets\n[color=#ff3333]Cluster AoE[/color]\n[color=#ff5555]-10% Speed[/color]",
			"damage": 40.0,
			"fire_rate": 0.8,
			"range": 560.0,
			"bullet_speed": 440.0,
			"pierce": 1,
			"spread": 0.05,
			"projectiles": 1,
			"knockback": 240.0,
			"aoe_radius": 100.0,
			"crit_chance": 0.15,
			"crit_mult": 2.0,
			"special": "cluster_bomb",
			"cost": 88,
			"color": Color8(255, 60, 40),
			"icon": "cluster_mortar"
		},
		"chrono_blaster": {
			"id": "chrono_blaster",
			"name": "Chrono Blaster",
			"type": "weapon",
			"category": "utility",
			"tier": TIER_RARE,
			"desc": "Time-warp temporal pulses\n[color=#aaccff]Slows enemies by 75%[/color]",
			"damage": 12.0,
			"fire_rate": 2.2,
			"range": 440.0,
			"bullet_speed": 600.0,
			"pierce": 2,
			"spread": 0.08,
			"projectiles": 1,
			"knockback": 60.0,
			"crit_chance": 0.08,
			"crit_mult": 1.5,
			"special": "temporal_slow",
			"cost": 46,
			"color": Color8(100, 180, 255),
			"icon": "chrono_blaster"
		},
		"arcane_splitter": {
			"id": "arcane_splitter",
			"name": "Arcane Prism Staff",
			"type": "weapon",
			"category": "spell",
			"tier": TIER_LEGENDARY,
			"desc": "Orb divides into 3 homing darts\n[color=#cc44ff]Split trajectory[/color]",
			"damage": 18.0,
			"fire_rate": 1.4,
			"range": 520.0,
			"bullet_speed": 550.0,
			"pierce": 1,
			"spread": 0.06,
			"projectiles": 1,
			"knockback": 90.0,
			"crit_chance": 0.15,
			"crit_mult": 1.9,
			"special": "split_arcane",
			"cost": 92,
			"color": Color8(210, 80, 255),
			"icon": "arcane_splitter"
		},
		"thunder_bow": {
			"id": "thunder_bow",
			"name": "Thunderbolt Bow",
			"type": "weapon",
			"category": "synergy",
			"tier": TIER_EPIC,
			"desc": "Chain lightning arrows\n[color=#ffff33]Electrocutes horde[/color]",
			"damage": 20.0,
			"fire_rate": 1.6,
			"range": 540.0,
			"bullet_speed": 800.0,
			"pierce": 2,
			"spread": 0.04,
			"projectiles": 1,
			"knockback": 110.0,
			"crit_chance": 0.12,
			"crit_mult": 1.75,
			"special": "lightning",
			"cost": 64,
			"color": Color8(255, 240, 60),
			"icon": "thunder_bow"
		},
		"inferno_repeater": {
			"id": "inferno_repeater",
			"name": "Volcano Repeater",
			"type": "weapon",
			"category": "elemental",
			"tier": TIER_RARE,
			"desc": "Rapid 3-round fire burst (3 dmg/1.5s burn)\n[color=#ff6622]Ignites & burns horde[/color]",
			"damage": 11.0,
			"fire_rate": 3.0,
			"range": 480.0,
			"bullet_speed": 750.0,
			"pierce": 2,
			"spread": 0.10,
			"projectiles": 3,
			"knockback": 70.0,
			"crit_chance": 0.10,
			"crit_mult": 1.65,
			"special": "burn",
			"cost": 50,
			"color": Color8(255, 110, 25),
			"icon": "inferno_repeater"
		},
		"frostfire_cannon": {
			"id": "frostfire_cannon",
			"name": "Thermal Disrupter",
			"type": "weapon",
			"category": "elemental",
			"tier": TIER_EPIC,
			"desc": "Dual frost & flame orbs\n[color=#33ddff]Freezes[/color] & [color=#ff5522]Burns targets[/color]",
			"damage": 18.0,
			"fire_rate": 1.6,
			"range": 500.0,
			"bullet_speed": 680.0,
			"pierce": 2,
			"spread": 0.14,
			"projectiles": 2,
			"knockback": 100.0,
			"crit_chance": 0.12,
			"crit_mult": 1.75,
			"special": "twin_plasma",
			"cost": 66,
			"color": Color8(120, 220, 255),
			"icon": "frostfire_cannon"
		},
		"arcane_railgun": {
			"id": "arcane_railgun",
			"name": "Aether Railgun",
			"type": "weapon",
			"category": "energy",
			"tier": TIER_LEGENDARY,
			"desc": "Infinite pierce beam lance\n[color=#dd44ff]Pierces everything in line[/color]",
			"damage": 55.0,
			"fire_rate": 0.60,
			"range": 850.0,
			"bullet_speed": 1400.0,
			"pierce": 99,
			"spread": 0.0,
			"projectiles": 1,
			"knockback": 300.0,
			"crit_chance": 0.22,
			"crit_mult": 2.3,
			"special": "split_arcane",
			"cost": 96,
			"color": Color8(225, 70, 255),
			"icon": "arcane_railgun"
		},
		"cluster_flak_cannon": {
			"id": "cluster_flak_cannon",
			"name": "Flak Cannon",
			"type": "weapon",
			"category": "explosive",
			"tier": TIER_EPIC,
			"desc": "6-pellet explosive blast\n[color=#ff4433]Close-range AoE[/color]",
			"damage": 9.0,
			"fire_rate": 0.90,
			"range": 360.0,
			"bullet_speed": 550.0,
			"pierce": 1,
			"spread": 0.36,
			"projectiles": 6,
			"knockback": 200.0,
			"aoe_radius": 50.0,
			"crit_chance": 0.10,
			"crit_mult": 1.7,
			"special": "explosive",
			"cost": 72,
			"color": Color8(255, 90, 40),
			"icon": "cluster_flak_cannon"
		},
		"chain_bolter": {
			"id": "chain_bolter",
			"name": "Storm Bolter",
			"type": "weapon",
			"category": "synergy",
			"tier": TIER_RARE,
			"desc": "Heavy electric bolts\n[color=#ffff55]Arcs lightning to 3 enemies[/color]",
			"damage": 14.0,
			"fire_rate": 2.5,
			"range": 460.0,
			"bullet_speed": 780.0,
			"pierce": 2,
			"spread": 0.08,
			"projectiles": 1,
			"knockback": 80.0,
			"crit_chance": 0.10,
			"crit_mult": 1.65,
			"special": "lightning",
			"cost": 54,
			"color": Color8(255, 235, 70),
			"icon": "chain_bolter"
		},
		"gravity_imploder": {
			"id": "gravity_imploder",
			"name": "Graviton Pulser",
			"type": "weapon",
			"category": "energy",
			"tier": TIER_EPIC,
			"desc": "Sucks enemies into vortex\n[color=#aa44ff]AoE implosion[/color]",
			"damage": 28.0,
			"fire_rate": 1.0,
			"range": 520.0,
			"bullet_speed": 460.0,
			"pierce": 1,
			"spread": 0.05,
			"projectiles": 1,
			"knockback": -180.0,
			"aoe_radius": 100.0,
			"crit_chance": 0.12,
			"crit_mult": 1.85,
			"special": "void_vortex",
			"cost": 68,
			"color": Color8(170, 50, 255),
			"icon": "gravity_imploder"
		},
		"dragon_breath": {
			"id": "dragon_breath",
			"name": "Dragon's Breath",
			"type": "weapon",
			"category": "elemental",
			"tier": TIER_LEGENDARY,
			"desc": "Incendiary magnum spread (3 dmg/1.5s burn)\n[color=#ffaa00]Flame damage & knockback[/color]",
			"damage": 26.0,
			"fire_rate": 1.1,
			"range": 420.0,
			"bullet_speed": 720.0,
			"pierce": 2,
			"spread": 0.22,
			"projectiles": 3,
			"knockback": 240.0,
			"crit_chance": 0.18,
			"crit_mult": 2.0,
			"special": "magma",
			"cost": 94,
			"color": Color8(255, 140, 20),
			"icon": "dragon_breath"
		},
		"mortar_strike": {
			"id": "mortar_strike",
			"name": "Orbital Barrage",
			"type": "weapon",
			"category": "explosive",
			"tier": TIER_LEGENDARY,
			"desc": "6-rocket artillery barrage\n[color=#ff4433]Massive explosive AoE[/color]",
			"damage": 28.0,
			"fire_rate": 0.75,
			"range": 620.0,
			"bullet_speed": 460.0,
			"pierce": 1,
			"spread": 0.32,
			"projectiles": 6,
			"knockback": 260.0,
			"aoe_radius": 85.0,
			"crit_chance": 0.16,
			"crit_mult": 2.0,
			"special": "explosive",
			"cost": 85,
			"color": Color8(255, 100, 30),
			"icon": "mortar"
		}
	}

func _init_skills() -> void:
	skills = {
		"raw_damage": {
			"id": "raw_damage",
			"name": "Hollow Point",
			"type": "skill",
			"tier": TIER_COMMON,
			"desc": "+13% Dmg",
			"stat": "damage_mult",
			"value": 0.13,
			"cost": 18,
			"icon": "damage"
		},
		"rapid_fire": {
			"id": "rapid_fire",
			"name": "Hair Trigger",
			"type": "skill",
			"tier": TIER_COMMON,
			"desc": "+13% Atk Spd",
			"stat": "attack_speed_mult",
			"value": 0.13,
			"cost": 20,
			"icon": "speed_atk"
		},
		"critical_eye": {
			"id": "critical_eye",
			"name": "Precision Optics",
			"type": "skill",
			"tier": TIER_RARE,
			"desc": "+8% Crit, +26% Crit Dmg",
			"stat": "crit_chance",
			"value": 0.08,
			"stat2": "crit_mult",
			"value2": 0.26,
			"cost": 28,
			"icon": "crit"
		},
		"titan_boots": {
			"id": "titan_boots",
			"name": "Greaves",
			"type": "skill",
			"tier": TIER_COMMON,
			"desc": "+11% Speed",
			"stat": "move_speed_mult",
			"value": 0.11,
			"cost": 16,
			"icon": "boots"
		},
		"reinforced_plate": {
			"id": "reinforced_plate",
			"name": "Ceramic Armor",
			"type": "skill",
			"tier": TIER_RARE,
			"desc": "+3 Armor",
			"stat": "armor",
			"value": 3.0,
			"cost": 25,
			"icon": "shield"
		},
		"vampiric_edge": {
			"id": "vampiric_edge",
			"name": "Leech Catalyst",
			"type": "skill",
			"tier": TIER_EPIC,
			"desc": "+3.3% Lifesteal",
			"stat": "lifesteal",
			"value": 0.033,
			"cost": 38,
			"icon": "lifesteal"
		},
		"magneto_core": {
			"id": "magneto_core",
			"name": "Resonator",
			"type": "skill",
			"tier": TIER_COMMON,
			"desc": "+33% Magnet",
			"stat": "pickup_radius_mult",
			"value": 0.33,
			"cost": 15,
			"icon": "magnet"
		},
		"vitality_surge": {
			"id": "vitality_surge",
			"name": "Adrenaline Tank",
			"type": "skill",
			"tier": TIER_COMMON,
			"desc": "+16 HP",
			"stat": "max_hp",
			"value": 16.0,
			"cost": 20,
			"icon": "heart"
		},
		"nanite_repair": {
			"id": "nanite_repair",
			"name": "Nano Rebuilder",
			"type": "skill",
			"tier": TIER_RARE,
			"desc": "+0.8 HP/s",
			"stat": "hp_regen",
			"value": 0.8,
			"cost": 30,
			"icon": "regen"
		},
		"clover_charm": {
			"id": "clover_charm",
			"name": "Lucky Charm",
			"type": "skill",
			"tier": TIER_RARE,
			"desc": "+20% Luck",
			"stat": "luck",
			"value": 0.20,
			"cost": 24,
			"icon": "clover"
		},
		"bone_satchel_expand": {
			"id": "bone_satchel_expand",
			"name": "Hauler Pack",
			"type": "skill",
			"tier": TIER_COMMON,
			"desc": "+5 Bone Cap",
			"stat": "max_bones_held",
			"value": 5,
			"cost": 20,
			"icon": "bone"
		},
		"water_backpack": {
			"id": "water_backpack",
			"name": "Water Tank",
			"type": "skill",
			"tier": TIER_COMMON,
			"desc": "+33 Water, +20% Range",
			"stat": "max_water",
			"value": 33.0,
			"stat2": "spray_range_mult",
			"value2": 0.20,
			"cost": 18,
			"icon": "water_tank"
		},
		"super_coolant": {
			"id": "super_coolant",
			"name": "Super Coolant",
			"type": "skill",
			"tier": TIER_RARE,
			"desc": "+33% Cooling Power",
			"stat": "cooling_efficiency",
			"value": 0.33,
			"cost": 28,
			"icon": "ice"
		},
		"hydro_pump": {
			"id": "hydro_pump",
			"name": "Hydro Pump",
			"type": "skill",
			"tier": TIER_RARE,
			"desc": "+10% Water Regen",
			"stat": "water_regen_rate",
			"value": 0.10,
			"cost": 24,
			"icon": "pump"
		},
		"cryo_reservoir": {
			"id": "cryo_reservoir",
			"name": "Cryo Reservoir",
			"type": "skill",
			"tier": TIER_EPIC,
			"desc": "+30 Water, +15% Refill",
			"stat": "max_water",
			"value": 30.0,
			"stat2": "water_regen_rate",
			"value2": 0.15,
			"cost": 36,
			"icon": "water_tank"
		},
		"frenzy_catalyst": {
			"id": "frenzy_catalyst",
			"name": "Heat Resonator",
			"type": "skill",
			"tier": TIER_EPIC,
			"desc": "+65% Dmg in Critical Heat",
			"stat": "heat_frenzy_bonus",
			"value": 0.65,
			"cost": 42,
			"icon": "frenzy"
		},
		"dash_booster": {
			"id": "dash_booster",
			"name": "Thruster Overclock",
			"type": "skill",
			"tier": TIER_RARE,
			"desc": "-30% Dash Cooldown Delay",
			"stat": "dash_cooldown_mult",
			"value": -0.30,
			"cost": 24,
			"icon": "boots"
		}
	}

func _init_furnace_upgrades() -> void:
	furnace_upgrades = {
		"bone_hopper_1": {
			"id": "bone_hopper_1",
			"name": "Bone Hopper I",
			"type": "furnace",
			"tier": TIER_COMMON,
			"desc": "+26 Bone Cap, +33% Feed",
			"furnace_stat": "max_bone_capacity",
			"value": 26,
			"cost": 20,
			"icon": "hopper"
		},
		"bone_hopper_2": {
			"id": "bone_hopper_2",
			"name": "Bone Hopper II",
			"type": "furnace",
			"tier": TIER_RARE,
			"desc": "+52 Bone Cap, +65% Feed\n[color=#ff5555]+15% Heat[/color]",
			"furnace_stat": "max_bone_capacity",
			"value": 52,
			"drawback_furnace_stat": "heat_per_bone_mult",
			"drawback_value": 0.15,
			"cost": 45,
			"icon": "hopper"
		},
		"turbo_smelter_1": {
			"id": "turbo_smelter_1",
			"name": "Smelt Blades I",
			"type": "furnace",
			"tier": TIER_COMMON,
			"desc": "+26% Smelt Spd",
			"furnace_stat": "process_speed_mult",
			"value": 0.26,
			"cost": 25,
			"icon": "turbo"
		},
		"turbo_smelter_2": {
			"id": "turbo_smelter_2",
			"name": "Smelt Blades II",
			"type": "furnace",
			"tier": TIER_RARE,
			"desc": "+52% Smelt Spd\n[color=#ff5555]-12% Gold[/color]",
			"furnace_stat": "process_speed_mult",
			"value": 0.52,
			"drawback_furnace_stat": "coin_yield_mult",
			"drawback_value": -0.12,
			"cost": 50,
			"icon": "turbo"
		},
		"golden_crucible_1": {
			"id": "golden_crucible_1",
			"name": "Gold Alchemy I",
			"type": "furnace",
			"tier": TIER_RARE,
			"desc": "+24% Gold Yield",
			"furnace_stat": "coin_yield_mult",
			"value": 0.24,
			"cost": 35,
			"icon": "crucible"
		},
		"golden_crucible_2": {
			"id": "golden_crucible_2",
			"name": "Gold Alchemy II",
			"type": "furnace",
			"tier": TIER_EPIC,
			"desc": "+46% Gold Yield\n[color=#ff5555]+20% Heat[/color]",
			"furnace_stat": "coin_yield_mult",
			"value": 0.46,
			"drawback_furnace_stat": "heat_per_bone_mult",
			"drawback_value": 0.20,
			"cost": 70,
			"icon": "crucible"
		},
		"thermal_insulation": {
			"id": "thermal_insulation",
			"name": "Heat Baffles",
			"type": "furnace",
			"tier": TIER_RARE,
			"desc": "-26% Heat Gen",
			"furnace_stat": "heat_per_bone_mult",
			"value": -0.26,
			"cost": 32,
			"icon": "insulation"
		},
		"reinforced_core": {
			"id": "reinforced_core",
			"name": "Boiler Core",
			"type": "furnace",
			"tier": TIER_EPIC,
			"desc": "+33 Safe Heat\n[color=#ff5555]+12% Meltdown Spd[/color]",
			"furnace_stat": "max_temp_bonus",
			"value": 33.0,
			"drawback_furnace_stat": "heat_per_bone_mult",
			"drawback_value": 0.12,
			"cost": 48,
			"icon": "core"
		},
		"water_injection_ports": {
			"id": "water_injection_ports",
			"name": "Injection Ports",
			"type": "furnace",
			"tier": TIER_RARE,
			"desc": "+46% Cooling Rate",
			"furnace_stat": "cooling_absorption_mult",
			"value": 0.46,
			"cost": 30,
			"icon": "injection"
		},
		"emergency_valve": {
			"id": "emergency_valve",
			"name": "Steam Valve",
			"type": "furnace",
			"tier": TIER_EPIC,
			"desc": "Auto-cool at 98% (1x)",
			"furnace_stat": "emergency_cool_charges",
			"value": 1,
			"cost": 55,
			"icon": "valve"
		},
		"greed_igniter": {
			"id": "greed_igniter",
			"name": "Supercharger",
			"type": "furnace",
			"tier": TIER_LEGENDARY,
			"desc": "3.25x Gold in Critical Heat\n[color=#ff5555]+15% Meltdown Spd[/color]",
			"furnace_stat": "critical_multiplier_bonus",
			"value": 1.3,
			"drawback_furnace_stat": "heat_per_bone_mult",
			"drawback_value": 0.15,
			"cost": 80,
			"icon": "greed"
		},
		"steam_blast_defense": {
			"id": "steam_blast_defense",
			"name": "Steam Purge",
			"type": "furnace",
			"tier": TIER_RARE,
			"desc": "Steam shockwave on cooling",
			"furnace_stat": "steam_blast_unlocked",
			"value": 1,
			"cost": 38,
			"icon": "steam_shock"
		},
		"furnace_heat_sink": {
			"id": "furnace_heat_sink",
			"name": "Heat Exchanger",
			"type": "furnace",
			"tier": TIER_RARE,
			"desc": "+25 Safe Heat Capacity",
			"furnace_stat": "max_temp_bonus",
			"value": 25.0,
			"cost": 35,
			"icon": "barricade"
		}
	}

func _init_abilities() -> void:
	abilities = {}

func _init_active_skills() -> void:
	active_skills = {
		"active_damage_boost": {
			"id": "active_damage_boost",
			"name": "Overdrive Surge",
			"type": "active_skill",
			"tier": TIER_RARE,
			"desc": "+100% Dmg for 10s\n[color=#ffff55][CD: 20s | Key 1/2/3][/color]",
			"duration": 10.0,
			"cooldown": 20.0,
			"icon_tag": "DMG",
			"color": Color8(255, 110, 40),
			"cost": 32,
			"icon": "damage"
		},
		"active_shield": {
			"id": "active_shield",
			"name": "Aegis Barrier",
			"type": "active_skill",
			"tier": TIER_EPIC,
			"desc": "Invulnerable Barrier for 6s\n[color=#ffff55][CD: 22s | Key 1/2/3][/color]",
			"duration": 6.0,
			"cooldown": 22.0,
			"icon_tag": "SHD",
			"color": Color8(60, 210, 255),
			"cost": 42,
			"icon": "shield"
		},
		"active_frost_nova": {
			"id": "active_frost_nova",
			"name": "Cryo Shockwave",
			"type": "active_skill",
			"tier": TIER_RARE,
			"desc": "Freezes all nearby monsters (5s)\n[color=#ffff55][CD: 18s | Key 1/2/3][/color]",
			"duration": 0.5,
			"cooldown": 18.0,
			"icon_tag": "ICE",
			"color": Color8(120, 230, 255),
			"cost": 35,
			"icon": "frost_nova"
		}
	}

func get_item(id: String) -> Dictionary:
	if weapons.has(id): return weapons[id]
	if skills.has(id): return skills[id]
	if furnace_upgrades.has(id): return furnace_upgrades[id]
	if abilities.has(id): return abilities[id]
	if active_skills.has(id): return active_skills[id]
	if turrets.has(id): return turrets[id]
	if id.begins_with("weapon_slot"): return get_weapon_slot_card()
	return {}

func get_weapon_slot_card() -> Dictionary:
	if not is_instance_valid(GameManager): return {}
	var cur_slots = GameManager.max_weapon_slots
	if cur_slots >= GameManager.MAX_WEAPONS:
		return {}
	var next_cost = GameManager.get_next_weapon_slot_cost()
	if next_cost <= 0: return {}
	
	var tier = TIER_RARE
	if cur_slots == 4:
		tier = TIER_EPIC
	elif cur_slots >= 5:
		tier = TIER_LEGENDARY
		
	return {
		"id": "weapon_slot_%d" % (cur_slots + 1),
		"name": "Arsenal Slot %d" % (cur_slots + 1),
		"type": "weapon_slot",
		"tier": tier,
		"desc": "Unlock Slot %d / 6\n[color=#55ff88]+1 Weapon Slot[/color]" % (cur_slots + 1),
		"cost": next_cost,
		"icon": "slot_expansion"
	}

func get_weapon_upgrade(base_id: String, target_tier: int) -> Dictionary:
	if not weapons.has(base_id): return {}
	var base_w = weapons[base_id].duplicate(true)
	var tier_roman = ["I", "II", "III", "IV"][clamp(target_tier, 0, 3)]
	
	base_w["tier"] = target_tier
	base_w["is_weapon_upgrade"] = true
	base_w["base_weapon_id"] = base_id
	base_w["name"] = "%s %s" % [base_w.get("name", "Gun"), TIER_NAMES.get(target_tier, "Upgrade")]
	base_w["color"] = TIER_COLORS.get(target_tier, Color.WHITE)
	base_w["damage"] = base_w.get("damage", 10.0) * (1.0 + target_tier * 0.45)
	base_w["fire_rate"] = base_w.get("fire_rate", 2.0) * (1.0 + target_tier * 0.13)
	base_w["crit_chance"] = base_w.get("crit_chance", 0.05) + target_tier * 0.04
	base_w["cost"] = int(base_w.get("cost", 20) * (1.0 + target_tier * 0.55))
	base_w["desc"] = "+45% Dmg, +13% Spd, +4% Crit"
	
	if target_tier >= TIER_EPIC and base_w.get("projectiles", 1) == 1 and base_w.get("category") == "kinetic":
		base_w["projectiles"] = 2
		base_w["spread"] = base_w.get("spread", 0.05) * 1.3
		
	if target_tier >= TIER_RARE:
		base_w["pierce"] = base_w.get("pierce", 1) + 1
		
	if base_id == "cryo_blaster":
		var bonus_tier = max(0, target_tier - TIER_RARE)
		var new_slow = 0.40 + (bonus_tier * 0.10)
		base_w["slow_factor"] = new_slow
		base_w["desc"] = "+45% Dmg, +13% Spd, +4% Crit\n[color=#33ccff]+10% Slow (" + str(int(round(new_slow * 100.0))) + "% Slow)[/color]"
		
	return base_w

func get_random_shop_pool(count: int = 4, luck_stat: float = 0.0, current_wave: int = 1) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	var unowned_weapons: Array[Dictionary] = []
	var owned_base_ids: Array[String] = []
	
	if is_instance_valid(GameManager):
		for eq in GameManager.equipped_weapons:
			var base_id = eq.get("base_weapon_id", eq.get("id", ""))
			owned_base_ids.append(base_id)
			
	for w_id in weapons.keys():
		if not (w_id in owned_base_ids):
			unowned_weapons.append(weapons[w_id])
	unowned_weapons.shuffle()
	
	# 1. High Gun Chance: 75% chance for weapon slot 1, 60% chance for weapon slot 2 if player has slots (<6)
	var weapons_equipped_count = GameManager.equipped_weapons.size() if is_instance_valid(GameManager) else 1
	if weapons_equipped_count < 6 and unowned_weapons.size() > 0 and pool.size() < count:
		if randf() < 0.75:
			pool.append(unowned_weapons.pop_back().duplicate(true))
		if weapons_equipped_count < 5 and unowned_weapons.size() > 0 and pool.size() < count:
			if randf() < 0.60:
				pool.append(unowned_weapons.pop_back().duplicate(true))
			
	# 2. Add weapon upgrade for owned weapons with high chance (60% chance)
	if is_instance_valid(GameManager) and pool.size() < count:
		var upgradable_weapons: Array[Dictionary] = []
		for eq in GameManager.equipped_weapons:
			var base_id = eq.get("base_weapon_id", eq.get("id", ""))
			var current_tier = eq.get("tier", TIER_COMMON)
			if current_tier < TIER_LEGENDARY:
				upgradable_weapons.append(eq)
		upgradable_weapons.shuffle()
		if not upgradable_weapons.is_empty() and randf() < 0.60:
			var eq = upgradable_weapons[0]
			var base_id = eq.get("base_weapon_id", eq.get("id", ""))
			var up_weapon = get_weapon_upgrade(base_id, eq.get("tier", TIER_COMMON) + 1)
			if not up_weapon.is_empty():
				pool.append(up_weapon)
				
	# 3. Add active skills if player has fewer than 3 active skills
	var owned_active_ids: Array[String] = []
	if is_instance_valid(GameManager):
		for a_skill in GameManager.active_skills:
			owned_active_ids.append(a_skill.get("id", ""))
			
	var unowned_active: Array[Dictionary] = []
	for a_id in active_skills.keys():
		if not (a_id in owned_active_ids):
			unowned_active.append(active_skills[a_id])
	unowned_active.shuffle()
	
	if unowned_active.size() > 0 and pool.size() < count and randf() < 0.65:
		pool.append(unowned_active.pop_back().duplicate(true))
		
	# 4. Chance to roll a Weapon Slot Expansion card
	if is_instance_valid(GameManager) and GameManager.max_weapon_slots < 6 and pool.size() < count:
		if randf() < 0.35:
			var slot_card_roll = get_weapon_slot_card()
			if not slot_card_roll.is_empty():
				pool.append(slot_card_roll)
					
	# 4.5. High Chance for Legendary Turret Card (boosted for user testing)
	if pool.size() < count and randf() < 0.75:
		var turret_keys = turrets.keys()
		if not turret_keys.is_empty():
			var chosen_t = turrets[turret_keys[randi() % turret_keys.size()]]
			pool.append(chosen_t.duplicate(true))
					
	# 5. Fill remaining slots with skills, furnace upgrades, active skills, turrets, and slot expansion
	var general_pool: Array[Dictionary] = []
	for s in skills.values(): general_pool.append(s)
	for f in furnace_upgrades.values(): general_pool.append(f)
	for act in unowned_active: general_pool.append(act)
	for w in unowned_weapons: general_pool.append(w)
	for t in turrets.values(): general_pool.append(t)
	var slot_card = get_weapon_slot_card()
	if not slot_card.is_empty():
		general_pool.append(slot_card)
	general_pool.shuffle()
	
	for item in general_pool:
		if pool.size() >= count:
			break
		var item_tier = item.get("tier", TIER_COMMON)
		var keep_chance = 1.0
		
		match item_tier:
			TIER_COMMON:
				keep_chance = max(0.4, 1.0 - (current_wave * 0.03) - (luck_stat * 0.5))
			TIER_RARE:
				keep_chance = clamp(0.35 + (current_wave * 0.03) + (luck_stat * 0.4), 0.25, 0.85)
			TIER_EPIC:
				keep_chance = clamp(0.15 + (current_wave * 0.04) + (luck_stat * 0.5), 0.15, 0.70)
			TIER_LEGENDARY:
				keep_chance = clamp(0.06 + (current_wave * 0.03) + (luck_stat * 0.6), 0.08, 0.50)
				
		if randf() <= keep_chance:
			pool.append(item.duplicate(true))
			
	while pool.size() < count and general_pool.size() > 0:
		pool.append(general_pool[randi() % general_pool.size()].duplicate(true))
		
	return pool
