class_name HrtMap
extends Node2D

@export var spawn_point: Marker2D
@export var map: Sprite2D

class RaceData:
	var horse_info: HorseData
	var speed: float
	var power: float
	
func spawn_horse(race_data: RaceData):
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
