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

func update_phase_buttons() -> void:
	var phase_names = ["briefing", "assembly", "launch", "cruise", "landing", "surface", "debrief"]
	var is_light = ThemeManager.theme_value > 0.5
	var text_col = ThemeManager.get_text_color()
	var platform = DataManager.get_platform(GameState.platform_id)
	var is_orbiter = str(platform.get("type", "rover")) == "orbiter" or GameState.platform_id == "sampler"

	for i in range(phase_buttons_container.get_child_count()):
		var btn = phase_buttons_container.get_child(i) as Button
		if btn and i < phase_names.size():
			var p_name = phase_names[i]
			if i == 4:
				btn.text = "5. Вихід на орбіту" if is_orbiter else "5. Посадка"
			elif i == 5:
				btn.text = "6. Орбіта" if is_orbiter else "6. Поверхня"

			var is_active = p_name == GameState.current_phase
			var sb = StyleBoxFlat.new()
			sb.set_corner_radius_all(8)
			sb.content_margin_left = 10
			sb.content_margin_right = 10
			sb.content_margin_top = 4
			sb.content_margin_bottom = 4

			if is_active:
				sb.bg_color = ThemeManager.accent_emerald * Color(1, 1, 1, 0.25)
				sb.border_color = ThemeManager.accent_emerald
				sb.set_border_width_all(1)
				btn.add_theme_color_override("font_color", ThemeManager.accent_emerald)
			else:
				sb.bg_color = Color(0, 0, 0, 0)
				sb.border_color = Color(0, 0, 0, 0)
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
