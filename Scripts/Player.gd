extends KinematicBody2D

# stats
var score : int = 0
 
# physics
var speed : int = 200
var jumpForce : int = 300
var gravity : int = 800
var vel : Vector2 = Vector2()
var grounded : bool = false
var lives : int = 1

#components
onready var sprite = $Sprite

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	get_input()
	# applying the velocity
	vel = move_and_slide(vel, Vector2.UP)
	# gravity
	vel.y += gravity * delta
	# reset horizontal velocity
	vel.x = 0

func get_input():
	# jump input
	if Input.is_action_pressed("jump") and is_on_floor():
		vel.y -= jumpForce
	# movement inputs
	if Input.is_action_pressed("move_left"):
		print('left')
		vel.x -= speed
		sprite.flip_h = true
	if Input.is_action_pressed("move_right"):
		vel.x += speed
		sprite.flip_h = false
		
func take_damage():
	lives -= 1
	if lives < 1:
		get_tree().reload_current_scene()

