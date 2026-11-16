extends Control

@onready var targets_container = $VBox/Content/LeftPanel/VBox/ScrollTargets/VBoxTargets
@onready var target_title = $VBox/Content/CenterPanel/VBox/TargetTitle
@onready var target_desc = $VBox/Content/CenterPanel/VBox/TargetDesc
@onready var target_specs = $VBox/Content/CenterPanel/VBox/TargetSpecs
@onready var target_image = $VBox/Content/CenterPanel/VBox/TargetImage
@onready var class_option = $VBox/Content/RightPanel/VBox/ClassOption
@onready var goal_option = $VBox/Content/RightPanel/VBox/GoalOption
@onready var btn_next = $VBox/Content/RightPanel/VBox/BtnNext

func _ready() -> void:
	populate_targets()
	populate_classes()
	populate_goals()
	update_target_display()
	apply_colors()
	btn_next.pressed.connect(_on_next_pressed)
	class_option.item_selected.connect(_on_class_selected)
	goal_option.item_selected.connect(_on_goal_selected)
	ThemeManager.theme_changed.connect(func(_v): apply_colors())

func apply_colors() -> void:
	var text_col = ThemeManager.get_text_color()
	var muted = ThemeManager.get_muted_color()
	var cyan = ThemeManager.get_accent_cyan()

	$VBox/Header.add_theme_color_override("font_color", text_col)
	$VBox/Content/LeftPanel/VBox/LblTitle.add_theme_color_override("font_color", text_col)
	$VBox/Content/RightPanel/VBox/LblClass.add_theme_color_override("font_color", text_col)
	$VBox/Content/RightPanel/VBox/LblGoal.add_theme_color_override("font_color", text_col)

	target_title.add_theme_color_override("font_color", text_col)
	target_desc.add_theme_color_override("font_color", muted)
	target_specs.add_theme_color_override("font_color", cyan)

	var left_panel = $VBox/Content/LeftPanel
	var center_panel = $VBox/Content/CenterPanel
	var right_panel = $VBox/Content/RightPanel
	left_panel.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(14, 1))
	center_panel.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(14, 1))
	right_panel.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(14, 1))

	var is_light = ThemeManager.theme_value > 0.5
	for btn in targets_container.get_children():
		if btn is Button:
			var is_sel = (GameState.target_id == _get_btn_target_id(btn))
			var sb = StyleBoxFlat.new()
			sb.set_corner_radius_all(8)
			sb.content_margin_left = 12
			sb.content_margin_right = 12
			sb.content_margin_top = 8
			sb.content_margin_bottom = 8
			if is_sel:
				sb.bg_color = ThemeManager.get_accent_emerald() * Color(1, 1, 1, 0.22)
				sb.border_color = ThemeManager.get_accent_emerald()
				sb.set_border_width_all(1)
				btn.add_theme_color_override("font_color", ThemeManager.get_accent_emerald())
			else:
				sb.bg_color = Color(0, 0, 0, 0.05) if is_light else Color(1, 1, 1, 0.05)
				sb.border_color = Color(0, 0, 0, 0.18) if is_light else Color(1, 1, 1, 0.1)
				sb.set_border_width_all(1)
				btn.add_theme_color_override("font_color", text_col)
			btn.add_theme_stylebox_override("normal", sb)

func _get_btn_target_id(btn: Button) -> String:
	for target in DataManager.targets:
		var t_name = DataManager.get_localized(target.get("name"), target.get("id"))
		if btn.text == t_name:
			return str(target.get("id", ""))
	return ""

func populate_targets() -> void:
	for child in targets_container.get_children():
		child.queue_free()
	for target in DataManager.targets:
		var btn = Button.new()
		var t_name = DataManager.get_localized(target.get("name"), target.get("id"))
		btn.text = t_name
		btn.custom_minimum_size = Vector2(180, 42)
		var t_id = target.get("id")
		btn.pressed.connect(func():
			SoundManager.play_click()
			GameState.target_id = t_id
			if t_id == "interstellar":
				GameState.class_id = "flagship"
				GameState.rocket_id = "titan_iiie"
				GameState.platform_id = "voyager_bus"
				GameState.power_id = "rtg_3"
				GameState.antenna_id = "hga_large"
				GameState.selected_instruments = ["cam_hires", "magnetometer", "ir_spectrometer", "mass_spectrometer", "lidar"]
				for ci in range(DataManager.mission_classes.size()):
					if DataManager.mission_classes[ci].get("id") == "flagship":
						class_option.select(ci)
			GameState.state_changed.emit()
			update_target_display()
			apply_colors()
		)
		targets_container.add_child(btn)

func populate_classes() -> void:
	class_option.clear()
	for i in range(DataManager.mission_classes.size()):
		var c = DataManager.mission_classes[i]
		var c_name = DataManager.get_localized(c.get("name"), c.get("id"))
		var c_budget = str(c.get("budget_musd", 0)) + " млн $"
		class_option.add_item(c_name + " (" + c_budget + ")", i)
		if c.get("id") == GameState.class_id:
			class_option.select(i)

func populate_goals() -> void:
	goal_option.clear()
	for i in range(DataManager.mission_goals.size()):
		var g = DataManager.mission_goals[i]
		var g_name = DataManager.get_localized(g.get("name"), g.get("id"))
		goal_option.add_item(g_name, i)
		if g.get("id") == GameState.goal_id:
			goal_option.select(i)

func update_target_display() -> void:
	var target = DataManager.get_target(GameState.target_id)
	var t_name = DataManager.get_localized(target.get("name"), GameState.target_id)
	var t_sum = DataManager.get_localized(target.get("summary"), "")
	target_title.text = t_name
	target_desc.text = t_sum

	var sun_au = target.get("sun_au", 1.0)
	var flight_d = target.get("flight_days", 200)
	var landing_dict = target.get("landing", {})
	var landing_type = landing_dict.get("type", "орбіта")
	var spec_text = "Відстань від Сонця: %s а.о.\n" % [str(sun_au)]
	spec_text += "Тривалість перельоту: ~%s діб\n" % [str(flight_d)]
	spec_text += "Тип посадки: %s\n" % [str(landing_type)]
	if GameState.target_id == "interstellar":
		spec_text += "\n[АВТОПРЕСЕТ: Ракета Titan IIIE, Voyager Bus, 3x РІТЕГ, HGA, прилади MAG/CRS/IRIS]"
	target_specs.text = spec_text

	var tex = DataManager.get_image_texture(GameState.target_id)
	if not tex:
		tex = DataManager.get_image_texture("map_" + GameState.target_id)
	if tex:
		target_image.texture = tex

func _on_class_selected(index: int) -> void:
	SoundManager.play_click()
	if index >= 0 and index < DataManager.mission_classes.size():
		GameState.class_id = DataManager.mission_classes[index].get("id", "discovery")
		GameState.state_changed.emit()

func _on_goal_selected(index: int) -> void:
	SoundManager.play_click()
	if index >= 0 and index < DataManager.mission_goals.size():
		GameState.goal_id = DataManager.mission_goals[index].get("id", "geology")
		GameState.state_changed.emit()

func _on_next_pressed() -> void:
	SoundManager.play_success()
	GameState.set_phase("assembly")
