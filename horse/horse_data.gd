class_name HorseData
extends Resource

@export var full_name: String
@export var short_name: String
@export var sprite_sheet: CompressedTexture2D

func build_atlas_tex() -> AtlasTexture:
	var out := AtlasTexture.new()
	out.atlas = sprite_sheet
	return out
