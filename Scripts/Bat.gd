extends KinematicBody2D

export var speed : int = 100
export var score_worth : int = 10

var time = 0
var velocity
var freq = 5
var amplitude = g.rand_int(5,25)
var is_dead = false
var has_killed = false


# Called when the node enters the scene tree for the first time.
func _ready():
	$ScoreLabel.text = "+"+str(score_worth)

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
		if body.has_power(g.power_parts.BAT_PROTECTION) and not 'Rat' in name:
			return 
		if body.has_power(g.power_parts.RAT_PROTECTION) and not 'Bat' in name:
			return
		if body.has_power(g.power_parts.RAT_PROTECTION) and body.has_power(g.power_parts.BAT_PROTECTION):
			return
		body.take_damage()
		has_killed = true
		disable_collision()

func _on_Back_body_entered(body):
	if body.name == "Player" and !is_dead and !has_killed:
		body.bounce_off_enemy()
		die(body)

func _on_Belly_body_entered(body):
	if body.name == "Player" and !is_dead and !has_killed:
		if body.has_power(g.power_parts.TOP_ATTACK):
			return die(body)
		if body.has_power(g.power_parts.TOP_SHIELD):
			return
		if body.has_power(g.power_parts.BAT_PROTECTION) and not 'Rat' in name:
			return 
		if body.has_power(g.power_parts.RAT_PROTECTION) and not 'Bat' in name:
			return
		if body.has_power(g.power_parts.RAT_PROTECTION) and body.has_power(g.power_parts.BAT_PROTECTION):
			return
		body.take_damage()
		has_killed = true
		disable_collision()
			
func die(player):
	play_die_sfx()
	is_dead = true
	z_index = 10
	$ScoreLabel.show()
	$AnimationPlayer.play("Score_Fly")
	player.enemy_score += score_worth
	$Sprite.play("die")
	$DeathTimer.start()
	disable_collision()
	
func play_die_sfx():
	randomize()
	var n = randi() % 4
	var variations = ['a', 'b', 'c', 'd']
	$SFX.stream = load('res://Assets/SFX/enemy_hit_'+ variations[n] +'.wav')
	$SFX.play()
	
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
