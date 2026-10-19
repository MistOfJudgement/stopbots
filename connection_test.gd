extends CanvasLayer

@onready var connection_status := $VBoxContainer/Label
@onready var state_status := $VBoxContainer/Label2
func _ready() -> void:
	add_child(WebsocketConnector.new())
	
func on_connect():
	connection_status.text = "connected"

func on_disconnect():
	connection_status.text = "disconnected"

func _process(delta: float) -> void:
	state_status.text = str(GameState.current_game_state) + " " + str(GameState.role)
