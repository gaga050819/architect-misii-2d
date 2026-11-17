extends Node2D

@export var cell_size: float = 24.0
@export var grid_origin: Vector2 = Vector2(340.0, 480.0)

var selected_index: int = -1
var symmetry_mode: bool = false
var anim_pulse: float = 0.0

func _process(delta: float) -> void:
	anim_pulse += delta * 4.0
	queue_redraw()

func _draw() -> void:
	var vp = get_viewport_rect().size
	draw_blueprint_grid(vp)
	draw_center_axis(vp)
	draw_launch_pad(vp)
	draw_placed_parts()
	if selected_index >= 0 and selected_index < GameState.custom_rocket_placed_parts.size():
		draw_selection_highlight(GameState.custom_rocket_placed_parts[selected_index])

func draw_blueprint_grid(vp: Vector2) -> void:
	var grid_col = Color(0.18, 0.35, 0.55, 0.18)
	var major_col = Color(0.22, 0.48, 0.72, 0.32)
	var step = cell_size

	var start_x = fmod(grid_origin.x, step)
	while start_x < vp.x:
		var is_major = abs(fmod(start_x - grid_origin.x, step * 4.0)) < 1.0
		var c = major_col if is_major else grid_col
		draw_line(Vector2(start_x, 0), Vector2(start_x, vp.y), c, 1.0)
		start_x += step

	var start_y = fmod(grid_origin.y, step)
	while start_y < vp.y:
		var is_major = abs(fmod(start_y - grid_origin.y, step * 4.0)) < 1.0
		var c = major_col if is_major else grid_col
		draw_line(Vector2(0, start_y), Vector2(vp.x, start_y), c, 1.0)
		start_y += step

func draw_center_axis(vp: Vector2) -> void:
	var axis_col = Color(0.0, 0.85, 1.0, 0.45)
	var cx = grid_origin.x
	var y = 0.0
	while y < vp.y:
		draw_line(Vector2(cx, y), Vector2(cx, y + 10.0), axis_col, 1.5)
		y += 18.0

func draw_launch_pad(_vp: Vector2) -> void:
	var cx = grid_origin.x
	var ground_y = grid_origin.y
	var pad_w = cell_size * 12.0
	var pad_rect = Rect2(cx - pad_w * 0.5, ground_y, pad_w, 24.0)
	draw_rect(pad_rect, Color(0.14, 0.18, 0.24, 0.95))
	draw_rect(pad_rect, Color(0.35, 0.42, 0.52), false, 1.5)

	var clamp_l = Rect2(cx - cell_size * 3.5, ground_y - 20.0, cell_size * 1.2, 20.0)
	var clamp_r = Rect2(cx + cell_size * 2.3, ground_y - 20.0, cell_size * 1.2, 20.0)
	draw_rect(clamp_l, Color(0.85, 0.35, 0.15, 0.85))
	draw_rect(clamp_r, Color(0.85, 0.35, 0.15, 0.85))
	draw_rect(clamp_l, Color(0.2, 0.2, 0.2), false, 1.2)
	draw_rect(clamp_r, Color(0.2, 0.2, 0.2), false, 1.2)

func draw_placed_parts() -> void:
	for i in range(GameState.custom_rocket_placed_parts.size()):
		var item = GameState.custom_rocket_placed_parts[i]
		draw_single_part(item, i == selected_index)

func draw_single_part(item: Dictionary, is_selected: bool) -> void:
	var p_id = str(item.get("part_id", ""))
	var part = DataManager.get_custom_part(p_id)
	if part.is_empty():
		return

	var gx = float(item.get("gx", 0.0))
	var gy = float(item.get("gy", 0.0))
	var gw = float(part.get("w_grid", 2.0))
	var gh = float(part.get("h_grid", 2.0))

	var px = grid_origin.x + gx * cell_size - (gw * cell_size * 0.5)
	var py = grid_origin.y - (gy + gh) * cell_size
	var pw = gw * cell_size
	var ph = gh * cell_size

	var rect = Rect2(px, py, pw, ph)
	var cat = str(part.get("category", ""))
	var base_col = Color.from_string(part.get("color", "#94a3b8"), Color.GRAY)

	match cat:
		"payload":
			draw_payload_part(rect, p_id, base_col)
		"heat_shield":
			draw_heat_shield_part(rect, base_col)
		"tanks":
			draw_tank_part(rect, p_id, base_col)
		"engines":
			draw_engine_part(rect, p_id, base_col)
		"decouplers":
			draw_decoupler_part(rect, p_id, base_col)
		"aero_landing":
			draw_aero_part(rect, p_id, base_col)
		_:
			draw_rect(rect, base_col)
			draw_rect(rect, Color.WHITE, false, 1.5)

	if is_selected:
		var pulse = 0.5 + sin(anim_pulse) * 0.5
		var border_col = Color(0.18, 0.94, 0.58, 0.7 + pulse * 0.3)
		draw_rect(rect.grow(3.0), border_col, false, 2.0)

func draw_payload_part(rect: Rect2, p_id: String, col: Color) -> void:
	if p_id == "capsule_crew":
		var pts = PackedVector2Array([
			Vector2(rect.position.x + rect.size.x * 0.25, rect.position.y),
			Vector2(rect.position.x + rect.size.x * 0.75, rect.position.y),
			Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y),
			Vector2(rect.position.x, rect.position.y + rect.size.y)
		])
		draw_colored_polygon(pts, col)
		draw_polyline(pts, Color(0.12, 0.16, 0.22), 2.0)
		draw_circle(rect.get_center() + Vector2(0, 4), 6.0, Color(0.1, 0.2, 0.35))
		draw_circle(rect.get_center() + Vector2(0, 4), 3.0, Color(0.4, 0.8, 1.0))
	else:
		draw_rect(rect, col)
		draw_rect(rect, Color(0.15, 0.20, 0.28), false, 2.0)
		var solar_l = Rect2(rect.position.x - 14.0, rect.position.y + 8.0, 12.0, rect.size.y - 16.0)
		var solar_r = Rect2(rect.position.x + rect.size.x + 2.0, rect.position.y + 8.0, 12.0, rect.size.y - 16.0)
		draw_rect(solar_l, Color(0.15, 0.35, 0.75))
		draw_rect(solar_r, Color(0.15, 0.35, 0.75))
		draw_rect(solar_l, Color(0.1, 0.15, 0.25), false, 1.0)
		draw_rect(solar_r, Color(0.1, 0.15, 0.25), false, 1.0)
		draw_circle(rect.get_center(), 5.0, Color(0.9, 0.8, 0.2))

func draw_heat_shield_part(rect: Rect2, col: Color) -> void:
	var pts = PackedVector2Array([
		Vector2(rect.position.x, rect.position.y),
		Vector2(rect.position.x + rect.size.x, rect.position.y),
		Vector2(rect.position.x + rect.size.x * 0.9, rect.position.y + rect.size.y),
		Vector2(rect.position.x + rect.size.x * 0.1, rect.position.y + rect.size.y)
	])
	draw_colored_polygon(pts, col)
	draw_polyline(pts, Color(0.15, 0.1, 0.05), 2.0)
	var ab_line_y = rect.position.y + rect.size.y * 0.6
	draw_line(Vector2(rect.position.x + rect.size.x * 0.15, ab_line_y), Vector2(rect.position.x + rect.size.x * 0.85, ab_line_y), Color(0.2, 0.12, 0.08), 2.0)

func draw_tank_part(rect: Rect2, p_id: String, col: Color) -> void:
	if p_id == "tank_cone_25_15":
		var pts = PackedVector2Array([
			Vector2(rect.position.x + rect.size.x * 0.2, rect.position.y),
			Vector2(rect.position.x + rect.size.x * 0.8, rect.position.y),
			Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y),
			Vector2(rect.position.x, rect.position.y + rect.size.y)
		])
		draw_colored_polygon(pts, col)
		draw_polyline(pts, Color(0.25, 0.30, 0.38), 1.8)
	elif p_id == "tank_side_booster":
		var pts = PackedVector2Array([
			Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y),
			Vector2(rect.position.x + rect.size.x, rect.position.y + cell_size * 1.5),
			Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y),
			Vector2(rect.position.x, rect.position.y + rect.size.y),
			Vector2(rect.position.x, rect.position.y + cell_size * 1.5)
		])
		draw_colored_polygon(pts, col)
		draw_polyline(pts, Color(0.25, 0.30, 0.38), 1.8)
	else:
		draw_rect(rect, col)
		draw_rect(rect, Color(0.25, 0.30, 0.38), false, 1.8)
		var ribs = int(rect.size.y / cell_size)
		for r in range(1, ribs):
			var ry = rect.position.y + r * cell_size
			draw_line(Vector2(rect.position.x, ry), Vector2(rect.position.x + rect.size.x, ry), Color(0.70, 0.75, 0.82), 1.0)
		draw_line(Vector2(rect.position.x + 4.0, rect.position.y + 4.0), Vector2(rect.position.x + 4.0, rect.position.y + rect.size.y - 4.0), Color(1, 1, 1, 0.4), 1.5)

func draw_engine_part(rect: Rect2, p_id: String, col: Color) -> void:
	if p_id == "engine_rcs":
		draw_circle(rect.get_center(), 6.0, col)
		draw_circle(rect.get_center(), 3.0, Color.BLACK)
		return

	var chamber = Rect2(rect.position.x + rect.size.x * 0.3, rect.position.y, rect.size.x * 0.4, rect.size.y * 0.35)
	draw_rect(chamber, col)
	draw_rect(chamber, Color(0.15, 0.18, 0.24), false, 1.5)

	var nozzle_top = rect.position.y + rect.size.y * 0.35
	var nozzle_bot = rect.position.y + rect.size.y
	var pts = PackedVector2Array([
		Vector2(rect.position.x + rect.size.x * 0.35, nozzle_top),
		Vector2(rect.position.x + rect.size.x * 0.65, nozzle_top),
		Vector2(rect.position.x + rect.size.x * 0.9, nozzle_bot),
		Vector2(rect.position.x + rect.size.x * 0.1, nozzle_bot)
	])
	draw_colored_polygon(pts, Color(0.22, 0.25, 0.32))
	draw_polyline(pts, Color(0.12, 0.15, 0.20), 1.8)
	var glow = Color(1.0, 0.55, 0.15, 0.35)
	draw_circle(Vector2(rect.position.x + rect.size.x * 0.5, nozzle_bot - 2.0), rect.size.x * 0.35, glow)

func draw_decoupler_part(rect: Rect2, p_id: String, col: Color) -> void:
	if p_id == "decoupler_radial":
		draw_rect(rect, col)
		draw_rect(rect, Color(0.15, 0.15, 0.15), false, 1.5)
		draw_line(rect.position, rect.position + rect.size, Color(0.1, 0.1, 0.1), 1.5)
	else:
		draw_rect(rect, col)
		draw_rect(rect, Color(0.15, 0.15, 0.15), false, 1.5)
		var step = 8.0
		var sx = rect.position.x
		while sx < rect.position.x + rect.size.x:
			draw_line(Vector2(sx, rect.position.y + rect.size.y), Vector2(min(rect.position.x + rect.size.x, sx + 8.0), rect.position.y), Color(0.1, 0.1, 0.1), 2.0)
			sx += 16.0

func draw_aero_part(rect: Rect2, p_id: String, col: Color) -> void:
	if p_id == "fairing_cone":
		var pts = PackedVector2Array([
			Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y),
			Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y),
			Vector2(rect.position.x, rect.position.y + rect.size.y)
		])
		draw_colored_polygon(pts, col)
		draw_polyline(pts, Color(0.25, 0.30, 0.38), 1.8)
		draw_line(Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y), Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y), Color(0.3, 0.35, 0.45), 1.2)
	elif p_id == "stabilizer_fin":
		var pts = PackedVector2Array([
			Vector2(rect.position.x, rect.position.y),
			Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y * 0.7),
			Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y),
			Vector2(rect.position.x, rect.position.y + rect.size.y)
		])
		draw_colored_polygon(pts, col)
		draw_polyline(pts, Color(0.1, 0.2, 0.4), 1.5)
	elif p_id == "landing_leg":
		var leg_top = rect.position + Vector2(rect.size.x * 0.5, 0)
		var leg_bot = rect.position + rect.size
		draw_line(leg_top, leg_bot, Color(0.35, 0.40, 0.48), 3.0)
		draw_circle(leg_bot, 4.0, Color(0.2, 0.2, 0.2))
	elif p_id == "parachute":
		draw_rect(rect, col)
		draw_rect(rect, Color(0.2, 0.2, 0.2), false, 1.5)
		draw_line(rect.position, rect.position + rect.size, Color.WHITE, 1.5)
		draw_line(Vector2(rect.position.x, rect.position.y + rect.size.y), Vector2(rect.position.x + rect.size.x, rect.position.y), Color.WHITE, 1.5)

func draw_selection_highlight(item: Dictionary) -> void:
	var p_id = str(item.get("part_id", ""))
	var part = DataManager.get_custom_part(p_id)
	if part.is_empty():
		return
	var gx = float(item.get("gx", 0.0))
	var gy = float(item.get("gy", 0.0))
	var gw = float(part.get("w_grid", 2.0))
	var gh = float(part.get("h_grid", 2.0))
	var px = grid_origin.x + gx * cell_size - (gw * cell_size * 0.5)
	var py = grid_origin.y - (gy + gh) * cell_size
	var pw = gw * cell_size
	var ph = gh * cell_size
	draw_rect(Rect2(px - 4, py - 4, pw + 8, ph + 8), Color(0.0, 0.95, 0.85, 0.4), false, 2.0)