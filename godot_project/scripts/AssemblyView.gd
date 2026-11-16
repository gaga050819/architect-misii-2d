extends Control

@onready var left_panel = $VBox/Content/LeftPanel
@onready var center_panel = $VBox/Content/CenterPanel
@onready var bottom_hud = $VBox/BottomHUD

@onready var cat_buttons = [
	$VBox/Content/LeftPanel/VBox/CategoryButtons/BtnCat0,
	$VBox/Content/LeftPanel/VBox/CategoryButtons/BtnCat1,
	$VBox/Content/LeftPanel/VBox/CategoryButtons/BtnCat2,
	$VBox/Content/LeftPanel/VBox/CategoryButtons/BtnCat3,
	$VBox/Content/LeftPanel/VBox/CategoryButtons/BtnCat4
]

@onready var slot_counter_box = $VBox/Content/LeftPanel/VBox/HBoxSlotCounter
@onready var lbl_slot_info = $VBox/Content/LeftPanel/VBox/HBoxSlotCounter/LblSlotInfo
@onready var icon_hint_lock = $VBox/Content/LeftPanel/VBox/HBoxSlotCounter/IconHintLock
@onready var lbl_lock_hint = $VBox/Content/LeftPanel/VBox/HBoxSlotCounter/LblLockHint
@onready var items_scroll = $VBox/Content/LeftPanel/VBox/ScrollItems/VBoxItems
@onready var blueprint_grid = $VBox/Content/CenterPanel/BlueprintArea/BlueprintGridVisual
@onready var probe_visual = $VBox/Content/CenterPanel/BlueprintArea/ProbeAnchor/ProbeVisual
@onready var center_header = $VBox/Content/CenterPanel/BlueprintArea/CenterHeader

@onready var bar_mass = $VBox/BottomHUD/HBoxMain/HBoxBars/VBoxMass/BarMass
@onready var lbl_mass = $VBox/BottomHUD/HBoxMain/HBoxBars/VBoxMass/LabelMass
@onready var bar_budget = $VBox/BottomHUD/HBoxMain/HBoxBars/VBoxBudget/BarBudget
@onready var lbl_budget = $VBox/BottomHUD/HBoxMain/HBoxBars/VBoxBudget/LabelBudget
@onready var bar_power = $VBox/BottomHUD/HBoxMain/HBoxBars/VBoxPower/BarPower
@onready var lbl_power = $VBox/BottomHUD/HBoxMain/HBoxBars/VBoxPower/LabelPower
@onready var lbl_science = $VBox/BottomHUD/HBoxMain/VBoxScience/LabelScienceVal
@onready var btn_launch = $VBox/BottomHUD/HBoxMain/BtnLaunch

var icon_lock = preload("res://assets/icons/icon_lock.svg")
var icon_warning = preload("res://assets/icons/icon_warning.svg")
var icon_check = preload("res://assets/icons/icon_check.svg")

var current_category: int = 0
var tween_mass: Tween
var tween_budget: Tween
var tween_power: Tween

func _ready() -> void:
	for i in range(cat_buttons.size()):
		var idx = i
		cat_buttons[i].pressed.connect(func(): _on_category_changed(idx))

	btn_launch.pressed.connect(_on_launch_pressed)
	GameState.state_changed.connect(update_ui)
	ThemeManager.theme_changed.connect(_on_theme_changed)
	get_tree().root.size_changed.connect(_on_viewport_resized)

	_on_viewport_resized()
	apply_liquid_glass_styles()
	update_category_buttons()
	populate_items()
	update_ui()

func _on_theme_changed(_v: float) -> void:
	apply_liquid_glass_styles()
	update_category_buttons()
	populate_items()
	update_ui()

func apply_liquid_glass_styles() -> void:
	var glass_panel = ThemeManager.create_glass_style(16, 1)
	left_panel.add_theme_stylebox_override("panel", glass_panel)
	center_panel.add_theme_stylebox_override("panel", glass_panel)
	bottom_hud.add_theme_stylebox_override("panel", glass_panel)

	var text_col = ThemeManager.get_text_color()
	var muted_col = ThemeManager.get_muted_color()

	center_header.add_theme_color_override("font_color", muted_col)
	lbl_slot_info.add_theme_color_override("font_color", text_col)
	lbl_lock_hint.add_theme_color_override("font_color", ThemeManager.accent_amber)

func update_category_buttons() -> void:
	var is_light = ThemeManager.theme_value > 0.5
	var text_col = ThemeManager.get_text_color()

	for i in range(cat_buttons.size()):
		var btn = cat_buttons[i]
		var is_sel = (i == current_category)
		var sb = StyleBoxFlat.new()
		sb.set_corner_radius_all(8)
		sb.content_margin_left = 6
		sb.content_margin_right = 6
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4

		if is_sel:
			sb.bg_color = ThemeManager.accent_emerald * Color(1, 1, 1, 0.22)
			sb.border_color = ThemeManager.accent_emerald
			sb.set_border_width_all(1)
			btn.add_theme_color_override("font_color", ThemeManager.accent_emerald)
		else:
			sb.bg_color = Color(1, 1, 1, 0.05) if not is_light else Color(0.68, 0.76, 0.88, 0.35)
			sb.border_color = Color(1, 1, 1, 0.1) if not is_light else Color(0.28, 0.40, 0.60, 0.50)
			sb.set_border_width_all(1)
			btn.add_theme_color_override("font_color", text_col)

		btn.add_theme_stylebox_override("normal", sb)

func _on_category_changed(tab: int) -> void:
	SoundManager.play_click()
	current_category = tab
	update_category_buttons()
	populate_items()
	update_ui()

func populate_items() -> void:
	for child in items_scroll.get_children():
		child.queue_free()

	var list: Array = []
	match current_category:
		0:
			list = DataManager.rockets
			lbl_slot_info.text = "Виберіть ракету-носій місії:"
			icon_hint_lock.visible = false
			lbl_lock_hint.visible = false
		1:
			list = DataManager.platforms
			lbl_slot_info.text = "Виберіть платформу апарата:"
			icon_hint_lock.visible = false
			lbl_lock_hint.visible = false
		2:
			list = DataManager.power_sources
			lbl_slot_info.text = "Виберіть систему живлення:"
			icon_hint_lock.visible = false
			lbl_lock_hint.visible = false
		3:
			list = DataManager.antennas
			lbl_slot_info.text = "Виберіть антену зв'язку з DSN:"
			icon_hint_lock.visible = false
			lbl_lock_hint.visible = false
		4:
			list = DataManager.instruments
			var platform = DataManager.get_platform(GameState.platform_id)
			var max_slots = int(platform.get("slots", 3))
			var used_slots = GameState.selected_instruments.size()
			lbl_slot_info.text = "Слоти обладнання: %d / %d" % [used_slots, max_slots]
			icon_hint_lock.visible = true
			lbl_lock_hint.visible = true

	for item in list:
		var card = create_item_card(item, current_category)
		items_scroll.add_child(card)

func check_lock_status(item: Dictionary, category: int) -> Dictionary:
	var target = DataManager.get_target(GameState.target_id)
	var platform = DataManager.get_platform(GameState.platform_id)
	var plat_type = str(platform.get("type", "rover"))
	var item_id = str(item.get("id", ""))

	if category == 4:
		var allowed_plats = item.get("platforms", [])
		if not allowed_plats.is_empty() and not allowed_plats.has(plat_type):
			var req_name = "Орбітер" if allowed_plats.has("orbiter") else "Ровер / Ландер"
			return {"locked": true, "is_warning": false, "reason": "Лише для: " + req_name}

		var max_slots = int(platform.get("slots", 3))
		var is_sel = GameState.selected_instruments.has(item_id)
		if not is_sel and GameState.selected_instruments.size() >= max_slots:
			return {"locked": true, "is_warning": false, "reason": "Слоти заповнено (%d/%d)" % [max_slots, max_slots]}

	elif category == 3:
		if item.get("relay", false) and not target.get("has_relay", false):
			return {"locked": true, "is_warning": false, "reason": "Ціль не має ретранслятора"}

	elif category == 1:
		var allowed = target.get("allowed_platform_types", [])
		var this_type = str(item.get("type", "rover"))
		if not allowed.is_empty() and not allowed.has(this_type):
			return {"locked": true, "is_warning": false, "reason": "Неможливо для даної цілі"}

	elif category == 0:
		var m_class = DataManager.get_mission_class(GameState.class_id)
		var budget = float(m_class.get("budget_musd", 1150.0))
		var cost = float(item.get("cost_musd", 90.0))
		if cost > budget * 0.45:
			return {"locked": false, "is_warning": true, "reason": "Важка ракета: висока ціна"}

	return {"locked": false, "is_warning": false, "reason": ""}

func create_item_card(item: Dictionary, category: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 90)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var item_id = item.get("id", "")
	var is_selected = is_item_selected(item_id, category)
	var lock_info = check_lock_status(item, category)
	var is_locked = lock_info["locked"]
	var is_warning = lock_info["is_warning"]

	panel.add_theme_stylebox_override("panel", ThemeManager.create_card_style(is_selected, is_locked))

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	var icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(56, 56)
	icon_rect.expand_mode = 1
	icon_rect.stretch_mode = 5
	var tex = DataManager.get_image_texture(item_id)
	if tex:
		icon_rect.texture = tex
	if is_locked:
		icon_rect.modulate = Color(0.6, 0.6, 0.6, 0.5)
	hbox.add_child(icon_rect)

	var vbox_info = VBoxContainer.new()
	vbox_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_info.add_theme_constant_override("separation", 3)

	var lbl_title = Label.new()
	lbl_title.text = DataManager.get_localized(item.get("name"), item_id)
	lbl_title.add_theme_font_size_override("font_size", 14)
	lbl_title.add_theme_color_override("font_color", ThemeManager.get_text_color())
	vbox_info.add_child(lbl_title)

	var stat_lines = build_stat_lines(item, category)
	for stat_line in stat_lines:
		var hbox_stat = HBoxContainer.new()
		hbox_stat.add_theme_constant_override("separation", 10)
		for chip in stat_line:
			var lbl_chip = Label.new()
			lbl_chip.text = chip["text"]
			lbl_chip.add_theme_font_size_override("font_size", 11)
			lbl_chip.add_theme_color_override("font_color", chip["color"])
			lbl_chip.clip_text = false
			hbox_stat.add_child(lbl_chip)
		vbox_info.add_child(hbox_stat)

	if lock_info["reason"] != "":
		var hbox_reason = HBoxContainer.new()
		hbox_reason.add_theme_constant_override("separation", 5)

		var reason_icon = TextureRect.new()
		reason_icon.custom_minimum_size = Vector2(14, 14)
		reason_icon.expand_mode = 1
		reason_icon.stretch_mode = 5
		if is_locked:
			reason_icon.texture = icon_lock
		elif is_warning:
			reason_icon.texture = icon_warning
		hbox_reason.add_child(reason_icon)

		var lbl_reason = Label.new()
		lbl_reason.text = lock_info["reason"]
		lbl_reason.add_theme_font_size_override("font_size", 11)
		var reason_color = ThemeManager.accent_amber if is_locked else ThemeManager.accent_cyan
		lbl_reason.add_theme_color_override("font_color", reason_color)
		hbox_reason.add_child(lbl_reason)

		vbox_info.add_child(hbox_reason)

	hbox.add_child(vbox_info)

	var btn_select = Button.new()
	btn_select.custom_minimum_size = Vector2(100, 36)
	btn_select.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	if is_selected:
		btn_select.text = "Обрано"
		btn_select.icon = icon_check
		btn_select.expand_icon = true
		btn_select.modulate = ThemeManager.accent_emerald
	elif is_locked:
		btn_select.text = "Замок"
		btn_select.icon = icon_lock
		btn_select.expand_icon = true
		btn_select.disabled = true
		btn_select.modulate = Color(0.65, 0.65, 0.65, 0.6)
	else:
		btn_select.text = "Вибрати"
		btn_select.modulate = ThemeManager.accent_cyan

	btn_select.pressed.connect(func():
		SoundManager.play_click()
		select_item(item_id, category)
		populate_items()
		update_ui()
	)
	hbox.add_child(btn_select)

	panel.mouse_entered.connect(func():
		if not is_locked:
			panel.modulate = Color(1.1, 1.1, 1.1)
	)
	panel.mouse_exited.connect(func():
		if not is_locked:
			panel.modulate = Color(1.0, 1.0, 1.0)
	)

	return panel

func fmt_reliability(r: float) -> String:
	return "%.0f%%" % (r * 100.0)

func fmt_data_rate(mbps: float) -> String:
	if mbps >= 1.0:
		return "%.1f Мбіт/с" % mbps
	elif mbps >= 0.001:
		return "%.0f кбіт/с" % (mbps * 1000.0)
	else:
		return "%.0f біт/с" % (mbps * 1000000.0)

func science_stars(base: float) -> String:
	return "[%d/5]" % int(base)

func build_stat_lines(item: Dictionary, category: int) -> Array:
	var muted = ThemeManager.get_muted_color()
	var cyan = ThemeManager.get_accent_cyan()
	var amber = ThemeManager.get_accent_amber()
	var emerald = ThemeManager.get_accent_emerald()
	var red_col = ThemeManager.get_accent_red()
	var text_col = ThemeManager.get_text_color()

	var lines: Array = []
	var row1: Array = []
	var row2: Array = []

	if item.has("mass_kg"):
		row1.append({"text": "%.1f кг" % float(item.get("mass_kg")), "color": muted})
	if item.has("cost_musd"):
		row1.append({"text": "%d млн $" % int(item.get("cost_musd")), "color": muted})

	match category:
		0:
			if item.has("leo_kg"):
				row1.append({"text": "LEO: %d т" % int(float(item.get("leo_kg")) / 1000.0), "color": cyan})
			var flights = int(item.get("flights", 0))
			var successes = int(item.get("successes", 0))
			if flights > 0:
				var rel_pct = int(float(successes) / float(flights) * 100.0)
				var rel_col = emerald if rel_pct >= 97 else (amber if rel_pct >= 90 else red_col)
				row2.append({"text": "%d/%d польотів — надійн. %d%%" % [successes, flights, rel_pct], "color": rel_col})

		1:
			if item.has("bus_power_w"):
				row1.append({"text": "Шина: %d Вт" % int(item.get("bus_power_w")), "color": amber})
			if item.has("slots"):
				row1.append({"text": "%d слотів" % int(item.get("slots")), "color": cyan})
			if item.has("reliability"):
				var rel = float(item.get("reliability"))
				var rel_col = emerald if rel >= 0.97 else (amber if rel >= 0.94 else red_col)
				row2.append({"text": "Надійн. %s" % fmt_reliability(rel), "color": rel_col})
			if item.has("ops_musd_per_step"):
				row2.append({"text": "Ops: %d млн$/крок" % int(item.get("ops_musd_per_step")), "color": muted})

		2:
			var target = DataManager.get_target(GameState.target_id)
			var platform = DataManager.get_platform(GameState.platform_id)
			var is_surf = str(platform.get("type", "rover")) != "orbiter"
			var p_loc = int(Calc.get_power_generated(item, target, is_surf))
			if item.has("p1au_w"):
				row1.append({"text": "%d Вт @1AU -> %d Вт тут" % [int(item.get("p1au_w")), p_loc], "color": amber})
			elif item.has("p0_w"):
				row1.append({"text": "%d Вт (РІТЕГ, постійно)" % [int(item.get("p0_w"))], "color": amber})
			if item.has("reliability"):
				var rel = float(item.get("reliability"))
				var rel_col = emerald if rel >= 0.97 else (amber if rel >= 0.94 else red_col)
				row2.append({"text": "Надійн. %s" % fmt_reliability(rel), "color": rel_col})
			var ptype = str(item.get("type", ""))
			if ptype == "rtg":
				row2.append({"text": "-4%/рік", "color": muted})
			elif ptype == "solar":
				row2.append({"text": "Сонячний потік", "color": muted})

		3:
			var target = DataManager.get_target(GameState.target_id)
			var dist_au = Calc.earth_distance_au(target)
			if item.has("rate_1au_mbps"):
				var rate = float(item.get("rate_1au_mbps"))
				var rate_eff = Calc.data_rate_effective(rate, dist_au)
				row1.append({"text": "Шв.: %s @цілі" % fmt_data_rate(rate_eff), "color": cyan})
				var ch = float(item.get("contact_h", 4.0))
				var d_cap = int(rate_eff * ch * 3600.0)
				row1.append({"text": "%d Мбіт/добу" % d_cap, "color": muted})
			elif item.has("relay_mbit_per_day"):
				if target.get("has_relay", false):
					row1.append({"text": "Реле: %d Мбіт/добу (MRO)" % int(item.get("relay_mbit_per_day")), "color": cyan})
				else:
					row1.append({"text": "Реле: 0 Мбіт/добу (немає реле)", "color": red_col})
			if item.has("contact_h"):
				row2.append({"text": "%d год/добу" % int(item.get("contact_h")), "color": muted})
			if item.has("reliability"):
				var rel = float(item.get("reliability"))
				var rel_col = emerald if rel >= 0.97 else (amber if rel >= 0.94 else red_col)
				row2.append({"text": "Надійн. %s" % fmt_reliability(rel), "color": rel_col})

		4:
			if item.has("power_w"):
				var duty = float(item.get("duty", 0.5))
				var pw = float(item.get("power_w"))
				row1.append({"text": "%g Вт (%.0f%% цикл)" % [pw, duty * 100.0], "color": amber})
			if item.has("science_base"):
				var sb = float(item.get("science_base"))
				row2.append({"text": "Наука: %s" % science_stars(sb), "color": Color(1.0, 0.85, 0.2)})
			if item.has("data_mbit_per_day"):
				var dmb = int(item.get("data_mbit_per_day"))
				row2.append({"text": "Дані: %d Мбіт/добу" % dmb, "color": cyan})
			if item.has("reliability"):
				var rel = float(item.get("reliability"))
				var rel_col = emerald if rel >= 0.97 else (amber if rel >= 0.94 else red_col)
				row2.append({"text": "Надійн. %s" % fmt_reliability(rel), "color": rel_col})
			if item.has("weights"):
				var w = item.get("weights") as Dictionary
				var sorted_keys: Array = w.keys()
				sorted_keys.sort_custom(func(a, b): return float(w[a]) > float(w[b]))
				var focus_parts: Array = []
				for k in sorted_keys.slice(0, 2):
					var val = float(w[k])
					if val >= 1.5:
						var label_map = {
							"water": "Вода", "map": "Карта",
							"interior": "Надра", "atmosphere": "Атм.", "life": "Життя"
						}
						focus_parts.append("%s x%.0f" % [label_map.get(k, k), val])
				if not focus_parts.is_empty():
					var focus_lbl = Label.new()
					var focus_row: Array = []
					for fp in focus_parts:
						focus_row.append({"text": fp, "color": text_col * Color(1,1,1,0.6)})
					lines.append(focus_row)

	if not row1.is_empty():
		lines.insert(0, row1)
	if not row2.is_empty():
		lines.append(row2)
	return lines

func is_item_selected(item_id: String, category: int) -> bool:
	match category:
		0:
			return GameState.rocket_id == item_id
		1:
			return GameState.platform_id == item_id
		2:
			return GameState.power_id == item_id
		3:
			return GameState.antenna_id == item_id
		4:
			return GameState.selected_instruments.has(item_id)
	return false

func select_item(item_id: String, category: int) -> void:
	match category:
		0:
			GameState.rocket_id = item_id
		1:
			GameState.platform_id = item_id
			filter_incompatible_instruments()
		2:
			GameState.power_id = item_id
		3:
			GameState.antenna_id = item_id
		4:
			GameState.toggle_instrument(item_id)
	GameState.state_changed.emit()

func filter_incompatible_instruments() -> void:
	var platform = DataManager.get_platform(GameState.platform_id)
	var plat_type = str(platform.get("type", "rover"))
	var to_remove = []
	for inst_id in GameState.selected_instruments:
		var inst = DataManager.get_instrument(inst_id)
		var allowed = inst.get("platforms", [])
		if not allowed.is_empty() and not allowed.has(plat_type):
			to_remove.append(inst_id)
	for id in to_remove:
		GameState.selected_instruments.erase(id)

func update_ui() -> void:
	var stats = GameState.get_current_stats()

	var launch_m = stats.get("launch_mass_kg", 0.0)
	var cap_m = stats.get("capacity_kg", 1.0)
	var mass_ok = stats.get("mass_ok", false)
	bar_mass.max_value = max(1.0, cap_m)
	if tween_mass:
		tween_mass.kill()
	tween_mass = create_tween()
	tween_mass.tween_property(bar_mass, "value", min(launch_m, cap_m), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	bar_mass.modulate = ThemeManager.accent_emerald if mass_ok else ThemeManager.accent_red
	var mass_pct = int((launch_m / max(1.0, cap_m)) * 100.0)
	lbl_mass.text = "%d / %d кг (%d%%)" % [int(launch_m), int(cap_m), mass_pct]

	var cost = stats.get("total_cost_musd", 0.0)
	var budget = stats.get("budget_limit_musd", 1.0)
	var budget_ok = stats.get("budget_ok", false)
	bar_budget.max_value = max(1.0, budget)
	if tween_budget:
		tween_budget.kill()
	tween_budget = create_tween()
	tween_budget.tween_property(bar_budget, "value", min(cost, budget), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	bar_budget.modulate = ThemeManager.accent_emerald if budget_ok else ThemeManager.accent_red
	var budget_pct = int((cost / max(1.0, budget)) * 100.0)
	lbl_budget.text = "%d / %d млн $ (%d%%)" % [int(cost), int(budget), budget_pct]

	var p_gen = stats.get("power_generated_w", 0.0)
	var p_bus = stats.get("power_bus_w", 0.0)
	var p_inst = stats.get("power_instruments_w", 0.0)
	var p_cons = stats.get("power_consumed_w", 1.0)
	var power_ok = stats.get("power_ok", false)
	bar_power.max_value = max(1.0, max(p_gen, p_cons))
	if tween_power:
		tween_power.kill()
	tween_power = create_tween()
	tween_power.tween_property(bar_power, "value", min(p_gen, max(p_gen, p_cons)), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	bar_power.modulate = ThemeManager.accent_emerald if power_ok else ThemeManager.accent_red
	var power_pct = int((p_gen / max(1.0, p_cons)) * 100.0)
	lbl_power.text = "%d Вт вир. / %d спож. [шина %d + пр. %d] (%d%%)" % [int(p_gen), int(p_cons), int(p_bus), int(p_inst), power_pct]

	var eff_rate = stats.get("data_rate_effective_mbps", 0.0)
	var data_per_day = stats.get("data_per_day_mbit", 0.0)
	var inst_demand = stats.get("data_instruments_mbit_per_day", 0.0)
	var contact_h = stats.get("data_contact_h", 4.0)
	var bottleneck = stats.get("data_bottleneck_pct", 1.0)
	var data_ok = bottleneck >= 0.95 or inst_demand == 0.0

	var science_val = stats.get("potential_science", 0.0)
	var rel = stats.get("reliability", 0.0)
	var rel_pct = int(rel * 100.0)

	var science_text = "Наука: %.0f  Надійн.: %d%%\nЗв'язок: %s  Канал: %d / %d Мбіт/добу" % [
		science_val,
		rel_pct,
		_fmt_mbps(eff_rate),
		int(min(data_per_day, inst_demand)),
		int(inst_demand)
	]
	if not data_ok:
		science_text += " [ВУЗЬКЕ МІСЦЕ!]"
	lbl_science.text = science_text
	var science_color = ThemeManager.get_accent_emerald() if data_ok else ThemeManager.get_accent_amber()
	lbl_science.add_theme_color_override("font_color", science_color)

	var can_launch = stats.get("is_valid_launch", false)
	btn_launch.disabled = not can_launch
	if can_launch:
		btn_launch.modulate = ThemeManager.accent_emerald
	else:
		btn_launch.modulate = Color(0.6, 0.6, 0.6, 0.7)

func _fmt_mbps(mbps: float) -> String:
	if mbps >= 1.0:
		return "%.2f Мбіт/с" % mbps
	elif mbps >= 0.001:
		return "%.1f кбіт/с" % (mbps * 1000.0)
	else:
		return "%.0f біт/с" % (mbps * 1000000.0)

func _on_launch_pressed() -> void:
	SoundManager.play_success()
	GameState.set_phase("launch")

func _on_viewport_resized() -> void:
	var vp_w = get_viewport_rect().size.x
	if vp_w < 1050.0:
		left_panel.custom_minimum_size.x = max(380.0, vp_w * 0.48)
	else:
		left_panel.custom_minimum_size.x = 520.0
