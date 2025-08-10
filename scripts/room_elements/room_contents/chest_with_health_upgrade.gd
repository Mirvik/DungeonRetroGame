extends Node2D

@onready var anim = $AnimatedSprite2D

var is_interactive: bool = true
		
func _on_interact_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and is_interactive:
		body.set_nearby_interactive_object(self)


func _on_interact_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.set_nearby_interactive_object(null)

func interact(body: Node2D) -> void:
	
	if body.is_in_group("player"):
		is_interactive = false
		body.set_nearby_interactive_object(null)
		
		anim.play("opened")
		if body.can_collect_health_upgrade():
			body.collect_health_upgrade()
	
