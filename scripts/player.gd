extends CharacterBody2D
class_name BatPlayer
## Murcielago protagonista: vuelo 2D, energia, dano y ecolocalizacion.

signal echolocated(origin: Vector2)

const SPEED := 300.0
const ACCEL := 1800.0
const FRICTION := 2200.0
const GRAVITY := 760.0
const FLAP_ACCEL := 2600.0
const MAX_FALL := 460.0
const MAX_RISE := 340.0
const DAMAGE := 15.0
const IFRAME_TIME := 1.2

var facing := 1
var can_move := true
var death_y := 100000.0
var spawn_point := Vector2.ZERO

var _wing_phase := 0.0
var _iframes := 0.0
var _knockback := Vector2.ZERO
var _hurtbox: Area2D
var _camera: Camera2D
var _sprite: AnimatedSprite2D
var _use_sprite := false
var _flap_timer := 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	z_index = 10

	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 10.0
	capsule.height = 26.0
	shape.shape = capsule
	add_child(shape)

	_hurtbox = Area2D.new()
	_hurtbox.collision_layer = 0
	_hurtbox.collision_mask = 4 | 16  # enemigos + peligros
	var hshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 12.0
	hshape.shape = circle
	_hurtbox.add_child(hshape)
	_hurtbox.body_entered.connect(_on_hurt_body)
	_hurtbox.area_entered.connect(_on_hurt_area)
	add_child(_hurtbox)

	_camera = Camera2D.new()
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 6.0
	add_child(_camera)

	_setup_sprite()

	EcosGameState.died.connect(_on_died)

func _setup_sprite() -> void:
	var names := ["bat_a", "bat_b", "bat_c"]
	for n in names:
		if not ResourceLoader.exists("res://assets/sprites/%s.png" % n):
			return
	var frames := SpriteFrames.new()
	frames.add_animation("fly")
	frames.set_animation_speed("fly", 10.0)
	frames.set_animation_loop("fly", true)
	for n in names:
		frames.add_frame("fly", load("res://assets/sprites/%s.png" % n))
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.scale = Vector2(1.4, 1.4)
	_sprite.z_index = 1
	add_child(_sprite)
	_sprite.play("fly")
	_use_sprite = true

func set_camera_limits(left: float, top: float, right: float, bottom: float) -> void:
	if _camera == null:
		return
	_camera.limit_left = int(left)
	_camera.limit_top = int(top)
	_camera.limit_right = int(right)
	_camera.limit_bottom = int(bottom)
	_camera.make_current()

func _physics_process(delta: float) -> void:
	if _iframes > 0.0:
		_iframes -= delta
		modulate.a = 0.4 + 0.6 * absf(sin(_iframes * 18.0))
		if _iframes <= 0.0:
			modulate.a = 1.0

	var dir := 0.0
	if can_move:
		dir = Input.get_axis("move_left", "move_right")
	if absf(dir) > 0.05:
		velocity.x = move_toward(velocity.x, dir * SPEED, ACCEL * delta)
		facing = 1 if dir > 0.0 else -1
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	velocity.y += GRAVITY * delta
	_flap_timer -= delta
	if can_move and Input.is_action_pressed("move_up"):
		velocity.y -= FLAP_ACCEL * delta
		if _flap_timer <= 0.0:
			EcosAudio.play("flap", -12.0, randf_range(0.95, 1.1))
			_flap_timer = 0.2
	if can_move and Input.is_action_pressed("move_down"):
		velocity.y += FLAP_ACCEL * delta
	velocity.y = clampf(velocity.y, -MAX_RISE, MAX_FALL)

	velocity += _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, 1400.0 * delta)

	move_and_slide()

	if is_on_ceiling() and velocity.y < 0.0:
		velocity.y = 0.0
	if is_on_floor() and velocity.y > 0.0:
		velocity.y = 0.0

	_wing_phase += delta * (8.0 + absf(velocity.x) * 0.02)
	if _use_sprite:
		_sprite.flip_h = facing < 0
		_sprite.speed_scale = 0.6 + clampf(absf(velocity.x) / SPEED, 0.0, 1.0) * 0.8
	else:
		queue_redraw()

	if can_move:
		EcosGameState.consume(EcosGameState.ENERGY_DRAIN_PER_SEC * delta)

	if global_position.y > death_y:
		global_position = spawn_point
		velocity = Vector2.ZERO
		take_damage(DAMAGE * 2.0, Vector2(0, -1))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("echolocation") and can_move:
		EcosAudio.play("echolocation", -8.0)
		echolocated.emit(global_position)

func take_damage(amount: float, from_dir: Vector2) -> void:
	if _iframes > 0.0:
		return
	_iframes = IFRAME_TIME
	EcosAudio.play("hit", -6.0)
	EcosGameState.damage(amount)
	EcosGameState.register_hit()
	_knockback = from_dir.normalized() * 260.0

func _on_hurt_body(body: Node2D) -> void:
	if body is EcosEnemy:
		take_damage(DAMAGE, global_position - body.global_position)

func _on_hurt_area(area: Area2D) -> void:
	if area.has_method("get_contact_damage"):
		take_damage(area.get_contact_damage(), global_position - area.global_position)

func _on_died() -> void:
	can_move = false
	velocity = Vector2.ZERO
	EcosAudio.play("defeat", -4.0)
	set_physics_process(false)

func _draw() -> void:
	if _use_sprite:
		return
	var flap := sin(_wing_phase) * 0.5 + 0.5
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))

	var body_color := Color(0.30, 0.20, 0.42)
	var wing_color := Color(0.22, 0.14, 0.32)
	var ear_color := Color(0.26, 0.17, 0.38)

	# Alas
	var wing_drop := 4.0 + flap * 10.0
	var left_wing := PackedVector2Array([
		Vector2(-4, -2), Vector2(-26, -6 - wing_drop),
		Vector2(-30, 6 - wing_drop * 0.4), Vector2(-6, 6),
	])
	var right_wing := PackedVector2Array([
		Vector2(4, -2), Vector2(26, -6 - wing_drop),
		Vector2(30, 6 - wing_drop * 0.4), Vector2(6, 6),
	])
	draw_colored_polygon(left_wing, wing_color)
	draw_colored_polygon(right_wing, wing_color)

	# Cuerpo
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.25))
	draw_circle(Vector2.ZERO, 11.0, body_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))

	# Orejas
	var left_ear := PackedVector2Array([
		Vector2(-9, -9), Vector2(-4, -22), Vector2(-1, -9),
	])
	var right_ear := PackedVector2Array([
		Vector2(9, -9), Vector2(4, -22), Vector2(1, -9),
	])
	draw_colored_polygon(left_ear, ear_color)
	draw_colored_polygon(right_ear, ear_color)

	# Ojos
	draw_circle(Vector2(-4, -2), 3.2, Color(1, 1, 1))
	draw_circle(Vector2(4, -2), 3.2, Color(1, 1, 1))
	draw_circle(Vector2(-3.4, -2), 1.6, Color(0.1, 0.05, 0.15))
	draw_circle(Vector2(4.6, -2), 1.6, Color(0.1, 0.05, 0.15))

	# Colmillos
	draw_line(Vector2(-2.5, 6), Vector2(-2.5, 9), Color(1, 1, 1), 1.0)
	draw_line(Vector2(2.5, 6), Vector2(2.5, 9), Color(1, 1, 1), 1.0)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
