extends Node2D

onready var particles = $Particles2D
var icon_type: String

# Called when the node enters the scene tree for the first time.
func _ready():
	particles.texture = load("res://Assets/UI/"+icon_type+"Icon.png")
	particles.emitting = true

func _on_LifeTime_timeout():
	queue_free()
