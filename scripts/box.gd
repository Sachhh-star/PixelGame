extends Area2D

signal collected

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var collected_sound: AudioStreamPlayer2D = $CollectedSound

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.alive:
		collected.emit()
		call_deferred("_disable_collision_and_play")

func _disable_collision_and_play() -> void:
	collision_shape_2d.disabled = true
	hide()
	collected_sound.play()
	await collected_sound.finished
	queue_free()
