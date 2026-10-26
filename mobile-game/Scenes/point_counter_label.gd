extends Label


# Called when the node enters the scene tree for the first time.
func _ready():
	ScoreManager.score_changed.connect(_on_score_changed)
	text="Points: "+str(ScoreManager.get_score())
func _on_score_changed(new_score:int):
	text="Points: " + str(new_score)
