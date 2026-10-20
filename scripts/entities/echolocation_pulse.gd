extends Node2D
class_name EcholocationPulse
## Onda visual de la ecolocalizacion: anillo que se expande y se desvanece.

var radius := 0.0
var max_radius := 320.0
var speed := 520.0
var _color := Color(0.5, 0.95, 1.0)

func _process(delta: float) -> void:
	radius += speed * delta
	queue_redraw()
	if radius >= max_radius:
		queue_free()

func _draw() -> void:
	var t := clampf(radius / max_radius, 0.0, 1.0)
	var alpha := (1.0 - t) * 0.85
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, Color(_color.r, _color.g, _color.b, alpha), 3.0)
	if radius > 30.0:
		draw_arc(Vector2.ZERO, radius - 24.0, 0, TAU, 64, Color(_color.r, _color.g, _color.b, alpha * 0.4), 2.0)
