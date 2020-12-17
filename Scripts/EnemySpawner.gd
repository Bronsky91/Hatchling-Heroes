extends Node2D

onready var player = get_node("../Player")
var rat = preload("res://Scenes/Rat.tscn")
var bat = preload("res://Scenes/Bat.tscn")
var batrat = preload("res://Scenes/BatRat.tscn")

func _on_Timer_timeout():
	var i = batrat.instance() if g.rand_int(1,4) == 1 else bat.instance()
	i.position = player.position
	i.position.x += 400
	i.position.y += g.rand_int(-64, 64)
	add_child(i)
