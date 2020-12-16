extends Area2D

func _on_body_entered(body):
	if body.name == "Player":
		if name == "WaterSurface":
			body.touching_water_surface(self.get_instance_id())
		else:
			body.touching_water(self.get_instance_id())


func _on_body_exited(body):
	if body.name == "Player":
		body.stopped_touching_water(self.get_instance_id())
