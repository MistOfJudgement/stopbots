extends VBoxContainer

@onready var info_text := $Label
var current_bet: int = 0
var base_change_value: int = 10
var selected_horse: int = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(WebsocketConnector.new())
	if GameState.current_player.role == GameState.Role.Player:
		info_text.text = "Cheer on your horse"
		%HBoxContainer.visible = false
		%HorseButtonContainer.visible = false

func load_racer(players: Array) -> void:
	var horses: Array[int] = []
	horses.assign(players.map(func(i: Dictionary) -> int: return int(i["horse_i"])))
	$HorseButtonContainer.setup_horses(horses)

	selected_horse = horses.pick_random()

func on_data_message(message: NetworkEvent) -> void:
	var payload: Dictionary = message.payload
	match payload["type"]:
		"announce_racers":
			if GameState.current_player.role == GameState.Role.Spectator:
				load_racer(payload["players"])
				get_tree().create_timer(int(payload["timeout"]) - Time.get_unix_time_from_system()).timeout.connect(end_betting_time)

		"update_money":
			GameState.current_player.player_stats.money = int(payload["amt"])
			$Money.text = "You have {0} to bet with" % (str(GameState.current_player.player_stats.money))
func end_betting_time() -> void:
	%HBoxContainer.visible = false
	%HorseButtonContainer.visible = false

func update_bet(change: int) -> void:
	current_bet += change
	$HBoxContainer/Label.text = "Current Bet: {0}" % (current_bet)
	$HBoxContainer/incr.disabled = current_bet + base_change_value > GameState.current_player.player_stats.money
	$HBoxContainer/dec.disabled = current_bet - base_change_value < 10
	WsMultiplayer.send_data({
		"type": "submit_bet",
		"horse_i": selected_horse,
		"amount": current_bet
	})
func _on_incr_pressed() -> void:
	current_bet += 10

func _on_dec_pressed() -> void:
	current_bet -= 10
