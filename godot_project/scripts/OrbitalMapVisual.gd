extends Control

var craft_altitude_km: float = 0.0
var craft_speed_kms: float = 0.0
var craft_angle_deg: float = 0.0
var semi_major_axis_km: float = 0.0
var eccentricity: float = 0.0
var periapsis_km: float = 0.0
var apoapsis_km: float = 0.0
var is_orbit_stable: bool = false
var true_anomaly: float = 0.0
var time_warp: float = 1.0

var earth_radius_km: float = 6371.0
var atm_height_km: float = 100.0
var target_name: String = "Марс"

func _ready() -> void:
	pass

func update_telemetry(alt_km: float, spd_kms: float, ang_deg: float, orbit_data: Dictionary, t_warp: float = 1.0) -> void:
	craft_altitude_km = alt_km
	craft_speed_kms = spd_kms
	craft_angle_deg = ang_deg
	time_warp = t_warp
	semi_major_axis_km = float(orbit_data.get("semi_major_axis", 0.0)) / 1000.0
	eccentricity = float(orbit_data.get("eccentricity", 0.0))
	periapsis_km = float(orbit_data.get("periapsis_km", 0.0))
	apoapsis_km = float(orbit_data.get("apoapsis_km", 0.0))
	is_orbit_stable = bool(orbit_data.get("is_stable_orbit", false))
	true_anomaly = float(orbit_data.get("true_anomaly", 0.0))
	queue_redraw()

func _draw() -> void:
	var rect = get_rect()
	var center = rect.size * 0.5 + Vector2(0, 40)
	var map_scale = 0.024

	draw_rect(Rect2(Vector2.ZERO, rect.size), Color(0.02, 0.04, 0.08, 0.96))

	var earth_r_px = earth_radius_km * map_scale
	var atm_r_px = (earth_radius_km + atm_height_km) * map_scale

	draw_circle(center, atm_r_px, Color(0.1, 0.45, 0.9, 0.22))
	draw_arc(center, atm_r_px, 0.0, TAU, 64, Color(0.2, 0.7, 1.0, 0.5), 1.5)

	draw_circle(center, earth_r_px, Color(0.08, 0.22, 0.48, 1.0))
	draw_circle(center, earth_r_px * 0.96, Color(0.06, 0.18, 0.42, 1.0))
	draw_arc(center, earth_r_px, 0.0, TAU, 64, Color(0.18, 0.55, 0.95, 0.9), 2.0)

	var continent_col = Color(0.14, 0.38, 0.28, 0.85)
	draw_circle(center + Vector2(-earth_r_px * 0.3, -earth_r_px * 0.2), earth_r_px * 0.35, continent_col)
	draw_circle(center + Vector2(earth_r_px * 0.25, earth_r_px * 0.1), earth_r_px * 0.4, continent_col)

	var font = get_theme_default_font()
	draw_string(font, center + Vector2(-22, 5), "ЗЕМЛЯ", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.6))

	var craft_dist_km = earth_radius_km + craft_altitude_km
	var craft_dist_px = craft_dist_km * map_scale
	var craft_rad = deg_to_rad(craft_angle_deg - 90.0)
	var craft_pos = center + Vector2(cos(craft_rad), sin(craft_rad)) * craft_dist_px

	if eccentricity > 0.0 and eccentricity < 1.0 and semi_major_axis_km > 0.0:
		var p_km = semi_major_axis_km * (1.0 - eccentricity * eccentricity)
		var orbit_pts = PackedVector2Array()
		var step = 0.05
		var segments = int(TAU / step) + 1
		for i in range(segments):
			var theta = i * step
			var r_orb_km = p_km / (1.0 + eccentricity * cos(theta))
			if r_orb_km > 0.0 and r_orb_km < 80000.0:
				var r_orb_px = r_orb_km * map_scale
				var rot_theta = theta + (craft_rad - true_anomaly)
				var pt = center + Vector2(cos(rot_theta), sin(rot_theta)) * r_orb_px
				orbit_pts.append(pt)

		if orbit_pts.size() > 3:
			var orb_col = Color(0.18, 0.94, 0.58, 0.85) if is_orbit_stable else Color(1.0, 0.6, 0.2, 0.75)
			draw_polyline(orbit_pts, orb_col, 2.0)

			var ap_rad = (craft_rad - true_anomaly) + PI
			var pe_rad = (craft_rad - true_anomaly)
			var ap_dist_px = (earth_radius_km + apoapsis_km) * map_scale
			var pe_dist_px = (earth_radius_km + periapsis_km) * map_scale
			var ap_pos = center + Vector2(cos(ap_rad), sin(ap_rad)) * ap_dist_px
			var pe_pos = center + Vector2(cos(pe_rad), sin(pe_rad)) * pe_dist_px

			draw_rect(Rect2(ap_pos - Vector2(5, 5), Vector2(10, 10)), Color(0.2, 0.85, 1.0, 0.95), true)
			draw_string(font, ap_pos + Vector2(10, 4), "Ap: %.1f км" % [apoapsis_km], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.2, 0.85, 1.0, 0.95))

			if periapsis_km > -earth_radius_km:
				var pe_col = Color(0.18, 0.94, 0.58, 0.95) if periapsis_km >= atm_height_km else Color(1.0, 0.35, 0.35, 0.95)
				draw_rect(Rect2(pe_pos - Vector2(5, 5), Vector2(10, 10)), pe_col, true)
				draw_string(font, pe_pos + Vector2(10, 4), "Pe: %.1f км" % [periapsis_km], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, pe_col)

	var heading_dir = Vector2(-sin(deg_to_rad(craft_angle_deg)), -cos(deg_to_rad(craft_angle_deg)))
	var arrow_pts = PackedVector2Array([
		craft_pos + heading_dir * 9.0,
		craft_pos + heading_dir.rotated(2.4) * 6.0,
		craft_pos,
		craft_pos + heading_dir.rotated(-2.4) * 6.0
	])
	draw_colored_polygon(arrow_pts, Color(1.0, 0.9, 0.2, 1.0))
	draw_circle(craft_pos, 3.5, Color(1.0, 1.0, 1.0, 1.0))
	draw_string(font, craft_pos + Vector2(12, -8), "Апарат: %.1f км | %.2f км/с" % [craft_altitude_km, craft_speed_kms], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.95, 0.4, 0.95))

	var panel_rect = Rect2(20, 20, 360, 110)
	draw_rect(panel_rect, Color(0.06, 0.1, 0.16, 0.88), true)
	draw_rect(panel_rect, Color(0.2, 0.5, 0.8, 0.5), false, 1.5)

	var stat_title = "СТАТУС ТРАЄКТОРІЇ"
	var stat_col = Color(0.2, 0.85, 1.0)
	var stat_desc = "Підйом в атмосфері"
	if is_orbit_stable:
		stat_desc = "СТАБІЛЬНА ОРБІТА LEO (Замкнена)"
		stat_col = Color(0.18, 0.94, 0.58)
	elif apoapsis_km > atm_height_km and periapsis_km < atm_height_km:
		stat_desc = "Суборбітальна траєкторія (Перицентр в атмосфері)"
		stat_col = Color(1.0, 0.65, 0.2)
	elif apoapsis_km > 0.0:
		stat_desc = "Суборбітальний підйом"
		stat_col = Color(0.8, 0.8, 0.9)

	draw_string(font, Vector2(35, 45), stat_title, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.6, 0.7, 0.85))
	draw_string(font, Vector2(35, 70), stat_desc, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, stat_col)
	draw_string(font, Vector2(35, 95), "Прискорення часу: %.0fx" % [time_warp], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.85, 0.95))
	draw_string(font, Vector2(35, 115), "Натисніть [M] або кнопку вгорі для повернення до камери", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.5, 0.6, 0.7))
