extends Node2D

onready var player = get_node("../Player")
var rat = preload("res://Scenes/Rat.tscn")
var bat = preload("res://Scenes/Bat.tscn")

func _on_Timer_timeout():
	var i = bat.instance()
	i.position = player.position
	i.position.x += 400
	i.position.y += g.rand_int(-64, 64)
	add_child(i)
