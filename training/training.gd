extends HFlowContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(WebsocketConnector.new())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_end_training_pressed() -> void:
	GameState.goto_race()
	pass # Replace with function body.
