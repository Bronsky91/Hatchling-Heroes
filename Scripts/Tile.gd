extends StaticBody2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func set_ground_sprite(is_floor: bool, mask: String):
	var surface = "_floor_" if is_floor else "_ceil_"
	var sprite_path = "res://Assets/Cave/Tiles/ground" + surface + mask + ".png"
	$Sprite.set_texture(load(sprite_path))
