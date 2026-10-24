extends HBoxContainer

@onready var player_list := $PlayerList

func _ready() -> void:
	# Bind to the global player list changed signal
	GameState.player_list_changed.connect(_refresh_player_ui)
	
	# Populate the list immediately on scene load
	_refresh_player_ui()
	$MainControls/RoomID.text = GameState.room
	gen_qr(get_url())
func get_url() -> String:
	if OS.has_feature('web'):
		# Listen for incoming messages from JavaScript
		var loc :String= JavaScriptBridge.eval('''
			document.location.href;
		''')

		# Check if map data was successfully retrieved
		return loc
	return ""
func gen_qr(tex: String) -> void:
	var qr_code: QrCode = QrCode.new()

	# choose the level of error correction (LOW, MEDIUM, QUARTILE, HIGH)
	qr_code.error_correct_level = QrCode.ErrorCorrectionLevel.LOW

	var texture: ImageTexture = qr_code.get_texture(tex) # Add your text here

	var qr_code_image := $MainControls/TextureRect
	qr_code_image.texture = texture

	qr_code.queue_free() # clean up to avoid leaks
func _refresh_player_ui() -> void:
	# Clear existing labels safely
	for child in player_list.get_children():
		child.queue_free()
		
	# Rebuild UI dynamically from GlobalGameState's dictionary
	for id in GameState.players:
		var player_info := GameState.players[id]
		player_info.player_stats = PlayerStats.new()
		var name_label := Label.new()
		name_label.text = player_info.name + "(" + ("Player" if player_info.role == GameState.Role.Player else "Spectator") + ")"
		if player_info.role == GameState.Role.Player:
			name_label.text += HorseDb.MainDb.horses[player_info.horse_info].full_name
		player_list.add_child(name_label)


func _on_button_pressed() -> void:
	if GameState.active_players().is_empty():
		return
	WsMultiplayer.send_data({
		"type": "start"
	})
	GameState.goto_race()


func _on_close_lobby_button_pressed() -> void:
	WsMultiplayer.socket.close()
