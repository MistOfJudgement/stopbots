extends VBoxContainer


func _ready() -> void:
	if GameState.is_authority:
		var winner: GameState.PlayerInfo
		var spectator_winner: GameState.PlayerInfo = null
		for p: GameState.PlayerInfo in GameState.players.values():
			if p.role == GameState.Role.Player and p.player_stats.wins >= GameState.wins_to_win:
				winner = p
			if p.role == GameState.Role.Spectator:
				if spectator_winner == null:
					spectator_winner = p
				elif p.player_stats.money > spectator_winner.player_stats.money:
					spectator_winner = p
		$Label.text = "Congrats to {0}!\nTrainer of {1}".format([winner.name, HorseDb.lookup(winner.horse_info).full_name])
		if spectator_winner:
			$Label2.text = "{0} is the best gambler with {1} money!".format([spectator_winner.name, spectator_winner.player_stats.money])
		else:
			$Label2.visible = false
	else:
		$Label.text = "Thanks for Racing!"
func _on_button_pressed() -> void:
	GameState.goto_lobby()
