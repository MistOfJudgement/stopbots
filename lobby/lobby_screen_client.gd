extends VBoxContainer

var remaining_horses: Array = []
@onready var button_container: HorseButtonContainer = $HorseButtonContainer
func _ready() -> void:
	$Name.text = GameState.current_player.name
	$RoomID.text = GameState.room
	
	for horse_i in len(HorseDb.MainDb.horses):
		remaining_horses.append(horse_i)
	GameState.player_list_changed.connect(refresh_ui)
	refresh_ui()
func refresh_ui() -> void:
	toggle_buttons(GameState.current_player.role != GameState.Role.Player)
	for i in range(button_container.loaded_buttons.size()):
		button_container.loaded_buttons[i].set_disabled(not (i in remaining_horses))
	if GameState.current_player.role == GameState.Role.Player:
		$HorseLabel.text = HorseDb.MainDb.horses[GameState.current_player.horse_info].full_name
	else:
		$HorseLabel.text = ""
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

func toggle_buttons(set_spectator: bool) -> void:
	$HBoxContainer/TrainerSelect.disabled = not set_spectator
	$HBoxContainer/SpectatorSelect.disabled = set_spectator
func on_horse_button_pressed(horse_i: int) -> void:
	WsMultiplayer.send_data({
		"type": "set_horse",
		"horse": horse_i
	})

func _on_quit_pressed() -> void:
	WsMultiplayer.socket.close()
	pass # Replace with function body.


func _on_trainer_select_pressed() -> void:
	#GameState.current_player.role = GameState.Role.Player
	#toggle_buttons(false)
	WsMultiplayer.send_data({
		"type": "set_role",
		"role": GameState.Role.Player
	})


func _on_spectator_select_pressed() -> void:
	#GameState.current_player.role = GameState.Role.Spectator
	#toggle_buttons(true)
	WsMultiplayer.send_data({
		"type": "set_role",
		"role": GameState.Role.Spectator
	})


func _on_horse_button_container_on_horse_button_pressed(i: int) -> void:
	on_horse_button_pressed(i)
