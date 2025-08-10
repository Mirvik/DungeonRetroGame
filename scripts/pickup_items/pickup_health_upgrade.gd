extends Node2D


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		
		if body.can_collect_health_upgrade():
			body.collect_health_upgrade()
			queue_free()
		else:
			return
