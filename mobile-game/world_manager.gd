extends Node2D

const CHUNK_PIXEL_SIZE: Vector2 = Vector2(1088,1088)

@export var chunk_scenes: Array[PackedScene]
@export var grid_height:int = 3
@export var grid_width: int = 3
@onready var player = $"../Player"
@export var render_distance:int = 2

var loaded_chunks : Dictionary = {}
func _ready():
	generate_world()

func _process(delta):
	if not player or chunk_scenes.is_empty():
		return
	update_chunks_around_player()


func generate_world():
	if chunk_scenes.is_empty():
		print("NO CHUNK SCENES TO WORLD MANAGER")
		return
			
func update_chunks_around_player():
	var player_grid_pos = Vector2i(
		floori(player.global_position.x / CHUNK_PIXEL_SIZE.x),
		floori(player.global_position.y / CHUNK_PIXEL_SIZE.y)
	)

	var needed_chunks: Array[Vector2i] = []

	for x in range(player_grid_pos.x - render_distance, player_grid_pos.x + render_distance + 1):
		for y in range(player_grid_pos.y - render_distance, player_grid_pos.y + render_distance + 1):
			var chunk_coords = Vector2i(x, y)
			needed_chunks.append(chunk_coords)
			
			if not loaded_chunks.has(chunk_coords):
				spawn_chunk(chunk_coords)

	var active_coords = loaded_chunks.keys()
	for coords in active_coords:
		if not coords in needed_chunks:
			unload_chunk(coords)

func spawn_chunk(coords: Vector2i):
	var random_scene = chunk_scenes.pick_random()
	var chunk_instance = random_scene.instantiate()
	chunk_instance.global_position = Vector2(coords.x * CHUNK_PIXEL_SIZE.x, coords.y *CHUNK_PIXEL_SIZE.y)
	
	add_child(chunk_instance)
	loaded_chunks[coords] = chunk_instance

func unload_chunk(coords: Vector2i):
	if loaded_chunks.has(coords):
		loaded_chunks[coords].queue_free()
		loaded_chunks.erase(coords)   
