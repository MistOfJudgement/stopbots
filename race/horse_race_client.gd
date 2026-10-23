extends VBoxContainer

@onready var info_text := $Label
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(WebsocketConnector.new())
	if GameState.current_player.role == GameState.Role.Player:
		info_text.text = "Cheer on your horse"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func load_racer(players: Array) -> void:
	for p in players:
		print("player:", p)
		var temp := Button.new()
		temp.text = p["player_name"]
		$HFlowContainer.add_child(temp)
	$HFlowContainer.visible = true
	$HBoxContainer.visible = true
func on_data_message(message: NetworkEvent) -> void:
	var payload: Dictionary = message.payload
	match payload["type"]:
		"announce_racers":
			if GameState.current_player.role == GameState.Role.Spectator:
				load_racer(payload["players"])
				get_tree().create_timer(int(payload["timeout"]) - Time.get_unix_time_from_system()).timeout.connect(end_betting_time)
func end_betting_time() -> void:
	$HFlowContainer.visible = false
	$HBoxContainer.visible = false
