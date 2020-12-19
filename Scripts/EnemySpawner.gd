extends Node2D

onready var player = get_node("../Player")
onready var tiles = get_node('../Tiles')

var rat = preload("res://Scenes/Rat.tscn")
var bat = preload("res://Scenes/Bat.tscn")
var batrat = preload("res://Scenes/BatRat.tscn")

enum enemy_type { BAT, RAT, BATRAT}

func _on_Timer_timeout():
	var i
	var type = g.rand_int(0,2)
	match type:
		enemy_type.BAT:
			i = bat.instance()
			i.position = player.position
			i.position.x += 400
			i.position.y += g.rand_int(-64, 64)
		enemy_type.RAT:
			for x in range(25, 50):
				var pos = ceil(player.position.x / 16) + x
				if x < tiles.map_size.x - 1:
					var mid_strip = tiles.floor_line[pos] == tiles.floor_line[pos - 1] and tiles.floor_line[pos] == tiles.floor_line[pos + 1]
					var not_above_pit = tiles.lava_tops[pos] == 0 and tiles.water_tops[pos] == 0 and tiles.pit_tops[pos] == 0
					if not_above_pit and mid_strip:
						# Valid spot
						i = rat.instance()
						i.position = Vector2(pos * 16, (tiles.floor_line[pos] * 16)- 16) 
						break
		enemy_type.BATRAT:
			i = batrat.instance()
			i.position = player.position
			i.position.x += 400
			i.position.y += g.rand_int(-64, 64)
			
	if i:
		add_child(i)
