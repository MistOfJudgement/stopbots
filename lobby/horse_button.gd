class_name HorseButton
extends Control

var horse_index: int = 0
signal on_press(ind: int)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Button.pressed.connect(on_press.emit.bind(horse_index))
	#set_horse(5)

func set_horse(i: int) -> void:
	var horse := HorseDb.MainDb.horses[i]
	%TextureRect.texture.atlas = horse.sprite_sheet.duplicate(true)
	%Label.text = horse.full_name
	horse_index = i
	
func set_disabled(disable: bool) -> void:
	%Button.disabled = disable
	modulate.a = 0.5 if disable else 1.0

func get_disabled() -> bool: return %Button.disabled
