class_name BetTracker
extends PanelContainer


func set_horse(horse: HorseData) -> void:
	%TextureRect.texture.atlas = horse.sprite_sheet
	%Name.text = horse.short_name
	
func set_bet(amount: int) -> void:
	%BetAmount.text = str(amount)
