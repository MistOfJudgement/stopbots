extends VBoxContainer

var horse_button := preload("res://lobby/horse_button.tscn")
func _ready() -> void:
	$Name.text = GameState.player_name
	$RoomID.text = GameState.room
	for horse_i in len(HorseDb.MainDb.horses):
		var tmp :HorseButton= horse_button.instantiate()
		tmp.set_horse(horse_i)
		$HorseButtonContainer.add_child(tmp)
func on_data_message(message: NetworkEvent) -> void:
	match message.payload.get("type"):
		"start":
			GameState.goto_race()
		"update_horse_list":
			pass
	$ChatMenu.on_data_message(message)


func _on_quit_pressed() -> void:
	WsMultiplayer.socket.close()
	pass # Replace with function body.


func _on_trainer_select_pressed() -> void:
	GameState.role = GameState.Role.Player
	$HBoxContainer/TrainerSelect.disabled = true
	$HBoxContainer/SpectatorSelect.disabled = false
	WsMultiplayer.send_data({
		"type": "set_role",
		"role": GameState.role
	})


func _on_spectator_select_pressed() -> void:
	GameState.role = GameState.Role.Spectator
	$HBoxContainer/TrainerSelect.disabled = false
	$HBoxContainer/SpectatorSelect.disabled = true
	WsMultiplayer.send_data({
		"type": "set_role",
		"role": GameState.role
	})
