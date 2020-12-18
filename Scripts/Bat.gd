extends KinematicBody2D

export var speed : int = 100
var time = 0
var velocity
var freq = 5
var amplitude = g.rand_int(5,25)
var is_dead = false
var has_killed = false


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if !is_dead:
		time += delta
		var v = Vector2(-64, 0)
		v.y = cos(time*freq)*amplitude
		velocity = v
		var collision = move_and_collide(velocity * delta)
	else:
		move_and_slide(Vector2.DOWN * 1600 * delta)

func _on_Face_body_entered(body):
	if body.name == "Player" and !is_dead:
		if body.has_power(g.power_parts.BAT_PROTECTION):
			return 
		body.take_damage()
		has_killed = true
		disable_collision()

func _on_Back_body_entered(body):
	if body.name == "Player" and !is_dead and !has_killed:
		body.bounce_off_enemy()
		die()

func _on_Belly_body_entered(body):
	if body.name == "Player" and !is_dead and !has_killed:
		print("player in belly!")

func die():
	is_dead = true
	z_index = 10
	$Sprite.play("die")
	$DeathTimer.start()
	disable_collision()

func _on_DeathTimer_timeout():
	self.queue_free()

func disable_collision():
	set_collision_mask_bit(g.collision_layers.PLAYER, false)
	set_collision_mask_bit(g.collision_layers.PLAYER_PROJECTILE, false)

func enable_collision():
	set_collision_mask_bit(g.collision_layers.PLAYER, true)
	set_collision_mask_bit(g.collision_layers.PLAYER_PROJECTILE, true)
