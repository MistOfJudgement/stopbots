extends HBoxContainer

@onready var player_list := $PlayerList

func _ready() -> void:
	# Bind to the global player list changed signal
	GameState.player_list_changed.connect(_refresh_player_ui)
	
	# Populate the list immediately on scene load
	_refresh_player_ui()

func _refresh_player_ui() -> void:
	# Clear existing labels safely
	for child in player_list.get_children():
		child.queue_free()
		
	# Rebuild UI dynamically from GlobalGameState's dictionary
	for id in GameState.players:
		var player_info = GameState.players[id]
		var name_label := Label.new()
		name_label.text = player_info.name
		player_list.add_child(name_label)


func _on_button_pressed() -> void:
	WsMultiplayer.send_data({
		"type": "start"
	})
	GameState.goto_race()


func _on_close_lobby_button_pressed() -> void:
	WsMultiplayer.socket.close()
