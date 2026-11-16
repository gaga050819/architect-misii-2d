extends Control

@onready var solar_visual = $Content/Center/SolarSystemVisual
@onready var left_telemetry_panel = $Content/LeftTelemetry
@onready var right_status_panel = $Content/RightStatusPanel
@onready var bottom_panel = $BottomPanel
@onready var event_panel = $EventPopup

@onready var lbl_sun_dist = $Content/LeftTelemetry/VBox/HBoxSunDist/LblSunDist
@onready var bar_sun_dist = $Content/LeftTelemetry/VBox/BarSunDist
@onready var lbl_distance_traveled = $Content/LeftTelemetry/VBox/HBoxTraveled/LblDistanceTraveled
@onready var lbl_speed = $Content/LeftTelemetry/VBox/HBoxSpeed/LblSpeed
@onready var lbl_light_delay = $Content/LeftTelemetry/VBox/HBoxDelay/LblLightDelay
@onready var lbl_solar_flux = $Content/LeftTelemetry/VBox/HBoxFlux/LblSolarFlux
@onready var lbl_power_gen = $Content/LeftTelemetry/VBox/HBoxPower/LblPowerGen
@onready var lbl_battery = $Content/LeftTelemetry/VBox/HBoxBattery/LblBattery
@onready var lbl_bitrate = $Content/LeftTelemetry/VBox/HBoxRate/LblBitrate
@onready var lbl_signal_dbm = $Content/LeftTelemetry/VBox/HBoxSignal/LblSignalDbm
@onready var lbl_data_sent = $Content/LeftTelemetry/VBox/HBoxPackets/LblDataSent

@onready var lbl_craft_type = $Content/RightStatusPanel/VBox/HBoxHeader/LblCraftType
@onready var lbl_craft_name = $Content/RightStatusPanel/VBox/LblCraftName
@onready var lbl_m1 = $Content/RightStatusPanel/VBox/VBoxMilestones/LblM1
@onready var lbl_m2 = $Content/RightStatusPanel/VBox/VBoxMilestones/LblM2
@onready var lbl_m3 = $Content/RightStatusPanel/VBox/VBoxMilestones/LblM3
@onready var lbl_m4 = $Content/RightStatusPanel/VBox/VBoxMilestones/LblM4
@onready var lbl_m5 = $Content/RightStatusPanel/VBox/VBoxMilestones/LblM5
@onready var lbl_m6 = $Content/RightStatusPanel/VBox/VBoxMilestones/LblM6

@onready var lbl_mission_time = $BottomPanel/HBoxMain/LblMissionTime
@onready var bar_cruise = $BottomPanel/HBoxMain/BarCruise
@onready var btn_next = $BottomPanel/HBoxMain/BtnArrival
@onready var btn_speed1x = $BottomPanel/HBoxMain/HBoxControls/BtnSpeed1x
@onready var btn_speed2x = $BottomPanel/HBoxMain/HBoxControls/BtnSpeed2x
@onready var btn_speed4x = $BottomPanel/HBoxMain/HBoxControls/BtnSpeed4x

@onready var lbl_event_title = $EventPopup/VBox/LblEventTitle
@onready var lbl_event_desc = $EventPopup/VBox/LblEventDesc
@onready var lbl_event_fact = $EventPopup/VBox/LblEventFact
@onready var btn_opt1 = $EventPopup/VBox/HBoxOptions/BtnOpt1
@onready var btn_opt2 = $EventPopup/VBox/HBoxOptions/BtnOpt2

var cruise_progress: float = 0.0
var event_triggered: bool = false
var base_cruise_speed: float = 0.07
var speed_multiplier: float = 1.0
var current_event_id: String = ""
var total_flight_days: int = 210
var total_distance_mkm: float = 225.0
var target_sun_au: float = 1.524
var craft_name_str: String = "Mars Scout"

func _ready() -> void:
	btn_next.visible = false
	event_panel.visible = false
	btn_next.pressed.connect(_on_arrival_pressed)
	btn_opt1.pressed.connect(func(): _resolve_event(1))
	btn_opt2.pressed.connect(func(): _resolve_event(2))

	btn_speed1x.pressed.connect(func(): _set_speed(1.0))
	btn_speed2x.pressed.connect(func(): _set_speed(2.0))
	btn_speed4x.pressed.connect(func(): _set_speed(4.0))
	_update_speed_buttons()

	ThemeManager.theme_changed.connect(func(_v): apply_theme())
	apply_theme()

	var target = DataManager.get_target(GameState.target_id)
	total_flight_days = int(target.get("flight_days", 210))
	target_sun_au = float(target.get("sun_au", 1.524))
	total_distance_mkm = max(1.0, abs(target_sun_au - 1.0) * 149.6 + 65.0)

	var platform = DataManager.get_platform(GameState.platform_id)
	var p_type = str(platform.get("type", "orbiter")).to_upper()
	lbl_craft_type.text = p_type
	var t_name = DataManager.get_localized(target.get("name"), "Марс")
	var p_name = DataManager.get_localized(platform.get("name"), "Апарат")
	craft_name_str = "%s (%s)" % [p_name, t_name]
	lbl_craft_name.text = craft_name_str

	bar_sun_dist.min_value = min(1.0, target_sun_au)
	bar_sun_dist.max_value = max(1.0, target_sun_au)

	update_telemetry()

func _set_speed(mult: float) -> void:
	SoundManager.play_click()
	speed_multiplier = mult
	_update_speed_buttons()

func _update_speed_buttons() -> void:
	var active_color = ThemeManager.get_accent_cyan()
	var dim_color = Color(0.65, 0.75, 0.88, 0.6)
	btn_speed1x.modulate = active_color if speed_multiplier == 1.0 else dim_color
	btn_speed2x.modulate = active_color if speed_multiplier == 2.0 else dim_color
	btn_speed4x.modulate = active_color if speed_multiplier == 4.0 else dim_color

func _process(delta: float) -> void:
	if event_panel.visible:
		return
	if cruise_progress < 1.0:
		cruise_progress += delta * base_cruise_speed * speed_multiplier
		cruise_progress = min(1.0, cruise_progress)
		solar_visual.transfer_progress = cruise_progress
		bar_cruise.value = cruise_progress * 100.0

		var elapsed_days = int(cruise_progress * total_flight_days)
		lbl_mission_time.text = "Місійний час: T+ %d діб (з %d)" % [elapsed_days, total_flight_days]

		update_telemetry()
		update_milestones()

		if cruise_progress > 0.42 and not event_triggered:
			trigger_random_event()
	else:
		if not btn_next.visible:
			btn_next.visible = true
			SoundManager.play_success()

func update_telemetry() -> void:
	var cur_dist = lerp(1.0, target_sun_au, cruise_progress)
	lbl_sun_dist.text = "%.2f а.о." % cur_dist
	bar_sun_dist.value = cur_dist

	var dist_traveled = cruise_progress * total_distance_mkm
	lbl_distance_traveled.text = "%.1f млн км з %.1f" % [dist_traveled, total_distance_mkm]

	var helio_speed = lerp(32.7, 21.8, cruise_progress)
	lbl_speed.text = "%.1f км/с" % helio_speed

	var dist_earth_au = max(0.02, cruise_progress * abs(target_sun_au - 1.0) + 0.1)
	var light_sec = dist_earth_au * 499.0
	var l_min = int(light_sec / 60.0)
	var l_sec = int(light_sec) % 60
	lbl_light_delay.text = "%d хв %02d с" % [l_min, l_sec]

	var solar_flux = 1361.0 / (cur_dist * cur_dist)
	lbl_solar_flux.text = "%d Вт/м²" % int(solar_flux)

	var power_item = DataManager.get_power(GameState.power_id)
	var is_rtg = str(power_item.get("type", "solar")) == "rtg"
	var p_gen = 0.0
	if is_rtg:
		p_gen = float(power_item.get("p0_w", 110.0))
	else:
		var p1 = float(power_item.get("p1au_w", 760.0))
		p_gen = p1 * (1.0 / (cur_dist * cur_dist))
	lbl_power_gen.text = "%d Вт" % int(p_gen)

	var ant_item = DataManager.get_antenna(GameState.antenna_id)
	var rate_1au = float(ant_item.get("rate_1au_mbps", 15.0))
	var eff_rate = Calc.data_rate_effective(rate_1au, dist_earth_au)
	lbl_bitrate.text = "%.1f Мбіт/с" % eff_rate

	var sig_dbm = lerp(-115.0, -137.0, cruise_progress)
	lbl_signal_dbm.text = "%.0f dBm [СТАБІЛЬНИЙ]" % sig_dbm

	var sent_mbit = int(cruise_progress * 18450.0)
	lbl_data_sent.text = "%d Мбіт" % sent_mbit

func update_milestones() -> void:
	var emerald = ThemeManager.get_accent_emerald()
	var muted = ThemeManager.get_muted_color()

	lbl_m1.text = "[V] T+0d  Старт і відліт від Землі"
	lbl_m1.modulate = emerald

	lbl_m2.text = "[V] T+2d  Розгортання сонячних крил"
	lbl_m2.modulate = emerald

	if cruise_progress >= 0.25:
		lbl_m3.text = "[V] T+45d Траєкторна корекція ТКМ-1"
		lbl_m3.modulate = emerald
	else:
		lbl_m3.text = "[...] T+45d Траєкторна корекція ТКМ-1"
		lbl_m3.modulate = muted

	if cruise_progress >= 0.50:
		lbl_m4.text = "[V] T+110d Середина міжпланетного шляху"
		lbl_m4.modulate = emerald
	else:
		lbl_m4.text = "[...] T+110d Середина міжпланетного шляху"
		lbl_m4.modulate = muted

	if cruise_progress >= 0.75:
		lbl_m5.text = "[V] T+185d Траєкторна корекція ТКМ-2"
		lbl_m5.modulate = emerald
	else:
		lbl_m5.text = "[...] T+185d Траєкторна корекція ТКМ-2"
		lbl_m5.modulate = muted

	if cruise_progress >= 0.98:
		lbl_m6.text = "[V] T+210d Захоплення орбіти цілі"
		lbl_m6.modulate = emerald
	else:
		lbl_m6.text = "[...] T+210d Захоплення орбіти цілі"
		lbl_m6.modulate = muted

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

func apply_theme() -> void:
	left_telemetry_panel.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(14, 1))
	right_status_panel.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(14, 1))
	bottom_panel.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(14, 1))
	event_panel.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(16, 2))

	var text_col = ThemeManager.get_text_color()
	var muted_col = ThemeManager.get_muted_color()
	var cyan = ThemeManager.get_accent_cyan()

	for lbl in left_telemetry_panel.find_children("*", "Label", true, false):
		var l = lbl as Label
		if l.name.begins_with("Sep"):
			l.add_theme_color_override("font_color", cyan)
		elif l.name in ["LblSunDist", "LblDistanceTraveled", "LblSpeed", "LblLightDelay", "LblSolarFlux", "LblPowerGen", "LblBattery", "LblBitrate", "LblSignalDbm", "LblDataSent"]:
			l.add_theme_color_override("font_color", text_col)
		else:
			l.add_theme_color_override("font_color", muted_col)

	lbl_craft_type.add_theme_color_override("font_color", cyan)
	lbl_craft_name.add_theme_color_override("font_color", text_col)
	for m_lbl in [lbl_m1, lbl_m2, lbl_m3, lbl_m4, lbl_m5, lbl_m6]:
		if m_lbl:
			m_lbl.add_theme_color_override("font_color", muted_col)

	lbl_event_title.add_theme_color_override("font_color", ThemeManager.get_accent_amber())
	lbl_event_desc.add_theme_color_override("font_color", text_col)
	lbl_event_fact.add_theme_color_override("font_color", muted_col)
	lbl_mission_time.add_theme_color_override("font_color", text_col)
	_update_speed_buttons()
