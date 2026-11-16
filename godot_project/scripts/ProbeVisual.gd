extends Node2D

@export var scale_factor: float = 2.2
var anim_time: float = 0.0

func _process(delta: float) -> void:
	anim_time += delta
	queue_redraw()

func _draw() -> void:
	var build = GameState.get_current_build()
	var platform = build.get("platform", {})
	var power = build.get("power", {})
	var antenna = build.get("antenna", {})
	var instruments = build.get("instruments", [])
	var plat_type = platform.get("type", "orbiter")

	var s = scale_factor
	var hover = sin(anim_time * 1.8) * 3.5 if plat_type == "orbiter" else 0.0
	var center = Vector2(0, hover)

	if GameState.target_id == "interstellar" or str(platform.get("id")) == "voyager_bus":
		draw_voyager_spacecraft(center, s)
		return

	var foil_base = Color(0.95, 0.82, 0.35)
	var foil_shade = Color(0.72, 0.56, 0.18)
	var foil_highlight = Color(1.0, 0.94, 0.65)
	var metal_color = Color(0.58, 0.64, 0.72)
	var dark_metal = Color(0.14, 0.16, 0.20)
	var led_green = Color(0.18, 0.94, 0.58)

	var power_id = power.get("id", "solar")
	if power_id.begins_with("solar") or power_id == "solar_large" or power_id == "solar_std" or power_id == "solar_xl":
		var wing_w = 72.0 * s
		var wing_h = 26.0 * s
		var flap = sin(anim_time * 1.5) * 3.0

		draw_solar_wing(Rect2(center.x - 32.0 * s - wing_w, center.y - wing_h * 0.5 + flap, wing_w, wing_h), true, s)
		draw_line(Vector2(center.x - 32.0 * s, center.y + flap), Vector2(center.x - 18.0 * s, center.y), metal_color, 4.5)
		draw_circle(Vector2(center.x - 18.0 * s, center.y), 4.0, dark_metal)

		draw_solar_wing(Rect2(center.x + 32.0 * s, center.y - wing_h * 0.5 - flap, wing_w, wing_h), false, s)
		draw_line(Vector2(center.x + 32.0 * s, center.y - flap), Vector2(center.x + 18.0 * s, center.y), metal_color, 4.5)
		draw_circle(Vector2(center.x + 18.0 * s, center.y), 4.0, dark_metal)

	elif power_id.begins_with("rtg"):
		var rtg_w = 22.0 * s
		var rtg_h = 32.0 * s
		var rtg_rect = Rect2(center.x - 40.0 * s, center.y - rtg_h * 0.5, rtg_w, rtg_h)
		draw_rect(rtg_rect, Color(0.35, 0.38, 0.44))
		draw_rect(rtg_rect, dark_metal, false, 2.0)
		for f in range(6):
			var fy = rtg_rect.position.y + f * (rtg_h / 5.0)
			draw_line(Vector2(rtg_rect.position.x - 5.0, fy), Vector2(rtg_rect.position.x + rtg_w + 5.0, fy), Color(0.22, 0.24, 0.28), 3.0)
			draw_line(Vector2(rtg_rect.position.x - 5.0, fy - 1.0), Vector2(rtg_rect.position.x + rtg_w + 5.0, fy - 1.0), Color(0.5, 0.55, 0.62), 1.0)
		var pulse = 0.6 + sin(anim_time * 5.0) * 0.35
		draw_circle(Vector2(center.x - 29.0 * s, center.y), 7.0 * s * 0.4, Color(1.0, 0.32, 0.15, pulse))
		draw_circle(Vector2(center.x - 29.0 * s, center.y), 3.5 * s * 0.4, Color(1.0, 0.85, 0.3, pulse))

	if plat_type == "rover":
		var body_w = 52.0 * s
		var body_h = 32.0 * s
		var body_rect = Rect2(center.x - body_w * 0.5, center.y - body_h * 0.5, body_w, body_h)

		var chassis_rect = Rect2(body_rect.position.x + 2.0, body_rect.position.y + body_h * 0.45, body_w - 4.0, body_h * 0.55)
		draw_rect(chassis_rect, Color(0.22, 0.24, 0.28))
		draw_rect(chassis_rect, Color(0.12, 0.13, 0.16), false, 1.5)

		var deck_rect = Rect2(body_rect.position.x, body_rect.position.y, body_w, body_h * 0.5)
		draw_mli_gold_foil(deck_rect)

		var front_rect = Rect2(body_rect.position.x - 6.0 * s, body_rect.position.y + 2.0, 6.0 * s, body_h - 4.0)
		draw_rect(front_rect, Color(0.18, 0.20, 0.25))
		draw_rect(front_rect, Color(0.10, 0.11, 0.14), false, 1.0)

		var rear_rect = Rect2(body_rect.position.x + body_w, body_rect.position.y + 2.0, 5.0 * s, body_h - 4.0)
		draw_rect(rear_rect, Color(0.20, 0.22, 0.27))
		draw_rect(rear_rect, Color(0.10, 0.11, 0.14), false, 1.0)

		var hazcam_y = body_rect.position.y + body_h * 0.3
		draw_circle(Vector2(front_rect.position.x + 1.5, hazcam_y - 4.0), 2.5 * s * 0.4, Color(0.08, 0.12, 0.18))
		draw_circle(Vector2(front_rect.position.x + 1.5, hazcam_y + 4.0), 2.5 * s * 0.4, Color(0.08, 0.12, 0.18))

		var wheel_r = 8.5 * s
		var wheel_y = center.y + 25.0 * s
		var axle_xs = [center.x - 28.0 * s, center.x, center.x + 28.0 * s]

		for ax in axle_xs:
			var arm_top = Vector2(ax, center.y + body_h * 0.5 - 2.0)
			var arm_bot = Vector2(ax + 3.0, wheel_y - wheel_r)
			var arm_rect = Rect2(
				min(arm_top.x, arm_bot.x) - 2.0,
				arm_top.y,
				abs(arm_bot.x - arm_top.x) + 4.0,
				arm_bot.y - arm_top.y
			)
			draw_rect(arm_rect, Color(0.32, 0.35, 0.42))
			draw_line(arm_top, arm_bot, metal_color, 4.0)

		draw_line(Vector2(axle_xs[0], wheel_y - wheel_r), Vector2(axle_xs[1], center.y + 10.0 * s), metal_color, 4.0)
		draw_line(Vector2(axle_xs[1], center.y + 10.0 * s), Vector2(axle_xs[2], wheel_y - wheel_r), metal_color, 4.0)

		for wx in axle_xs:
			draw_line(Vector2(wx, center.y + 10.0 * s), Vector2(wx, wheel_y), dark_metal, 4.0)
			draw_wheel_textured(Vector2(wx, wheel_y), wheel_r)

		var mast_base = Vector2(center.x + 16.0 * s, center.y - body_h * 0.5)
		var mast_top = Vector2(center.x + 20.0 * s, center.y - 44.0 * s)
		draw_line(mast_base, mast_top, metal_color, 4.5)
		draw_line(mast_base + Vector2(2, 0), mast_top + Vector2(2, 0), Color(0.85, 0.90, 0.95), 1.5)
		draw_circle(mast_base, 5.0 * s * 0.4, Color(0.28, 0.32, 0.38))
		draw_circle(mast_base, 3.0 * s * 0.4, metal_color)

		var mast_pan = sin(anim_time * 1.4) * 2.5
		var mast_tilt = cos(anim_time * 0.9) * 1.2
		var head_pos = mast_top + Vector2(mast_pan, mast_tilt)
		var head_rect = Rect2(head_pos.x - 7.0 * s, head_pos.y - 5.0 * s, 16.0 * s, 10.0 * s)
		draw_rect(head_rect, dark_metal)
		draw_rect(head_rect, Color(0.4, 0.45, 0.52), false, 1.5)

		draw_circle(head_pos + Vector2(1.5 * s, 0), 4.0 * s * 0.7, Color(0.08, 0.12, 0.18))
		draw_circle(head_pos + Vector2(1.5 * s, 0), 3.2 * s * 0.7, Color(0.15, 0.65, 0.95))
		draw_circle(head_pos + Vector2(0.5 * s, -1.0 * s * 0.7), 1.2 * s * 0.7, Color(1, 1, 1, 0.9))

		draw_circle(head_pos + Vector2(6.5 * s, 0), 3.0 * s * 0.7, Color(0.08, 0.12, 0.18))
		draw_circle(head_pos + Vector2(6.5 * s, 0), 2.2 * s * 0.7, Color(0.95, 0.35, 0.15))
		if fmod(anim_time * 0.8, 3.0) < 0.25:
			draw_circle(head_pos + Vector2(6.5 * s, 0), 4.5, Color(1.0, 0.3, 0.2, 0.75))

		var arm_base = Vector2(front_rect.position.x, center.y + body_h * 0.5 - 2.0 * s)
		var arm_shoulder = arm_base + Vector2(-3.0 * s, 2.0 * s)
		var arm_elbow = arm_shoulder + Vector2(-10.0 * s, 12.0 * s + sin(anim_time * 1.2) * 1.5 * s)
		var arm_wrist = arm_elbow + Vector2(-7.0 * s, 10.0 * s + cos(anim_time * 1.2) * 1.5 * s)
		draw_line(arm_base, arm_shoulder, dark_metal, 4.0)
		draw_line(arm_shoulder, arm_elbow, metal_color, 3.6)
		draw_circle(arm_shoulder, 3.5 * s * 0.4, dark_metal)
		draw_line(arm_elbow, arm_wrist, metal_color, 2.8)
		draw_circle(arm_elbow, 3.0 * s * 0.4, dark_metal)
		draw_rect(Rect2(arm_wrist.x - 3.5 * s, arm_wrist.y - 3.0 * s, 7.0 * s, 6.0 * s), dark_metal)
		draw_line(arm_wrist, arm_wrist + Vector2(0.0, 5.0 * s), Color(0.88, 0.92, 0.96), 2.2)
		draw_circle(arm_wrist + Vector2(0.0, 5.5 * s), 1.6 * s, Color(0.95, 0.65, 0.25))

	elif plat_type == "lander":
		var r_hex = 22.0 * s
		var hex_pts = PackedVector2Array()
		for i in range(6):
			var ang = i * TAU / 6.0 - PI / 6.0
			hex_pts.append(center + Vector2(cos(ang), sin(ang)) * r_hex)
		draw_polygon(hex_pts, [foil_base])

		for i in range(5):
			var t_ratio = float(i) / 4.0
			var r_cur = lerp(r_hex * 0.3, r_hex, t_ratio)
			draw_arc(center, r_cur, 0, TAU, 24, foil_shade, 1.0)

		draw_polyline(hex_pts, dark_metal, 3.0)
		var close_line = PackedVector2Array([hex_pts[hex_pts.size() - 1], hex_pts[0]])
		draw_polyline(close_line, dark_metal, 3.0)

		var noz_offsets = [-14.0 * s, 0.0, 14.0 * s]
		for nx_off in noz_offsets:
			var noz_top = PackedVector2Array([
				Vector2(center.x + nx_off - 5.0 * s, center.y + r_hex * 0.85),
				Vector2(center.x + nx_off + 5.0 * s, center.y + r_hex * 0.85),
				Vector2(center.x + nx_off + 7.0 * s, center.y + r_hex + 8.0 * s),
				Vector2(center.x + nx_off - 7.0 * s, center.y + r_hex + 8.0 * s)
			])
			draw_polygon(noz_top, [dark_metal])
			draw_polyline(noz_top, Color(0.4, 0.44, 0.52), 1.5)

		var leg_angles = [PI * 0.5 + TAU / 3.0, PI * 0.5, PI * 0.5 - TAU / 3.0]
		var leg_bot_r = r_hex + 24.0 * s
		for la in leg_angles:
			var leg_attach = center + Vector2(cos(la), sin(la)) * (r_hex * 0.9)
			var leg_foot = center + Vector2(cos(la), sin(la)) * leg_bot_r
			draw_line(leg_attach, leg_foot, metal_color, 4.5)
			draw_circle(leg_foot, 7.0 * s * 0.4, dark_metal)
			draw_circle(leg_foot, 5.0 * s * 0.4, metal_color)

		var sci_rect = Rect2(center.x - 10.0 * s, center.y - r_hex - 10.0 * s, 20.0 * s, 8.0 * s)
		draw_rect(sci_rect, Color(0.28, 0.32, 0.38))
		draw_rect(sci_rect, metal_color, false, 1.5)
		draw_circle(Vector2(sci_rect.position.x + sci_rect.size.x * 0.3, sci_rect.position.y + sci_rect.size.y * 0.5), 2.0 * s * 0.4, led_green)
		draw_circle(Vector2(sci_rect.position.x + sci_rect.size.x * 0.7, sci_rect.position.y + sci_rect.size.y * 0.5), 2.0 * s * 0.4, led_green)

	else:
		var bus_w = 40.0 * s
		var bus_h = 48.0 * s
		var bus_rect = Rect2(center.x - bus_w * 0.5, center.y - bus_h * 0.5, bus_w, bus_h)

		var foil_rect = Rect2(bus_rect.position.x - 3.0, bus_rect.position.y - 3.0, bus_w + 6.0, bus_h + 6.0)
		draw_mli_gold_foil(foil_rect)

		var panel_rect = Rect2(bus_rect.position.x + bus_w * 0.3, bus_rect.position.y, bus_w * 0.7, bus_h)
		draw_rect(panel_rect, Color(0.26, 0.29, 0.35, 0.85))
		draw_rect(panel_rect, Color(0.18, 0.20, 0.25), false, 1.5)

		var tracker_rect = Rect2(bus_rect.position.x + bus_w - 4.0, center.y - 6.0 * s, 8.0 * s, 12.0 * s)
		draw_rect(tracker_rect, Color(0.12, 0.14, 0.18))
		draw_rect(tracker_rect, Color(0.35, 0.38, 0.45), false, 1.0)

		var corner_offsets = [
			Vector2(-bus_w * 0.5 - 2.0, -bus_h * 0.5 - 2.0),
			Vector2(bus_w * 0.5 + 2.0, -bus_h * 0.5 - 2.0),
			Vector2(bus_w * 0.5 + 2.0, bus_h * 0.5 + 2.0),
			Vector2(-bus_w * 0.5 - 2.0, bus_h * 0.5 + 2.0)
		]
		var nozzle_dirs = [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
		var rcs_active = sin(anim_time * 2.8) > 0.82
		for ci in range(4):
			var cp = center + corner_offsets[ci]
			var nd = nozzle_dirs[ci]
			var noz_poly = PackedVector2Array([
				cp,
				cp + nd * Vector2(5.0, 0),
				cp + nd * Vector2(7.0, 4.0),
				cp + nd * Vector2(0, 4.0)
			])
			draw_polygon(noz_poly, [Color(0.20, 0.22, 0.28)])
			draw_polyline(noz_poly, Color(0.4, 0.44, 0.52), 1.0)
			if rcs_active and (ci == 0 or ci == 2):
				var puff_dir = nd.normalized()
				var puff_poly = PackedVector2Array([
					cp + puff_dir * 4.0,
					cp + puff_dir * 14.0 + Vector2(-puff_dir.y, puff_dir.x) * 4.5,
					cp + puff_dir * 14.0 - Vector2(-puff_dir.y, puff_dir.x) * 4.5
				])
				draw_polygon(puff_poly, [Color(0.5, 0.85, 1.0, 0.55)])

		var rw_center = center + Vector2(-bus_w * 0.25, 0)
		draw_circle(rw_center, 10.0 * s * 0.4, Color(0.25, 0.28, 0.35))
		draw_circle(rw_center, 11.0 * s * 0.4, Color(0.65, 0.70, 0.78))
		draw_circle(rw_center, 5.0 * s * 0.4, dark_metal)
		var rw_ang = anim_time * 1.5
		var rw_tip = rw_center + Vector2(cos(rw_ang), sin(rw_ang)) * (10.0 * s * 0.4)
		draw_line(rw_center, rw_tip, Color(0.9, 0.95, 1.0), 2.0)

		draw_polygon(PackedVector2Array([
			Vector2(center.x - 14.0 * s, center.y + bus_h * 0.5),
			Vector2(center.x + 14.0 * s, center.y + bus_h * 0.5),
			Vector2(center.x + 18.0 * s, center.y + bus_h * 0.5 + 14.0 * s),
			Vector2(center.x - 18.0 * s, center.y + bus_h * 0.5 + 14.0 * s)
		]), [dark_metal])

	var deck_y = center.y - 16.0 * s
	if plat_type == "lander":
		deck_y = center.y - 30.0 * s
	elif plat_type == "orbiter":
		deck_y = center.y - 24.0 * s

	var ant_id = antenna.get("id", "omni")
	var mount_x = center.x - 14.0 * s
	var mount_pos = Vector2(mount_x, deck_y)

	if ant_id.begins_with("hga"):
		var dish_r = 22.0 * s if ant_id == "hga_large" else 16.0 * s
		var dish_c = Vector2(mount_x, deck_y - dish_r * 0.85 - 12.0 * s)
		draw_dish_textured(dish_c, dish_r, mount_pos, metal_color, dark_metal)
	else:
		var base_mount = Rect2(mount_x - 5.0 * s * 0.5, deck_y - 4.0 * s, 5.0 * s, 4.0 * s)
		draw_rect(base_mount, dark_metal)
		draw_rect(base_mount, metal_color, false, 1.2)

		var seg_len = 7.0 * s
		var seg_starts = [deck_y - 4.0 * s, deck_y - 4.0 * s - seg_len, deck_y - 4.0 * s - seg_len * 2.0]
		for si in range(3):
			draw_line(Vector2(mount_x, seg_starts[si]), Vector2(mount_x, seg_starts[si] - seg_len), metal_color, 3.5 - si * 0.8)
			if si < 2:
				draw_circle(Vector2(mount_x, seg_starts[si] - seg_len), 2.5, Color(0.4, 0.44, 0.52))

		var whip_top = Vector2(mount_x, seg_starts[2] - seg_len)
		var tip_r = 3.5 + sin(anim_time * 3.5) * 1.5
		draw_circle(whip_top, tip_r, Color(0.18, 0.88, 1.0))
		draw_circle(whip_top, tip_r * 0.5, Color.WHITE)

		for ow in range(3):
			var ow_phase = fmod(anim_time * 1.8 + float(ow) * 0.33, 1.0)
			var wave_r = 6.0 + ow_phase * 26.0 * s
			var wave_a = (1.0 - ow_phase) * 0.55
			draw_arc(whip_top, wave_r, 0, TAU, 20, Color(0.2, 0.9, 1.0, wave_a), 1.4)

	var inst_count = instruments.size()
	for i in range(inst_count):
		var ang = (float(i) / max(1.0, float(inst_count))) * TAU
		var ix = center.x + cos(ang) * (26.0 * s)
		var iy = center.y + sin(ang) * (20.0 * s)
		draw_circle(Vector2(ix, iy), 6.0, dark_metal)
		draw_circle(Vector2(ix, iy), 4.5, led_green)
		draw_circle(Vector2(ix, iy), 2.0, Color.WHITE)

func draw_mli_gold_foil(rect: Rect2) -> void:
	var foil_base = Color(0.95, 0.82, 0.35)
	var foil_shade = Color(0.74, 0.58, 0.20)
	var foil_hi = Color(1.0, 0.95, 0.68)
	var dark_metal = Color(0.16, 0.18, 0.22)

	draw_rect(rect, foil_base)

	var cell_w = 12.0
	var cell_h = 10.0
	var cols = int(rect.size.x / cell_w)
	var rows = int(rect.size.y / cell_h)

	for r in range(rows):
		for c in range(cols):
			var cx = rect.position.x + c * cell_w
			var cy = rect.position.y + r * cell_h
			draw_line(Vector2(cx, cy), Vector2(cx + cell_w, cy), foil_hi, 0.8)
			draw_line(Vector2(cx, cy), Vector2(cx, cy + cell_h), foil_hi, 0.8)
			draw_line(Vector2(cx + cell_w, cy), Vector2(cx + cell_w, cy + cell_h), foil_shade, 0.8)
			draw_line(Vector2(cx, cy + cell_h), Vector2(cx + cell_w, cy + cell_h), foil_shade, 0.8)

	draw_rect(rect, dark_metal, false, 2.5)

func draw_solar_wing(rect: Rect2, _is_left: bool, _s: float) -> void:
	var dark_bg = Color(0.06, 0.12, 0.24)
	var cell_color = Color(0.14, 0.38, 0.78)
	var busbar_color = Color(0.75, 0.85, 0.95, 0.8)
	var frame_color = Color(0.85, 0.88, 0.92)
	var shimmer_color = Color(0.4, 0.75, 1.0, 0.55)
	var shadow_color = Color(0.08, 0.20, 0.50, 0.5)

	draw_rect(rect, dark_bg)

	var cell_cols = 6
	var cell_rows = 3
	var cw = (rect.size.x - 4.0) / float(cell_cols)
	var ch = (rect.size.y - 4.0) / float(cell_rows)

	for r in range(cell_rows):
		for c in range(cell_cols):
			var cell_index = r * cell_cols + c
			var cx = rect.position.x + 2.0 + c * cw + 1.0
			var cy = rect.position.y + 2.0 + r * ch + 1.0
			var cell_rect = Rect2(cx, cy, cw - 2.0, ch - 2.0)
			draw_rect(cell_rect, cell_color)

			draw_line(Vector2(cx, cy), Vector2(cx + (cw - 2.0), cy + (ch - 2.0)), shadow_color, 1.0)

			draw_line(Vector2(cx, cy + (ch - 2.0) * 0.5), Vector2(cx + cw - 2.0, cy + (ch - 2.0) * 0.5), busbar_color, 1.2)
			for f in range(3):
				var fx = cx + (f + 1) * ((cw - 2.0) / 4.0)
				draw_line(Vector2(fx, cy), Vector2(fx, cy + ch - 2.0), Color(0.4, 0.65, 0.9, 0.4), 0.8)

			if sin(anim_time * 3.0 + cell_index) > 0.8:
				draw_rect(cell_rect, shimmer_color)

	var cut = 5.0
	draw_polygon(PackedVector2Array([
		rect.position,
		Vector2(rect.position.x + cut, rect.position.y),
		rect.position + Vector2(0, cut)
	]), [dark_bg])
	draw_polygon(PackedVector2Array([
		Vector2(rect.position.x + rect.size.x - cut, rect.position.y),
		Vector2(rect.position.x + rect.size.x, rect.position.y),
		Vector2(rect.position.x + rect.size.x, rect.position.y + cut)
	]), [dark_bg])
	draw_polygon(PackedVector2Array([
		Vector2(rect.position.x, rect.position.y + rect.size.y - cut),
		Vector2(rect.position.x, rect.position.y + rect.size.y),
		Vector2(rect.position.x + cut, rect.position.y + rect.size.y)
	]), [dark_bg])
	draw_polygon(PackedVector2Array([
		Vector2(rect.position.x + rect.size.x - cut, rect.position.y + rect.size.y),
		Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y),
		Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y - cut)
	]), [dark_bg])

	draw_rect(rect, frame_color, false, 2.0)

func draw_wheel_textured(pos: Vector2, radius: float) -> void:
	var tire_color = Color(0.18, 0.20, 0.24)
	var rim_color = Color(0.68, 0.72, 0.78)
	var spoke_color = Color(0.32, 0.35, 0.40)
	var tread_dark = Color(0.10, 0.11, 0.14)

	draw_circle(pos, radius, tire_color)

	for t in range(12):
		var t_ang_start = t * TAU / 12.0
		var t_ang_end = t_ang_start + TAU / 24.0
		var t_col = tread_dark if t % 2 == 0 else rim_color
		draw_arc(pos, radius - 1.0, t_ang_start, t_ang_end, 6, t_col, 4.0)

	draw_circle(pos, radius - 5.0, spoke_color)

	for g in range(8):
		var ang = g * (TAU / 8.0) + anim_time * 2.0
		var p1 = pos + Vector2(cos(ang), sin(ang)) * (radius - 5.0)
		var p2 = pos + Vector2(cos(ang), sin(ang)) * (radius - 2.5)
		draw_line(p1, p2, Color(0.1, 0.1, 0.12), 2.0)
		var hub_tip = pos + Vector2(cos(ang), sin(ang)) * (radius - 5.0)
		draw_line(pos, hub_tip, Color(0.45, 0.48, 0.55), 1.2)

	for b in range(3):
		var bolt_ang = b * TAU / 3.0 + PI / 6.0
		var bolt_pos = pos + Vector2(cos(bolt_ang), sin(bolt_ang)) * (radius * 0.4)
		draw_circle(bolt_pos, 2.0, Color(0.14, 0.16, 0.20))
		draw_circle(bolt_pos, 1.0, Color(0.55, 0.58, 0.65))

	draw_circle(pos, 3.0, Color(0.14, 0.16, 0.20))
	draw_circle(pos, 1.5, Color.WHITE)

func draw_dish_textured(center: Vector2, radius: float, mount_base: Vector2, metal_col: Color, dark_col: Color) -> void:
	var tilt = sin(anim_time * 0.8) * 14.0 * PI / 180.0
	var arc_start = PI * 0.85 + tilt
	var arc_end = PI * 2.15 + tilt

	var base_w = 8.0
	draw_rect(Rect2(mount_base.x - base_w, mount_base.y - 3.5, base_w * 2.0, 5.0), dark_col)
	draw_rect(Rect2(mount_base.x - base_w, mount_base.y - 3.5, base_w * 2.0, 5.0), metal_col, false, 1.2)
	draw_circle(Vector2(mount_base.x - base_w + 2.0, mount_base.y - 1.0), 1.2, metal_col)
	draw_circle(Vector2(mount_base.x + base_w - 2.0, mount_base.y - 1.0), 1.2, metal_col)

	var mast_mid = center + Vector2(0, 4.0)
	draw_line(mount_base + Vector2(-3.0, 0), mast_mid + Vector2(-2.5, 0), Color(0.35, 0.40, 0.48), 3.5)
	draw_line(mount_base + Vector2(3.0, 0), mast_mid + Vector2(2.5, 0), Color(0.35, 0.40, 0.48), 3.5)
	draw_line(mount_base, mast_mid, metal_col, 2.5)

	var brace_pt = mount_base.lerp(mast_mid, 0.5)
	draw_line(brace_pt - Vector2(4, 0), brace_pt + Vector2(4, 0), metal_col, 2.0)
	draw_circle(brace_pt, 2.5, dark_col)

	draw_circle(mast_mid, 5.0, dark_col)
	draw_circle(mast_mid, 3.5, metal_col)
	draw_circle(mast_mid, 1.8, dark_col)

	var dish_pts: PackedVector2Array = []
	var seg_count = 24
	for i in range(seg_count + 1):
		var t = float(i) / float(seg_count)
		var a = lerp(arc_start, arc_end, t)
		dish_pts.append(center + Vector2(cos(a), sin(a)) * radius)

	var inner_pts: PackedVector2Array = []
	for i in range(seg_count, -1, -1):
		var t = float(i) / float(seg_count)
		var a = lerp(arc_start, arc_end, t)
		inner_pts.append(center + Vector2(cos(a), sin(a)) * (radius * 0.75))

	var solid_dish = dish_pts + inner_pts
	draw_colored_polygon(solid_dish, Color(0.20, 0.24, 0.30))
	draw_polyline(dish_pts, Color(0.95, 0.98, 1.0), 3.0)
	draw_polyline(inner_pts, Color(0.70, 0.78, 0.88), 1.8)

	for rib_i in range(5):
		var rib_t = rib_i / 4.0
		var rib_a = lerp(arc_start, arc_end, rib_t)
		var p_inner = center + Vector2(cos(rib_a), sin(rib_a)) * (radius * 0.75)
		var p_outer = center + Vector2(cos(rib_a), sin(rib_a)) * radius
		draw_line(p_inner, p_outer, Color(0.55, 0.65, 0.78, 0.6), 1.0)

	var rim_left = center + Vector2(cos(arc_start), sin(arc_start)) * radius
	var rim_right = center + Vector2(cos(arc_end), sin(arc_end)) * radius
	var horn_dir = Vector2(cos((arc_start + arc_end) * 0.5), sin((arc_start + arc_end) * 0.5))
	var horn_pos = center - horn_dir * (radius * 0.65)

	draw_line(rim_left, horn_pos, Color(0.55, 0.62, 0.72), 1.5)
	draw_line(rim_right, horn_pos, Color(0.55, 0.62, 0.72), 1.5)
	draw_line(mast_mid, horn_pos, Color(0.40, 0.48, 0.58), 1.2)
	draw_circle(horn_pos, 4.5, Color(0.18, 0.92, 1.0))
	draw_circle(horn_pos, 2.0, Color.WHITE)

	for rw in range(4):
		var rw_phase = fmod(anim_time * 2.2 + float(rw) * 0.25, 1.0)
		var wave_r = 10.0 + rw_phase * 42.0
		var wave_a = (1.0 - rw_phase) * 0.7
		var w_start = arc_start + 0.3
		var w_end = arc_end - 0.3
		draw_arc(horn_pos, wave_r, w_start, w_end, 20, Color(0.2, 0.9, 1.0, wave_a), 2.0)

func draw_voyager_spacecraft(center: Vector2, s: float) -> void:
	var float_y = sin(anim_time * 1.5) * 4.0
	var c = center + Vector2(0, float_y)

	var dish_r = 38.0 * s
	var dish_c = c + Vector2(0, -6.0 * s)
	draw_circle(dish_c, dish_r, Color(0.94, 0.96, 0.98))
	draw_circle(dish_c, dish_r * 0.85, Color(0.88, 0.91, 0.95))
	draw_circle(dish_c, dish_r * 0.55, Color(0.78, 0.82, 0.88))
	draw_arc(dish_c, dish_r, 0, TAU, 48, Color(0.65, 0.70, 0.78), 2.0)

	var sub_r = 7.0 * s
	draw_circle(dish_c, sub_r, Color(0.25, 0.28, 0.35))
	draw_circle(dish_c, sub_r * 0.6, Color(1.0, 0.82, 0.25))

	for i in range(3):
		var a = i * TAU / 3.0 + anim_time * 0.05
		var tip = dish_c + Vector2(cos(a), sin(a)) * (dish_r * 0.92)
		draw_line(dish_c, tip, Color(0.35, 0.40, 0.48), 1.5)

	var bus_w = 42.0 * s
	var bus_h = 24.0 * s
	var bus_rect = Rect2(c.x - bus_w * 0.5, c.y + 12.0 * s, bus_w, bus_h)
	draw_rect(bus_rect, Color(0.88, 0.72, 0.25))
	draw_rect(Rect2(bus_rect.position.x, bus_rect.position.y, bus_w * 0.3, bus_h), Color(1.0, 0.85, 0.45, 0.3))
	draw_rect(bus_rect, Color(0.35, 0.28, 0.10), false, 2.0)

	for b in range(5):
		var bx = bus_rect.position.x + b * (bus_w / 4.0)
		draw_line(Vector2(bx, bus_rect.position.y), Vector2(bx, bus_rect.position.y + bus_h), Color(0.55, 0.42, 0.15, 0.6), 1.2)

	var rec_c = c + Vector2(-9.0 * s, 24.0 * s)
	var rec_r = 10.5 * s
	draw_circle(rec_c, rec_r, Color(0.98, 0.82, 0.22))
	draw_circle(rec_c, rec_r * 0.8, Color(0.82, 0.68, 0.18))
	draw_circle(rec_c, rec_r * 0.25, Color(0.2, 0.18, 0.12))
	draw_arc(rec_c, rec_r, 0, TAU, 32, Color(1.0, 0.95, 0.6), 1.5)
	for i in range(6):
		var ra = i * TAU / 6.0
		draw_line(rec_c, rec_c + Vector2(cos(ra), sin(ra)) * (rec_r * 0.75), Color(0.55, 0.45, 0.12, 0.8), 1.0)

	var mag_start = c + Vector2(-bus_w * 0.5, 18.0 * s)
	var mag_end = mag_start + Vector2(-85.0 * s, 10.0 * s)
	draw_line(mag_start, mag_end, Color(0.70, 0.75, 0.82), 2.0)
	var mag_top = mag_start + Vector2(0, -4.0 * s)
	var mag_top_end = mag_end + Vector2(0, -4.0 * s)
	draw_line(mag_top, mag_top_end, Color(0.70, 0.75, 0.82), 1.5)
	for i in range(8):
		var t = float(i) / 7.0
		var p1 = mag_start.lerp(mag_end, t)
		var p2 = mag_top.lerp(mag_top_end, t)
		draw_line(p1, p2, Color(0.5, 0.55, 0.65), 1.2)
	draw_rect(Rect2(mag_end.x - 5.0 * s, mag_end.y - 7.0 * s, 10.0 * s, 6.0 * s), Color(0.9, 0.92, 0.95))
	var mag_mid = mag_start.lerp(mag_end, 0.5)
	draw_rect(Rect2(mag_mid.x - 4.0 * s, mag_mid.y - 6.0 * s, 8.0 * s, 5.0 * s), Color(0.9, 0.92, 0.95))

	var rtg_start = c + Vector2(bus_w * 0.5, 22.0 * s)
	var rtg_end = rtg_start + Vector2(48.0 * s, 18.0 * s)
	draw_line(rtg_start, rtg_end, Color(0.45, 0.50, 0.58), 3.0)
	for r in range(3):
		var rp = rtg_start.lerp(rtg_end, 0.35 + r * 0.28)
		var rtg_box = Rect2(rp.x - 5.0 * s, rp.y - 10.0 * s, 10.0 * s, 20.0 * s)
		draw_rect(rtg_box, Color(0.22, 0.24, 0.28))
		draw_rect(rtg_box, Color(0.45, 0.50, 0.58), false, 1.2)
		draw_circle(rp, 2.5 * s, Color(1.0, 0.45, 0.15, 0.85))

	var scan_start = c + Vector2(bus_w * 0.45, 12.0 * s)
	var scan_end = scan_start + Vector2(38.0 * s, -22.0 * s)
	draw_line(scan_start, scan_end, Color(0.55, 0.60, 0.70), 2.5)
	var plat_box = Rect2(scan_end.x - 8.0 * s, scan_end.y - 8.0 * s, 16.0 * s, 16.0 * s)
	draw_rect(plat_box, Color(0.28, 0.32, 0.38))
	draw_rect(plat_box, Color(0.65, 0.72, 0.82), false, 1.5)
	draw_rect(Rect2(scan_end.x + 8.0 * s, scan_end.y - 6.0 * s, 12.0 * s, 5.0 * s), Color(0.12, 0.14, 0.18))
	draw_rect(Rect2(scan_end.x + 8.0 * s, scan_end.y + 1.0 * s, 10.0 * s, 6.0 * s), Color(0.12, 0.14, 0.18))

	draw_line(c + Vector2(-15.0 * s, 36.0 * s), c + Vector2(-65.0 * s, 85.0 * s), Color(0.85, 0.90, 0.98), 1.0)
	draw_line(c + Vector2(15.0 * s, 36.0 * s), c + Vector2(65.0 * s, 85.0 * s), Color(0.85, 0.90, 0.98), 1.0)

	for pw in range(3):
		var phase = fmod(anim_time * 1.8 + float(pw) * 0.33, 1.0)
		var rad = sub_r + phase * 45.0 * s
		var alpha = (1.0 - phase) * 0.65
		draw_arc(dish_c, rad, PI * 1.05, PI * 1.95, 24, Color(0.0, 0.9, 1.0, alpha), 2.0)
