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

func _ready() -> void:
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
	initial_rocket_pos = Vector2(pad_x, table_top_y - 8.0)
	if not is_launching:
		rocket_visual.position = initial_rocket_pos

func _process(delta: float) -> void:
	flight_area.queue_redraw()

	if not is_launching:
		update_pad_alignment()
		return
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
	btn_start.disabled = true

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
