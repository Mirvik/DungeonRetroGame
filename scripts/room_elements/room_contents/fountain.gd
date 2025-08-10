extends Area2D

var has_fountain_healed: bool = false

@onready var anim = $AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	anim.play("default")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and has_fountain_healed == false:
		body.heal_to_max()
		has_fountain_healed = true
