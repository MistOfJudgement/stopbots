extends Node2D

@export var horse_template:= preload("res://race/horse.tscn")
var horses: Array[Node2D] = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not GameState.is_authority:
		printerr("how did we get here")
	for player: GameState.PlayerInfo in GameState.active_players():
		var tmp :Node2D= horse_template.instantiate()
		var offset :Vector2 = Vector2(randf_range(-10, 10), randf_range(-10, 10))
		tmp.global_position = $Spawn.global_position + offset
		add_child(tmp)
		horses.append(tmp)
		print(player.name)
			
	pass # Replace with function body.
	WsMultiplayer.send_data({
		"type": "announce_racers",
		"timeout": Time.get_unix_time_from_system() + 10,
		"players": GameState.active_players().map(
			func(e: GameState.PlayerInfo): return {
				"player_id": e.connection_id,
				"player_name": e.name,
			})
	})

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_timer_timeout() -> void:
	#remove starting gate
	pass


func _on_end_race_button_pressed() -> void:
	GameState.goto_train()


func _on_win_race_button_pressed() -> void:
	GameState.goto_win()
