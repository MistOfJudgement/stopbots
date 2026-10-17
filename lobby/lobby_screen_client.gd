extends HBoxContainer


func on_data_message(message: NetworkEvent) -> void:
	if message.payload.get("type") == "start":
		GameState.goto_race()
	$ChatMenu.on_data_message(message)
