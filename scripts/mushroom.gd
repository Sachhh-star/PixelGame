extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var death_sound: AudioStreamPlayer = $DeathSound

signal enemy_defeated

@export var speed: float = 0.0
var direction = 1.0
var is_alive = true

func _ready() -> void:
	speed = 0.0

func _process(delta: float) -> void:
	if is_alive:
		position.x += direction * speed * delta

func _on_timer_timeout() -> void:
	if is_alive:
		direction *= -1
		animated_sprite_2d.flip_h = !animated_sprite_2d.flip_h

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.alive and is_alive:
		# Check if player is jumping on top of the mushroom (falling down)
		# Allow a small tolerance (e.g. +10 pixels) because Mushroom is short
		if body.velocity.y > 0 and body.position.y < position.y + 10:
			die()
			body.bounce()
			emit_signal("enemy_defeated")
		else:
			body.die()

func die() -> void:
	is_alive = false
	death_sound.play()
	if animated_sprite_2d.sprite_frames.has_animation("hit"):
		animated_sprite_2d.play("hit")
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
