extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var sprite_path
	if "LavaSurface" in name:
		sprite_path = "res://Assets/Cave/Tiles/lava_surface_0" + str(g.rand_int(1,2)) + ".png"
	elif "LavaFill" in name:
		sprite_path = "res://Assets/Cave/Tiles/lava_fill_0" + str(g.rand_int(1,2)) + ".png"
	$Sprite.set_texture(load(sprite_path))


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
