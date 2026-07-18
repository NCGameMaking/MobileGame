extends CharacterBody2D

enum GunType { PISTOL, SHOTGUN, MACHINE_GUN, KNIFE}

@export var speed: float = 300.0
@export var bullet_scene : PackedScene

@export var aim_line: Line2D
@export var muzzle: Marker2D

@onready var pistol_sprite = $PistolSprite
@onready var machine_gun_sprite = $MachineGunSprite
@onready var shotgun_sprite = $ShotgunSprite
@onready var ammo_label = $UI/AmmoLabel

@onready var machine_gun_reload = $MachineGunReload
@onready var pistol_gun_reload = $PistolGunReload
@onready var shotgun_reload = $ShotgunReload
@onready var melee_area = $MeleeArea


var gun_stats = {
	GunType.PISTOL: {"current_ammo": 7, "ammo_max": 7, "reload_time": 1.0, "spread": 0, "projectiles": 1, "is_automatic": false, "is_melee": false},
	GunType.SHOTGUN: {"current_ammo": 2, "ammo_max": 2, "reload_time": 2.0, "spread": 0.22, "projectiles": 5, "is_automatic": false, "is_melee": false},
	GunType.KNIFE: {"current_ammo": 1, "ammo_max": 1, "reload_time": 0.4, "spread": 0, "projectiles": 0, "is_automatic": false, "is_melee": true},
	GunType.MACHINE_GUN: {"current_ammo": 30, "ammo_max": 30, "reload_time": 2.2, "spread": 0.08, "projectiles": 1, "is_automatic": true, "is_melee": false}
}

var current_gun: GunType = GunType.PISTOL
var current_ammo: int = 7
var is_reloading: bool = false
var is_aiming = false
var machine_gun_cooldown: bool = false

func _ready():
	update_weapon_sprites()
	update_ammo_ui()

func _physics_process(delta: float):
	var input_direction = Input.get_vector("backward","forward","up", "down")
	velocity = input_direction * speed
	move_and_slide()
	
	handle_test_aiming()
	
	if Input.is_key_pressed(KEY_1): switch_weapon(GunType.PISTOL)
	if Input.is_key_pressed(KEY_2): switch_weapon(GunType.SHOTGUN)
	if Input.is_key_pressed(KEY_3): switch_weapon(GunType.MACHINE_GUN)
	if Input.is_key_pressed(KEY_Q): switch_weapon(GunType.KNIFE)

	if Input.is_key_pressed(KEY_R) and not is_reloading: start_reload()


func handle_test_aiming():
	var stats = gun_stats[current_gun]
	var input_detected: bool = false
	look_at(get_global_mouse_position())

	if Input.is_action_pressed("shoot"):
		if not is_reloading:
			is_aiming = true
			aim_line.visible = true
			look_at(get_global_mouse_position())
			
			if stats["is_automatic"]:
				shoot_current_gun()
		
	else:
		if is_aiming:
			if not stats["is_automatic"] and not is_reloading:
				shoot_current_gun()
			is_aiming = false
			await get_tree().create_timer(1.0).timeout
			aim_line.visible = false

func shoot_current_gun() -> void:
	
	var stats = gun_stats[current_gun]

	if not bullet_scene or current_ammo <= 0 or is_reloading:
		return
	
	if stats["is_automatic"] and machine_gun_cooldown:
		return
	if stats.has("is_melee") and stats["is_melee"]:
			start_melee_attack()
			return
	stats["current_ammo"] -= 1
	update_ammo_ui()
	
	if stats["current_ammo"] == 0:
		start_reload()

	if stats["is_automatic"]:
		machine_gun_cooldown = true
		get_tree().create_timer(0.1).timeout.connect(func(): machine_gun_cooldown = false)
	

		
	var global_mouse = get_global_mouse_position()
	var raw_direction = (global_mouse - global_position).normalized()

	for i in range(stats["projectiles"]):
		var bullet = bullet_scene.instantiate()
		bullet.global_position = muzzle.global_position  # <-- use muzzle, not player center + 30
		
		var final_direction = raw_direction
		if current_gun == GunType.SHOTGUN and stats["projectiles"] > 1:
			var fraction = float(i) / float(stats["projectiles"] - 1)
			var spread_offset = lerp(-stats["spread"], stats["spread"], fraction)
			final_direction = raw_direction.rotated(spread_offset)
		else:
			if stats["spread"] > 0.0:
				var random_offset = randf_range(-stats["spread"], stats["spread"])
				final_direction = raw_direction.rotated(random_offset)
		
		bullet.direction = final_direction
		bullet.global_rotation = bullet.direction.angle()
		get_tree().current_scene.add_child(bullet)

func start_reload() -> void:
	is_reloading = true
	print("Reloading weapon...")
	update_weapon_sprites()
	update_ammo_ui()
	
	await get_tree().create_timer(gun_stats[current_gun]["reload_time"]).timeout

	gun_stats[current_gun]["current_ammo"] = gun_stats[current_gun]["ammo_max"]
	is_reloading = false
	
	update_weapon_sprites()
	update_ammo_ui()

	print("Reloading complete! Ammo: ", current_ammo)
	

func switch_weapon(new_gun: GunType) -> void:
	if current_gun == new_gun or is_reloading: return
	current_gun = new_gun
	current_ammo = gun_stats[current_gun]["ammo_max"]
	
	update_weapon_sprites()
	update_ammo_ui()
	print("Switched to: ", GunType.keys()[new_gun])


func update_weapon_sprites():
	pistol_sprite.visible = false
	shotgun_sprite.visible = false
	machine_gun_sprite.visible = false
	pistol_gun_reload.visible = false
	shotgun_reload.visible = false
	machine_gun_reload.visible = false
	melee_area.visible = false
	
	
	match current_gun:
		GunType.PISTOL:
			if is_reloading:
				pistol_gun_reload.visible = true
			else:
				pistol_sprite.visible = true
		GunType.SHOTGUN:
			if is_reloading:
				shotgun_reload.visible = true
			else:
				shotgun_sprite.visible = true
		GunType.MACHINE_GUN:
			if is_reloading:
				machine_gun_reload.visible = true
			else:
				machine_gun_sprite.visible = true
		GunType.KNIFE:
			melee_area.visible = true

func update_ammo_ui():
	if ammo_label:
		if is_reloading:
			ammo_label.text = "RELOADING..."
		else:
			var weapon_name = GunType.keys()[current_gun]
			var current_bullets = gun_stats[current_gun]["current_ammo"]
			var max_capacity = gun_stats[current_gun]["ammo_max"]
			ammo_label.text = weapon_name + ": " + str(current_bullets) + " / " + str(max_capacity)

func start_melee_attack():
	is_reloading = true
	$AnimationPlayer.play("knifeattack")
	var targets = melee_area.get_overlapping_bodies()
	for target in targets:
		if target.is_in_group("enemies"):
			if target.has_method("take_damage"):
				target.take_damage(2)
	
	await $AnimationPlayer.animation_finished
	
	is_reloading = false
	
