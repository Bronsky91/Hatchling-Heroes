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
	
	if !can_lava_walk:
		$StaticBody2D.queue_free()
		connect('body_entered', self, '_on_body_entered')
		connect('body_entered', self, '_on_body_exited')

func _on_body_entered(body):
	if body.name == "Player" and !can_lava_walk:
		if body.lives > 1:
			body.position = Vector2(32, 16)
		body.take_damage()
