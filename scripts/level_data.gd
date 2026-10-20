extends RefCounted
class_name EcosLevelData
## Genera la definicion de cada uno de los 10 niveles (data-driven).
## Cada nivel devuelve un Dictionary con plataformas, enemigos, objetos, etc.

const GROUND_Y := 560.0
const WORLD_H := 720.0

const LEVEL_NAMES := [
	"El comienzo",
	"Sendero oscuro",
	"El bosque profundo",
	"Entrada a la cueva",
	"La guarida del buho",
	"Caverna olvidada",
	"Ecos profundos",
	"El camino perdido",
	"La ultima caverna",
	"El reencuentro",
]

static func get_level(index: int) -> Dictionary:
	var i := clampi(index, 1, LEVEL_NAMES.size())
	var rng := RandomNumberGenerator.new()
	rng.seed = i * 1000 + 7

	var theme := _theme_for(i)
	var darkness := _darkness_for(i)
	var width := _width_for(i)

	var level := {
		"index": i,
		"name": LEVEL_NAMES[i - 1],
		"theme": theme,
		"darkness": darkness,
		"width": width,
		"height": WORLD_H,
		"spawn": Vector2(140, 420),
		"death_y": WORLD_H + 260.0,
		"goal": Vector2(width - 150.0, GROUND_Y - 90.0),
		"is_final": i == 10,
		"platforms": [] as Array,
		"collectibles": [] as Array,
		"enemies": [] as Array,
		"hazards": [] as Array,
	}

	_build_terrain(level, rng, theme)
	_populate(level, rng, i, theme)
	return level

static func _theme_for(i: int) -> String:
	match i:
		4, 6, 7, 9:
			return "cave"
		5, 8:
			return "mixed"
		10:
			return "refuge"
		_:
			return "forest"

static func _darkness_for(i: int) -> float:
	match i:
		4:
			return 0.78
		6:
			return 0.82
		7:
			return 0.92
		9:
			return 0.85
		5:
			return 0.35
		8:
			return 0.45
		_:
			return 0.18

static func _width_for(i: int) -> float:
	match i:
		1:
			return 2600.0
		2:
			return 3200.0
		3:
			return 4300.0
		4:
			return 3600.0
		5:
			return 4000.0
		6:
			return 4700.0
		7:
			return 4300.0
		8:
			return 4500.0
		9:
			return 5000.0
		10:
			return 2300.0
		_:
			return 3000.0

# --- Terreno ---

static func _build_terrain(level: Dictionary, rng: RandomNumberGenerator, theme: String) -> void:
	var width: float = level["width"]
	var platforms: Array = level["platforms"]
	var is_cave := theme == "cave" or theme == "mixed"

	# Suelo solido al inicio y al final
	platforms.append(Rect2(0, GROUND_Y, 520, 200))
	platforms.append(Rect2(width - 520, GROUND_Y, 520, 200))

	var x := 520.0
	while x < width - 520.0:
		var seg_w := rng.randf_range(300.0, 620.0)
		if x + seg_w > width - 520.0:
			seg_w = width - 520.0 - x
		if seg_w > 60.0:
			platforms.append(Rect2(x, GROUND_Y, seg_w, 200))
		x += seg_w
		var gap := rng.randf_range(130.0, 210.0)
		x += gap

	# Plataformas flotantes (rutas alternativas / objetos elevados)
	var count := int(width / 500.0)
	for n in count:
		var px := rng.randf_range(500.0, width - 500.0)
		var py := rng.randf_range(250.0, GROUND_Y - 120.0)
		var pw := rng.randf_range(120.0, 260.0)
		platforms.append(Rect2(px, py, pw, 26))

	if is_cave:
		# Techo de la cueva con estalactitas (representado por plataformas arriba)
		var cx := 0.0
		while cx < width:
			var cw := rng.randf_range(300.0, 700.0)
			platforms.append(Rect2(cx, -80.0, cw, 140))
			cx += cw + rng.randf_range(120.0, 260.0)

# --- Contenido (objetos, enemigos, peligros) ---

static func _populate(level: Dictionary, rng: RandomNumberGenerator, i: int, theme: String) -> void:
	var width: float = level["width"]
	var collectibles: Array = level["collectibles"]
	var enemies: Array = level["enemies"]
	var hazards: Array = level["hazards"]
	var is_cave := theme == "cave" or theme == "mixed"

	# Objetos recolectables distribuidos por todo el nivel
	var obj_count := int(width / 260.0) + 6
	for n in obj_count:
		var px := rng.randf_range(320.0, width - 260.0)
		var py := rng.randf_range(150.0, GROUND_Y - 60.0)
		var kind := "fruit"
		var roll := rng.randf()
		if roll < 0.4:
			kind = "fruit"
		elif roll < 0.7:
			kind = "bug_small"
		elif roll < 0.9:
			kind = "bug_medium"
		else:
			kind = "bug_special"
		collectibles.append({"pos": Vector2(px, py), "type": kind})

	# Enemigos, cantidad creciente con el numero de nivel
	var enemy_count := 1 + int(i * 0.9)
	for n in enemy_count:
		var px := rng.randf_range(600.0, width - 400.0)
		var kind := "spider"
		var roll := rng.randf()
		if is_cave:
			if roll < 0.45:
				kind = "spider"
			elif roll < 0.85:
				kind = "owl"
			else:
				kind = "snake"
		else:
			if roll < 0.5:
				kind = "spider"
			elif roll < 0.8:
				kind = "owl"
			else:
				kind = "snake"
		var py := GROUND_Y - 30.0
		if kind == "owl":
			py = rng.randf_range(200.0, GROUND_Y - 160.0)
		enemies.append({"pos": Vector2(px, py), "kind": kind})

	# Jefes
	if i == 5:
		enemies.append({"pos": Vector2(width - 900.0, 300.0), "kind": "boss_owl"})
	if i == 9:
		enemies.append({"pos": Vector2(width - 1100.0, 320.0), "kind": "cave_guardian"})

	# Peligros
	var hazard_count := 2 + int(i * 0.7)
	for n in hazard_count:
		var px := rng.randf_range(700.0, width - 350.0)
		var kind := "spikes"
		var roll := rng.randf()
		if is_cave:
			if roll < 0.4:
				kind = "spikes"
			elif roll < 0.7:
				kind = "web"
			else:
				kind = "falling_rock"
		else:
			kind = "thorns" if roll < 0.5 else "spikes"
		var py := GROUND_Y - 14.0
		var move := 0.0
		if kind == "web":
			py = rng.randf_range(260.0, GROUND_Y - 160.0)
		elif kind == "falling_rock":
			py = rng.randf_range(220.0, 420.0)
			move = 90.0
		hazards.append({"pos": Vector2(px, py), "kind": kind, "move": move})
