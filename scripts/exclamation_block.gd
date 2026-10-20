extends Area2D

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var collected_sound: AudioStreamPlayer2D = $CollectedSound
@onready var sprite_2d: Sprite2D = $Sprite2D

signal collected

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.alive:
		collected_sound.play()
		collected.emit()
		call_deferred("_disable_collision")
		
		# Nicely fade out and free
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		tween.tween_callback(queue_free)

func _disable_collision() -> void:
	collision_shape_2d.disabled = true
