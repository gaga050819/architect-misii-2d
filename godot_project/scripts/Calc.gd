extends Node

const G0: float = 9.81
const DESIGN_MARGIN: float = 0.2
const WARN_MARGIN: float = 0.15
const RTG_DECAY: float = 0.96
const RATE_CAP_MBPS: float = 100.0

func fuel_mass(dry_mass: float, dv_kms: float, isp_s: float) -> float:
	if dv_kms <= 0.0 or isp_s <= 0.0:
		return 0.0
	var dv = dv_kms * 1000.0
	var exhaust_v = isp_s * G0
	return dry_mass * (exp(dv / exhaust_v) - 1.0)

func earth_distance_au(target: Dictionary) -> float:
	var orbit_au = float(target.get("orbit_au", target.get("sun_au", 1.524)))
	if orbit_au <= 1.0:
		return max(0.002, abs(orbit_au - 1.0) + 0.28)
	return max(0.15, orbit_au - 0.52)

func data_rate_effective(rate_1au_mbps: float, dist_au: float) -> float:
	var d = max(0.01, dist_au)
	var rate = rate_1au_mbps / (d * d)
	return min(RATE_CAP_MBPS, rate)

func get_rocket_capacity(rocket: Dictionary, target: Dictionary) -> float:
	var target_id = str(target.get("id", "mars"))
	var to_kg_map = rocket.get("to_kg", {})
	if to_kg_map is Dictionary and to_kg_map.has(target_id):
		return float(to_kg_map[target_id])
	var leo_kg = float(rocket.get("leo_kg", 22800.0))
	var k_cap = float(target.get("k_capacity", 0.18))
	return leo_kg * k_cap

func get_power_generated(power: Dictionary, target: Dictionary, is_surface: bool) -> float:
	var ptype = str(power.get("type", "solar"))
	if ptype == "rtg":
		return float(power.get("p0_w", 110.0))
	var base = float(power.get("p1au_w", 760.0))
	var sun_au = float(target.get("sun_au", 1.524))
	var factor = 1.0 / (sun_au * sun_au)
	if is_surface and target.has("surface_solar_factor"):
		factor = float(target.get("surface_solar_factor"))
	elif not is_surface and target.has("orbit_solar_factor"):
		factor = float(target.get("orbit_solar_factor"))
	return max(0.0, base * factor)

func evaluate_build(build: Dictionary) -> Dictionary:
	var target = build.get("target", {})
	var rocket = build.get("rocket", {})
	var platform = build.get("platform", {})
	var power = build.get("power", {})
	var antenna = build.get("antenna", {})
	var instruments = build.get("instruments", [])
	var m_class = build.get("class", {})
	var goal = build.get("goal", {})

	var plat_type = str(platform.get("type", "rover"))
	var is_surface = plat_type != "orbiter"

	var dry_mass = float(platform.get("mass_kg", 500.0))
	dry_mass += float(power.get("mass_kg", 50.0))
	dry_mass += float(antenna.get("mass_kg", 15.0))

	var instrument_power_cons = 0.0
	var base_science = 0.0
	var goal_id = str(goal.get("id", ""))
	var data_mbit_per_day_total = 0.0

	for inst in instruments:
		dry_mass += float(inst.get("mass_kg", 10.0))
		var duty = float(inst.get("duty", 0.5))
		instrument_power_cons += float(inst.get("power_w", 20.0)) * duty
		var sb = float(inst.get("science_base", inst.get("science", 2.0)))
		var weights = inst.get("weights", {}) as Dictionary
		var goal_weight = 1.0
		if goal_id != "" and weights.has(goal_id):
			goal_weight = max(1.0, float(weights[goal_id]))
		base_science += sb * goal_weight
		data_mbit_per_day_total += float(inst.get("data_mbit_per_day", 10.0))

	var margin_mass = dry_mass * DESIGN_MARGIN
	var total_dry = dry_mass + margin_mass

	var isp_s = 320.0
	var dv_kms = float(target.get("dv_capture_kms", 1.0))
	var fuel = fuel_mass(total_dry, dv_kms, isp_s)
	var launch_mass = total_dry + fuel

	var capacity_kg = get_rocket_capacity(rocket, target)
	var mass_ok = launch_mass <= capacity_kg
	var mass_reserve_pct = 0.0
	if capacity_kg > 0:
		mass_reserve_pct = (capacity_kg - launch_mass) / capacity_kg

	var cost = float(rocket.get("cost_musd", 90.0))
	cost += float(platform.get("cost_musd", 200.0))
	cost += float(power.get("cost_musd", 40.0))
	cost += float(antenna.get("cost_musd", 15.0))
	for inst in instruments:
		cost += float(inst.get("cost_musd", 25.0))

	var budget_limit = float(m_class.get("budget_musd", 1150.0))
	var budget_ok = cost <= budget_limit

	var power_gen = get_power_generated(power, target, is_surface)
	var bus_power = float(platform.get("bus_power_w", 100.0))
	var total_consumption = bus_power + instrument_power_cons
	var power_ok = power_gen >= total_consumption

	var ant_rate_1au = float(antenna.get("rate_1au_mbps", antenna.get("rate_mbps", 0.05)))
	var dist_au = earth_distance_au(target)
	var eff_rate = 0.0
	var is_relay = antenna.get("relay", false) or str(antenna.get("id")) == "relay_uhf"

	var contact_h = float(antenna.get("contact_h", 4.0))
	var daily_capacity_mbit = 0.0

	if is_relay:
		if target.get("has_relay", false):
			daily_capacity_mbit = float(antenna.get("relay_mbit_per_day", 400.0))
			eff_rate = daily_capacity_mbit / (max(1.0, contact_h) * 3600.0)
		else:
			daily_capacity_mbit = 0.0
			eff_rate = 0.0
	else:
		eff_rate = data_rate_effective(ant_rate_1au, dist_au)
		daily_capacity_mbit = eff_rate * contact_h * 3600.0

	var inst_demand = data_mbit_per_day_total
	var data_bottleneck_pct = 1.0
	if inst_demand > 0.0:
		data_bottleneck_pct = clamp(daily_capacity_mbit / inst_demand, 0.0, 1.0)

	var reliability = float(platform.get("reliability", 0.95))
	var r_flights = int(rocket.get("flights", 1))
	var r_success = int(rocket.get("successes", 1))
	var rocket_reliability = float(r_success) / max(1.0, float(r_flights))
	reliability *= rocket_reliability
	if mass_reserve_pct < WARN_MARGIN:
		reliability *= 0.92

	return {
		"dry_mass_kg": total_dry,
		"fuel_mass_kg": fuel,
		"launch_mass_kg": launch_mass,
		"capacity_kg": capacity_kg,
		"mass_ok": mass_ok,
		"mass_reserve_pct": mass_reserve_pct,
		"total_cost_musd": cost,
		"budget_limit_musd": budget_limit,
		"budget_ok": budget_ok,
		"power_generated_w": power_gen,
		"power_consumed_w": total_consumption,
		"power_bus_w": bus_power,
		"power_instruments_w": instrument_power_cons,
		"power_ok": power_ok,
		"data_rate_1au_mbps": ant_rate_1au,
		"data_rate_effective_mbps": eff_rate,
		"data_contact_h": contact_h,
		"data_per_day_mbit": daily_capacity_mbit,
		"data_instruments_mbit_per_day": inst_demand,
		"data_bottleneck_pct": data_bottleneck_pct,
		"potential_science": base_science,
		"reliability": reliability,
		"rocket_reliability_pct": rocket_reliability * 100.0,
		"is_valid_launch": mass_ok and budget_ok and power_ok and instruments.size() > 0
	}

func calculate_custom_rocket(placed_parts: Array) -> Dictionary:
	var mass_dry_t: float = 0.0
	var mass_fuel_t: float = 0.0
	var total_thrust_kn: float = 0.0
	var thrust_weighted_isp: float = 0.0
	var has_heat_shield: bool = false
	var max_temp_k: float = 1200.0
	var total_ablation_t: float = 0.0
	var has_control: bool = false
	var has_parachute: bool = false
	var nose_cd: float = 0.82
	var engine_count: int = 0

	for item in placed_parts:
		var p_id = str(item.get("part_id", ""))
		var part = DataManager.get_custom_part(p_id)
		if part.is_empty():
			continue
		var cat = str(part.get("category", ""))
		var md = float(part.get("mass_dry", 0.1))
		var mf = float(part.get("mass_fuel", 0.0))
		mass_dry_t += md
		mass_fuel_t += mf

		if cat == "engines":
			var th = float(part.get("thrust", 0.0))
			var isp = float(part.get("isp_sl", 280.0))
			total_thrust_kn += th
			thrust_weighted_isp += th * isp
			engine_count += 1
		elif cat == "heat_shield":
			has_heat_shield = true
			max_temp_k = max(max_temp_k, float(part.get("max_temp", 3000.0)))
			total_ablation_t += float(part.get("ablation_mass", 0.3))
		elif cat == "payload":
			has_control = true
		elif p_id == "parachute":
			has_parachute = true
		elif p_id == "fairing_cone" or p_id == "tank_cone_25_15":
			nose_cd = min(nose_cd, float(part.get("cd", 0.05)))

	var mass_total_t: float = mass_dry_t + mass_fuel_t
	var mass_total_kg: float = mass_total_t * 1000.0
	var mass_dry_kg: float = mass_dry_t * 1000.0

	var twr: float = 0.0
	if mass_total_kg > 0.0:
		twr = (total_thrust_kn * 1000.0) / (mass_total_kg * G0)

	var avg_isp: float = 280.0
	if total_thrust_kn > 0.0:
		avg_isp = thrust_weighted_isp / total_thrust_kn

	var delta_v: float = 0.0
	if mass_dry_t > 0.0 and mass_total_t > mass_dry_t:
		delta_v = avg_isp * G0 * log(mass_total_t / mass_dry_t)

	var can_lift_off: bool = twr >= 1.05 and has_control and engine_count > 0
	var reaches_orbit: bool = delta_v >= 7800.0

	return {
		"mass_dry_t": mass_dry_t,
		"mass_fuel_t": mass_fuel_t,
		"mass_total_t": mass_total_t,
		"mass_total_kg": mass_total_kg,
		"thrust_kn": total_thrust_kn,
		"avg_isp": avg_isp,
		"twr": twr,
		"delta_v": delta_v,
		"can_lift_off": can_lift_off,
		"reaches_orbit": reaches_orbit,
		"has_heat_shield": has_heat_shield,
		"max_temp_k": max_temp_k,
		"ablation_t": total_ablation_t,
		"has_control": has_control,
		"has_parachute": has_parachute,
		"cd": nose_cd,
		"part_count": placed_parts.size()
	}

func vis_viva(mu: float, r: float, a: float) -> float:
	if r <= 0.0 or a <= 0.0:
		return 0.0
	var v_sq = mu * ((2.0 / r) - (1.0 / a))
	return sqrt(max(0.0, v_sq))

func orbital_period(mu: float, a: float) -> float:
	if mu <= 0.0 or a <= 0.0:
		return 0.0
	return TAU * sqrt((a * a * a) / mu)

func hohmann_transfer(mu: float, r1: float, r2: float) -> Dictionary:
	if r1 <= 0.0 or r2 <= 0.0 or mu <= 0.0:
		return {"dv1": 0.0, "dv2": 0.0, "total_dv": 0.0, "transfer_time": 0.0}
	var a_tx = (r1 + r2) * 0.5
	var v1 = sqrt(mu / r1)
	var v2 = sqrt(mu / r2)
	var v_tx1 = sqrt(mu * ((2.0 / r1) - (1.0 / a_tx)))
	var v_tx2 = sqrt(mu * ((2.0 / r2) - (1.0 / a_tx)))
	var dv1 = abs(v_tx1 - v1)
	var dv2 = abs(v2 - v_tx2)
	var t_tx = PI * sqrt((a_tx * a_tx * a_tx) / mu)
	return {
		"dv1": dv1,
		"dv2": dv2,
		"total_dv": dv1 + dv2,
		"transfer_time": t_tx
	}

func atmospheric_density(rho0: float, h: float, scale_height: float) -> float:
	if h < 0.0:
		h = 0.0
	if scale_height <= 0.0:
		return 0.0
	return rho0 * exp(-h / scale_height)

func calculate_keplerian_orbit(mu: float, r_m: float, vx_m: float, vy_m: float, planet_r_m: float = 6371000.0) -> Dictionary:
	var v_sq = vx_m * vx_m + vy_m * vy_m
	var v = sqrt(v_sq)
	var eps = (v_sq * 0.5) - (mu / r_m)
	var h_ang = abs(r_m * vx_m)
	var a = 0.0
	var e = 0.0
	var pe = 0.0
	var ap = 0.0
	if abs(eps) > 1e-7:
		a = -mu / (2.0 * eps)
	var disc = 1.0 + (2.0 * eps * h_ang * h_ang) / (mu * mu)
	e = sqrt(max(0.0, disc))
	if a > 0.0:
		pe = (a * (1.0 - e)) - planet_r_m
		ap = (a * (1.0 + e)) - planet_r_m
	else:
		pe = ((h_ang * h_ang) / (mu * (1.0 + e))) - planet_r_m
		ap = 999999999.0
	var is_stable = pe >= 130000.0 and ap >= 140000.0 and e < 1.0
	var nu = atan2(h_ang * vy_m / mu, (h_ang * h_ang) / (mu * r_m) - 1.0)
	return {
		"speed": v,
		"semi_major_axis": a,
		"eccentricity": e,
		"periapsis_km": pe / 1000.0,
		"apoapsis_km": ap / 1000.0,
		"true_anomaly": nu,
		"is_stable_orbit": is_stable
	}

func calculate_aero_heating(rho: float, speed: float, nose_radius: float = 1.0) -> float:
	if rho <= 0.0 or speed <= 600.0 or nose_radius <= 0.0:
		return 0.0
	var q = 1.83e-4 * sqrt(rho / nose_radius) * pow(speed, 3.0)
	return max(0.0, q)

func calculate_dynamic_pressure(rho: float, speed: float) -> float:
	if rho <= 0.0 or speed <= 0.0:
		return 0.0
	return 0.5 * rho * speed * speed
