extends HBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	WsMultiplayer.on_disconnect.connect(func (): get_tree().change_scene_to_file("res://title_screen.tscn"))
	WsMultiplayer.on_recieve_ws_message.connect(message_recieved)

func message_recieved(message: String) -> void:
	var obj = JSON.parse_string(message)
	
	$ChatMenu.recieve_json_message(obj)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
