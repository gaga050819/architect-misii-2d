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
	is_launching = true
	launch_timer = 0.0
	btn_start.disabled = true

func _on_next_pressed() -> void:
	SoundManager.play_click()
	GameState.set_phase("cruise")
