extends KinematicBody2D

export var speed : int = 100
export var score_worth : int = 5

var gravity = 800
var velocity
var is_dead = false
var has_killed = false
var facing = -1


# Called when the node enters the scene tree for the first time.
func _ready():
	$ScoreLabel.text = "+"+str(score_worth)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if !is_dead:
		# If hitting wall move the other way
		if !$FloorRayCast.is_colliding() or $WallRayCast.is_colliding():
			turn_around()
	
		velocity = Vector2(64 * facing, 0)
		velocity.y += gravity * delta
		var collision = move_and_collide(velocity * delta)

func turn_around():
	facing *= -1
	$WallRayCast.cast_to.x = 20 * facing
	$FloorRayCast.position.x = 20 * facing
	$Sprite.play('right') if facing == 1 else $Sprite.play('left')

func _on_Face_body_entered(body):
	if body.name == "Player" and !is_dead:
		if body.has_power(g.power_parts.RAT_PROTECTION):
			return
		body.take_damage()
		has_killed = true
		disable_collision()

func _on_Back_body_entered(body):
	if body.name == "Player" and !is_dead and !has_killed:
		body.bounce_off_enemy()
		die(body)
		
func play_die_sfx():
	randomize()
	var n = randi() % 2
	var variations = ['1', '2']
	$SFX.stream = load('res://Assets/SFX/arcade/rat_death'+ variations[n] +'.wav')
	$SFX.play()
	
func die(player):
	play_die_sfx()
	is_dead = true
	z_index = 10
	$ScoreLabel.show()
	$AnimationPlayer.play("Score_Fly")
	player.enemy_score += score_worth
	$Sprite.play("die_right") if facing == 1 else $Sprite.play('die_left')
	$DeathTimer.start()
	disable_collision()

func _on_DeathTimer_timeout():
	queue_free()

func disable_collision():
	set_collision_mask_bit(g.collision_layers.PLAYER, false)
	set_collision_mask_bit(g.collision_layers.PLAYER_PROJECTILE, false)

func enable_collision():
	set_collision_mask_bit(g.collision_layers.PLAYER, true)
	set_collision_mask_bit(g.collision_layers.PLAYER_PROJECTILE, true)


func _on_AnimationPlayer_animation_finished(anim_name):
	$AnimationPlayer.stop()
