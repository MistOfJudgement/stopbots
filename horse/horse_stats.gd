class_name HorseStats
extends RefCounted

var horse_info: int
var speed: float
var power: float
var bets: int
func _init(index: int) -> void:
	horse_info = index
	speed = 1.0
	power = 1.0
	bets = 0
	
static func from_player(player: GameState.PlayerInfo) -> HorseStats:
	var tmp:= HorseStats.new(player.horse_info)
	tmp.speed = player.player_stats.speed
	tmp.power = player.player_stats.power
	return tmp
