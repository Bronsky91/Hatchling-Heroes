extends Node2D

export var map_size: Vector2 = Vector2(500,34)
export var spawn_width: int = 10
export var strip_min: int = 3
export var strip_max: int = 30
export var ceiling_min: int = 2
export var ceiling_max: int = 8
export var ground_min: int = 15
export var ground_max: int = 22

enum TILE {NONE, GROUND, WATER, LAVA, SPIKE_UP, SPIKE_DOWN, SPIKE_WATER, PLATFORM = -1}
var matrix = []
var ceiling_line = []
var floor_line = []
var water_tops = []
var water_bottoms = []
var pit_tops = []
var pit_bottoms = []
var lava_line = []
var tile_ground = preload("res://Scenes/TileGround.tscn")
var tile_water = preload("res://Scenes/TileWater.tscn")
var tile_lava = preload("res://Scenes/TileLava.tscn")
var tile_spike = preload("res://Scenes/TileSpike.tscn")
var tile_submerged_spike = preload("res://Scenes/TileSubmergedSpike.tscn")
var tile_platform = preload("res://Scenes/TilePlatform.tscn")

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
					if matrix[i][strip_height - 1] == TILE.SPIKE_UP:
						matrix[i][strip_height - 1] = TILE.NONE
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

func add_platforms(gap_start: int, gap_stop: int, gap_height: int):
	var platform_width = 3
	var jumpable_start = gap_start - 1 if matrix[gap_start - 1][gap_height - 1] == TILE.NONE else gap_start - 2
	var jumpable_stop = gap_stop + 1 if matrix[gap_stop + 1][gap_height - 1] == TILE.NONE else gap_start + 2
	print("add_platforms - gap_start:" + str(gap_start) + " gap_stop:" + str(gap_stop) + " gap_height:" + str(gap_height) + " jumpable_start:" + str(jumpable_start) + " jumpable_stop:" + str(jumpable_stop))
	# start at first free ground tile preceding gap
	# place first platform either [up 3, right 2-3] or [up 2, right 2-4]
	var platform_y = rand_int(2,3)
	var platform_x = rand_int(2,4) if platform_y == 2 else rand_int(2,3)
	platform_x = gap_start + platform_x
	platform_y = gap_height - platform_y
	print("platform_x:" + str(platform_x) + " platform_y:" + str(platform_y))
	matrix[platform_x][platform_y] = TILE.PLATFORM
	
	var gap_clearable: bool = false
	while !gap_clearable:
		# check if gap is now clearable (4 away for elevation 2, 5 away for elevation 3, etc)
		var distance_x = jumpable_stop - (platform_x + platform_width)
		var distance_y = gap_height - platform_y
		print("distance_x:" + str(distance_x) + " distance_y:" + str(distance_y))
		if distance_x - distance_y <= 2:
			print("gap_clearable!")
			gap_clearable = true
		else:
			print("gap not clearable!")
			# not there yet, place new platform. viable options are:
			# [up 0, right 3-5], [up 1, right 3-5], [up 2, right 2-4], [up 3, right 2-3]
			# TODO: if no valid placements, rebuild cave
			var valid_placement: bool = false
			while !valid_placement:
				var new_y: int = rand_int(0,3)
				var new_x: int
				match new_y:
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
				print("new_x:" + str(new_x) + " new_y:" + str(new_y))
				var is_valid = true
				# ensure platform is not on or immediately below/above spikes
				for i in range(new_x, new_x + platform_width + 1):
					for j in range(0,3):
						if i > 0 and j < map_size.y:
							if matrix[i][j] == TILE.SPIKE_UP or matrix[i][j] == TILE.SPIKE_DOWN:
								is_valid = false
								break
						else:
							is_valid = false
							break
				if is_valid:
					platform_x = new_x
					platform_y = new_y
					matrix[platform_x][platform_y] = TILE.PLATFORM
					print("valid! -- placing platform at:" + str(platform_x) + "," + str(platform_y))
					valid_placement = true

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
				TILE.PLATFORM:
					print("placing platform at: " + str(x) +","+str(y))
					t = tile_platform.instance()
			if t:
				t.position = Vector2(x * 16, y * 16)
				add_child(t)

func rand_int(min_value: int,max_value: int, inclusive_range = true):
	if inclusive_range:
		max_value += 1
	var range_size = max_value - min_value
	return (randi() % range_size) + min_value
