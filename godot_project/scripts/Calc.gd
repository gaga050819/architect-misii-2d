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
