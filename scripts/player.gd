extends CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer = $JumpSound
@onready var death_sound: AudioStreamPlayer = $DeathSound
@onready var camera_2d: Camera2D = $Camera2D

signal player_died

var fade_rect: ColorRect
var invulnerable = false



const JUMP_VELOCITY = -750.0
var speed = 200.0
const NORMAL_SPEED = 200.0
var alive = true
var can_move = false

func _ready() -> void:
	add_to_group("player")
	
	if camera_2d:
		camera_2d.make_current()
		camera_2d.zoom = Vector2(2, 2)
		update_camera_limits()
	
	# Only setup local fade if not managed by Main scene
	if get_tree().current_scene.name != "Main":
		setup_fade()
		fade_in()
		# When running level independently, play intro after fade
		await get_tree().create_timer(1.0).timeout
		play_camera_intro()

func update_camera_limits() -> void:
	if not camera_2d:
		return
	
	var tilemap = get_parent().get_node_or_null("TileMapLayer")
	if tilemap:
		var used_rect = tilemap.get_used_rect()
		var tile_size = tilemap.tile_set.tile_size
		var cell_size = tilemap.scale * Vector2(tile_size)
		
		var left = tilemap.position.x + used_rect.position.x * cell_size.x
		var right = tilemap.position.x + used_rect.end.x * cell_size.x
		var top = tilemap.position.y + used_rect.position.y * cell_size.y
		var bottom = tilemap.position.y + used_rect.end.y * cell_size.y
		
		# Set limits dynamically based on TileMapLayer bounds
		camera_2d.limit_left = int(left)
		camera_2d.limit_right = int(right)
		camera_2d.limit_top = int(top)
		camera_2d.limit_bottom = int(bottom)
		
		# Expand the background TextureRect to fully cover the tilemap bounds nicely
		var texture_rect = get_parent().get_node_or_null("TextureRect")
		if texture_rect:
			var padding = 600.0  # Extra margin so edges are never visible
			texture_rect.position = Vector2(left - padding, top - padding)
			texture_rect.size = Vector2((right - left) + padding * 2, (bottom - top) + padding * 2)
			print("Expanded background TextureRect to cover level bounds.")
		
		print("Dynamic camera limits set: L=", camera_2d.limit_left, " R=", camera_2d.limit_right, " T=", camera_2d.limit_top, " B=", camera_2d.limit_bottom)
	else:
		# Fallback to default limits if tilemap is not found
		camera_2d.limit_top = -820
		camera_2d.limit_left = 0
		camera_2d.limit_right = 100000
		camera_2d.limit_bottom = 3000

func play_camera_intro() -> void:
	if not camera_2d:
		can_move = true
		return
	
	var exit = get_parent().get_node_or_null("Exit")
	if not exit:
		can_move = true
		return
	
	can_move = false
	
	var original_zoom = camera_2d.zoom
	var original_local_pos = camera_2d.position
	
	# Step 1: Zoom in on the player
	var zoom_in_tween = create_tween()
	zoom_in_tween.tween_property(camera_2d, "zoom", Vector2(3.0, 3.0), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await zoom_in_tween.finished
	
	await get_tree().create_timer(0.4).timeout
	
	# Step 2: Pan to exit and zoom out to 1.8 to show exit surroundings
	var exit_local_pos = exit.global_position - global_position
	var pan_to_exit_tween = create_tween().set_parallel(true)
	pan_to_exit_tween.tween_property(camera_2d, "position", exit_local_pos, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pan_to_exit_tween.tween_property(camera_2d, "zoom", Vector2(1.8, 1.8), 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await pan_to_exit_tween.finished
	
	# Step 3: Pause at exit
	await get_tree().create_timer(1.2).timeout
	
	# Step 4: Pan back to player and restore gameplay zoom
	var pan_back_tween = create_tween().set_parallel(true)
	pan_back_tween.tween_property(camera_2d, "position", original_local_pos, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pan_back_tween.tween_property(camera_2d, "zoom", original_zoom, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await pan_back_tween.finished
	
	# Step 5: Enable movement
	can_move = true

func setup_fade() -> void:
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_layer.add_child(fade_rect)

func fade_in() -> void:
	fade_rect.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 1.0)

func fade_out() -> void:
	fade_rect.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 1.5)
	await tween.finished

var jump_count = 0
const MAX_JUMPS = 2

func _physics_process(delta: float) -> void:
	if !alive:
		return
		
	# Add animation
	if velocity.x > 1 or velocity.x < -1:
		animated_sprite_2d.animation = "running"
	else:
		animated_sprite_2d.animation = "idle"
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		animated_sprite_2d.animation = "jumping"
	else:
		jump_count = 0 # Reset jumps when on floor

	# Fall detection
	if position.y > 1000:
		die()

	if can_move:
	# Handle jump.
		if Input.is_action_just_pressed("jump") and jump_count < MAX_JUMPS:
			velocity.y = JUMP_VELOCITY
			jump_sound.play()
			jump_count += 1

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var direction := Input.get_axis("left", "right")
		if direction:
			velocity.x = direction * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)

		move_and_slide()
		
		if direction == 1.0:
			animated_sprite_2d.flip_h = false
		elif direction == -1.0:
			animated_sprite_2d.flip_h = true

func die() -> void:
	if not alive:
		return
	
	alive = false
	death_sound.play()
	animated_sprite_2d.animation = "dying"
	
	# Emit signal so Main.gd or other listeners know we died
	emit_signal("player_died", self)
	
	print("Player died!")
	
	print("Player died!")
	
	# If running independently (not via Main), handle restart locally
	if get_tree().current_scene.name != "Main":
		await fade_out()
		GameState.decrease_health(get_tree())

func take_damage() -> void:
	if not alive or invulnerable:
		return
		
	GameState.lives -= 1
	print("Player took damage! Lives remaining: ", GameState.lives)
	
	if GameState.lives <= 0:
		die()
	else:
		_start_invulnerability()

func _start_invulnerability() -> void:
	invulnerable = true
	
	# Blink effect: toggle visibility/opacity
	var blink_tween = create_tween()
	for i in range(5):
		blink_tween.tween_property(animated_sprite_2d, "modulate:a", 0.2, 0.1)
		blink_tween.tween_property(animated_sprite_2d, "modulate:a", 1.0, 0.1)
	
	await blink_tween.finished
	invulnerable = false

func bounce() -> void:
	# Give player a small bounce when jumping on enemy
	velocity.y = JUMP_VELOCITY * 0.5
	jump_sound.play()

func apply_speed_boost(duration: float) -> void:
	speed = 600.0 # Double speed
	print("Speed boost activated!")
	
	# Create a timer to reset speed
	var timer = get_tree().create_timer(duration)
	await timer.timeout
	
	speed = NORMAL_SPEED
	print("Speed boost ended.")
