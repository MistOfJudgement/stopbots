extends HFlowContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(WebsocketConnector.new())

func _on_end_training_pressed() -> void:
	GameState.goto_race()
	pass # Replace with function body.
