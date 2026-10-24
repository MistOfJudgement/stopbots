class_name TrainerCard
extends PanelContainer


func set_player(player: GameState.PlayerInfo) -> void:
	%TrainerLabel.text = player.name
	%Horse.text = HorseDb.lookup(player.horse_info).full_name
	%Speed.text = "Speed: {0}".format([player.player_stats.speed])
	%Power.text = "Power: {0}".format([player.player_stats.power])
	%TextureRect.texture.atlas = HorseDb.lookup(player.horse_info).sprite_sheet
