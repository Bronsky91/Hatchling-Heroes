extends Node2D

export var map_size: Vector2 = Vector2(500,34)
export var spawn_width: int = 10
export var strip_min: int = 3
export var strip_max: int = 30
export var ceiling_min: int = 2
export var ceiling_max: int = 8
export var ground_min: int = 15
export var ground_max: int = 22

enum TILE {NONE, GROUND, WATER, LAVA, SPIKE_UP, SPIKE_DOWN, SPIKE_WATER = -1}
var matrix = []
var ceiling_line = []
var floor_line = []
var water_tops = []
var water_bottoms = []
var lava_line = []
var tile_ground = preload("res://Scenes/TileGround.tscn")
var tile_water = preload("res://Scenes/TileWater.tscn")
var tile_lava = preload("res://Scenes/TileLava.tscn")
var tile_spike = preload("res://Scenes/TileSpike.tscn")
var tile_submerged_spike = preload("res://Scenes/TileSubmergedSpike.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	generate_map()

func generate_map():
	prepare_matrix()
	add_floor()
	add_ceiling()
	add_water()
	add_lava()
	render_matrix()

func prepare_matrix():
	for x in range(map_size.x + 1):
		matrix.append([])
		water_tops.append(int(0))
		water_bottoms.append(int(0))
		for y in range(map_size.y + 1):
			matrix[x].append(TILE.NONE)

func add_floor():
	var strip_buffer: int = rand_int(strip_min, strip_max)
	var current_height: int = rand_int(ground_min, ground_max)
	for x in range(map_size.x + 1):
		# fixed ground height below player spawn
		if x < spawn_width:
			floor_line.append(ground_min)
			for y in range(ground_min,map_size.y + 1):
				matrix[x][y] = TILE.GROUND
		else:
			if strip_buffer <= 0:
				strip_buffer = rand_int(strip_min, strip_max)
				current_height = rand_int(ground_min, ground_max)
			floor_line.append(current_height)
			# 1 in 3 chance to add a spike here if a valid spot
			if rand_int(1,3) == 1:
				if can_spike_go_here(Vector2(x,current_height - 1)):
					add_spike(Vector2(x,current_height - 1),Vector2.UP,false)
			# fill in rest of floor with ground tiles
			for y in range(current_height,map_size.y + 1):
				matrix[x][y] = TILE.GROUND
			strip_buffer -= 1

func add_ceiling():
	var strip_buffer: int = rand_int(strip_min, strip_max)
	var current_height: int = rand_int(ceiling_min, ceiling_max)
	for x in range(map_size.x + 1):
		# fixed ceiling height above player spawn
		if x < spawn_width:
			ceiling_line.append(int(0))
			matrix[x][0] = TILE.GROUND
			continue
		
		if strip_buffer <= 0:
			strip_buffer = rand_int(strip_min, strip_max)
			current_height = rand_int(ceiling_min, ceiling_max)
		ceiling_line.append(current_height)
		# 1 in 3 chance to add a spike here
		if rand_int(1,3) == 1:
			add_spike(Vector2(x,current_height + 1),Vector2.DOWN,false)
		for y in range(0, current_height + 1):
			matrix[x][y] = TILE.GROUND
		strip_buffer -= 1

func add_water():
	var strip_start: int = 0
	var strip_height: int = floor_line[0]
	var is_first_strip: bool = true
	for x in range(1, map_size.x + 1):
		# if floor elevation has changed, check how long the past strip was
		if floor_line[x] != strip_height:
			var strip_len = x - 1 - strip_start
			# if longer than 3 tiles, %50 to replace last strip with water
			# (always skip first strip however, as it will be the spawn area)
			if strip_len >= 3 and is_first_strip:
				is_first_strip = false
			elif strip_len >= 4 and rand_int(1,2) == 1:
				var water_len_min = strip_len - 4 if strip_len - 4 > 2 else 2
				var water_len = rand_int(water_len_min, strip_len - 2)
				var water_depth = rand_int(strip_height + 4, strip_height + 8)
				var start_padding = rand_int(1, strip_len - water_len - 1)
				for i in range(strip_start + start_padding, strip_start + water_len + 1):
					water_tops[i] = strip_height
					water_bottoms[i] = water_depth
					# cleanup any spikes floating above where this new water is
					if matrix[i][strip_height - 1] == TILE.SPIKE_UP:
						matrix[i][strip_height - 1] = TILE.NONE
					for j in range(strip_height, water_depth + 1):
						matrix[i][j] = TILE.WATER
					# add submerged spike to bottom of water
					add_spike(Vector2(i,water_depth),Vector2.UP,true)
			strip_start = x
			strip_height = floor_line[x]

func add_lava():
	var strip_buffer: int = rand_int(strip_min, strip_max)
	var current_height: int = rand_int(ground_min + 2, map_size.y)
	for x in range(map_size.x + 1):
		# ensure bottom tile is always lava no matter what
		matrix[x][map_size.y] = TILE.LAVA
		
		if strip_buffer <= 0:
			strip_buffer = rand_int(strip_min, strip_max)
			current_height = rand_int(floor_line[x] + 2, map_size.y)
		# ensure lava has 4 spaces of padding from any nearby floor top or water bottom
		for i in range(0,4):
			if x - i >= 0:
				if floor_line[x - i] >= current_height - 4:
					current_height = floor_line[x - i] + 4
				if water_bottoms[x - i] >= current_height - 4:
					current_height = water_bottoms[x - i] + 4
			if x + i <= map_size.x:
				if floor_line[x + i] >= current_height - 4:
					current_height = floor_line[x + i] + 4
				if water_bottoms[x + i] >= current_height - 4:
					current_height = water_bottoms[x + i] + 4
		lava_line.append(current_height)
		for y in range(current_height, map_size.y + 1):
			matrix[x][y] = TILE.LAVA
		strip_buffer -= 1

func can_spike_go_here(coord: Vector2):
	# flag invalid if too close to existing spike
	for i in range(1,3):
		if coord.x - i > 0:
			if matrix[coord.x - i][coord.y] == TILE.SPIKE_UP:
				return false
		if coord.x + i < map_size.x:
			if matrix[coord.x + i][coord.y] == TILE.SPIKE_UP:
				return false
	#  or if first tile after climb
	if coord.x > 0 and floor_line[coord.x - 1] - (coord.y + 1) > 1:
		return false
	return true

func add_spike(coord: Vector2, facing: Vector2, submerged: bool):
	match facing:
		Vector2.UP:
			matrix[coord.x][coord.y] = TILE.SPIKE_WATER if submerged else TILE.SPIKE_UP
		Vector2.DOWN:
			matrix[coord.x][coord.y] = TILE.SPIKE_WATER if submerged else TILE.SPIKE_DOWN

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
				TILE.SPIKE_UP:
					t = tile_spike.instance()
				TILE.SPIKE_DOWN:
					t = tile_spike.instance()
					t.flip_upside_down()
				TILE.SPIKE_WATER:
					t = tile_submerged_spike.instance()
			if t:
				t.position = Vector2(x * 16, y * 16)
				add_child(t)

func rand_int(min_value: int,max_value: int, inclusive_range = true):
	if inclusive_range:
		max_value += 1
	var range_size = max_value - min_value
	return (randi() % range_size) + min_value
