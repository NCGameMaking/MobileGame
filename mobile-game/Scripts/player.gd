extends CharacterBody2D

enum GunType { PISTOL, SHOTGUN, MACHINE_GUN, KNIFE}

@export var speed: float = 300.0
@export var bullet_scene : PackedScene

@export var max_health: int = 100.0
var current_health: int

@export var aim_line: Line2D
@export var muzzle: Marker2D

@onready var pistol_sprite = $PistolSprite
@onready var machine_gun_sprite = $MachineGunSprite
@onready var shotgun_sprite = $ShotgunSprite
@onready var reload_bar = $UI/Panel/ReloadBar

@onready var pistol_ammo_label = $UI/Panel/VBoxContainer/PistolAmmoLabel
@onready var shotgun_ammo_label = $UI/Panel/VBoxContainer/ShotgunAmmoLabel
@onready var machine_gun_ammo_label = $UI/Panel/VBoxContainer/MachineGunAmmoLabel

@onready var scene_filter = $SceneFilter
@onready var death_ui = $DeathUI
@onready var camera = $Camera2D

@onready var pistol_ui = $UI/Panel/Pistol
@onready var shotgun_ui = $UI/Panel/Shotgun
@onready var machine_gun_ui = $UI/Panel/MachineGun

@onready var day_count_label = $DeathUI/DeathPanel/DayCountLabel
@onready var wave_node = $"../WaveManager"

@onready var machine_gun_white_ui = $UI/Panel/MachineGunWhiteUI
@onready var shotgun_white_ui = $UI/Panel/ShotgunWhiteUI
@onready var pistol_white_ui = $UI/Panel/PistolWhiteUI

@onready var healthbar = $UI/Panel/Healthbar
var inactive_gun = Color(0.3, 0.3,0.3, 0.6)

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
var is_knifing: bool = false

func _ready():
	$UI/Panel.show()
	$".".modulate = Color(1,1,1,1)
	current_health = max_health
	update_health_ui()
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
	if Input.is_action_just_pressed("knife") and not is_knifing: start_melee_attack()

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
	reload_bar.value = 0
	reload_bar.visible = true
	var tween = create_tween()
	
	var reload_time = gun_stats[current_gun]["reload_time"]
	
	tween.tween_property(reload_bar, "value", 100.0, reload_time)
	
	is_reloading = true
	print("Reloading weapon...")
	update_weapon_sprites()
	update_ammo_ui()

	await get_tree().create_timer(reload_time).timeout

	gun_stats[current_gun]["current_ammo"] = gun_stats[current_gun]["ammo_max"]
	is_reloading = false
	
	update_weapon_sprites()
	update_ammo_ui()

	print("Reloading complete! Ammo: ", current_ammo)
	reload_bar.hide()
	

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
	pistol_ui.modulate = inactive_gun
	shotgun_ui.modulate = inactive_gun
	machine_gun_ui.modulate = inactive_gun
	machine_gun_white_ui.visible = false
	shotgun_white_ui.visible = false
	pistol_white_ui.visible = false
	reload_bar.visible = false

	match current_gun:
		GunType.PISTOL:
			pistol_white_ui.visible = true
			if is_reloading:
				pistol_gun_reload.visible = true
				reload_bar.visible = true
			else:
				pistol_sprite.visible = true
		GunType.SHOTGUN:
			shotgun_white_ui.visible = true
			if is_reloading:
				shotgun_reload.visible = true
				reload_bar.visible = true
			else:
				shotgun_sprite.visible = true
		GunType.MACHINE_GUN:
			machine_gun_white_ui.visible = true
			if is_reloading:
				machine_gun_reload.visible = true
				reload_bar.visible = true
			else:
				machine_gun_sprite.visible = true
		GunType.KNIFE:
			melee_area.visible = true
			

func update_ammo_ui():
	if gun_stats.has(GunType.PISTOL):
		var p_cur = gun_stats[GunType.PISTOL]["current_ammo"]
		var p_max = gun_stats[GunType.PISTOL]["ammo_max"]
		pistol_ammo_label.text = str(p_cur) + "/" + str(p_max)
	if gun_stats.has(GunType.SHOTGUN):
		var s_cur = gun_stats[GunType.SHOTGUN]["current_ammo"]
		var s_max = gun_stats[GunType.SHOTGUN]["ammo_max"]
		shotgun_ammo_label.text = str(s_cur) + "/" + str(s_max)
	if gun_stats.has(GunType.MACHINE_GUN):
		var m_cur = gun_stats[GunType.MACHINE_GUN]["current_ammo"]
		var m_max = gun_stats[GunType.MACHINE_GUN]["ammo_max"]
		machine_gun_ammo_label.text = str(m_cur) + "/" + str(m_max)
		

func start_melee_attack():
	if is_knifing:
		return
	is_knifing = true
	var previous_gun = current_gun
	
	current_gun = GunType.KNIFE
	update_weapon_sprites()
	$AnimationPlayer.play("knifeattack")
	var targets = melee_area.get_overlapping_bodies()
	for target in targets:
		if target.is_in_group("enemies"):
			if target.has_method("take_damage"):
				target.take_damage(3)
	
	await $AnimationPlayer.animation_finished
	
	is_knifing = false
	
	current_gun = previous_gun
	update_weapon_sprites()

func take_damage(amount: int):
	$AnimationPlayer.play("hurt")
	current_health -= amount
	current_health = clamp(current_health,0,max_health)
	
	update_health_ui()
	
	if current_health <= 0:
		die()
	
func update_health_ui():
	if healthbar:
		healthbar.value = current_health
		
func die():
	print("PLayer ded")
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	
	var tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property(camera, "zoom", Vector2(0.5,0.5), 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	if scene_filter:
		tween.tween_property(scene_filter, "color", Color(0.4, 0.4,0.5), 1.5)
	await tween.finished
	
	var wave_node = $"../WaveManager"
	
	print("DEBUG: wave_node is -> ", wave_node)
	
	var completed_waves = 0
	if wave_node != null:
		completed_waves = max(0, wave_node.current_wave - 1)
	day_count_label.text = "You survived for %d waves" % completed_waves
	$UI/Panel.hide()
	$AnimationPlayer.play("death")


func _on_retry_button_pressed():
	get_tree().reload_current_scene()

func _on_quit_button_pressed():
	get_tree().quit()
