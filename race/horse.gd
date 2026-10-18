extends RigidBody2D

@export var forward_thrust: float = 150.0
@onready var map_sprite: Sprite2D = $"../Node2D/HrtMap1Outline1"

func _ready() -> void:
	randomize_angle()
func randomize_angle() -> void:
	#var space_state = get_world_2d().direct_space_state
	#var result: Dictionary = {}
	#while not result.collider:
		#var query = PhysicsRayQueryParameters2D.create(Vector2(0, 0), Vector2(50, 100))
		#result = space_state.intersect_ray(query)
	linear_velocity = Vector2(randf_range(-100, 100), randf_range(-100, 100)).normalized() * 100
	
func _physics_process(delta: float) -> void:
	if (get_contact_count() > 0):
		randomize_angle()
		#get_colliding_bodies()[0].get_angle_to(position)
	while is_touching_wall(transform.origin + linear_velocity*delta):
		linear_velocity = Vector2(randf_range(-100, 100), randf_range(-100, 100)).normalized() * 100

func is_touching_wall(pos: Vector2) -> bool:
	if not map_sprite or not map_sprite.texture:
		return false
		
	var image = map_sprite.texture.get_image()
	if not image:
		return false
		
	if image.is_compressed():
		image.decompress()
		
	var local_pos = map_sprite.to_local(pos)
	if map_sprite.centered:
		local_pos += image.get_size() / 2.0
	var margin := 13
	if local_pos.x-margin < 0 or local_pos.y-margin < 0 or local_pos.x+margin >= image.get_width() or local_pos.y +margin >= image.get_height():
		return true
		
	var pixel_color0 = image.get_pixel(int(local_pos.x-margin), int(local_pos.y-margin))
	var pixel_color1 = image.get_pixel(int(local_pos.x-margin), int(local_pos.y+margin))
	var pixel_color2 = image.get_pixel(int(local_pos.x+margin), int(local_pos.y-margin))
	var pixel_color3 = image.get_pixel(int(local_pos.x+margin), int(local_pos.y+margin))
	return [pixel_color0, pixel_color1, pixel_color2, pixel_color3].any(func (x: Color): return x.a > 0.5)



func _on_body_entered(body: Node) -> void:
	randomize_angle()
