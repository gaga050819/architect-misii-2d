extends Node

signal leaderboard_loaded(entries: Array)
signal score_submitted(success: bool)

var api_base: String = "https://kvdb.io/NX3aW88qQJiiNGJ2m9mK16/"
var http_fetch: HTTPRequest
var http_submit: HTTPRequest
var is_fetching: bool = false
var is_submitting: bool = false

func _ready() -> void:
	http_fetch = HTTPRequest.new()
	add_child(http_fetch)
	http_fetch.request_completed.connect(_on_fetch_completed)

	http_submit = HTTPRequest.new()
	add_child(http_submit)
	http_submit.request_completed.connect(_on_submit_completed)

func fetch_leaderboard() -> void:
	if is_fetching:
		return
	is_fetching = true
	var url = api_base + "?prefix=entry_&values=true"
	var err = http_fetch.request(url)
	if err != OK:
		is_fetching = false
		leaderboard_loaded.emit([])

func submit_score(p_name: String, p_score: int, p_target: String) -> void:
	if is_submitting:
		return
	is_submitting = true
	var clean_name = p_name.strip_edges()
	if clean_name.is_empty():
		clean_name = "Командир"
	clean_name = clean_name.substr(0, 24)

	var t_stamp = int(Time.get_unix_time_from_system())
	var r_num = randi() % 9999
	var key = "entry_%d_%04d" % [t_stamp, r_num]
	var url = api_base + key

	var payload = {
		"name": clean_name,
		"score": p_score,
		"target": p_target,
		"date": Time.get_date_string_from_system()
	}
	var json_str = JSON.stringify(payload)
	var headers = PackedStringArray(["Content-Type: application/json"])
	var err = http_submit.request(url, headers, HTTPClient.METHOD_POST, json_str)
	if err != OK:
		is_submitting = false
		score_submitted.emit(false)

func _on_fetch_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	is_fetching = false
	var entries: Array = []
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		leaderboard_loaded.emit(entries)
		return

	var text = body.get_string_from_utf8()
	var lines = text.split("\n", false)
	for line in lines:
		var eq_idx = line.find("=")
		if eq_idx == -1:
			continue
		var val_str = line.substr(eq_idx + 1).strip_edges()
		var json = JSON.new()
		var parse_err = json.parse(val_str)
		if parse_err == OK and json.data is Dictionary:
			var d = json.data as Dictionary
			entries.append({
				"name": str(d.get("name", "Невідомий")),
				"score": int(d.get("score", 0)),
				"target": str(d.get("target", "Місія")),
				"date": str(d.get("date", ""))
			})

	entries.sort_custom(func(a, b): return int(a["score"]) > int(b["score"]))
	if entries.size() > 30:
		entries = entries.slice(0, 30)

	leaderboard_loaded.emit(entries)

func _on_submit_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	is_submitting = false
	var ok = (result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300)
	score_submitted.emit(ok)
	if ok:
		fetch_leaderboard()
