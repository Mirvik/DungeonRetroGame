extends CharacterBody2D

var type

signal dead(enemy_instance)

var max_hearts: int = 3
var current_hearts: int

var contact_damage: int = 1
var contact_knockback_force: float = 75.0
var contact_knockback_duration: float = 0.2

var knockback_velocity: Vector2
var knockback_timer: float = 0.0

var speed := 75

enum EnemyState {
	MOVING,
	THROWING,
	DEAD
}

var state: EnemyState = EnemyState.MOVING

var direction := Vector2.ZERO

var last_direction_name: String
var player_direction_name: String

@export var bullet: PackedScene

@onready var anim := $AnimatedSprite2D
@onready var animP := $AnimationPlayer

@onready var random_timer := $RandomTimer
@onready var throwing_timer := $ThrowingTimer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.name = "Orc"
	
	current_hearts = max_hearts
	
	random_timer.start()
	_randomize_direction()

func _physics_process(delta: float) -> void:
	
	if state in [EnemyState.DEAD, EnemyState.THROWING]:
		return
	
	if _is_player_on_same_row_or_column(10) and throwing_timer.is_stopped():
		_throw()
		throwing_timer.start()

	if knockback_timer > 0:
		knockback_timer -= delta
		if knockback_timer <= 0:
			knockback_velocity = Vector2.ZERO
	
	velocity = direction * speed + knockback_velocity
	move_and_slide()



# Movement
func _randomize_direction() -> void:
	
	if state != EnemyState.MOVING:
		return
	
	var angle = randf_range(0, PI * 2)
	direction = Vector2(cos(angle), sin(angle)).normalized()
	
	if abs(direction.x) > abs(direction.y):
		last_direction_name = "right" if direction.x > 0 else "left"
	else:
		last_direction_name = "down" if direction.y > 0 else "up"
			
	_play_directional_animation("walk", last_direction_name)

func _is_player_on_same_row_or_column(tolerance: float = 1.0):
	
	var player_pos = get_parent().get_node("Player").global_position
	var is_same_x = abs(player_pos.x - global_position.x) <= tolerance
	var is_same_y = abs(player_pos.y - global_position.y) <= tolerance
	return is_same_x or is_same_y

func _get_player_direction_name(tolerance: float = 1.0) -> String:
	
	var player_pos = get_parent().get_node("Player").global_position
	var is_same_x = abs(player_pos.x - global_position.x) <= tolerance
	var is_same_y = abs(player_pos.y - global_position.y) <= tolerance
	
	if is_same_x: #Are in the same column
		if player_pos.y > global_position.y:
			return "down"
		else:
			return "up"
		
	else: #Are in the same row
		if player_pos.x > global_position.x:
			return "right"
		else:
			return "left"
		
func _throw():
	state = EnemyState.THROWING
	_reset_velocity()
	player_direction_name = _get_player_direction_name(10)
	_play_directional_animation("throw", player_direction_name)
	
func _launch_bullet():
	var b = bullet.instantiate()
	b.global_position = global_position
	
	match player_direction_name:
		"left":
			b.rotation = deg_to_rad(180)
		"right":
			b.rotation = deg_to_rad(0)
		"up":
			b.rotation = deg_to_rad(270)
		"down":
			b.rotation = deg_to_rad(90)
	
	get_parent().add_child(b)

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



func _on_random_timer_timeout() -> void:
	_randomize_direction()


func _play_directional_animation(base_name: String, direction_name: String):
	if direction_name in ["left", "right"]:
		animP.play(base_name + "_right")
		anim.flip_h = (direction_name == "left")
	else:
		animP.play(base_name + "_" + direction_name)
		anim.flip_h = false

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	
	if "throw" in anim_name:
		state = EnemyState.MOVING
		_launch_bullet()
		_play_directional_animation("walk", last_direction_name)
	
	elif anim_name == "death":
		queue_free()

func _on_contact_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(contact_damage)
		body.apply_knockback(global_position, contact_knockback_force, contact_knockback_duration)
