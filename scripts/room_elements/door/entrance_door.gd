extends StaticBody2D

var dir: String
@onready var dungeon = get_node("/root/Dungeon")

@onready var anim = $AnimatedSprite2D
@onready var enter_blocker = $EnterBlocker

func _ready() -> void:
	enter_blocker.disabled = false
	self.name = "Entrance door"
	anim.play("closed")
	
func _on_next_room_trigger_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		dungeon.start_fade()


func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation == "opening":
		anim.play("opened")
		enter_blocker.disabled = true
		
	elif anim.animation == "closing":
		anim.play("closed") 


func open_door():
	anim.play("opening")

func close_door():
	anim.play("closing")
	enter_blocker.disabled = false

func set_dir(new_dir):
	pass
