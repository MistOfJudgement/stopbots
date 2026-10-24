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
	add_child(WebsocketConnector.new())
	for p in GameState.active_players():
		var tmp := HorseStats.new(p.horse_info)
		map.spawn_horses(tmp)
		var bet_temp: BetTracker = bet_template.instantiate()
		bet_temp.set_bet(0)
		bet_temp.set_horse(p.horse_info)
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
		"timeout": Time.get_unix_time_from_system() + $StartTimer.wait_time,
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
	for spec: String in bets.keys():
		var bet := bets[spec]
		GameState.players[spec].player_stats.money -= bet.amt
		WsMultiplayer.send_data_to(spec, {
			"type": "update_money",
			"amt": GameState.players[spec].player_stats.money
		})


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
	var horse_bet_nodes: Array[BetTracker] = []
	horse_bet_nodes.assign(betting_container.get_children().filter(func(n: Node) -> bool: return n is BetTracker))
	var group_bets: Dictionary[int, int] = {}
	
	for bet: HorseBet in bets.values():
		if bet.horse_i not in group_bets:
			group_bets[bet.horse_i] = 0
		group_bets[bet.horse_i] += bet.amt
	for bet_node in (horse_bet_nodes):
		bet_node.set_bet(group_bets[bet_node.horse_index])
func sum(a: int, c: int) -> int: return a + c
func payout(winner: int) -> void:
	var pot: int = 0
	var winning_pool: int = 0

	for p: String in bets.keys():
		var bet: HorseBet = bets[p]
		pot += bet.amt
		if bet.horse_i == winner:
			winning_pool += bet.amt

	if winning_pool == 0:
		#idk we can keep this for now. no refunds
		return
		
	for p: String in bets.keys():
		var bet: HorseBet = bets[p]
		if bet.horse_i == winner:
			var payout_amount: int = int((float(bet.amt) / float(winning_pool)) * float(pot))
			var i: GameState.PlayerInfo = GameState.players[p]
			i.player_stats.money += payout_amount
			WsMultiplayer.send_data_to(i.connection_id, {
				"type": "update_money",
				"amt": i.player_stats.money
			})