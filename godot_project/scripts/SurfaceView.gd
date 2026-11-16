extends Control

@onready var env_visual = $ViewportContainer/Terrain/SurfaceEnvironmentVisual
@onready var vehicle_node = $ViewportContainer/Terrain/VehicleNode
@onready var probe_visual = $ViewportContainer/Terrain/VehicleNode/ProbeVisual
@onready var fx_visual = $ViewportContainer/Terrain/SamplingFxVisual

@onready var lbl_science = $TopHUD/HBox/LblScience
@onready var lbl_target_hint = $TopHUD/HBox/LblHint
@onready var btn_sample = $Controls/BtnSample
@onready var btn_antenna = $Controls/BtnAntenna
@onready var btn_left = $Controls/BtnDriveLeft
@onready var btn_right = $Controls/BtnDriveRight
@onready var btn_finish = $TopHUD/HBox/BtnFinish

@onready var event_popup = $SurfaceEventPopup
@onready var lbl_ev_title = $SurfaceEventPopup/VBox/LblEventTitle
@onready var lbl_ev_desc = $SurfaceEventPopup/VBox/LblEventDesc
@onready var lbl_ev_fact = $SurfaceEventPopup/VBox/LblEventFact
@onready var btn_opt1 = $SurfaceEventPopup/VBox/HBoxOptions/BtnOpt1
@onready var btn_opt2 = $SurfaceEventPopup/VBox/HBoxOptions/BtnOpt2

var rover_x: float = 200.0
var move_dir: float = 0.0
var total_distance_traveled: float = 0.0
var surface_event_triggered: bool = false
var is_locked_anim: bool = false
var platform_type: String = "rover"

var sample_spots: Array = []

func _ready() -> void:
	btn_finish.pressed.connect(_on_finish_pressed)
	btn_sample.pressed.connect(_on_sample_pressed)
	btn_antenna.pressed.connect(_on_antenna_pressed)

	btn_opt1.pressed.connect(func(): _resolve_surface_event(1))
	btn_opt2.pressed.connect(func(): _resolve_surface_event(2))

	ThemeManager.theme_changed.connect(func(_v): apply_theme())
	apply_theme()

	var platform = DataManager.get_platform(GameState.platform_id)
	platform_type = str(platform.get("type", "rover"))
	if GameState.platform_id == "sampler":
		platform_type = "sampler"

	setup_platform_mode()
	update_hud()

func setup_platform_mode() -> void:
	btn_left.visible = true
	btn_right.visible = true
	btn_sample.visible = true
	btn_antenna.visible = true

	if GameState.target_id == "interstellar":
		env_visual.is_orbit = true
		vehicle_node.position.y = 240.0
		rover_x = 450.0
		vehicle_node.position.x = rover_x
		env_visual.rover_x = rover_x

		btn_left.text = "<- Курс до геліопаузи"
		btn_right.text = "Міжзоряний курс ->"
		btn_sample.text = "Замір плазми і поля"
		btn_antenna.text = "Канал наддалекого DSN"

		btn_left.button_down.connect(func(): move_dir = -1.0)
		btn_left.button_up.connect(func(): move_dir = 0.0)
		btn_left.mouse_exited.connect(func(): move_dir = 0.0)
		btn_left.pressed.connect(func():
			rover_x = clamp(rover_x - 45.0, 80.0, 1200.0)
			vehicle_node.position.x = rover_x
			env_visual.rover_x = rover_x
			total_distance_traveled += 45.0
			check_sample_spots()
		)
		btn_right.button_down.connect(func(): move_dir = 1.0)
		btn_right.button_up.connect(func(): move_dir = 0.0)
		btn_right.mouse_exited.connect(func(): move_dir = 0.0)
		btn_right.pressed.connect(func():
			rover_x = clamp(rover_x + 45.0, 80.0, 1200.0)
			vehicle_node.position.x = rover_x
			env_visual.rover_x = rover_x
			total_distance_traveled += 45.0
			check_sample_spots()
		)

		sample_spots = [
			{"x": 280.0, "y": 420.0, "name": "Ударна хвиля геліопаузи (MAG/PWS)", "method": "scan", "science": 60.0, "taken": false},
			{"x": 580.0, "y": 420.0, "name": "Спектрометрія космічних променів (CRS)", "method": "scan", "science": 65.0, "taken": false},
			{"x": 880.0, "y": 420.0, "name": "Міжзоряне магнітне поле (Fluxgate MAG)", "method": "scan", "science": 70.0, "taken": false},
			{"x": 1100.0, "y": 420.0, "name": "Плазмова щільність за межами геліосфери", "method": "scan", "science": 75.0, "taken": false}
		]
		lbl_target_hint.text = "Глибокий космос: вимірюйте космічні промені, плазму та межу геліосфери!"

	elif platform_type == "orbiter" or platform_type == "sampler":
		env_visual.is_orbit = true
		vehicle_node.position.y = 210.0
		rover_x = 380.0
		vehicle_node.position.x = rover_x
		env_visual.rover_x = rover_x

		btn_left.text = "<- Орбіта Захід"
		btn_right.text = "Орбіта Схід ->"
		btn_sample.text = "Сканувати ціль"
		btn_antenna.text = "Канал зв'язку DSN"

		btn_left.button_down.connect(func(): move_dir = -1.0)
		btn_left.button_up.connect(func(): move_dir = 0.0)
		btn_left.mouse_exited.connect(func(): move_dir = 0.0)
		btn_left.pressed.connect(func():
			rover_x = clamp(rover_x - 45.0, 80.0, 1200.0)
			vehicle_node.position.x = rover_x
			env_visual.rover_x = rover_x
			total_distance_traveled += 45.0
			check_sample_spots()
		)
		btn_right.button_down.connect(func(): move_dir = 1.0)
		btn_right.button_up.connect(func(): move_dir = 0.0)
		btn_right.mouse_exited.connect(func(): move_dir = 0.0)
		btn_right.pressed.connect(func():
			rover_x = clamp(rover_x + 45.0, 80.0, 1200.0)
			vehicle_node.position.x = rover_x
			env_visual.rover_x = rover_x
			total_distance_traveled += 45.0
			check_sample_spots()
		)

		sample_spots = [
			{"x": 380.0, "y": 465.0, "name": "Вулкан Олімп (HiRISE)", "method": "scan", "science": 45.0, "taken": false},
			{"x": 680.0, "y": 485.0, "name": "Каньйон Марінера (CRISM)", "method": "scan", "science": 50.0, "taken": false},
			{"x": 1000.0, "y": 460.0, "name": "Полярна шапка льоду (SHARAD)", "method": "scan", "science": 40.0, "taken": false}
		]
		lbl_target_hint.text = "Орбітальний режим: керуйте маневром для сканування секторів планети"

	elif platform_type == "lander":
		env_visual.is_orbit = false
		vehicle_node.position.y = 494.0
		rover_x = 640.0
		vehicle_node.position.x = rover_x
		env_visual.rover_x = rover_x

		btn_left.text = "Метеостанція"
		btn_sample.text = "Буріння керна"
		btn_right.text = "Сейсмометр SEIS"
		btn_antenna.text = "Канал зв'язку DSN"

		btn_left.pressed.connect(_on_lander_weather_pressed)
		btn_right.pressed.connect(_on_lander_seismic_pressed)

		sample_spots = [
			{"x": 610.0, "y": 540.0, "name": "Ґрунт майданчика посадки", "method": "drill", "science": 45.0, "taken": false},
			{"x": 670.0, "y": 540.0, "name": "Мікроаналіз пилу", "method": "micro", "science": 40.0, "taken": false}
		]
		lbl_target_hint.text = "Посадкова станція: проводьте наукові заміри інструментами"

	else:
		env_visual.is_orbit = false
		vehicle_node.position.y = 507.0
		rover_x = 200.0
		vehicle_node.position.x = rover_x
		env_visual.rover_x = rover_x

		btn_left.text = "<- Рух вліво"
		btn_right.text = "Рух вправо ->"
		btn_sample.text = "Зібрати пробу"
		btn_antenna.text = "Канал зв'язку DSN"

		btn_left.button_down.connect(func(): move_dir = -1.0)
		btn_left.button_up.connect(func(): move_dir = 0.0)
		btn_left.pressed.connect(func():
			rover_x = clamp(rover_x - 45.0, 80.0, 1200.0)
			vehicle_node.position.x = rover_x
			env_visual.rover_x = rover_x
			total_distance_traveled += 45.0
			check_sample_spots()
		)
		btn_right.button_down.connect(func(): move_dir = 1.0)
		btn_right.button_up.connect(func(): move_dir = 0.0)
		btn_right.pressed.connect(func():
			rover_x = clamp(rover_x + 45.0, 80.0, 1200.0)
			vehicle_node.position.x = rover_x
			env_visual.rover_x = rover_x
			total_distance_traveled += 45.0
			check_sample_spots()
		)

		sample_spots = [
			{"x": 290.0, "y": 540.0, "name": "Георадарне зондування", "method": "gpr", "science": 35.0, "taken": false},
			{"x": 425.0, "y": 538.0, "name": "Базальтова скеля", "method": "laser", "science": 35.0, "taken": false},
			{"x": 620.0, "y": 538.0, "name": "Мікроструктура реголіту", "method": "micro", "science": 40.0, "taken": false},
			{"x": 755.0, "y": 536.0, "name": "Кратерне оголення", "method": "drill", "science": 45.0, "taken": false},
			{"x": 1055.0, "y": 537.0, "name": "Глинисті відклади", "method": "scoop", "science": 50.0, "taken": false}
		]
		lbl_target_hint.text = "Керуйте стрілками або кнопками для пошуку точок досліджень"

func _process(delta: float) -> void:
	if event_popup.visible or is_locked_anim:
		return

	if platform_type != "lander":
		var dx = 0.0
		var speed = 145.0 if (platform_type == "orbiter" or platform_type == "sampler") else 115.0
		if Input.is_action_pressed("ui_left") or move_dir < 0.0:
			dx = -delta * speed
		elif Input.is_action_pressed("ui_right") or move_dir > 0.0:
			dx = delta * speed

		if abs(dx) > 0.0:
			rover_x += dx
			rover_x = clamp(rover_x, 80.0, 1200.0)
			vehicle_node.position.x = rover_x
			env_visual.rover_x = rover_x
			total_distance_traveled += abs(dx)

	check_sample_spots()

	if total_distance_traveled > 260.0 and not surface_event_triggered:
		trigger_surface_breakdown()

func check_sample_spots() -> void:
	var near_spot = null
	var threshold = 85.0 if (platform_type == "orbiter" or platform_type == "sampler") else 65.0

	for spot in sample_spots:
		if not spot["taken"] and abs(rover_x - spot["x"]) < threshold:
			near_spot = spot
			break

	if near_spot:
		btn_sample.disabled = false
		btn_sample.modulate = ThemeManager.get_accent_emerald()
		lbl_target_hint.text = "Ціль у фокусі: " + near_spot["name"] + " (Натисніть '" + btn_sample.text + "')"
	else:
		btn_sample.disabled = true
		btn_sample.modulate = Color(0.65, 0.65, 0.65, 0.6)
		if platform_type == "orbiter" or platform_type == "sampler":
			lbl_target_hint.text = "Керуйте орбітою (Захід/Схід) для виходу на сектори зйомки"
		elif platform_type == "lander":
			lbl_target_hint.text = "Стаціонарна станція: проведіть усі заплановані дослідження"
		else:
			lbl_target_hint.text = "Керуйте стрілками або кнопками для пошуку точок досліджень"

func _on_sample_pressed() -> void:
	var threshold = 85.0 if (platform_type == "orbiter" or platform_type == "sampler") else 65.0
	for spot in sample_spots:
		if not spot["taken"] and abs(rover_x - spot["x"]) < threshold:
			spot["taken"] = true
			is_locked_anim = true
			var method = spot["method"]
			var target_pt = Vector2(spot["x"], spot.get("y", 540.0))
			var origin_pt: Vector2
			if platform_type == "lander":
				origin_pt = vehicle_node.position + Vector2(-22.0, 10.0)
			elif platform_type == "orbiter" or platform_type == "sampler":
				origin_pt = vehicle_node.position + Vector2(0.0, 15.0)
			else:
				var is_facing_left = target_pt.x < vehicle_node.position.x
				var arm_side = -1.0 if is_facing_left else 1.0
				if method == "laser":
					origin_pt = vehicle_node.position + Vector2(arm_side * 18.0, -38.0)
				else:
					origin_pt = vehicle_node.position + Vector2(arm_side * 28.0, 14.0)

			if method == "scan":
				fx_visual.start_orbital_scan(origin_pt, target_pt)
				SoundManager.play_laser()
				lbl_target_hint.text = "Орбітальний сканер: спектральний аналіз та картографування сектору..."
			elif method == "laser":
				fx_visual.start_laser(origin_pt, target_pt)
				SoundManager.play_laser()
				lbl_target_hint.text = "Лазерна абляція: випаровування породи та спектральний аналіз..."
			elif method == "drill":
				fx_visual.start_drill(origin_pt, target_pt)
				SoundManager.play_drill()
				lbl_target_hint.text = "Алмазне буріння: забір керна породи в герметичний контейнер..."
			elif method == "micro":
				fx_visual.start_microscopic(origin_pt, target_pt)
				SoundManager.play_click()
				lbl_target_hint.text = "Мікроскопічний аналіз: фотографування структури породи на рівні мкм..."
			elif method == "gpr":
				fx_visual.start_gpr(origin_pt, target_pt)
				SoundManager.play_radio_chirp()
				lbl_target_hint.text = "Підповерхневий георадар: імпульсне зондування шарів ґрунту..."
			else:
				fx_visual.start_scoop(origin_pt, target_pt)
				SoundManager.play_click()
				lbl_target_hint.text = "Маніпулятор-ківш: забір пухкого реголіту та скидання в камеру аналізу..."

			var timer = get_tree().create_timer(2.8)
			timer.timeout.connect(func():
				is_locked_anim = false
				GameState.collected_science += spot["science"]
				SoundManager.play_success()
				update_hud()
				check_sample_spots()
				trigger_auto_antenna_pulse()
			)
			break

func _on_lander_weather_pressed() -> void:
	if is_locked_anim:
		return
	is_locked_anim = true
	SoundManager.play_click()
	lbl_target_hint.text = "Метеостанція: вимірювання тиску, температури та швидкості вітру..."
	var timer = get_tree().create_timer(1.8)
	timer.timeout.connect(func():
		is_locked_anim = false
		GameState.collected_science += 25.0
		SoundManager.play_success()
		update_hud()
		btn_left.disabled = true
		btn_left.modulate = Color(0.6, 0.6, 0.6, 0.6)
		trigger_auto_antenna_pulse()
	)

func _on_lander_seismic_pressed() -> void:
	if is_locked_anim:
		return
	is_locked_anim = true
	SoundManager.play_beep(280.0, 0.4)
	lbl_target_hint.text = "Сейсмометр SEIS: реєстрація мікросейсмічних коливань літосфери..."
	var timer = get_tree().create_timer(1.8)
	timer.timeout.connect(func():
		is_locked_anim = false
		GameState.collected_science += 35.0
		SoundManager.play_success()
		update_hud()
		btn_right.disabled = true
		btn_right.modulate = Color(0.6, 0.6, 0.6, 0.6)
		trigger_auto_antenna_pulse()
	)

func trigger_auto_antenna_pulse() -> void:
	var dish_pt = vehicle_node.position + Vector2(0, -45)
	fx_visual.start_antenna(dish_pt)
	SoundManager.play_radio_chirp()
	lbl_target_hint.text = "ПЕРЕДАЧА ДАНИХ (DSN): Хвилі сигналу надіслано на Землю!"

func _on_antenna_pressed() -> void:
	trigger_auto_antenna_pulse()

func trigger_surface_breakdown() -> void:
	surface_event_triggered = true
	event_popup.visible = true
	SoundManager.play_beep(380.0, 0.3)

	var ev_type = randi() % 3
	if ev_type == 0:
		lbl_ev_title.text = "АВАРІЯ СИСТЕМИ: Перегрів бортового комп'ютера"
		lbl_ev_desc.text = "Сонячна радіація спричинила термічний стрибок температури процесора до 78°C."
		lbl_ev_fact.text = "Це сталося насправді: зонд Magellan біля Венери регулярно розвертав панелі для терморегуляції в тіні."
		btn_opt1.text = "Розвернути радіатор охолодження"
		btn_opt2.text = "Форсувати обчислення (+20 науки, ризик)"
	elif ev_type == 1:
		lbl_ev_title.text = "ПОГОДНА АНОМАЛІЯ: Сезонна пилова буря"
		lbl_ev_desc.text = "Атмосферний фронт підняв хмару піску, зменшивши інсоляцію сонячних батарей на 75%."
		lbl_ev_fact.text = "Це сталося насправді: у 2018 році глобальна пилова буря знеструмила сонячні панелі марсохода Opportunity."
		btn_opt1.text = "Сплячий режим на 48 годин (Зберегти батареї)"
		btn_opt2.text = "Продовжити заміри пилу (+25 науки, ризик)"
	else:
		lbl_ev_title.text = "ПРИЛАДОВА АНОМАЛІЯ: Збій орієнтації дзеркала"
		lbl_ev_desc.text = "Привід спектрометра зафіксував мікролюфт оптичної системи."
		lbl_ev_fact.text = "Це сталося насправді: космічний телескоп Хаббл успішно компенсував збої гіроскопів програмними алгоритмами."
		btn_opt1.text = "Провести автокалібрування"
		btn_opt2.text = "Використати резервний сенсор"

func _resolve_surface_event(choice: int) -> void:
	SoundManager.play_click()
	event_popup.visible = false
	if choice == 2:
		GameState.collected_science += 20.0
		lbl_target_hint.text = "Ризик виправдався: отримано +20 очок науки!"
	else:
		lbl_target_hint.text = "Безпечне рішення виконано: системи стабільні."
	update_hud()

func update_hud() -> void:
	var total = int(GameState.collected_science)
	lbl_science.text = "Зібрано науки: %d очок" % [total]

func _on_finish_pressed() -> void:
	SoundManager.play_click()
	GameState.set_phase("debrief")

func apply_theme() -> void:
	event_popup.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(16, 2))
	var top_hud = get_node_or_null("TopHUD")
	if top_hud:
		top_hud.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(12, 1))

	var text_col = ThemeManager.get_text_color()
	var muted_col = ThemeManager.get_muted_color()
	var emerald = ThemeManager.get_accent_emerald()
	var amber = ThemeManager.get_accent_amber()

	lbl_science.add_theme_color_override("font_color", emerald)
	lbl_target_hint.add_theme_color_override("font_color", amber)
	lbl_ev_title.add_theme_color_override("font_color", amber)
	lbl_ev_desc.add_theme_color_override("font_color", text_col)
	lbl_ev_fact.add_theme_color_override("font_color", muted_col)
