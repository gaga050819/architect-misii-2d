extends Node2D

@export var radius: float = 38.0
@export var pitch_deg: float = 0.0
@export var velocity_vector: Vector2 = Vector2.ZERO

var anim_time: float = 0.0

func _process(delta: float) -> void:
	anim_time += delta
	queue_redraw()

func _draw() -> void:
	var center = Vector2.ZERO
	var r = radius

	draw_circle(center, r + 7.0, Color(0.05, 0.08, 0.14, 0.95))
	draw_arc(center, r + 7.0, 0, TAU, 48, Color(0.08, 0.18, 0.32, 1.0), 1.5)

	var sky_pts = PackedVector2Array()
	var sky_cols = PackedColorArray()
	for i in range(33):
		var ang = i * (TAU / 32.0)
		sky_pts.append(center + Vector2(cos(ang), sin(ang)) * r)
		if sin(ang) < 0:
			sky_cols.append(Color(0.05, 0.25, 0.75))
		else:
			sky_cols.append(Color(0.55, 0.38, 0.25))
	draw_colored_polygon(sky_pts, sky_cols)

	var bezel_pts = PackedVector2Array()
	for i in range(64):
		var ang = i * (TAU / 63.0)
		bezel_pts.append(center + Vector2(cos(ang), sin(ang)) * (r + 1.0))
	draw_arc(center, r + 1.0, 0, TAU, 64, Color(0.22, 0.28, 0.38), 4.0)
	draw_arc(center, r + 3.0, PI * 1.15, PI * 1.85, 32, Color(0.5, 0.65, 0.85, 0.5), 2.5)
	draw_arc(center, r + 3.0, PI * 0.15, PI * 0.85, 32, Color(0.1, 0.12, 0.18, 0.7), 2.0)

	var rad = deg_to_rad(pitch_deg)
	var perp = Vector2(cos(rad + PI * 0.5), sin(rad + PI * 0.5))
	var horizon_dir = Vector2(cos(rad), sin(rad))

	draw_line(center - horizon_dir * r, center + horizon_dir * r, Color(0.0, 0.85, 1.0, 0.9), 2.0)

	for tick in range(-3, 4):
		if tick == 0:
			continue
		var tick_offset = perp * (tick * r / 4.0)
		var tick_len = 6.0 if abs(tick) == 2 else 4.0
		draw_line(center + tick_offset - horizon_dir * tick_len,
				  center + tick_offset + horizon_dir * tick_len,
				  Color(0.0, 0.85, 1.0, 0.5), 1.0)

	draw_line(center - Vector2(14, 0), center - Vector2(5, 0), Color(1.0, 0.85, 0.15), 2.5)
	draw_line(center + Vector2(5, 0), center + Vector2(14, 0), Color(1.0, 0.85, 0.15), 2.5)
	draw_circle(center, 3.0, Color(1.0, 0.85, 0.15))
	draw_arc(center, 3.5, 0, TAU, 16, Color(1.0, 0.85, 0.15, 0.6), 1.0)

	if velocity_vector.length() > 2.0:
		var vn = velocity_vector.normalized()
		var pv = Vector2(vn.x, -vn.y) * (r * 0.65)
		var retro = -pv
		var pulse = 0.65 + sin(anim_time * 6.0) * 0.2
		draw_circle(pv, 5.0, Color(1.0, 0.95, 0.3, 0.9))
		draw_arc(pv, 8.5, 0, TAU, 20, Color(1.0, 0.95, 0.3, 0.7 * pulse), 1.5)
		draw_line(pv + Vector2(0, -11), pv + Vector2(0, -7), Color(1.0, 0.95, 0.3), 2.0)
		draw_line(pv + Vector2(-11, 0), pv + Vector2(-7, 0), Color(1.0, 0.95, 0.3), 2.0)
		draw_line(pv + Vector2(11, 0), pv + Vector2(7, 0), Color(1.0, 0.95, 0.3), 2.0)

		draw_circle(retro, 4.5, Color(1.0, 0.45, 0.1, 0.85))
		draw_arc(retro, 7.5, 0, TAU, 16, Color(1.0, 0.45, 0.1, 0.65), 1.5)
		draw_line(retro + Vector2(0, -9), retro + Vector2(0, -6), Color(1.0, 0.45, 0.1), 1.5)
		draw_line(retro + Vector2(-9, 0), retro + Vector2(-6, 0), Color(1.0, 0.45, 0.1), 1.5)
		draw_line(retro + Vector2(9, 0), retro + Vector2(6, 0), Color(1.0, 0.45, 0.1), 1.5)
		draw_arc(retro, 7.5, PI * 0.0, PI * 0.6, 10, Color(1.0, 0.45, 0.1, 0.4), 2.0)
		draw_arc(retro, 7.5, PI * 1.0, PI * 1.6, 10, Color(1.0, 0.45, 0.1, 0.4), 2.0)
