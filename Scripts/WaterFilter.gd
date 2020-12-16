extends Sprite

# Called when the node enters the scene tree for the first time.
func _ready():
	set_shader_scale()

func set_shader_scale():
	material.set_shader_param("sprite_scale", scale)
