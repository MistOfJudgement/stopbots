class_name WebsocketMultiplayer
extends Node

@export var public_host = Secret.websocket_host
@export var chat_api_prefix = "/api/chat/"
@export var local_host := "ws://localhost:8787"
var websocket_host := local_host
signal on_recieve_ws_message
signal on_connect
signal on_disconnect
var socket:= WebSocketPeer.new()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process(false)
	pass # Replace with function body.

var first := true
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Call this in `_process()` or `_physics_process()`.
	# Data transfer and state updates will only happen when calling this function.
	socket.poll()

	# get_ready_state() tells you what state the socket is in.
	var state = socket.get_ready_state()
	# `WebSocketPeer.STATE_OPEN` means the socket is connected and ready
	# to send and receive data.
	
	if state == WebSocketPeer.STATE_OPEN:
		if first:
			first = false
			on_connect.emit()
			
		while socket.get_available_packet_count():
			var packet = socket.get_packet()
			if socket.was_string_packet():
				var packet_text = packet.get_string_from_utf8()
				print("< Got text data from server: %s" % packet_text)
			else:
				print("< Got binary data from server: %d bytes" % packet.size())
			on_recieve_ws_message.emit(packet.get_string_from_utf8())
	# `WebSocketPeer.STATE_CLOSING` means the socket is closing.
	# It is important to keep polling for a clean close.
	elif state == WebSocketPeer.STATE_CLOSING:
		pass

	# `WebSocketPeer.STATE_CLOSED` means the connection has fully closed.
	# It is now safe to stop polling.
	elif state == WebSocketPeer.STATE_CLOSED:
		# The code will be `-1` if the disconnection was not properly notified by the remote peer.
		var code = socket.get_close_code()
		print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		set_process(false)
		on_disconnect.emit()
		first = true

func connect_to_server(room_id: String) -> void:
	var url = websocket_host + chat_api_prefix + room_id
	print(url)
	var err = socket.connect_to_url(url)
	if err == OK:
		print("Connecting to %s..." % url)
		set_process(true)
	else:
		push_error("Unable to connect.")
		set_process(false)
