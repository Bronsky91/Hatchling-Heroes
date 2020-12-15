extends Sprite

var velocity = Vector2(0, 0)
var target_pos: Vector2
var speed = 200

var type: String

func _physics_process(delta):
	var angle = get_angle_to(target_pos)
	
	velocity.x = cos(angle)
	velocity.y = sin(angle)
	
	global_position += velocity * speed * delta
