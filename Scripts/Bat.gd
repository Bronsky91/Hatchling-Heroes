extends KinematicBody2D

export var speed : int = 100
var time = 0
var velocity
var freq = 5
var amplitude = g.rand_int(5,25)


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	time += delta
	var v = Vector2(-64, 0)
	v.y = cos(time*freq)*amplitude
	velocity = v
	var collision = move_and_collide(velocity * delta)

