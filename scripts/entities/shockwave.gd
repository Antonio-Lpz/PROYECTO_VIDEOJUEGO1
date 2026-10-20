extends Area2D
class_name EcosShockwave
## Onda expansiva de los jefes (Guardian de la Cueva). Dania al contacto.

var radius := 12.0
var max_radius := 150.0
var speed := 260.0
var damage := 12.0
var _shape: CircleShape2D

func _ready() -> void:
	collision_layer = 16
	collision_mask = 2
	z_index = 7
	var cs := CollisionShape2D.new()
	_shape = CircleShape2D.new()
	_shape.radius = radius
	cs.shape = _shape
	add_child(cs)

func get_contact_damage() -> float:
	return damage

func _process(delta: float) -> void:
	radius += speed * delta
	_shape.radius = radius
	queue_redraw()
	if radius >= max_radius:
		queue_free()

func _draw() -> void:
	var t := clampf(radius / max_radius, 0.0, 1.0)
	var alpha := (1.0 - t) * 0.85
	draw_arc(Vector2.ZERO, radius, 0, TAU, 48, Color(0.65, 0.5, 1.0, alpha), 3.0)
	draw_arc(Vector2.ZERO, radius * 0.8, 0, TAU, 48, Color(0.4, 0.9, 1.0, alpha * 0.5), 2.0)
