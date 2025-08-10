extends CharacterBody2D

@export var bullet: PackedScene
@export var placed_bomb: PackedScene

@onready var hud := $"../UI/HUD"
@onready var anim := $AnimatedSprite2D
@onready var animP := $AnimationPlayer
@onready var invulnerability_timer := $invulnerability_timer

var inventory = {
	"key": 1,
	"coin": 0,
	"bomb": 0
}

enum PlayerState {
	IDLE,
	MOVING,
	ATTACKING,
	SHOOTING,
	PLANTINT_BOMB,
	INTERACTING,
	GETTING_ITEM,
	HURT,
	DEAD,
	FROZEN
}

var state: PlayerState = PlayerState.IDLE

var max_hearts: int = 6
var current_hearts: int = 6

var knockback_force: float = 75.0
var knockback_duration: float = 0.2
var speed: float = 200.0

var last_direction_name: String = "down"
var nearby_interact_object

var is_input_disabled: bool = false
var is_invulnerable: bool = false


var bow_unlocked: bool = false
var bombs_unlocked: bool = false

var num_health_upgrades: int = 0

var knockback_velocity := Vector2.ZERO
var knockback_timer: float = 0.0

#Base
func can_accept_input() -> bool:
	return state in [PlayerState.IDLE, PlayerState.MOVING]

func _ready() -> void:
	hud.update_player_health_bar(current_hearts, max_hearts)
	hud.update_collectible_counts(inventory)

func _physics_process(delta: float) -> void:
	
	if knockback_timer > 0:
		knockback_timer -= delta
		if knockback_timer <= 0:
			knockback_velocity = Vector2.ZERO

	if can_accept_input():
		get_input()
		move_and_slide()
	else:
		_reset_velocity()
		move_and_slide()
		
func _input(event: InputEvent) -> void:
	
	# If is not capable
	if not can_accept_input():
		return
		
	if Input.is_action_pressed("attack"):
		_attack()
	
	if Input.is_action_pressed("shoot") and bow_unlocked:
		_shoot()
	
	if Input.is_action_pressed("plant_bomb") and inventory["bomb"] > 0:
		_plant_bomb()
		
	if Input.is_action_pressed("interact") and nearby_interact_object != null:
		_interact()
	
	if Input.is_action_pressed("take_damage"):
		take_damage(1)

func get_input():
	
	#Movement
	var input_vector = Input.get_vector("left", "right", "up", "down")
	velocity = input_vector * speed + knockback_velocity
		
	
	if input_vector != Vector2.ZERO:
		if abs(input_vector.x) > abs(input_vector.y):
			
			if input_vector.x > 0:
				last_direction_name = "right"
				anim.flip_h = true
			else:
				last_direction_name = "left"
				anim.flip_h = false
		else:
			
			if input_vector.y > 0:
				last_direction_name = "down"
			else:
				last_direction_name = "up"
			anim.flip_h = false
			
		state = PlayerState.MOVING
		animP.play("walk_" + last_direction_name)
	else:
		state = PlayerState.IDLE
		animP.play("idle_" + last_direction_name)



#Actions
func _attack():
	state = PlayerState.ATTACKING
	_reset_velocity()
	animP.play("attack_" + last_direction_name)

func _shoot():
	state = PlayerState.SHOOTING
	_reset_velocity()
	animP.play("shoot_" + last_direction_name)

func _plant_bomb():
	state = PlayerState.PLANTINT_BOMB
	_reset_velocity()
	animP.play("plant_" + last_direction_name)

func _interact():
	state = PlayerState.INTERACTING
	_reset_velocity()
	animP.play("interact_" + last_direction_name)



# Signals
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name.begins_with("attack"):
		state = PlayerState.IDLE
	
	elif anim_name.begins_with("shoot"):
		state = PlayerState.IDLE
		_launch_bullet()
	
	elif anim_name.begins_with("plant"):
		state = PlayerState.IDLE
		_set_bomb()
		spend_collectibles(1, "bomb")
	
	elif anim_name.begins_with("interact"):
		state = PlayerState.IDLE
		if nearby_interact_object:
			nearby_interact_object.interact(self)
		
	elif anim_name == "hurt":
		state = PlayerState.IDLE
		
	elif anim_name == "get_item":
		state = PlayerState.IDLE
		$Label.visible = false
		
func _on_invulnerability_timer_timeout() -> void:
	is_invulnerable = false
	
func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		body.take_damage(1)
		body.apply_knockback(position, knockback_force, knockback_duration)

func _on_attack_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("breakable_objects"):
		area.destroy()


func _launch_bullet():
	var b = bullet.instantiate()
	get_tree().root.add_child(b)
	b.global_position = global_position
		
	match last_direction_name:
		"left":
			b.rotation = deg_to_rad(180)
		"right":
			b.rotation = deg_to_rad(0)
		"up":
			b.rotation = deg_to_rad(270)
		"down":
			b.rotation = deg_to_rad(90)

func _set_bomb():
	var bomb = placed_bomb.instantiate()
	bomb.global_position = global_position
	get_tree().root.add_child(bomb)

# Freeze * Unfreeze
func freeze_player() -> void:
	set_physics_process(false)

func unfreeze_player() -> void:
	set_physics_process(true)

func apply_knockback(source_position: Vector2, force: float, duration: float = 0.2):
	var dir = (global_position - source_position).normalized()
	knockback_velocity += dir * force
	knockback_timer = duration

# Health func
func take_damage(amount: int) -> void:
	
	#Ignore damage
	if is_invulnerable or state == PlayerState.DEAD:
		return
		
	#take damage
	current_hearts = max(current_hearts - amount, 0)
	hud.update_player_health_bar(current_hearts, max_hearts)
	_reset_velocity()
	
	# Death
	if current_hearts == 0:
		die()
		
	# Get hurt
	else:
		_get_hurt()

func _get_hurt():
	is_invulnerable = true
	invulnerability_timer.start()
	
	while is_invulnerable:
		anim.modulate = Color(1, 1, 1, 0.5)
		await get_tree().create_timer(0.1).timeout
		anim.modulate = Color(1, 1, 1, 1)
		await get_tree().create_timer(0.1).timeout
		
	anim.modulate = Color(1, 1, 1, 1)

func die() -> void:
	state = PlayerState.DEAD
	animP.play("death")
	
func heal_to_max() -> void:
	current_hearts = max_hearts
	hud.update_player_health_bar(current_hearts, max_hearts)


func set_nearby_interactive_object(object) -> void:
	nearby_interact_object = object

func can_collect_health_upgrade() -> bool:
	return num_health_upgrades < 2

# Collect & get
func obtain_item(item: String) -> void:
	$Label.text = item
	$Label.visible = true
	
	state = PlayerState.GETTING_ITEM
	_reset_velocity()
	animP.play("get_item")

func collect_collectibles(amount: int = 1, type: String = "coin") -> void:
	
	if not inventory.has(type):
		return
	
	if type == "bomb" and not bombs_unlocked:
		unlock_bombs()
	
	inventory[type] += amount
	hud.update_collectible_counts(inventory)
	
	$Label.text = "{amount} {type}".format({"amount": amount, "type": type})
	$Label.visible = true
	
	state = PlayerState.GETTING_ITEM
	_reset_velocity()
	animP.play("get_item")

func can_spend_collectibles(amount: int, type: String) -> bool:
	if inventory.has(type):
		
		return inventory[type] - amount >= 0
	else:
		return false
		
func spend_collectibles(amount: int, type: String):
	
	if inventory[type]:
		inventory[type] -= amount
		hud.update_collectible_counts(inventory)

func collect_health_upgrade() -> void:
	num_health_upgrades += 1
	max_hearts += 2
	hud.expand_player_health_bar(num_health_upgrades)
	hud.update_player_health_bar(current_hearts, max_hearts)
	
	heal_to_max()
	
	$Label.text = "Health Upgrade"
	$Label.visible = true
	
	state = PlayerState.GETTING_ITEM
	_reset_velocity()
	animP.play("get_item")

func get_bow():
	$Label.text = "Bow"
	$Label.visible = true
	
	state = PlayerState.GETTING_ITEM
	_reset_velocity()
	animP.play("get_item")
	
	unlock_bow()

func _reset_velocity() -> void:
	velocity = Vector2.ZERO

# Unlock func
func unlock_bow() -> void:
	bow_unlocked = true
	hud.show_weapon_icon("bow")
	
	
func unlock_bombs() -> void:
	bombs_unlocked = true
	hud.show_weapon_icon("bomb")
