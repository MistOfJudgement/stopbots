extends Node2D

@export var horse_template := preload("res://race/horse.tscn")
var horses: Array[Node2D] = []
@onready var map: HrtMap = $Map1
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not GameState.is_authority:
		printerr("how did we get here")
	for player: GameState.PlayerInfo in GameState.active_players():
		var tmp := HorseStats.new()
		tmp.horse_info = player.horse_info
		tmp.speed = 1
		tmp.power = 1
		map.spawn_horses(tmp)

	WsMultiplayer.send_data({
		"type": "announce_racers",
		"timeout": Time.get_unix_time_from_system() + 10,
		"players": GameState.active_players().map(
			func(e: GameState.PlayerInfo) -> Dictionary: return {
				"player_id": e.connection_id,
				"player_name": e.name,
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
