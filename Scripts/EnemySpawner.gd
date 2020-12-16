extends Node2D

onready var player = get_node("../Player")
var rat = preload("res://Scenes/Rat.tscn")
var bat = preload("res://Scenes/Bat.tscn")
var batrat = preload("res://Scenes/BatRat.tscn")

func _on_Timer_timeout():
	var i = bat.instance() if g.rand_int(1,2) == 1 else batrat.instance()
	i.position = player.position
	i.position.x += 400
	i.position.y += g.rand_int(-64, 64)
	add_child(i)
