extends CharacterBody2D

@export var speed: float = 130.0
@export var health: int = 12
@export var max_health:int = 12
@onready var avoidance_area = $AvoidanceArea
@onready var health_bar = $HealthBar

@export var attack_cooldown: float = 1.0
var player_in_range: CharacterBody2D=null
var is_attacking: bool = false

var player: CharacterBody2D = null
var sb: StyleBoxFlat

func _ready():
	sb = health_bar.get_theme_stylebox("fill").duplicate()
	health_bar.visible = false
	add_to_group("enemies")
	
	var players = get_tree().get_nodes_in_group("player")
	
	if players.size() > 0:
		player = players[0]

func _physics_process(delta: float):
	if not player:
		return

	var target_direction = (player.global_position - global_position).normalized()

	var separation_force = Vector2.ZERO
	var neighbours = avoidance_area.get_overlapping_bodies()
	
	for neighbour in neighbours:
		if neighbour != self and neighbour.is_in_group("enemies"):
			var push_away_dir = global_position - neighbour.global_position
			
			var distance = push_away_dir.length()
			separation_force += push_away_dir.normalized() / (distance + 0.1)
	
	
	var final_direction = (target_direction + (separation_force * 300)).normalized()
	var target_velocity = final_direction * speed
	velocity = velocity.lerp(target_velocity, 10*delta)
		
	look_at(player.global_position)
		
	move_and_slide()
	
	if health_bar:
		health_bar.rotation = -global_rotation

func take_damage(amount: int):
	health -= amount
	health_bar.value = health
	health_bar.visible = true
	
	var health_pt: float = float(health)
	
	if health_pt >= 9:
		sb.bg_color = Color(0,1,0)
	elif health_pt >=6:
		sb.bg_color = Color(1,0.65,0)
	else:
		sb.bg_color = Color(1,0,0)
		
	health_bar.add_theme_stylebox_override("fill", sb)
	
	print("zombie hit")
	if health <= 0:
		queue_free()
		print("zombie dead")

func _on_attack_area_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = body
		if not is_attacking:
			attack_loop()
			print("hurt_player")


func _on_attack_area_body_exited(body):
	if body == player_in_range:
		player_in_range = null

func attack_loop():
	is_attacking = true
	while player_in_range != null and is_instance_valid(player_in_range):
		if is_instance_valid(player_in_range) and player_in_range.has_method("take_damage"):
			player_in_range.take_damage(10)
		
		if is_inside_tree():
			await get_tree().create_timer(attack_cooldown).timeout
		else:
			return
	is_attacking = false
