extends Node2D

signal nurture_pressed

var particle = preload("res://Scenes/ParticleIcon.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("nurture_pressed", self, "_on_nurture_pressed")

func _on_nurture_pressed(type):
	var new_particle = particle.instance()
	new_particle.icon_type = type
	$EggSprite/ParticleStart.add_child(new_particle)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
