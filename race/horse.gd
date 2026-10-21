class_name HorseBody
extends CharacterBody2D

@export var forward_thrust: float = 150.0
var map_sprite: Sprite2D
var stats: HorseStats
var straightaway_boost: float = 1.0
func set_horse(horse: HorseStats) -> void:
	$Cyn.texture.atlas = HorseDb.MainDb.horses[horse.horse_info].sprite_sheet.duplicate(true)
	stats = horse
func _ready() -> void:
	randomize_angle()
func randomize_angle() -> void:
	velocity = Vector2(randf_range(-100, 100), randf_range(-100, 100)).normalized() * stats.speed * 100
	
func _physics_process(delta: float) -> void:
		#get_colliding_bodies()[0].get_angle_to(position)
	var i := 0
	while is_touching_wall(transform.origin + velocity * delta * straightaway_boost) and i < 20:
		velocity = Vector2(randf_range(-100, 100), randf_range(-100, 100)).normalized() * stats.speed * 100
		straightaway_boost = 1.0
		i += 1
	#if i == 30: return
	var collision := move_and_collide(velocity * delta * straightaway_boost)
	straightaway_boost += 0.1
	if collision:
		straightaway_boost = 1.0
		velocity = velocity.bounce(collision.get_normal())
		return
		#velocity = velocity.bounce(collision.get_normal())
func is_touching_wall(pos: Vector2) -> bool:
	if not map_sprite or not map_sprite.texture:
		return false
		
	var image := map_sprite.texture.get_image()
	if not image:
		return false
		
	if image.is_compressed():
		image.decompress()
		
	var local_pos := map_sprite.to_local(pos)
	if map_sprite.centered:
		local_pos += image.get_size() / 2.0
	var margin := 13
	if local_pos.x - margin < 0 or local_pos.y - margin < 0 or local_pos.x + margin >= image.get_width() or local_pos.y + margin >= image.get_height():
		return true
		
	var pixel_color0 := image.get_pixel(int(local_pos.x - margin), int(local_pos.y - margin))
	var pixel_color1 := image.get_pixel(int(local_pos.x - margin), int(local_pos.y + margin))
	var pixel_color2 := image.get_pixel(int(local_pos.x + margin), int(local_pos.y - margin))
	var pixel_color3 := image.get_pixel(int(local_pos.x + margin), int(local_pos.y + margin))
	return [pixel_color0, pixel_color1, pixel_color2, pixel_color3].any(func(x: Color) -> bool: return x.a > 0.5)


func _on_body_entered(body: Node) -> void:
	randomize_angle()
