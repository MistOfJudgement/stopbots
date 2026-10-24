extends CanvasLayer

@onready var connection_status := %status
@onready var state_status := %state
func _ready() -> void:
	add_child(WebsocketConnector.new())
	
func on_connect() -> void:
	connection_status.text = "connected"

func on_disconnect() -> void:
	connection_status.text = "disconnected"

func _process(_delta: float) -> void:
	state_status.text = str(GameState.current_game_state) + " " + str(GameState.current_player.role)
	
func on_data_message(event: NetworkEvent) -> void:
	var log_label := Label.new()
	log_label.text = str(event.payload)
	%VBoxContainer.add_child(log_label)
func on_system_message(type: String, data: Dictionary) -> void:
	var log_label := Label.new()
	log_label.text = str(type, " ", data)
	%VBoxContainer.add_child(log_label)
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_0 and event.is_pressed():
			$Panel.visible = not $Panel.visible


func _on_state_sync_pressed() -> void:
	GameState.request_transition(GameState.current_game_state)
