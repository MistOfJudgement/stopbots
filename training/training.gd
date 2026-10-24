extends Control

var turn_counts: Dictionary[String, int] = {}
@export var horse_template: PackedScene = preload("res://training/trainer_card.tscn")
var trainer_cards: Dictionary[String, TrainerCard] = {}
func _ready() -> void:
	add_child(WebsocketConnector.new())
	
	for player in GameState.active_players():
		turn_counts[player.connection_id] = 4
		var horse_instance :TrainerCard= horse_template.instantiate()
		horse_instance.set_player(player)
		trainer_cards[player.connection_id] = horse_instance
		%HorseContainer.add_child(horse_instance)
func _on_end_training_pressed() -> void:
	GameState.goto_race()

func on_data_message(message: NetworkEvent) -> void:
	var payload: Dictionary = message.payload
	var sender := GameState.players[message.sender_id]
	
	match payload["type"]:
		"train_speed":
			sender.player_stats.speed += 0.25
			turn_counts[sender.connection_id] -= 1
			send_training_output(sender)

		"train_power":
			sender.player_stats.power += 0.25
			turn_counts[sender.connection_id] -= 1
			send_training_output(sender)
	if completed_training():
		_on_end_training_pressed()

func completed_training() -> bool:
	return turn_counts.values().reduce(func(a: int, c: int) -> int: return a + c) == 0
func send_training_output(player: GameState.PlayerInfo) -> void:
	trainer_cards[player.connection_id].set_player(player)
	WsMultiplayer.send_data_to(player.connection_id, {
		"type": "training_output",
		"speed": player.player_stats.speed,
		"power": player.player_stats.power,
		"turns": turn_counts[player.connection_id]
	})
