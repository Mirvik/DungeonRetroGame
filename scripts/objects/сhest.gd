extends Node2D

@onready var anim = $AnimatedSprite2D

var is_interactive: bool = true
var rng = RandomNumberGenerator.new()

var amount: int = rng.randi_range(1, 3)
var roll_item: int = rng.randi_range(1, 3)
var item: String

func _ready() -> void:
	if roll_item == 1:
		item = "key"
	elif roll_item == 2:
		item = "coin"
	elif roll_item == 3:
		item = "bomb"
		
func _on_interact_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and is_interactive:
		body.set_nearby_interactive_object(self)


func _on_interact_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.set_nearby_interactive_object(null)

func interact(body: Node2D) -> void:
	
	if body.is_in_group("player"):
		is_interactive = false
		body.set_nearby_interactive_object(null)
		
		anim.play("opened")
		body.collect_collectibles(amount, item)
	
