extends StateMachine

var movement_disabled = false

func _ready():
	add_state("idle")
	add_state("run")
	add_state("jump")
	add_state("fall")
	add_state("fly")
	add_state("wall_slide")
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
	elif state == states.wall_slide:
		if event.is_action_pressed("jump"):
			parent.wall_jump()
			set_state(states.jump)

func _state_logic(delta):
	if not movement_disabled:
		parent._update_move_direction()
		parent._update_wall_direction()
		if state != states.wall_slide:
			parent._handle_movement()
		parent._apply_gravity(delta)
		if state == states.wall_slide:
			parent._cap_gravity_wall_slide()
			parent._handle_wall_slide_sticking()
		parent._apply_movement()

func _get_transition(delta):
	var direction = "_left" if parent.facing < 0 else "_right"
	match state:
		states.idle:
			if !parent.is_on_floor():
				if parent.velocity.y < 0:
					return states.jump
				else:
					return states.fall
			elif parent.velocity.x != 0:
				return states.run
		states.run:
			if !parent.is_on_floor():
				if parent.velocity.y < 0:
					return states.jump
				else:
					return states.fall
			elif parent.velocity.x == 0:
				return states.idle
			elif !parent.anim_player.current_animation.ends_with(direction):
				return states.run
		states.jump:
			if parent.wall_direction != 0 and parent.wall_slide_cooldown.is_stopped():
				return states.wall_slide
			elif parent.is_flying:
				return states.fly
			elif parent.velocity.y >= 0:
				return states.fall
			elif parent.is_on_floor():
				return states.idle
		states.fly:
			if parent.wall_direction != 0 and parent.wall_slide_cooldown.is_stopped():
				return states.wall_slide
			elif parent.velocity.y >= 0:
				return states.fall
			elif parent.is_on_floor():
				return states.idle
			elif !parent.anim_player.current_animation.ends_with(direction):
				return states.fly
		states.fall:
			if parent.wall_direction != 0 and parent.wall_slide_cooldown.is_stopped():
				return states.wall_slide
			elif parent.is_on_floor():
				return states.idle
			elif parent.velocity.y < 0:
				return states.jump
		states.wall_slide:
			if parent.is_on_floor():
				return states.idle
			elif parent.wall_direction == 0:
				return states.fall
	return null

func _enter_state(new_state, old_state):
	var direction = "_left" if parent.facing < 0 else "_right"
	parent.get_node("StateLabel").text = states.keys()[new_state].to_lower() + direction
	match new_state:
		states.idle:
			parent.anim_player.play("idle" + direction)
		states.run:
			parent.anim_player.play("run" + direction)
		states.jump:
			parent.anim_player.play("jump" + direction)
		states.fall:
			parent.anim_player.play("fall" + direction)
		states.fly:
			parent.anim_player.play("fly" + direction)
		states.wall_slide:
			parent.anim_player.play("wall_slide" + direction)

func _exit_state(old_state, new_state):
	match old_state:
		states.wall_slide:
			parent.wall_slide_cooldown.start()


func _on_WallSlideStickyTimer_timeout():
	if state == states.wall_slide:
		set_state(states.fall)
