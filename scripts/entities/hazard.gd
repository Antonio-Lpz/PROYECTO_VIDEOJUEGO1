extends Area2D
class_name EcosHazard
## Peligros estaticos o moviles que reducen la energia al contacto.

enum Kind { SPIKES, THORNS, WEB, FALLING_ROCK }

var kind: int = Kind.SPIKES
var damage := 12.0
var _time := 0.0
var _origin := Vector2.ZERO
var _move_range := 0.0

func setup(kind_value: int) -> void:
	kind = kind_value

func _ready() -> void:
	add_to_group("revealable")
	collision_layer = 16
	collision_mask = 2
	_origin = position
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 18)
	shape.shape = rect
	add_child(shape)
	if kind == Kind.FALLING_ROCK or kind == Kind.WEB:
		rect.size = Vector2(24, 24)

func set_move_range(value: float) -> void:
	_move_range = value

func get_contact_damage() -> float:
	return damage

func _process(delta: float) -> void:
	_time += delta
	if _move_range > 0.0:
		position.y = _origin.y + sin(_time * 1.5) * _move_range
	queue_redraw()

func _draw() -> void:
	match kind:
		Kind.SPIKES:
			_draw_spikes()
		Kind.THORNS:
			_draw_thorns()
		Kind.WEB:
			_draw_web()
		Kind.FALLING_ROCK:
			_draw_rock()

func _draw_spikes() -> void:
	var color := Color(0.55, 0.57, 0.6)
	for i in 3:
		var x := -10.0 + i * 10.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 5, 9), Vector2(x + 5, 9), Vector2(x, -9),
		]), color)

func _draw_thorns() -> void:
	var color := Color(0.30, 0.45, 0.22)
	for i in 3:
		var x := -8.0 + i * 8.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 4, 9), Vector2(x + 4, 9), Vector2(x, -8),
		]), color)

func _draw_web() -> void:
	var color := Color(0.8, 0.8, 0.85, 0.7)
	for i in 4:
		var a := PI * float(i) / 4.0
		draw_line(Vector2(-12, -12), Vector2(12, 12).rotated(a), color, 1.2)
		draw_line(Vector2(12, -12), Vector2(-12, 12).rotated(a), color, 1.2)
	draw_arc(Vector2.ZERO, 10.0, 0, TAU, 24, color, 1.0)

func _draw_rock() -> void:
	draw_circle(Vector2.ZERO, 12.0, Color(0.4, 0.4, 0.42))
	if _move_range > 0.0:
		draw_line(Vector2(0, -12), Vector2(0, -22), Color(0.5, 0.5, 0.5, 0.5), 2.0)

func set_highlight(value: bool) -> void:
	modulate = Color(2.0, 2.0, 2.0) if value else Color(1, 1, 1)
