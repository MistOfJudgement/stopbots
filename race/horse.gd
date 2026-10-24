class_name HorseBody
extends CharacterBody2D

#@export var forward_thrust: float = 150.0
var stats: HorseStats
var straightaway_boost: float = 1.0
func set_horse(horse: HorseStats) -> void:
	$Cyn.texture.atlas = HorseDb.MainDb.horses[horse.horse_info].sprite_sheet.duplicate(true)
	stats = horse
func _ready() -> void:
	randomize_angle()
func randomize_angle() -> void:
	velocity = Vector2(randf_range(-100, 100), randf_range(-100, 100)).normalized() * stats.speed * 55
	
func _physics_process(delta: float) -> void:
	var collision := move_and_collide(velocity * delta * straightaway_boost)
	straightaway_boost += 0.1 * (stats.power - 0.9)
	if collision:
		straightaway_boost = 1.0
		velocity = velocity.bounce(collision.get_normal())
		return
		$AudioStreamPlayer2D.play()

func _on_body_entered(_body: Node) -> void:
	randomize_angle()
