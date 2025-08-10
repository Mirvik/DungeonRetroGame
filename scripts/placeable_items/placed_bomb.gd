extends Area2D

var damage: int = 3
var explosion_knockback_force: float = 150.0
var explosion_knockback_duration = 0.3

@onready var anim := $AnimatedSprite2D
@onready var collision := $CollisionShape2D
@onready var explode_timer := $EplodeTimer

func _ready() -> void:
	anim.play("ticking")
	collision.disabled = true
	explode_timer.start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_eplode_timer_timeout() -> void:
	anim.play("explosion")
	collision.disabled = false

func _on_body_entered(body: Node2D) -> void:
	
	if body.is_in_group("player"):
		body.take_damage(damage)
		body.apply_knockback(global_position, explosion_knockback_force, explosion_knockback_duration)
		
	elif body.is_in_group("enemies"):
		body.take_damage(damage)
		body.apply_knockback(global_position, explosion_knockback_force, explosion_knockback_duration)
	
	elif body.is_in_group("weak_wall"):
		body.crack_wall()

func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation == "explosion":
		queue_free()
