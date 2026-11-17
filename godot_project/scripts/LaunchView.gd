extends Control

@onready var rocket_visual = $FlightArea/RocketVisual
@onready var btn_start = $Controls/BtnStartLaunch
@onready var btn_next = $Controls/BtnNextPhase
@onready var lbl_status = $Telemetry/VBox/LblStatus
@onready var lbl_altitude = $Telemetry/VBox/LblAltitude
@onready var lbl_speed = $Telemetry/VBox/LblSpeed
@onready var lbl_gforce = $Telemetry/VBox/LblGForce
@onready var lbl_telemetry_details = $Telemetry/VBox/LblDetails
@onready var flight_area = $FlightArea
@onready var telemetry_panel = $Telemetry
@onready var window_panel = $LaunchWindowPanel
@onready var lbl_target_info = $LaunchWindowPanel/VBox/LblTargetInfo
@onready var slider_offset = $LaunchWindowPanel/VBox/SliderOffset
@onready var lbl_offset_val = $LaunchWindowPanel/VBox/LblOffsetVal
@onready var lbl_window_status = $LaunchWindowPanel/VBox/LblWindowStatus

var is_launching: bool = false
var altitude_km: float = 0.0
var speed_kms: float = 0.0
var launch_timer: float = 0.0
var initial_rocket_pos: Vector2
var shake_intensity: float = 0.0
var umbilical_angle: float = 0.0
var downrange_km: float = 0.0
var stars: Array = []
var current_local_center_y: float = -75.0

var is_custom: bool = false
var custom_stats: Dictionary = {}
var m_dry_kg: float = 5000.0
var m_fuel_kg: float = 45000.0
var m_curr_kg: float = 50000.0
var thrust_n: float = 600000.0
var isp_s: float = 300.0
var aero_cd: float = 0.25
var current_pitch_deg: float = 0.0
var ang_vel_deg: float = 0.0
var throttle_val: float = 1.0
var sas_mode: String = "MANUAL"
var vx_ms: float = 0.0
var vy_ms: float = 0.0
var x_pos_m: float = 0.0
var y_pos_m: float = 0.0
var max_alt_reached_m: float = 0.0
var time_warp: float = 1.0
var staging_step: int = 0
var hull_temp_k: float = 293.0
var ablation_kg: float = 300.0
var map_view_node: Control = null
var is_map_active: bool = false
var is_crashed: bool = false
var custom_ground_offset: float = 0.0

var is_steer_left_held: bool = false
var is_steer_right_held: bool = false

var custom_controls_box: Control = null
var slider_throttle: VSlider = null
var lbl_throttle_val: Label = null
var btn_stage: Button = null
var btn_map_toggle: Button = null
var btn_sas: Button = null
var btn_steer_left: Button = null
var btn_steer_right: Button = null
var btn_time_warp: Button = null
var btn_reset: Button = null

func _ready() -> void:
	is_custom = GameState.is_custom_rocket
	update_pad_alignment()
	current_local_center_y = -75.0
	_init_window_panel()
	ThemeManager.theme_changed.connect(func(_v): apply_theme())
	apply_theme()
	btn_start.pressed.connect(_on_start_pressed)
	btn_next.pressed.connect(_on_next_pressed)
	btn_next.visible = false
	lbl_status.text = "Передстартовий відлік: очікування команди"
	lbl_altitude.text = "Висота: 0.0 км"
	lbl_speed.text = "Швидкість: 0.00 км/с (0 км/год)"
	lbl_gforce.text = "Перевантаження: 1.0 G"
	lbl_telemetry_details.text = "Дальність: 0.0 км | Тиск Q: 0.0 кПа"

	for i in range(70):
		stars.append(Vector2(randf_range(20.0, 1260.0), randf_range(10.0, 400.0)))

	_setup_orbital_map()

	if is_custom:
		_init_custom_rocket_mode()

func _setup_orbital_map() -> void:
	var map_script = load("res://scripts/OrbitalMapVisual.gd")
	if map_script:
		map_view_node = Control.new()
		map_view_node.set_script(map_script)
		map_view_node.set_anchors_preset(PRESET_FULL_RECT)
		map_view_node.visible = false
		flight_area.add_child(map_view_node)

func _init_custom_rocket_mode() -> void:
	custom_stats = Calc.calculate_custom_rocket(GameState.custom_rocket_placed_parts)
	m_dry_kg = max(500.0, float(custom_stats.get("mass_dry_t", 5.0)) * 1000.0)
	m_fuel_kg = max(100.0, float(custom_stats.get("mass_fuel_t", 20.0)) * 1000.0)
	m_curr_kg = m_dry_kg + m_fuel_kg
	thrust_n = max(50000.0, float(custom_stats.get("thrust_kn", 400.0)) * 1000.0)
	isp_s = max(200.0, float(custom_stats.get("avg_isp", 280.0)))
	aero_cd = max(0.08, float(custom_stats.get("cd", 0.2)))
	ablation_kg = float(custom_stats.get("ablation_t", 0.2)) * 1000.0

	if custom_controls_box:
		return

	custom_controls_box = Control.new()
	custom_controls_box.name = "CustomSfsControls"
	custom_controls_box.set_anchors_preset(PRESET_FULL_RECT)
	custom_controls_box.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(custom_controls_box)

	var throttle_panel = PanelContainer.new()
	throttle_panel.position = Vector2(25, 235)
	throttle_panel.size = Vector2(85, 290)
	throttle_panel.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(12, 1))
	custom_controls_box.add_child(throttle_panel)

	var t_vbox = VBoxContainer.new()
	t_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	t_vbox.add_theme_constant_override("separation", 6)
	throttle_panel.add_child(t_vbox)

	var lbl_th_title = Label.new()
	lbl_th_title.text = "ТЯГА"
	lbl_th_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_th_title.add_theme_font_size_override("font_size", 12)
	lbl_th_title.add_theme_color_override("font_color", ThemeManager.accent_cyan)
	t_vbox.add_child(lbl_th_title)

	var btn_th_max = Button.new()
	btn_th_max.text = "100%"
	btn_th_max.custom_minimum_size = Vector2(65, 26)
	btn_th_max.pressed.connect(func(): _set_throttle(1.0))
	t_vbox.add_child(btn_th_max)

	slider_throttle = VSlider.new()
	slider_throttle.custom_minimum_size = Vector2(28, 140)
	slider_throttle.size_flags_horizontal = SIZE_SHRINK_CENTER
	slider_throttle.min_value = 0.0
	slider_throttle.max_value = 1.0
	slider_throttle.step = 0.01
	slider_throttle.value = 1.0
	slider_throttle.value_changed.connect(func(val): throttle_val = val; _update_throttle_label())
	t_vbox.add_child(slider_throttle)

	var btn_th_zero = Button.new()
	btn_th_zero.text = "0%"
	btn_th_zero.custom_minimum_size = Vector2(65, 26)
	btn_th_zero.pressed.connect(func(): _set_throttle(0.0))
	t_vbox.add_child(btn_th_zero)

	lbl_throttle_val = Label.new()
	lbl_throttle_val.text = "100%"
	lbl_throttle_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_throttle_val.add_theme_font_size_override("font_size", 12)
	t_vbox.add_child(lbl_throttle_val)

	var bottom_bar = HBoxContainer.new()
	bottom_bar.set_anchors_preset(PRESET_BOTTOM_WIDE)
	bottom_bar.offset_top = -62.0
	bottom_bar.offset_bottom = -10.0
	bottom_bar.offset_left = 180.0
	bottom_bar.offset_right = -180.0
	bottom_bar.add_theme_constant_override("separation", 10)
	bottom_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	custom_controls_box.add_child(bottom_bar)

	btn_steer_left = Button.new()
	btn_steer_left.text = "<- [A]"
	btn_steer_left.custom_minimum_size = Vector2(80, 48)
	btn_steer_left.button_down.connect(func(): is_steer_left_held = true)
	btn_steer_left.button_up.connect(func(): is_steer_left_held = false)
	btn_steer_left.mouse_exited.connect(func(): is_steer_left_held = false)
	bottom_bar.add_child(btn_steer_left)

	btn_steer_right = Button.new()
	btn_steer_right.text = "[D] ->"
	btn_steer_right.custom_minimum_size = Vector2(80, 48)
	btn_steer_right.button_down.connect(func(): is_steer_right_held = true)
	btn_steer_right.button_up.connect(func(): is_steer_right_held = false)
	btn_steer_right.mouse_exited.connect(func(): is_steer_right_held = false)
	bottom_bar.add_child(btn_steer_right)

	btn_sas = Button.new()
	btn_sas.text = "SAS: РУЧНЕ"
	btn_sas.custom_minimum_size = Vector2(130, 48)
	btn_sas.pressed.connect(_cycle_sas_mode)
	bottom_bar.add_child(btn_sas)

	btn_stage = Button.new()
	btn_stage.text = "СТУПІНЬ (Space)"
	btn_stage.custom_minimum_size = Vector2(160, 48)
	btn_stage.pressed.connect(_on_custom_stage_triggered)
	var stage_style = StyleBoxFlat.new()
	stage_style.bg_color = Color(0.9, 0.45, 0.1, 0.8)
	stage_style.set_corner_radius_all(8)
	btn_stage.add_theme_stylebox_override("normal", stage_style)
	bottom_bar.add_child(btn_stage)

	btn_map_toggle = Button.new()
	btn_map_toggle.text = "КАРТА (M)"
	btn_map_toggle.custom_minimum_size = Vector2(130, 48)
	btn_map_toggle.pressed.connect(_toggle_map_view)
	bottom_bar.add_child(btn_map_toggle)

	btn_time_warp = Button.new()
	btn_time_warp.text = "1x"
	btn_time_warp.custom_minimum_size = Vector2(60, 48)
	btn_time_warp.pressed.connect(_cycle_time_warp)
	bottom_bar.add_child(btn_time_warp)

	btn_reset = Button.new()
	btn_reset.text = "В ЦЕХ"
	btn_reset.custom_minimum_size = Vector2(80, 48)
	btn_reset.pressed.connect(_on_reset_pressed)
	bottom_bar.add_child(btn_reset)

func _on_reset_pressed() -> void:
	if is_crashed:
		_restart_custom_launch()
	else:
		GameState.set_phase("custom_builder")

func _restart_custom_launch() -> void:
	is_crashed = false
	is_launching = false
	y_pos_m = 0.0
	x_pos_m = 0.0
	vx_ms = 0.0
	vy_ms = 0.0
	ang_vel_deg = 0.0
	current_pitch_deg = 0.0
	throttle_val = 1.0
	launch_timer = 0.0
	max_alt_reached_m = 0.0
	custom_ground_offset = 0.0
	staging_step = 0
	rocket_visual.staging_stage = 0
	rocket_visual.visible = true
	rocket_visual.rotation_degrees = 0.0
	rocket_visual.thrust_power = 0.0
	_init_custom_rocket_mode()
	update_pad_alignment()
	btn_start.visible = true
	btn_reset.text = "В ЦЕХ"
	btn_reset.modulate = Color.WHITE
	lbl_status.text = "Готовність до повторного старту. Натисніть СТАРТ."
	lbl_status.modulate = ThemeManager.accent_cyan

func _set_throttle(val: float) -> void:
	throttle_val = clamp(val, 0.0, 1.0)
	if slider_throttle:
		slider_throttle.value = throttle_val
	_update_throttle_label()

func _update_throttle_label() -> void:
	if lbl_throttle_val:
		lbl_throttle_val.text = "%d%%" % int(throttle_val * 100.0)

func _cycle_sas_mode() -> void:
	SoundManager.play_click()
	match sas_mode:
		"MANUAL":
			sas_mode = "PROGRADE"
			btn_sas.text = "SAS: ПРОГРАД"
			btn_sas.modulate = ThemeManager.accent_emerald
		"PROGRADE":
			sas_mode = "VERTICAL"
			btn_sas.text = "SAS: ВЕРТИК"
			btn_sas.modulate = ThemeManager.accent_cyan
		"VERTICAL":
			sas_mode = "MANUAL"
			btn_sas.text = "SAS: РУЧНЕ"
			btn_sas.modulate = Color.WHITE

func _cycle_time_warp() -> void:
	SoundManager.play_click()
	if time_warp == 1.0:
		time_warp = 2.0
	elif time_warp == 2.0:
		time_warp = 5.0
	elif time_warp == 5.0:
		time_warp = 10.0
	else:
		time_warp = 1.0
	btn_time_warp.text = "%.0fx" % time_warp

func _toggle_map_view() -> void:
	SoundManager.play_click()
	is_map_active = not is_map_active
	if map_view_node:
		map_view_node.visible = is_map_active
	if btn_map_toggle:
		btn_map_toggle.text = "КАМЕРА (M)" if is_map_active else "КАРТА (M)"

func _on_custom_stage_triggered() -> void:
	SoundManager.play_click()
	staging_step += 1
	rocket_visual.staging_stage = staging_step
	var drop_dry = m_dry_kg * 0.22
	m_dry_kg = max(400.0, m_dry_kg - drop_dry)
	thrust_n = max(30000.0, thrust_n * 0.85)
	lbl_status.text = "СТУПІНЬ %d ВІДОКРЕМЛЕНО! Системи номінальні." % staging_step

func _unhandled_input(event: InputEvent) -> void:
	if not is_custom or not is_launching:
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		match event.keycode:
			KEY_SPACE:
				_on_custom_stage_triggered()
			KEY_M:
				_toggle_map_view()
			KEY_Z:
				_set_throttle(1.0)
			KEY_X:
				_set_throttle(0.0)

func _init_window_panel() -> void:
	window_panel.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(16, 1))
	var target_info = DataManager.get_target(GameState.target_id)
	var t_name = DataManager.get_localized(target_info.get("name"), "Ціль")
	var win = target_info.get("window", {})
	var syn_d = int(win.get("synodic_days", 780))
	lbl_target_info.text = "Ціль: %s | Синодичний період: %d діб" % [t_name, syn_d]
	slider_offset.value = 0.0
	slider_offset.value_changed.connect(_on_slider_changed)
	_update_window_status(0)
	var bar_ctrl = Control.new()
	bar_ctrl.name = "WindowBarControl"
	bar_ctrl.custom_minimum_size = Vector2(0, 44)
	bar_ctrl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var vbox_win = window_panel.get_node("VBox")
	vbox_win.add_child(bar_ctrl)
	vbox_win.move_child(bar_ctrl, 2)
	bar_ctrl.draw.connect(_on_window_bar_draw.bind(bar_ctrl))
	bar_ctrl.set_script(null)

func _draw_window_bar() -> void:
	var ctrl = window_panel.get_node_or_null("VBox/WindowBarControl")
	if ctrl:
		ctrl.queue_redraw()

func _on_slider_changed(val: float) -> void:
	_update_window_status(int(val))
	var bar = window_panel.get_node_or_null("VBox/WindowBarControl")
	if bar:
		bar.queue_redraw()

func _update_window_status(off: int) -> void:
	if off == 0:
		lbl_offset_val.text = "Дата старту: Т-0 (Оптимальна дата Гомана)"
		lbl_window_status.text = "Ідеальне вирівнювання орбіт: dV мінімальний, 100% паливного запасу."
		lbl_window_status.modulate = ThemeManager.accent_emerald
	elif abs(off) <= 10:
		lbl_offset_val.text = "Дата старту: %s%d діб від оптимуму" % ["+" if off > 0 else "", off]
		lbl_window_status.text = "Допустиме вікно (+5% dV). Невеликі втрати палива."
		lbl_window_status.modulate = ThemeManager.accent_amber
	else:
		lbl_offset_val.text = "Дата старту: %s%d діб від оптимуму" % ["+" if off > 0 else "", off]
		lbl_window_status.text = "Неоптимальне вікно (+%d%% dV). Високий ризик дефіциту палива!" % [abs(off) * 2]
		lbl_window_status.modulate = ThemeManager.accent_red

func _on_window_bar_draw(ctrl: Control) -> void:
	var w = ctrl.size.x
	if w < 10:
		return
	var h = ctrl.size.y
	var total_days = 60
	var cell_w = w / float(total_days)
	var cur_off = int(slider_offset.value)
	for d in range(total_days):
		var day_off = d - 30
		var cell_x = d * cell_w
		var col: Color
		if abs(day_off) == 0:
			col = Color(0.18, 0.94, 0.58, 0.95)
		elif abs(day_off) <= 5:
			col = Color(0.18, 0.94, 0.58, 0.60)
		elif abs(day_off) <= 10:
			col = Color(1.0, 0.74, 0.20, 0.75)
		elif abs(day_off) <= 20:
			col = Color(1.0, 0.50, 0.20, 0.70)
		else:
			col = Color(1.0, 0.36, 0.36, 0.60)
		ctrl.draw_rect(Rect2(cell_x + 1, 2, cell_w - 2, h - 10), col, true, 1.0)
		ctrl.draw_rect(Rect2(cell_x + 1, 2, cell_w - 2, h - 10), Color(0, 0, 0, 0.18), false, 1.0)
	var sel_d = cur_off + 30
	var sel_x = sel_d * cell_w
	ctrl.draw_rect(Rect2(sel_x, 0, cell_w, h - 2), Color(1, 1, 1, 0.95), false, 2.5)
	ctrl.draw_rect(Rect2(sel_x + 2, 2, cell_w - 4, h - 6), Color(1, 1, 1, 0.22), true, 1.0)
	var label_positions = [-30, -15, 0, 15, 30]
	for lp in label_positions:
		var lx = (lp + 30) * cell_w + cell_w * 0.5
		var ltext = "T%+d" % lp if lp != 0 else "T-0"
		ctrl.draw_string(ctrl.get_theme_default_font(), Vector2(lx - 12, h - 1), ltext, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 1, 1, 0.75))

func update_pad_alignment() -> void:
	var rect = flight_area.get_viewport_rect()
	var pad_x = rect.size.x * 0.5
	var ground_y = rect.size.y - 75.0
	var table_top_y = ground_y - 14.0
	if is_custom and rocket_visual.has_method("get_custom_rocket_height"):
		var pivot_y = rocket_visual.get_custom_rocket_height() * 0.5
		initial_rocket_pos = Vector2(pad_x, table_top_y - pivot_y)
	else:
		initial_rocket_pos = Vector2(pad_x, table_top_y - 8.0)
	if not is_launching and not is_crashed:
		rocket_visual.position = initial_rocket_pos

func _process(delta: float) -> void:
	flight_area.queue_redraw()

	if not is_launching:
		update_pad_alignment()
		return

	if is_custom:
		_process_custom_flight(delta)
	else:
		_process_classic_flight(delta)

func _process_custom_flight(delta: float) -> void:
	if is_crashed:
		return

	launch_timer += delta
	if launch_timer < 2.5:
		var count = 3 - int(launch_timer)
		lbl_status.text = "Зворотний відлік T-%d... Запалювання!" % [count]
		shake_intensity = (launch_timer / 2.5) * 3.5
		rocket_visual.position = initial_rocket_pos + Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
		return

	var dt = delta * time_warp

	var steer_input = 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or is_steer_left_held:
		steer_input -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or is_steer_right_held:
		steer_input += 1.0

	if Input.is_key_pressed(KEY_SHIFT):
		_set_throttle(throttle_val + 0.4 * dt)
	elif Input.is_key_pressed(KEY_CTRL):
		_set_throttle(throttle_val - 0.4 * dt)

	var v_total = sqrt(vx_ms * vx_ms + vy_ms * vy_ms)

	if steer_input != 0.0:
		ang_vel_deg += steer_input * 65.0 * dt
		ang_vel_deg = clamp(ang_vel_deg, -90.0, 90.0)
	else:
		if sas_mode == "PROGRADE" and v_total > 15.0:
			var pro_deg = rad_to_deg(atan2(vx_ms, vy_ms))
			var diff = fposmod(pro_deg - current_pitch_deg + 180.0, 360.0) - 180.0
			ang_vel_deg = clamp(diff * 4.0, -60.0, 60.0)
		elif sas_mode == "VERTICAL":
			var diff = fposmod(-current_pitch_deg + 180.0, 360.0) - 180.0
			ang_vel_deg = clamp(diff * 4.0, -60.0, 60.0)
		else:
			ang_vel_deg = move_toward(ang_vel_deg, 0.0, 45.0 * dt)

	current_pitch_deg += ang_vel_deg * dt
	current_pitch_deg = fposmod(current_pitch_deg + 180.0, 360.0) - 180.0

	var f_th = 0.0
	if m_fuel_kg > 0.0 and throttle_val > 0.0:
		f_th = thrust_n * throttle_val
		var m_dot = f_th / (isp_s * 9.80665)
		m_fuel_kg = max(0.0, m_fuel_kg - m_dot * dt)
	else:
		f_th = 0.0
		throttle_val = 0.0
		_update_throttle_label()

	m_curr_kg = m_dry_kg + m_fuel_kg
	var r_m = 6371000.0 + y_pos_m
	var g = 3.986004418e14 / (r_m * r_m)
	var rho = Calc.atmospheric_density(1.225, y_pos_m, 8500.0)
	var area = 3.14159 * 1.5 * 1.5
	var f_drag = 0.5 * aero_cd * area * rho * v_total * v_total
	var q_press_kpa = (0.5 * rho * v_total * v_total) / 1000.0

	var pitch_rad = deg_to_rad(current_pitch_deg)
	var ax_th = (f_th * sin(pitch_rad)) / m_curr_kg
	var ay_th = (f_th * cos(pitch_rad)) / m_curr_kg

	var drag_dir_x = -(vx_ms / max(1.0, v_total))
	var drag_dir_y = -(vy_ms / max(1.0, v_total))
	var ax_drag = (f_drag * drag_dir_x) / m_curr_kg
	var ay_drag = (f_drag * drag_dir_y) / m_curr_kg

	var a_cent = (vx_ms * vx_ms) / r_m
	var ax = ax_th + ax_drag
	var ay = ay_th + ay_drag - g + a_cent

	vx_ms += ax * dt
	vy_ms += ay * dt
	x_pos_m += vx_ms * dt
	y_pos_m += vy_ms * dt
	max_alt_reached_m = max(max_alt_reached_m, y_pos_m)

	if y_pos_m <= 0.0:
		y_pos_m = 0.0
		if max_alt_reached_m > 4.0:
			var impact_spd = sqrt(vx_ms * vx_ms + vy_ms * vy_ms)
			if impact_spd > 12.0 or abs(current_pitch_deg) > 22.0:
				is_crashed = true
				is_launching = false
				vx_ms = 0.0
				vy_ms = 0.0
				rocket_visual.thrust_power = 0.0
				lbl_status.text = "КАТАСТРОФА: Апарат розбився об поверхню! Швидкість удару: %.1f м/с (%.0f км/год)" % [impact_spd, impact_spd * 3.6]
				lbl_status.modulate = ThemeManager.accent_red
				SoundManager.play_beep(180.0, 0.6)
				btn_reset.text = "ПОВТОРИТИ"
				btn_reset.modulate = ThemeManager.accent_amber
				return
			else:
				vx_ms = 0.0
				vy_ms = 0.0
				lbl_status.text = "М'ЯКА ПОСАДКА: Апарат успішно сів на поверхню Землі!"
				lbl_status.modulate = ThemeManager.accent_emerald
		else:
			vx_ms = 0.0
			vy_ms = max(0.0, vy_ms)

	altitude_km = y_pos_m / 1000.0
	speed_kms = sqrt(vx_ms * vx_ms + vy_ms * vy_ms) / 1000.0
	downrange_km = x_pos_m / 1000.0

	var heat_flux = Calc.calculate_aero_heating(rho, v_total, 1.5)
	if heat_flux > 3000.0:
		if bool(custom_stats.get("has_heat_shield", false)):
			ablation_kg = max(0.0, ablation_kg - heat_flux * 1e-8 * dt)
		else:
			hull_temp_k += heat_flux * 0.00008 * dt

	var orb = Calc.calculate_keplerian_orbit(3.986004418e14, r_m, vx_ms, vy_ms, 6371000.0)
	if map_view_node:
		map_view_node.update_telemetry(altitude_km, speed_kms, current_pitch_deg, orb, time_warp)

	var vp_rect = flight_area.get_viewport_rect()
	var climb_target_y = vp_rect.size.y * 0.45
	if y_pos_m < 100.0:
		var climb_t = y_pos_m / 100.0
		rocket_visual.position.y = lerp(initial_rocket_pos.y, climb_target_y, climb_t)
		custom_ground_offset = 0.0
	else:
		rocket_visual.position.y = climb_target_y
		custom_ground_offset = (y_pos_m - 100.0) * 1.5

	var max_drift_px = vp_rect.size.x * 0.28
	rocket_visual.position.x = initial_rocket_pos.x + clamp(x_pos_m * 0.02, -max_drift_px, max_drift_px)
	rocket_visual.rotation_degrees = current_pitch_deg
	rocket_visual.thrust_power = throttle_val
	rocket_visual.altitude_km = altitude_km
	rocket_visual.is_flying = (y_pos_m > 0.5 or throttle_val > 0.0)

	var dv_rem = isp_s * 9.80665 * log(m_curr_kg / max(1.0, m_dry_kg))
	var fuel_pct = (m_fuel_kg / max(1.0, float(custom_stats.get("mass_fuel_t", 20.0)) * 1000.0)) * 100.0
	var g_accel = sqrt(ax * ax + (ay + g) * (ay + g)) / 9.80665

	lbl_altitude.text = "Висота: %.1f км | Ap: %.1f км | Pe: %.1f км" % [altitude_km, orb.apoapsis_km, orb.periapsis_km]
	lbl_speed.text = "Швидкість: %.2f км/с (%d км/год) | Запас dV: %d м/с" % [speed_kms, int(speed_kms * 3600.0), int(dv_rem)]
	lbl_gforce.text = "Перевантаження: %.1f G | Паливо: %.1f%%" % [g_accel, fuel_pct]
	lbl_telemetry_details.text = "Дальність: %.1f км | Тиск Q: %.1f кПа | Т: %.0f K" % [downrange_km, q_press_kpa, hull_temp_k]

	if bool(orb.get("is_stable_orbit", false)):
		lbl_status.text = "СТАБІЛЬНА ОРБІТА LEO ЗАКРИТА! Готовність до міжпланетного перельоту."
		lbl_status.modulate = ThemeManager.accent_emerald
		btn_next.visible = true
	elif altitude_km > 100.0:
		lbl_status.text = "Лінія Кармана пройдена (100 км): Космос. Сформуйте орбіту нахилом до горизонту!"
	elif q_press_kpa > 25.0:
		lbl_status.text = "MAX-Q: Максимальний аеродинамічний тиск!"

func _process_classic_flight(delta: float) -> void:
	launch_timer += delta

	if launch_timer < 3.0:
		var count = 3 - int(launch_timer)
		lbl_status.text = "Зворотний відлік T-%d... Запалювання двигунів!" % [count]
		shake_intensity = (launch_timer / 3.0) * 3.5
		rocket_visual.position = initial_rocket_pos + Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
		return

	if umbilical_angle < 45.0:
		umbilical_angle += delta * 60.0

	rocket_visual.is_flying = true
	SoundManager.play_thruster()

	var accel = 0.42 + (speed_kms * 0.08)
	speed_kms += delta * accel
	altitude_km += speed_kms * delta * 28.0
	downrange_km += speed_kms * delta * 12.0
	rocket_visual.altitude_km = altitude_km

	var g_val = 1.0 + (accel / 0.098)
	var q_press = max(0.0, sin(clamp(altitude_km / 35.0, 0.0, PI)) * 36.0)

	shake_intensity = lerp(4.0, 0.4, clamp(altitude_km / 90.0, 0.0, 1.0))

	var pitch_deg = 0.0
	if altitude_km > 8.0:
		var t_pitch = clamp((altitude_km - 8.0) / 135.0, 0.0, 1.0)
		pitch_deg = smoothstep(0.0, 1.0, t_pitch) * 68.0
	rocket_visual.rotation_degrees = pitch_deg

	var target_local_y = -75.0
	if rocket_visual.staging_stage >= 2:
		target_local_y = -135.0
	current_local_center_y = lerp(current_local_center_y, target_local_y, delta * 2.5)

	var climb_t = clamp(altitude_km / 25.0, 0.0, 1.0)
	var climb_px = smoothstep(0.0, 1.0, climb_t) * 240.0
	var downrange_t = clamp((altitude_km - 8.0) / 135.0, 0.0, 1.0)
	var downrange_px = smoothstep(0.0, 1.0, downrange_t) * 140.0

	var desired_x = initial_rocket_pos.x + downrange_px
	var desired_y = initial_rocket_pos.y - climb_px

	var rad = deg_to_rad(pitch_deg)
	var off_x = -current_local_center_y * sin(rad)
	var off_y = current_local_center_y * (cos(rad) - 1.0)
	var base_pos = Vector2(desired_x - off_x, desired_y - off_y)
	var shake = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
	rocket_visual.position = base_pos + shake

	lbl_altitude.text = "Висота: %.1f км" % [altitude_km]
	lbl_speed.text = "Швидкість: %.2f км/с (%d км/год)" % [speed_kms, int(speed_kms * 3600.0)]
	lbl_gforce.text = "Перевантаження: %.1f G" % [g_val]
	lbl_telemetry_details.text = "Дальність: %.1f км | Динамічний тиск Q: %.1f кПа" % [downrange_km, q_press]

	if altitude_km > 12.0 and altitude_km < 18.0:
		lbl_status.text = "MAX-Q: Максимальний аеродинамічний опір атмосфери!"

	var r_info = DataManager.get_rocket(GameState.rocket_id)
	var has_boosters = int(r_info.get("boosters", 0)) > 0

	if has_boosters and altitude_km > 24.0 and rocket_visual.staging_stage == 0:
		rocket_visual.staging_stage = 1
		lbl_status.text = "Відокремлення прискорювачів! Системи номінальні."
		SoundManager.play_click()
	elif not has_boosters and rocket_visual.staging_stage == 0 and altitude_km > 55.0:
		rocket_visual.staging_stage = 2
		lbl_status.text = "MECO: Головний ступінь відпрацював! Запуск двигуна 2-го ступеня."
		SoundManager.play_click()

	if has_boosters and altitude_km > 55.0 and rocket_visual.staging_stage == 1:
		rocket_visual.staging_stage = 2
		lbl_status.text = "MECO: Головний ступінь відпрацював! Запуск двигуна 2-го ступеня."
		SoundManager.play_click()

	if altitude_km > 85.0 and rocket_visual.staging_stage == 2:
		rocket_visual.staging_stage = 3
		lbl_status.text = "Скидання головного обтічника! Зонд у відкритому космосі."
		SoundManager.play_click()

	if altitude_km >= 180.0:
		is_launching = false
		rocket_visual.thrust_power = 0.0
		var target_info = DataManager.get_target(GameState.target_id)
		var t_name = DataManager.get_localized(target_info.get("name"), "цілі")
		lbl_status.text = "SECO: Вихід на опорну орбіту успішний! Готовність до перельоту до: %s." % [t_name]
		SoundManager.play_success()
		btn_next.visible = true

func _on_start_pressed() -> void:
	SoundManager.play_click()
	window_panel.visible = false
	var off = int(slider_offset.value)
	GameState.launch_window_offset = off
	if off == 0:
		GameState.flight_events_log.append("Старт у точне вікно Гомана: максимальна енергетична ефективність!")
	else:
		GameState.flight_events_log.append("Старт зі зміщенням %d діб: витрачено додаткове паливо." % [off])
	is_launching = true
	launch_timer = 0.0
	btn_start.visible = false

func _on_next_pressed() -> void:
	SoundManager.play_click()
	GameState.set_phase("cruise")

func apply_theme() -> void:
	telemetry_panel.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(16, 1))
	window_panel.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(16, 1))
	var text_col = ThemeManager.get_text_color()
	var muted_col = ThemeManager.get_muted_color()
	var cyan = ThemeManager.get_accent_cyan()

	lbl_altitude.add_theme_color_override("font_color", text_col)
	lbl_speed.add_theme_color_override("font_color", text_col)
	lbl_gforce.add_theme_color_override("font_color", text_col)
	lbl_telemetry_details.add_theme_color_override("font_color", muted_col)
	lbl_target_info.add_theme_color_override("font_color", cyan)
	lbl_offset_val.add_theme_color_override("font_color", text_col)
	var win_title = window_panel.get_node_or_null("VBox/LblWindowTitle")
	if win_title:
		win_title.add_theme_color_override("font_color", cyan)
	var bar = window_panel.get_node_or_null("VBox/WindowBarControl")
	if bar:
		bar.queue_redraw()
