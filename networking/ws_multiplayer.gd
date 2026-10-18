class_name WebsocketMultiplayer
extends Node

@export var chat_api_prefix: String = "/api/chat/"
@export var websocket_host: String = Secret.websocket_host

signal on_connect()
signal on_disconnect()
signal on_data_message(event: NetworkEvent) # The main one to communicate between client and host
signal on_system_message(type: String, data: Dictionary) # For auth/errors/joins if needed. communication directly with the server

var socket := WebSocketPeer.new()
var is_connected_to_server := false
func _ready() -> void:
	set_process(false)

func _process(_delta: float) -> void:
	socket.poll()
	var state := socket.get_ready_state()
	
	if state == WebSocketPeer.STATE_OPEN:
		if not is_connected_to_server:
			is_connected_to_server = true
			on_connect.emit()
			
		while socket.get_available_packet_count() > 0:
			var packet := socket.get_packet()
			if socket.was_string_packet():
				var text := packet.get_string_from_utf8()
				print("[WS RECV] <- ", text) # <-- ADD THIS LOG
				var json := JSON.new()
				if json.parse(text) == OK and json.get_data() is Dictionary:
					var d := json.get_data() as Dictionary
					var type: String = d.get("type", "")
					
					# Direct routing: Data gets its own typed event, everything else goes to system
					if type == "data":
						on_data_message.emit(NetworkEvent.from_dict(d))
					else:
						on_system_message.emit(type, d)
				else:
					push_error("Invalid JSON received: " + text)

	elif state == WebSocketPeer.STATE_CLOSED:
		var code := socket.get_close_code()
		print("WebSocket closed. Code: %d" % code)
		set_process(false)
		if is_connected_to_server:
			is_connected_to_server = false
			on_disconnect.emit()

func connect_to_server(room_id: String) -> void:
	var url := websocket_host + chat_api_prefix + room_id
	if socket.connect_to_url(url) == OK:
		set_process(true)
	else:
		push_error("Unable to connect to %s" % url)
		set_process(false)

func send_authenticate(password: String) -> void:
	socket.send_text(JSON.stringify({"type": "authenticate", "password": password}))

# Use send_data when communicating between host and client
func send_data(event_data: Variant) -> void:
	var payload_string: String = event_data if event_data is String else JSON.stringify(event_data)
	var final_json = JSON.stringify({"type": "data", "payload": payload_string})
	print("[WS SEND] -> ", final_json) # <-- ADD THIS LOG
	socket.send_text(final_json)
