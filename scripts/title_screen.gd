extends Node2D

@onready var start_button = $StartButton
@onready var animP = $AnimationPlayer
@onready var audio_stream_player = $AudioStreamPlayer2D
func _ready() -> void:
	animP.play("logo_animation")

func _input(event: InputEvent) -> void:
	
	if event.is_action_pressed("exit"):
		get_tree().quit()
	
	if event.is_pressed():
		start_button.play("pressed")
		start_game()
		
func start_game():
	get_tree().change_scene_to_file("res://scenes/start_scene.tscn")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "logo_animation":
		start_button.play("press_any_key")


func _on_audio_stream_player_2d_finished() -> void:
	start_button.play("off")
	animP.play("logo_animation")
	audio_stream_player.play()
