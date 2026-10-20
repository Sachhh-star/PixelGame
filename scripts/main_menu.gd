extends Control


func _on_play_pressed() -> void:
	print("play pressed")
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_quit_pressed() -> void:
	print("quit pressed")
	get_tree().quit()
