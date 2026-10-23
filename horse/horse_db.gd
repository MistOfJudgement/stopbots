class_name HorseDb
extends Resource

@export var horses: Array[HorseData]

static var MainDb:HorseDb= load("res://horse/core_db.tres") as HorseDb

static func lookup(i:int) -> HorseData: return MainDb.horses[i]
