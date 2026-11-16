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

		btn_left.text = "<- РљСѓСЂСЃ РґРѕ РіРµР»С–РѕРїР°СѓР·Рё"
		btn_right.text = "РњС–Р¶Р·РѕСЂСЏРЅРёР№ РєСѓСЂСЃ ->"
		btn_sample.text = "Р—Р°РјС–СЂ РїР»Р°Р·РјРё С– РїРѕР»СЏ"
		btn_antenna.text = "РљР°РЅР°Р» РЅР°РґРґР°Р»РµРєРѕРіРѕ DSN"

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
			{"x": 280.0, "y": 420.0, "name": "РЈРґР°СЂРЅР° С…РІРёР»СЏ РіРµР»С–РѕРїР°СѓР·Рё (MAG/PWS)", "method": "scan", "science": 60.0, "taken": false},
			{"x": 580.0, "y": 420.0, "name": "РЎРїРµРєС‚СЂРѕРјРµС‚СЂС–СЏ РєРѕСЃРјС–С‡РЅРёС… РїСЂРѕРјРµРЅС–РІ (CRS)", "method": "scan", "science": 65.0, "taken": false},
			{"x": 880.0, "y": 420.0, "name": "РњС–Р¶Р·РѕСЂСЏРЅРµ РјР°РіРЅС–С‚РЅРµ РїРѕР»Рµ (Fluxgate MAG)", "method": "scan", "science": 70.0, "taken": false},
			{"x": 1100.0, "y": 420.0, "name": "РџР»Р°Р·РјРѕРІР° С‰С–Р»СЊРЅС–СЃС‚СЊ Р·Р° РјРµР¶Р°РјРё РіРµР»С–РѕСЃС„РµСЂРё", "method": "scan", "science": 75.0, "taken": false}
		]
		lbl_target_hint.text = "Р“Р»РёР±РѕРєРёР№ РєРѕСЃРјРѕСЃ: РІРёРјС–СЂСЋР№С‚Рµ РєРѕСЃРјС–С‡РЅС– РїСЂРѕРјРµРЅС–, РїР»Р°Р·РјСѓ С‚Р° РјРµР¶Сѓ РіРµР»С–РѕСЃС„РµСЂРё!"

	elif platform_type == "orbiter" or platform_type == "sampler":
		env_visual.is_orbit = true
		vehicle_node.position.y = 210.0
		rover_x = 380.0
		vehicle_node.position.x = rover_x
		env_visual.rover_x = rover_x

		btn_left.text = "<- РћСЂР±С–С‚Р° Р—Р°С…С–Рґ"
		btn_right.text = "РћСЂР±С–С‚Р° РЎС…С–Рґ ->"
		btn_sample.text = "РЎРєР°РЅСѓРІР°С‚Рё С†С–Р»СЊ"
		btn_antenna.text = "РљР°РЅР°Р» Р·РІ'СЏР·РєСѓ DSN"

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
			{"x": 380.0, "y": 465.0, "name": "Р’СѓР»РєР°РЅ РћР»С–РјРї (HiRISE)", "method": "scan", "science": 45.0, "taken": false},
			{"x": 680.0, "y": 485.0, "name": "РљР°РЅСЊР№РѕРЅ РњР°СЂС–РЅРµСЂР° (CRISM)", "method": "scan", "science": 50.0, "taken": false},
			{"x": 1000.0, "y": 460.0, "name": "РџРѕР»СЏСЂРЅР° С€Р°РїРєР° Р»СЊРѕРґСѓ (SHARAD)", "method": "scan", "science": 40.0, "taken": false}
		]
		lbl_target_hint.text = "РћСЂР±С–С‚Р°Р»СЊРЅРёР№ СЂРµР¶РёРј: РєРµСЂСѓР№С‚Рµ РјР°РЅРµРІСЂРѕРј РґР»СЏ СЃРєР°РЅСѓРІР°РЅРЅСЏ СЃРµРєС‚РѕСЂС–РІ РїР»Р°РЅРµС‚Рё"

	elif platform_type == "lander":
		env_visual.is_orbit = false
		vehicle_node.position.y = 494.0
		rover_x = 640.0
		vehicle_node.position.x = rover_x
		env_visual.rover_x = rover_x

		btn_left.text = "РњРµС‚РµРѕСЃС‚Р°РЅС†С–СЏ"
		btn_sample.text = "Р‘СѓСЂС–РЅРЅСЏ РєРµСЂРЅР°"
		btn_right.text = "РЎРµР№СЃРјРѕРјРµС‚СЂ SEIS"
		btn_antenna.text = "РљР°РЅР°Р» Р·РІ'СЏР·РєСѓ DSN"

		btn_left.pressed.connect(_on_lander_weather_pressed)
		btn_right.pressed.connect(_on_lander_seismic_pressed)

		sample_spots = [
			{"x": 610.0, "y": 540.0, "name": "ТђСЂСѓРЅС‚ РјР°Р№РґР°РЅС‡РёРєР° РїРѕСЃР°РґРєРё", "method": "drill", "science": 45.0, "taken": false},
			{"x": 670.0, "y": 540.0, "name": "РњС–РєСЂРѕР°РЅР°Р»С–Р· РїРёР»Сѓ", "method": "micro", "science": 40.0, "taken": false}
		]
		lbl_target_hint.text = "РџРѕСЃР°РґРєРѕРІР° СЃС‚Р°РЅС†С–СЏ: РїСЂРѕРІРѕРґСЊС‚Рµ РЅР°СѓРєРѕРІС– Р·Р°РјС–СЂРё С–РЅСЃС‚СЂСѓРјРµРЅС‚Р°РјРё"

	else:
		env_visual.is_orbit = false
		vehicle_node.position.y = 466.0
		rover_x = 200.0
		vehicle_node.position.x = rover_x
		env_visual.rover_x = rover_x

		btn_left.text = "<- Р СѓС… РІР»С–РІРѕ"
		btn_right.text = "Р СѓС… РІРїСЂР°РІРѕ ->"
		btn_sample.text = "Р—С–Р±СЂР°С‚Рё РїСЂРѕР±Сѓ"
		btn_antenna.text = "РљР°РЅР°Р» Р·РІ'СЏР·РєСѓ DSN"

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
			{"x": 290.0, "y": 540.0, "name": "Р“РµРѕСЂР°РґР°СЂРЅРµ Р·РѕРЅРґСѓРІР°РЅРЅСЏ", "method": "gpr", "science": 35.0, "taken": false},
			{"x": 425.0, "y": 538.0, "name": "Р‘Р°Р·Р°Р»СЊС‚РѕРІР° СЃРєРµР»СЏ", "method": "laser", "science": 35.0, "taken": false},
			{"x": 620.0, "y": 538.0, "name": "РњС–РєСЂРѕСЃС‚СЂСѓРєС‚СѓСЂР° СЂРµРіРѕР»С–С‚Сѓ", "method": "micro", "science": 40.0, "taken": false},
			{"x": 755.0, "y": 536.0, "name": "РљСЂР°С‚РµСЂРЅРµ РѕРіРѕР»РµРЅРЅСЏ", "method": "drill", "science": 45.0, "taken": false},
			{"x": 1055.0, "y": 537.0, "name": "Р“Р»РёРЅРёСЃС‚С– РІС–РґРєР»Р°РґРё", "method": "scoop", "science": 50.0, "taken": false}
		]
		lbl_target_hint.text = "РљРµСЂСѓР№С‚Рµ СЃС‚СЂС–Р»РєР°РјРё Р°Р±Рѕ РєРЅРѕРїРєР°РјРё РґР»СЏ РїРѕС€СѓРєСѓ С‚РѕС‡РѕРє РґРѕСЃР»С–РґР¶РµРЅСЊ"

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
		lbl_target_hint.text = "Р¦С–Р»СЊ Сѓ С„РѕРєСѓСЃС–: " + near_spot["name"] + " (РќР°С‚РёСЃРЅС–С‚СЊ '" + btn_sample.text + "')"
	else:
		btn_sample.disabled = true
		btn_sample.modulate = Color(0.65, 0.65, 0.65, 0.6)
		if platform_type == "orbiter" or platform_type == "sampler":
			lbl_target_hint.text = "РљРµСЂСѓР№С‚Рµ РѕСЂР±С–С‚РѕСЋ (Р—Р°С…С–Рґ/РЎС…С–Рґ) РґР»СЏ РІРёС…РѕРґСѓ РЅР° СЃРµРєС‚РѕСЂРё Р·Р№РѕРјРєРё"
		elif platform_type == "lander":
			lbl_target_hint.text = "РЎС‚Р°С†С–РѕРЅР°СЂРЅР° СЃС‚Р°РЅС†С–СЏ: РїСЂРѕРІРµРґС–С‚СЊ СѓСЃС– Р·Р°РїР»Р°РЅРѕРІР°РЅС– РґРѕСЃР»С–РґР¶РµРЅРЅСЏ"
		else:
			lbl_target_hint.text = "РљРµСЂСѓР№С‚Рµ СЃС‚СЂС–Р»РєР°РјРё Р°Р±Рѕ РєРЅРѕРїРєР°РјРё РґР»СЏ РїРѕС€СѓРєСѓ С‚РѕС‡РѕРє РґРѕСЃР»С–РґР¶РµРЅСЊ"

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
						origin_pt = vehicle_node.position + Vector2(arm_side * 20.0, -18.0)
				else:
						origin_pt = vehicle_node.position + Vector2(arm_side * 30.0, 30.0)

			if method == "scan":
				fx_visual.start_orbital_scan(origin_pt, target_pt)
				SoundManager.play_laser()
				lbl_target_hint.text = "РћСЂР±С–С‚Р°Р»СЊРЅРёР№ СЃРєР°РЅРµСЂ: СЃРїРµРєС‚СЂР°Р»СЊРЅРёР№ Р°РЅР°Р»С–Р· С‚Р° РєР°СЂС‚РѕРіСЂР°С„СѓРІР°РЅРЅСЏ СЃРµРєС‚РѕСЂСѓ..."
			elif method == "laser":
				fx_visual.start_laser(origin_pt, target_pt)
				SoundManager.play_laser()
				lbl_target_hint.text = "Р›Р°Р·РµСЂРЅР° Р°Р±Р»СЏС†С–СЏ: РІРёРїР°СЂРѕРІСѓРІР°РЅРЅСЏ РїРѕСЂРѕРґРё С‚Р° СЃРїРµРєС‚СЂР°Р»СЊРЅРёР№ Р°РЅР°Р»С–Р·..."
			elif method == "drill":
				fx_visual.start_drill(origin_pt, target_pt)
				SoundManager.play_drill()
				lbl_target_hint.text = "РђР»РјР°Р·РЅРµ Р±СѓСЂС–РЅРЅСЏ: Р·Р°Р±С–СЂ РєРµСЂРЅР° РїРѕСЂРѕРґРё РІ РіРµСЂРјРµС‚РёС‡РЅРёР№ РєРѕРЅС‚РµР№РЅРµСЂ..."
			elif method == "micro":
				fx_visual.start_microscopic(origin_pt, target_pt)
				SoundManager.play_click()
				lbl_target_hint.text = "РњС–РєСЂРѕСЃРєРѕРїС–С‡РЅРёР№ Р°РЅР°Р»С–Р·: С„РѕС‚РѕРіСЂР°С„СѓРІР°РЅРЅСЏ СЃС‚СЂСѓРєС‚СѓСЂРё РїРѕСЂРѕРґРё РЅР° СЂС–РІРЅС– РјРєРј..."
			elif method == "gpr":
				fx_visual.start_gpr(origin_pt, target_pt)
				SoundManager.play_radio_chirp()
				lbl_target_hint.text = "РџС–РґРїРѕРІРµСЂС…РЅРµРІРёР№ РіРµРѕСЂР°РґР°СЂ: С–РјРїСѓР»СЊСЃРЅРµ Р·РѕРЅРґСѓРІР°РЅРЅСЏ С€Р°СЂС–РІ Т‘СЂСѓРЅС‚Сѓ..."
			else:
				fx_visual.start_scoop(origin_pt, target_pt)
				SoundManager.play_click()
				lbl_target_hint.text = "РњР°РЅС–РїСѓР»СЏС‚РѕСЂ-РєС–РІС€: Р·Р°Р±С–СЂ РїСѓС…РєРѕРіРѕ СЂРµРіРѕР»С–С‚Сѓ С‚Р° СЃРєРёРґР°РЅРЅСЏ РІ РєР°РјРµСЂСѓ Р°РЅР°Р»С–Р·Сѓ..."

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
	lbl_target_hint.text = "РњРµС‚РµРѕСЃС‚Р°РЅС†С–СЏ: РІРёРјС–СЂСЋРІР°РЅРЅСЏ С‚РёСЃРєСѓ, С‚РµРјРїРµСЂР°С‚СѓСЂРё С‚Р° С€РІРёРґРєРѕСЃС‚С– РІС–С‚СЂСѓ..."
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
	lbl_target_hint.text = "РЎРµР№СЃРјРѕРјРµС‚СЂ SEIS: СЂРµС”СЃС‚СЂР°С†С–СЏ РјС–РєСЂРѕСЃРµР№СЃРјС–С‡РЅРёС… РєРѕР»РёРІР°РЅСЊ Р»С–С‚РѕСЃС„РµСЂРё..."
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
	lbl_target_hint.text = "РџР•Р Р•Р”РђР§Рђ Р”РђРќРРҐ (DSN): РҐРІРёР»С– СЃРёРіРЅР°Р»Сѓ РЅР°РґС–СЃР»Р°РЅРѕ РЅР° Р—РµРјР»СЋ!"

func _on_antenna_pressed() -> void:
	trigger_auto_antenna_pulse()

func trigger_surface_breakdown() -> void:
	surface_event_triggered = true
	event_popup.visible = true
	SoundManager.play_beep(380.0, 0.3)

	var ev_type = randi() % 3
	if ev_type == 0:
		lbl_ev_title.text = "РђР’РђР Р†РЇ РЎРРЎРўР•РњР: РџРµСЂРµРіСЂС–РІ Р±РѕСЂС‚РѕРІРѕРіРѕ РєРѕРјРї'СЋС‚РµСЂР°"
		lbl_ev_desc.text = "РЎРѕРЅСЏС‡РЅР° СЂР°РґС–Р°С†С–СЏ СЃРїСЂРёС‡РёРЅРёР»Р° С‚РµСЂРјС–С‡РЅРёР№ СЃС‚СЂРёР±РѕРє С‚РµРјРїРµСЂР°С‚СѓСЂРё РїСЂРѕС†РµСЃРѕСЂР° РґРѕ 78В°C."
		lbl_ev_fact.text = "Р¦Рµ СЃС‚Р°Р»РѕСЃСЏ РЅР°СЃРїСЂР°РІРґС–: Р·РѕРЅРґ Magellan Р±С–Р»СЏ Р’РµРЅРµСЂРё СЂРµРіСѓР»СЏСЂРЅРѕ СЂРѕР·РІРµСЂС‚Р°РІ РїР°РЅРµР»С– РґР»СЏ С‚РµСЂРјРѕСЂРµРіСѓР»СЏС†С–С— РІ С‚С–РЅС–."
		btn_opt1.text = "Р РѕР·РІРµСЂРЅСѓС‚Рё СЂР°РґС–Р°С‚РѕСЂ РѕС…РѕР»РѕРґР¶РµРЅРЅСЏ"
		btn_opt2.text = "Р¤РѕСЂСЃСѓРІР°С‚Рё РѕР±С‡РёСЃР»РµРЅРЅСЏ (+20 РЅР°СѓРєРё, СЂРёР·РёРє)"
	elif ev_type == 1:
		lbl_ev_title.text = "РџРћР“РћР”РќРђ РђРќРћРњРђР›Р†РЇ: РЎРµР·РѕРЅРЅР° РїРёР»РѕРІР° Р±СѓСЂСЏ"
		lbl_ev_desc.text = "РђС‚РјРѕСЃС„РµСЂРЅРёР№ С„СЂРѕРЅС‚ РїС–РґРЅСЏРІ С…РјР°СЂСѓ РїС–СЃРєСѓ, Р·РјРµРЅС€РёРІС€Рё С–РЅСЃРѕР»СЏС†С–СЋ СЃРѕРЅСЏС‡РЅРёС… Р±Р°С‚Р°СЂРµР№ РЅР° 75%."
		lbl_ev_fact.text = "Р¦Рµ СЃС‚Р°Р»РѕСЃСЏ РЅР°СЃРїСЂР°РІРґС–: Сѓ 2018 СЂРѕС†С– РіР»РѕР±Р°Р»СЊРЅР° РїРёР»РѕРІР° Р±СѓСЂСЏ Р·РЅРµСЃС‚СЂСѓРјРёР»Р° СЃРѕРЅСЏС‡РЅС– РїР°РЅРµР»С– РјР°СЂСЃРѕС…РѕРґР° Opportunity."
		btn_opt1.text = "РЎРїР»СЏС‡РёР№ СЂРµР¶РёРј РЅР° 48 РіРѕРґРёРЅ (Р—Р±РµСЂРµРіС‚Рё Р±Р°С‚Р°СЂРµС—)"
		btn_opt2.text = "РџСЂРѕРґРѕРІР¶РёС‚Рё Р·Р°РјС–СЂРё РїРёР»Сѓ (+25 РЅР°СѓРєРё, СЂРёР·РёРє)"
	else:
		lbl_ev_title.text = "РџР РР›РђР”РћР’Рђ РђРќРћРњРђР›Р†РЇ: Р—Р±С–Р№ РѕСЂС–С”РЅС‚Р°С†С–С— РґР·РµСЂРєР°Р»Р°"
		lbl_ev_desc.text = "РџСЂРёРІС–Рґ СЃРїРµРєС‚СЂРѕРјРµС‚СЂР° Р·Р°С„С–РєСЃСѓРІР°РІ РјС–РєСЂРѕР»СЋС„С‚ РѕРїС‚РёС‡РЅРѕС— СЃРёСЃС‚РµРјРё."
		lbl_ev_fact.text = "Р¦Рµ СЃС‚Р°Р»РѕСЃСЏ РЅР°СЃРїСЂР°РІРґС–: РєРѕСЃРјС–С‡РЅРёР№ С‚РµР»РµСЃРєРѕРї РҐР°Р±Р±Р» СѓСЃРїС–С€РЅРѕ РєРѕРјРїРµРЅСЃСѓРІР°РІ Р·Р±РѕС— РіС–СЂРѕСЃРєРѕРїС–РІ РїСЂРѕРіСЂР°РјРЅРёРјРё Р°Р»РіРѕСЂРёС‚РјР°РјРё."
		btn_opt1.text = "РџСЂРѕРІРµСЃС‚Рё Р°РІС‚РѕРєР°Р»С–Р±СЂСѓРІР°РЅРЅСЏ"
		btn_opt2.text = "Р’РёРєРѕСЂРёСЃС‚Р°С‚Рё СЂРµР·РµСЂРІРЅРёР№ СЃРµРЅСЃРѕСЂ"

func _resolve_surface_event(choice: int) -> void:
	SoundManager.play_click()
	event_popup.visible = false
	if choice == 2:
		GameState.collected_science += 20.0
		lbl_target_hint.text = "Р РёР·РёРє РІРёРїСЂР°РІРґР°РІСЃСЏ: РѕС‚СЂРёРјР°РЅРѕ +20 РѕС‡РѕРє РЅР°СѓРєРё!"
	else:
		lbl_target_hint.text = "Р‘РµР·РїРµС‡РЅРµ СЂС–С€РµРЅРЅСЏ РІРёРєРѕРЅР°РЅРѕ: СЃРёСЃС‚РµРјРё СЃС‚Р°Р±С–Р»СЊРЅС–."
	update_hud()

func update_hud() -> void:
	var total = int(GameState.collected_science)
	lbl_science.text = "Р—С–Р±СЂР°РЅРѕ РЅР°СѓРєРё: %d РѕС‡РѕРє" % [total]

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
