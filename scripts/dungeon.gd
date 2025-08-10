extends Node2D

# === Константы ===
const STATE_OPENED = "opened"
const STATE_LOCKED = "locked"
const STATE_SOLID = "solid"
const STATE_CRACKED = "cracked"

const ROOM_NORMAL = "normal"
const ROOM_FOUNTAIN = "fountain"

const OBJ_FOUNTAIN = 0
const OBJ_CHEST = 1
const OBJ_POT = 2
const OBJ_CHEST_WITH_BOW = 3

# === Данные подземелья ===
var dungeon_data = {
	"width": 5,
	"height": 6,
	"special_rooms": {
		"boss": { "x": 4, "y": 5 },
		"key": { "x": 1, "y": 3 },
		"bow": { "x": 2, "y": 4 }
	},
	"rooms": {}
}

var room_example = {
	"id": "2_0",                         # строка "x_y" для уникального ID комнаты
	"coords": {"x": 2, "y": 0},           # координаты комнаты в подземелье
	"border": 1,                          # индекс бордюра (из borders_arr)
	"floor": 1,                           # индекс текстуры пола (из floors_arr)
	"type": "fountain",                   # тип комнаты: normal / fountain / chest_room и т.д.
	"doors": [
		{"type": "opened", "dir": "down", "state": "opened"},
		{"type": "locked", "dir": "left", "state": "locked"}
	],
	"enemies": [
		{"type": 0, "x": -120, "y": 50},    # враг с индексом 0 (из enemies_arr) и координатами в комнате
		{"type": 2, "x": 80, "y": -40}
	],
	"is_danger_room": true,               # логический флаг — опасная ли комната
	"objects": [
		{"type": 0, "x": 0, "y": 0, "has_fountain_healed": false}, # фонтан
		{"type": 1, "x": 50, "y": 30, "opened": false},            # сундук
		{"type": 2, "x": -60, "y": -20, "broken": false}           # горшок
	],
	"visited": false                      # заходил ли игрок в эту комнату
}

var current_coords = Vector2(2, 0)
var entered_from_door = {"type": 0, "dir": "down", "state": STATE_OPENED}

# === Игровые узлы ===
@onready var player = $Player
@onready var camera = $Camera2D
@onready var ui = $UI
@onready var audio_stream_player = $AudioStreamPlayer2D

# === Ресурсы ===
var borders_arr = [
	preload("res://prefabs/room_elements/border/border1.tscn"),
	preload("res://prefabs/room_elements/border/fountain_room_border.tscn")
]
var floors_arr = [
	preload("res://art/room_elements/floor/FirstRoomFloor.png"),
	preload("res://art/room_elements/floor/FountainRoomFloor.png"),
	preload("res://art/room_elements/floor/Floor1.png"),
	preload("res://art/room_elements/floor/Floor2.png"),
	preload("res://art/room_elements/floor/Floor3.png"),
	preload("res://art/room_elements/floor/Floor4.png"),
	preload("res://art/room_elements/floor/Floor5.png"),
	preload("res://art/room_elements/floor/Floor6.png"),
	preload("res://art/room_elements/floor/Floor7.png"),
	preload("res://art/room_elements/floor/Floor8.png"),
	preload("res://art/room_elements/floor/Floor9.png")
]
var doors_prefabs = [
	preload("res://prefabs/room_elements/door/entrance_door.tscn"),
	preload("res://prefabs/room_elements/door/door_opened.tscn"),
	preload("res://prefabs/room_elements/door/door_locked.tscn"),
	preload("res://prefabs/room_elements/wall/weak_wall.tscn")
]

var wall_prefab = preload("res://prefabs/room_elements/wall/strong_wall.tscn")
var objects_arr = [
	preload("res://prefabs/room_elements/room_contents/fountain.tscn"),
	preload("res://prefabs/room_elements/room_contents/chest.tscn"),
	preload("res://prefabs/room_elements/room_contents/pot.tscn"),
	preload("res://prefabs/room_elements/room_contents/chest_with_bow.tscn"),
	preload("res://prefabs/room_elements/room_contents/chest_with_health_upgrade.tscn")
]

var enemies_prefabs = [
	preload("res://prefabs/enemies/goblin.tscn"),
	preload("res://prefabs/enemies/enhanced_goblin.tscn"),
	preload("res://prefabs/enemies/orc.tscn"),
	preload("res://prefabs/enemies/enhanced_orc.tscn"),
	preload("res://prefabs/enemies/knight.tscn"),
	preload("res://prefabs/enemies/enhanced_knight.tscn"),
	preload("res://prefabs/enemies/living_bomb.tscn")
]

# === Прочее ===
var rng = RandomNumberGenerator.new()
var directions_arr = ["up", "right", "down", "left"]
var scale_factor = 2.5

@onready var fade_sprite = $DeathFade
var fade_alpha := 0.0
var fading := false
var fading_in := false
var fade_speed := 0.8  # скорость затемнения (можно регулировать)

func _ready() -> void:
	
	# Начинаем с чёрного экрана и постепенно проявляем сцену
	fade_alpha = 1.0
	fade_sprite.modulate.a = fade_alpha
	fade_sprite.visible = true
	fading_in = true

	camera.make_current()
	_generate_first_room()
	load_room(Vector2(2, 0), Vector2(0, 90))

func _process(delta: float) -> void:
	if fading:
		player.freeze_player()
		player.z_index = 3
		fade_alpha += fade_speed * delta
		if fade_alpha >= 1.0:
			fade_alpha = 1.0
			fading = false
			var start_scene: String = "res://scenes/start_scene.tscn"
			get_tree().change_scene_to_file(start_scene)
		_update_fade_alpha()

	elif fading_in:
		player.freeze_player()
		player.z_index = 3
		fade_alpha -= fade_speed * delta
		if fade_alpha <= 0.0:
			fade_alpha = 0.0
			fading_in = false
			fade_sprite.visible = false
		_update_fade_alpha()

	else:
		player.unfreeze_player()
		player.z_index = 1
		if player.state == player.PlayerState.DEAD:
			start_fade()

func start_fade():
	if fading or fading_in:
		return # Already fading, ignore
	fading = true
	fade_alpha = 0.0
	fade_sprite.visible = true
	_update_fade_alpha()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("exit"):
		get_tree().quit()
	
	if event.is_action_pressed("restart"):
		get_tree().change_scene_to_file("res://scenes/dungeon.tscn")

func _update_fade_alpha():
	var col = fade_sprite.modulate
	col.a = fade_alpha
	fade_sprite.modulate = col


func set_entered_from_door(new_dir: String, new_type: int, new_state: String) -> void:
	entered_from_door = {"type": new_type, "dir": new_dir, "state": new_state}

# === Генерация комнаты ===
func _generate_first_room():
	var id = "2_0"
	var coords = Vector2(2, 0)
	
	var border = 0  # первый бордюр из массива
	var floor = 0   # первая текстура пола
	
	var type_room = "normal"
	
	# Дверь, из которой игрок "вошёл" в комнату (стартовая, поэтому вниз открыта)
	var doors = [
		{"type": 0, "dir": "down", "state": "opened"}
	]
	
	var number_doors = 4  # всего дверей в комнате
	
	# Случайно перемешаем направления
	var available_dirs = ["up", "right", "down", "left"]
	available_dirs.erase("down")  # дверь вниз уже добавлена, убираем чтобы не дублировать
	
	available_dirs.shuffle()
	
	for i in range(number_doors - 1):  # -1 потому что дверь вниз уже есть
		var dir = available_dirs[i]
		
		# Случайный тип двери из doors_arr, кроме "down"
		var door_type = _random_door_type()
		var state = ""
		match door_type:
			1:
				state = "opened"
			2:
				state = "locked"
			3:
				state = "solid"
		
		doors.append({"type": door_type, "dir": dir, "state": state})

	
	var enemies = []
	var is_danger_room = false
	var objects = []
	var visited = true
	
	add_room(
		id,
		ROOM_NORMAL,
		border,
		floor,
		doors,
		enemies,
		enemies.size() > 4,
		objects,
		true
	)

func generate_room():
	var id = "%d_%d" % [current_coords.x, current_coords.y]

	# Если комната с таким id уже есть, то не генерируем заново
	if dungeon_data["rooms"].has(id):
		return  # Комната уже есть — ничего не делаем

	var roll = rng.randf()

	if roll < 0.2:
		_add_fountain_room(id)
	else:
		_add_normal_room(id)
	print(dungeon_data["rooms"][id])

# === Типы комнат ===
func _add_fountain_room(id: String):
	var doors = _generate_doors()
	add_room(
		id,
		ROOM_FOUNTAIN,
		1,
		1,
		doors,
		[],
		false,
		[{"type": OBJ_FOUNTAIN, "x": 0, "y": 0, "has_fountain_healed": false}],
		false
	)

func _add_normal_room(id: String):
	var doors = _generate_doors()
	var enemies = _generate_enemies()
	var objects = _generate_objects()
	add_room(
		id,
		ROOM_NORMAL,
		0,
		rng.randi_range(2, floors_arr.size() - 1),
		doors,
		enemies,
		enemies.size() > 4,
		objects,
		false
	)

# === Генерация элементов ===
func _generate_doors() -> Array:
	var doors = []
	# Дверь, из которой пришёл игрок
	doors.append(
		{
			"type": entered_from_door["type"], 
			"dir": opposite_dir(entered_from_door["dir"]), 
			"state": STATE_CRACKED if entered_from_door["type"] == 3 else STATE_OPENED
		}
	)

	var number_doors = rng.randi_range(1, 4)
	directions_arr.shuffle()
	for dir in directions_arr:
		if doors[0]["dir"] == dir: continue
		if _is_border_blocked(dir): continue

		var door_type = _random_door_type()
		var door_state = _door_state_by_type(door_type)
		doors.append({"type": door_type, "dir": dir, "state": door_state})

		if doors.size() >= number_doors: break
	return doors

func _generate_enemies() -> Array:
	var enemies = []
	var count = rng.randi_range(0, 4)
	for i in count:
		var pos = _random_point()
		enemies.append({"type": rng.randi_range(0, enemies_prefabs.size() - 1), "x": pos.x, "y": pos.y})
	return enemies

func _generate_objects() -> Array:
	var objs = []
	var count = rng.randi_range(0, 3)
	for i in count:
		var pos = _random_point()
		var type_obj = rng.randi_range(1, 4)
		var props = {"x": pos.x, "y": pos.y}
		if type_obj == OBJ_CHEST or type_obj == OBJ_CHEST_WITH_BOW:
			props["opened"] = false
		elif type_obj == OBJ_POT:
			props["broken"] = false
		var obj = {"type": type_obj}
		for key in props.keys():
			obj[key] = props[key]
		objs.append(obj)
	return objs


# === Добавление комнаты ===
func add_room(id: String, type_room: String, border: int, floor: int, doors: Array, enemies: Array, is_danger: bool, objects: Array, is_visited: bool):
	dungeon_data["rooms"][id] = {
		"id": id,
		"coords": current_coords,
		"border": border,
		"floor": floor,
		"type": type_room,
		"doors": doors,
		"enemies": enemies,
		"is_danger_room": is_danger,
		"objects": objects,
		"visited": is_visited
	}

# === Утилиты ===
func opposite_dir(dir: String) -> String:
	match dir:
		"up": return "down"
		"down": return "up"
		"left": return "right"
		"right": return "left"
		_: return "blablabla"

func _is_border_blocked(dir: String) -> bool:
	return (
		dir == "up" and current_coords.y == dungeon_data["height"] - 1
		or dir == "down" and current_coords.y == 0
		or dir == "left" and current_coords.x == 0
		or dir == "right" and current_coords.x == dungeon_data["width"] - 1
	)


func _random_door_type() -> int:
	var idx = rng.randi_range(1, 3)
	return idx

func _door_state_by_type(door_type: int) -> String:
	match door_type:
		1: return STATE_OPENED
		2: return STATE_LOCKED
		3: return STATE_SOLID
		_: return STATE_OPENED

func _random_point() -> Vector2:
	return Vector2(rng.randf_range(-180, 180), rng.randf_range(-80, 80))

func _clear_scene_except():
	var exclude_names = ["player", "camera2d", "ui", "deathfade", "audiostreamplayer2d"]
	for child in get_tree().current_scene.get_children():
		if child.name.to_lower() not in exclude_names:
			child.queue_free()

func load_room(room_coords: Vector2, player_coords: Vector2):
	_clear_scene_except()
	player.global_position = player_coords
	
	var id = "%d_%d" % [int(room_coords.x), int(room_coords.y)]
	var room = dungeon_data["rooms"][id]
	if room != null:
		
		load_room_visuals(room["border"], room["floor"])
		load_room_doors(room["doors"])
		load_room_objects(room["objects"])
		load_room_enemies(room["enemies"])
	

func load_room_visuals(border_index: int, floor_index: int = 0) -> void:
	# Загружаем бордер (берём первый из массива borders)
	var room_border = borders_arr[border_index].instantiate()
	room_border.global_position = Vector2.ZERO
	room_border.scale = Vector2(scale_factor, scale_factor)
	add_child(room_border)
	
	# Загружаем пол (floor) по индексу floor_index из floors
	var floor_sprite = Sprite2D.new()
	floor_sprite.texture = floors_arr[floor_index]
	floor_sprite.global_position = Vector2.ZERO
	floor_sprite.scale = Vector2(scale_factor, scale_factor)
	floor_sprite.z_index = -1  # чтобы пол был ниже бордера и прочего
	add_child(floor_sprite)

func load_room_doors(doors_data: Array):
	var door_dirs = []
	for door_info in doors_data:
		var index = door_info["type"]  # индекс двери (0 — открытая, 1 — закрытая и т.п.)
		var dir = door_info["dir"]         # направление: "up", "right", "down", "left"
		var state = door_info["state"]  # состояние двери
		
		
		door_dirs.append(dir)

		var door_instance = doors_prefabs[index].instantiate()

		var door_positions = {
			"up": Vector2(0, -159.8),
			"right": Vector2(260.3, 0),
			"down": Vector2(0, 160.5),
			"left": Vector2(-259.8, 0)
		}
		var door_angles = {
			"up": 0,
			"right": 90,
			"down": 180,
			"left": 270
		}
		
		door_instance.set_dir(dir)
		door_instance.global_position = door_positions[dir]
		door_instance.rotation_degrees = door_angles[dir]
		
		door_instance.scale = Vector2(scale_factor, scale_factor)
		add_child(door_instance)
		
		if state == "opened" and door_instance.has_method("open_door"):
			door_instance.open_door()
		elif state == "locked" and door_instance.has_method("lock_door"):
			door_instance.lock_door()
		elif state == "solid" and door_instance.has_method("reset_wall"):
			door_instance.reset_wall()
		elif state == "cracked" and door_instance.has_method("crack_wall"):
			door_instance.crack_wall()

	# Теперь для направлений, в которых нет двери, ставим стены
	var all_dirs = ["up", "right", "down", "left"]
	var wall_positions = {
		"up": Vector2(0, -159.8),
		"right": Vector2(260.3, 0),
		"down": Vector2(0, 160.5),
		"left": Vector2(-259.8, 0)
	}
	var wall_angles = {
		"up": 0,
		"right": 90,
		"down": 180,
		"left": 270
	}
	for dir in all_dirs:
		if dir in door_dirs:
			continue  # дверь уже есть, пропускаем
		
		# Создаём стену на месте отсутствующей двери
		var wall_instance = wall_prefab.instantiate()
		wall_instance.global_position = wall_positions[dir]
		wall_instance.rotation_degrees = wall_angles[dir]
		wall_instance.scale = Vector2(scale_factor, scale_factor)
		add_child(wall_instance)

func load_room_objects(objects_data: Array):
	for object_info in objects_data:
		var index = object_info.get("type", "")
		var pos_x = object_info.get("x", 0)
		var pos_y = object_info.get("y", 0)
			
		var object_scene : PackedScene = objects_arr[index]
			
		if object_scene != null:
			var object_instance = object_scene.instantiate()
			object_instance.global_position = Vector2(pos_x, pos_y)
			object_instance.scale = Vector2(scale_factor, scale_factor)
			add_child(object_instance)


func load_room_enemies(enemies_data: Array):
	for enemy_info in enemies_data:
		var index = enemy_info.get("type", "")
		var pos_x = enemy_info.get("x", 0)
		var pos_y = enemy_info.get("y", 0)
			
		var enemy_scene : PackedScene = enemies_prefabs[index]
			
		if enemy_scene != null:
			var enemy_instance = enemy_scene.instantiate()
			enemy_instance.global_position = Vector2(pos_x, pos_y)
			enemy_instance.scale = Vector2(scale_factor, scale_factor)
			add_child(enemy_instance)
			
			enemy_instance.type = index
			enemy_instance.connect("dead", Callable(self, "_on_enemy_dead"))

func _on_audio_stream_player_2d_finished() -> void:
	audio_stream_player.play()

func _on_enemy_dead(enemy_instance):
	var id = "%d_%d" % [int(current_coords.x), int(current_coords.y)]
	var room = dungeon_data["rooms"].get(id, null)
	if room == null:
		return

	var enemies = room["enemies"]
	var enemy_type = enemy_instance.get("type") if enemy_instance.has_method("get") else null
	# Если у врага нет свойства type, можно попробовать достать иначе,
	# или заменить на подходящее получение типа врага из instance

	# Проходим по списку врагов и удаляем первого с совпадающим типом
	for i in range(enemies.size()):
		if enemies[i]["type"] == enemy_type:
			enemies.remove_at(i)
			break
