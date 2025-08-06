extends Panel


#Textures and icons for UI
var z_icon := preload("res://art/ui/ZIcon.png")
var x_icon_1 := preload("res://art/ui/XIcon1.png")
var x_icon_2 := preload("res://art/ui/XIcon2.png")
var c_icon_1 := preload("res://art/ui/CIcon1.png")
var c_icon_2 := preload("res://art/ui/CIcon2.png")

var player_bar_1_texture := preload("res://art/ui/PlayerBar1.png")
var player_bar_2_texture := preload("res://art/ui/PlayerBar2.png")
var player_bar_3_texture := preload("res://art/ui/PlayerBar3.png")

var player_full_heart_texture := preload("res://art/ui/PlayerHeart.png")
var player_half_heart_texture := preload("res://art/ui/PlayerHalfHeart.png")
var player_no_heart_texture := preload("res://art/ui/PlayerNoHeart.png")

@onready var attack_slot := $HBox/WeaponSlots/AttackSlot
@onready var bow_slot := $HBox/WeaponSlots/BowSlot
@onready var bomb_slot := $HBox/WeaponSlots/BombSlot

func show_weapon_icon(weapon: String):
	if weapon == "bow":
		bow_slot.texture = x_icon_2
	elif weapon == "bomb":
		bomb_slot.texture = c_icon_2

func update_health_bar(current_hearts: int) -> void:
	
	var hearts: int = current_hearts
	
	for n in range(1, 4):
		var heart_path = "HBox/HealthBars/PlayerBarContainer/HealthBar/heart_%d" % n
		var heart_node = get_node(heart_path)
		
		if (hearts >= 2):
			heart_node.texture = player_full_heart_texture
		elif (hearts == 1):
			heart_node.texture = player_half_heart_texture
		else:
			heart_node.texture = player_no_heart_texture
		
		hearts -= 2

func update_collectable_counts(inventory: Dictionary) -> void:
	get_node("HBox/CollectableCounts/KeyAmount").text = str(inventory["key"])
	get_node("HBox/CollectableCounts/CoinAmount").text = str(inventory["coin"])
	get_node("HBox/CollectableCounts/BombAmount").text = str(inventory["bomb"])
