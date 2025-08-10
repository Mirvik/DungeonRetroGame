extends Area2D

var is_broken: bool = false

@onready var anim = $AnimatedSprite2D
@onready var collision = $StaticBody2D/CollisionShape2D

func _ready() -> void:
	anim.play("intact")
	
func destroy() -> void:
	anim.play("broken")
	z_index = 0
	collision.disabled = true
