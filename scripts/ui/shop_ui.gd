# shop_ui.gd - Brotato-Inspired Roguelite Armory & Foundry Shop
class_name ShopUI
extends CanvasLayer

signal save_and_quit_requested()

var shop_cards: Array[Dictionary] = []
var locked_indices: Array[int] = []
var reroll_cost: int = 5

# Root views
@onready var shop_main_view: VBoxContainer = $Root/Margin/ShopMainView
@onready var my_weapons_view: VBoxContainer = $Root/Margin/MyWeaponsView

# Shop Main View Node References
@onready var gold_label: Label = $Root/Margin/ShopMainView/TopBar/GoldLabel
@onready var bones_label: Label = $Root/Margin/ShopMainView/TopBar/BonesLabel
@onready var stats_title: Label = $Root/Margin/ShopMainView/ContentHBox/StatsPanel/StatsMargin/StatsVBox/StatsTitle
@onready var stats_label: RichTextLabel = $Root/Margin/ShopMainView/ContentHBox/StatsPanel/StatsMargin/StatsVBox/StatsLabel
@onready var card_container: HBoxContainer = $Root/Margin/ShopMainView/ContentHBox/CenterVBox/CardContainer
@onready var save_quit_btn: Button = $Root/Margin/ShopMainView/ContentHBox/CenterVBox/ActionBar/ShopSaveQuitButton
@onready var my_weapons_btn: Button = $Root/Margin/ShopMainView/ContentHBox/CenterVBox/ActionBar/MyWeaponsButton
@onready var reroll_btn: Button = $Root/Margin/ShopMainView/ContentHBox/CenterVBox/ActionBar/RerollButton
@onready var next_wave_btn: Button = $Root/Margin/ShopMainView/ContentHBox/CenterVBox/ActionBar/NextWaveButton

# My Weapons View Node References
@onready var weapons_title: Label = $Root/Margin/MyWeaponsView/WeaponsTopBar/WeaponsTitle
@onready var weapons_gold_label: Label = $Root/Margin/MyWeaponsView/WeaponsTopBar/WeaponsGoldLabel
@onready var weapons_back_btn: Button = $Root/Margin/MyWeaponsView/WeaponsTopBar/WeaponsBackButton
@onready var weapons_grid: GridContainer = $Root/Margin/MyWeaponsView/WeaponsGrid
@onready var weapons_back_bottom_btn: Button = $Root/Margin/MyWeaponsView/WeaponsBottomBar/WeaponsBackBottomButton

func _ready() -> void:
	_connect_events()
	_setup_buttons()

func _setup_buttons() -> void:
	if save_quit_btn:
		_style_button(save_quit_btn, Color8(55, 200, 255), Color8(15, 38, 55), Color8(150, 235, 255), Color8(25, 65, 95))
		save_quit_btn.pressed.connect(_on_save_quit_pressed)
	if reroll_btn:
		_style_button(reroll_btn, Color8(255, 195, 35), Color8(45, 30, 10), Color8(255, 235, 100), Color8(75, 50, 15))
		reroll_btn.pressed.connect(_on_reroll_pressed)
	if next_wave_btn:
		_style_button(next_wave_btn, Color8(44, 245, 120), Color8(15, 45, 25), Color8(120, 255, 170), Color8(25, 75, 40))
		next_wave_btn.pressed.connect(_on_next_wave_pressed)
	if my_weapons_btn:
		_style_button(my_weapons_btn, Color8(50, 190, 255), Color8(15, 35, 60), Color8(140, 230, 255), Color8(25, 60, 100))
		my_weapons_btn.pressed.connect(func(): _toggle_my_weapons_view(true))
	if weapons_back_btn:
		_style_button(weapons_back_btn, Color8(180, 200, 220), Color8(25, 32, 45), Color8(230, 240, 255), Color8(45, 55, 75))
		weapons_back_btn.pressed.connect(func(): _toggle_my_weapons_view(false))
	if weapons_back_bottom_btn:
		_style_button(weapons_back_bottom_btn, Color8(180, 200, 220), Color8(25, 32, 45), Color8(230, 240, 255), Color8(45, 55, 75))
		weapons_back_bottom_btn.pressed.connect(func(): _toggle_my_weapons_view(false))
	
	# Connect and style shop cards
	for i in range(4):
		var card_node = card_container.get_node_or_null("Card%d" % i)
		if card_node:
			var buy_b = card_node.get_node_or_null("Margin/VBox/BuyButton") as Button
			var lock_b = card_node.get_node_or_null("Margin/VBox/LockButton") as Button
			var idx = i
			if buy_b:
				_style_button(buy_b, Color8(55, 200, 255), Color8(20, 36, 54), Color8(150, 235, 255), Color8(35, 70, 110))
				buy_b.pressed.connect(func(): _on_buy_item_clicked(idx))
			if lock_b:
				_style_button(lock_b, Color8(190, 85, 255), Color8(38, 18, 52), Color8(230, 150, 255), Color8(60, 28, 85))
				lock_b.pressed.connect(func(): _toggle_card_lock(idx))
				
	# Connect and style My Weapons slots
	for i in range(GameManager.MAX_WEAPONS):
		var slot_node = weapons_grid.get_node_or_null("Slot%d" % i)
		if slot_node:
			var sell_b = slot_node.get_node_or_null("Margin/VBox/BottomHBox/SellButton") as Button
			var unlock_b = slot_node.get_node_or_null("Margin/VBox/BottomHBox/UnlockButton") as Button
			var idx = i
			if sell_b:
				_style_button(sell_b, Color8(255, 85, 65), Color8(50, 18, 15), Color8(255, 150, 135), Color8(85, 30, 25))
				sell_b.pressed.connect(func(): _on_sell_weapon_clicked(idx))
			if unlock_b:
				_style_button(unlock_b, Color8(255, 160, 40), Color8(55, 30, 10), Color8(255, 200, 90), Color8(85, 48, 15))
				unlock_b.pressed.connect(_on_buy_slot_clicked)

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
	
	var sb_disabled = StyleBoxFlat.new()
	sb_disabled.bg_color = Color8(25, 28, 35)
	sb_disabled.border_color = Color8(60, 65, 75)
	sb_disabled.set_border_width_all(2)
	sb_disabled.set_corner_radius_all(6)
	
	btn.add_theme_stylebox_override("normal", sb_norm)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_stylebox_override("focus", sb_hover)
	btn.add_theme_stylebox_override("disabled", sb_disabled)

func _connect_events() -> void:
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.weapons_updated.connect(_on_weapons_updated)

func reset_shop() -> void:
	locked_indices.clear()
	shop_cards.clear()
	reroll_cost = 5
	visible = false

func open_shop() -> void:
	visible = true
	_toggle_my_weapons_view(false)
	_generate_shop_pool(false)
	_update_stats_display()
	_update_slot_buttons()
	_update_gold_display()
	if next_wave_btn:
		next_wave_btn.text = "START WAVE %d >>" % GameManager.current_wave

func close_shop() -> void:
	visible = false

func _toggle_my_weapons_view(show_weapons: bool) -> void:
	SoundManager.play_sfx("button_click")
	if show_weapons:
		if shop_main_view: shop_main_view.visible = false
		if my_weapons_view: my_weapons_view.visible = true
		_update_my_weapons_display()
		_update_slot_buttons()
		_update_gold_display()
	else:
		if shop_main_view: shop_main_view.visible = true
		if my_weapons_view: my_weapons_view.visible = false
		_update_stats_display()
		_update_slot_buttons()
		_update_gold_display()
		_render_cards() # Re-render existing shop cards without rerolling

func _generate_shop_pool(is_reroll: bool) -> void:
	while shop_cards.size() < 4:
		shop_cards.append({})
		
	if is_reroll:
		var new_items: Array[Dictionary] = ItemDatabase.get_random_shop_pool(4, GameManager.luck, GameManager.current_wave)
		for i in range(4):
			if not (i in locked_indices):
				if i < new_items.size():
					shop_cards[i] = new_items[i]
	else:
		var preserved_cards: Array[Dictionary] = []
		for i in range(4):
			if i in locked_indices and i < shop_cards.size() and not shop_cards[i].is_empty():
				preserved_cards.append(shop_cards[i])
			else:
				preserved_cards.append({})
				
		var roll_count = 4 - locked_indices.size()
		var new_items: Array[Dictionary] = ItemDatabase.get_random_shop_pool(roll_count, GameManager.luck, GameManager.current_wave)
		var new_idx = 0
		for i in range(4):
			if not (i in locked_indices):
				if new_idx < new_items.size():
					preserved_cards[i] = new_items[new_idx]
					new_idx += 1
		shop_cards = preserved_cards
				
	_render_cards()

func _render_cards() -> void:
	if not card_container: return
	
	for i in range(4):
		var card_panel = card_container.get_node_or_null("Card%d" % i)
		if not card_panel: continue
		
		if i >= shop_cards.size() or shop_cards[i].is_empty():
			card_panel.visible = false
			continue
			
		card_panel.visible = true
		var item = shop_cards[i]
		var tier = item.get("tier", ItemDatabase.TIER_COMMON)
		var tier_col = ItemDatabase.TIER_COLORS.get(tier, Color.WHITE)
		var tier_name = ItemDatabase.TIER_NAMES.get(tier, "Common")
		var is_up = item.get("is_weapon_upgrade", false)
		var is_slot = (item.get("type") == "weapon_slot")
		
		var sb_card = card_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if sb_card:
			match tier:
				ItemDatabase.TIER_COMMON:
					sb_card.bg_color = Color8(28, 32, 42, 255)
					sb_card.border_color = Color8(150, 165, 185)
				ItemDatabase.TIER_RARE:
					sb_card.bg_color = Color8(16, 40, 75, 255)
					sb_card.border_color = Color8(40, 190, 255)
				ItemDatabase.TIER_EPIC:
					sb_card.bg_color = Color8(48, 16, 68, 255)
					sb_card.border_color = Color8(225, 60, 255)
				ItemDatabase.TIER_LEGENDARY:
					sb_card.bg_color = Color8(65, 38, 8, 255)
					sb_card.border_color = Color8(255, 215, 30)
				_:
					sb_card.bg_color = Color8(24, 28, 36, 255)
					sb_card.border_color = tier_col
			sb_card.set_border_width_all(3)
			card_panel.add_theme_stylebox_override("panel", sb_card)
			
		var tier_badge = card_panel.get_node_or_null("Margin/VBox/TierBadge") as Label
		if tier_badge:
			if is_up:
				tier_badge.text = "[ UPGRADE ]"
				tier_badge.modulate = Color8(44, 245, 78)
			elif is_slot:
				tier_badge.text = "[ +1 SLOT ]"
				tier_badge.modulate = Color8(255, 195, 40)
			else:
				tier_badge.text = "[ %s ]" % tier_name.to_upper()
				tier_badge.modulate = tier_col
			
		var icon_rect = card_panel.get_node_or_null("Margin/VBox/IconRect") as TextureRect
		if icon_rect:
			var icon_tex = VisualFactory.get_item_icon(item)
			icon_rect.texture = icon_tex
			icon_rect.visible = (icon_tex != null)
				
		var name_lbl = card_panel.get_node_or_null("Margin/VBox/NameLabel") as Label
		if name_lbl:
			name_lbl.text = item.get("name", "Item")
			
		var desc_lbl = card_panel.get_node_or_null("Margin/VBox/DescLabel") as RichTextLabel
		if desc_lbl:
			desc_lbl.text = "[font_size=15]" + item.get("desc", "") + "[/font_size]"
			
		var cost = item.get("cost", 10)
		var cost_lbl = card_panel.get_node_or_null("Margin/VBox/CostLabel") as Label
		if cost_lbl:
			cost_lbl.text = "%d GOLD" % cost
			
		var buy_btn = card_panel.get_node_or_null("Margin/VBox/BuyButton") as Button
		if buy_btn:
			var is_weapon = (item.get("type") == "weapon")
			var inventory_full = is_weapon and not is_up and GameManager.equipped_weapons.size() >= GameManager.max_weapon_slots
			
			if inventory_full:
				buy_btn.text = "SLOTS FULL"
				buy_btn.disabled = true
				_style_button(buy_btn, Color8(80, 85, 95), Color8(25, 28, 35), Color8(80, 85, 95), Color8(25, 28, 35))
			elif is_slot:
				buy_btn.text = "UNLOCK"
				buy_btn.disabled = (GameManager.coins < cost or GameManager.max_weapon_slots >= GameManager.MAX_WEAPONS)
				_style_button(buy_btn, Color8(255, 170, 40), Color8(55, 30, 10), Color8(255, 210, 80), Color8(85, 48, 15))
			else:
				buy_btn.text = "UPGRADE" if is_up else "BUY"
				buy_btn.disabled = GameManager.coins < cost
				if is_up:
					_style_button(buy_btn, Color8(44, 245, 120), Color8(15, 45, 25), Color8(120, 255, 170), Color8(25, 75, 40))
				else:
					_style_button(buy_btn, tier_col, Color8(20, 30, 45), Color.WHITE, Color8(35, 60, 95))
			
		var lock_btn = card_panel.get_node_or_null("Margin/VBox/LockButton") as Button
		if lock_btn:
			var is_locked = (i in locked_indices)
			lock_btn.text = "LOCKED" if is_locked else "LOCK"
			if is_locked:
				_style_button(lock_btn, Color8(255, 195, 35), Color8(55, 38, 10), Color8(255, 235, 120), Color8(80, 55, 15))
			else:
				_style_button(lock_btn, Color8(180, 90, 255), Color8(35, 18, 50), Color8(230, 150, 255), Color8(60, 30, 85))

func _toggle_card_lock(idx: int) -> void:
	if idx in locked_indices:
		locked_indices.erase(idx)
	else:
		locked_indices.append(idx)
	SoundManager.play_sfx("button_click")
	_render_cards()

func _on_buy_item_clicked(idx: int) -> void:
	if idx < 0 or idx >= shop_cards.size(): return
	var item = shop_cards[idx]
	var success = GameManager.buy_item(item)
	if success:
		if idx in locked_indices:
			locked_indices.erase(idx)
		var new_items: Array[Dictionary] = ItemDatabase.get_random_shop_pool(1, GameManager.luck, GameManager.current_wave)
		if not new_items.is_empty():
			shop_cards[idx] = new_items[0]
		else:
			shop_cards[idx] = {}
		_update_slot_buttons()
		_update_gold_display()
		_update_stats_display()
		_render_cards()

func _on_buy_slot_clicked() -> void:
	var success = GameManager.buy_weapon_slot()
	if success:
		_update_slot_buttons()
		_update_gold_display()
		_update_stats_display()
		if my_weapons_view and my_weapons_view.visible:
			_update_my_weapons_display()
		_render_cards()

func _on_reroll_pressed() -> void:
	if GameManager.spend_coins(reroll_cost):
		SoundManager.play_sfx("button_click")
		_generate_shop_pool(true)
		_update_gold_display()

func _on_save_quit_pressed() -> void:
	SoundManager.play_sfx("buy_item")
	GameManager.save_current_run("SHOP")
	close_shop()
	emit_signal("save_and_quit_requested")

func _on_next_wave_pressed() -> void:
	close_shop()
	GameManager.advance_to_next_wave()

func _on_coins_changed(_amount: int, _delta: int) -> void:
	_update_gold_display()
	_update_slot_buttons()
	_render_cards()

func _on_weapons_updated() -> void:
	_update_slot_buttons()
	if my_weapons_view and my_weapons_view.visible:
		_update_my_weapons_display()
	_render_cards()

func _update_slot_buttons() -> void:
	var equipped_cnt = GameManager.equipped_weapons.size()
	var max_slots = GameManager.max_weapon_slots
	
	if my_weapons_btn:
		my_weapons_btn.text = "MY WEAPONS (%d/%d)" % [equipped_cnt, max_slots]
		
	if weapons_title:
		weapons_title.text = "[ MY WEAPONS & LOADOUT (%d / %d SLOTS) ]" % [equipped_cnt, max_slots]

func _update_gold_display() -> void:
	if gold_label:
		gold_label.text = "GOLD: %d" % GameManager.coins
	if bones_label:
		bones_label.text = "BONES: %d / %d" % [GameManager.bones_held, GameManager.max_bones_held]
	if weapons_gold_label:
		weapons_gold_label.text = "GOLD: %d" % GameManager.coins

func _update_stats_display() -> void:
	if not stats_label: return
	var s = "[font_size=19]"
	s += "[b]HP:[/b] %d\n" % int(GameManager.max_hp)
	s += "[b]Regen:[/b] %.1f/s\n" % GameManager.hp_regen
	s += "[b]Armor:[/b] %d\n" % int(GameManager.armor)
	s += "[b]Dmg:[/b] +%.0f%%\n" % ((GameManager.damage_mult - 1.0) * 100.0)
	s += "[b]Atk Spd:[/b] +%.0f%%\n" % ((GameManager.attack_speed_mult - 1.0) * 100.0)
	s += "[b]Crit:[/b] %.0f%%\n" % (GameManager.crit_chance * 100.0)
	s += "[b]Crit Dmg:[/b] %.1fx\n" % GameManager.crit_mult
	s += "[b]Speed:[/b] +%.0f%%\n" % ((GameManager.move_speed_mult - 1.0) * 100.0)
	s += "[b]Lifesteal:[/b] %.0f%%\n" % (GameManager.lifesteal * 100.0)
	s += "[b]Luck:[/b] +%.0f%%\n" % (GameManager.luck * 100.0)
	s += "[b]Bone Cap:[/b] %d\n" % GameManager.max_bones_held
	s += "\n[color=#ff9933][b]--- FURNACE ---[/b][/color]\n"
	s += "[b]Cap:[/b] %d\n" % GameManager.furnace_max_bones
	s += "[b]Smelt:[/b] +%.0f%%\n" % ((GameManager.furnace_process_speed_mult - 1.0) * 100.0)
	s += "[b]Gold:[/b] +%.0f%%\n" % ((GameManager.furnace_coin_yield_mult - 1.0) * 100.0)
	s += "[b]Safe Heat:[/b] %.0f C\n" % (100.0 + GameManager.furnace_max_temp_bonus)
	s += "[/font_size]"
	stats_label.text = s

func _update_my_weapons_display() -> void:
	if not weapons_grid: return
	
	var equipped_cnt = GameManager.equipped_weapons.size()
	var max_slots = GameManager.max_weapon_slots
	
	for i in range(GameManager.MAX_WEAPONS):
		var slot_panel = weapons_grid.get_node_or_null("Slot%d" % i)
		if not slot_panel: continue
		
		var icon_rect = slot_panel.get_node_or_null("Margin/VBox/HeaderHBox/IconRect") as TextureRect
		var name_lbl = slot_panel.get_node_or_null("Margin/VBox/HeaderHBox/InfoVBox/NameLabel") as Label
		var tier_badge = slot_panel.get_node_or_null("Margin/VBox/HeaderHBox/InfoVBox/TierBadge") as Label
		var cat_lbl = slot_panel.get_node_or_null("Margin/VBox/HeaderHBox/InfoVBox/CategoryLabel") as Label
		var stats_lbl = slot_panel.get_node_or_null("Margin/VBox/StatsLabel") as RichTextLabel
		var sell_btn = slot_panel.get_node_or_null("Margin/VBox/BottomHBox/SellButton") as Button
		var unlock_btn = slot_panel.get_node_or_null("Margin/VBox/BottomHBox/UnlockButton") as Button
		
		var sb_slot = slot_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		
		if i < equipped_cnt:
			# Equipped Weapon
			var w = GameManager.equipped_weapons[i]
			var tier = w.get("tier", ItemDatabase.TIER_COMMON)
			var tier_col = ItemDatabase.TIER_COLORS.get(tier, Color.WHITE)
			var tier_name = ItemDatabase.TIER_NAMES.get(tier, "Common")
			var cost = w.get("cost", 20)
			var refund = int(cost * 0.7)
			
			if sb_slot:
				sb_slot.bg_color = Color8(18, 22, 32, 240)
				sb_slot.border_color = tier_col
				sb_slot.set_border_width_all(3)
				slot_panel.add_theme_stylebox_override("panel", sb_slot)
				
			if icon_rect:
				var icon_tex = VisualFactory.get_item_icon(w)
				if not icon_tex:
					var wep_id = w.get("base_weapon_id", w.get("id", "pistol"))
					icon_tex = VisualFactory.get_weapon_texture(wep_id)
				icon_rect.texture = icon_tex
				icon_rect.visible = (icon_tex != null)
				
			if name_lbl:
				name_lbl.text = w.get("name", "Gun")
				name_lbl.modulate = tier_col
				
			if tier_badge:
				tier_badge.text = "[ %s ]" % tier_name.to_upper()
				tier_badge.modulate = tier_col
				
			if cat_lbl:
				var cat = w.get("category", "kinetic").to_upper()
				cat_lbl.text = "TYPE: %s" % cat
				cat_lbl.modulate = Color8(170, 190, 215)
				
			if stats_lbl:
				var base_dmg = w.get("damage", 10.0)
				var eff_dmg = base_dmg * GameManager.damage_mult
				var projs = w.get("projectiles", 1)
				var base_fr = w.get("fire_rate", 2.0)
				var eff_fr = base_fr * GameManager.attack_speed_mult
				var rng = w.get("range", 400.0)
				var spd = w.get("bullet_speed", 600.0)
				var pierce_val = w.get("pierce", 1)
				var crit_c = w.get("crit_chance", 0.05) + GameManager.crit_chance
				var crit_m = w.get("crit_mult", 1.5) * (GameManager.crit_mult / 1.5)
				var spec = w.get("special", "")
				var aoe_rad = w.get("aoe_radius", 0.0)
				
				var st = "[font_size=18]"
				st += "[b]Damage:[/b] %.1f [color=#88ff88](Eff: %.1f)[/color]\n" % [base_dmg, eff_dmg]
				st += "[b]Bullets/Shot:[/b] %d   |   [b]Atk Speed:[/b] %.2f/s\n" % [projs, eff_fr]
				if spd > 0.0:
					st += "[b]Range:[/b] %d   |   [b]Speed:[/b] %d\n" % [int(rng), int(spd)]
				else:
					st += "[b]Range:[/b] %d (Melee/Aura)\n" % int(rng)
				st += "[b]Crit:[/b] %.0f%% (%.1fx)   |   [b]Pierce:[/b] %d\n" % [crit_c * 100.0, crit_m, pierce_val]
				if aoe_rad > 0.0:
					st += "[color=#ff9944][b]AoE Radius:[/b] %d px[/color]\n" % int(aoe_rad)
				if spec != "":
					st += "[color=#44d0ff][b]Special:[/b] %s[/color]\n" % spec.capitalize().replace("_", " ")
				st += "[/font_size]"
				stats_lbl.text = st
				
			if sell_btn:
				sell_btn.visible = true
				sell_btn.text = "SELL (+%d G)" % refund
				_style_button(sell_btn, Color8(255, 85, 65), Color8(50, 18, 15), Color8(255, 150, 135), Color8(85, 30, 25))
				
			if unlock_btn:
				unlock_btn.visible = false
				
		elif i < max_slots:
			# Unlocked but Empty Slot
			if sb_slot:
				sb_slot.bg_color = Color8(14, 16, 22, 200)
				sb_slot.border_color = Color8(55, 65, 85)
				sb_slot.set_border_width_all(2)
				slot_panel.add_theme_stylebox_override("panel", sb_slot)
				
			if icon_rect: icon_rect.visible = false
			if name_lbl:
				name_lbl.text = "SLOT %d" % (i + 1)
				name_lbl.modulate = Color8(160, 175, 195)
			if tier_badge:
				tier_badge.text = "[ EMPTY ]"
				tier_badge.modulate = Color8(100, 120, 145)
			if cat_lbl:
				cat_lbl.text = "OPEN SLOT"
				cat_lbl.modulate = Color8(100, 120, 145)
			if stats_lbl:
				stats_lbl.text = "\n[font_size=19][color=#778899][i]Slot is unlocked and ready.\nBuy a weapon in the Armory to equip it here.[/i][/color][/font_size]"
			if sell_btn:
				sell_btn.visible = false
			if unlock_btn:
				unlock_btn.visible = false
				
		else:
			# Locked Slot
			var slot_cost = 70
			match i:
				3: slot_cost = 70
				4: slot_cost = 140
				5: slot_cost = 210
				
			if sb_slot:
				sb_slot.bg_color = Color8(10, 11, 15, 220)
				sb_slot.border_color = Color8(40, 42, 52)
				sb_slot.set_border_width_all(2)
				slot_panel.add_theme_stylebox_override("panel", sb_slot)
				
			if icon_rect: icon_rect.visible = false
			if name_lbl:
				name_lbl.text = "SLOT %d" % (i + 1)
				name_lbl.modulate = Color8(110, 115, 130)
			if tier_badge:
				tier_badge.text = "[ LOCKED ]"
				tier_badge.modulate = Color8(180, 80, 50)
			if cat_lbl:
				cat_lbl.text = "LOCKED"
				cat_lbl.modulate = Color8(90, 95, 110)
			if stats_lbl:
				stats_lbl.text = "\n[font_size=19][color=#887766]Locked weapon slot.\nAppears in shop as [color=#ffd700]Slot Expansion[/color] card (%d G).[/color][/font_size]" % slot_cost
			if sell_btn:
				sell_btn.visible = false
			if unlock_btn:
				unlock_btn.visible = false

func _on_sell_weapon_clicked(idx: int) -> void:
	GameManager.sell_weapon(idx)
	_update_slot_buttons()
	_update_gold_display()
	_update_my_weapons_display()
