extends Node2D

@export var bet_template := preload("res://race/BetTracker.tscn")
@onready var map: HrtMap = $Map1
@onready var betting_container: Container = $CanvasLayer/MarginContainer/BettingContainer
@onready var win_label: Label = $CanvasLayer/WinMessage
class HorseBet:
	var horse_i: int
	var amt: int
	func _init(i: int, a: int) -> void:
		horse_i = i
		amt = a
var bets: Dictionary[String, HorseBet] = {}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not GameState.is_authority:
		printerr("how did we get here")
	for i in range(len(HorseDb.MainDb.horses)):
		var tmp := HorseStats.new(i)
		map.spawn_horses(tmp)
		var bet_temp: BetTracker = bet_template.instantiate()
		bet_temp.set_bet(0)
		bet_temp.set_horse(HorseDb.lookup(i))
		betting_container.add_child(bet_temp)

	for i: GameState.PlayerInfo in GameState.players.values():
		if i.role == GameState.Role.Spectator:
			i.player_stats.money += 100
			WsMultiplayer.send_data_to(i.connection_id, {
				"type": "update_money",
				"amt": i.player_stats.money
			})
	WsMultiplayer.send_data({
		"type": "announce_racers",
		"timeout": Time.get_unix_time_from_system() + 10,
		"players": GameState.active_players().map(
			func(e: GameState.PlayerInfo) -> Dictionary: return {
				"player_id": e.connection_id,
				"player_name": e.name,
				"horse_i": e.horse_info
			})
	})
func _on_start_timer_timeout() -> void:
	#remove starting gate
	map.open_gate()
	pass


func _on_end_race_button_pressed() -> void:
	GameState.goto_train()


func _on_win_race_button_pressed() -> void:
	GameState.goto_win()


func _on_map_1_on_win(horse_i: int) -> void:
	win_label.text = "{0} wins!".format(HorseDb.lookup(horse_i).full_name)
	payout(horse_i)
	await get_tree().create_timer(5).timeout
	GameState.goto_train()

func on_data_message(event: NetworkEvent) -> void:
	var payload: Dictionary = event.payload
	match payload["type"]:
		"submit_bet":
			var player := GameState.get_or_create_player(event.sender_id)
			var amount := int(payload["amount"])
			var horse_i := int(payload["horse_i"])
			if player.role != GameState.Role.Spectator: return
			place_bet(player.connection_id, horse_i, amount)

func place_bet(player: String, horse_i: int, amount: int) -> void:
	bets[player] = HorseBet.new(horse_i, amount)
	update_bets_ui()

func update_bets_ui() -> void:
	var horse_bet_nodes: Array[BetTracker] = betting_container.get_children().filter(func(n: Node): return n is BetTracker)
	var group_bets: Array[int] = []
	group_bets.resize(horse_bet_nodes.size())
	
	for bet: HorseBet in bets.values():
		group_bets[bet.horse_i] += bet.amt
	
	for i in range(len(horse_bet_nodes)):
		horse_bet_nodes[i].set_bet(group_bets[i])
func sum(a: int, c: int) -> int: return a + c
func payout(winner: int) -> void:
	var pot: int = 0
	var winners: Array[String] = []
	for p in bets.keys():
		pot += bets[p].amt
		if bets[p].horse_i == winner:
			winners.append(p)
		
	for s in winners:
		var i: GameState.PlayerInfo = GameState.players[s]
		@warning_ignore("integer_division")
		i.player_stats.money += pot / len(winners)
		WsMultiplayer.send_data_to(i.connection_id, {
			"type": "update_money",
			"amt": i.player_stats.money
		})
