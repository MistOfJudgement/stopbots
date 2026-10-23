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
var is_authority: bool = true

var current_player: PlayerInfo = PlayerInfo.new()
# --- PLAYER MANAGEMENT ---
class PlayerInfo:
	var connection_id: String
	var role: Role
	var name: String
	var horse_info: int # lookup for horse info?
	var player_stats: PlayerStats

var players: Dictionary[String, PlayerInfo] = {}

func active_players() -> Array[PlayerInfo]:
	return players.values().filter(func(e: PlayerInfo) -> bool: return e.role == Role.Player)

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
			current_player.role = Role.Host
		"client":
			is_authority = false
		_:
			printerr("GlobalGameState: Unknown role received -> ", role_str)

func set_role(role_val: int) -> void:
	current_player.role = role_from_val(role_val)

func role_from_val(role_val: int) -> Role:
	if role_val >= 0 and role_val < Role.size():
		return Role.values()[role_val]
	return Role.None

# ============================================================================
# SCENE & STATE TRANSITIONS
# ============================================================================
class ScopedScene:
	var host_scene_path: String
	var client_scene_path: String
	func _init(authDict: Dictionary[bool, String]) -> void:
		host_scene_path = authDict[true]
		client_scene_path = authDict[false]
	
	func pull(is_auth: bool) -> String:
		return host_scene_path if is_auth else client_scene_path
	
var SCENE_PATHS: Dictionary[GameStateType, ScopedScene] = {
	GameStateType.Lobby: ScopedScene.new({
		true: "res://lobby/lobby_screen.tscn",
		false: "res://lobby/lobby_screen_client.tscn"
	}),
	GameStateType.Race: ScopedScene.new({
		true: "res://race/horse_race.tscn",
		false: "res://race/horse_race_client.tscn"
	}),
	GameStateType.Train: ScopedScene.new({
		true: "res://training/training.tscn",
		false: "res://training/training_client.tscn"
	}),
	GameStateType.End: ScopedScene.new({
		true: "res://win/win_screen.tscn",
		false: "res://win/win_screen.tscn"
	})
}

func transition_to_state(target_state: GameStateType, notify_network: bool = true) -> void:
	if current_game_state == target_state:
		return

	current_game_state = target_state

	if notify_network and is_authority:
		WsMultiplayer.send_data({
			"type": "change_state",
			"target_state": target_state
		})

	if SCENE_PATHS.has(target_state):
		var scene := SCENE_PATHS[target_state]
		get_tree().change_scene_to_file(scene.pull(is_authority))
	else:
		printerr("GlobalGameState: No scene mapped for state -> ", target_state)

func goto_lobby() -> void: transition_to_state(GameStateType.Lobby)
func goto_race() -> void: transition_to_state(GameStateType.Race)
func goto_train() -> void: transition_to_state(GameStateType.Train)
func goto_win() -> void: transition_to_state(GameStateType.End)

# ============================================================================
# NETWORK MESSAGE ROUTING (Incoming from WsMultiplayer)
# ============================================================================

func on_data_message(event: NetworkEvent) -> void:
	var raw_payload = event.payload
	var payload: Dictionary = {}

	if raw_payload is String:
		var parsed = JSON.parse_string(raw_payload)
		if parsed is Dictionary:
			payload = parsed
	elif raw_payload is Dictionary:
		payload = raw_payload

	var msg_type: String = payload.get("type", "UNKNOWN")
	print("[DATA MSG PROCESSED] Type: ", msg_type, " from: ", event.sender_id)

	match msg_type:
		"sync_state":
			print("-> HOST: Processing sync_state request for client: ", event.sender_id)
			var player := get_or_create_player(event.sender_id)
			WsMultiplayer.send_data_to(event.sender_id, {
				"type": "sync_state_output",
				"role": player.role,
				"current_game_state": current_game_state,
			})

		"set_name":
			if is_authority:
				var player := get_or_create_player(event.sender_id)
				player.name = payload.get("name", "Unknown")
				print("-> HOST: Updated name for ", event.sender_id, " to: ", player.name)
				player_list_changed.emit()

		"set_role":
			if is_authority:
				var player := get_or_create_player(event.sender_id)
				player.role = role_from_val(int(payload["role"]))
				#check if can then send to one person
				if player.role == Role.Player:
					if is_all_horses_selected():
						return # unable to assign horse
					
					var remaining_horses: Array = get_unpicked_horses()
					player.horse_info = remaining_horses.pick_random()
					WsMultiplayer.send_data_to(player.connection_id, {
						"type": "set_horse_output",
						"horse": player.horse_info
					})
				WsMultiplayer.send_data({
					"type": "update_remaining_horses",
					"remaining": get_unpicked_horses()
				})
				WsMultiplayer.send_data_to(player.connection_id, {
					"type": "set_role_output",
					"role": player.role,
				})
				player_list_changed.emit()
		"set_role_output":
			if not is_authority:
				set_role(int(payload["role"])) # validation on client is not needed
				player_list_changed.emit()
		"set_horse":
			if is_authority:
				var player := get_or_create_player(event.sender_id)
				player.horse_info = int(payload["horse"])
				WsMultiplayer.send_data_to(player.connection_id, {
					"type": "set_horse_output",
					"horse": player.horse_info
				})
				WsMultiplayer.send_data({
					"type": "update_remaining_horses",
					"remaining": get_unpicked_horses()
				})
				player_list_changed.emit()
		"set_horse_output":
			if not is_authority:
				var horse := int(payload["horse"])
				current_player.horse_info = horse
				player_list_changed.emit()

		"sync_state_output":
			if not is_authority:
				print("-> CLIENT: Received sync_state_output from host!")
				set_role(payload.get("role", Role.Spectator))
				var target_state := int(payload.get("current_game_state", GameStateType.None))
				transition_to_state(target_state, false)

		"change_state":
			if not is_authority:
				var target_state := int(payload.get("target_state", GameStateType.None))
				print("-> CLIENT: Host commanded state change to: ", target_state)
				transition_to_state(target_state, false)

		_:
			print("-> UNKNOWN MESSAGE TYPE: ", msg_type)
func is_all_horses_selected() -> bool:
	return active_players().size() >= HorseDb.MainDb.horses.size()
func get_unpicked_horses() -> Array[int]:
	var out: Array = range(0, HorseDb.MainDb.horses.size())
	for player in active_players():
		out.erase(player.horse_info)
	return out as Array[int]
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
			if not is_authority:
				return
			
			var source_id: String = data.get("source", "")
			if source_id.is_empty():
				return

			if type == "joined":
				if current_game_state == GameStateType.Lobby:
					var info := PlayerInfo.new()
					info.connection_id = source_id
					info.role = Role.Spectator
					info.name = "Connecting..."
					players[source_id] = info
					player_list_changed.emit()
				else:
					if not players.has(source_id) or players[source_id] == null:
						var info := PlayerInfo.new()
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
	if is_authority:
		return
	WsMultiplayer.send_data({"type": "sync_state"})
	if not current_player.name:
		current_player.name = "Player_{}".format(randi_range(1, 999))
	WsMultiplayer.send_data({"type": "set_name", "name": current_player.name})

func get_or_create_player(connection_id: String) -> PlayerInfo:
	if not players.has(connection_id):
		var info := PlayerInfo.new()
		info.connection_id = connection_id
		info.role = Role.Spectator
		info.name = "Connecting..."
		players[connection_id] = info
		player_list_changed.emit()
	return players[connection_id]

func on_disconnect() -> void:
	reset()

func reset() -> void:
	current_game_state = GameStateType.None
	set_role(Role.None)
	is_authority = false
	room = ""
	password = ""
	players.clear() # Clear out stale sessions
	player_list_changed.emit()
	get_tree().change_scene_to_file("res://title_screen.tscn")
