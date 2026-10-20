extends Node
## Estado global del juego: energia, puntaje, progreso y guardado local.
## Se registra como autoload con el nombre "EcosGameState".

const SAVE_PATH := "user://ecos_de_la_noche.save"
const TOTAL_LEVELS := 10

const ENERGY_MAX := 100.0
const ENERGY_DRAIN_PER_SEC := 0.6

var energy: float = ENERGY_MAX
var score: int = 0
var fruits: int = 0
var bugs: int = 0
var current_level: int = 1
var unlocked_levels: int = 1
var level_scores: Dictionary = {}

signal energy_changed(value: float, maximum: float)
signal stats_changed()
signal died()

func _ready() -> void:
	_ensure_input_map()
	load_game()

func reset_level_stats() -> void:
	energy = ENERGY_MAX
	score = 0
	fruits = 0
	bugs = 0
	energy_changed.emit(energy, ENERGY_MAX)
	stats_changed.emit()

func add_energy(amount: float) -> void:
	energy = clampf(energy + amount, 0.0, ENERGY_MAX)
	energy_changed.emit(energy, ENERGY_MAX)

func damage(amount: float) -> void:
	energy = clampf(energy - amount, 0.0, ENERGY_MAX)
	energy_changed.emit(energy, ENERGY_MAX)
	if energy <= 0.0:
		died.emit()

func consume(amount: float) -> void:
	energy = clampf(energy - amount, 0.0, ENERGY_MAX)
	energy_changed.emit(energy, ENERGY_MAX)
	if energy <= 0.0:
		died.emit()

func add_fruit(points: int, energy_gain: float) -> void:
	fruits += 1
	score += points
	add_energy(energy_gain)
	stats_changed.emit()

func add_bug(points: int, energy_gain: float) -> void:
	bugs += 1
	score += points
	add_energy(energy_gain)
	stats_changed.emit()

func complete_level() -> void:
	score += 100
	if current_level >= unlocked_levels and unlocked_levels < TOTAL_LEVELS:
		unlocked_levels = min(current_level + 1, TOTAL_LEVELS)
	var prev: int = int(level_scores.get(current_level, 0))
	level_scores[current_level] = max(prev, score)
	stats_changed.emit()
	save_game()

func register_hit() -> void:
	pass

# --- Guardado ---

func save_game() -> void:
	var data := {
		"unlocked_levels": unlocked_levels,
		"current_level": current_level,
		"level_scores": level_scores,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("No se pudo escribir el guardado: %s" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	unlocked_levels = int(parsed.get("unlocked_levels", 1))
	current_level = int(parsed.get("current_level", 1))
	var raw_scores = parsed.get("level_scores", {})
	if typeof(raw_scores) == TYPE_DICTIONARY:
		for k in raw_scores:
			level_scores[int(k)] = int(raw_scores[k])

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	unlocked_levels = 1
	current_level = 1
	level_scores.clear()

# --- Mapa de entrada (se define por codigo para no depender del editor) ---

func _ensure_input_map() -> void:
	var definitions := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"echolocation": [KEY_E],
		"interact": [KEY_E],
		"pause": [KEY_ESCAPE],
		"restart": [KEY_R],
		"confirm": [KEY_ENTER, KEY_SPACE],
	}
	for action in definitions.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for keycode in definitions[action]:
			var ev := InputEventKey.new()
			ev.keycode = keycode
			ev.physical_keycode = keycode
			if not InputMap.action_has_event(action, ev):
				InputMap.action_add_event(action, ev)
