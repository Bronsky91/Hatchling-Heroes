extends StaticBody2D

export var submerged: bool = false
var variation: int = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	variation = rand_int(1,4)
	var prefix = "dev-waterspikes" if submerged else "dev-spikes"
	var new_sprite = load("res://Assets/Cave/" + prefix + str(variation) + ".png")
	$Sprite.set_texture(new_sprite)
	# resize collision shape on tall spikes
	if variation == 3 or variation == 4:
		$Sprite.position = Vector2(0,8)
		$CollisionShape2D.shape.extents = Vector2(8,16)
		$CollisionShape2D.position = Vector2(0,-8)
	else:
		$Sprite.position = Vector2(0,0)
		$CollisionShape2D.shape.extents = Vector2(8,8)
		$CollisionShape2D.position = Vector2(0,0)

func flip_upside_down():
	$Sprite.rotation_degrees = 180

func rand_int(min_value: int,max_value: int, inclusive_range = true):
	if inclusive_range:
		max_value += 1
	var range_size = max_value - min_value
	return (randi() % range_size) + min_value
