extends MarginContainer

var turns_remaining := 4
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(WebsocketConnector.new())
	if not GameState.current_player.role == GameState.Role.Player:
		%TurnCount.visible = false
		%TextureRect.visible = false
		%TrainingActions.visible = false
		%Title.text = "Sit back and wait. You have {0} money".format([GameState.current_player.player_stats.money])
	else:
		%TextureRect.texture.atlas = HorseDb.MainDb.horses[GameState.current_player.horse_info].sprite_sheet
		update_ui()
func update_ui() -> void:
	%SpeedBox/Label.text = "SPEED: {0}".format([GameState.current_player.player_stats.speed])
	%PowerBox/Label.text = "SPEED: {0}".format([GameState.current_player.player_stats.power])
	%TurnCount.text = "You have {0} turns remaining".format([turns_remaining])
	if turns_remaining == 0:
		%TrainingActions.visible = false
func _on_speed_button_pressed() -> void:
	WsMultiplayer.send_data({
		"type": "train_speed"
	})
	
func _on_power_button_pressed() -> void:
	WsMultiplayer.send_data({
		"type": "train_power"
	})
	pass # Replace with function body.
func on_data_message(ev: NetworkEvent) -> void:
	var payload: Dictionary = ev.payload
	match payload["type"]:
		"training_output":
			GameState.current_player.player_stats.speed = float(payload["speed"])
			GameState.current_player.player_stats.power = float(payload["power"])
			turns_remaining = int(payload["turns"])
			update_ui()
