class_name WebsocketConnector
extends Node

var events:= [
	&"on_connect",
	&"on_disconnect",
	&"on_data_message",
	&"on_system_message",
	
]

func _enter_tree() -> void:
	var parent := get_parent()
	for ev in events:
		if parent.has_method(ev):
			WsMultiplayer.connect(ev, Callable(parent, ev))
func _exit_tree() -> void:
	var parent := get_parent()
	for ev in events:
		if parent.has_method(ev):
			WsMultiplayer.disconnect(ev, Callable(parent, ev))
