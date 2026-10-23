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
