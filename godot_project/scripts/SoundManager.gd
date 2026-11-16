extends Node

var player: AudioStreamPlayer
var generator: AudioStreamGenerator
var playback: AudioStreamGeneratorPlayback
var sample_rate: float = 22050.0

func _ready() -> void:
	player = AudioStreamPlayer.new()
	generator = AudioStreamGenerator.new()
	generator.mix_rate = sample_rate
	generator.buffer_length = 0.1
	player.stream = generator
	add_child(player)
	player.play()
	playback = player.get_stream_playback()

func play_beep(freq: float = 880.0, duration: float = 0.08) -> void:
	if not playback:
		return
	var frames_to_push = int(sample_rate * duration)
	for i in range(frames_to_push):
		var t = float(i) / sample_rate
		var sample = sin(TAU * freq * t) * (1.0 - (float(i) / float(frames_to_push))) * 0.2
		playback.push_frame(Vector2(sample, sample))

func play_click() -> void:
	play_beep(1200.0, 0.03)

func play_success() -> void:
	play_beep(587.33, 0.06)
	play_beep(880.0, 0.12)

func play_thruster() -> void:
	if not playback:
		return
	var frames_to_push = int(sample_rate * 0.05)
	for i in range(frames_to_push):
		var sample = (randf() * 2.0 - 1.0) * 0.15
		playback.push_frame(Vector2(sample, sample))

func play_explosion() -> void:
	if not playback:
		return
	var frames_to_push = int(sample_rate * 0.45)
	for i in range(frames_to_push):
		var progress = float(i) / float(frames_to_push)
		var env = pow(1.0 - progress, 2.0)
		var noise = (randf() * 2.0 - 1.0) * 0.45
		var bass = sin(TAU * 55.0 * (float(i) / sample_rate)) * 0.35
		var sample = (noise + bass) * env
		playback.push_frame(Vector2(sample, sample))

func play_laser() -> void:
	if not playback:
		return
	var frames_to_push = int(sample_rate * 0.12)
	for i in range(frames_to_push):
		var progress = float(i) / float(frames_to_push)
		var freq = lerp(2200.0, 420.0, progress)
		var env = (1.0 - progress) * 0.3
		var sample = sin(TAU * freq * (float(i) / sample_rate)) * env
		playback.push_frame(Vector2(sample, sample))

func play_drill() -> void:
	if not playback:
		return
	var frames_to_push = int(sample_rate * 0.18)
	for i in range(frames_to_push):
		var t = float(i) / sample_rate
		var mod = sin(TAU * 35.0 * t) * 0.5 + 0.5
		var noise = (randf() * 2.0 - 1.0) * 0.2
		var buzz = sin(TAU * 140.0 * t) * 0.25
		var sample = (buzz + noise) * mod
		playback.push_frame(Vector2(sample, sample))

func play_radio_chirp() -> void:
	if not playback:
		return
	var frames_to_push = int(sample_rate * 0.07)
	for i in range(frames_to_push):
		var t = float(i) / sample_rate
		var sample = sin(TAU * 1760.0 * t) * 0.18
		playback.push_frame(Vector2(sample, sample))
