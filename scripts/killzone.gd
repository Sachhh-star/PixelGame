extends Area2D
@onready var timer: Timer = $Timer


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Killzone hit!")
		body.die()
		# Main.gd or player.gd will handle the restart
