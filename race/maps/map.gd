class_name HrtMap
extends Node2D

signal on_win(horse_i: int)
@export var spawn_point: Marker2D
@export var map: Sprite2D
@export var horse_template := preload("res://race/horse.tscn")


var horses: Array[HorseBody] = []
func _ready() -> void:
	var targets := get_tree().get_nodes_in_group("target")
	for i in targets:
		if i is HrtTarget:
			i.area.body_entered.connect(win)

func win(body: Node2D) -> void:
	for i in horses:
		i.process_mode = Node.PROCESS_MODE_DISABLED
	body.modulate.b = 1.0
	create_tween().tween_property($Camera2D, "offset", body.global_position, 3)
	create_tween().tween_property($Camera2D, "zoom", Vector2.ONE * 5, 3)
func spawn_horses(horse_stats: HorseStats) -> void:
	var tmp: HorseBody = horse_template.instantiate()
	tmp.set_horse(horse_stats)
	tmp.map_sprite = map
	var offset: Vector2 = Vector2(randf_range(-10, 10), randf_range(-10, 10))
	tmp.global_position = $Spawn.global_position + offset
	add_child(tmp)
	horses.append(tmp)

func open_gate() -> void:
	var gates := get_tree().get_nodes_in_group("starting_gate")
	for gate in gates:
		if gate is Node2D:
			gate.visible = false
			gate.process_mode = Node.PROCESS_MODE_DISABLED
