extends Node2D
## Orquestador principal: menu, juego, pausa, victoria, derrota y guardado.

enum State { MENU, SELECT, OPTIONS, PLAYING, PAUSED, GAMEOVER, VICTORY }

var _state: int = State.MENU
var _world: Node2D
var _ui: CanvasLayer
var _hud: EcosHud
var _screen: Control
var _level: EcosLevel
var _current_index := 1
var _last_winning_score := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_world = Node2D.new()
	_world.name = "World"
	_world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_world)

	_ui = CanvasLayer.new()
	_ui.layer = 20
	add_child(_ui)

	EcosGameState.died.connect(_on_energy_depleted)
	EcosAudio.play_music("music")
	show_menu()

# --- Navegacion de pantallas ---

func _clear_screen() -> void:
	if _screen != null and is_instance_valid(_screen):
		if _screen.get_parent() == _ui:
			_ui.remove_child(_screen)
		_screen.queue_free()
	_screen = null

func _clear_world() -> void:
	if _hud != null and is_instance_valid(_hud):
		if _hud.get_parent() == _ui:
			_ui.remove_child(_hud)
		_hud.queue_free()
	_hud = null
	_level = null
	for c in _world.get_children():
		_world.remove_child(c)
		c.queue_free()

func show_menu() -> void:
	get_tree().paused = false
	_state = State.MENU
	_clear_world()
	_clear_screen()
	var menu := EcosMenu.new()
	menu.play_pressed.connect(_on_play)
	menu.level_select_pressed.connect(_on_select)
	menu.options_pressed.connect(_on_options)
	menu.quit_pressed.connect(_on_quit)
	_screen = menu
	_ui.add_child(menu)

func _on_play() -> void:
	var start := clampi(EcosGameState.current_level, 1, EcosGameState.TOTAL_LEVELS)
	start_level(start)

func _on_select() -> void:
	_state = State.SELECT
	_clear_screen()
	var sel := EcosLevelSelect.new()
	sel.level_chosen.connect(_on_level_chosen)
	sel.back_pressed.connect(show_menu)
	_screen = sel
	_ui.add_child(sel)

func _on_level_chosen(index: int) -> void:
	start_level(index)

func _on_options() -> void:
	_state = State.OPTIONS
	_clear_screen()
	_screen = _build_options()
	_ui.add_child(_screen)

func _build_options() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.11)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	var title := _make_label("Opciones y controles", 40, Vector2(0, 60), 1280)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var body := _make_label(
		"A / <-  moverse a la izquierda\n"
		+ "D / ->  moverse a la derecha\n"
		+ "W / ^   subir / volar\n"
		+ "S / v   bajar\n"
		+ "E       ecolocalizacion / interactuar\n"
		+ "R       reiniciar nivel\n"
		+ "ESC     pausa\n",
		22, Vector2(360, 160), 700)
	root.add_child(body)

	var del := Button.new()
	del.text = "Borrar progreso guardado"
	del.custom_minimum_size = Vector2(320, 52)
	del.add_theme_font_size_override("font_size", 20)
	del.position = Vector2(480, 470)
	del.pressed.connect(_on_delete_save)
	root.add_child(del)

	var back := Button.new()
	back.text = "Volver"
	back.custom_minimum_size = Vector2(320, 52)
	back.add_theme_font_size_override("font_size", 20)
	back.position = Vector2(480, 540)
	back.pressed.connect(show_menu)
	root.add_child(back)
	return root

func _on_delete_save() -> void:
	EcosGameState.delete_save()

func _on_quit() -> void:
	get_tree().quit()

# --- Juego ---

func start_level(index: int) -> void:
	get_tree().paused = false
	_state = State.PLAYING
	_clear_world()
	_clear_screen()
	_current_index = index

	_level = EcosLevel.new()
	_level.index = index
	_level.level_completed.connect(_on_level_completed)
	_level.player_died.connect(_on_player_died)
	_world.add_child(_level)

	_hud = EcosHud.new()
	_ui.add_child(_hud)

	EcosAudio.play("start", -8.0)

func _on_level_completed() -> void:
	EcosGameState.complete_level()
	_last_winning_score = EcosGameState.score
	var is_final := _current_index >= EcosGameState.TOTAL_LEVELS
	if is_final:
		_state = State.VICTORY
		_show_final_victory()
	else:
		_state = State.VICTORY
		_show_level_victory()

func _on_player_died() -> void:
	pass

func _on_energy_depleted() -> void:
	if _state != State.PLAYING:
		return
	_state = State.GAMEOVER
	_show_game_over()

func _show_level_victory() -> void:
	get_tree().paused = true
	_clear_screen()
	_screen = _build_overlay(
		"Nivel completado",
		"Puntos: %d\nFrutas: %d   Bichos: %d" % [EcosGameState.score, EcosGameState.fruits, EcosGameState.bugs],
		[
			["Siguiente nivel", func() -> void: start_level(mini(_current_index + 1, EcosGameState.TOTAL_LEVELS))],
			["Repetir", func() -> void: start_level(_current_index)],
			["Menu principal", func() -> void: show_menu()],
		])
	_ui.add_child(_screen)

func _show_final_victory() -> void:
	get_tree().paused = true
	_clear_screen()
	_screen = _build_overlay(
		"El reencuentro",
		"Tras atravesar la ultima caverna, el pequeno murcielago\n"
		+ "encuentra a su familia al amanecer.\n\n"
		+ "Puntuacion final: %d" % EcosGameState.score,
		[
			["Repetir nivel", func() -> void: start_level(_current_index)],
			["Menu principal", func() -> void: show_menu()],
		])
	_ui.add_child(_screen)

func _show_game_over() -> void:
	get_tree().paused = true
	_clear_screen()
	_screen = _build_overlay(
		"Sin energia",
		"El murcielago no pudo continuar.\nNivel %02d - %s" % [_current_index, EcosLevelData.LEVEL_NAMES[_current_index - 1]],
		[
			["Reintentar", func() -> void: start_level(_current_index)],
			["Menu principal", func() -> void: show_menu()],
		])
	_ui.add_child(_screen)

func _show_pause() -> void:
	_state = State.PAUSED
	get_tree().paused = true
	_clear_screen()
	_screen = _build_overlay(
		"Pausa",
		"Nivel %02d - %s" % [_current_index, EcosLevelData.LEVEL_NAMES[_current_index - 1]],
		[
			["Continuar", _resume],
			["Reiniciar nivel", func() -> void: start_level(_current_index)],
			["Menu principal", func() -> void: show_menu()],
		])
	_ui.add_child(_screen)

func _resume() -> void:
	get_tree().paused = false
	_state = State.PLAYING
	_clear_screen()

# --- Entrada global ---

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if _state == State.PLAYING:
			_show_pause()
			get_viewport().set_input_as_handled()
		elif _state == State.PAUSED:
			_resume()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("restart") and _state == State.PLAYING:
		start_level(_current_index)
		get_viewport().set_input_as_handled()

# --- Constructores de UI ---

func _build_overlay(title: String, message: String, buttons: Array) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.process_mode = Node.PROCESS_MODE_ALWAYS

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.06, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var panel := ColorRect.new()
	panel.color = Color(0.08, 0.09, 0.16, 0.95)
	panel.position = Vector2(340, 150)
	panel.size = Vector2(600, 420)
	root.add_child(panel)

	var t := _make_label(title, 42, Vector2(340, 180), 600)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	root.add_child(t)

	var m := _make_label(message, 20, Vector2(360, 250), 560)
	m.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(m)

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(490, 380)
	vbox.size = Vector2(300, 300)
	vbox.add_theme_constant_override("separation", 14)
	root.add_child(vbox)

	for entry in buttons:
		var b := Button.new()
		b.text = entry[0]
		b.custom_minimum_size = Vector2(300, 50)
		b.add_theme_font_size_override("font_size", 20)
		b.pressed.connect(entry[1])
		vbox.add_child(b)
	return root

func _make_label(text: String, size: int, pos: Vector2, width: float) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = Vector2(width, 200)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.92, 0.94, 1.0))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 4)
	return l
