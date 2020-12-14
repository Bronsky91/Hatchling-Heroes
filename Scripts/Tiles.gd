extends Node2D

export var map_size: Vector2 = Vector2(500,34)
export var spawn_width: int = 10
export var strip_min: int = 3
export var strip_max: int = 30
export var ceiling_min: int = 2
export var ceiling_max: int = 8
export var ground_min: int = 15
export var ground_max: int = 22

enum TILE {NONE, GROUND, WATER, LAVA, SPIKE_UP, SPIKE_UP_A, SPIKE_UP_B, SPIKE_DOWN, SPIKE_DOWN_A, SPIKE_DOWN_B, SPIKE_WATER, SPIKE_WATER, SPIKE_WATER_A, SPIKE_WATER_B, PLATFORM = -1}
var matrix = []
var ceiling_line = []
var floor_line = []
var water_tops = []
var water_bottoms = []
var pit_tops = []
var pit_bottoms = []
var lava_line = []
var tile_ground = preload("res://Scenes/Tiles/Ground.tscn")
var tile_water_surface = preload("res://Scenes/Tiles/WaterSurface.tscn")
var tile_water_fill = preload("res://Scenes/Tiles/WaterFill.tscn")
var tile_lava = preload("res://Scenes/Tiles/Lava.tscn")
var tile_platform = preload("res://Scenes/Tiles/Platform_01.tscn")
var tile_spike_u_01 = preload("res://Scenes/Tiles/SpikeU_01.tscn")
var tile_spike_u_02 = preload("res://Scenes/Tiles/SpikeU_02.tscn")
var tile_spike_u_03a = preload("res://Scenes/Tiles/SpikeU_03a.tscn")
var tile_spike_u_03b = preload("res://Scenes/Tiles/SpikeU_03b.tscn")
var tile_spike_d_01 = preload("res://Scenes/Tiles/SpikeD_01.tscn")
var tile_spike_d_02 = preload("res://Scenes/Tiles/SpikeD_02.tscn")
var tile_spike_d_03a = preload("res://Scenes/Tiles/SpikeD_03a.tscn")
var tile_spike_d_03b = preload("res://Scenes/Tiles/SpikeD_03b.tscn")
var tile_spike_w_01 = preload("res://Scenes/Tiles/SpikeW_01.tscn")
var tile_spike_w_02 = preload("res://Scenes/Tiles/SpikeW_02.tscn")
var tile_spike_w_03a = preload("res://Scenes/Tiles/SpikeW_03a.tscn")
var tile_spike_w_03b = preload("res://Scenes/Tiles/SpikeW_03b.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	generate_map()

func generate_map():
	prepare_matrix()
	add_floor()
	add_ceiling()
	add_water_and_pits()
	add_lava()
	render_matrix()

func prepare_matrix():
	for x in range(map_size.x + 1):
		matrix.append([])
		water_tops.append(int(0))
		water_bottoms.append(int(0))
		pit_tops.append(int(0))
		pit_bottoms.append(int(0))
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

func add_water_and_pits():
	var strip_start: int = 0
	var strip_height: int = floor_line[0]
	var is_strip_water: bool
	var is_first_strip: bool = true
	for x in range(1, map_size.x + 1):
		# if floor elevation has changed, check how long the past strip was
		if floor_line[x] != strip_height:
			var strip_len = x - 1 - strip_start
			# if longer than 3 tiles, %50 to replace last strip with water or pit
			# (always skip first strip however, as it will be the spawn area)
			if strip_len >= 3 and is_first_strip:
				is_first_strip = false
			elif strip_len >= 4 and rand_int(1,2) == 1:
				# calculate water / pit dimensions
				is_strip_water = rand_int(1,2) == 1 # 50% chance to make this either water or a spike pit
				var new_len_min = strip_len - 4 if strip_len - 4 > 2 else 2
				var new_len = rand_int(new_len_min, strip_len - 2)
				var new_depth = rand_int(strip_height + 4, strip_height + 8)
				var start_padding = rand_int(1, strip_len - new_len - 1)
				# pass start and length details to platform adding function
				add_platforms(strip_start + start_padding, strip_start + new_len, strip_height)
				# process calculated water / pit dimensions
				for i in range(strip_start + start_padding, strip_start + new_len + 1):
					# cleanup any spikes floating above where this new water or pit is
					matrix[i][strip_height - 1] = TILE.NONE
					matrix[i][strip_height - 2] = TILE.NONE
					# make note of top and bottom heights of new water or pit
					if is_strip_water:
						water_tops[i] = strip_height
						water_bottoms[i] = new_depth
					else:
						pit_tops[i] = strip_height
						pit_bottoms[i] = new_depth
					# fill in tiles as water or none to make a pit
					for j in range(strip_height, new_depth + 1):
						matrix[i][j] = TILE.WATER if is_strip_water else TILE.NONE
					# add spike to bottom of water or pit
					add_spike(Vector2(i,new_depth),Vector2.UP,is_strip_water)
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
				if pit_bottoms[x - i] >= current_height - 4:
					current_height = pit_bottoms[x - i] + 4
			if x + i <= map_size.x:
				if floor_line[x + i] >= current_height - 4:
					current_height = floor_line[x + i] + 4
				if water_bottoms[x + i] >= current_height - 4:
					current_height = water_bottoms[x + i] + 4
				if pit_bottoms[x + i] >= current_height - 4:
					current_height = pit_bottoms[x + i] + 4
		lava_line.append(current_height)
		for y in range(current_height, map_size.y + 1):
			matrix[x][y] = TILE.LAVA
		strip_buffer -= 1

func can_spike_go_here(coord: Vector2):
	# flag invalid if too close to existing tile
	for i in range(1,3):
		if coord.x - i > 0 and matrix[coord.x - i][coord.y] != TILE.NONE:
			return false
		if coord.x + i < map_size.x and matrix[coord.x + i][coord.y] != TILE.NONE:
			return false
		if coord.y - i > 0 and matrix[coord.x][coord.y - i] != TILE.NONE:
			return false
	#  or if first tile after climb
	if coord.x > 0 and floor_line[coord.x - 1] - (coord.y + 1) > 1:
		return false
	return true

func add_spike(coord: Vector2, facing: Vector2, submerged: bool):
	var spike_height = rand_int(1,2)
	if facing == Vector2.UP and spike_height == 1:
		matrix[coord.x][coord.y] = TILE.SPIKE_WATER if submerged else TILE.SPIKE_UP
	elif facing == Vector2.UP and spike_height == 2:
		matrix[coord.x][coord.y] = TILE.SPIKE_WATER_A if submerged else TILE.SPIKE_UP_A
		matrix[coord.x][coord.y - 1] = TILE.SPIKE_WATER_B if submerged else TILE.SPIKE_UP_B
	elif facing == Vector2.DOWN and spike_height == 1:
		matrix[coord.x][coord.y] = TILE.SPIKE_DOWN
	elif facing == Vector2.DOWN and spike_height == 2:
		matrix[coord.x][coord.y] = TILE.SPIKE_DOWN_A
		matrix[coord.x][coord.y + 1] = TILE.SPIKE_DOWN_B

func add_platforms(gap_start: int, gap_stop: int, gap_height: int):
	var platform_width = 3
	var jumpable_start = gap_start - 1 if matrix[gap_start - 1][gap_height - 1] == TILE.NONE else gap_start - 2
	var jumpable_stop = gap_stop + 1 if matrix[gap_stop + 1][gap_height - 1] == TILE.NONE else gap_stop + 2
	# start at first free ground tile preceding gap
	# place first platform either [up 3, right 2-3] or [up 2, right 2-4]
	var platform_y = rand_int(2,3)
	var platform_x = rand_int(2,4) if platform_y == 2 else rand_int(2,3)
	platform_x = gap_start + platform_x
	platform_y = gap_height - platform_y
	matrix[platform_x][platform_y] = TILE.PLATFORM
	
	var gap_clearable: bool = false
	var iteration_counter: int = 20
	while !gap_clearable and iteration_counter > 0:
		# check if gap is now clearable (4 away for elevation 2, 5 away for elevation 3, etc)
		var distance_x = jumpable_stop - (platform_x + platform_width)
		var distance_y = gap_height - platform_y
		if distance_x - distance_y <= 2:
			gap_clearable = true
		else:
			# not there yet, place new platform. viable options are:
			# [down 1, right 4-6], [up 0, right 3-5], [up 1, right 3-5], [up 2, right 2-4], [up 3, right 2-3]
			# TODO: if no valid placements, rebuild cave
			var valid_placement: bool = false
			while !valid_placement and iteration_counter > 0:
				var new_y: int = rand_int(-1,3)
				var new_x: int
				match new_y:
					-1:
						new_x = rand_int(4,6)
					0:
						new_x = rand_int(3,5)
					1:
						new_x = rand_int(3,5)
					2:
						new_x = rand_int(2,4)
					3:
						new_x = rand_int(2,3)
				new_x = platform_x + platform_width + new_x
				new_y = platform_y - new_y
				var is_valid = true
				# ensure platform is not pressed up against anything
				for x in range(new_x - 1, new_x + platform_width + 2):
					if !is_valid:
						break
					for y in range(new_y - 1, new_y + 2):
						if x > 0 and y < map_size.y:
							if matrix[x][y] != TILE.NONE:
								is_valid = false
								break
						else:
							is_valid = false
							break
				if is_valid:
					platform_x = new_x
					platform_y = new_y
					matrix[platform_x][platform_y] = TILE.PLATFORM
					iteration_counter = 20
					valid_placement = true
				else:
					iteration_counter -= 1
					if iteration_counter == 0:
						print("failed to find valid platform placement! gave up covering gap...")

func is_tile_a_spike(x: int, y: int):
	return TILE.keys()[matrix[x][y]].begins_with("SPIKE")

func render_matrix():
	for x in range(map_size.x + 1):
		for y in range(map_size.y + 1):
			var t
			match matrix[x][y]:
				TILE.GROUND:
					t = tile_ground.instance()
				TILE.WATER:
					t = tile_water_surface.instance() if water_tops[x] == y else tile_water_fill.instance()
				TILE.LAVA:
					t = tile_lava.instance()
				TILE.SPIKE_UP:
					t = tile_spike_u_01.instance() if rand_int(1,2) == 1 else tile_spike_u_02.instance()
				TILE.SPIKE_UP_A:
					t = tile_spike_u_03a.instance()
				TILE.SPIKE_UP_B:
					t = tile_spike_u_03b.instance()
				TILE.SPIKE_DOWN:
					t = tile_spike_d_01.instance() if rand_int(1,2) == 1 else tile_spike_d_02.instance()
				TILE.SPIKE_DOWN_A:
					t = tile_spike_d_03a.instance()
				TILE.SPIKE_DOWN_B:
					t = tile_spike_d_03b.instance()
				TILE.SPIKE_WATER:
					t = tile_spike_w_01.instance() if rand_int(1,2) == 1 else tile_spike_w_02.instance()
				TILE.SPIKE_WATER_A:
					t = tile_spike_w_03a.instance()
				TILE.SPIKE_WATER_B:
					t = tile_spike_w_03b.instance()
				TILE.PLATFORM:
					t = tile_platform.instance()
			if t:
				t.position = Vector2(x * 16, y * 16)
				add_child(t)

func rand_int(min_value: int,max_value: int, inclusive_range = true):
	if inclusive_range:
		max_value += 1
	var range_size = max_value - min_value
	return (randi() % range_size) + min_value
