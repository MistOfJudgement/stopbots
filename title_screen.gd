extends VBoxContainer

@onready var roomInput := $HBoxContainer/RoomIDInput
@onready var password := $HBoxContainer/PasswordInput2
@onready var nameInput: LineEdit = $HBoxContainer/NameInput

func _ready() -> void:
	if OS.has_feature("speed"):
		roomInput.text = "Test"
		nameInput.text = "TestClient" + str(randi() % 50)
		_on_join_room_button_pressed()
func _on_join_room_button_pressed() -> void:
	if roomInput.text == "": return
	GameState.current_player.name = "Player_{}".format(randi_range(1, 999)) if nameInput.text.is_empty() else nameInput.text
	WsMultiplayer.connect_to_server(roomInput.text)


# 1. Triggered when the socket successfully connects
func on_connect() -> void:
	# Uses the clean typed helper we set up in WebsocketMultiplayer
	WsMultiplayer.send_authenticate(password.text)

# 2. Handles non-game messages like auth success, errors, and joins
func on_system_message(type: String, data: Dictionary) -> void:
	match type:
		"authenticated":
			print("Successfully authenticated as: ", data.get("role"))
			GameState.set_authority((data.get("role")))
			GameState.room = roomInput.text
			if GameState.is_authority:
				GameState.goto_lobby()
			else:
				GameState.sync_state()

		"error":
			push_error("Auth/Server error: " + data.get("message", "/error"))
		_:
			print("System event [%s]: " % type, data)
