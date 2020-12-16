extends Sprite

onready var map_size = get_node('../../../Tiles').map_size


# Called when the node enters the scene tree for the first time.
func _ready():
	scale = map_size
	scale.x += 5
	position.x -= 5 * 16


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
