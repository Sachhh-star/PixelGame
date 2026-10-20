extends Node2D
@onready var score_label: Label = $HUD/ScorePanel/ScoreLabel
@onready var fade: ColorRect = $HUD/Fade
@onready var background_music: AudioStreamPlayer = $BackgroundMusic

const APPLE_SCENE = preload("res://scenes/apple.tscn")
const MUSHROOM_SCENE = preload("res://scenes/mushroom.tscn")
const BEE_SCENE = preload("res://scenes/bee.tscn")
const COIN_SCENE = preload("res://scenes/coin.tscn")
const BOX_SCENE = preload("res://scenes/box.tscn")

var level: int = 1
var score: int = 0
var current_level_root: Node = null
var last_intro_level: int = 0

var lives_label: Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Setup the level
	fade.modulate.a = 1.0
	current_level_root = get_node("LevelRoot")
	_setup_lives_ui()
	update_lives_ui()
	await _load_level(level, true, false)
	
	#----------
	#level mangement
	#----------


func _setup_lives_ui() -> void:
	lives_label = Label.new()
	lives_label.name = "LivesLabel"
	# Position simply below score or top right. 
	# Assuming default font/theme.
	lives_label.position = Vector2(20, 60)
	lives_label.modulate = Color(1, 1, 1, 1) # White
	$HUD.add_child(lives_label)
	_setup_speed_timer_ui()

var speed_timer_label: Label
var speed_boost_timer: float = 0.0

func _setup_speed_timer_ui() -> void:
	speed_timer_label = Label.new()
	speed_timer_label.name = "SpeedTimerLabel"
	speed_timer_label.text = ""
	# Position top right (screen width is 1280)
	speed_timer_label.position = Vector2(1100, 60)
	speed_timer_label.add_theme_font_size_override("font_size", 24)
	speed_timer_label.modulate = Color(1, 1, 0, 1) # Yellow
	$HUD.add_child(speed_timer_label)

func update_lives_ui() -> void:
	var hearts = ""
	for i in range(GameState.lives):
		hearts += " ❤️" # Using emoji heart
	lives_label.text = "LIVES:" + hearts


func _load_level(level_number: int, first_load: bool, reset_score) -> void:
	speed_boost_timer = 0.0
	#Fade out
	if not first_load:
		await _fade(1.0)

	if reset_score:
		score = 0
		score_label.text = "SCORE: 0"

	if current_level_root:
		current_level_root.queue_free()
		
	#change level
	var level_path = "res://scenes/Levels/level%s.tscn" % level_number
	current_level_root = load(level_path).instantiate()
	add_child(current_level_root)
	current_level_root.name = "LevelRoot"
	_setup_level(current_level_root)
	
	
	#Fade in
	await _fade(0.0)
	
	var player = _get_player_node()
	if player:
		if level != last_intro_level:
			last_intro_level = level
			if player.has_method("play_camera_intro"):
				await player.play_camera_intro()
		else:
			# Skip camera pan on level restarts to let the player try again quickly
			player.can_move = true

func _setup_level(level_root: Node) -> void:
	_spawn_items_dynamically(level_root)
	#Connect Exit
	var exit = level_root.get_node_or_null("Exit")
	if exit:
		if exit.has_signal("body_entered"):
			if not exit.body_entered.is_connected(_on_exit_body_entered):
				exit.body_entered.connect(_on_exit_body_entered)
	
	# Connect all signals recursively
	_connect_signals_recursively(level_root)

	# Connect Player
	var player = _get_player_node()
	if player:
		if player.has_signal("player_died"):
			if not player.player_died.is_connected(_on_player_died):
				player.player_died.connect(_on_player_died)
				print("Connected player signal")

func _connect_signals_recursively(node: Node) -> void:
	if node.has_signal("collected"):
		var nname = node.name.to_lower()
		if nname.contains("apple"):
			if not node.collected.is_connected(_on_apple_collected):
				node.collected.connect(_on_apple_collected)
				print("Recursively connected Apple: ", node.name)
		elif nname.contains("coin"):
			if not node.collected.is_connected(_on_coin_collected):
				node.collected.connect(_on_coin_collected)
				print("Recursively connected Coin: ", node.name)
		elif nname.contains("box") or nname.contains("crate"):
			if not node.collected.is_connected(_on_box_collected):
				node.collected.connect(_on_box_collected.bind(node))
				print("Recursively connected Box: ", node.name)
		elif nname.contains("question"):
			if not node.collected.is_connected(_on_question_block_collected):
				node.collected.connect(_on_question_block_collected.bind(node))
				print("Recursively connected Question Block: ", node.name)
		elif nname.contains("exclamation"):
			if not node.collected.is_connected(_on_exclamation_block_collected):
				node.collected.connect(_on_exclamation_block_collected.bind(node))
				print("Recursively connected Exclamation Block: ", node.name)
				
	if node.has_signal("enemy_defeated"):
		if not node.enemy_defeated.is_connected(increase_score):
			node.enemy_defeated.connect(increase_score)
			print("Recursively connected Enemy Defeated: ", node.name)
			
	if node.has_signal("player_died"):
		if not node.is_in_group("player"):
			if not node.player_died.is_connected(_on_player_died):
				node.player_died.connect(_on_player_died)
				print("Recursively connected Hazard: ", node.name)
				
	for child in node.get_children():
		_connect_signals_recursively(child)


#------------

#------------
func _on_exit_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		level += 1
		#print(level)
		body.can_move = false
		
		if level > 8:
			_load_end_screen()
		else:
			await _load_level(level, false, false)

func _load_end_screen() -> void:
	if current_level_root:
		current_level_root.queue_free()
		
	#Fade out
	await _fade(1.0)
	
	var end_scene = load("res://scenes/you_win.tscn").instantiate()
	add_child(end_scene)
	current_level_root = end_scene # Track it so we can remove it on restart
	
	# Connect signals
	end_scene.play_again.connect(_on_end_play_again)
	end_scene.quit_game.connect(_on_quit_pressed)

	#Fade in
	await _fade(0.0)

func _on_end_play_again() -> void:
	GameState.lives = 3
	update_lives_ui()
	level = 1
	score = 0
	last_intro_level = 0
	await _load_level(level, true, true)


func _on_player_died(body):
	speed_boost_timer = 0.0
	body.die()
	
	GameState.lives -= 1
	update_lives_ui()
	print("Main: Lives remaining: ", GameState.lives)
	
	if GameState.lives > 0:
		# Restart current level
		await _load_level(level, false, false)
	else:
		# Game Over - Reset to Level 1
		print("Main: Game Over!")
		
		# Show Game Over UI
		if not game_over_container:
			_setup_game_over_ui()
		game_over_container.visible = true
		
		# Ensure mouse is visible and can interact
		# (Though usually Mouse is visible in 2D anyway unless hidden)

var game_over_container: Control

func _setup_game_over_ui() -> void:
	# Container to hold everything
	game_over_container = Control.new()
	game_over_container.name = "GameOverContainer"
	game_over_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$HUD.add_child(game_over_container)
	
	# Semi-transparent background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_container.add_child(bg)
	
	# Center Container for alignment
	var center_cont = CenterContainer.new()
	center_cont.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_container.add_child(center_cont)
	
	# VBox for vertical stacking
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	center_cont.add_child(vbox)
	
	# Label
	var label = Label.new()
	label.text = "YOU LOSE"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 64)
	label.modulate = Color(1, 0, 0, 1)
	vbox.add_child(label)
	
	# Play Again Button
	var btn_play = Button.new()
	btn_play.text = "PLAY AGAIN"
	btn_play.add_theme_font_size_override("font_size", 32)
	btn_play.pressed.connect(_on_play_again_pressed)
	vbox.add_child(btn_play)
	
	# Quit Button
	var btn_quit = Button.new()
	btn_quit.text = "QUIT"
	btn_quit.add_theme_font_size_override("font_size", 32)
	btn_quit.pressed.connect(_on_quit_pressed)
	vbox.add_child(btn_quit)

func _on_play_again_pressed() -> void:
	game_over_container.visible = false
	GameState.lives = 3
	update_lives_ui()
	level = 1
	score = 0
	last_intro_level = 0
	await _load_level(level, true, true)

func _on_quit_pressed() -> void:
	get_tree().quit()


func add_points(amount: int) -> void:
	score += amount
	score_label.text = "SCORE : %s" % score

func increase_score() -> void:
	add_points(1)

func _get_player_node() -> Node:
	if current_level_root:
		var p = current_level_root.get_node_or_null("player")
		if p:
			return p
		return current_level_root.get_node_or_null("Player")
	return null

func _connect_block_signals(node: Node) -> void:
	if node.has_signal("collected"):
		if node.name.begins_with("QuestionBlock") or node.name.contains("question") or node.name.contains("Question"):
			if not node.collected.is_connected(_on_question_block_collected):
				node.collected.connect(_on_question_block_collected.bind(node))
				print("Connected Question Block: ", node.name)
		elif node.name.begins_with("ExclamationBlock") or node.name.contains("exclamation") or node.name.contains("Exclamation"):
			if not node.collected.is_connected(_on_exclamation_block_collected):
				node.collected.connect(_on_exclamation_block_collected)
				print("Connected Exclamation Block: ", node.name)
		elif node.name.contains("Coin") or node.name.contains("coin"):
			if not node.collected.is_connected(_on_coin_collected):
				node.collected.connect(_on_coin_collected)
				print("Connected Coin: ", node.name)
		elif node.name.contains("box") or node.name.contains("Box") or node.name.contains("Crate") or node.name.contains("crate"):
			if not node.collected.is_connected(_on_box_collected):
				node.collected.connect(_on_box_collected.bind(node))
				print("Connected Box: ", node.name)

func _on_apple_collected() -> void:
	# Apple only restores 1 heart/life
	GameState.increase_health()
	print("Apple collected: +1 heart/life")

func _on_coin_collected() -> void:
	# Coin gives +2 score points
	add_points(2)
	print("Coin collected: +2 score")

func _on_box_collected(box: Node2D) -> void:
	var roll = randf()
	var spawned_obj: Node2D = null
	
	if roll <= 0.5:
		# 50% Coin
		spawned_obj = COIN_SCENE.instantiate()
		spawned_obj.collected.connect(_on_coin_collected)
		print("Box spawned: Coin (50% chance)")
	elif roll <= 0.8:
		# 30% Apple
		spawned_obj = APPLE_SCENE.instantiate()
		spawned_obj.collected.connect(_on_apple_collected)
		print("Box spawned: Apple (30% chance)")
	else:
		# 20% Bee
		spawned_obj = BEE_SCENE.instantiate()
		if spawned_obj.has_signal("enemy_defeated"):
			spawned_obj.enemy_defeated.connect(increase_score)
		print("Box spawned: Bee (20% chance)")
		
	if spawned_obj and box:
		# Spawn at the box's position
		spawned_obj.position = box.position
		box.get_parent().call_deferred("add_child", spawned_obj)

func _on_question_block_collected(block: Node2D) -> void:
	increase_score()
	
	# Choose a random item/enemy to spawn:
	# 0 = Apple, 1 = Mushroom, 2 = Bee
	var choice = randi() % 3
	var spawned_obj: Node2D = null
	
	match choice:
		0:
			spawned_obj = APPLE_SCENE.instantiate()
			spawned_obj.collected.connect(_on_apple_collected)
			print("Question Block spawned: Apple")
		1:
			spawned_obj = MUSHROOM_SCENE.instantiate()
			spawned_obj.enemy_defeated.connect(increase_score)
			print("Question Block spawned: Mushroom")
		2:
			spawned_obj = BEE_SCENE.instantiate()
			spawned_obj.enemy_defeated.connect(increase_score)
			print("Question Block spawned: Bee")
			
	if spawned_obj and block:
		# Place it slightly above the block's position relative to the same parent
		spawned_obj.position = block.position + Vector2(0, -24)
		block.get_parent().call_deferred("add_child", spawned_obj)

func _on_exclamation_block_collected() -> void:
	increase_score()
	
	# Random chance: 50% Lose 1 Heart, 50% Gain 1 Heart
	if randf() > 0.5:
		GameState.increase_health()
		print("Exclamation Block: Gained 1 heart!")
	else:
		var player = _get_player_node()
		if player:
			player.die()
			print("Exclamation Block: Lost 1 heart!")


#------------
#FADE
#------------
#------------
#FADE
#------------
func _fade(to_alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", to_alpha, 1.5)
	await tween.finished

func _process(delta: float) -> void:
	update_lives_ui()
	
	if speed_boost_timer > 0:
		speed_boost_timer -= delta
		speed_timer_label.text = "SPEED: %.1f" % speed_boost_timer
		speed_timer_label.visible = true
	else:
		speed_timer_label.visible = false

func _spawn_items_dynamically(level_root: Node) -> void:
	var tilemap = level_root.get_node_or_null("TileMapLayer")
	if not tilemap:
		return
		
	var used_cells = tilemap.get_used_cells()
	var floor_cells = []
	
	var player_pos = Vector2.ZERO
	var exit_pos = Vector2.ZERO
	
	var player = level_root.get_node_or_null("player")
	if not player:
		player = level_root.get_node_or_null("Player")
	if player:
		player_pos = player.position
		
	var exit = level_root.get_node_or_null("Exit")
	if exit:
		exit_pos = exit.position
	
	for cell in used_cells:
		var cell_above = Vector2i(cell.x, cell.y - 1)
		var cell_above_above = Vector2i(cell.x, cell.y - 2)
		
		if tilemap.get_cell_source_id(cell_above) == -1:
			if tilemap.get_cell_source_id(cell_above_above) == -1:
				var pos = tilemap.map_to_local(cell_above) + tilemap.position
				if pos.distance_to(player_pos) > 120.0 and pos.distance_to(exit_pos) > 120.0:
					floor_cells.append(cell_above)
				
	if floor_cells.size() < 10:
		floor_cells.clear()
		for cell in used_cells:
			var cell_above = Vector2i(cell.x, cell.y - 1)
			if tilemap.get_cell_source_id(cell_above) == -1:
				var pos = tilemap.map_to_local(cell_above) + tilemap.position
				if pos.distance_to(player_pos) > 60.0 and pos.distance_to(exit_pos) > 60.0:
					floor_cells.append(cell_above)
				
	if floor_cells.is_empty():
		return
		
	floor_cells.shuffle()
	
	var apples_container = level_root.get_node_or_null("Apples")
	if not apples_container:
		apples_container = Node2D.new()
		apples_container.name = "Apples"
		level_root.add_child(apples_container)
		
	var apple_children = apples_container.get_children()
	
	if apple_children.size() > 4:
		apple_children.shuffle()
		for i in range(apple_children.size() - 4):
			apple_children[i].queue_free()
	elif apple_children.size() == 0:
		# Spawn 3 apples because there were none
		var spawned_apples = 0
		while spawned_apples < 3 and not floor_cells.is_empty():
			var cell = floor_cells.pop_back()
			var apple = APPLE_SCENE.instantiate()
			apple.position = tilemap.map_to_local(cell) + tilemap.position
			apples_container.add_child(apple)
			apple.collected.connect(_on_apple_collected)
			spawned_apples += 1
