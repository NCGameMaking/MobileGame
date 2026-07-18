extends Area2D

@export var speed: float = 1000.0
var direction: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
