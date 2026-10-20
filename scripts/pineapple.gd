extends Area2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var collected_sound: AudioStreamPlayer2D = $CollectedSound

signal collected

func _on_body_entered(_body: Node2D) -> void:
	animated_sprite_2d.animation = "collected"
	collected_sound.play()
	collected.emit()
	call_deferred("_disable_collision")


func _disable_collision() -> void:
	collision_shape_2d.disabled = true
	
