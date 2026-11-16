extends Control

@onready var bg = $Background
@onready var top_bar = $TopBar
@onready var phase_buttons_container = $TopBar/HBox/HBoxPhaseButtons
@onready var view_container = $ViewContainer
@onready var theme_slider = $TopBar/HBox/ThemeBox/ThemeSlider

var views = {}
var current_view_node: Control = null

func _ready() -> void:
	register_views()
	var phase_names = ["briefing", "assembly", "launch", "cruise", "landing", "surface", "debrief"]
	for i in range(phase_buttons_container.get_child_count()):
		var btn = phase_buttons_container.get_child(i) as Button
		if btn and i < phase_names.size():
			var p_name = phase_names[i]
			btn.pressed.connect(func(): _on_nav_button_pressed(p_name))

	theme_slider.value = ThemeManager.theme_value
	theme_slider.value_changed.connect(_on_theme_slider_changed)
	ThemeManager.theme_changed.connect(_on_theme_updated)

	GameState.phase_changed.connect(_on_phase_changed)
	GameState.state_changed.connect(_on_state_changed)
	get_tree().root.size_changed.connect(_on_viewport_resized)
	_on_phase_changed(GameState.current_phase)
	apply_theme_styling()
	update_phase_buttons()

func register_views() -> void:
	views["briefing"] = preload("res://scenes/BriefingView.tscn")
	views["assembly"] = preload("res://scenes/AssemblyView.tscn")
	views["launch"] = preload("res://scenes/LaunchView.tscn")
	views["cruise"] = preload("res://scenes/CruiseView.tscn")
	views["landing"] = preload("res://scenes/LandingView.tscn")
	views["surface"] = preload("res://scenes/SurfaceView.tscn")
	views["debrief"] = preload("res://scenes/DebriefView.tscn")

func _on_theme_slider_changed(val: float) -> void:
	ThemeManager.set_theme_value(val)

func _on_theme_updated(_val: float) -> void:
	apply_theme_styling()
	update_phase_buttons()

func apply_theme_styling() -> void:
	bg.color = ThemeManager.get_bg_color()
	var glass_style = ThemeManager.create_glass_style(14, 1)
	top_bar.add_theme_stylebox_override("panel", glass_style)
	$TopBar/HBox/LblGameTitle.add_theme_color_override("font_color", ThemeManager.get_text_color())

func _on_phase_changed(phase_name: String) -> void:
	if not views.has(phase_name):
		return
	if current_view_node:
		current_view_node.queue_free()
		current_view_node = null
	var scene_res = views[phase_name]
	current_view_node = scene_res.instantiate()
	view_container.add_child(current_view_node)
	update_phase_buttons()

func _on_state_changed() -> void:
	update_phase_buttons()

func _on_viewport_resized() -> void:
	apply_theme_styling()
	update_phase_buttons()

func update_phase_buttons() -> void:
	var phase_names = ["briefing", "assembly", "launch", "cruise", "landing", "surface", "debrief"]
	var text_col = ThemeManager.get_text_color()
	var platform = DataManager.get_platform(GameState.platform_id)
	var is_orbiter = str(platform.get("type", "rover")) == "orbiter" or GameState.platform_id == "sampler"
	var current_idx = phase_names.find(GameState.current_phase)

	var vp_w = get_viewport_rect().size.x
	var is_compact = vp_w < 1060.0
	var is_tiny = vp_w < 840.0

	var title_lbl = $TopBar/HBox/LblGameTitle
	if title_lbl:
		if is_tiny:
			title_lbl.visible = false
		else:
			title_lbl.visible = true
			title_lbl.text = "АРХІТЕКТОР 2D" if is_compact else "АРХІТЕКТОР МІСІЇ 2D"

	var pad_h = 4 if is_tiny else (6 if is_compact else 12)
	var font_sz = 10 if is_tiny else (11 if is_compact else 13)

	for i in range(phase_buttons_container.get_child_count()):
		var btn = phase_buttons_container.get_child(i) as Button
		if btn and i < phase_names.size():
			var p_name = phase_names[i]
			if is_compact:
				match i:
					0: btn.text = "1. Ціль"
					1: btn.text = "2. Збірка"
					2: btn.text = "3. Старт"
					3: btn.text = "4. Переліт"
					4: btn.text = "5. Орбіта" if is_orbiter else "5. Посадка"
					5: btn.text = "6. Орбіта" if is_orbiter else "6. Поверхня"
					6: btn.text = "7. Звіт"
			else:
				match i:
					0: btn.text = "1. Ціль"
					1: btn.text = "2. Конструктор"
					2: btn.text = "3. Старт"
					3: btn.text = "4. Переліт"
					4: btn.text = "5. Вихід на орбіту" if is_orbiter else "5. Посадка"
					5: btn.text = "6. Орбіта" if is_orbiter else "6. Поверхня"
					6: btn.text = "7. Підсумок"

			btn.add_theme_font_size_override("font_size", font_sz)

			var is_active = (p_name == GameState.current_phase)
			var is_past = (current_idx != -1 and i < current_idx)

			var sb = StyleBoxFlat.new()
			sb.set_corner_radius_all(8)
			sb.content_margin_left = pad_h
			sb.content_margin_right = pad_h
			sb.content_margin_top = 4
			sb.content_margin_bottom = 4

			if is_active:
				sb.bg_color = Color(0.18, 0.94, 0.58, 0.22)
				sb.border_color = Color(0.18, 0.94, 0.58, 0.95)
				sb.set_border_width_all(1)
				sb.border_width_bottom = 2
				sb.shadow_color = Color(0.18, 0.94, 0.58, 0.3)
				sb.shadow_size = 6
				btn.add_theme_color_override("font_color", Color(0.18, 0.94, 0.58, 1.0))
			elif is_past:
				var past_bg = Color(0.0, 0.85, 1.0, 0.10) if ThemeManager.theme_value <= 0.5 else Color(0.0, 0.40, 0.70, 0.18)
				var past_border = Color(0.0, 0.85, 1.0, 0.45) if ThemeManager.theme_value <= 0.5 else Color(0.0, 0.32, 0.65, 0.65)
				var past_text = Color(0.0, 0.85, 1.0, 0.95) if ThemeManager.theme_value <= 0.5 else Color(0.0, 0.25, 0.60, 1.0)
				sb.bg_color = past_bg
				sb.border_color = past_border
				sb.set_border_width_all(1)
				btn.add_theme_color_override("font_color", past_text)
			else:
				var is_light_mode = ThemeManager.theme_value > 0.5
				sb.bg_color = Color(0.08, 0.12, 0.18, 0.25) if not is_light_mode else Color(0.70, 0.78, 0.90, 0.30)
				sb.border_color = Color(0.3, 0.4, 0.55, 0.25) if not is_light_mode else Color(0.30, 0.42, 0.60, 0.40)
				sb.set_border_width_all(1)
				btn.add_theme_color_override("font_color", text_col * Color(1, 1, 1, 0.75))
			btn.add_theme_stylebox_override("normal", sb)

func _on_nav_button_pressed(target_phase: String) -> void:
	SoundManager.play_click()
	var platform = DataManager.get_platform(GameState.platform_id)
	var is_orbiter = str(platform.get("type", "rover")) == "orbiter" or GameState.platform_id == "sampler"
	if target_phase == "landing" and is_orbiter:
		GameState.set_phase("surface")
		return
	GameState.set_phase(target_phase)
