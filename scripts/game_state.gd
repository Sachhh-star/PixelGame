class_name GameState
extends Node

static var lives: int = 3

static func decrease_health(tree: SceneTree) -> void:
	lives -= 1
	print("Lives remaining: ", lives)
	
	if lives > 0:
		tree.reload_current_scene()
	else:
		reset_game(tree)

static func increase_health() -> void:
	if lives < 3:
		lives += 1
		print("Lives increased: ", lives)

static func reset_game(tree: SceneTree) -> void:
	print("Game Over! Resetting lives.")
	lives = 3
	tree.reload_current_scene()
