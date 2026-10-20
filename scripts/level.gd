extends Node2D
class_name EcosLevel
## Construye un nivel a partir de la definicion data-driven y controla
## la ecolocalizacion y las condiciones de victoria/derrota.

signal level_completed()
signal player_died()

const REVEAL_SPEED := 620.0
const REVEAL_DURATION := 1.4

var index := 1
var data: Dictionary = {}
var player: BatPlayer
var _reveal_active := false
var _reveal_center := Vector2.ZERO
var _reveal_radius := 0.0
var _reveal_time := 0.0
var _bg := Color(0.05, 0.06, 0.12)

func _ready() -> void:
	data = EcosLevelData.get_level(index)
	EcosGameState.current_level = index
	EcosGameState.reset_level_stats()
	_build_background()
	_build_terrain()
	_build_contents()
	_build_goal()
	_spawn_player()
	_apply_darkness()

func _build_background() -> void:
	var theme: String = data["theme"]
	match theme:
		"cave":
			_bg = Color(0.06, 0.05, 0.10)
		"mixed":
			_bg = Color(0.06, 0.07, 0.12)
		"refuge":
			_bg = Color(0.10, 0.08, 0.16)
		_:
			_bg = Color(0.05, 0.07, 0.14)
	z_index = -100

func _build_terrain() -> void:
	var theme: String = data["theme"]
	var body_color := Color(0.16, 0.22, 0.14)
	var edge_color := Color(0.28, 0.42, 0.22)
	if theme == "cave":
		body_color = Color(0.14, 0.13, 0.18)
		edge_color = Color(0.28, 0.26, 0.34)
	elif theme == "mixed":
		body_color = Color(0.15, 0.17, 0.16)
		edge_color = Color(0.26, 0.34, 0.28)
	elif theme == "refuge":
		body_color = Color(0.20, 0.15, 0.24)
		edge_color = Color(0.36, 0.28, 0.42)

	for rect in data["platforms"]:
		_add_platform(rect, body_color, edge_color)

func _add_platform(rect: Rect2, body_color: Color, edge_color: Color) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.z_index = 1
	body.position = rect.position

	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	cs.shape = rs
	cs.position = rect.size * 0.5
	body.add_child(cs)

	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(rect.size.x, 0),
		Vector2(rect.size.x, rect.size.y), Vector2(0, rect.size.y),
	])
	poly.color = body_color
	body.add_child(poly)

	var top := Polygon2D.new()
	top.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(rect.size.x, 0),
		Vector2(rect.size.x, 6), Vector2(0, 6),
	])
	top.color = edge_color
	body.add_child(top)

	add_child(body)

func _build_contents() -> void:
	for item in data["collectibles"]:
		var c := EcosCollectible.new()
		c.setup(item["type"])
		c.position = item["pos"]
		c.z_index = 3
		add_child(c)

	for item in data["enemies"]:
		var e := EcosEnemy.new()
		e.setup(_enemy_kind(item["kind"]))
		e.position = item["pos"]
		e.z_index = 6
		add_child(e)

	for item in data["hazards"]:
		var h := EcosHazard.new()
		h.setup(_hazard_kind(item["kind"]))
		h.position = item["pos"]
		h.set_move_range(item.get("move", 0.0))
		h.z_index = 2
		add_child(h)

func _build_goal() -> void:
	var goal := EcosGoal.new()
	goal.is_final = data["is_final"]
	goal.position = data["goal"]
	goal.z_index = 4
	goal.reached.connect(_on_goal_reached)
	add_child(goal)

func _spawn_player() -> void:
	player = BatPlayer.new()
	player.position = data["spawn"]
	player.spawn_point = data["spawn"]
	player.death_y = data["death_y"]
	player.add_to_group("player")
	player.echolocated.connect(_on_echolocated)
	add_child(player)

	var width: float = data["width"]
	player.set_camera_limits(-60.0, -200.0, width + 60.0, data["height"] + 200.0)

func _apply_darkness() -> void:
	var darkness: float = data["darkness"]
	if darkness <= 0.0:
		return
	var cm := CanvasModulate.new()
	cm.color = Color(1, 1, 1).lerp(Color(0.22, 0.24, 0.40), darkness)
	add_child(cm)

func _process(delta: float) -> void:
	if not _reveal_active:
		return
	_reveal_time -= delta
	_reveal_radius += REVEAL_SPEED * delta
	for node in get_tree().get_nodes_in_group("revealable"):
		if node is Node2D and node.has_method("set_highlight"):
			var node_2d: Node2D = node as Node2D
			var distance: float = node_2d.global_position.distance_to(_reveal_center)
			node_2d.set_highlight(distance <= _reveal_radius)
	if _reveal_time <= 0.0:
		_reveal_active = false
		for node in get_tree().get_nodes_in_group("revealable"):
			if node.has_method("set_highlight"):
				node.set_highlight(false)

func _on_echolocated(origin: Vector2) -> void:
	var pulse := EcholocationPulse.new()
	pulse.z_index = 8
	pulse.max_radius = 420.0
	add_child(pulse)
	pulse.global_position = origin
	_reveal_active = true
	_reveal_center = origin
	_reveal_radius = 90.0
	_reveal_time = REVEAL_DURATION

func _on_goal_reached() -> void:
	if player != null:
		player.can_move = false
	level_completed.emit()

func _enemy_kind(name: String) -> int:
	match name:
		"owl":
			return EcosEnemy.Kind.OWL
		"snake":
			return EcosEnemy.Kind.SNAKE
		"boss_owl":
			return EcosEnemy.Kind.BOSS_OWL
		"cave_guardian":
			return EcosEnemy.Kind.CAVE_GUARDIAN
		_:
			return EcosEnemy.Kind.SPIDER

func _hazard_kind(name: String) -> int:
	match name:
		"thorns":
			return EcosHazard.Kind.THORNS
		"web":
			return EcosHazard.Kind.WEB
		"falling_rock":
			return EcosHazard.Kind.FALLING_ROCK
		_:
			return EcosHazard.Kind.SPIKES

func _draw() -> void:
	var width: float = data.get("width", 1280.0)
	var height: float = data.get("height", 720.0)
	var theme: String = data.get("theme", "forest")

	# Cielo con degradado simple
	var bands := 8
	for i in bands:
		var t := float(i) / float(bands)
		var color := _bg.lerp(_bg.lightened(0.25), t)
		draw_rect(Rect2(-200, -200 + (height + 400) * t / bands, width + 400, (height + 400) / bands + 2), color)

	if theme == "forest" or theme == "mixed" or theme == "refuge":
		# Estrellas
		var stars := _stars(width, height)
		for s in stars:
			draw_circle(s, 1.5, Color(1, 1, 1, 0.7))
		# Luna
		draw_circle(Vector2(width * 0.8, 120), 46.0, Color(0.9, 0.92, 0.8, 0.9))
		draw_circle(Vector2(width * 0.8 + 14, 112), 40.0, _bg)
	else:
		# Cristales de cueva
		var crystals := _crystals(width, height)
		for c in crystals:
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(0, -18), c + Vector2(-9, 12), c + Vector2(9, 12),
			]), Color(0.35, 0.45, 0.75, 0.35))

func _stars(width: float, height: float) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = index * 31 + 3
	var out: Array = []
	for i in 70:
		out.append(Vector2(rng.randf_range(0, width), rng.randf_range(0, height * 0.6)))
	return out

func _crystals(width: float, height: float) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = index * 17 + 5
	var out: Array = []
	for i in 30:
		out.append(Vector2(rng.randf_range(0, width), rng.randf_range(120, height * 0.8)))
	return out
