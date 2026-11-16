extends Control

@onready var left_panel = $Content/LeftPanel
@onready var photo_container = $Content/LeftPanel/VBox/PhotoContainer
@onready var right_panel = $Content/RightPanel

@onready var patch_visual = $Content/LeftPanel/VBox/PatchAnchor/MissionPatchVisual
@onready var nasa_photo_rect = $Content/LeftPanel/VBox/PhotoContainer/NasaPhotoRect
@onready var lbl_photo_caption = $Content/LeftPanel/VBox/LblPhotoCaption
@onready var lbl_photo_credit = $Content/LeftPanel/VBox/LblPhotoCredit

@onready var lbl_score = $Content/RightPanel/VBox/LblScore
@onready var lbl_breakdown = $Content/RightPanel/VBox/LblBreakdown
@onready var lbl_comparison = $Content/RightPanel/VBox/LblComparison
@onready var btn_restart = $Content/RightPanel/VBox/HBoxActions/BtnRestart
@onready var btn_show_leaderboard = $Content/RightPanel/VBox/HBoxActions/BtnShowLeaderboard

@onready var edit_callsign = $Content/RightPanel/VBox/LeaderboardBox/HBoxSubmit/EditCallsign
@onready var btn_submit = $Content/RightPanel/VBox/LeaderboardBox/HBoxSubmit/BtnSubmit
@onready var lbl_submit_status = $Content/RightPanel/VBox/LeaderboardBox/LblSubmitStatus

@onready var modal = $LeaderboardModal
@onready var vbox_entries = $LeaderboardModal/VBox/ScrollEntries/VBoxEntries
@onready var btn_close_modal = $LeaderboardModal/VBox/BtnCloseModal

var has_submitted: bool = false

func _ready() -> void:
	btn_restart.pressed.connect(_on_restart_pressed)
	btn_show_leaderboard.pressed.connect(_on_show_leaderboard_pressed)
	btn_close_modal.pressed.connect(_on_close_modal_pressed)
	btn_submit.pressed.connect(_on_submit_pressed)

	LeaderboardManager.leaderboard_loaded.connect(_on_leaderboard_loaded)
	LeaderboardManager.score_submitted.connect(_on_score_submitted)

	apply_liquid_glass_styles()
	display_real_nasa_photo()
	calculate_final_results()

func apply_liquid_glass_styles() -> void:
	left_panel.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(16, 1))
	right_panel.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(16, 1))
	photo_container.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(10, 1))
	modal.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(20, 2))

func display_real_nasa_photo() -> void:
	var platform = DataManager.get_platform(GameState.platform_id)
	var p_type = str(platform.get("type", "rover"))
	var t_id = GameState.target_id

	var chosen_item: Dictionary = {}
	if DataManager.media_data.has("items"):
		for item in DataManager.media_data["items"]:
			if item.get("target") == t_id and item.get("platform_type") == p_type:
				chosen_item = item
				break
		if chosen_item.is_empty():
			for item in DataManager.media_data["items"]:
				if item.get("target") == t_id:
					chosen_item = item
					break

	if not chosen_item.is_empty():
		var file_str = str(chosen_item.get("file", ""))
		var img_key = file_str.replace("img/", "").replace(".jpg", "").replace(".png", "")
		var tex = DataManager.get_image_texture(img_key)
		if tex:
			nasa_photo_rect.texture = tex
		lbl_photo_caption.text = str(chosen_item.get("caption", "Знімок поверхні"))
		lbl_photo_credit.text = "Фото: " + str(chosen_item.get("credit", "NASA"))
	else:
		var fallback_tex = DataManager.get_image_texture(t_id)
		if fallback_tex:
			nasa_photo_rect.texture = fallback_tex
		lbl_photo_caption.text = "Знімок об'єкта місії"
		lbl_photo_credit.text = "NASA / JPL"

func calculate_final_results() -> void:
	var stats = GameState.get_current_stats()
	var base_science = stats.get("potential_science", 50.0)
	var final_science = base_science + GameState.collected_science - GameState.landing_damage
	var final_score_val = int(clamp(final_science, 10.0, 100.0))
	GameState.final_score = final_score_val

	lbl_score.text = "ОЦІНКА МІСІЇ: %d / 100" % [final_score_val]
	if final_score_val >= 80:
		lbl_score.modulate = ThemeManager.accent_emerald
	elif final_score_val >= 50:
		lbl_score.modulate = ThemeManager.accent_amber
	else:
		lbl_score.modulate = ThemeManager.accent_red

	var b_text = "Деталізація результатів інженерної оцінки:\n\n"
	b_text += "• Науковий потенціал приладів: +%d\n" % [int(base_science)]
	b_text += "• Зібрано польових зразків: +%d\n" % [int(GameState.collected_science)]
	if GameState.landing_damage > 0:
		b_text += "• Штраф за пошкодження при посадці: -%d\n" % [int(GameState.landing_damage)]
	b_text += "• Бюджетна ефективність: 100%\n"
	b_text += "• Інженерний запас маси ракети: %.1f%%\n" % [stats.get("mass_reserve_pct", 0.2) * 100.0]
	if GameState.launch_window_offset != 0:
		b_text += "• Зміщення вікна старту: %d діб\n" % [GameState.launch_window_offset]
	lbl_breakdown.text = b_text

	var comp_text = "Порівняння з реальними історичними місіями NASA:\n\n"
	if GameState.target_id == "mars":
		comp_text += "Ваша місія досягла результатів, порівнянних з марсоходом Perseverance (NASA, 2020) та науковою лабораторією Curiosity."
	elif GameState.target_id == "moon":
		comp_text += "Успіх вашого апарата наближений до місій програми Artemis та картографічного орбітера LRO."
	elif GameState.target_id == "venus":
		comp_text += "Ваш апарат зібрав унікальні дані в екстремальній атмосфері, повторивши досягнення місії Magellan та станцій Venera."
	elif GameState.target_id == "europa":
		comp_text += "Місія здійснила якісний прорив у дослідженні підлідного океану на рівні флагманського проекту Europa Clipper."
	else:
		comp_text += "Зонд успішно виконав високоточне картографування та забір реголіту у стилі місії OSIRIS-REx."
	lbl_comparison.text = comp_text

func _on_submit_pressed() -> void:
	if has_submitted:
		lbl_submit_status.text = "Ваш результат вже надіслано до світового залу слави!"
		return
	var c_name = edit_callsign.text.strip_edges()
	if c_name.is_empty():
		lbl_submit_status.text = "Будь ласка, вкажіть ваш позивний або ім'я."
		lbl_submit_status.modulate = ThemeManager.accent_amber
		return

	btn_submit.disabled = true
	lbl_submit_status.text = "Надсилання результату на сервер..."
	lbl_submit_status.modulate = ThemeManager.accent_cyan

	var target_info = DataManager.get_target(GameState.target_id)
	var t_name = DataManager.get_localized(target_info.get("name"), "Ціль")
	LeaderboardManager.submit_score(c_name, GameState.final_score, t_name)

func _on_score_submitted(success: bool) -> void:
	btn_submit.disabled = false
	if success:
		has_submitted = true
		btn_submit.text = "Опубліковано ✓"
		btn_submit.disabled = true
		lbl_submit_status.text = "Успішно опубліковано у Світовий лідерборд!"
		lbl_submit_status.modulate = ThemeManager.accent_emerald
	else:
		lbl_submit_status.text = "Помилка зв'язку з сервером. Спробуйте ще раз."
		lbl_submit_status.modulate = ThemeManager.accent_red

func _on_show_leaderboard_pressed() -> void:
	SoundManager.play_click()
	modal.visible = true
	_clear_entries()
	var loading_lbl = Label.new()
	loading_lbl.text = "Завантаження світових рекордів..."
	loading_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_entries.add_child(loading_lbl)
	LeaderboardManager.fetch_leaderboard()

func _on_close_modal_pressed() -> void:
	SoundManager.play_click()
	modal.visible = false

func _on_leaderboard_loaded(entries: Array) -> void:
	_clear_entries()
	if entries.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "Таблиця наразі порожня або відсутній зв'язок. Будьте першим!"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox_entries.add_child(empty_lbl)
		return

	for idx in range(entries.size()):
		var entry = entries[idx] as Dictionary
		var row = HBoxContainer.new()
		row.theme_override_constants.separation = 12

		var rank_lbl = Label.new()
		rank_lbl.custom_minimum_size = Vector2(40, 0)
		rank_lbl.text = "#%d" % [idx + 1]
		if idx == 0:
			rank_lbl.modulate = Color(1.0, 0.85, 0.2)
		elif idx == 1:
			rank_lbl.modulate = Color(0.85, 0.9, 0.95)
		elif idx == 2:
			rank_lbl.modulate = Color(0.85, 0.55, 0.3)
		row.add_child(rank_lbl)

		var name_lbl = Label.new()
		name_lbl.size_flags_horizontal = SIZE_EXPAND_FILL
		name_lbl.text = str(entry.get("name", "Командир"))
		row.add_child(name_lbl)

		var target_lbl = Label.new()
		target_lbl.custom_minimum_size = Vector2(90, 0)
		target_lbl.text = str(entry.get("target", "Марс"))
		target_lbl.modulate = Color(0.65, 0.75, 0.88)
		row.add_child(target_lbl)

		var score_lbl = Label.new()
		score_lbl.custom_minimum_size = Vector2(80, 0)
		score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		score_lbl.text = "%d балів" % [int(entry.get("score", 0))]
		score_lbl.modulate = ThemeManager.accent_emerald
		row.add_child(score_lbl)

		vbox_entries.add_child(row)

func _clear_entries() -> void:
	for child in vbox_entries.get_children():
		child.queue_free()

func _on_restart_pressed() -> void:
	SoundManager.play_click()
	GameState.reset_mission()
	GameState.set_phase("briefing")
