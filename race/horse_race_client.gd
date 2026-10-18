extends VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(WebsocketConnector.new())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func load_racer(players: Array[Dictionary]):
	for p in players:
		var temp:= Button.new()
		temp.text = p["player_name"]
		$HFlowContainer.add_child(temp)
func on_data_message(message: NetworkEvent):
	var payload: Dictionary = message.payload
	match payload["type"]:
		"announce_racers":
			load_racer(payload["players"])
			await get_tree().create_timer(int(payload["timeout"]) - Time.get_unix_time_from_system()).timeout
