extends Area2D

var damage: int = 1
var speed: float = 200.0

var knockback_force: float = 75.0
var knockback_duration: float = 0.2

func _physics_process(delta: float) -> void:
	position += transform.x * speed * delta

func _on_area_entered(area: Area2D) -> void:
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		body.take_damage(damage)
		body.apply_knockback(position, knockback_force, knockback_duration)
		queue_free()
