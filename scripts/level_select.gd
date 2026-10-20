extends Control
class_name EcosLevelSelect
## Seleccion de nivel: muestra los 10 niveles y bloquea los no desbloqueados.

signal level_chosen(index: int)
signal back_pressed()

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
	title.text = "Seleccionar nivel"
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 60)
	title.size = Vector2(1280, 60)
	add_child(title)

	var grid := GridContainer.new()
	grid.columns = 5
	grid.position = Vector2(140, 200)
	grid.size = Vector2(1000, 300)
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	add_child(grid)

	for i in range(1, EcosGameState.TOTAL_LEVELS + 1):
		var unlocked := i <= EcosGameState.unlocked_levels
		var b := Button.new()
		b.custom_minimum_size = Vector2(176, 110)
		b.add_theme_font_size_override("font_size", 20)
		b.disabled = not unlocked
		if unlocked:
			var best: int = int(EcosGameState.level_scores.get(i, 0))
			b.text = "%02d\n%s\n%s" % [i, EcosLevelData.LEVEL_NAMES[i - 1], ("- %d pts" % best) if best > 0 else ""]
		else:
			b.text = "%02d\nBLOQUEADO" % i
		var idx := i
		b.pressed.connect(func() -> void: level_chosen.emit(idx))
		grid.add_child(b)

	var back := Button.new()
	back.text = "Volver"
	back.custom_minimum_size = Vector2(240, 52)
	back.add_theme_font_size_override("font_size", 20)
	back.position = Vector2(520, 600)
	back.pressed.connect(func() -> void: back_pressed.emit())
	add_child(back)
