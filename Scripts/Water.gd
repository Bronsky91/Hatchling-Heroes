extends Area2D

var can_water_walk

# Called when the node enters the scene tree for the first time.
func _ready():
	can_water_walk = get_node("../../Player").has_power(g.power_parts.WATER_WALK)
	if can_water_walk:
		disconnect('body_entered', self, '_on_body_entered')
		disconnect('body_exited', self, '_on_body_exited')
	else:
		$StaticBody2D.queue_free()
		connect('body_entered', self, '_on_body_entered')
		connect('body_exited', self, '_on_body_exited')



func _on_body_entered(body):
	if body.name == "Player":
		if "WaterSurface" in name:
			body.touching_water_surface(self.get_instance_id())
		elif "WaterFill" in name:
			body.touching_water(self.get_instance_id())

func _on_body_exited(body):
	if body.name == "Player":
		body.stopped_touching_water(self.get_instance_id())
