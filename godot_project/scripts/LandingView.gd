extends Control

@onready var flight_area = $FlightArea
@onready var craft_node = $FlightArea/LanderCraft
@onready var craft_visual = $FlightArea/LanderCraft/LandingCraftVisual
@onready var terrain_visual = $FlightArea/LandingTerrainVisual
@onready var navball = $HUD/VBox/HBoxNavball/NavballAnchor/NavballVisual

@onready var hud_panel = $HUD
@onready var lbl_status = $HUD/VBox/LblStatus
@onready var lbl_mode_badge = $HUD/VBox/LblModeBadge
@onready var lbl_alt = $HUD/VBox/LblAlt
@onready var lbl_vspeed = $HUD/VBox/LblVSpeed
@onready var lbl_hspeed = $HUD/VBox/LblHSpeed
@onready var lbl_pitch = $HUD/VBox/HBoxNavball/VBoxNavStats/LblPitch
@onready var lbl_twr = $HUD/VBox/HBoxNavball/VBoxNavStats/LblTWR
@onready var lbl_fuel = $HUD/VBox/LblFuel
@onready var btn_box = $HUD/VBox/HBoxTouchdownButtons
@onready var btn_retry = $HUD/VBox/HBoxTouchdownButtons/BtnRetry
@onready var btn_next = $HUD/VBox/HBoxTouchdownButtons/BtnNext
@onready var btn_chute = $Controls/BtnChute
@onready var btn_toggle_mode = $Controls/BtnToggleMode

@onready var btn_thrust_up = $Controls/BtnThrustUp
@onready var btn_thrust_left = $Controls/BtnThrustLeft
@onready var btn_thrust_right = $Controls/BtnThrustRight

@onready var mode_dialog = $ModeDialog
@onready var panel_manual = $ModeDialog/VBox/HBoxCards/PanelManual
@onready var panel_auto = $ModeDialog/VBox/HBoxCards/PanelAuto
@onready var btn_select_manual = $ModeDialog/VBox/HBoxCards/PanelManual/VBoxM/BtnSelectManual
@onready var btn_select_auto = $ModeDialog/VBox/HBoxCards/PanelAuto/VBoxA/BtnSelectAuto

var craft_pos: Vector2 = Vector2(640, 50)
var craft_vel: Vector2 = Vector2(25, 45)
var craft_angle_deg: float = 0.0
var craft_ang_vel: float = 0.0

var fuel_pct: float = 100.0
var throttle: float = 0.0
var is_active: bool = true
var is_sim_started: bool = false
var flight_mode: String = "manual"

var is_thrust_key: bool = false
var is_left_key: bool = false
var is_right_key: bool = false

var edl_phase: int = 2
var parachute_deployed: bool = false
var ground_y: float = 570.0
var pad_center_x: float = 640.0
var pad_width: float = 240.0

var gravity: float = 36.0
var max_thrust: float = 95.0
var dry_mass: float = 400.0
var fuel_mass: float = 250.0

var shake_intensity: float = 0.0

var auto_glitch_type: int = -1
var auto_glitch_triggered: bool = false
var radar_lag_timer: float = 0.0
var thrust_modifier: float = 1.0

func _ready() -> void:
	btn_box.visible = false
	btn_next.pressed.connect(_on_next_pressed)
	btn_retry.pressed.connect(_on_retry_pressed)
	btn_chute.pressed.connect(_on_chute_pressed)
	btn_toggle_mode.pressed.connect(_on_toggle_mode_pressed)

	btn_select_manual.pressed.connect(_on_select_manual_pressed)
	btn_select_auto.pressed.connect(_on_select_auto_pressed)

	btn_thrust_up.button_down.connect(func(): is_thrust_key = true)
	btn_thrust_up.button_up.connect(func(): is_thrust_key = false)
	btn_thrust_left.button_down.connect(func(): is_left_key = true)
	btn_thrust_left.button_up.connect(func(): is_left_key = false)
	btn_thrust_right.button_down.connect(func(): is_right_key = true)
	btn_thrust_right.button_up.connect(func(): is_right_key = false)

	ThemeManager.theme_changed.connect(func(_v): apply_theme())
	apply_theme()

	init_planetary_physics()
	craft_node.position = craft_pos
	terrain_visual.craft_pos = craft_pos
	update_flight_hud(ground_y - craft_pos.y, 0.6)

	mode_dialog.visible = true
	is_sim_started = false

func init_planetary_physics() -> void:
	match GameState.target_id:
		"mars":
			gravity = 36.0
			edl_phase = 0
			btn_chute.visible = true
		"moon":
			gravity = 16.0
			edl_phase = 2
			btn_chute.visible = false
		"venus":
			gravity = 85.0
			edl_phase = 0
			btn_chute.visible = true
		"europa":
			gravity = 13.0
			edl_phase = 2
			btn_chute.visible = false
		_:
			gravity = 12.0
			edl_phase = 2
			btn_chute.visible = false

	craft_visual.edl_phase = edl_phase

func _on_select_manual_pressed() -> void:
	SoundManager.play_click()
	flight_mode = "manual"
	mode_dialog.visible = false
	is_sim_started = true
	is_active = true
	update_mode_ui()
	lbl_status.text = "РУЧНЕ КЕРУВАННЯ: Усе залежить від вашої майстерності!"
	lbl_status.modulate = ThemeManager.get_accent_cyan()

func _on_select_auto_pressed() -> void:
	SoundManager.play_click()
	flight_mode = "auto"
	setup_auto_glitch()
	mode_dialog.visible = false
	is_sim_started = true
	is_active = true
	update_mode_ui()
	lbl_status.text = "АВТОПІЛОТ EDL АКТИВНИЙ: Бортовий комп'ютер веде посадку..."
	lbl_status.modulate = ThemeManager.get_accent_emerald()

func setup_auto_glitch() -> void:
	var stats = GameState.get_current_stats()
	var rel = float(stats.get("reliability", 0.95))
	var glitch_chance = clamp(1.0 - rel + 0.08, 0.08, 0.28)
	if randf() < glitch_chance:
		auto_glitch_type = randi() % 3
	else:
		auto_glitch_type = -1
	auto_glitch_triggered = false
	radar_lag_timer = 0.0
	thrust_modifier = 1.0

func _on_toggle_mode_pressed() -> void:
	SoundManager.play_click()
	if flight_mode == "manual":
		flight_mode = "auto"
		setup_auto_glitch()
		lbl_status.text = "АВТОПІЛОТ EDL АКТИВНИЙ: Бортовий комп'ютер взяв керування"
		lbl_status.modulate = ThemeManager.get_accent_emerald()
	else:
		flight_mode = "manual"
		lbl_status.text = "РУЧНИЙ РЕЖИМ: Пілот перехопив керування апаратом"
		lbl_status.modulate = ThemeManager.get_accent_cyan()
	update_mode_ui()

func update_mode_ui() -> void:
	if flight_mode == "manual":
		lbl_mode_badge.text = "РЕЖИМ: [ПІЛОТ] РУЧНЕ ПІЛОТУВАННЯ"
		lbl_mode_badge.modulate = ThemeManager.get_accent_cyan()
		btn_toggle_mode.text = "Автопілот EDL"
		btn_thrust_up.disabled = false
		btn_thrust_left.disabled = false
		btn_thrust_right.disabled = false
	else:
		lbl_mode_badge.text = "РЕЖИМ: [EDL] АВТОПІЛОТ"
		lbl_mode_badge.modulate = ThemeManager.get_accent_emerald()
		btn_toggle_mode.text = "Взяти керування (Ручне)"
		btn_thrust_up.disabled = true
		btn_thrust_left.disabled = true
		btn_thrust_right.disabled = true

func _process(delta: float) -> void:
	if shake_intensity > 0.01:
		flight_area.position = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
		shake_intensity = move_toward(shake_intensity, 0.0, delta * 30.0)
	else:
		flight_area.position = Vector2.ZERO

	if not is_sim_started or not is_active:
		return

	var dist_to_ground = ground_y - craft_pos.y

	if flight_mode == "auto":
		process_autopilot(delta, dist_to_ground)
	else:
		process_manual_input(delta)

	craft_angle_deg += craft_ang_vel * delta
	craft_angle_deg = clamp(craft_angle_deg, -65.0, 65.0)

	var current_mass = dry_mass + fuel_mass * (fuel_pct / 100.0)
	var mass_ratio = dry_mass / max(1.0, current_mass)

	craft_vel.y += gravity * delta

	if edl_phase == 0:
		var drag = craft_vel.length() * 0.45 * delta
		craft_vel = craft_vel.move_toward(Vector2.ZERO, drag)
		if craft_vel.length() < 55.0:
			edl_phase = 1
			craft_visual.edl_phase = edl_phase

	elif edl_phase == 1 and parachute_deployed:
		var chute_drag = 32.0 * delta
		craft_vel.y = move_toward(craft_vel.y, 22.0, chute_drag)
		craft_vel.x = move_toward(craft_vel.x, 0.0, chute_drag * 0.8)

	if throttle > 0.01 and fuel_pct > 0.0:
		var thrust_f = (max_thrust * thrust_modifier / max(0.5, mass_ratio)) * throttle
		var rad = deg_to_rad(craft_angle_deg)
		var thrust_vec = Vector2(sin(rad), -cos(rad)) * thrust_f
		craft_vel += thrust_vec * delta
		fuel_pct = max(0.0, fuel_pct - throttle * delta * 8.5)
		SoundManager.play_thruster()

	craft_pos += craft_vel * delta
	craft_pos.x = clamp(craft_pos.x, 60.0, 1220.0)
	craft_pos.y = max(40.0, craft_pos.y)
	if craft_pos.y <= 40.0 and craft_vel.y < 0.0:
		craft_vel.y = 0.0

	craft_node.position = craft_pos
	craft_node.rotation_degrees = craft_angle_deg
	craft_visual.throttle = throttle

	terrain_visual.craft_pos = craft_pos

	if dist_to_ground < 70.0 and throttle > 0.1:
		craft_visual.ground_dust_alpha = clamp((70.0 - dist_to_ground) / 60.0, 0.0, 1.0)
	else:
		craft_visual.ground_dust_alpha = 0.0

	update_flight_hud(dist_to_ground, mass_ratio)

	if craft_pos.y >= ground_y - 20.0:
		is_active = false
		craft_pos.y = ground_y - 20.0
		craft_node.position = craft_pos
		craft_visual.throttle = 0.0
		evaluate_touchdown()

func process_manual_input(delta: float) -> void:
	if Input.is_action_pressed("ui_up") or is_thrust_key or Input.is_key_pressed(KEY_W):
		throttle = move_toward(throttle, 1.0, delta * 3.5)
	else:
		throttle = move_toward(throttle, 0.0, delta * 4.0)

	var rcs_left = Input.is_action_pressed("ui_left") or is_left_key or Input.is_key_pressed(KEY_A)
	var rcs_right = Input.is_action_pressed("ui_right") or is_right_key or Input.is_key_pressed(KEY_D)

	craft_visual.is_rcs_left = rcs_left
	craft_visual.is_rcs_right = rcs_right

	if rcs_left:
		craft_ang_vel -= 140.0 * delta
		SoundManager.play_click()
	elif rcs_right:
		craft_ang_vel += 140.0 * delta
		SoundManager.play_click()
	else:
		craft_ang_vel = move_toward(craft_ang_vel, 0.0, delta * 85.0)

func process_autopilot(delta: float, dist_to_ground: float) -> void:
	if edl_phase == 0 and dist_to_ground < 430.0 and not parachute_deployed:
		_on_chute_pressed()
		lbl_status.text = "АВТОПІЛОТ: Розкриття парашута на висоті 420 м"
		lbl_status.modulate = ThemeManager.get_accent_emerald()

	if auto_glitch_type == 0 and not auto_glitch_triggered and dist_to_ground < 140.0:
		auto_glitch_triggered = true
		var gust_dir = -1.0 if craft_pos.x > pad_center_x else 1.0
		craft_vel.x += gust_dir * randf_range(38.0, 50.0)
		shake_intensity = 7.0
		SoundManager.play_beep(320.0, 0.3)
		lbl_status.text = "УВАГА: Порив атмосферної бурі збив курс автопілота!"
		lbl_status.modulate = ThemeManager.get_accent_amber()

	elif auto_glitch_type == 1 and not auto_glitch_triggered and dist_to_ground < 65.0:
		auto_glitch_triggered = true
		radar_lag_timer = 0.85
		SoundManager.play_beep(280.0, 0.3)
		lbl_status.text = "ЗБІЙ TRN: Затримка радіовисотоміра! Запізніле гальмування!"
		lbl_status.modulate = ThemeManager.get_accent_amber()

	elif auto_glitch_type == 2 and not auto_glitch_triggered and dist_to_ground < 45.0:
		auto_glitch_triggered = true
		thrust_modifier = 0.52
		SoundManager.play_beep(220.0, 0.4)
		lbl_status.text = "АВАРІЯ ДВИГУНА: Падіння тиску в паливній магістралі EDL!"
		lbl_status.modulate = ThemeManager.get_accent_red()

	var dx = pad_center_x - craft_pos.x
	var target_vx = clamp(dx * 0.35, -20.0, 20.0)
	var vx_err = target_vx - craft_vel.x
	var target_tilt = clamp(vx_err * 1.5, -22.0, 22.0)
	if dist_to_ground < 28.0:
		target_tilt = 0.0

	var tilt_err = target_tilt - craft_angle_deg
	craft_ang_vel = move_toward(craft_ang_vel, clamp(tilt_err * 7.5, -120.0, 120.0), delta * 260.0)

	craft_visual.is_rcs_left = tilt_err < -2.0
	craft_visual.is_rcs_right = tilt_err > 2.0

	var eff_dist = dist_to_ground
	if radar_lag_timer > 0.0:
		radar_lag_timer -= delta
		eff_dist = dist_to_ground + 35.0

	var target_vy = 36.0
	if eff_dist < 320.0:
		target_vy = 20.0
	if eff_dist < 120.0:
		target_vy = 10.0
	if eff_dist < 35.0:
		target_vy = 4.5

	var vy_err = craft_vel.y - target_vy
	var target_throttle = clamp(0.55 + vy_err * 0.09, 0.0, 1.0)
	throttle = move_toward(throttle, target_throttle, delta * 4.5)

func update_flight_hud(dist_to_ground: float, mass_ratio: float) -> void:
	lbl_alt.text = "Радарна висота AGL: %d м" % [int(max(0.0, dist_to_ground))]

	var vspeed_ok = craft_vel.y <= 36.0
	lbl_vspeed.text = "Верт. швидкість: %.1f м/с" % [craft_vel.y]
	lbl_vspeed.modulate = ThemeManager.get_accent_emerald() if vspeed_ok else ThemeManager.get_accent_red()

	var hspeed_ok = abs(craft_vel.x) <= 18.0
	lbl_hspeed.text = "Гориз. швидкість: %.1f м/с" % [abs(craft_vel.x)]
	lbl_hspeed.modulate = ThemeManager.get_accent_emerald() if hspeed_ok else ThemeManager.get_accent_red()

	var pitch_ok = abs(craft_angle_deg) <= 8.5
	lbl_pitch.text = "Кут нахилу: %.1f°" % [craft_angle_deg]
	lbl_pitch.modulate = ThemeManager.get_accent_emerald() if pitch_ok else ThemeManager.get_accent_red()

	var cur_twr = (max_thrust * thrust_modifier / max(0.5, mass_ratio)) / max(1.0, gravity)
	lbl_twr.text = "Тяга TWR: %.2f" % [cur_twr * throttle]

	lbl_fuel.text = "Запас палива: %d%% (Тяга: %d%%)" % [int(fuel_pct), int(throttle * 100.0)]
	lbl_fuel.modulate = ThemeManager.get_accent_emerald() if fuel_pct > 20.0 else ThemeManager.get_accent_red()

	navball.pitch_deg = craft_angle_deg
	navball.velocity_vector = craft_vel

func _on_chute_pressed() -> void:
	if edl_phase <= 1 and not parachute_deployed:
		parachute_deployed = true
		edl_phase = 1
		craft_visual.edl_phase = 1
		btn_chute.disabled = true
		SoundManager.play_success()

func evaluate_touchdown() -> void:
	btn_box.visible = true
	var on_pad = abs(craft_pos.x - pad_center_x) <= (pad_width * 0.5)
	var speed_ok = craft_vel.y <= 36.0 and abs(craft_vel.x) <= 18.0
	var angle_ok = abs(craft_angle_deg) <= 9.0

	if flight_mode == "auto":
		if auto_glitch_type == -1 and speed_ok and angle_ok:
			lbl_status.text = "АВТОПІЛОТ: Ідеальна посадка в центр майданчика! Системи номінальні."
			lbl_status.modulate = ThemeManager.get_accent_emerald()
			GameState.landing_damage = 0.0
			craft_visual.is_landed = true
			craft_visual.landing_compression = 1.0
			SoundManager.play_success()
		elif auto_glitch_type == 0:
			lbl_status.text = "АВТОПІЛОТ: Посадка на схилі через порив вітру. Легке пошкодження опори."
			lbl_status.modulate = ThemeManager.get_accent_cyan()
			GameState.landing_damage = 10.0
			craft_visual.is_landed = true
			craft_visual.landing_compression = 0.9
			SoundManager.play_beep(280.0, 0.3)
		elif auto_glitch_type == 1:
			lbl_status.text = "АВТОПІЛОТ: Жорсткий дотик через збій радара TRN. Пошкоджено амортизатори."
			lbl_status.modulate = ThemeManager.get_accent_amber()
			GameState.landing_damage = 25.0
			craft_visual.is_landed = true
			craft_visual.landing_compression = 1.4
			SoundManager.play_beep(280.0, 0.3)
		else:
			lbl_status.text = "АВТОПІЛОТ: Катастрофа при посадці через відмову паливного клапана EDL!"
			lbl_status.modulate = ThemeManager.get_accent_red()
			GameState.landing_damage = 60.0
			craft_visual.trigger_explosion()
			SoundManager.play_explosion()
			shake_intensity = 18.0
	else:
		if on_pad and speed_ok and angle_ok:
			lbl_status.text = "ІДЕАЛЬНА РУЧНА ПОСАДКА В ЦЕНТР МАЙДАНЧИКА!"
			lbl_status.modulate = ThemeManager.get_accent_emerald()
			GameState.landing_damage = 0.0
			craft_visual.is_landed = true
			craft_visual.landing_compression = 1.0
			SoundManager.play_success()
		elif speed_ok and angle_ok:
			lbl_status.text = "М'яка ручна посадка за межами майданчика (шасі ціле)."
			lbl_status.modulate = ThemeManager.get_accent_cyan()
			GameState.landing_damage = 5.0
			craft_visual.is_landed = true
			craft_visual.landing_compression = 0.8
			SoundManager.play_success()
		elif craft_vel.y <= 55.0 and abs(craft_angle_deg) <= 18.0:
			lbl_status.text = "ЖОРСТКА РУЧНА ПОСАДКА! Пошкодження амортизаторів шасі."
			lbl_status.modulate = ThemeManager.get_accent_amber()
			GameState.landing_damage = 25.0
			craft_visual.is_landed = true
			craft_visual.landing_compression = 1.4
			SoundManager.play_beep(280.0, 0.3)
		else:
			lbl_status.text = "КАТАСТРОФА ПРИ ПОСАДЦІ! Перевищено ліміт швидкості або кута."
			lbl_status.modulate = ThemeManager.get_accent_red()
			GameState.landing_damage = 60.0
			craft_visual.trigger_explosion()
			SoundManager.play_explosion()
			shake_intensity = 18.0

func _on_retry_pressed() -> void:
	SoundManager.play_click()
	craft_pos = Vector2(640, 50)
	craft_vel = Vector2(25, 45)
	craft_angle_deg = 0.0
	craft_ang_vel = 0.0
	fuel_pct = 100.0
	throttle = 0.0
	is_active = true
	is_sim_started = false
	parachute_deployed = false
	btn_chute.disabled = false
	btn_box.visible = false
	craft_visual.is_exploded = false
	craft_visual.is_landed = false
	craft_visual.landing_compression = 0.0
	init_planetary_physics()
	craft_node.position = craft_pos
	lbl_status.text = "Посадкова телеметрія номінальна"
	lbl_status.modulate = ThemeManager.get_accent_emerald()
	mode_dialog.visible = true
	lbl_mode_badge.text = "РЕЖИМ: ОЧІКУВАННЯ ВИБОРУ"
	lbl_mode_badge.modulate = ThemeManager.get_accent_cyan()

func _on_next_pressed() -> void:
	SoundManager.play_click()
	GameState.set_phase("surface")

func apply_theme() -> void:
	hud_panel.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(14, 1))
	mode_dialog.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(18, 2))
	panel_manual.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(12, 1))
	panel_auto.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(12, 1))

	var text_col = ThemeManager.get_text_color()
	var muted_col = ThemeManager.get_muted_color()
	var cyan = ThemeManager.get_accent_cyan()

	lbl_alt.add_theme_color_override("font_color", text_col)
	lbl_vspeed.add_theme_color_override("font_color", text_col)
	lbl_hspeed.add_theme_color_override("font_color", text_col)
	lbl_pitch.add_theme_color_override("font_color", text_col)
	lbl_twr.add_theme_color_override("font_color", text_col)
	lbl_fuel.add_theme_color_override("font_color", text_col)

	var d_title = mode_dialog.get_node_or_null("VBox/LblDialogTitle")
	if d_title:
		d_title.add_theme_color_override("font_color", cyan)
	var d_sub = mode_dialog.get_node_or_null("VBox/LblDialogSub")
	if d_sub:
		d_sub.add_theme_color_override("font_color", muted_col)
	var m_title = panel_manual.get_node_or_null("VBoxM/LblManualTitle")
	if m_title:
		m_title.add_theme_color_override("font_color", text_col)
	var m_desc = panel_manual.get_node_or_null("VBoxM/LblManualDesc")
	if m_desc:
		m_desc.add_theme_color_override("font_color", muted_col)
	var a_title = panel_auto.get_node_or_null("VBoxA/LblAutoTitle")
	if a_title:
		a_title.add_theme_color_override("font_color", text_col)
	var a_desc = panel_auto.get_node_or_null("VBoxA/LblAutoDesc")
	if a_desc:
		a_desc.add_theme_color_override("font_color", muted_col)
