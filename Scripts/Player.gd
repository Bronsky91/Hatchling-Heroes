extends KinematicBody2D

signal grounded_updated(is_grounded)

var gravity = 800
var velocity = Vector2()
var move_speed = 10 * 16
var move_direction
var move_input_speed = 0
var jump_height = 3 * 16
var max_jump_velocity
var min_jump_velocity
var min_jump_height = 2 * 16
var facing = 1
var wall_direction = 1

var is_jumping = false
var is_grounded = false
var is_sliding = false

var lives = 1

onready var anim_player = $Body/AnimationPlayer
onready var body = $Body
onready var left_wall_raycast = $LeftWallRaycast
onready var right_wall_raycast = $RightWallRaycast
onready var wall_slide_cooldown = $WallSlideCooldown
onready var wall_slide_sticky_timer = $WallSlideStickyTimer

# Called when the node enters the scene tree for the first time.
func _ready():
	max_jump_velocity = -sqrt(2 * gravity * jump_height)
	min_jump_velocity = -sqrt(2 * gravity * min_jump_height)

func _apply_gravity(delta):
	velocity.y += gravity * delta
	# set is_jumping to false if player is jumping and moving downward
	if is_jumping and velocity.y >= 0:
		is_jumping = false

func _cap_gravity_wall_slide():
	var max_velocity = 16 * 10 if Input.is_action_pressed("move_down") else 16
	velocity.y = min(velocity.y, max_velocity)

func _apply_movement():
	var snap = Vector2.DOWN * 32 if !is_jumping else Vector2.ZERO
	
	velocity = move_and_slide_with_snap(velocity, snap, Vector2.UP)
	
	var was_grounded = is_grounded
	is_grounded = is_on_floor()
	
	if was_grounded == null || is_grounded != was_grounded:
		emit_signal("grounded_updated", is_grounded)

func _update_move_direction():
	move_direction = -int(Input.is_action_pressed("move_left")) + int(Input.is_action_pressed("move_right"))

func _handle_movement(var move_speed = self.move_speed):
	# Get movement keypresses, convert to integers, and then store in move_direction
	move_input_speed = -Input.get_action_strength("move_left") + Input.get_action_strength("move_right")
	# Lerp velocity.x towards the direction the player is pressing keys for, weighted based on if they're grounded or not
	velocity.x = lerp(velocity.x, move_speed * move_input_speed, _get_h_weight())
	# Set sprite facing based on the last movement key pressed
	if move_direction != 0:
		$Body.scale.x = -move_direction
		facing = move_direction

func _handle_wall_slide_sticking():
	if move_direction != 0 and move_direction != wall_direction:
		if wall_slide_sticky_timer.is_stopped():
			wall_slide_sticky_timer.start()
	else:
		wall_slide_sticky_timer.stop()

func _get_h_weight():
	if is_on_floor():
		return 0.2
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

func variable_jump():
	if velocity.y < min_jump_velocity:
		velocity.y = min_jump_velocity

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

## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _physics_process(delta):
#	get_input()
#	# applying the velocity
#	velocity = move_and_slide(velocity, Vector2.UP)
#	# reset horizontal velocity
#	velocity.x = 0

#func get_input():	
#	var sliding_left = false
#	var sliding_right = false
#
#	# wall slide input
#	if is_on_wall() and !is_on_floor():
#		var wall_dir = wall_dir()
#		if wall_dir == "left" and Input.is_action_pressed("move_left"):
#			sliding_left = true
#		elif wall_dir == "right" and Input.is_action_pressed("move_right"):
#			sliding_right = true
#		if velocity.y >= 0 and (sliding_left or sliding_right):
#			velocity.y = min(velocity.y + wall_slide_acceleration, wall_slide_max_speed)
#		else:
#			velocity.y += gravity
#
#	# jump input
#	if Input.is_action_just_pressed("jump"):
#		if is_on_floor():
#			velocity.y -= jumpForce
#		elif sliding_left:
#			velocity.x += jumpForce
#			velocity.y -= jumpForce
#		elif sliding_right:
#			velocity.x -= jumpForce
#			velocity.y -= jumpForce
#
#	# movement inputs
#	if Input.is_action_pressed("move_left"):
#		print('left')
#		velocity.x -= speed
#		sprite.flip_h = true
#	if Input.is_action_pressed("move_right"):
#		velocity.x += speed
#		sprite.flip_h = false
