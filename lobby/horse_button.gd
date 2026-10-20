class_name HorseButton
extends Control

var horse_index: int = 0
signal on_press(ind)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Button.pressed.connect(on_press.emit.bind(horse_index))
	#set_horse(5)

func set_horse(i: int):
	var horse:= HorseDb.MainDb.horses[i]
	%TextureRect.texture.atlas = horse.sprite_sheet.duplicate(true)
	%Label.text = horse.full_name
	horse_index = i
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
