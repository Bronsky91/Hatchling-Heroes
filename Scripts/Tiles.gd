extends Node2D

export var map_size: Vector2 = Vector2(300,28)
export var spawn_width: int = 10
export var strip_min: int = 3
export var strip_max: int = 15
export var ceiling_min: int = 2
export var ceiling_max: int = 6
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
	add_water()
	render_matrix()


func prepare_matrix():
	for x in range(map_size.x + 1):
		matrix.append([])
		for y in range(map_size.y + 1):
			matrix[x].append(TILE.NONE)


func add_floor():
	var buffer: int = rand_int(strip_min, strip_max)
	var current_height: int = rand_int(ground_min, ground_max)
	for x in range(map_size.x + 1):
		# fixed ground height below player spawn
		if x < spawn_width:
			floor_line.append(ground_min)
			for y in range(ground_min,map_size.y + 1):
				matrix[x][y] = TILE.GROUND
		else:
			if buffer <= 0:
				buffer = rand_int(strip_min, strip_max)
				current_height = rand_int(ground_min, ground_max)
			floor_line.append(current_height)
			for y in range(current_height,map_size.y + 1):
				matrix[x][y] = TILE.GROUND
			buffer -= 1


func add_ceiling():
	var buffer: int = rand_int(strip_min, strip_max)
	var current_height: int = rand_int(ceiling_min, ceiling_max)
	for x in range(map_size.x + 1):
		# fixed ceiling height above player spawn
		if x < spawn_width:
			ceiling_line.append(0)
			matrix[x][0] = TILE.GROUND
			continue
		
		if buffer <= 0:
			buffer = rand_int(strip_min, strip_max)
			current_height = rand_int(ceiling_min, ceiling_max)
		ceiling_line.append(current_height)
		for y in range(0, current_height + 1):
			matrix[x][y] = TILE.GROUND
		buffer -= 1


func add_water():
	var strip_start: int = 0
	var strip_height: int = floor_line[0]
	var is_first_strip: bool = true
	for x in range(1, map_size.x + 1):
		# if floor elevation has changed, check how long the past strip was
		if floor_line[x] != strip_height:
			var strip_len = x - 1 - strip_start
			# if longer than 3 tiles, %25 to replace last strip with water
			# (always skip first strip however, as it will be the spawn area)
			if strip_len >= 3 and is_first_strip:
				is_first_strip = false
			elif strip_len >= 4 and rand_int(1,1) == 1:
				var water_len_min = strip_len - 4 if strip_len - 4 > 2 else 2
				var water_len = rand_int(water_len_min, strip_len - 2)
				var water_height = rand_int(strip_height, ground_max)
				var start_padding = rand_int(1, strip_len - water_len - 1)
				for i in range(strip_start + start_padding, strip_start + water_len + 1):
					for j in range(strip_height, water_height + 1):
						matrix[i][j] = TILE.WATER
			strip_start = x
			strip_height = floor_line[x]


func render_matrix():
	for x in range(map_size.x + 1):
		for y in range(map_size.y + 1):
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
