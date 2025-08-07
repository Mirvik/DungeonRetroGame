extends CharacterBody2D

@onready var hud := $"../UI/HUD"
@onready var anim := $AnimatedSprite2D
@onready var animP := $AnimationPlayer
@onready var invulnerability_timer := $invulnerability_timer

var inventory = {
	"key": 0,
	"coin": 0,
	"bomb": 0
}

enum PlayerState {
	IDLE,
	MOVING,
	ATTACKING,
	INTERACTING,
	GETTING_ITEM,
	HURT,
	DEAD,
	FROZEN
}

var state: PlayerState = PlayerState.IDLE

var max_hearts: int = 6
var current_hearts: int = 6

var force: int = 100
var speed: int = 300
var last_direction: String = "down"
var nearby_interactive_object

var is_input_disabled: bool = false
var is_invulnerable: bool = false


var bow_unlocked: bool = false
var bombs_unlocked: bool = false

var num_health_upgrades: int = 0

func _ready() -> void:
	hud.update_player_health_bar(current_hearts, max_hearts)
	hud.update_collectable_counts(inventory)
	
func can_accept_input() -> bool:
	return state in [PlayerState.IDLE, PlayerState.MOVING]

func _physics_process(delta: float) -> void:
	

	if can_accept_input():
		get_input()
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		move_and_slide()
		
func _input(event: InputEvent) -> void:
	
	# If is capable
	if not can_accept_input():
		return
		
	if Input.is_action_pressed("attack"):
		state = PlayerState.ATTACKING
		velocity = Vector2.ZERO
		animP.play("attack_" + last_direction)
		
	if Input.is_action_pressed("interact") and nearby_interactive_object != null:
		state = PlayerState.INTERACTING
		velocity = Vector2.ZERO
		anim.play("interact_" + last_direction)
		
	if Input.is_action_pressed("take_damage"):
		#take_damage(1)
		
		if can_receive_health_upgrade():
			get_health_upgrade()

func get_input():
	#Movement
	var input_vector = Input.get_vector("left", "right", "up", "down")
	velocity = input_vector * speed
		
	
	if input_vector != Vector2.ZERO:
		if abs(input_vector.x) > abs(input_vector.y):
			
			if input_vector.x > 0:
				last_direction = "right"
				anim.flip_h = true
			else:
				last_direction = "left"
				anim.flip_h = false
		else:
			
			if input_vector.y > 0:
				last_direction = "down"
			else:
				last_direction = "up"
			anim.flip_h = false
			
		anim.play("walk_" + last_direction)
		state = PlayerState.MOVING
	else:
		anim.play("idle_" + last_direction)
		state = PlayerState.IDLE

		
func _on_animated_sprite_2d_animation_finished() -> void:
	if "attack" in anim.animation:
		state = PlayerState.IDLE
		
	elif "interact" in anim.animation:
		state = PlayerState.IDLE
		nearby_interactive_object.interact(self)
		
	elif anim.animation == "hurt":
		state = PlayerState.IDLE
		
	elif anim.animation == "get_item":
		state = PlayerState.IDLE
		$Label.visible = false

func freeze_player() -> void:
	state = PlayerState.FROZEN
	velocity = Vector2.ZERO
	anim.play("idle_" + last_direction)

func unfreeze_player() -> void:
	state = PlayerState.IDLE

func take_damage(amount: int) -> void:
	
	#Ignore damage
	if is_invulnerable or state == PlayerState.DEAD:
		return
		
	#take damage
	current_hearts = max(current_hearts - amount, 0)
	hud.update_player_health_bar(current_hearts, max_hearts)
	velocity = Vector2.ZERO
	
	# Death
	if current_hearts == 0:
		die()
		return
		
	# Get hurt
	else:
		state = PlayerState.HURT
		is_invulnerable = true
		anim.play("hurt")
		invulnerability_timer.start()
		
func die() -> void:
	state = PlayerState.DEAD
	print("YOU DIED!")

func _on_invulnerability_timer_timeout() -> void:
	is_invulnerable = false

func obtain_item(item: String) -> void:
	$Label.text = "the dungeon key"
	$Label.visible = true
	
	state = PlayerState.GETTING_ITEM
	velocity = Vector2.ZERO
	anim.play("get_item")

func collect_collectable(item: String, amount: int = 1) -> void:
	
	if item == "bomb" and not bombs_unlocked:
		unlock_bombs()
		
	if item in inventory:
		inventory[item] += amount
	
	hud.update_collectable_counts(inventory)
	
	$Label.text = "{amount} {item}".format({"amount": amount, "item": item})
	$Label.visible = true
	
	state = PlayerState.GETTING_ITEM
	velocity = Vector2.ZERO
	anim.play("get_item")

func can_receive_health_upgrade() -> bool:
	return num_health_upgrades < 2

func get_health_upgrade() -> void:
	num_health_upgrades += 1
	max_hearts += 2
	hud.expand_player_health_bar(num_health_upgrades)
	hud.update_player_health_bar(current_hearts, max_hearts)
	
	heal_to_max()

func heal_to_max() -> void:
	current_hearts = max_hearts
	hud.update_player_health_bar(current_hearts, max_hearts)

func unlock_bow() -> void:
	bow_unlocked = true
	hud.show_weapon_icon("bow")
	
	
func unlock_bombs() -> void:
	bombs_unlocked = true
	hud.show_weapon_icon("bomb")


func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		body.take_damage(1)
		body.apply_knockback(position, force)
		
