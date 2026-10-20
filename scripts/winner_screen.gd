extends CanvasLayer

signal play_again
signal quit_game

func _on_play_again_pressed() -> void:
	play_again.emit()

func _on_quit_pressed() -> void:
	quit_game.emit()
