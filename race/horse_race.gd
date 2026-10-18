extends Node2D

var horses: Array[Node2D] = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not GameState.is_authority:
		printerr("how did we get here")
	for player: GameState.PlayerInfo in GameState.active_players():
		pass
			
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
