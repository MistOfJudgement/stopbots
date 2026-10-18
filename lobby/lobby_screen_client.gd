extends VBoxContainer

func _ready() -> void:
	$Name.text = GameState.player_name
	$RoomID.text = GameState.room
func on_data_message(message: NetworkEvent) -> void:
	if message.payload.get("type") == "start":
		GameState.goto_race()
	$ChatMenu.on_data_message(message)


func _on_quit_pressed() -> void:
	WsMultiplayer.socket.close()
	pass # Replace with function body.
