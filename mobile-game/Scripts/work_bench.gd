extends StaticBody2D
var player_in_range :bool=false
var current_player : Node2D=null
@onready var prompt = $UIHUD/Control/Prompt
@onready var uiupgrade = $UIHUD/Control/UIUPGRADE

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_interaction_area_body_entered(body):
	if body.is_in_group("player"):
		player_in_range=true
		current_player=body
		if prompt:
			prompt.show()


func _on_interaction_area_body_exited(body):
	if body == current_player:
		player_in_range=false
		current_player=null
		if prompt:
			prompt.hide()
		if uiupgrade:
			uiupgrade.hide()

func _unhandled_input(event:InputEvent):
	if player_in_range and Input.is_action_just_pressed("interact"):
		if uiupgrade:
			uiupgrade.visible = !uiupgrade.visible
			if uiupgrade.visible:
				if prompt:
					prompt.hide
			else:
				if prompt:
					prompt.show()
