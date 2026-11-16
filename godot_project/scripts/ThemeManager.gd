extends Node

signal theme_changed(val: float)

var theme_value: float = 0.0

var color_bg_dark: Color = Color(0.05, 0.07, 0.12, 1.0)
var color_bg_light: Color = Color(0.88, 0.92, 0.97, 1.0)

var color_panel_dark: Color = Color(0.09, 0.13, 0.20, 0.78)
var color_panel_light: Color = Color(0.96, 0.98, 1.0, 0.92)

var color_border_dark: Color = Color(0.35, 0.72, 0.98, 0.40)
var color_border_light: Color = Color(0.30, 0.50, 0.75, 0.70)

var color_text_dark: Color = Color(0.96, 0.98, 1.0, 1.0)
var color_text_light: Color = Color(0.04, 0.08, 0.14, 1.0)

var color_muted_dark: Color = Color(0.65, 0.75, 0.88, 1.0)
var color_muted_light: Color = Color(0.18, 0.26, 0.38, 1.0)

var accent_cyan: Color = Color(0.0, 0.90, 1.0, 1.0)
var accent_emerald: Color = Color(0.18, 0.94, 0.58, 1.0)
var accent_amber: Color = Color(1.0, 0.74, 0.20, 1.0)
var accent_red: Color = Color(1.0, 0.36, 0.36, 1.0)

var accent_cyan_light: Color = Color(0.0, 0.32, 0.65, 1.0)
var accent_emerald_light: Color = Color(0.02, 0.42, 0.22, 1.0)
var accent_amber_light: Color = Color(0.60, 0.34, 0.0, 1.0)
var accent_red_light: Color = Color(0.70, 0.08, 0.08, 1.0)

func set_theme_value(v: float) -> void:
	theme_value = clamp(v, 0.0, 1.0)
	theme_changed.emit(theme_value)

func get_bg_color() -> Color:
	return color_bg_dark.lerp(color_bg_light, theme_value)

func get_panel_color() -> Color:
	return color_panel_dark.lerp(color_panel_light, theme_value)

func get_border_color() -> Color:
	return color_border_dark.lerp(color_border_light, theme_value)

func get_text_color() -> Color:
	return color_text_dark.lerp(color_text_light, theme_value)

func get_muted_color() -> Color:
	return color_muted_dark.lerp(color_muted_light, theme_value)

func get_accent_cyan() -> Color:
	return accent_cyan.lerp(accent_cyan_light, theme_value)

func get_accent_emerald() -> Color:
	return accent_emerald.lerp(accent_emerald_light, theme_value)

func get_accent_amber() -> Color:
	return accent_amber.lerp(accent_amber_light, theme_value)

func get_accent_red() -> Color:
	return accent_red.lerp(accent_red_light, theme_value)

func create_glass_style(corner_radius: int = 12, border_width: int = 1) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = get_panel_color()
	sb.border_color = get_border_color()
	sb.border_blend = true
	sb.set_border_width_all(border_width)
	sb.border_width_top = border_width + 1
	sb.set_corner_radius_all(corner_radius)
	sb.shadow_color = Color(0, 0, 0, lerp(0.40, 0.10, theme_value))
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 4)
	sb.content_margin_left = 14
	sb.content_margin_top = 10
	sb.content_margin_right = 14
	sb.content_margin_bottom = 10
	return sb

func create_card_style(is_selected: bool, is_locked: bool) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.set_corner_radius_all(10)
	sb.set_border_width_all(1)
	sb.border_blend = true
	sb.content_margin_left = 10
	sb.content_margin_top = 8
	sb.content_margin_right = 10
	sb.content_margin_bottom = 8

	if is_selected:
		var sel_dark = Color(0.10, 0.28, 0.20, 0.88)
		var sel_light = Color(0.80, 0.96, 0.87, 0.95)
		sb.bg_color = sel_dark.lerp(sel_light, theme_value)
		var border_col = accent_emerald.lerp(accent_emerald_light, theme_value)
		sb.border_color = border_col
		sb.border_width_top = 2
		sb.shadow_color = Color(border_col.r, border_col.g, border_col.b, 0.30)
		sb.shadow_size = 8
		sb.shadow_offset = Vector2(0, 2)
	elif is_locked:
		var lock_dark = Color(0.07, 0.09, 0.13, 0.50)
		var lock_light = Color(0.84, 0.86, 0.90, 0.60)
		sb.bg_color = lock_dark.lerp(lock_light, theme_value)
		sb.border_color = Color(0.38, 0.44, 0.52, 0.30)
		sb.shadow_size = 0
	else:
		sb.bg_color = get_panel_color()
		sb.border_color = get_border_color()
		sb.border_width_top = 2
		sb.shadow_color = Color(0, 0, 0, lerp(0.24, 0.06, theme_value))
		sb.shadow_size = 5
		sb.shadow_offset = Vector2(0, 2)
	return sb
