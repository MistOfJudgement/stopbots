class_name NetworkEvent
extends RefCounted

var sender_id: String
var timestamp: int
var payload: Variant # Can be your inner event dictionary/object

static func from_dict(d: Dictionary) -> NetworkEvent:
	var ev := NetworkEvent.new()
	ev.sender_id = d.get("from", "")
	ev.timestamp = int(d.get("timestamp", 0))

	var raw_payload = d.get("payload")
	if raw_payload is String:
		var json := JSON.new()
		if json.parse(raw_payload) == OK:
			ev.payload = json.get_data()
		else:
			ev.payload = raw_payload
	else:
		ev.payload = raw_payload
		
	return ev

func _to_string() -> String:
	return "{sender_id {0}, timestamp: {1}. payload: {2}".format([sender_id, timestamp, payload])
