class_name ChatMenu
extends VBoxContainer

class MessageBody:
	var source: String
	var message: String
	var timestamp: int
	
	# Helper to turn a Dictionary into a strongly-typed MessageBody
	static func from_dict(d: Dictionary) -> MessageBody:
		var mb := MessageBody.new()
		mb.source = GameState.players.get(d.get("source", "Unknown")).name
		mb.message = d.get("message", "")
		mb.timestamp = int(d.get("timestamp", 0))
		return mb

@onready var messageTemplate: Label = $TextMessage
@onready var textInputBox: LineEdit = $MessageSend

func add_message(msg: MessageBody) -> void:
	var temp := messageTemplate.duplicate() as Label
	# Formatting timestamp nicely (e.g., HH:MM:SS or date)
	var time_str := Time.get_time_string_from_unix_time(msg.timestamp)
	temp.text = "[%s] (%s): %s" % [time_str, msg.source, msg.message]
	temp.visible = true
	add_child(temp)

# This replaces your old receive function and listens to NetworkEvent directly
func on_data_message(event: NetworkEvent) -> void:
	var payload: Dictionary = event.payload
	if payload.is_empty(): return
	match payload.get("type"):
		"message":
			var msg: MessageBody = MessageBody.new()
			msg.message = payload.get("message")
			msg.source = event.sender_id
			msg.timestamp = event.timestamp
			add_message(msg)
		_:
			print("unknown message", event._to_string(), payload)
func on_chat_send_pressed() -> void:
	if textInputBox.text.strip_edges() == "":
		return
		
	var message := MessageBody.new()
	message.message = textInputBox.text
	message.source = "Me" # Will be overwritten on the receiving end by server's 'from' id
	message.timestamp = Time.get_unix_time_from_system()
	
	# Optionally show it locally right away
	#add_message(message)
	
	# Send it using the helper on WebsocketMultiplayer which packages it into the "data" type
	var chat_payload := {
		"message": message.message,
		"type": "message"
	}
	WsMultiplayer.send_data(chat_payload)
	
	textInputBox.clear()
