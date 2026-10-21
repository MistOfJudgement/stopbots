extends VBoxContainer

var horse_button := preload("res://lobby/horse_button.tscn")
var loaded_buttons: Array[HorseButton] = []
var remaining_horses: Array = []
func _ready() -> void:
	$Name.text = GameState.current_player.name
	$RoomID.text = GameState.room
	for horse_i in len(HorseDb.MainDb.horses):
		var tmp: HorseButton = horse_button.instantiate()
		tmp.set_horse(horse_i)
		tmp.set_disabled(false)
		tmp.on_press.connect(on_horse_button_pressed)
		loaded_buttons.append(tmp)
		$HorseButtonContainer.add_child(tmp)
		remaining_horses.append(horse_i)
	GameState.player_list_changed.connect(refresh_ui)
	refresh_ui()
func refresh_ui() -> void:
	for i in range(loaded_buttons.size()):
		loaded_buttons[i].set_disabled(not (i in remaining_horses))
	if GameState.current_player.role == GameState.Role.Player:
		$HorseLabel.text = HorseDb.MainDb.horses[GameState.current_player.horse_info].full_name
func on_data_message(message: NetworkEvent) -> void:
	var payload: Dictionary = message.payload
	match payload.get("type"):
		"start":
			GameState.goto_race()
		"update_remaining_horses":
			var remaining: Array = payload["remaining"]
			remaining_horses = remaining.map(func(e: float) -> int: return int(e))
			refresh_ui()
			
	$ChatMenu.on_data_message(message)


func on_horse_button_pressed(horse_i: int) -> void:
	WsMultiplayer.send_data({
		"type": "set_horse",
		"horse": horse_i
	})

func _on_quit_pressed() -> void:
	WsMultiplayer.socket.close()
	pass # Replace with function body.


func _on_trainer_select_pressed() -> void:
	GameState.current_player.role = GameState.Role.Player
	$HBoxContainer/TrainerSelect.disabled = true
	$HBoxContainer/SpectatorSelect.disabled = false
	WsMultiplayer.send_data({
		"type": "set_role",
		"role": GameState.current_player.role
	})


func _on_spectator_select_pressed() -> void:
	GameState.current_player.role = GameState.Role.Spectator
	$HBoxContainer/TrainerSelect.disabled = false
	$HBoxContainer/SpectatorSelect.disabled = true
	WsMultiplayer.send_data({
		"type": "set_role",
		"role": GameState.current_player.role
	})
