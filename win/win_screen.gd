extends VBoxContainer


func _ready() -> void:
	if GameState.is_authority:
		var winner: GameState.PlayerInfo
		for p in GameState.active_players():
			if p.player_stats.wins >= GameState.wins_to_win:
				winner = p
				break
		$Label.text = "Congrats to {0}!\nTrainer of {1}".format([winner.name, HorseDb.lookup(winner.horse_info).full_name])
	else:
		$Label.text = "Thanks for Racing!"
func _on_button_pressed() -> void:
	GameState.goto_lobby()
