extends Node2D

var player
var is_interactive: bool = true


func _on_interact_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and is_interactive:
		body.nearby_interactive_object = self


func _on_interact_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.nearby_interactive_object = null

func interact(body: Node2D) -> void:
	
	player = body
	
	is_interactive = false
	player.nearby_interactive_object = null
	player.freeze_player()
	
	$AnimatedSprite2D.play("opening")
	
func _on_animated_sprite_2d_animation_finished() -> void:
	
	if $AnimatedSprite2D.animation == "opening":
		player.collect_collectable("bomb", 2)
		$AnimatedSprite2D.play("opened")
