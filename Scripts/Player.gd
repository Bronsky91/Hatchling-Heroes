extends KinematicBody2D

signal grounded_updated(is_grounded)

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

var is_jumping = false
var is_flying = false
var is_grounded = false
var is_sliding = false

var lives = 1
var can_fly = true
var level_complete = false

var score = 0

onready var anim_player = $Body/AnimationPlayer
onready var body = $Body
onready var left_wall_raycast = $LeftWallRaycast
onready var right_wall_raycast = $RightWallRaycast
onready var wall_slide_cooldown = $WallSlideCooldown
onready var wall_slide_sticky_timer = $WallSlideStickyTimer
onready var map_size_x = get_node('../Tiles').map_size.x * 16
onready var score_timer_label = get_node('../../UI/TimerLabel')
onready var UI = get_node('../../UI')

# Called when the node enters the scene tree for the first time.
func _ready():
	g.load_creature(body)
	max_jump_velocity = -sqrt(2 * gravity * jump_height)
	min_jump_velocity = -sqrt(2 * gravity * min_jump_height)
	
func _physics_process(delta):
	if position.x > map_size_x and not level_complete:
		complete_level()
		
func complete_level():
	level_complete = true
	add_score_to_board()
	$ScoreTimer.stop()
	$StateMachine.movement_disabled = true
	$Body.z_index = 2
	UI.game_over()
	# TODO: Game Success Screen -> Egg Creation
	
func _on_ScoreTimer_timeout():
	score += 0.01
	score_timer_label.text = str(score).pad_decimals(1)

func add_score_to_board():
	if not OS.is_debug_build():
		var f = File.new()
		f.open("res://SaveData/character_state.json", File.READ)
		var json = JSON.parse(f.get_as_text())
		f.close()
		var data = json.result
		$GameJoltAPI.add_score(str(score).pad_decimals(2), score, '', '', data['Name'], '', JSON.print(data))

func _apply_gravity(delta):
	velocity.y += gravity * delta
	# set is_jumping and is_flying to false if player is jumping/flying and moving downward
	if (is_jumping or is_flying) and velocity.y >= 0:
		is_jumping = false
		is_flying = false

func _cap_gravity_wall_slide():
	var max_velocity = tile_size * 10 if Input.is_action_pressed("move_down") else tile_size
	velocity.y = min(velocity.y, max_velocity)

func _apply_movement():
	var snap = Vector2.DOWN * (tile_size * 2) if !is_jumping and !is_flying else Vector2.ZERO
	
	velocity = move_and_slide_with_snap(velocity, snap, Vector2.UP)
	
	var was_grounded = is_grounded
	is_grounded = is_on_floor()
	
	if was_grounded == null || is_grounded != was_grounded:
		emit_signal("grounded_updated", is_grounded)

func _update_move_direction():
	move_direction = -int(Input.is_action_pressed("move_left")) + int(Input.is_action_pressed("move_right"))

func _handle_movement(var speed = self.move_speed):
	# Get movement keypresses, convert to integers, and then store in move_direction
	move_input_speed = -Input.get_action_strength("move_left") + Input.get_action_strength("move_right")
	# Lerp velocity.x towards the direction the player is pressing keys for, weighted based on if they're grounded or not
	velocity.x = lerp(velocity.x, speed * move_input_speed, _get_h_weight())
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
	if is_on_floor():
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
	if can_fly:
		velocity.y = max_jump_velocity
		is_flying = true

func wall_jump():
	velocity.y = max_jump_velocity
	velocity.x = (max_jump_velocity / 2) * wall_direction

func _check_is_grounded(raycasts = self.raycasts):
	# Loop through ground raycasts to determine if they're colliding with the ground
	for raycast in raycasts.get_children():
		if raycast.is_colliding():
			return true
	# If loop completes then raycast was not detected
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

func take_damage():
	lives -= 1
	if lives < 1:
		get_tree().reload_current_scene()

