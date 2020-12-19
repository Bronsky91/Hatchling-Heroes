extends Area2D

var avail_to_dmg = true

func _ready():
	connect('body_entered', self, '_on_body_entered')
	connect('body_entered', self, '_on_body_exited')

func _on_body_entered(body):
	if body.name == "Player" and avail_to_dmg and not 'U_03b' in name: #U_03b is a combo spike with 03a
		if ('D' in name or 'platform' in name) and body.has_power(g.power_parts.TOP_SHIELD):
			return
		body.take_damage('spike')
		avail_to_dmg = false

func _on_body_exited(body):
	avail_to_dmg = true
