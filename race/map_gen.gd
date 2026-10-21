extends Node2D

@export var map_texture: Texture2D

@onready var sprite_2d: Sprite2D = $HrtMap1Outline1
@onready var static_body_2d: StaticBody2D = $StaticBody2D

func _ready() -> void:
	if map_texture:
		sprite_2d.texture = map_texture
		generate_outer_boundaries()
		parse_spawn_pixels()

func generate_outer_boundaries() -> void:
	var img_size := map_texture.get_size()
	
	# Automatically build 4 outer walls matching the image dimensions
	create_wall_box(Vector2(img_size.x / 2, -10), Vector2(img_size.x, 20))                 # Top Wall
	create_wall_box(Vector2(img_size.x / 2, img_size.y + 10), Vector2(img_size.x, 20))      # Bottom Wall
	create_wall_box(Vector2(-10, img_size.y / 2), Vector2(20, img_size.y))                 # Left Wall
	create_wall_box(Vector2(img_size.x + 10, img_size.y / 2), Vector2(20, img_size.y))      # Right Wall

func create_wall_box(pos: Vector2, size: Vector2) -> void:
	var collision_shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = size
	collision_shape.shape = rect_shape
	collision_shape.position = pos
	static_body_2d.add_child(collision_shape)

func parse_spawn_pixels() -> void:
	var image := map_texture.get_image()
	if not image:
		return
		
	if image.is_compressed():
		image.decompress()
		
	for x in range(image.get_width()):
		for y in range(image.get_height()):
			var pixel_color := image.get_pixel(x, y)
			
			# Red pixel = Horse spawn
			#if pixel_color.is_equal_approx(Color.RED):
				#spawn_entity("res://scenes/horse.tscn", Vector2(x, y))
				#
			## Blue pixel = Carrot spawn
			#elif pixel_color.is_equal_approx(Color.BLUE):
				#spawn_entity("res://scenes/carrot.tscn", Vector2(x, y))

func spawn_entity(scene_path: String, spawn_position: Vector2) -> void:
	var scene := load(scene_path)
	if scene:
		var instance = scene.instantiate()
		instance.position = spawn_position
		add_child(instance)
