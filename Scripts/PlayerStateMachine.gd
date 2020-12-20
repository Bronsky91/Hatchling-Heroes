extends StateMachine

var movement_disabled = false

func _ready():
	add_state("idle")
	add_state("run")
	add_state("jump")
	add_state("double_jump")
	add_state("fall")
	add_state("swim")
	add_state("sink")
	add_state("fly")
	add_state("wall_slide")
	add_state("death")
	call_deferred("set_state", states.idle)

func _input(event):
	if state == states.idle or state == states.run:
		if event.is_action_pressed("jump"):
			parent.jump()
	elif state == states.jump:
		if event.is_action_released("jump"):
			parent.minimize_jump()
		elif event.is_action_pressed("jump"):
			parent.subsequent_jump()
	elif state == states.fall:
		if event.is_action_pressed("jump"):
			parent.subsequent_jump()
	elif state == states.swim or state == states.sink:
		if event.is_action_pressed("jump"):
			parent.swim_jump()
	elif state == states.wall_slide:
		if event.is_action_pressed("jump"):
			parent.wall_jump()
			set_state(states.jump)

func _state_logic(delta):
	if not movement_disabled:
		parent._update_move_direction()
		if state == states.swim or state == states.sink:
			parent._handle_movement(parent.swim_speed_horizontal)
			parent._apply_vertical_swim_velocity(delta)
#			parent._handle_surfacing(delta)
#			parent._update_swim_animations()
		else:
			parent._update_wall_direction()
			if state != states.wall_slide:
				parent._handle_movement()
			parent._apply_gravity(delta)
			if state == states.wall_slide:
				parent._cap_gravity_wall_slide()
				parent._handle_wall_slide_sticking()
		parent._apply_movement(delta)

func _get_transition(delta):
	var direction = "_left" if parent.facing < 0 else "_right"
	if parent.is_dead and state != states.death:
		return states.death
	match state:
		states.idle:
			if parent.is_in_water():
				if parent.velocity.y < 0:
					return states.swim
				else:
					return states.sink
			elif !parent._check_is_grounded():
				if parent.velocity.y < 0:
					return states.jump
				else:
					return states.fall
			elif parent.velocity.x != 0:
				return states.run
		states.run:
			if parent.is_in_water():
				if parent.velocity.y < 0:
					return states.swim
				else:
					return states.sink
			elif !parent._check_is_grounded():
				if parent.velocity.y < 0:
					return states.jump
				else:
					return states.fall
			elif parent.velocity.x == 0:
				return states.idle
			elif !parent.anim_player.current_animation.ends_with(direction):
				return states.run
		states.jump:
			if parent.is_in_water():
				if parent.velocity.y < 0:
					return states.swim
				else:
					return states.sink
			elif parent.wall_direction != 0 and parent.wall_slide_cooldown.is_stopped():
				return states.wall_slide
			elif parent.is_double_jumping:
				return states.double_jump
			elif parent.is_flying:
				return states.fly
			elif parent.velocity.y >= 0:
				return states.fall
			elif parent._check_is_grounded():
				return states.idle
		states.double_jump:
			if parent.is_in_water():
				parent.is_double_jumping = false
				if parent.velocity.y < 0:
					return states.swim
				else:
					return states.sink
			elif parent.wall_direction != 0 and parent.wall_slide_cooldown.is_stopped():
				parent.is_double_jumping = false
				return states.wall_slide
			elif parent.is_flying:
				return states.fly
			elif parent.velocity.y >= 0:
				return states.fall
			elif parent._check_is_grounded():
				parent.is_double_jumping = false
				return states.idle
		states.fly:
			if parent.is_in_water():
				parent.fly_count = 0
				if parent.velocity.y < 0:
					return states.swim
				else:
					return states.sink
			elif parent.wall_direction != 0 and parent.wall_slide_cooldown.is_stopped():
				parent.fly_count = 0
				return states.wall_slide
			elif parent.velocity.y >= 0:
				return states.fall
			elif parent._check_is_grounded():
				parent.fly_count = 0
				return states.idle
			elif !parent.anim_player.current_animation.ends_with(direction):
				return states.fly
		states.fall:
			if parent.is_in_water():
				parent.is_double_jumping = false
				parent.fly_count = 0
				if parent.velocity.y < 0:
					return states.swim
				else:
					return states.sink 
			elif (parent.wall_direction != 0 and parent.wall_direction == parent.facing) and parent.wall_slide_cooldown.is_stopped():
				parent.is_double_jumping = false
				parent.fly_count = 0
				return states.wall_slide
			elif parent._check_is_grounded():
				parent.is_double_jumping = false
				parent.fly_count = 0
				return states.idle
			elif parent.velocity.y < 0:
				return states.jump
		states.swim:
			if parent.is_in_water():
				if parent.velocity.y < 0:
					return states.swim
				else:
					return states.sink
				
				if !parent.anim_player.current_animation.ends_with(direction):
					return states.swim
			else:
				if parent.velocity.y < 0:
					return states.jump
				elif parent.velocity.y > 0:
					return states.fall
				elif parent.velocity.y == 0:
					return states.idle
		states.sink:
			if parent.is_in_water():
				if parent.velocity.y < 0:
					return states.swim
				else:
					return states.sink
				if !parent.anim_player.current_animation.ends_with(direction):
					return states.sink
			else:
				if parent.velocity.y < 0:
					return states.jump
				elif parent.velocity.y > 0:
					return states.fall
				elif parent.velocity.y == 0:
					return states.idle
		states.wall_slide:
			if parent._check_is_grounded():
				return states.idle
			elif parent.wall_direction == 0:
				return states.fall
	return null

func _enter_state(new_state, old_state):
	var direction = "_left" if parent.facing < 0 else "_right"
	if OS.is_debug_build():
		parent.get_node("StateLabel").text = states.keys()[new_state].to_lower() + direction
	else:
		parent.get_node("StateLabel").hide()
	match new_state:
		states.idle:
			parent.anim_player.play("idle" + direction)
		states.run:
			parent.anim_player.play("run" + direction)
		states.jump:
			parent.anim_player.play("jump" + direction)
		states.double_jump:
			parent.anim_player.play("jump" + direction)
		states.fall:
			parent.anim_player.play("fall" + direction)
		states.swim:
			parent.anim_player.play("swim" + direction)
		states.sink:
			parent.anim_player.play("sink" + direction)
		states.fly:
			parent.anim_player.play("fly" + direction)
		states.wall_slide:
			parent.anim_player.play("wall_slide" + direction)
		states.death:
			parent.anim_player.play("death" + direction)

func _exit_state(old_state, new_state):
	match old_state:
		states.wall_slide:
			parent.wall_slide_cooldown.start()

func is_swimming():
	return state == states.swim or state == states.sink

func _on_WallSlideStickyTimer_timeout():
	if state == states.wall_slide:
		set_state(states.fall)
