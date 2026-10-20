extends CanvasLayer
class_name EcosHud
## Interfaz durante el juego: energia, frutas, bichos, nivel, puntaje y eco.

var _energy_fill: ColorRect
var _energy_bg: ColorRect
var _fruits_label: Label
var _bugs_label: Label
var _level_label: Label
var _score_label: Label
var _echo_label: Label
var _hint_label: Label
var _echo_flash := 0.0

const BAR_W := 284.0
const BAR_H := 16.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	var panel := ColorRect.new()
	panel.color = Color(0, 0, 0, 0.45)
	panel.position = Vector2(16, 16)
	panel.size = Vector2(316, 80)
	add_child(panel)

	_fruits_label = _make_label(Vector2(26, 22), 16)
	_bugs_label = _make_label(Vector2(180, 22), 16)

	var energy_title := _make_label(Vector2(26, 48), 13)
	energy_title.text = "Energia"

	_energy_bg = ColorRect.new()
	_energy_bg.color = Color(0.1, 0.1, 0.14, 0.9)
	_energy_bg.position = Vector2(26, 68)
	_energy_bg.size = Vector2(BAR_W, BAR_H)
	add_child(_energy_bg)

	_energy_fill = ColorRect.new()
	_energy_fill.color = Color(0.35, 0.85, 0.4)
	_energy_fill.position = Vector2(26, 68)
	_energy_fill.size = Vector2(BAR_W, BAR_H)
	add_child(_energy_fill)

	_level_label = _make_label(Vector2(0, 22), 18)
	_level_label.position = Vector2(1060, 22)
	_level_label.size = Vector2(200, 30)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_level_label)

	_score_label = _make_label(Vector2(26, 672), 18)
	add_child(_score_label)

	_echo_label = _make_label(Vector2(560, 24), 16)
	_echo_label.size = Vector2(160, 30)
	_echo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_echo_label.text = "ECOLOCALIZACION"
	add_child(_echo_label)

	_hint_label = _make_label(Vector2(360, 690), 14)
	_hint_label.size = Vector2(560, 24)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.text = "A/D o flechas moverse   W subir   S bajar   E ecolocalizar   R reiniciar   ESC pausa"
	add_child(_hint_label)

	EcosGameState.energy_changed.connect(_on_energy_changed)
	EcosGameState.stats_changed.connect(_refresh)
	_on_energy_changed(EcosGameState.energy, EcosGameState.ENERGY_MAX)
	_refresh()

func _make_label(pos: Vector2, size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 4)
	return l

func _on_energy_changed(value: float, maximum: float) -> void:
	var ratio: float = 0.0 if maximum <= 0.0 else clampf(value / maximum, 0.0, 1.0)
	_energy_fill.size = Vector2(BAR_W * ratio, BAR_H)
	if ratio > 0.5:
		_energy_fill.color = Color(0.35, 0.85, 0.4)
	elif ratio > 0.25:
		_energy_fill.color = Color(0.95, 0.78, 0.25)
	else:
		_energy_fill.color = Color(0.9, 0.3, 0.25)

func _refresh() -> void:
	_fruits_label.text = "Frutas: %d" % EcosGameState.fruits
	_bugs_label.text = "Bichos: %d" % EcosGameState.bugs
	_level_label.text = "Nivel %02d" % EcosGameState.current_level
	_level_label.tooltip_text = EcosLevelData.LEVEL_NAMES[clampi(EcosGameState.current_level - 1, 0, 9)]
	_score_label.text = "Puntos: %d" % EcosGameState.score

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("echolocation"):
		_echo_flash = 0.6
	if _echo_flash > 0.0:
		_echo_flash -= delta
		_echo_label.modulate = Color(0.5, 0.95, 1.0, 1.0)
	else:
		_echo_label.modulate = Color(1, 1, 1, 0.35)
