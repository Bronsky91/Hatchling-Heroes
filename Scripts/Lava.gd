extends Area2D

var can_lava_walk
var sprite_path

# Called when the node enters the scene tree for the first time.
func _ready():
	can_lava_walk = get_node("../../Player").has_power(g.power_parts.LAVA_WALK)
	if "LavaSurface" in name:
		sprite_path = "res://Assets/Cave/Tiles/lava_surface_0" + str(g.rand_int(1,2)) + ".png"
	elif "LavaFill" in name:
		sprite_path = "res://Assets/Cave/Tiles/lava_fill_0" + str(g.rand_int(1,2)) + ".png"
	$Sprite.set_texture(load(sprite_path))

func _on_body_entered(body):
	if body.name == "Player" and !can_lava_walk:
		body.take_damage()
