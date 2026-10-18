class_name GlobalGameState
extends Node

signal player_list_changed # Emitted so UI can update automatically

enum GameStateType {
	None,
	Lobby,
	Race,
	Train,
	End,
}

enum Role {
	Host,
	Player,
	Spectator,
	None,
}

# --- STATE VARIABLES ---
var current_game_state: GameStateType = GameStateType.None
var room: String = ""
var password: String = ""
var is_authority: bool = false
var role: Role = Role.None
var player_name: String = "Player_" + str(randi() % 1000)

# --- PLAYER MANAGEMENT ---
class PlayerInfo:
	var connection_id: String
	var role: Role
	var name: String

var players: Dictionary[String, PlayerInfo] = {}
func active_players() -> Array[PlayerInfo]:
	return players.values().filter(func(e): e.role == Role.Player)
# --- INITIALIZATION ---
func _ready() -> void:
	add_child(WebsocketConnector.new())

# ============================================================================
# ROLE & AUTHORITY MANAGEMENT
# ============================================================================

func set_authority(role_str: String) -> void:
	match role_str.to_lower():
		"host":
			is_authority = true
			role = Role.Host
		"client":
			is_authority = false
		_:
			printerr("GlobalGameState: Unknown role received -> ", role_str)

func set_role(role_val: int) -> void:
	if role_val >= 0 and role_val < Role.size():
		role = Role.values()[role_val]


# ============================================================================
# SCENE & STATE TRANSITIONS
# ============================================================================

func goto_lobby() -> void:
	# Only block if we are ALREADY in the lobby scene
	if current_game_state == GameStateType.Lobby: return

	current_game_state = GameStateType.Lobby
	WsMultiplayer.send_data({
		"type": "change_state",
		"target_state": GameStateType.Lobby
	})
	if is_authority:
		get_tree().change_scene_to_file("res://lobby/lobby_screen.tscn")
	else:
		get_tree().change_scene_to_file("res://lobby/lobby_screen_client.tscn")
func goto_race() -> void:
	if current_game_state == GameStateType.Race: return
	current_game_state = GameStateType.Race

	if is_authority:
		# 1. Tell all connected clients to also switch to the race
		WsMultiplayer.send_data({
			"type": "change_state",
			"target_state": GameStateType.Race
		})
		# 2. Host changes its own scene
		get_tree().change_scene_to_file("res://race/horse_race.tscn")
	else:
		# Client scene transition
		get_tree().change_scene_to_file("res://race/horse_race_client.tscn")
func goto_train() -> void:
	pass
# ============================================================================
# NETWORK MESSAGE ROUTING (Incoming from WsMultiplayer)
# ============================================================================

func on_data_message(event: NetworkEvent) -> void:
	var raw_payload = event.payload
	var payload: Dictionary = {}

	# 1. Safely handle whether the payload came in as a JSON string or already a dictionary
	if raw_payload is String:
		var parsed = JSON.parse_string(raw_payload)
		if parsed is Dictionary:
			payload = parsed
	elif raw_payload is Dictionary:
		payload = raw_payload

	# 2. Add a debug print to see what type we actually extracted
	var msg_type = payload.get("type", "UNKNOWN")
	print("[DATA MSG PROCESSED] Type: ", msg_type, " from: ", event.sender_id)

	# 3. Match the parsed type
	match msg_type:
		"sync_state":
			print("-> HOST: Processing sync_state request for client: ", event.sender_id)
			var player = get_or_create_player(event.sender_id)
			WsMultiplayer.send_data({
				"type": "sync_state_output",
				"role": player.role,
				"current_game_state": current_game_state,
			})

		"set_name":
			if is_authority:
				var player = get_or_create_player(event.sender_id)
				player.name = payload.get("name", "Unknown")
				print("-> HOST: Updated name for ", event.sender_id, " to: ", player.name)
				player_list_changed.emit()

		"sync_state_output":
			if not is_authority:
				print("-> CLIENT: Received sync_state_output from host!")
				set_role(payload.get("role", Role.Spectator))
				var target_state = int(payload.get("current_game_state", GameStateType.None))
				
				if target_state == GameStateType.Lobby:
					goto_lobby()
				elif target_state == GameStateType.Race:
					goto_race()
		"change_state":
			if not is_authority:
				var target_state = int(payload.get("target_state", GameStateType.None))
				print("-> CLIENT: Host commanded state change to: ", target_state)
				
				match target_state:
					GameStateType.Lobby:
						goto_lobby()
					GameStateType.Race:
						goto_race()
					GameStateType.Train:
						goto_train() # Or whatever your next phase is
					_:
						printerr("Unknown target state received from host: ", target_state)
		_:
			print("-> UNKNOWN MESSAGE TYPE: ", msg_type)
func on_system_message(type: String, data: Dictionary) -> void:
	match type:
		"authenticated":
			print("Successfully authenticated as: ", data.get("role"))
			set_authority(data.get("role"))
			if is_authority:
				goto_lobby()
			else:
				sync_state()

		"joined", "left":
			# Only the host tracks global player joins/leaves
			if not is_authority: return
			
			var source_id = data.get("source", "")
			if source_id.is_empty(): return

			if type == "joined":
				if current_game_state == GameStateType.Lobby:
					var info = PlayerInfo.new()
					info.connection_id = source_id
					info.role = Role.Spectator
					info.name = "Connecting..."
					players[source_id] = info
					player_list_changed.emit()
				else:
					if not players.has(source_id) or players[source_id] == null:
						var info = PlayerInfo.new()
						info.connection_id = source_id
						info.role = Role.None # Late-join / waiting room
						info.name = "Connecting..."
						players[source_id] = info

			elif type == "left":
				if current_game_state == GameStateType.Lobby:
					players.erase(source_id)
					player_list_changed.emit()
				else:
					if players.has(source_id) and players[source_id].role == Role.None:
						players.erase(source_id)
		_:
			pass


# ============================================================================
# HELPER METHODS
# ============================================================================

func sync_state() -> void:
	if is_authority: return
	WsMultiplayer.send_data({"type": "sync_state"})
	WsMultiplayer.send_data({"type": "set_name", "name": player_name})

func get_or_create_player(connection_id: String) -> PlayerInfo:
	if not players.has(connection_id):
		var info = PlayerInfo.new()
		info.connection_id = connection_id
		info.role = Role.Spectator
		info.name = "Connecting..."
		players[connection_id] = info
		player_list_changed.emit()
	return players[connection_id]

func on_disconnect():
	reset()

func reset():
	current_game_state = GameStateType.None
	role = Role.None
	get_tree().change_scene_to_file("res://title_screen.tscn")
