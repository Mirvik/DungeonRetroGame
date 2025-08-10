extends CharacterBody2D

var type

signal dead(enemy_instance)

enum EnemyState { MOVING, DEAD }

var max_hearts := 3
var current_hearts := max_hearts

var contact_damage: int = 1
var contact_knockback_force: float = 75.0
var contact_knockback_duration: float = 0.2

var state := EnemyState.MOVING
var speed := 75
var direction := Vector2.ZERO

var knockback_velocity := Vector2.ZERO
var knockback_timer := 0.0

@onready var collision := $CollisionShape2D2
@onready var anim := $AnimatedSprite2D
@onready var random_timer := $RandomTimer

func _ready() -> void:
	self.name = "EnhancedGoblin"
	anim.play("run")
	random_timer.start()
	_randomize_direction()

func _physics_process(delta: float) -> void:
	if state in [EnemyState.DEAD]:
		return

	if knockback_timer > 0:
		knockback_timer -= delta
		if knockback_timer <= 0:
			knockback_velocity = Vector2.ZERO

	velocity = direction * speed + knockback_velocity
	move_and_slide()

func take_damage(amount: int) -> void:
	if state == EnemyState.DEAD:
		return

	current_hearts = max(current_hearts - amount, 0)

	if current_hearts == 0:
		die()
	else:
		_blink()

func die() -> void:
	state = EnemyState.DEAD
	_reset_velocity()
	anim.play("death")
	collision.queue_free()
	set_process(false)
	set_physics_process(false)
	
	emit_signal("dead", self)

func apply_knockback(source_pos: Vector2, force: float, duration: float = 0.2) -> void:
	var dir = (global_position - source_pos).normalized()
	knockback_velocity = dir * force
	knockback_timer = duration

func _blink() -> void:
	anim.modulate = Color(1, 1, 1, 0.5)
	await get_tree().create_timer(0.1).timeout
	anim.modulate = Color(1, 1, 1, 1)

func _reset_velocity() -> void:
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	knockback_timer = 0.0

func _randomize_direction() -> void:
	var angle = randf_range(0, PI * 2)
	direction = Vector2(cos(angle), sin(angle)).normalized()


func _on_random_timer_timeout() -> void:
	_randomize_direction()

func _on_contact_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(contact_damage)
		body.apply_knockback(global_position, contact_knockback_force, contact_knockback_duration)
