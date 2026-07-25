extends Node2D

@export var enemy_scene : PackedScene
@onready var spawn_timer = $SpawnTimer

var current_wave: int = 1
var enemies_left_to_spawn: int =5
var spawn_cooldown: float = 5.0


# Called when the node enters the scene tree for the first time.
func _ready():
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	start_next_wave()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func start_next_wave():
	print("starting wave", current_wave)
	$CanvasLayer/WaveCounterLabel.text = "Wave: " + str(current_wave)
	
	enemies_left_to_spawn = 5 + (current_wave + 2)
	spawn_cooldown = max(0.4, 1.5-(current_wave * 0.1))
	spawn_timer.wait_time = spawn_cooldown
	spawn_timer.start()
	

func _on_spawn_timer_timeout():
	if enemies_left_to_spawn > 0:
		spawn_enemy()
		enemies_left_to_spawn -= 1
	else:
		spawn_timer.stop()
		check_wave_clear_loop()

func spawn_enemy():
	if not enemy_scene : return
	
	var enemy_instance = enemy_scene.instantiate()
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		var random_direction = Vector2.RIGHT.rotated(randf_range(0,2*PI))
		var spawn_distance = 800
		enemy_instance.global_position = player.global_position + (random_direction * spawn_distance)
	get_tree().current_scene.add_child(enemy_instance)

func check_wave_clear_loop():
	await get_tree().create_timer(1.0).timeout
	
	var active_enemies = get_tree().get_nodes_in_group("enemies")
	
	if active_enemies.size() == 0:
		current_wave += 1
		print("Wave cleared! Next wave coming up...")
		await get_tree().create_timer(3.0).timeout
		start_next_wave()
	else:
		check_wave_clear_loop()
