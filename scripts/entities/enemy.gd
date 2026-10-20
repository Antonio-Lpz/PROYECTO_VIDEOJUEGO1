extends CharacterBody2D
class_name EcosEnemy
## Enemigos del bosque y las cuevas. Comportamiento segun su tipo.

const GRAVITY := 900.0

enum Kind { SPIDER, OWL, SNAKE, BOSS_OWL, CAVE_GUARDIAN }

var kind: int = Kind.SPIDER
var speed := 70.0
var detect_radius := 220.0
var patrol_range := 90.0

var _origin := Vector2.ZERO
var _dir := 1.0
var _time := 0.0
var _target: Node2D = null
var highlight := false
var _awake := false
var _sprite: Sprite2D
var _use_sprite := false

# Estado de jefes
var _mode := 0
var _attack_timer := 0.0
var _dive_target := Vector2.ZERO
var _dive_time := 0.0
var _special_timer := 0.0

func setup(kind_value: int) -> void:
	kind = kind_value
	match kind:
		Kind.SPIDER:
			speed = 55.0
			detect_radius = 210.0
		Kind.OWL:
			speed = 120.0
			detect_radius = 300.0
		Kind.SNAKE:
			speed = 130.0
			detect_radius = 170.0
		Kind.BOSS_OWL:
			speed = 150.0
			detect_radius = 420.0
			scale = Vector2(1.8, 1.8)
		Kind.CAVE_GUARDIAN:
			speed = 110.0
			detect_radius = 420.0
			scale = Vector2(2.2, 2.2)

func _ready() -> void:
	add_to_group("revealable")
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	_origin = global_position

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14.0
	shape.shape = circle
	add_child(shape)

	if kind == Kind.OWL or kind == Kind.BOSS_OWL or kind == Kind.CAVE_GUARDIAN:
		collision_mask = 0
		z_index = 6
	else:
		z_index = 5

	_setup_sprite()
	_attack_timer = randf_range(1.5, 3.0)
	_special_timer = randf_range(5.0, 7.0)

func _setup_sprite() -> void:
	var file := ""
	match kind:
		Kind.SPIDER:
			file = "spider"
		Kind.OWL:
			file = "owl"
		Kind.SNAKE:
			file = "snake"
		Kind.BOSS_OWL:
			file = "owl_boss"
		Kind.CAVE_GUARDIAN:
			file = "guardian"
	var path := "res://assets/sprites/%s.png" % file
	if file == "" or not ResourceLoader.exists(path):
		return
	var s := Sprite2D.new()
	s.texture = load(path)
	s.scale = Vector2(1.2, 1.2)
	s.z_index = 1
	add_child(s)
	_sprite = s
	_use_sprite = true

func is_flying() -> bool:
	return kind == Kind.OWL or kind == Kind.BOSS_OWL or kind == Kind.CAVE_GUARDIAN

func _physics_process(delta: float) -> void:
	_time += delta
	if _target == null or not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player")

	if is_flying():
		_fly_behavior(delta)
	else:
		_ground_behavior(delta)

	queue_redraw()

func _fly_behavior(delta: float) -> void:
	if kind == Kind.BOSS_OWL:
		_boss_owl_behavior(delta)
		return
	if kind == Kind.CAVE_GUARDIAN:
		_guardian_behavior(delta)
		return
	# Buho comun: patrulla y persigue brevemente
	var target := _origin
	var chasing := false
	if _target != null and global_position.distance_to(_target.global_position) < detect_radius:
		chasing = true
		target = _target.global_position

	if chasing:
		var to := (target - global_position)
		velocity = to.normalized() * speed
	else:
		var x := _origin.x + sin(_time * 1.2) * patrol_range
		velocity = Vector2((x - global_position.x), (_origin.y - global_position.y) * 2.0)
		velocity = velocity.normalized() * speed * 0.7
	move_and_slide()

func _boss_owl_behavior(delta: float) -> void:
	_dive_time -= delta
	_attack_timer -= delta
	var to_player := Vector2.ZERO
	var near := false
	if _target != null and is_instance_valid(_target):
		to_player = _target.global_position - global_position
		near = to_player.length() < detect_radius

	if _dive_time > 0.0:
		# En picada rapida hacia el punto fijado
		velocity = (_dive_target - global_position).normalized() * speed * 1.9
	elif _attack_timer <= 0.0 and near:
		# Inicia ataque
		_attack_timer = randf_range(3.0, 4.5)
		_dive_time = 0.75
		_dive_target = _target.global_position
		EcosAudio.play("flap", -8.0, 0.8)
	else:
		# Flotar/patrullar y acercarse lentamente
		if near:
			velocity = to_player.normalized() * speed * 0.5
		else:
			var x := _origin.x + sin(_time * 1.1) * patrol_range * 1.5
			velocity = Vector2(x - global_position.x, _origin.y - global_position.y).normalized() * speed * 0.5
	move_and_slide()

func _guardian_behavior(delta: float) -> void:
	_attack_timer -= delta
	_special_timer -= delta
	_dive_time -= delta

	var near := false
	var to_player := Vector2.ZERO
	if _target != null and is_instance_valid(_target):
		to_player = _target.global_position - global_position
		near = to_player.length() < detect_radius

	if _dive_time > 0.0:
		velocity = (_dive_target - global_position).normalized() * speed * 1.7
	else:
		if near and _attack_timer <= 0.0:
			_attack_timer = randf_range(3.0, 4.5)
			_spawn_shockwave()
		if near and _special_timer <= 0.0:
			_special_timer = randf_range(6.0, 8.0)
			_dive_time = 0.7
			_dive_target = _target.global_position
			EcosAudio.play("hit", -10.0, 0.6)
		if near:
			velocity = to_player.normalized() * speed * 0.55
		else:
			velocity = Vector2(_origin.x - global_position.x, _origin.y - global_position.y).normalized() * speed * 0.4
	velocity.y += sin(_time * 2.0) * 12.0
	move_and_slide()

func _spawn_shockwave() -> void:
	if get_parent() == null:
		return
	var sw := EcosShockwave.new()
	sw.damage = 12.0
	get_parent().add_child(sw)
	sw.global_position = global_position
	EcosAudio.play("echolocation", -8.0, 0.7)

func _ground_behavior(delta: float) -> void:
	velocity.y += GRAVITY * delta
	var near := false
	if _target != null and global_position.distance_to(_target.global_position) < detect_radius:
		near = true

	if kind == Kind.SPIDER and not _awake:
		if near:
			_awake = true
		else:
			velocity.x = 0.0
			move_and_slide()
			return

	var move_speed := speed
	if near:
		_dir = signf(_target.global_position.x - global_position.x)
		move_speed = speed * 1.6
		if _dir == 0.0:
			_dir = 1.0
	else:
		if global_position.x > _origin.x + patrol_range:
			_dir = -1.0
		elif global_position.x < _origin.x - patrol_range:
			_dir = 1.0

	velocity.x = _dir * move_speed
	if _use_sprite:
		_sprite.flip_h = _dir < 0.0
	move_and_slide()
	if is_on_floor():
		velocity.y = 0.0

func _draw() -> void:
	if _use_sprite:
		return
	if highlight:
		draw_circle(Vector2.ZERO, 26.0, Color(1.0, 0.3, 0.35, 0.18))
	match kind:
		Kind.SPIDER:
			_draw_spider()
		Kind.OWL, Kind.BOSS_OWL:
			_draw_owl(kind == Kind.BOSS_OWL)
		Kind.SNAKE:
			_draw_snake()
		Kind.CAVE_GUARDIAN:
			_draw_guardian()

func _draw_spider() -> void:
	var body := Color(0.12, 0.10, 0.16)
	draw_circle(Vector2(0, 0), 8.0, body)
	draw_circle(Vector2(0, -9), 5.5, body.darkened(0.15))
	for i in 4:
		var y := -6.0 + i * 4.0
		draw_line(Vector2(-4, y), Vector2(-16, y - 5), body, 1.6)
		draw_line(Vector2(4, y), Vector2(16, y - 5), body, 1.6)
	draw_circle(Vector2(-3, -10), 1.8, Color(0.9, 0.1, 0.15))
	draw_circle(Vector2(3, -10), 1.8, Color(0.9, 0.1, 0.15))

func _draw_owl(big: bool) -> void:
	var feather := Color(0.45, 0.33, 0.22)
	if big:
		feather = Color(0.35, 0.24, 0.18)
	_draw_ellipse(Vector2.ZERO, 13.0, 16.0, feather)
	_draw_ellipse(Vector2.ZERO, 9.0, 12.0, feather.lightened(0.1))
	# alas
	draw_colored_polygon(PackedVector2Array([
		Vector2(-11, -6), Vector2(-26, 2), Vector2(-10, 10),
	]), feather.darkened(0.2))
	draw_colored_polygon(PackedVector2Array([
		Vector2(11, -6), Vector2(26, 2), Vector2(10, 10),
	]), feather.darkened(0.2))
	# ojos
	draw_circle(Vector2(-5, -5), 4.5, Color(0.95, 0.85, 0.25))
	draw_circle(Vector2(5, -5), 4.5, Color(0.95, 0.85, 0.25))
	draw_circle(Vector2(-5, -5), 2.0, Color(0.05, 0.05, 0.05))
	draw_circle(Vector2(5, -5), 2.0, Color(0.05, 0.05, 0.05))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -1), Vector2(-3, 4), Vector2(3, 4),
	]), Color(0.9, 0.6, 0.15))

func _draw_snake() -> void:
	var color := Color(0.30, 0.55, 0.30)
	var pts := PackedVector2Array()
	for i in 7:
		var t := float(i)
		pts.append(Vector2(-24 + t * 7.0, sin(_time * 6.0 + t * 0.8) * 4.0))
	draw_polyline(pts, color, 6.0)
	var head := pts[pts.size() - 1]
	draw_circle(head, 5.0, color.lightened(0.1))
	draw_circle(head + Vector2(2, -1.5), 2.0, Color(0.95, 0.85, 0.2))
	draw_circle(head + Vector2(2, -1.5), 1.0, Color(0.05, 0.05, 0.05))
	draw_line(head + Vector2(4, 2), head + Vector2(10, 5), Color(0.9, 0.1, 0.1), 1.5)

func _draw_guardian() -> void:
	var color := Color(0.20, 0.16, 0.30)
	draw_circle(Vector2.ZERO, 16.0, color)
	# cuernos
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12, -8), Vector2(-20, -24), Vector2(-4, -12),
	]), color.darkened(0.3))
	draw_colored_polygon(PackedVector2Array([
		Vector2(12, -8), Vector2(20, -24), Vector2(4, -12),
	]), color.darkened(0.3))
	# ojos
	draw_circle(Vector2(-6, -2), 4.0, Color(0.6, 0.9, 1.0))
	draw_circle(Vector2(6, -2), 4.0, Color(0.6, 0.9, 1.0))
	draw_circle(Vector2(-6, -2), 1.8, Color(0.05, 0.05, 0.1))
	draw_circle(Vector2(6, -2), 1.8, Color(0.05, 0.05, 0.1))
	_draw_ellipse(Vector2.ZERO, 18.0, 22.0, Color(0.25, 0.2, 0.38, 0.35))

func set_highlight(value: bool) -> void:
	if highlight != value:
		highlight = value
		modulate = Color(2.2, 2.2, 2.2) if value else Color(1, 1, 1)
		queue_redraw()

func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color, segments := 20) -> void:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, color)
