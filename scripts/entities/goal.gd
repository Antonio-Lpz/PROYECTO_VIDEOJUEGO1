extends Area2D
class_name EcosGoal
## Zona final del nivel. Al entrar se completa el nivel.

signal reached()

var _time := 0.0
var is_final := false

func _ready() -> void:
	add_to_group("revealable")
	collision_layer = 32
	collision_mask = 2
	monitorable = true
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(60, 140)
	shape.shape = rect
	add_child(shape)
	body_entered.connect(_on_body)
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _on_body(body: Node2D) -> void:
	if body is BatPlayer:
		EcosAudio.play("goal", -5.0)
		reached.emit()

func set_highlight(_value: bool) -> void:
	pass

func _draw() -> void:
	var pulse := 0.6 + 0.4 * sin(_time * 3.0)
	if is_final:
		draw_circle(Vector2.ZERO, 70.0 * pulse, Color(1.0, 0.85, 0.4, 0.10))
		draw_arc(Vector2.ZERO, 60.0, 0, TAU, 48, Color(1.0, 0.9, 0.5, 0.7), 3.0)
	else:
		draw_circle(Vector2.ZERO, 70.0 * pulse, Color(0.4, 0.9, 1.0, 0.08))
		draw_arc(Vector2.ZERO, 60.0, 0, TAU, 48, Color(0.5, 0.95, 1.0, 0.6), 3.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -70), Vector2(-24, -40), Vector2(-24, 70),
		Vector2(24, 70), Vector2(24, -40),
	]), Color(0.2, 0.25, 0.4, 0.25))
