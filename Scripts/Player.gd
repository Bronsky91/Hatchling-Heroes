extends KinematicBody2D

signal grounded_updated(is_grounded)

var ideal_framerate = 60.0
var tile_size = 16
var gravity = 800
var velocity = Vector2()
var move_speed = 10 * tile_size
var move_direction
var move_input_speed = 0
var jump_height = 3 * tile_size
var min_jump_height = tile_size / 2
var max_jump_velocity
var min_jump_velocity
var facing = 1
var wall_direction = 1
var swim_up_speed = -3 * tile_size
var passive_swim_y_speed = 2 * tile_size # Boyancy
var swim_down_speed = 3 * tile_size
var swim_speed_horizontal = 3 * tile_size
var swim_jump_out_velocity = -5 * tile_size
var overlapping_water = []
var overlapping_water_surface = []

var is_jumping = false
var is_flying = false
var is_grounded = false
var is_sliding = false
var is_invulnerable = false
var is_flashing = false
var is_dead = false

var lives = 2
var air_max = 5
var can_double_jump = false
var level_complete = false
var previous_pos_x: int

var powers = [] # Powers the creatures has from body parts (Ex: Flying)

var seconds = 0
var distance_score: int
var enemy_score: int
var score: int = 0

onready var state_machine = $StateMachine
onready var anim_player = $Body/AnimationPlayer
onready var body = $Body
onready var swim_level = $SwimLevel
onready var left_wall_raycast = $LeftWallRaycast
onready var right_wall_raycast = $RightWallRaycast
onready var floor_raycast = $FloorRaycast
onready var enemy_raycast = $EnemyRaycast
onready var wall_slide_cooldown = $WallSlideCooldown
onready var wall_slide_sticky_timer = $WallSlideStickyTimer
onready var map_size_x = get_node('../Tiles').map_size.x * 16
onready var UI = get_node('../../UI')
onready var lives_container = get_node('../../UI/LivesContainer')
onready var timer_label = get_node('../../UI/TimerLabel')
onready var score_label = get_node('../../UI/ScoreLabel')
onready var music_player = get_node("../../MusicPlayer")

# Called when the node enters the scene tree for the first time.
func _ready():
	if not OS.is_debug_build():
		music_player.stream = load('res://Assets/Music/Cave Music Game Jam1.wav')
		music_player.play()
	powers = g.load_creature(body)
	if has_power(g.power_parts.SWIM):
		swim_up_speed = -10 * tile_size
		swim_down_speed = 10 * tile_size
		swim_speed_horizontal = 10 * tile_size
	if has_power(g.power_parts.EXTRA_LIFE):
		lives += 1 
	if has_power(g.power_parts.EXTRA_AIR):
		air_max = 10
		UI.get_node("AirMeter").max_value = air_max
		UI.get_node("AirMeter").value = air_max
	if has_power(g.power_parts.WATER_WALK):
		floor_raycast.set_collision_mask_bit(g.collision_layers.WATER, true)

	add_lives_to_container()
	
	max_jump_velocity = -sqrt(2 * gravity * jump_height)
	min_jump_velocity = -sqrt(2 * gravity * min_jump_height)
	
func add_lives_to_container():
	var lives_array = range(lives)
	for lives in lives_array:
		var control = Control.new()
		control.rect_position.y = 10
		var sprite = Sprite.new()
		g.giveth_shaders_to_new_sprite($Body/Head, sprite)
		sprite.texture = $Body/Head.texture
		sprite.vframes = 6
		sprite.hframes = 7
		sprite.frame = 27
		control.add_child(sprite)
		lives_container.add_child(control)
	
func _physics_process(delta):
	if int(position.x) > previous_pos_x:
		distance_score += 1
		previous_pos_x = int(position.x)
	if position.x > map_size_x and not level_complete:
		complete_level('COMPLETED')
		# When dead complete_level('GAME OVER')
	if (is_in_water() and not is_in_water_surface()) and $AirTimer.is_stopped() and not has_power(g.power_parts.GILLS):
		$AirTimer.start()
		UI.get_node("AirMeter").show()
		
func has_power(power):
	return power in powers
	
func complete_level(text):
	if text == 'COMPLETED':
		music_player.stream = load('res://Assets/Music/level_complete_game_jam_01.wav')
	else:
		music_player.stream = load('res://Assets/Music/Game_Over_Game_jam_1.wav')
	music_player.play()
	z_index = 1
	level_complete = true
	$StateMachine.movement_disabled = true
	add_score_to_board(text)
	$ScoreTimer.stop()
	$Body.z_index = 2
	UI.game_over(text)
	
func _on_ScoreTimer_timeout():
	seconds += 0.1
	score = (distance_score / 10) + enemy_score
	score_label.text = str(score)
	timer_label.text = str(seconds).pad_decimals(1)

func add_score_to_board(text):
	if text == "COMPLETED":
		score += 300 - int(seconds)
	if not OS.is_debug_build():
		var f = File.new()
		f.open("user://character_state.save", File.READ)
		var json = JSON.parse(f.get_as_text())
		f.close()
		var data = json.result
		$GameJoltAPI.add_score(str(score), score, '', '', data['Name'], '', JSON.print(data))

func _apply_gravity(delta):
	velocity.y += gravity * delta
	# set is_jumping and is_flying to false if player is jumping/flying and moving downward
	if (is_jumping or is_flying) and velocity.y >= 0:
		is_jumping = false
		is_flying = false

func _cap_gravity_wall_slide():
	var max_velocity = tile_size * 10 if Input.is_action_pressed("move_down") else tile_size
	velocity.y = 0 if has_power(g.power_parts.WALL_STICK) else min(velocity.y, max_velocity) 

func _apply_movement(delta):
	var snap = Vector2.DOWN * (tile_size * 2) if !is_jumping and !is_flying else Vector2.ZERO
	
	velocity = move_and_slide_with_snap(velocity, snap, Vector2.UP)
	
	var was_grounded = is_grounded
	is_grounded = _check_is_grounded()
	
	if was_grounded == null || is_grounded != was_grounded:
		emit_signal("grounded_updated", is_grounded)

func _update_move_direction():
	move_direction = -int(Input.is_action_pressed("move_left")) + int(Input.is_action_pressed("move_right"))

func _handle_movement(var speed = self.move_speed):
	var delta = get_physics_process_delta_time()
	# Get movement keypresses, convert to integers, and then store in move_direction
	move_input_speed = -Input.get_action_strength("move_left") + Input.get_action_strength("move_right")
	# Lerp velocity.x towards the direction the player is pressing keys for, weighted based on if they're grounded or not
	velocity.x = lerp(velocity.x, speed * move_input_speed, _get_h_weight() * delta / (1/ideal_framerate))
	# Set sprite facing based on the last movement key pressed
	if move_direction != 0:
		facing = move_direction

func _handle_wall_slide_sticking():
	if move_direction != 0 and move_direction != wall_direction:
		if wall_slide_sticky_timer.is_stopped():
			wall_slide_sticky_timer.start()
	else:
		wall_slide_sticky_timer.stop()

func _get_h_weight():
	if state_machine.is_swimming():
		return 0.05
	elif _check_is_grounded():
		return 1
	else:
		if move_direction == 0:
			return 0.02
		elif move_direction == sign(velocity.x) and abs(velocity.x) > move_speed:
			return 0.0
		else:
			return 0.1

func jump():
	velocity.y = max_jump_velocity
	is_jumping = true

func minimize_jump():
	if velocity.y < min_jump_velocity:
		velocity.y = min_jump_velocity

func subsequent_jump():
	if has_power(g.power_parts.FLYING):
		velocity.y = max_jump_velocity
		is_flying = true

func wall_jump():
	velocity.y = max_jump_velocity
	velocity.x = (max_jump_velocity / 2) * wall_direction

func swim_jump():
	if is_in_water_surface():
		velocity.y = max_jump_velocity
	elif is_in_water():
		velocity.y = (max_jump_velocity / 3) * 2

func _apply_vertical_swim_velocity(delta):
	velocity.y = lerp(velocity.y, passive_swim_y_speed, 0.075 * delta / (1/ideal_framerate))

func bounce_off_enemy():
	velocity.y = max_jump_velocity / 2
	is_jumping = true

#func _handle_surfacing(delta):
#	if velocity.y < 0:
#		var space_state = get_world_2d().direct_space_state
#		var surface_level = swim_level.global_position + Vector2.DOWN * velocity.y * delta
#		var results = space_state.intersect_point(surface_level, 1, [], g.collision_layers.WATER, false, true)
#		if !results:
#			var ray_result = space_state.intersect_ray(surface_level, swim_level.global_position, [], g.collision_layers.WATER)
#			if ray_result:
#				velocity.y = (ray_result.position.y - swim_level.global_position.y) / delta

func touching_water_surface(id: int):
	if !overlapping_water_surface.has(id):
		overlapping_water_surface.append(id)
	touching_water(id)

func touching_water(id: int):
	if !overlapping_water.has(id):
		if overlapping_water.size() == 0:
			entered_water()
		overlapping_water.append(id)

func stopped_touching_water(id: int):
	if overlapping_water_surface.has(id):
		overlapping_water_surface.erase(id)
	if overlapping_water.has(id):
		overlapping_water.erase(id)
	if overlapping_water.size() == 0:
		exited_water()

func is_in_water_surface():
	return overlapping_water_surface.size() != 0

# jumped into water
func entered_water():
	velocity.y = passive_swim_y_speed * 4
	$SFX.stream = load('res://Assets/SFX/enter_water.wav')
	$SFX.play()

func exited_water():
	$SFX.stream = load('res://Assets/SFX/enter_water.wav')
	$SFX.play()

func is_in_water():
#	var space_state = get_world_2d().direct_space_state
#	var results = space_state.intersect_point(swim_level.global_position, 32, [], 2147483647, true, true)
#	print("water detected? " + str(results.size()))
#	for i in results:
#		print(i.collider)
#		if i.shape:
#			print (i.shape)
#
#	#return results.size() != 0
#	return false
	return overlapping_water.size() != 0

func can_jump_out_of_water():
	var space_state = get_world_2d().direct_space_state
	var results = space_state.intersect_point(swim_level.global_position + Vector2.UP * 32.0, 1, [], g.collision_layers.WATER, false, true)
	return velocity.y <= 0 && results.size() == 0

func _check_is_grounded():
	if floor_raycast.is_colliding() or enemy_raycast.is_colliding():
		return true
	else:
		return false

func _update_wall_direction():
	var is_near_wall_left = _check_is_valid_wall(left_wall_raycast)
	var is_near_wall_right = _check_is_valid_wall(right_wall_raycast)
	if is_near_wall_left and is_near_wall_right:
		wall_direction = move_direction
	else:
		wall_direction = -int(is_near_wall_left) + int(is_near_wall_right)

func _check_is_valid_wall(raycast):
	if raycast.is_colliding():
		var dot = acos(Vector2.UP.dot(raycast.get_collision_normal()))
		if dot > PI * 0.35 and dot < PI * 0.55:
			return true
	return false

func wall_dir():
	for i in range(get_slide_count()):
		var collision = get_slide_collision(i)
		if collision.normal.x > 0:
			return "left"
		elif collision.normal.x < 0:
			return "right"
	return "none"

func take_damage(type = ""):
	if !is_invulnerable and !level_complete:
		play_damaged_sfx()
		jump()
		lives -= 1
		if lives >= 0:
			lives_container.get_children()[-1].queue_free()
		if lives < 1 and not level_complete:
			if type == 'spike':
				play_impale_sfx()
			is_dead = true
			complete_level("GAME OVER")
		else:
			is_invulnerable = true
			$InvulnerabilityTimer.start()
			$FlashTimer.start()
			
func play_impale_sfx():
	$SFX.stream = load('res://Assets/SFX/spike_impale.wav')
	$SFX.play()
	
func play_damaged_sfx():
	randomize()
	var n = randi() % 4
	var variations = ['a', 'b', 'c', 'poo']
	$SFX.stream = load('res://Assets/SFX/dmg_'+ variations[n] +'.wav')
	$SFX.play()

func _on_AirTimer_timeout():
	if UI.get_node('AirMeter').value == air_max:
		UI.get_node('AirMeter').hide()
		$AirTimer.stop()
	if is_in_water_surface() or not is_in_water():
		UI.get_node('AirMeter').value += 0.2
	elif is_in_water():
		UI.get_node('AirMeter').value -= 0.1
	if UI.get_node('AirMeter').value == 0:
		take_damage()


func _on_InvulnerabilityTimer_timeout():
	is_invulnerable = false


func _on_FlashTimer_timeout():
	if is_invulnerable:
		if is_flashing:
			modulate = Color(1,1,1,1) # normal
		else:
			modulate = Color(1,0,0,0.5) # red
		is_flashing = !is_flashing
		$FlashTimer.start()
	else:
		modulate = Color(1,1,1,1) # normal
