class_name BetTracker
extends PanelContainer

var horse_index: int
func set_horse(horse_i: int) -> void:
	horse_index = horse_i
	var horse := HorseDb.lookup(horse_index)
	%TextureRect.texture.atlas = horse.sprite_sheet
	%Name.text = horse.short_name
	
func set_bet(amount: int) -> void:
	%BetAmount.text = str(amount)
