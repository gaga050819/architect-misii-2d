extends Node

var targets: Array = []
var rockets: Array = []
var platforms: Array = []
var instruments: Array = []
var power_sources: Array = []
var antennas: Array = []
var extras: Array = []
var mission_classes: Array = []
var mission_goals: Array = []
var events_data: Dictionary = {}
var media_data: Dictionary = {}
var images_cache: Dictionary = {}

func _ready() -> void:
	load_all_data()

func load_all_data() -> void:
	targets = load_json_array("res://data/targets.json")
	rockets = load_json_array("res://data/rockets.json")
	var comp_dict = load_json_dict("res://data/components.json")
	if comp_dict.has("platforms"):
		platforms = comp_dict["platforms"]
	if comp_dict.has("instruments"):
		instruments = comp_dict["instruments"]
	if comp_dict.has("power"):
		power_sources = comp_dict["power"]
	if comp_dict.has("antennas"):
		antennas = comp_dict["antennas"]
	if comp_dict.has("extras"):
		extras = comp_dict["extras"]
	var miss_dict = load_json_dict("res://data/mission.json")
	if miss_dict.has("classes"):
		mission_classes = miss_dict["classes"]
	if miss_dict.has("goals"):
		mission_goals = miss_dict["goals"]
	events_data = load_json_dict("res://data/events.json")
	media_data = load_json_dict("res://data/media.json")

func load_json_array(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text()
	var parsed = JSON.parse_string(text)
	if parsed is Array:
		return parsed
	return []

func load_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text()
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}

func get_item_by_id(list: Array, id: String) -> Dictionary:
	for item in list:
		if item is Dictionary and item.get("id") == id:
			return item
	return {}

func get_target(id: String) -> Dictionary:
	return get_item_by_id(targets, id)

func get_rocket(id: String) -> Dictionary:
	return get_item_by_id(rockets, id)

func get_platform(id: String) -> Dictionary:
	return get_item_by_id(platforms, id)

func get_power(id: String) -> Dictionary:
	return get_item_by_id(power_sources, id)

func get_antenna(id: String) -> Dictionary:
	return get_item_by_id(antennas, id)

func get_instrument(id: String) -> Dictionary:
	return get_item_by_id(instruments, id)

func get_mission_class(id: String) -> Dictionary:
	return get_item_by_id(mission_classes, id)

func get_goal(id: String) -> Dictionary:
	return get_item_by_id(mission_goals, id)

func get_localized(field: Variant, default_text: String = "") -> String:
	if field is Dictionary:
		if field.has("uk"):
			return str(field["uk"])
		elif field.has("en"):
			return str(field["en"])
	elif field is String:
		return field
	return default_text

func get_image_texture(img_name: String) -> Texture2D:
	if images_cache.has(img_name):
		return images_cache[img_name]
	var paths = [
		"res://assets/images/" + img_name + ".jpg",
		"res://assets/images/" + img_name + ".png",
		"res://assets/images/" + img_name,
		"res://assets/icons/" + img_name + ".svg",
		"res://assets/icons/" + img_name + ".png"
	]
	for p in paths:
		if ResourceLoader.exists(p):
			var tex = load(p)
			if tex is Texture2D:
				images_cache[img_name] = tex
				return tex
	return null
