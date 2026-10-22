extends VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(WebsocketConnector.new())
	$TextureRect.texture.atlas = HorseDb.MainDb.horses[GameState.current_player.horse_info].sprite_sheet
	update_ui()
func update_ui() -> void:
	$HBoxContainer/SpeedBox/Label.text = "SPEED: {}".format(GameState.current_player.player_stats.speed)
	$HBoxContainer/PowerBox/Label.text = "SPEED: {}".format(GameState.current_player.player_stats.power)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_speed_button_pressed() -> void:
	WsMultiplayer.send_data({
		"type": "train_speed"
	})
	
func on_data_message(ev: NetworkEvent) -> void:
	var payload :Dictionary= ev.payload
	match payload["type"]:
		"train_speed_output":
			GameState.current_player.player_stats.speed += float(payload["speed"])
			update_ui()
