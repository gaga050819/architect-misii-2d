extends Control

@onready var grid_visual = $Content/CenterPanel/GridVisual
@onready var items_container = $Content/LeftPanel/VBox/ScrollItems/VBoxItems
@onready var cat_container = $Content/LeftPanel/VBox/CategoryButtons

@onready var lbl_mass_val = $BottomHUD/HBoxMain/VBoxMass/LblMassVal
@onready var lbl_twr_val = $BottomHUD/HBoxMain/VBoxTWR/LblTWRVal
@onready var lbl_dv_val = $BottomHUD/HBoxMain/VBoxDV/LblDVVal
@onready var lbl_heat_val = $BottomHUD/HBoxMain/VBoxHeat/LblHeatVal
@onready var lbl_status_hint = $BottomHUD/HBoxMain/LblStatusHint
@onready var btn_launch = $BottomHUD/HBoxMain/BtnLaunch

@onready var btn_back = $TopBar/HBox/BtnBack
@onready var btn_clear = $TopBar/HBox/BtnClear
@onready var btn_sample = $TopBar/HBox/BtnSample
@onready var btn_symmetry = $TopBar/HBox/BtnSymmetry

@onready var btn_move_up = $Content/CenterPanel/Toolbar/BtnMoveUp
@onready var btn_move_down = $Content/CenterPanel/Toolbar/BtnMoveDown
@onready var btn_move_left = $Content/CenterPanel/Toolbar/BtnMoveLeft
@onready var btn_move_right = $Content/CenterPanel/Toolbar/BtnMoveRight
@onready var btn_delete = $Content/CenterPanel/Toolbar/BtnDelete

var current_category: String = "payload"
var is_symmetry: bool = false

func _ready() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	btn_clear.pressed.connect(_on_clear_pressed)
	btn_sample.pressed.connect(_on_sample_pressed)
	btn_symmetry.pressed.connect(_on_symmetry_toggled)
	btn_launch.pressed.connect(_on_launch_pressed)

	btn_move_up.pressed.connect(func(): _move_selected(0, 1))
	btn_move_down.pressed.connect(func(): _move_selected(0, -1))
	btn_move_left.pressed.connect(func(): _move_selected(-1, 0))
	btn_move_right.pressed.connect(func(): _move_selected(1, 0))
	btn_delete.pressed.connect(_delete_selected)

	setup_categories()
	populate_items()
	if GameState.custom_rocket_placed_parts.is_empty():
		load_sample_rocket()
	recalculate_physics()
	apply_styling()

func apply_styling() -> void:
	$TopBar.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(12, 1))
	$Content/LeftPanel.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(12, 1))
	$Content/CenterPanel.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(12, 1))
	$BottomHUD.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(14, 1))

func setup_categories() -> void:
	for child in cat_container.get_children():
		child.queue_free()

	for cat in DataManager.custom_categories:
		var c_id = str(cat.get("id", ""))
		var c_name = str(cat.get("name", ""))
		var btn = Button.new()
		btn.text = c_name
		btn.custom_minimum_size = Vector2(0, 32)
		btn.pressed.connect(func():
			SoundManager.play_click()
			current_category = c_id
			update_category_ui()
			populate_items()
		)
		cat_container.add_child(btn)
	update_category_ui()

func update_category_ui() -> void:
	var children = cat_container.get_children()
	for i in range(children.size()):
		var btn = children[i] as Button
		if not btn:
			continue
		var cat = DataManager.custom_categories[i]
		var is_sel = (cat.get("id", "") == current_category)
		var sb = StyleBoxFlat.new()
		sb.set_corner_radius_all(6)
		sb.content_margin_left = 8
		sb.content_margin_right = 8
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		if is_sel:
			sb.bg_color = ThemeManager.accent_emerald * Color(1, 1, 1, 0.25)
			sb.border_color = ThemeManager.accent_emerald
			sb.set_border_width_all(1)
			btn.add_theme_color_override("font_color", ThemeManager.accent_emerald)
		else:
			sb.bg_color = Color(1, 1, 1, 0.05)
			sb.border_color = Color(1, 1, 1, 0.12)
			sb.set_border_width_all(1)
			btn.add_theme_color_override("font_color", ThemeManager.get_text_color())
		btn.add_theme_stylebox_override("normal", sb)

func populate_items() -> void:
	for child in items_container.get_children():
		child.queue_free()

	var parts = DataManager.get_custom_parts_by_category(current_category)
	for p in parts:
		var card = create_part_card(p)
		items_container.add_child(card)

func create_part_card(part: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.14, 0.20, 0.85)
	sb.border_color = Color(0.25, 0.35, 0.48, 0.5)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", sb)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var title = Label.new()
	title.text = str(part.get("name", ""))
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", ThemeManager.get_text_color())
	vbox.add_child(title)

	var specs_text = ""
	var md = float(part.get("mass_dry", 0.0))
	var mf = float(part.get("mass_fuel", 0.0))
	specs_text += "Маса: " + str(md + mf) + " т"
	if mf > 0.0:
		specs_text += " (Паливо: " + str(mf) + " т)"
	if part.has("thrust"):
		specs_text += " | Тяга: " + str(part["thrust"]) + " кН"
	if part.has("isp_sl"):
		specs_text += " | Isp: " + str(part["isp_sl"]) + " c"
	if part.has("max_temp"):
		specs_text += " | Tmax: " + str(part["max_temp"]) + " K"

	var specs = Label.new()
	specs.text = specs_text
	specs.add_theme_font_size_override("font_size", 11)
	specs.add_theme_color_override("font_color", ThemeManager.get_muted_color())
	vbox.add_child(specs)

	var btn_add = Button.new()
	btn_add.text = "+ Додати"
	btn_add.custom_minimum_size = Vector2(85, 32)
	btn_add.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var p_id = str(part.get("id", ""))
	btn_add.pressed.connect(func(): _on_add_part_pressed(p_id))
	hbox.add_child(btn_add)

	return panel

func _on_add_part_pressed(p_id: String) -> void:
	SoundManager.play_click()
	var part = DataManager.get_custom_part(p_id)
	if part.is_empty():
		return

	var highest_y = 0.0
	for item in GameState.custom_rocket_placed_parts:
		var item_part = DataManager.get_custom_part(str(item.get("part_id", "")))
		var gy = float(item.get("gy", 0.0))
		var gh = float(item_part.get("h_grid", 2.0))
		highest_y = max(highest_y, gy + gh)

	var cat = str(part.get("category", ""))
	var new_gx = 0.0
	var new_gy = highest_y

	if cat == "engines":
		new_gy = 0.0
		for item in GameState.custom_rocket_placed_parts:
			item["gy"] += float(part.get("h_grid", 2.0))
	elif part.get("is_booster", false) or part.get("snap_side", false):
		new_gx = 2.5
		new_gy = 0.0

	var new_item = {
		"part_id": p_id,
		"gx": new_gx,
		"gy": new_gy
	}
	GameState.custom_rocket_placed_parts.append(new_item)
	grid_visual.selected_index = GameState.custom_rocket_placed_parts.size() - 1

	if is_symmetry and abs(new_gx) > 0.01:
		var mirror_item = {
			"part_id": p_id,
			"gx": -new_gx,
			"gy": new_gy
		}
		GameState.custom_rocket_placed_parts.append(mirror_item)

	recalculate_physics()

func _move_selected(dx: int, dy: int) -> void:
	var idx = grid_visual.selected_index
	if idx >= 0 and idx < GameState.custom_rocket_placed_parts.size():
		SoundManager.play_click()
		var item = GameState.custom_rocket_placed_parts[idx]
		item["gx"] += float(dx) * 0.5
		item["gy"] = max(0.0, item["gy"] + float(dy) * 0.5)
		recalculate_physics()

func _delete_selected() -> void:
	var idx = grid_visual.selected_index
	if idx >= 0 and idx < GameState.custom_rocket_placed_parts.size():
		SoundManager.play_click()
		GameState.custom_rocket_placed_parts.remove_at(idx)
		grid_visual.selected_index = -1
		recalculate_physics()

func _on_clear_pressed() -> void:
	SoundManager.play_click()
	GameState.custom_rocket_placed_parts.clear()
	grid_visual.selected_index = -1
	recalculate_physics()

func _on_symmetry_toggled() -> void:
	SoundManager.play_click()
	is_symmetry = not is_symmetry
	btn_symmetry.text = "Симетрія: 2x" if is_symmetry else "Симетрія: 1x"
	btn_symmetry.modulate = ThemeManager.accent_emerald if is_symmetry else Color.WHITE

func _on_back_pressed() -> void:
	SoundManager.play_click()
	GameState.is_custom_rocket = false
	GameState.set_phase("assembly")

func _on_launch_pressed() -> void:
	var stats = Calc.calculate_custom_rocket(GameState.custom_rocket_placed_parts)
	if not stats["can_lift_off"]:
		SoundManager.play_warning()
		lbl_status_hint.text = "Увага! Ракета не може злетіти (TWR < 1.05 або немає двигуна / зонда)!"
		lbl_status_hint.modulate = ThemeManager.accent_red
		return

	SoundManager.play_click()
	GameState.is_custom_rocket = true
	GameState.custom_rocket_stats = stats
	GameState.set_phase("launch")

func recalculate_physics() -> void:
	var stats = Calc.calculate_custom_rocket(GameState.custom_rocket_placed_parts)
	GameState.custom_rocket_stats = stats

	lbl_mass_val.text = str(snapped(stats["mass_total_t"], 0.1)) + " т (Суха: " + str(snapped(stats["mass_dry_t"], 0.1)) + " т)"

	var twr = stats["twr"]
	lbl_twr_val.text = str(snapped(twr, 0.01))
	if twr >= 1.2:
		lbl_twr_val.modulate = ThemeManager.accent_emerald
	elif twr >= 1.05:
		lbl_twr_val.modulate = ThemeManager.accent_amber
	else:
		lbl_twr_val.modulate = ThemeManager.accent_red

	var dv = stats["delta_v"]
	lbl_dv_val.text = str(int(dv)) + " м/с"
	if dv >= 9200.0:
		lbl_dv_val.modulate = ThemeManager.accent_emerald
	elif dv >= 7800.0:
		lbl_dv_val.modulate = ThemeManager.accent_cyan
	else:
		lbl_dv_val.modulate = ThemeManager.accent_amber

	if stats["has_heat_shield"]:
		lbl_heat_val.text = "Є (" + str(int(stats["max_temp_k"])) + " K)"
		lbl_heat_val.modulate = ThemeManager.accent_emerald
	else:
		lbl_heat_val.text = "Відсутній ⚠️"
		lbl_heat_val.modulate = ThemeManager.accent_red

	if not stats["has_control"]:
		lbl_status_hint.text = "Потрібно встановити Командний модуль або Капсулу!"
		lbl_status_hint.modulate = ThemeManager.accent_red
		btn_launch.disabled = true
	elif stats["thrust_kn"] <= 0.0 or twr < 1.05:
		lbl_status_hint.text = "Тяга недостатня для відриву від Землі! (TWR < 1.05)"
		lbl_status_hint.modulate = ThemeManager.accent_red
		btn_launch.disabled = true
	elif dv < 7800.0:
		lbl_status_hint.text = "Запасу dV недостатньо для замкненої орбіти (потрібно >= 7800 м/с). Суборбітальний політ."
		lbl_status_hint.modulate = ThemeManager.accent_amber
		btn_launch.disabled = false
	else:
		lbl_status_hint.text = "Ракета готова до старту та виходу на орбіту! dV = " + str(int(dv)) + " м/с."
		lbl_status_hint.modulate = ThemeManager.accent_emerald
		btn_launch.disabled = false

func _on_sample_pressed() -> void:
	SoundManager.play_click()
	load_sample_rocket()
	recalculate_physics()

func load_sample_rocket() -> void:
	GameState.custom_rocket_placed_parts.clear()
	GameState.custom_rocket_placed_parts = [
		{"part_id": "engine_merlin", "gx": 0.0, "gy": 0.0},
		{"part_id": "tank_large_25", "gx": 0.0, "gy": 2.0},
		{"part_id": "decoupler_vertical", "gx": 0.0, "gy": 9.0},
		{"part_id": "engine_vacuum", "gx": 0.0, "gy": 10.0},
		{"part_id": "tank_med_25", "gx": 0.0, "gy": 12.0},
		{"part_id": "heat_shield_25", "gx": 0.0, "gy": 16.0},
		{"part_id": "capsule_crew", "gx": 0.0, "gy": 17.0},
		{"part_id": "parachute", "gx": 0.0, "gy": 20.0},
		{"part_id": "stabilizer_fin", "gx": -1.8, "gy": 0.0},
		{"part_id": "stabilizer_fin", "gx": 1.8, "gy": 0.0}
	]
	grid_visual.selected_index = -1