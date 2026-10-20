extends Node
## Autoload de audio (EcosAudio). Reproduce efectos de sonido con un pool de
## reproductores para permitir solapamiento.

const POOL_SIZE := 10
const SFX_DIR := "res://assets/sfx/"

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _cache: Dictionary = {}
var _music: AudioStreamPlayer

func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)

func play_music(track: String, volume_db := -16.0) -> void:
	var stream := _get_stream(track)
	if stream == null:
		return
	if _music == null:
		_music = AudioStreamPlayer.new()
		add_child(_music)
	_music.stream = stream
	_music.volume_db = volume_db
	if not _music.finished.is_connected(_loop_music):
		_music.finished.connect(_loop_music)
	_music.play()

func _loop_music() -> void:
	if _music != null:
		_music.play()

func play(sound: String, volume_db := -6.0, pitch := 1.0) -> void:
	var stream := _get_stream(sound)
	if stream == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = clampf(pitch, 0.5, 2.0)
	p.play()

func _get_stream(sound: String) -> AudioStream:
	if _cache.has(sound):
		return _cache[sound]
	var path := SFX_DIR + sound + ".wav"
	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		stream = load(path)
	_cache[sound] = stream
	return stream
