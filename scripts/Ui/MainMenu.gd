extends Control


func loadGame():
	get_tree().change_scene_to_file("res://Scenes/main scene.tscn")
func exitGame():
	get_tree().quit()
