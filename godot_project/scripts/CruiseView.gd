extends Control

@onready var solar_visual = $Content/Center/SolarSystemVisual
@onready var bar_cruise = $BottomPanel/HBoxMain/BarCruise
@onready var lbl_progress = $BottomPanel/HBoxMain/LblProgress
@onready var lbl_telemetry = $Content/LeftTelemetry/VBox/LblTelemetry
@onready var left_telemetry_panel = $Content/LeftTelemetry
@onready var bottom_panel = $BottomPanel
@onready var btn_next = $BottomPanel/HBoxMain/BtnArrival
@onready var event_panel = $EventPopup
@onready var lbl_event_title = $EventPopup/VBox/LblEventTitle
@onready var lbl_event_desc = $EventPopup/VBox/LblEventDesc
@onready var lbl_event_fact = $EventPopup/VBox/LblEventFact
@onready var btn_opt1 = $EventPopup/VBox/HBoxOptions/BtnOpt1
@onready var btn_opt2 = $EventPopup/VBox/HBoxOptions/BtnOpt2

var cruise_progress: float = 0.0
var event_triggered: bool = false
var cruise_speed: float = 0.12
var current_event_id: String = ""

func _ready() -> void:
	btn_next.visible = false
	event_panel.visible = false
	btn_next.pressed.connect(_on_arrival_pressed)
	btn_opt1.pressed.connect(func(): _resolve_event(1))
	btn_opt2.pressed.connect(func(): _resolve_event(2))

	left_telemetry_panel.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(14, 1))
	bottom_panel.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(14, 1))
	event_panel.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(16, 2))

	update_telemetry()

func _process(delta: float) -> void:
	if event_panel.visible:
		return
	if cruise_progress < 1.0:
		cruise_progress += delta * cruise_speed
		solar_visual.transfer_progress = cruise_progress
		bar_cruise.value = cruise_progress * 100.0
		lbl_progress.text = "Прогрес перельоту: %d%%" % [int(cruise_progress * 100.0)]
		update_telemetry()

		if cruise_progress > 0.42 and not event_triggered:
			trigger_random_event()
	else:
		if not btn_next.visible:
			btn_next.visible = true
			SoundManager.play_success()

func update_telemetry() -> void:
	var target = DataManager.get_target(GameState.target_id)
	var sun_au = float(target.get("sun_au", 1.5))
	var cur_dist = lerp(1.0, sun_au, cruise_progress)
	var solar_flux = 1361.0 / (cur_dist * cur_dist)
	var data_rate_val = Calc.data_rate_effective(25.0, cur_dist)

	var t_text = "Телеметрія перельоту:\n\n"
	t_text += "Відстань від Сонця: %.2f а.о.\n" % [cur_dist]
	t_text += "Сонячний потік: %d Вт/м²\n" % [int(solar_flux)]
	t_text += "Швидкість зв'язку DSN: %.1f Мбіт/с\n" % [data_rate_val]
	t_text += "Стан систем борту: НОМІНАЛЬНИЙ\n"
	lbl_telemetry.text = t_text

func trigger_random_event() -> void:
	event_triggered = true
	event_panel.visible = true
	SoundManager.play_beep(440.0, 0.25)

	var ev_options = ["antenna_stuck", "unit_error", "solar_flare", "gyro_drift", "micrometeorite"]
	current_event_id = ev_options[randi() % ev_options.size()]

	match current_event_id:
		"antenna_stuck":
			lbl_event_title.text = "АВАРІЯ У ПОЛЬОТІ: Головна антена HGA не розкрилася"
			lbl_event_desc.text = "Приводи парасолькової антени частково заклинило на 4-й секції. Швидкість каналу впала."
			lbl_event_fact.text = "Це сталося насправді: у 1991 році антена апарата Galileo застрягла. NASA перемкнуло зв'язок на малу всеспрямовану антену і розробило алгоритми стиснення даних на льоту."
			btn_opt1.text = "Перейти на резервну малу антену LGA"
			btn_opt2.text = "Форсувати привід електромотора (Ризик поломки)"
		"unit_error":
			lbl_event_title.text = "НАВІГАЦІЙНА ПОМИЛКА: Розбіжність одиниць виміру"
			lbl_event_desc.text = "Бортовий комп'ютер зафіксував неузгодженість телеметрії імпульсу між фунт-силами та ньютонами."
			lbl_event_fact.text = "Це сталося насправді: у 1999 році Mars Climate Orbiter згорів в атмосфері Марса через те, що одна команда використовувала метричні одиниці, а інша — імперські."
			btn_opt1.text = "Звірити та перекалібрувати за стандартом СІ"
			btn_opt2.text = "Продовжити політ за початковою програмою"
		"solar_flare":
			lbl_event_title.text = "РАДІАЦІЙНИЙ ШТОРМ: Корональний викид маси Сонця"
			lbl_event_desc.text = "Датчики фіксують різкий стрибок високоенергетичних протонів. Ризик збою пам'яті комп'ютера."
			lbl_event_fact.text = "Це сталося насправді: сонячні протонні бурі неодноразово змушували марсіанські зонди переходити в безпечний режим Safe Mode для захисту ПЗЗ-матриць."
			btn_opt1.text = "Безпечний режим Safe Mode на 24 години"
			btn_opt2.text = "Виміряти спектр випромінювання (+30 науки, ризик)"
		"gyro_drift":
			lbl_event_title.text = "СИСТЕМА ОРІЄНТАЦІЇ: Дрейф зоряного датчика"
			lbl_event_desc.text = "Оптичний зоряний трекер втратив орієнтир через відблиск космічного пилу."
			lbl_event_fact.text = "Це сталося насправді: космічні апарати часто використовують гіроскопи та сонячні датчики як резерв при засліпленні зоряних камер."
			btn_opt1.text = "Калібрувати за сузір'ям Центавра"
			btn_opt2.text = "Перейти на резервний сонячний датчик"
		"micrometeorite":
			lbl_event_title.text = "ЗІТКНЕННЯ: Удар мікрометеороїда по корпусу"
			lbl_event_desc.text = "П'єзоелектричний датчик зареєстрував пробиття зовнішнього шару теплоізоляції."
			lbl_event_fact.text = "Це сталося насправді: екран термоізоляції зондів багатошаровий (MLI), саме щоб нейтралізувати удари дрібних частинок міжпланетного пилу."
			btn_opt1.text = "Герметизувати модуль та увімкнути термопідігрів"
			btn_opt2.text = "Просканувати мікротріщину радаром (+15 науки)"

func _resolve_event(choice: int) -> void:
	SoundManager.play_click()
	event_panel.visible = false
	if choice == 2:
		GameState.collected_science += 25.0
		GameState.flight_events_log.append("Ризикований маневр успішний: +25 очок науки!")
	else:
		GameState.flight_events_log.append("Системи захищено за регламентом NASA.")

func _on_arrival_pressed() -> void:
	SoundManager.play_click()
	var platform = DataManager.get_platform(GameState.platform_id)
	var p_type = platform.get("type", "orbiter")
	if p_type == "orbiter":
		GameState.set_phase("surface")
	else:
		GameState.set_phase("landing")
