extends Node2D


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.collect_collectable("key", 1)
		queue_free()
