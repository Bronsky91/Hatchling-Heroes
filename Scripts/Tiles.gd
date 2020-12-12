extends Node2D

export var map_size: Vector2 = Vector2(100,28)
export var ceiling_min: int = 2
export var ceiling_max: int = 7
export var ground_min: int = 10
export var ground_max: int = 17

enum TILE {NONE, GROUND, WATER, LAVA, C_SPIKE, F_SPIKE = -1}
var matrix = []
var ceiling_line = []
var floor_line = []
var tile_ground = preload("res://Scenes/TileGround.tscn")
var tile_water = preload("res://Scenes/TileWater.tscn")
var tile_lava = preload("res://Scenes/TileLava.tscn")
var tile_spike = preload("res://Scenes/TileSpike.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	generate_map()


func generate_map():
	prepare_matrix()
	add_floor()
	add_ceiling()
	render_matrix()


func prepare_matrix():
	for x in range(map_size.x):
		matrix.append([])
		for y in range(map_size.y):
			matrix[x].append(TILE.NONE)


func add_floor():
	var buffer: int = rand_int(3, 15)
	var current_height: int = rand_int(ground_min, ground_max)
	for x in range(map_size.x):
		if buffer <= 0:
			buffer = rand_int(3, 15)
			current_height = rand_int(ground_min, ground_max)
		floor_line.append(current_height)
		for y in range(current_height,map_size.y):
			matrix[x][y] = TILE.GROUND
		buffer -= 1


func add_ceiling():
	var buffer: int = rand_int(3, 15)
	var current_height: int = rand_int(ceiling_min, ceiling_max)
	for x in range(map_size.x):
		# fixed ceiling height above player spawn
		if x < 10:
			ceiling_line.append(0)
			matrix[x][0] = TILE.GROUND
			continue
		
		if buffer <= 0:
			buffer = rand_int(3, 15)
			current_height = rand_int(ceiling_min, ceiling_max)
		ceiling_line.append(current_height)
		for y in range(0, current_height):
			matrix[x][y] = TILE.GROUND
		buffer -= 1


func render_matrix():
	print(matrix)
	for x in range(map_size.x):
		for y in range(map_size.y):
			var t
			match matrix[x][y]:
				TILE.GROUND:
					t = tile_ground.instance()
				TILE.WATER:
					t = tile_water.instance()
				TILE.LAVA:
					t = tile_lava.instance()
			if t:
				t.position = Vector2(x * 16, y * 16)
				add_child(t)


func rand_int(min_value,max_value, inclusive_range = true):
	if inclusive_range:
		max_value += 1
	var range_size = max_value - min_value
	return (randi() % range_size) + min_value
