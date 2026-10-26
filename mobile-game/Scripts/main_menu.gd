extends Control



func _on_resume_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/test_level.tscn")
	

func _on_quit_button_pressed():
	get_tree().quit()


func _on_ht_pbutton_pressed():
	get_tree().change_scene_to_file("res://Scenes/htp_menu.tscn")
