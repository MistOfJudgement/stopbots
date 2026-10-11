class_name ChatMenu
extends VBoxContainer

class MessageBody:
	var source: String
	var message: String
	var timestamp: int
	
@onready var messageTemplate :Label= $TextMessage
@onready var textInputBox: LineEdit = $MessageSend
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func add_message(msg: MessageBody) -> void:
	var temp := messageTemplate.duplicate()
	temp.text = "[" + Time.get_date_string_from_unix_time(msg.timestamp) + "]" + "(" + msg.source + ")" + msg.message
	add_child(temp)

func recieve_json_message(json: Variant):
	var msg: MessageBody = MessageBody.new()
	msg.message = json["message"]
	msg.source = json["source"]
	msg.timestamp = json["timestamp"]
	add_message(msg)
 

func _on_chat_send_pressed() -> void:
	var message: MessageBody = MessageBody.new()
	message.message = textInputBox.text
	message.source = "Client"
	message.timestamp = Time.get_unix_time_from_system()
	add_message(message)
	WsMultiplayer.socket.send_text(message.message)
	
