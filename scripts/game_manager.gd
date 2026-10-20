extends Node

var lives: int = 3

func decrease_health() -> void:
	lives -= 1
	print("Lives remaining: ", lives)
	
	if lives > 0:
		reload_scene()
	else:
		reset_game()

func reload_scene() -> void:
	# Restart the current level
	get_tree().reload_current_scene()

func reset_game() -> void:
	print("Game Over! Resetting lives.")
	lives = 3
	# In a full game, this might go to a Game Over screen or Main Menu
	# For now, we'll just restart the current level with full lives
	get_tree().reload_current_scene()
