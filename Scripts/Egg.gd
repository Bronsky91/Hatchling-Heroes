extends Node2D

signal nurture_pressed

var particle = preload("res://Scenes/ParticleIcon.tscn")

var nurture_count_dict = {
	"Dark": 0,
	"Cold": 0,
	"Hate": 0,
	"Love": 0,
	"Crystal": 0,
	"Heat": 0,
	"Light": 0,
	"Slime": 0
}

func _ready():
	connect("nurture_pressed", self, "_on_nurture_pressed")

func _on_nurture_pressed(type):
	show_nurture_particle(type)
	nurture_count_dict[type] += 1
	print(nurture_count_dict)
	
func show_nurture_particle(type):
	var new_particle = particle.instance()
	new_particle.icon_type = type
	$EggSprite/ParticleStart.add_child(new_particle)
