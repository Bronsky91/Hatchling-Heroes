extends StateMachine

func _ready():
	add_state("idle")
	add_state("run")
	add_state("jump")
	add_state("fall")
	add_state("wall_slide")
	call_deferred("set_state", states.idle)

func _input(event):
	if state == states.idle or state == states.run:
		if event.is_action_pressed("jump"):
			parent.jump()
	elif state == states.jump:
		if event.is_action_released("jump"):
			parent.variable_jump()
	elif state == states.wall_slide:
		if event.is_action_pressed("jump"):
			parent.wall_jump()
			set_state(states.jump)

func _state_logic(delta):
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
		states.jump:
			if parent.wall_direction != 0 and parent.wall_slide_cooldown.is_stopped():
				return states.wall_slide
			elif parent.velocity.y >= 0:
				return states.fall
			elif parent.is_on_floor():
				return states.idle
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
	parent.get_node("StateLabel").text = states.keys()[new_state].capitalize()
	match new_state:
		states.idle:
			parent.anim_player.play("idle")
		states.run:
			parent.anim_player.play("run")
		states.jump:
			parent.anim_player.play("jump")
		states.fall:
			parent.anim_player.play("fall")
		states.wall_slide:
			parent.anim_player.play("wall_slide")

func _exit_state(old_state, new_state):
	match old_state:
		states.wall_slide:
			parent.wall_slide_cooldown.start()


func _on_WallSlideStickyTimer_timeout():
	if state == states.wall_slide:
		set_state(states.fall)
