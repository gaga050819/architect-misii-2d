extends Node2D

@export var throttle: float = 0.0
@export var is_rcs_left: bool = false
@export var is_rcs_right: bool = false
@export var edl_phase: int = 2
@export var is_landed: bool = false
@export var is_exploded: bool = false
@export var landing_compression: float = 0.0
@export var ground_dust_alpha: float = 0.0

var anim_time: float = 0.0
var explosion_time: float = 0.0
var debris_pieces: Array = []
var smoke_puffs: Array = []

func _ready() -> void:
	pass

func trigger_explosion() -> void:
	is_exploded = true
	explosion_time = 0.0
	debris_pieces.clear()
	smoke_puffs.clear()

	for i in range(24):
		var ang = randf() * TAU
		var spd = randf_range(60.0, 320.0)
		var piece = {
			"pos": Vector2(randf_range(-15.0, 15.0), randf_range(-20.0, 10.0)),
			"vel": Vector2(cos(ang) * spd, sin(ang) * spd - randf_range(40.0, 180.0)),
			"rot": randf() * TAU,
			"rot_vel": randf_range(-12.0, 12.0),
			"size": Vector2(randf_range(6.0, 16.0), randf_range(4.0, 10.0)),
			"type": randi() % 3
		}
		debris_pieces.append(piece)

	for s in range(12):
		var puff = {
			"pos": Vector2(randf_range(-25.0, 25.0), randf_range(-10.0, 10.0)),
			"vel": Vector2(randf_range(-30.0, 30.0), randf_range(-50.0, -15.0)),
			"rad": randf_range(12.0, 28.0),
			"max_rad": randf_range(45.0, 90.0),
			"alpha": randf_range(0.6, 0.9)
		}
		smoke_puffs.append(puff)

func _process(delta: float) -> void:
	anim_time += delta
	if is_exploded:
		explosion_time += delta
		for piece in debris_pieces:
			piece["vel"].y += 180.0 * delta
			piece["pos"] += piece["vel"] * delta
			piece["rot"] += piece["rot_vel"] * delta
			if piece["pos"].y > 25.0:
				piece["pos"].y = 25.0
				piece["vel"].y = -piece["vel"].y * 0.35
				piece["vel"].x *= 0.75
				piece["rot_vel"] *= 0.5

		for puff in smoke_puffs:
			puff["pos"] += puff["vel"] * delta
			puff["rad"] = move_toward(puff["rad"], puff["max_rad"], delta * 25.0)
			puff["alpha"] = move_toward(puff["alpha"], 0.0, delta * 0.22)

	queue_redraw()

func _draw() -> void:
	var s = 1.3
	var foil_color = Color(0.94, 0.80, 0.38)
	var dark_metal = Color(0.18, 0.20, 0.25)
	var metal_color = Color(0.60, 0.65, 0.72)

	if is_exploded:
		draw_explosion_visual()
		return

	if edl_phase == 0:
		var plasma_glow = 0.6 + sin(anim_time * 20.0) * 0.3
		var plasma_pts = PackedVector2Array([
			Vector2(-45.0 * s, 15.0 * s),
			Vector2(0, 35.0 * s),
			Vector2(45.0 * s, 15.0 * s),
			Vector2(0, 48.0 * s)
		])
		draw_colored_polygon(plasma_pts, Color(1.0, 0.45, 0.1, plasma_glow))

	if edl_phase == 1:
		var chute_y = -130.0 * s
		var chute_w = 70.0 * s
		var chute_h = 40.0 * s
		var chute_poly = PackedVector2Array([
			Vector2(-chute_w, chute_y),
			Vector2(-chute_w * 0.7, chute_y - chute_h),
			Vector2(0, chute_y - chute_h * 1.2),
			Vector2(chute_w * 0.7, chute_y - chute_h),
			Vector2(chute_w, chute_y)
		])
		draw_colored_polygon(chute_poly, Color(0.95, 0.4, 0.2))
		draw_polyline(chute_poly, Color(1, 1, 1), 2.0)
		for c in range(5):
			var cx = -chute_w + c * (chute_w * 0.5)
			draw_line(Vector2(cx, chute_y), Vector2(0, -20.0 * s), Color(0.85, 0.88, 0.92, 0.7), 1.2)

	if throttle > 0.01:
		var f_len = (48.0 + sin(anim_time * 42.0) * 12.0) * throttle * s
		var f_w = 15.0 * s
		var flame_poly = PackedVector2Array([
			Vector2(-f_w * 0.5, 14.0 * s),
			Vector2(f_w * 0.5, 14.0 * s),
			Vector2(0, 14.0 * s + f_len)
		])
		draw_colored_polygon(flame_poly, Color(1.0, 0.6, 0.15, 0.9))
		var core_flame = PackedVector2Array([
			Vector2(-f_w * 0.25, 14.0 * s),
			Vector2(f_w * 0.25, 14.0 * s),
			Vector2(0, 14.0 * s + f_len * 0.6)
		])
		draw_colored_polygon(core_flame, Color(1.0, 0.95, 0.55, 0.95))

	if is_rcs_left:
		draw_line(Vector2(-24.0 * s, -10.0 * s), Vector2(-44.0 * s, -10.0 * s), Color(0.85, 0.95, 1.0, 0.9), 3.5)
		draw_circle(Vector2(-44.0 * s, -10.0 * s), 3.0, Color(0.5, 0.8, 1.0, 0.7))
	if is_rcs_right:
		draw_line(Vector2(24.0 * s, -10.0 * s), Vector2(44.0 * s, -10.0 * s), Color(0.85, 0.95, 1.0, 0.9), 3.5)
		draw_circle(Vector2(44.0 * s, -10.0 * s), 3.0, Color(0.5, 0.8, 1.0, 0.7))

	var leg_comp = landing_compression * 8.0 * s
	var leg_bot_y = 28.0 * s - leg_comp
	var leg_span = 46.0 * s

	draw_line(Vector2(-18.0 * s, 8.0 * s), Vector2(-leg_span, leg_bot_y), metal_color, 3.5)
	draw_line(Vector2(-leg_span - 8.0 * s, leg_bot_y), Vector2(-leg_span + 8.0 * s, leg_bot_y), dark_metal, 3.0)

	draw_line(Vector2(18.0 * s, 8.0 * s), Vector2(leg_span, leg_bot_y), metal_color, 3.5)
	draw_line(Vector2(leg_span - 8.0 * s, leg_bot_y), Vector2(leg_span + 8.0 * s, leg_bot_y), dark_metal, 3.0)

	var body_poly = PackedVector2Array([
		Vector2(-24.0 * s, -16.0 * s),
		Vector2(24.0 * s, -16.0 * s),
		Vector2(30.0 * s, 12.0 * s),
		Vector2(-30.0 * s, 12.0 * s)
	])
	draw_colored_polygon(body_poly, foil_color)
	draw_polyline(body_poly, dark_metal, 2.0)

	for h in range(4):
		var hy = -12.0 * s + h * 6.5 * s
		draw_line(Vector2(-22.0 * s, hy), Vector2(22.0 * s, hy), Color(0.82, 0.68, 0.25, 0.4), 1.0)

	var nozzle_poly = PackedVector2Array([
		Vector2(-7.0 * s, 12.0 * s),
		Vector2(7.0 * s, 12.0 * s),
		Vector2(10.0 * s, 21.0 * s),
		Vector2(-10.0 * s, 21.0 * s)
	])
	draw_colored_polygon(nozzle_poly, dark_metal)

	draw_rect(Rect2(-14.0 * s, -28.0 * s, 28.0 * s, 14.0 * s), Color(0.90, 0.92, 0.96))
	draw_rect(Rect2(-14.0 * s, -28.0 * s, 28.0 * s, 14.0 * s), dark_metal, false, 1.5)
	draw_circle(Vector2(0, -21.0 * s), 4.0 * s, Color(0.25, 0.85, 1.0))

	draw_arc(Vector2(-12.0 * s, -32.0 * s), 11.0 * s, PI * 0.8, PI * 2.2, 16, Color(0.92, 0.94, 0.98), 2.5)
	draw_line(Vector2(-12.0 * s, -32.0 * s), Vector2(-12.0 * s, -24.0 * s), metal_color, 2.0)

	if ground_dust_alpha > 0.05:
		for d in range(8):
			var dx = (d - 4) * 22.0 * s
			var dy = 25.0 * s + sin(d * 1.5) * 6.0
			draw_circle(Vector2(dx, dy), 14.0 * s, Color(0.85, 0.55, 0.38, ground_dust_alpha * 0.45))

func draw_explosion_visual() -> void:
	var t = explosion_time

	draw_oval(Vector2(0, 24), 60.0, 14.0, Color(0.12, 0.10, 0.08, 0.7))

	for puff in smoke_puffs:
		if puff["alpha"] > 0.01:
			var smoke_col = Color(0.18, 0.18, 0.20, puff["alpha"])
			draw_circle(puff["pos"], puff["rad"], smoke_col)

	if t < 0.8:
		var shock_rad = t * 180.0
		var shock_alpha = clamp(1.0 - (t / 0.8), 0.0, 1.0)
		draw_arc(Vector2.ZERO, shock_rad, 0, TAU, 32, Color(1.0, 0.85, 0.5, shock_alpha * 0.9), 3.5)
		draw_arc(Vector2.ZERO, shock_rad * 0.7, 0, TAU, 28, Color(1.0, 0.4, 0.1, shock_alpha * 0.6), 2.5)

	if t < 1.4:
		var blast_scale = clamp(1.0 - (t / 1.4), 0.0, 1.0)
		var fire_colors = [
			Color(1.0, 0.95, 0.7, 0.95 * blast_scale),
			Color(1.0, 0.65, 0.15, 0.85 * blast_scale),
			Color(0.95, 0.25, 0.1, 0.75 * blast_scale),
			Color(0.65, 0.15, 0.1, 0.65 * blast_scale)
		]
		for f in range(10):
			var angle = f * (TAU / 10.0) + t * 4.0
			var dist = sin(t * 12.0 + f) * 18.0 + 10.0
			var c_pos = Vector2(cos(angle) * dist, sin(angle) * dist - t * 25.0)
			var c_rad = (32.0 - f * 2.0) * blast_scale
			var c_col = fire_colors[f % fire_colors.size()]
			draw_circle(c_pos, max(4.0, c_rad), c_col)

	for piece in debris_pieces:
		draw_set_transform(piece["pos"], piece["rot"], Vector2.ONE)
		var sz = piece["size"]
		if piece["type"] == 0:
			draw_rect(Rect2(-sz.x * 0.5, -sz.y * 0.5, sz.x, sz.y), Color(0.95, 0.78, 0.35))
			draw_rect(Rect2(-sz.x * 0.5, -sz.y * 0.5, sz.x, sz.y), Color(0.2, 0.2, 0.2), false, 1.0)
		elif piece["type"] == 1:
			draw_line(Vector2(-sz.x, 0), Vector2(sz.x, 0), Color(0.7, 0.75, 0.8), 2.5)
		else:
			draw_circle(Vector2.ZERO, sz.x * 0.4, Color(0.3, 0.35, 0.4))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func draw_oval(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts = PackedVector2Array()
	for i in range(32):
		var ang = i * (TAU / 32.0)
		pts.append(center + Vector2(cos(ang) * rx, sin(ang) * ry))
	draw_colored_polygon(pts, color)
