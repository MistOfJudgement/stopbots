extends VBoxContainer

@onready var input := $HBoxContainer/RoomIDInput
func _on_create_room_button_pressed() -> void:
	get_tree().change_scene_to_file("res://lobby_screen.tscn")
	
	


func _on_join_room_button_pressed() -> void:
	if input.text == "": return
	WsMultiplayer.connect_to_server(input.text)
	
	WsMultiplayer.on_connect.connect(func (): 
		get_tree().change_scene_to_file("res://lobby_screen.tscn")
		, CONNECT_ONE_SHOT)
