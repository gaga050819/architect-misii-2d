extends Node

signal state_changed
signal phase_changed(new_phase: String)

var target_id: String = "mars"
var class_id: String = "discovery"
var goal_id: String = "geology"
var rocket_id: String = "falcon9"
var platform_id: String = "rover_small"
var power_id: String = "solar_s"
var antenna_id: String = "hga_small"
var selected_instruments: Array = ["drill", "laser_spectrometer"]

var current_phase: String = "briefing"

var final_score: int = 0
var collected_science: float = 0.0
var landing_damage: float = 0.0
var flight_events_log: Array = []
var mission_success: bool = true

func _ready() -> void:
	reset_mission()

func reset_mission() -> void:
	target_id = "mars"
	class_id = "discovery"
	goal_id = "geology"
	rocket_id = "falcon9"
	platform_id = "rover_small"
	power_id = "solar_s"
	antenna_id = "hga_small"
	selected_instruments = ["drill", "laser_spectrometer"]
	current_phase = "briefing"
	final_score = 0
	collected_science = 0.0
	landing_damage = 0.0
	flight_events_log.clear()
	mission_success = true
	state_changed.emit()

func get_current_build() -> Dictionary:
	var target = DataManager.get_target(target_id)
	var rocket = DataManager.get_rocket(rocket_id)
	var platform = DataManager.get_platform(platform_id)
	var power = DataManager.get_power(power_id)
	var antenna = DataManager.get_antenna(antenna_id)
	var m_class = DataManager.get_mission_class(class_id)
	var goal = DataManager.get_goal(goal_id)
	var inst_list: Array = []
	for inst_id in selected_instruments:
		var inst = DataManager.get_instrument(inst_id)
		if not inst.is_empty():
			inst_list.append(inst)
	return {
		"target": target,
		"rocket": rocket,
		"platform": platform,
		"power": power,
		"antenna": antenna,
		"instruments": inst_list,
		"class": m_class,
		"goal": goal
	}

func get_current_stats() -> Dictionary:
	return Calc.evaluate_build(get_current_build())

func toggle_instrument(inst_id: String) -> void:
	if selected_instruments.has(inst_id):
		selected_instruments.erase(inst_id)
	else:
		var platform = DataManager.get_platform(platform_id)
		var max_slots = int(platform.get("slots", 4))
		if selected_instruments.size() < max_slots:
			selected_instruments.append(inst_id)
	state_changed.emit()

func set_phase(new_phase: String) -> void:
	current_phase = new_phase
	phase_changed.emit(new_phase)
	state_changed.emit()
