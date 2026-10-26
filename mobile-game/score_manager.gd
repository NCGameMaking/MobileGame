extends Node

signal score_changed(new_score: int)

var score:int=0

func add_points(amount:int):
	score+=amount
	score_changed.emit(score)

func reset_score():
	score=0
	score_changed.emit(score)
	
func get_score()->int:
	return score
