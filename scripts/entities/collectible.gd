extends Area2D
class_name EcosCollectible
## Alimento recolectable: frutas y bichos. Recupera energia y da puntaje.

const TYPES := {
	"fruit": {"energy": 15.0, "points": 10, "is_fruit": true},
	"bug_small": {"energy": 10.0, "points": 30, "is_fruit": false},
	"bug_medium": {"energy": 20.0, "points": 30, "is_fruit": false},
	"bug_special": {"energy": 30.0, "points": 30, "is_fruit": false},
}

var type := "fruit"
var _bob := 0.0
var _base_y := 0.0
var highlight := false
var _sprite: Sprite2D
var _use_sprite := false

func setup(kind: String) -> void:
	type = kind if TYPES.has(kind) else "fruit"

func _ready() -> void:
	add_to_group("revealable")
	collision_layer = 8
	collision_mask = 2
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 12.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	_base_y = position.y
	_setup_sprite()

func _setup_sprite() -> void:
	var sprite_name := "apple" if type == "fruit" else "bug"
	var path := "res://assets/sprites/%s.png" % sprite_name
	if not ResourceLoader.exists(path):
		return
	_sprite = Sprite2D.new()
	_sprite.texture = load(path)
	_sprite.scale = Vector2(0.9, 0.9)
	_sprite.z_index = 1
	if sprite_name == "bug":
		match type:
			"bug_medium":
				_sprite.modulate = Color(1.0, 0.75, 0.4)
			"bug_special":
				_sprite.modulate = Color(0.55, 1.0, 1.0)
	add_child(_sprite)
	_use_sprite = true

func _process(delta: float) -> void:
	_bob += delta * 3.0
	position.y = _base_y + sin(_bob) * 3.0
	queue_redraw()

func set_highlight(value: bool) -> void:
	if highlight != value:
		highlight = value
		modulate = Color(2.2, 2.2, 2.2) if value else Color(1, 1, 1)
		queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if not (body is BatPlayer):
		return
	var data: Dictionary = TYPES[type]
	if data["is_fruit"]:
		EcosGameState.add_fruit(int(data["points"]), float(data["energy"]))
		EcosAudio.play("collect_fruit", -8.0)
	else:
		EcosGameState.add_bug(int(data["points"]), float(data["energy"]))
		EcosAudio.play("collect_bug", -8.0)
	queue_free()

func _draw() -> void:
	if _use_sprite:
		return
	if highlight:
		draw_circle(Vector2.ZERO, 18.0, Color(0.4, 1.0, 0.95, 0.25))
	if type == "fruit":
		_draw_fruit()
	else:
		_draw_bug()

func _draw_fruit() -> void:
	var r := 8.0
	var color := Color(0.85, 0.20, 0.25)
	if type == "fruit":
		color = Color(0.85, 0.20, 0.25)
	draw_circle(Vector2(-2, 0), r, color)
	draw_circle(Vector2(2, 0), r, color)
	draw_line(Vector2(0, -8), Vector2(2, -13), Color(0.35, 0.6, 0.25), 1.5)
	draw_colored_polygon(PackedVector2Array([
		Vector2(2, -13), Vector2(8, -14), Vector2(3, -9),
	]), Color(0.30, 0.65, 0.28))

func _draw_bug() -> void:
	var scale_size := 1.0
	var color := Color(0.95, 0.80, 0.20)
	if type == "bug_medium":
		color = Color(0.90, 0.55, 0.15)
		scale_size = 1.25
	elif type == "bug_special":
		color = Color(0.55, 0.90, 0.95)
		scale_size = 1.4
	var w := 5.0 * scale_size
	_draw_ellipse(Vector2.ZERO, w, w * 0.7, color)
	draw_circle(Vector2(0, -w * 0.4), w * 0.5, color.darkened(0.2))
	var wing := Color(1, 1, 1, 0.5)
	_draw_ellipse(Vector2(-w * 0.6, 0), w * 0.5, w * 0.3, wing)
	_draw_ellipse(Vector2(w * 0.6, 0), w * 0.5, w * 0.3, wing)
	# patas
	draw_line(Vector2(-w * 0.5, w * 0.4), Vector2(-w * 0.2, w * 0.9), color.darkened(0.4), 1.0)
	draw_line(Vector2(w * 0.5, w * 0.4), Vector2(w * 0.2, w * 0.9), color.darkened(0.4), 1.0)

func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color, segments := 20) -> void:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, color)
