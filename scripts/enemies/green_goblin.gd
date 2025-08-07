extends CharacterBody2D

var max_hearts: int = 2
var current_hearts: int

var is_dead: bool = false
var is_stunned: bool = false

var knockback_velocity: Vector2
var knockback_timer: float = 0.0

var speed := 75
var direction := Vector2.ZERO

@onready var collision = $CollisionShape2D2
@onready var anim = $AnimatedSprite2D

@onready var random_timer = $RandomTimer
@onready var stun_timer = $StunTimer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_hearts = max_hearts
	anim.play("run")
	
	random_timer.start()
	_randomize_direction()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	
	if is_dead or is_stunned:
		return
	
	if knockback_timer > 0:
		knockback_timer -= delta
	elif knockback_timer <= 0:
		knockback_velocity = Vector2.ZERO
	
	velocity = direction * speed + knockback_velocity
	move_and_slide()

func blink():
	anim.visible = false
	await get_tree().create_timer(0.1).timeout
	anim.visible = true

func apply_knockback(source_position: Vector2, force: float, duration: float = 0.2):
	var direction = (global_position - source_position).normalized()
	knockback_velocity += direction * force
	knockback_timer = duration

func apply_stun():
	velocity = Vector2.ZERO
	is_stunned = true
	stun_timer.start()

func take_damage(amount: int) -> void:
	
	if is_dead:
		return
		
	current_hearts = max(current_hearts - amount, 0)
	
	if current_hearts == 0:
		die()
		return
	
	else:
		blink()

func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	anim.play("death")
	
	collision.disabled = true
	set_process(false)
	set_physics_process(false)


func _on_random_timer_timeout() -> void:
	_randomize_direction()

func _on_stun_timer_timeout() -> void:
	is_stunned = false

func _randomize_direction() -> void:
	var angle = randf_range(0, PI * 2)
	direction = Vector2(cos(angle), sin(angle)).normalized()
