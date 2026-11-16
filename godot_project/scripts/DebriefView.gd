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
@onready var btn_restart = $Content/RightPanel/VBox/BtnRestart

func _ready() -> void:
	btn_restart.pressed.connect(_on_restart_pressed)
	apply_liquid_glass_styles()
	display_real_nasa_photo()
	calculate_final_results()

func apply_liquid_glass_styles() -> void:
	left_panel.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(16, 1))
	right_panel.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(16, 1))
	photo_container.add_theme_stylebox_override("panel", ThemeManager.create_glass_style(10, 1))

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

func _on_restart_pressed() -> void:
	SoundManager.play_click()
	GameState.reset_mission()
	GameState.set_phase("briefing")
