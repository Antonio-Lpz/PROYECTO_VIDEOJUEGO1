extends Control
class_name EcosMenu
## Pantalla de inicio.

signal play_pressed()
signal level_select_pressed()
signal options_pressed()
signal quit_pressed()

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.11)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "Ecos de la Noche"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0.05, 0.1, 0.3))
	title.add_theme_constant_override("outline_size", 8)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 90)
	title.size = Vector2(1280, 90)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "El viaje de un pequeno murcielago en busca de su familia"
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.75, 0.9))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(0, 175)
	subtitle.size = Vector2(1280, 30)
	add_child(subtitle)

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(490, 280)
	vbox.size = Vector2(300, 360)
	vbox.add_theme_constant_override("separation", 18)
	add_child(vbox)

	_add_button(vbox, "Jugar", func() -> void: play_pressed.emit())
	_add_button(vbox, "Seleccionar nivel", func() -> void: level_select_pressed.emit())
	_add_button(vbox, "Opciones", func() -> void: options_pressed.emit())
	_add_button(vbox, "Salir", func() -> void: quit_pressed.emit())

	var footer := Label.new()
	footer.text = "Godot 4  |  Prototipo jugable vertical slice"
	footer.add_theme_font_size_override("font_size", 14)
	footer.add_theme_color_override("font_color", Color(0.5, 0.55, 0.7))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.position = Vector2(0, 675)
	footer.size = Vector2(1280, 24)
	add_child(footer)

func _add_button(parent: Node, text: String, action: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(300, 52)
	b.add_theme_font_size_override("font_size", 22)
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(func() -> void: EcosAudio.play("click", -12.0))
	b.pressed.connect(action)
	parent.add_child(b)
