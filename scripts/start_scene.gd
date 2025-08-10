extends Node2D

@onready var player = $Player
@onready var camera = $Camera2D
@onready var ui = $UI
@onready var fade_sprite = $DeathFade

var fade_alpha := 0.0
var fading := false
var fading_in := false
var fade_speed := 0.8  # скорость затемнения (можно регулировать)

func _ready() -> void:
	camera.make_current()
	# Начинаем с чёрного экрана и постепенно проявляем сцену
	fade_alpha = 1.0
	fade_sprite.modulate.a = fade_alpha
	fade_sprite.visible = true
	fading_in = true

func _process(delta: float) -> void:
	if fading:
		player.freeze_player()
		player.z_index = 3
		fade_alpha += fade_speed * delta
		if fade_alpha >= 1.0:
			fade_alpha = 1.0
			fading = false
			var dungeon: String = "res://scenes/dungeon.tscn"
			get_tree().change_scene_to_file(dungeon)
		_update_fade_alpha()

	elif fading_in:
		player.freeze_player()
		player.z_index = 3
		fade_alpha -= fade_speed * delta
		if fade_alpha <= 0.0:
			fade_alpha = 0.0
			fading_in = false
			fade_sprite.visible = false
		_update_fade_alpha()

	else:
		player.unfreeze_player()
		player.z_index = 1
		if player.state == player.PlayerState.DEAD:
			start_fade()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("exit"):
		get_tree().quit()

func start_fade():
	if fading or fading_in:
		return # Already fading, ignore
	fading = true
	fade_alpha = 0.0
	fade_sprite.visible = true
	_update_fade_alpha()

func _update_fade_alpha():
	var col = fade_sprite.modulate
	col.a = fade_alpha
	fade_sprite.modulate = col


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		start_fade()
