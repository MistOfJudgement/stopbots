class_name HorseButtonContainer
extends HFlowContainer

var horse_button := preload("res://lobby/horse_button.tscn")
var loaded_buttons: Array[HorseButton] = []

signal on_horse_button_pressed(i: int)
# Called when the node enters the scene tree for the first time.
func setup_horses(horses: Array[int]) -> void:
	for horse_i in horses:
		var tmp: HorseButton = horse_button.instantiate()
		tmp.set_horse(horse_i)
		tmp.set_disabled(false)
		tmp.on_press.connect(on_horse_button_pressed.emit)
		loaded_buttons.append(tmp)
		add_child(tmp)
