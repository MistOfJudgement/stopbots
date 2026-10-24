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
		$Money.visible = false
		
		
func load_racer(players: Array) -> void:
	var horses: Array[int] = []
	horses.assign(players.map(func(i: Dictionary) -> int: return int(i["horse_i"])))
	$HorseButtonContainer.setup_horses(horses)

	selected_horse = horses.pick_random()
	update_bet(selected_horse, 0)
func on_data_message(message: NetworkEvent) -> void:
	var payload: Dictionary = message.payload
	match payload["type"]:
		"announce_racers":
			if GameState.current_player.role == GameState.Role.Spectator:
				load_racer(payload["players"])
				get_tree().create_timer(int(payload["timeout"]) - Time.get_unix_time_from_system()).timeout.connect(end_betting_time)

		"update_money":
			GameState.current_player.player_stats.money = int(payload["amt"])
			$Money.text = "You have {0} to bet with".format([GameState.current_player.player_stats.money])
func end_betting_time() -> void:
	%HBoxContainer.visible = false
	%HorseButtonContainer.visible = false

func update_bet(horse_i: int, change: int) -> void:
	current_bet += change
	selected_horse = horse_i
	$HBoxContainer/Label.text = "Current Bet: {0}".format([current_bet])
	$HBoxContainer/incr.disabled = current_bet + base_change_value > GameState.current_player.player_stats.money
	$HBoxContainer/dec.disabled = current_bet - base_change_value < 10
	for button: HorseButton in %HorseButtonContainer.loaded_buttons:
		button.set_disabled(button.horse_index == selected_horse)
	WsMultiplayer.send_data({
		"type": "submit_bet",
		"horse_i": selected_horse,
		"amount": current_bet
	})
func _on_incr_pressed() -> void:
	update_bet(selected_horse, 10)
	

func _on_dec_pressed() -> void:
	update_bet(selected_horse, -10)


func _on_horse_button_container_on_horse_button_pressed(i: int) -> void:
	update_bet(i, 0)
