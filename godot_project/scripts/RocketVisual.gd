extends Node2D

@export var is_flying: bool = false
@export var staging_stage: int = 0
@export var thrust_power: float = 1.0
@export var altitude_km: float = 0.0

var flame_time: float = 0.0
var booster_l_pos: Vector2 = Vector2.ZERO
var booster_r_pos: Vector2 = Vector2.ZERO
var booster_rot: float = 0.0
var stage1_pos: Vector2 = Vector2.ZERO
var stage1_rot: float = 0.0
var fairing_sep_dist: float = 0.0

func _process(delta: float) -> void:
	flame_time += delta
	if staging_stage >= 1:
		booster_l_pos += Vector2(-48.0, 32.0) * delta
		booster_r_pos += Vector2(48.0, 32.0) * delta
		booster_rot += delta * 0.7
	if staging_stage >= 2:
		stage1_pos += Vector2(0, 95.0) * delta
		stage1_rot += delta * 0.2
	if staging_stage >= 3:
		fairing_sep_dist += delta * 70.0
	queue_redraw()

func get_rocket_config() -> Dictionary:
	var r_id = GameState.rocket_id
	var cfg = {
		"id": r_id,
		"w": 26.0,
		"h_s1": 142.0,
		"h_s2": 52.0,
		"h_f": 58.0,
		"f_w": 18.2,
		"core_col": Color(0.95, 0.96, 0.98),
		"inter_col": Color(0.12, 0.13, 0.15),
		"inter_h": 22.0,
		"s2_col": Color(0.95, 0.96, 0.98),
		"boosters": 0,
		"booster_type": "",
		"booster_w": 0.0,
		"booster_h": 0.0,
		"booster_col": Color(1, 1, 1),
		"has_fins": false,
		"has_legs": false,
		"nozzle_count": 3,
		"plume_type": "kerosene",
		"is_ukrainian": false
	}
	if r_id == "falcon9":
		cfg["w"] = 26.0
		cfg["h_s1"] = 142.0
		cfg["h_s2"] = 52.0
		cfg["h_f"] = 58.0
		cfg["f_w"] = 18.2
		cfg["core_col"] = Color(0.95, 0.96, 0.98)
		cfg["inter_col"] = Color(0.12, 0.13, 0.15)
		cfg["inter_h"] = 22.0
		cfg["has_fins"] = true
		cfg["has_legs"] = true
		cfg["nozzle_count"] = 3
		cfg["plume_type"] = "kerosene"
	elif r_id == "falcon_heavy":
		cfg["w"] = 26.0
		cfg["h_s1"] = 142.0
		cfg["h_s2"] = 52.0
		cfg["h_f"] = 58.0
		cfg["f_w"] = 18.2
		cfg["core_col"] = Color(0.95, 0.96, 0.98)
		cfg["inter_col"] = Color(0.12, 0.13, 0.15)
		cfg["inter_h"] = 22.0
		cfg["boosters"] = 2
		cfg["booster_type"] = "core"
		cfg["booster_w"] = 26.0
		cfg["booster_h"] = 142.0
		cfg["booster_col"] = Color(0.95, 0.96, 0.98)
		cfg["has_fins"] = true
		cfg["has_legs"] = true
		cfg["nozzle_count"] = 3
		cfg["plume_type"] = "falcon_heavy"
	elif r_id == "atlas_v_541":
		cfg["w"] = 28.0
		cfg["h_s1"] = 114.0
		cfg["h_s2"] = 42.0
		cfg["h_f"] = 74.0
		cfg["f_w"] = 24.5
		cfg["core_col"] = Color(0.76, 0.52, 0.28)
		cfg["inter_col"] = Color(0.94, 0.95, 0.96)
		cfg["inter_h"] = 16.0
		cfg["s2_col"] = Color(0.95, 0.96, 0.98)
		cfg["boosters"] = 4
		cfg["booster_type"] = "srb"
		cfg["booster_w"] = 9.0
		cfg["booster_h"] = 72.0
		cfg["booster_col"] = Color(0.94, 0.95, 0.96)
		cfg["has_fins"] = false
		cfg["has_legs"] = false
		cfg["nozzle_count"] = 2
		cfg["plume_type"] = "atlas"
	elif r_id == "vulcan":
		cfg["w"] = 34.0
		cfg["h_s1"] = 118.0
		cfg["h_s2"] = 46.0
		cfg["h_f"] = 64.0
		cfg["f_w"] = 18.5
		cfg["core_col"] = Color(0.82, 0.44, 0.18)
		cfg["inter_col"] = Color(0.94, 0.95, 0.96)
		cfg["inter_h"] = 18.0
		cfg["s2_col"] = Color(0.95, 0.96, 0.98)
		cfg["boosters"] = 4
		cfg["booster_type"] = "srb"
		cfg["booster_w"] = 10.5
		cfg["booster_h"] = 80.0
		cfg["booster_col"] = Color(0.89, 0.88, 0.85)
		cfg["has_fins"] = false
		cfg["has_legs"] = false
		cfg["nozzle_count"] = 2
		cfg["plume_type"] = "vulcan"
	elif r_id == "antares":
		cfg["w"] = 28.0
		cfg["h_s1"] = 98.0
		cfg["h_s2"] = 34.0
		cfg["h_f"] = 46.0
		cfg["f_w"] = 14.8
		cfg["core_col"] = Color(0.92, 0.93, 0.95)
		cfg["inter_col"] = Color(0.18, 0.20, 0.24)
		cfg["inter_h"] = 14.0
		cfg["s2_col"] = Color(0.24, 0.26, 0.30)
		cfg["boosters"] = 0
		cfg["booster_type"] = ""
		cfg["has_fins"] = false
		cfg["has_legs"] = false
		cfg["nozzle_count"] = 2
		cfg["plume_type"] = "kerosene"
		cfg["is_ukrainian"] = true
	elif r_id == "titan_iiie":
		cfg["w"] = 24.0
		cfg["h_s1"] = 108.0
		cfg["h_s2"] = 38.0
		cfg["h_f"] = 62.0
		cfg["f_w"] = 18.0
		cfg["core_col"] = Color(0.26, 0.30, 0.24)
		cfg["inter_col"] = Color(0.92, 0.94, 0.96)
		cfg["inter_h"] = 16.0
		cfg["s2_col"] = Color(0.95, 0.96, 0.98)
		cfg["boosters"] = 2
		cfg["booster_type"] = "srb"
		cfg["booster_w"] = 15.0
		cfg["booster_h"] = 114.0
		cfg["booster_col"] = Color(0.92, 0.93, 0.95)
		cfg["has_fins"] = false
		cfg["has_legs"] = false
		cfg["nozzle_count"] = 2
		cfg["plume_type"] = "titan"
	return cfg

func _draw() -> void:
	var cfg = get_rocket_config()
	var w = cfg["w"]
	var h_s1 = cfg["h_s1"]
	var h_s2 = cfg["h_s2"]
	var h_f = cfg["h_f"]
	var boosters = cfg["boosters"]
	var vac_factor = clamp(altitude_km / 80.0, 0.0, 1.0)

	if is_flying and thrust_power > 0.0 and staging_stage < 2:
		draw_engine_plumes(cfg, Vector2(0, 0), w * 0.7, thrust_power, vac_factor)

	if is_flying and thrust_power > 0.0 and staging_stage >= 2:
		var s2_bottom = -h_s1
		draw_vacuum_plume(Vector2(0, s2_bottom), w * 0.5, thrust_power)

	if staging_stage < 2:
		draw_first_stage(cfg, stage1_pos, 1.0)
		if boosters > 0:
			draw_side_boosters(cfg, 1.0)
	else:
		if stage1_pos.y < 450.0:
			var s1_alpha = clamp(1.0 - (stage1_pos.y / 450.0), 0.0, 1.0)
			draw_first_stage(cfg, stage1_pos, s1_alpha)

	if boosters > 0 and staging_stage >= 1:
		if booster_l_pos.y < 450.0:
			var b_alpha = clamp(1.0 - (booster_l_pos.y / 450.0), 0.0, 1.0)
			draw_side_boosters(cfg, b_alpha)

	var s2_y = -h_s1 - h_s2
	draw_second_stage(cfg, s2_y)

	var payload_y = s2_y - 25.0
	draw_payload_probe(payload_y)

	if staging_stage < 3:
		draw_fairing(cfg, s2_y)
	else:
		if fairing_sep_dist < 400.0:
			draw_separating_fairings(cfg, s2_y)

func draw_engine_plumes(cfg: Dictionary, origin: Vector2, width_base: float, power: float, vac_blend: float) -> void:
	var p_type = cfg["plume_type"]
	if p_type == "falcon_heavy" and staging_stage == 0:
		var bw = cfg["booster_w"]
		draw_single_core_plume(origin + Vector2(-bw - 2.0, 0), width_base * 0.9, power, vac_blend, "kerosene")
		draw_single_core_plume(origin + Vector2(bw + 2.0, 0), width_base * 0.9, power, vac_blend, "kerosene")
		draw_single_core_plume(origin, width_base, power, vac_blend, "kerosene")
	elif (p_type == "atlas" or p_type == "vulcan" or p_type == "titan") and staging_stage == 0:
		var w = cfg["w"]
		var srb_w = 14.0 if p_type == "titan" else 10.0
		var srb_offset = (w * 0.5 + 10.0) if p_type == "titan" else (w * 0.5 + 6.0)
		draw_srb_plume(origin + Vector2(-srb_offset, 0), srb_w, power)
		draw_srb_plume(origin + Vector2(srb_offset, 0), srb_w, power)
		draw_single_core_plume(origin, width_base, power, vac_blend, "kerosene" if p_type == "titan" else p_type)
	else:
		draw_single_core_plume(origin, width_base, power, vac_blend, p_type)

func draw_single_core_plume(origin: Vector2, width_base: float, power: float, vac_blend: float, p_type: String) -> void:
	var flame_len = (70.0 + sin(flame_time * 38.0) * 14.0) * power
	var plume_spread = lerp(width_base * 0.8, width_base * 3.4, vac_blend)
	var outer_color = Color(1.0, 0.52, 0.12, lerp(0.88, 0.40, vac_blend))
	var core_color = Color(1.0, 0.96, 0.55, 0.95)
	var inner_core_color = Color(0.55, 0.78, 1.0, 0.72)

	if p_type == "vulcan":
		outer_color = Color(0.20, 0.65, 1.0, lerp(0.85, 0.35, vac_blend))
		core_color = Color(0.65, 0.92, 1.0, 0.98)
		inner_core_color = Color(0.90, 0.97, 1.0, 0.85)

	var glow_radius = width_base * 1.4 + 6.0
	var glow_col = Color(outer_color.r, outer_color.g, outer_color.b, 0.18)
	draw_circle(origin + Vector2(0, flame_len * 0.18), glow_radius, glow_col)

	var outer_poly = PackedVector2Array([
		origin + Vector2(-width_base * 0.5, 0),
		origin + Vector2(width_base * 0.5, 0),
		origin + Vector2(plume_spread, flame_len),
		origin + Vector2(0, flame_len * 1.3),
		origin + Vector2(-plume_spread, flame_len)
	])
	draw_polygon(outer_poly, [outer_color])

	var core_poly = PackedVector2Array([
		origin + Vector2(-width_base * 0.3, 0),
		origin + Vector2(width_base * 0.3, 0),
		origin + Vector2(width_base * 0.48, flame_len * 0.65),
		origin + Vector2(0, flame_len * 0.9),
		origin + Vector2(-width_base * 0.48, flame_len * 0.65)
	])
	draw_polygon(core_poly, [core_color])

	var inner_poly = PackedVector2Array([
		origin + Vector2(-width_base * 0.14, 0),
		origin + Vector2(width_base * 0.14, 0),
		origin + Vector2(width_base * 0.20, flame_len * 0.38),
		origin + Vector2(0, flame_len * 0.55),
		origin + Vector2(-width_base * 0.20, flame_len * 0.38)
	])
	draw_polygon(inner_poly, [inner_core_color])

	if vac_blend < 0.45:
		for i in range(4):
			var dy = 16.0 + i * 16.0
			var d_col: Color
			if i % 2 == 0:
				d_col = Color(1.0, 1.0, 1.0, 0.92)
			else:
				d_col = Color(0.75, 0.90, 1.0, 0.88)
			var diamond = PackedVector2Array([
				origin + Vector2(0, dy - 6.0),
				origin + Vector2(4.5, dy),
				origin + Vector2(0, dy + 6.0),
				origin + Vector2(-4.5, dy)
			])
			draw_polygon(diamond, [d_col])

func draw_srb_plume(origin: Vector2, width: float, power: float) -> void:
	var flame_len = (55.0 + sin(flame_time * 44.0) * 12.0) * power
	var glow_col = Color(1.0, 0.72, 0.20, 0.16)
	draw_circle(origin + Vector2(0, flame_len * 0.15), width * 1.2, glow_col)
	var srb_outer = PackedVector2Array([
		origin + Vector2(-width * 0.5, 0),
		origin + Vector2(width * 0.5, 0),
		origin + Vector2(width * 0.9, flame_len * 0.8),
		origin + Vector2(0, flame_len),
		origin + Vector2(-width * 0.9, flame_len * 0.8)
	])
	draw_polygon(srb_outer, [Color(1.0, 0.72, 0.20, 0.90)])
	var srb_core = PackedVector2Array([
		origin + Vector2(-width * 0.3, 0),
		origin + Vector2(width * 0.3, 0),
		origin + Vector2(width * 0.4, flame_len * 0.5),
		origin + Vector2(0, flame_len * 0.75),
		origin + Vector2(-width * 0.4, flame_len * 0.5)
	])
	draw_polygon(srb_core, [Color(1.0, 1.0, 0.90, 0.98)])

func draw_vacuum_plume(origin: Vector2, width_base: float, power: float) -> void:
	var bell_len = (85.0 + sin(flame_time * 26.0) * 10.0) * power
	var bell_w = width_base * 4.8
	var bell_poly = PackedVector2Array([
		origin + Vector2(-width_base * 0.4, 0),
		origin + Vector2(width_base * 0.4, 0),
		origin + Vector2(bell_w, bell_len * 0.7),
		origin + Vector2(bell_w * 0.6, bell_len),
		origin + Vector2(0, bell_len * 1.15),
		origin + Vector2(-bell_w * 0.6, bell_len),
		origin + Vector2(-bell_w, bell_len * 0.7)
	])
	draw_polygon(bell_poly, [Color(0.32, 0.65, 1.0, 0.60)])
	var inner_poly = PackedVector2Array([
		origin + Vector2(-width_base * 0.22, 0),
		origin + Vector2(width_base * 0.22, 0),
		origin + Vector2(bell_w * 0.28, bell_len * 0.55),
		origin + Vector2(0, bell_len * 0.72),
		origin + Vector2(-bell_w * 0.28, bell_len * 0.55)
	])
	draw_polygon(inner_poly, [Color(0.55, 0.85, 1.0, 0.45)])
	draw_circle(origin, width_base * 0.9, Color(0.80, 0.95, 1.0, 0.22))

func draw_first_stage(cfg: Dictionary, offset: Vector2, alpha: float = 1.0) -> void:
	if alpha <= 0.01:
		return
	var r_id = cfg["id"]
	var w = cfg["w"]
	var h = cfg["h_s1"]
	var s1_top = -h
	var bx = offset.x - w * 0.5
	var by = offset.y + s1_top
	var body_rect = Rect2(bx, by, w, h)
	var core_col = Color(cfg["core_col"].r, cfg["core_col"].g, cfg["core_col"].b, alpha)

	draw_rect(body_rect, core_col)

	if r_id == "falcon9" or r_id == "falcon_heavy":
		draw_rect(Rect2(bx, by, w * 0.28, h), Color(1.0, 1.0, 1.0, 0.13 * alpha))
		draw_rect(Rect2(bx + w * 0.28, by, w * 0.44, h), Color(0.0, 0.0, 0.0, 0.03 * alpha))
		draw_rect(Rect2(bx + w * 0.72, by, w * 0.28, h), Color(0.0, 0.0, 0.0, 0.11 * alpha))
	elif r_id == "atlas_v_541":
		draw_rect(Rect2(bx, by, w * 0.25, h), Color(0.9, 0.65, 0.35, 0.22 * alpha))
		draw_rect(Rect2(bx + w * 0.25, by, w * 0.5, h), Color(0.0, 0.0, 0.0, 0.04 * alpha))
		draw_rect(Rect2(bx + w * 0.75, by, w * 0.25, h), Color(0.0, 0.0, 0.0, 0.14 * alpha))
	elif r_id == "vulcan":
		draw_rect(Rect2(bx, by, w * 0.28, h), Color(1.0, 0.72, 0.30, 0.18 * alpha))
		draw_rect(Rect2(bx + w * 0.28, by, w * 0.44, h), Color(0.0, 0.0, 0.0, 0.03 * alpha))
		draw_rect(Rect2(bx + w * 0.72, by, w * 0.28, h), Color(0.0, 0.0, 0.0, 0.14 * alpha))
		var diag_poly = PackedVector2Array([
			Vector2(bx + w * 0.18, by + h * 0.22),
			Vector2(bx + w * 0.38, by + h * 0.22),
			Vector2(bx + w * 0.26, by + h * 0.52),
			Vector2(bx + w * 0.06, by + h * 0.52)
		])
		draw_polygon(diag_poly, [Color(1.0, 0.60, 0.15, 0.18 * alpha)])
	else:
		draw_rect(Rect2(bx, by, w * 0.28, h), Color(1.0, 1.0, 1.0, 0.10 * alpha))
		draw_rect(Rect2(bx + w * 0.72, by, w * 0.28, h), Color(0.0, 0.0, 0.0, 0.10 * alpha))

	var ring_step = 20.0
	var ring_count = int(h / ring_step)
	for ri in range(ring_count):
		var ry = by + ri * ring_step + ring_step * 0.5
		draw_circle(Vector2(bx + 1.5, ry), 1.5, Color(0.75, 0.78, 0.82, 0.55 * alpha))
		draw_circle(Vector2(bx + w - 1.5, ry), 1.5, Color(0.55, 0.57, 0.60, 0.50 * alpha))

	draw_line(Vector2(bx + 3.0, by), Vector2(bx + 3.0, by + h), Color(1.0, 1.0, 1.0, 0.4 * alpha), 2.0)
	draw_line(Vector2(bx + w - 3.0, by), Vector2(bx + w - 3.0, by + h), Color(0.0, 0.0, 0.0, 0.25 * alpha), 2.5)
	draw_rect(body_rect, Color(0.16, 0.18, 0.22, alpha), false, 1.6)

	if r_id == "falcon9" or r_id == "falcon_heavy":
		var logo_y = by + h * 0.30
		var logo_h = 10.0
		var logo_w = w * 0.52
		draw_rect(Rect2(offset.x - logo_w * 0.5, logo_y, logo_w, logo_h), Color(0.06, 0.07, 0.09, 0.82 * alpha))
		var lx = offset.x - logo_w * 0.5 + 3.0
		var ly = logo_y + 2.5
		draw_line(Vector2(lx, ly), Vector2(lx + 7.0, ly), Color(0.90, 0.92, 0.95, 0.90 * alpha), 1.5)
		draw_line(Vector2(lx, ly + 3.0), Vector2(lx + 9.0, ly + 3.0), Color(0.90, 0.92, 0.95, 0.90 * alpha), 1.5)
		draw_line(Vector2(lx, ly + 6.0), Vector2(lx + 6.0, ly + 6.0), Color(0.90, 0.92, 0.95, 0.90 * alpha), 1.5)
	elif r_id == "atlas_v_541":
		var logo_y2 = by + h * 0.28
		var logo_w2 = w * 0.38
		draw_rect(Rect2(offset.x - logo_w2 * 0.5, logo_y2, logo_w2, 9.0), Color(0.08, 0.10, 0.14, 0.78 * alpha))

	if cfg["is_ukrainian"]:
		var ribbon_y = offset.y + s1_top + h * 0.42
		draw_rect(Rect2(offset.x - w * 0.38, ribbon_y, w * 0.76, 8.0), Color(0.0, 0.36, 0.75, alpha))
		draw_rect(Rect2(offset.x - w * 0.38, ribbon_y + 8.0, w * 0.76, 8.0), Color(1.0, 0.85, 0.0, alpha))
		draw_rect(Rect2(offset.x - w * 0.38, ribbon_y, w * 0.76, 16.0), Color(0.18, 0.20, 0.24, alpha), false, 1.2)

	var inter_h = cfg["inter_h"]
	var inter_col = Color(cfg["inter_col"].r, cfg["inter_col"].g, cfg["inter_col"].b, alpha)
	draw_rect(Rect2(offset.x - w * 0.5, offset.y + s1_top, w, inter_h), inter_col)
	draw_rect(Rect2(offset.x - w * 0.5, offset.y + s1_top, w, inter_h), Color(0.15, 0.17, 0.20, alpha), false, 1.2)

	for t in range(4):
		var ty = offset.y + s1_top + 3.0 + t * 4.0
		draw_line(Vector2(offset.x - w * 0.5, ty), Vector2(offset.x + w * 0.5, ty), Color(0.3, 0.33, 0.38, 0.6 * alpha), 1.0)

	if cfg["has_fins"]:
		var fin_y = offset.y + s1_top + inter_h + 4.0
		var frame_w = 7.0
		var frame_h = 6.0
		var lf_x = offset.x - w * 0.5 - frame_w
		var rf_x = offset.x + w * 0.5
		draw_rect(Rect2(lf_x, fin_y, frame_w, frame_h), Color(0.25, 0.28, 0.34, alpha))
		draw_rect(Rect2(lf_x, fin_y, frame_w, frame_h), Color(0.40, 0.44, 0.50, alpha), false, 0.8)
		draw_line(Vector2(lf_x + frame_w * 0.5, fin_y), Vector2(lf_x + frame_w * 0.5, fin_y + frame_h), Color(0.40, 0.44, 0.50, 0.7 * alpha), 0.8)
		draw_line(Vector2(lf_x, fin_y + frame_h * 0.5), Vector2(lf_x + frame_w, fin_y + frame_h * 0.5), Color(0.40, 0.44, 0.50, 0.7 * alpha), 0.8)
		draw_rect(Rect2(rf_x, fin_y, frame_w, frame_h), Color(0.25, 0.28, 0.34, alpha))
		draw_rect(Rect2(rf_x, fin_y, frame_w, frame_h), Color(0.40, 0.44, 0.50, alpha), false, 0.8)
		draw_line(Vector2(rf_x + frame_w * 0.5, fin_y), Vector2(rf_x + frame_w * 0.5, fin_y + frame_h), Color(0.40, 0.44, 0.50, 0.7 * alpha), 0.8)
		draw_line(Vector2(rf_x, fin_y + frame_h * 0.5), Vector2(rf_x + frame_w, fin_y + frame_h * 0.5), Color(0.40, 0.44, 0.50, 0.7 * alpha), 0.8)

	for ring in range(3):
		var ry = offset.y + s1_top + inter_h + 30.0 + ring * 32.0
		draw_line(Vector2(offset.x - w * 0.5, ry), Vector2(offset.x + w * 0.5, ry), Color(0.4, 0.45, 0.52, 0.4 * alpha), 1.0)

	if cfg["has_legs"]:
		var leg_top_y = offset.y - 42.0
		var leg_bot_y = offset.y
		var lleg_top_x = offset.x - w * 0.5
		var rleg_top_x = offset.x + w * 0.5
		draw_line(Vector2(lleg_top_x, leg_top_y), Vector2(lleg_top_x - 2.5, leg_bot_y), Color(0.15, 0.16, 0.18, alpha), 3.5)
		draw_line(Vector2(lleg_top_x - 1.0, leg_top_y + 10.0), Vector2(lleg_top_x - 5.0, leg_bot_y), Color(0.22, 0.24, 0.28, alpha), 1.8)
		draw_circle(Vector2(lleg_top_x - 2.5, leg_bot_y), 3.0, Color(0.18, 0.20, 0.24, alpha))
		draw_line(Vector2(rleg_top_x, leg_top_y), Vector2(rleg_top_x + 2.5, leg_bot_y), Color(0.15, 0.16, 0.18, alpha), 3.5)
		draw_line(Vector2(rleg_top_x + 1.0, leg_top_y + 10.0), Vector2(rleg_top_x + 5.0, leg_bot_y), Color(0.22, 0.24, 0.28, alpha), 1.8)
		draw_circle(Vector2(rleg_top_x + 2.5, leg_bot_y), 3.0, Color(0.18, 0.20, 0.24, alpha))

	var n_count = cfg["nozzle_count"]
	var engine_y = offset.y
	var nozzle_spread: float
	if r_id == "falcon9" or r_id == "falcon_heavy":
		nozzle_spread = w * 0.70
	elif r_id == "atlas_v_541":
		nozzle_spread = w * 0.56
	else:
		nozzle_spread = w * 0.60

	for n in range(n_count):
		var nx = offset.x
		if n_count > 1:
			var step_x = nozzle_spread / float(n_count - 1)
			nx = offset.x - nozzle_spread * 0.5 + n * step_x
		var bell_top_hw: float
		var bell_bot_hw: float
		var bell_h: float
		if r_id == "atlas_v_541":
			bell_top_hw = 4.5
			bell_bot_hw = 7.5
			bell_h = 9.0
		elif r_id == "vulcan":
			bell_top_hw = 4.2
			bell_bot_hw = 7.0
			bell_h = 9.0
		else:
			bell_top_hw = 3.8
			bell_bot_hw = 5.8
			bell_h = 8.5
		var nozzle_col = Color(0.20, 0.22, 0.26, alpha)
		draw_polygon(PackedVector2Array([
			Vector2(nx - bell_top_hw, engine_y),
			Vector2(nx + bell_top_hw, engine_y),
			Vector2(nx + bell_bot_hw, engine_y + bell_h),
			Vector2(nx - bell_bot_hw, engine_y + bell_h)
		]), [nozzle_col])
		draw_line(Vector2(nx - bell_top_hw, engine_y), Vector2(nx + bell_top_hw, engine_y), Color(0.42, 0.45, 0.50, alpha), 1.5)
		if r_id == "vulcan":
			draw_circle(Vector2(nx, engine_y + bell_h * 0.55), bell_top_hw * 0.65, Color(0.15, 0.40, 0.90, 0.60 * alpha))
		else:
			draw_circle(Vector2(nx, engine_y + bell_h * 0.55), bell_top_hw * 0.65, Color(0.08, 0.09, 0.12, 0.80 * alpha))

func draw_side_boosters(cfg: Dictionary, alpha: float = 1.0) -> void:
	if alpha <= 0.01:
		return
	var r_id = cfg["id"]
	var b_type = cfg["booster_type"]
	var w = cfg["w"]
	var bw = cfg["booster_w"]
	var bh = cfg["booster_h"]

	if b_type == "core":
		var by = -bh + stage1_pos.y
		var left_x = -w - 2.0 + booster_l_pos.x
		var left_rect = Rect2(left_x - bw * 0.5, by + booster_l_pos.y, bw, bh)
		draw_rect(left_rect, Color(0.95, 0.96, 0.98, alpha))
		draw_rect(Rect2(left_rect.position.x, left_rect.position.y, bw * 0.28, bh), Color(1.0, 1.0, 1.0, 0.13 * alpha))
		draw_rect(Rect2(left_rect.position.x + bw * 0.72, left_rect.position.y, bw * 0.28, bh), Color(0.0, 0.0, 0.0, 0.11 * alpha))
		draw_polygon(PackedVector2Array([
			Vector2(left_rect.position.x, by + booster_l_pos.y),
			Vector2(left_rect.position.x + bw, by + booster_l_pos.y),
			Vector2(left_rect.position.x + bw * 0.5, by + booster_l_pos.y - 24.0)
		]), [Color(0.95, 0.96, 0.98, alpha)])
		draw_rect(left_rect, Color(0.18, 0.20, 0.25, alpha), false, 1.5)

		var fin_w = 6.0
		var fin_h = 5.0
		var fin_y = by + booster_l_pos.y + 12.0
		draw_rect(Rect2(left_rect.position.x - fin_w, fin_y, fin_w, fin_h), Color(0.25, 0.28, 0.34, alpha))
		draw_rect(Rect2(left_rect.position.x - fin_w, fin_y, fin_w, fin_h), Color(0.40, 0.44, 0.50, alpha), false, 0.8)
		draw_line(Vector2(left_rect.position.x - fin_w + fin_w * 0.5, fin_y), Vector2(left_rect.position.x - fin_w + fin_w * 0.5, fin_y + fin_h), Color(0.40, 0.44, 0.50, 0.7 * alpha), 0.8)
		draw_line(Vector2(left_rect.position.x - fin_w, fin_y + fin_h * 0.5), Vector2(left_rect.position.x, fin_y + fin_h * 0.5), Color(0.40, 0.44, 0.50, 0.7 * alpha), 0.8)
		draw_rect(Rect2(left_rect.position.x + bw, fin_y, fin_w, fin_h), Color(0.25, 0.28, 0.34, alpha))
		draw_rect(Rect2(left_rect.position.x + bw, fin_y, fin_w, fin_h), Color(0.40, 0.44, 0.50, alpha), false, 0.8)
		draw_line(Vector2(left_rect.position.x + bw + fin_w * 0.5, fin_y), Vector2(left_rect.position.x + bw + fin_w * 0.5, fin_y + fin_h), Color(0.40, 0.44, 0.50, 0.7 * alpha), 0.8)
		draw_line(Vector2(left_rect.position.x + bw, fin_y + fin_h * 0.5), Vector2(left_rect.position.x + bw + fin_w, fin_y + fin_h * 0.5), Color(0.40, 0.44, 0.50, 0.7 * alpha), 0.8)

		var leg_h = 42.0
		var leg_top_y = by + bh + booster_l_pos.y - leg_h
		var leg_bot_y = by + bh + booster_l_pos.y
		draw_line(Vector2(left_rect.position.x, leg_top_y), Vector2(left_rect.position.x - 2.0, leg_bot_y), Color(0.15, 0.16, 0.18, alpha), 3.0)
		draw_line(Vector2(left_rect.position.x - 0.5, leg_top_y + 10.0), Vector2(left_rect.position.x - 4.0, leg_bot_y), Color(0.22, 0.24, 0.28, alpha), 1.6)
		draw_circle(Vector2(left_rect.position.x - 2.0, leg_bot_y), 2.5, Color(0.18, 0.20, 0.24, alpha))

		for n in range(3):
			var nx = left_x - bw * 0.3 + n * (bw * 0.3)
			draw_polygon(PackedVector2Array([
				Vector2(nx - 3.5, by + bh + booster_l_pos.y),
				Vector2(nx + 3.5, by + bh + booster_l_pos.y),
				Vector2(nx + 5.0, by + bh + booster_l_pos.y + 8.5),
				Vector2(nx - 5.0, by + bh + booster_l_pos.y + 8.5)
			]), [Color(0.20, 0.22, 0.26, alpha)])
			draw_line(Vector2(nx - 3.5, by + bh + booster_l_pos.y), Vector2(nx + 3.5, by + bh + booster_l_pos.y), Color(0.42, 0.45, 0.50, alpha), 1.4)
			draw_circle(Vector2(nx, by + bh + booster_l_pos.y + 7.0), 2.0, Color(0.08, 0.09, 0.12, 0.80 * alpha))

		var right_x = w + 2.0 + booster_r_pos.x
		var right_rect = Rect2(right_x - bw * 0.5, by + booster_r_pos.y, bw, bh)
		draw_rect(right_rect, Color(0.95, 0.96, 0.98, alpha))
		draw_rect(Rect2(right_rect.position.x, right_rect.position.y, bw * 0.28, bh), Color(1.0, 1.0, 1.0, 0.13 * alpha))
		draw_rect(Rect2(right_rect.position.x + bw * 0.72, right_rect.position.y, bw * 0.28, bh), Color(0.0, 0.0, 0.0, 0.11 * alpha))
		draw_polygon(PackedVector2Array([
			Vector2(right_rect.position.x, by + booster_r_pos.y),
			Vector2(right_rect.position.x + bw, by + booster_r_pos.y),
			Vector2(right_rect.position.x + bw * 0.5, by + booster_r_pos.y - 24.0)
		]), [Color(0.95, 0.96, 0.98, alpha)])
		draw_rect(right_rect, Color(0.18, 0.20, 0.25, alpha), false, 1.5)

		var rfin_y = by + booster_r_pos.y + 12.0
		draw_rect(Rect2(right_rect.position.x - fin_w, rfin_y, fin_w, fin_h), Color(0.25, 0.28, 0.34, alpha))
		draw_rect(Rect2(right_rect.position.x - fin_w, rfin_y, fin_w, fin_h), Color(0.40, 0.44, 0.50, alpha), false, 0.8)
		draw_line(Vector2(right_rect.position.x - fin_w + fin_w * 0.5, rfin_y), Vector2(right_rect.position.x - fin_w + fin_w * 0.5, rfin_y + fin_h), Color(0.40, 0.44, 0.50, 0.7 * alpha), 0.8)
		draw_line(Vector2(right_rect.position.x - fin_w, rfin_y + fin_h * 0.5), Vector2(right_rect.position.x, rfin_y + fin_h * 0.5), Color(0.40, 0.44, 0.50, 0.7 * alpha), 0.8)
		draw_rect(Rect2(right_rect.position.x + bw, rfin_y, fin_w, fin_h), Color(0.25, 0.28, 0.34, alpha))
		draw_rect(Rect2(right_rect.position.x + bw, rfin_y, fin_w, fin_h), Color(0.40, 0.44, 0.50, alpha), false, 0.8)
		draw_line(Vector2(right_rect.position.x + bw + fin_w * 0.5, rfin_y), Vector2(right_rect.position.x + bw + fin_w * 0.5, rfin_y + fin_h), Color(0.40, 0.44, 0.50, 0.7 * alpha), 0.8)
		draw_line(Vector2(right_rect.position.x + bw, rfin_y + fin_h * 0.5), Vector2(right_rect.position.x + bw + fin_w, rfin_y + fin_h * 0.5), Color(0.40, 0.44, 0.50, 0.7 * alpha), 0.8)

		var rleg_top_y = by + bh + booster_r_pos.y - leg_h
		var rleg_bot_y = by + bh + booster_r_pos.y
		draw_line(Vector2(right_rect.position.x + bw, rleg_top_y), Vector2(right_rect.position.x + bw + 2.0, rleg_bot_y), Color(0.15, 0.16, 0.18, alpha), 3.0)
		draw_line(Vector2(right_rect.position.x + bw + 0.5, rleg_top_y + 10.0), Vector2(right_rect.position.x + bw + 4.0, rleg_bot_y), Color(0.22, 0.24, 0.28, alpha), 1.6)
		draw_circle(Vector2(right_rect.position.x + bw + 2.0, rleg_bot_y), 2.5, Color(0.18, 0.20, 0.24, alpha))

		for n in range(3):
			var nx = right_x - bw * 0.3 + n * (bw * 0.3)
			draw_polygon(PackedVector2Array([
				Vector2(nx - 3.5, by + bh + booster_r_pos.y),
				Vector2(nx + 3.5, by + bh + booster_r_pos.y),
				Vector2(nx + 5.0, by + bh + booster_r_pos.y + 8.5),
				Vector2(nx - 5.0, by + bh + booster_r_pos.y + 8.5)
			]), [Color(0.20, 0.22, 0.26, alpha)])
			draw_line(Vector2(nx - 3.5, by + bh + booster_r_pos.y), Vector2(nx + 3.5, by + bh + booster_r_pos.y), Color(0.42, 0.45, 0.50, alpha), 1.4)
			draw_circle(Vector2(nx, by + bh + booster_r_pos.y + 7.0), 2.0, Color(0.08, 0.09, 0.12, 0.80 * alpha))

		if staging_stage == 0:
			draw_line(Vector2(left_x + bw * 0.5, by + bh * 0.3), Vector2(-w * 0.5, by + bh * 0.3), Color(0.3, 0.33, 0.38), 2.5)
			draw_line(Vector2(right_x - bw * 0.5, by + bh * 0.3), Vector2(w * 0.5, by + bh * 0.3), Color(0.3, 0.33, 0.38), 2.5)
			draw_line(Vector2(left_x + bw * 0.5, by + bh * 0.85), Vector2(-w * 0.5, by + bh * 0.85), Color(0.3, 0.33, 0.38), 2.5)
			draw_line(Vector2(right_x - bw * 0.5, by + bh * 0.85), Vector2(w * 0.5, by + bh * 0.85), Color(0.3, 0.33, 0.38), 2.5)

	elif b_type == "srb":
		var by = -bh + stage1_pos.y
		var b_col = Color(cfg["booster_col"].r, cfg["booster_col"].g, cfg["booster_col"].b, alpha)

		var left_x = -w * 0.5 - bw - 1.0 + booster_l_pos.x
		var left_rect = Rect2(left_x, by + booster_l_pos.y, bw, bh)
		draw_rect(left_rect, b_col)
		draw_rect(Rect2(left_x, by + booster_l_pos.y, bw * 0.30, bh), Color(1.0, 1.0, 1.0, 0.12 * alpha))
		draw_rect(Rect2(left_x + bw * 0.70, by + booster_l_pos.y, bw * 0.30, bh), Color(0.0, 0.0, 0.0, 0.10 * alpha))
		draw_polygon(PackedVector2Array([
			Vector2(left_x, by + booster_l_pos.y),
			Vector2(left_x + bw, by + booster_l_pos.y),
			Vector2(left_x + bw, by + booster_l_pos.y - 14.0)
		]), [b_col])
		draw_rect(left_rect, Color(0.2, 0.22, 0.26, alpha), false, 1.2)
		draw_polygon(PackedVector2Array([
			Vector2(left_x + 1.0, by + bh + booster_l_pos.y),
			Vector2(left_x + bw - 1.0, by + bh + booster_l_pos.y),
			Vector2(left_x + bw + 1.0, by + bh + booster_l_pos.y + 6.0),
			Vector2(left_x - 1.0, by + bh + booster_l_pos.y + 6.0)
		]), [Color(0.18, 0.20, 0.24, alpha)])

		var right_x = w * 0.5 + 1.0 + booster_r_pos.x
		var right_rect = Rect2(right_x, by + booster_r_pos.y, bw, bh)
		draw_rect(right_rect, b_col)
		draw_rect(Rect2(right_x, by + booster_r_pos.y, bw * 0.30, bh), Color(1.0, 1.0, 1.0, 0.12 * alpha))
		draw_rect(Rect2(right_x + bw * 0.70, by + booster_r_pos.y, bw * 0.30, bh), Color(0.0, 0.0, 0.0, 0.10 * alpha))
		draw_polygon(PackedVector2Array([
			Vector2(right_x, by + booster_r_pos.y),
			Vector2(right_x + bw, by + booster_r_pos.y),
			Vector2(right_x, by + booster_r_pos.y - 14.0)
		]), [b_col])
		draw_rect(right_rect, Color(0.2, 0.22, 0.26, alpha), false, 1.2)
		if r_id == "titan_iiie":
			for seg in range(5):
				var sy = by + booster_l_pos.y + seg * (bh / 5.0)
				draw_line(Vector2(left_x, sy), Vector2(left_x + bw, sy), Color(0.2, 0.22, 0.25, 0.7 * alpha), 1.5)
				var rsy = by + booster_r_pos.y + seg * (bh / 5.0)
				draw_line(Vector2(right_x, rsy), Vector2(right_x + bw, rsy), Color(0.2, 0.22, 0.25, 0.7 * alpha), 1.5)
			draw_polygon(PackedVector2Array([
				Vector2(left_x, by + booster_l_pos.y),
				Vector2(left_x + bw, by + booster_l_pos.y),
				Vector2(left_x + bw, by + booster_l_pos.y - 14.0)
			]), [Color(0.12, 0.14, 0.18, alpha)])
			draw_polygon(PackedVector2Array([
				Vector2(right_x, by + booster_r_pos.y),
				Vector2(right_x + bw, by + booster_r_pos.y),
				Vector2(right_x, by + booster_r_pos.y - 14.0)
			]), [Color(0.12, 0.14, 0.18, alpha)])

func draw_second_stage(cfg: Dictionary, top_y: float) -> void:
	var w = cfg["w"]
	var h = cfg["h_s2"]
	var body_rect = Rect2(-w * 0.5, top_y, w, h)
	draw_rect(body_rect, cfg["s2_col"])
	draw_rect(Rect2(-w * 0.5, top_y, w * 0.28, h), Color(1.0, 1.0, 1.0, 0.12))
	draw_rect(Rect2(-w * 0.5 + w * 0.72, top_y, w * 0.28, h), Color(0.0, 0.0, 0.0, 0.10))
	draw_line(Vector2(body_rect.position.x + 3.0, top_y), Vector2(body_rect.position.x + 3.0, top_y + h), Color(1.0, 1.0, 1.0, 0.6), 2.0)
	draw_rect(body_rect, Color(0.16, 0.18, 0.22), false, 1.6)

	var vac_nozzle = PackedVector2Array([
		Vector2(-4.5, top_y + h),
		Vector2(4.5, top_y + h),
		Vector2(8.5, top_y + h + 15.0),
		Vector2(-8.5, top_y + h + 15.0)
	])
	draw_polygon(vac_nozzle, [Color(0.22, 0.24, 0.28)])
	draw_line(Vector2(-4.5, top_y + h), Vector2(4.5, top_y + h), Color(0.42, 0.45, 0.50), 1.5)
	draw_circle(Vector2(0, top_y + h + 14.0), 5.5, Color(1.0, 0.55, 0.15, 0.7))

func draw_payload_probe(y: float) -> void:
	var hex_pts = PackedVector2Array()
	for i in range(6):
		var ang = deg_to_rad(30.0 + i * 60.0)
		hex_pts.append(Vector2(cos(ang) * 13.0, y - 13.0 + sin(ang) * 13.0))
	draw_polygon(hex_pts, [Color(0.95, 0.82, 0.35)])
	draw_polyline(hex_pts + PackedVector2Array([hex_pts[0]]), Color(0.2, 0.22, 0.26), 1.5)

	draw_rect(Rect2(-28.0, y - 3.5, 15.0, 7.0), Color(0.15, 0.45, 0.9))
	draw_rect(Rect2(-28.0, y - 3.5, 15.0, 7.0), Color(0.08, 0.28, 0.65), false, 1.0)
	draw_rect(Rect2(13.0, y - 3.5, 15.0, 7.0), Color(0.15, 0.45, 0.9))
	draw_rect(Rect2(13.0, y - 3.5, 15.0, 7.0), Color(0.08, 0.28, 0.65), false, 1.0)

	draw_arc(Vector2(0, y - 13.0), 7.0, deg_to_rad(200.0), deg_to_rad(340.0), 12, Color(0.92, 0.94, 0.98), 2.0)
	draw_circle(Vector2(0, y - 20.0), 2.5, Color(0.92, 0.94, 0.98))

func draw_fairing(cfg: Dictionary, base_y: float) -> void:
	var f_w = cfg["f_w"]
	var h = cfg["h_f"]
	var f_top = base_y - h
	var fairing_poly = PackedVector2Array([
		Vector2(-f_w, base_y),
		Vector2(-f_w, base_y - h * 0.62),
		Vector2(0, f_top),
		Vector2(f_w, base_y - h * 0.62),
		Vector2(f_w, base_y)
	])
	draw_polygon(fairing_poly, [Color(0.96, 0.97, 0.98)])

	var panel_step = 15.0
	var panel_count = int(h / panel_step)
	for pi in range(1, panel_count):
		var py = base_y - pi * panel_step
		var t = clamp((base_y - py) / h, 0.0, 1.0)
		var half_w = lerp(f_w, 0.0, (t - 0.38) / 0.62) if t > 0.38 else f_w
		if t <= 0.38:
			half_w = f_w
		else:
			half_w = lerp(f_w, 0.0, (t - 0.38) / 0.62)
		draw_line(Vector2(-half_w + 1.0, py), Vector2(half_w - 1.0, py), Color(0.80, 0.82, 0.86, 0.35), 0.8)

	var seam_seg = 5.0
	var seam_gap = 3.0
	var seam_y = f_top
	while seam_y < base_y:
		var seg_end = min(seam_y + seam_seg, base_y)
		draw_line(Vector2(0, seam_y), Vector2(0, seg_end), Color(0.25, 0.28, 0.32), 1.2)
		seam_y += seam_seg + seam_gap

	draw_polyline(fairing_poly, Color(0.16, 0.18, 0.22), 1.6)
	draw_circle(Vector2(0, f_top), 2.5, Color(0.75, 0.78, 0.84))

func draw_separating_fairings(cfg: Dictionary, base_y: float) -> void:
	var f_w = cfg["f_w"]
	var h = cfg["h_f"]
	var f_top = base_y - h
	var sep_dist = fairing_sep_dist

	var left_poly = PackedVector2Array([
		Vector2(-sep_dist, base_y + sep_dist * 0.3),
		Vector2(-f_w - sep_dist, base_y + sep_dist * 0.3),
		Vector2(-f_w - sep_dist * 1.3, base_y - h * 0.62 + sep_dist * 0.3),
		Vector2(-sep_dist, f_top + sep_dist * 0.3)
	])
	draw_polygon(left_poly, [Color(0.96, 0.97, 0.98)])
	draw_polyline(left_poly, Color(0.18, 0.20, 0.24), 1.4)

	var right_poly = PackedVector2Array([
		Vector2(sep_dist, base_y + sep_dist * 0.3),
		Vector2(f_w + sep_dist, base_y + sep_dist * 0.3),
		Vector2(f_w + sep_dist * 1.3, base_y - h * 0.62 + sep_dist * 0.3),
		Vector2(sep_dist, f_top + sep_dist * 0.3)
	])
	draw_polygon(right_poly, [Color(0.96, 0.97, 0.98)])
	draw_polyline(right_poly, Color(0.18, 0.20, 0.24), 1.4)
