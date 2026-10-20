extends Area2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var death_sound: AudioStreamPlayer = $DeathSound

signal enemy_defeated

const SPEED = 65.0
var direction = -1.0
var is_alive = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_alive:
		position.x += direction * SPEED * delta


func _on_timer_timeout() -> void:
	if is_alive:
		direction *= -1
		animated_sprite_2d.flip_h = !animated_sprite_2d.flip_h


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.alive and is_alive:
		# Check if player is jumping on top of the snail (falling down)
		if body.velocity.y > 0 and body.position.y < position.y:
			# Player jumped on the snail from above - kill the snail and bounce player
			die()
			body.bounce()
			emit_signal("enemy_defeated")
		else:
			# Player hit from the side - player dies
			body.die()
	#print(body.name)

func die() -> void:
	is_alive = false
	death_sound.play()
	# Play death animation or hide the snail
	animated_sprite_2d.play("hit")
	# Optionally make it disappear
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
