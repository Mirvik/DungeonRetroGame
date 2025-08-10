extends CharacterBody2D

var type

signal dead(enemy_instance)

var max_hearts: int = 5
var current_hearts: int

var contact_damage: int = 2
var contact_knockback_force: float = 75.0
var contact_knockback_duration: float = 0.2

var knockback_velocity: Vector2
var knockback_timer: float = 0.0

var speed := 75

enum EnemyState {
	MOVING,
	DEAD,
	STUNNED
}

var state = EnemyState.MOVING

var last_direction_name: String = "up"

@onready var anim := $AnimatedSprite2D
@onready var animP := $AnimationPlayer

var player: CharacterBody2D

func _ready() -> void:
	self.name = "Knight"
	
	current_hearts = max_hearts
	
	player = get_tree().get_nodes_in_group("player")[0]

func _physics_process(delta: float) -> void:
	if state in [EnemyState.DEAD, EnemyState.STUNNED]:
		return
	
	if knockback_timer > 0:
		knockback_timer -= delta
		if knockback_timer <= 0:
			knockback_velocity = Vector2.ZERO
	
	if player:
		# Направление от врага к игроку
		var direction = (player.global_position - global_position).normalized()
		
		# Двигаем врага к игроку
		velocity = direction * speed + knockback_velocity
		move_and_slide()
		
		last_direction_name = _get_direction_name(direction)
		_play_directional_animation("walk", last_direction_name)
		

func _blink():
	anim.modulate = Color(1, 1, 1, 0.5)
	await get_tree().create_timer(0.1).timeout
	anim.modulate = Color(1, 1, 1, 1)

func apply_knockback(source_position: Vector2, force: float, duration: float = 0.2):
	var dir = (global_position - source_position).normalized()
	knockback_velocity += dir * force
	knockback_timer = duration

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
	animP.play("death")
	
	emit_signal("dead", self)

func _reset_velocity() -> void:
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	knockback_timer = 0.0
	

func _get_direction_name(direction: Vector2) -> StringName:
	if direction != Vector2.ZERO:
		if abs(direction.x) > abs(direction.y):
				
			if direction.x > 0:
				return "right"
			else:
				return "left"
		else:
				
			if direction.y > 0:
				return "down"
			else:
				return "up"
	
	return last_direction_name

func _play_directional_animation(base_name: String, direction_name: String):
	if direction_name in ["left", "right"]:
		animP.play(base_name + "_right")
		anim.flip_h = (direction_name == "left")
	else:
		animP.play(base_name + "_" + direction_name)
		anim.flip_h = false

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "death":
		queue_free()

func _on_contact_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(contact_damage)
		body.apply_knockback(global_position, contact_knockback_force, contact_knockback_duration)
