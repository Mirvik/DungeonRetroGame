extends StaticBody2D


@onready var dungeon = get_node("/root/Dungeon")

@onready var anim = $AnimatedSprite2D
@onready var enter_blocker = $EnterBlocker

var dir: String
var door_type: int = 2
var door_state: String = "opened"

var is_transitioning = false

func _ready() -> void:
	self.name = "Door locked"
	anim.play("locked")  # Показываем открытую дверь
	enter_blocker.disabled = true  # Проход открыт

func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation == "opening":
		anim.play("opened")
		enter_blocker.disabled = true
	
	elif anim.animation == "locking":
		anim.play("locked")


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


func _on_interact_trigger_body_entered(body: Node2D) -> void:
	if anim.animation == "locked" and body.is_in_group("player"):
		body.set_nearby_interactive_object(self)
		
func _on_interact_trigger_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.set_nearby_interactive_object(null)

func interact(body: Node2D):
	if body.can_spend_collectibles(1, "key"):
		body.spend_collectibles(1, "key")
		open_door()
	
func open_door():
	anim.play("opening")

func lock_door():
	anim.play("locking")
	enter_blocker.disabled = false

func set_dir(new_dir):
	dir = new_dir
