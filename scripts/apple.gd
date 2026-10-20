extends Area2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collected_sound: AudioStreamPlayer2D = $CollectedSound
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

signal collected

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.alive:
		animated_sprite_2d.animation = "collected"
		collected_sound.play()
		collected.emit()
		call_deferred("_disable_collistion")

func _disable_collistion() -> void:
	collision_shape_2d.disabled = true


func _on_animated_sprite_2d_animation_looped() -> void:
	if animated_sprite_2d.animation == "collected":
		queue_free()
