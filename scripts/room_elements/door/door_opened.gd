extends StaticBody2D

@onready var dungeon = get_node("/root/Dungeon")

@onready var anim = $AnimatedSprite2D
@onready var enter_blocker = $EnterBlocker

var dir: String
var door_type: int = 1
var door_state: String = "opened"

var is_transitioning = false


func _ready() -> void:
	self.name = "Door opened"
	anim.play("opened")  # Показываем открытую дверь
	enter_blocker.disabled = true  # Проход открыт

func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation == "opening":
		anim.play("opened")
		enter_blocker.disabled = true
		
	elif anim.animation == "closing":
		anim.play("closed")


func _on_next_room_trigger_body_entered(body: Node2D) -> void:
	if is_transitioning:
		return
	
	if body.is_in_group("player"):
		var player_pos = body.global_position
		var dist = global_position.distance_to(player_pos)
		if dist < 48: # расстояние в пикселях
			
			
			is_transitioning = true
				
			var player_coords = Vector2.ZERO
				
			dungeon.set_entered_from_door(dir, door_type, door_state)
				
			# Обновляем координаты текущей комнаты в зависимости от направления двери
			match dir:
				"up":
					dungeon.current_coords.y += 1
					player_coords = Vector2(0, 50)  # Позиция игрока у нижней части комнаты (заходит сверху)
				"down":
					dungeon.current_coords.y -= 1
					player_coords = Vector2(0, -50) # Позиция игрока у верхней части комнаты (заходит снизу)
				"left":
					dungeon.current_coords.x -= 1
					player_coords = Vector2(180, 0) # Позиция игрока справа (заходит слева)
				"right":
					dungeon.current_coords.x += 1
					player_coords = Vector2(-180, 0) # Позиция игрока слева (заходит справа)
				
			# Генерируем комнату, если нет
			dungeon.generate_room()
			dungeon.load_room(dungeon.current_coords, player_coords)

	
func open_door():
	anim.play("opening")

func lock_door():
	anim.play("closing")
	enter_blocker.disabled = false

func set_dir(new_dir):
	dir = new_dir
