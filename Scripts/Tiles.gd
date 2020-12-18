extends Node2D

export var map_size: Vector2 = Vector2(500,34)
export var spawn_width: int = 10
export var strip_min: int = 3
export var strip_max: int = 30
export var ceiling_min: int = 2
export var ceiling_max: int = 8
export var ground_min: int = 15
export var ground_max: int = 22

enum PIT_TYPE {WATER, LAVA, SPIKE = -1}
enum TILE {NONE, GROUND_FLOOR, GROUND_CEIL, WATER, LAVA, SPIKE_UP, SPIKE_UP_A, SPIKE_UP_B, SPIKE_DOWN, SPIKE_DOWN_A, SPIKE_DOWN_B, SPIKE_WATER, SPIKE_WATER, SPIKE_WATER_A, SPIKE_WATER_B, PLATFORM, PLATFORM_SPIKE = -1}
var matrix = []
var ceiling_line = []
var floor_line = []
var water_tops = []
var water_bottoms = []
var lava_tops = []
var lava_bottoms = []
var pit_tops = []
var pit_bottoms = []
var lava_line = []
var platform_sprites = []
var water_filter = preload("res://Scenes/WaterFilter.tscn")
var tile_ground = preload("res://Scenes/Tiles/Ground.tscn")
var tile_water_surface = preload("res://Scenes/Tiles/WaterSurface.tscn")
var tile_water_fill = preload("res://Scenes/Tiles/WaterFill.tscn")
var tile_lava_surface = preload("res://Scenes/Tiles/LavaSurface.tscn")
var tile_lava_fill = preload("res://Scenes/Tiles/LavaFill.tscn")
var tile_lava = preload("res://Scenes/Tiles/Lava.tscn")
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
	add_pits()
	add_platforms()
	#add_lava()
	render_matrix()

func prepare_matrix():
	for x in range(map_size.x):
		matrix.append([])
		water_tops.append(int(0))
		water_bottoms.append(int(0))
		lava_tops.append(int(0))
		lava_bottoms.append(int(0))
		pit_tops.append(int(0))
		pit_bottoms.append(int(0))
		platform_sprites.append([])
		for y in range(map_size.y):
			matrix[x].append(TILE.NONE)
			platform_sprites[x].append(int(0))

func add_floor():
	var strip_buffer: int = rand_int(strip_min, strip_max)
	var current_height: int = rand_int(ground_min, ground_max)
	for x in range(map_size.x):
		# fixed ground height below player spawn
		if x < spawn_width:
			floor_line.append(ground_min)
			for y in range(ground_min,map_size.y):
				matrix[x][y] = TILE.GROUND_FLOOR
		else:
			if strip_buffer <= 0:
				strip_buffer = rand_int(strip_min, strip_max)
				current_height = rand_int(ground_min, ground_max)
			floor_line.append(current_height)
			# 1 in 8 chance to add a spike here if a valid spot
			if rand_int(1,8) == 1:
				if can_spike_go_here(Vector2(x,current_height - 1)):
					add_spike(Vector2(x,current_height - 1),Vector2.UP,false)
			# fill in rest of floor with ground tiles
			for y in range(current_height,map_size.y):
				matrix[x][y] = TILE.GROUND_FLOOR
			strip_buffer -= 1

func add_ceiling():
	var strip_buffer: int = rand_int(strip_min, strip_max)
	var current_height: int = rand_int(ceiling_min, ceiling_max)
	for x in range(map_size.x):
		# fixed ceiling height above player spawn
		if x < spawn_width:
			ceiling_line.append(int(0))
			matrix[x][0] = TILE.GROUND_CEIL
			continue
		
		if strip_buffer <= 0:
			strip_buffer = rand_int(strip_min, strip_max)
			current_height = rand_int(ceiling_min, ceiling_max)
		ceiling_line.append(current_height)
		# 1 in 3 chance to add a spike here
		if rand_int(1,3) == 1:
			add_spike(Vector2(x,current_height),Vector2.DOWN,false)
		for y in range(0, current_height):
			matrix[x][y] = TILE.GROUND_CEIL
		strip_buffer -= 1

func add_pits():
	var strip_start: int = 0
	var strip_height: int = floor_line[0]
	var is_first_strip: bool = true
	var pit_type: int = -1
	for x in range(1, map_size.x):
		# if floor elevation has changed, check how long the past strip was
		if floor_line[x] != strip_height:
			var strip_len = x - 1 - strip_start
			# if longer than 3 tiles, %50 to replace last strip with water or pit
			# (always skip first strip however, as it will be the spawn area)
			if strip_len >= 3 and is_first_strip:
				is_first_strip = false
			elif strip_len >= 4 and rand_int(1,2) == 1:
				# calculate water / pit dimensions
				pit_type = rand_int(0,2) # 33.3% chance to make this pit either water, lava, or spikes
				var new_len_min = strip_len - 4 if strip_len - 4 > 2 else 2
				var new_len = rand_int(new_len_min, strip_len - 2)
				var new_depth = rand_int(strip_height + 4, strip_height + 8)
				var start_padding = rand_int(1, strip_len - new_len - 1)
				
				# process calculated water / pit dimensions
				for i in range(strip_start + start_padding, strip_start + new_len):
					# cleanup any spikes floating above where this new water or pit is
					matrix[i][strip_height - 1] = TILE.NONE
					matrix[i][strip_height - 2] = TILE.NONE
					# bump floor line down below bottom of new water or pit
					floor_line[i] = new_depth + 1
					# make note of top and bottom heights of new water or pit
					var tile: int
					match pit_type:
						PIT_TYPE.WATER:
							water_tops[i] = strip_height
							water_bottoms[i] = new_depth
							tile = TILE.WATER
						PIT_TYPE.LAVA:
							lava_tops[i] = strip_height
							lava_bottoms[i] = new_depth
							tile = TILE.LAVA
						PIT_TYPE.SPIKE:
							pit_tops[i] = strip_height
							pit_bottoms[i] = new_depth
							tile = TILE.NONE
					# fill pit with water, lava, or air
					for j in range(strip_height, new_depth):
						matrix[i][j] = tile
					# add spike to bottom of water or spike pit
					if pit_type == PIT_TYPE.WATER or pit_type == PIT_TYPE.SPIKE:
						add_spike(Vector2(i, new_depth), Vector2.UP, pit_type == PIT_TYPE.WATER)
				# if water, add water filter over designated area
				if pit_type == PIT_TYPE.WATER:
					var filter = water_filter.instance()
					filter.scale = Vector2(new_len + 0.5, new_depth + 0.5)
					filter.set_shader_scale()
					filter.position = Vector2((strip_start + start_padding - 0.5) * 16, (strip_height - 0.5) * 16)
					add_child(filter)
			strip_start = x
			strip_height = floor_line[x]

func add_platforms():
	var water_strip_start: int = 0
	var water_strip_height: int = 0
	var water_strip_end: int = 0
	var in_water_strip: bool = false
	var lava_strip_start: int = 0
	var lava_strip_height: int = 0
	var lava_strip_end: int = 0
	var in_lava_strip: bool = false
	var pit_strip_start: int = 0
	var pit_strip_height: int = 0
	var pit_strip_end: int = 0
	var in_pit_strip: bool = false
	for x in range(map_size.x):
		# if not processing water strip, seek the next one out
		if !in_water_strip and water_tops[x] != 0:
			in_water_strip = true
			water_strip_start = x
			water_strip_height = water_tops[x]
		# otherwise if processing water strip, seek its end and cover it in platforms
		elif in_water_strip and water_tops[x] == 0:
			in_water_strip = false
			water_strip_end = x - 1
			cover_gap_with_platforms(water_strip_start, water_strip_end, water_strip_height)
		
		# if not processing lava strip, seek the next one out
		if !in_lava_strip and lava_tops[x] != 0:
			in_lava_strip = true
			lava_strip_start = x
			lava_strip_height = lava_tops[x]
		# otherwise if processing lava strip, seek its end and cover it in platforms
		elif in_lava_strip and lava_tops[x] == 0:
			in_lava_strip = false
			lava_strip_end = x - 1
			cover_gap_with_platforms(lava_strip_start, lava_strip_end, lava_strip_height)
		
		# if not processing spike pit strip, seek the next one out
		if !in_pit_strip and pit_tops[x] != 0:
			in_pit_strip = true
			pit_strip_start = x
			pit_strip_height = pit_tops[x]
		# otherwise if processing spike pit strip, seek its end and cover it in platforms
		elif in_pit_strip and pit_tops[x] == 0:
			in_pit_strip = false
			pit_strip_end = x - 1
			cover_gap_with_platforms(pit_strip_start, pit_strip_end, pit_strip_height)

func cover_gap_with_platforms(gap_start: int, gap_stop: int, gap_height: int):
	var platform_width = rand_int(1,3)
	# jumpable_start = first non-spike tile preceeding gap.
	# since spikes can't spawn side-by-side, safely assume this will either be 1 or 2 tiles before gap
	var jumpable_start
	if gap_start - 1 < 0:
		jumpable_start = gap_start
	elif gap_start - 2 < 0:
		jumpable_start = gap_start - 1 if matrix[gap_start - 1][gap_height - 1] == TILE.NONE else gap_start
	else:
		jumpable_start = gap_start - 1 if matrix[gap_start - 1][gap_height - 1] == TILE.NONE else gap_start - 2
	# jumpable_stop = first non-spike tile following gap.
	# since spikes can't spawn side-by-side, safely assume this will either be 1 or 2 tiles after gap
	var jumpable_stop
	if gap_stop + 1 > map_size.x - 1:
		jumpable_stop = gap_stop
	elif gap_stop + 2 > map_size.x - 1:
		jumpable_stop = gap_stop + 1 if matrix[gap_stop + 1][gap_height - 1] == TILE.NONE else gap_stop
	else:
		jumpable_stop = gap_stop + 1 if matrix[gap_stop + 1][gap_height - 1] == TILE.NONE else gap_stop + 2
	 
	 
	# start at first free ground tile preceding gap
	# place first platform either [up 3, right 2-3] or [up 2, right 2-4]
	# TODO: confirm starting place is valid, or safe to assume it'll always be valid?
	var platform_y = rand_int(-3,-2)
	var platform_x = rand_int(2,4) if platform_y == -2 else rand_int(2,3)
	platform_x += gap_start
	platform_y += gap_height
	add_platform(platform_x, platform_y, platform_width)
	
	var gap_clearable: bool = false
	while !gap_clearable:
		# check if gap is now clearable (4 away for elevation 2, 5 away for elevation 3, etc)
		var dx1 = abs(platform_x + platform_width)
		var dx2 = abs(jumpable_stop)
		var dy1 = abs(gap_height)
		var dy2 = abs(platform_y)
		var distance_x = dx2 - dx1 if dx2 >= dx1 else dx1 - dx2 
		var distance_y = dy2 - dy1 if dy2 >= dy1 else dy1 - dy2
		if distance_x - distance_y <= 2:
			gap_clearable = true
		else:
			# not there yet, place new platform.
			# start by building an array of all possible placements:
			# [down 1, right 4-6], [up 0, right 3-5], [up 1, right 3-5], [up 2, right 2-4], [up 3, right 2-3]
			var placements = []
			placements.append(Vector3(1, 4, 6))
			placements.append(Vector3(0, 3, 5))
			placements.append(Vector3(-1, 3, 5))
			placements.append(Vector3(-2, 2, 4))
			placements.append(Vector3(-3, 2, 3))
			
			# loop through all possible placements, adding valid placements to new array
			var valid_placements = []
			for p in placements:
				var y = p.x
				for x in range(p.y, p.z):
					var new_x: int = x + platform_x + platform_width
					var new_y: int = y + platform_y
					# check placement validity for every possible new platform width (1-3)
					for new_width in range(1,4):
						if can_platform_go_here(new_x,new_y,new_width):
							valid_placements.append(Vector3(new_x,new_y,new_width))
			# once we have a list of possible placements, randomly chooose one!
			if valid_placements.size() == 0:
				print("NO VALID PLATFORM PLACEMENTS!")
				gap_clearable = true
				break
			# determine which valid placement we're going with, update vars, flag tiles
			var new_placement = valid_placements[rand_int(0,valid_placements.size() - 1)]
			platform_x = new_placement.x
			platform_y = new_placement.y
			platform_width = new_placement.z
			add_platform(platform_x, platform_y, platform_width)

func add_platform(x: int, y: int, width: int):
	var sprite_sets
	if width == 1:
		 sprite_sets = ["01"]
	elif width == 2:
		sprite_sets = ["01","02","03","04"]
	elif width == 3:
		sprite_sets = ["02","03","04"]
	var sprite_set = sprite_sets[rand_int(0,sprite_sets.size() - 1)]
	var counter = 0
	for i in range(x, x + width):
		counter += 1
		platform_sprites[i][y] = sprite_set
		matrix[i][y] = TILE.PLATFORM
		if (counter == 2 or counter == 3) and sprite_set == "04":
			matrix[i][y + 1] = TILE.PLATFORM_SPIKE
			platform_sprites[i][y + 1] = sprite_set

func can_platform_go_here(x: int, y: int, width: int):
	# check for 2 tile free margin around potential new platform spot
	for i in range(x - 2, x + width + 2):
		for j in range(y - 2, y + 2):
			if i > 0 and i < map_size.x - 1 and j > 0 and j < map_size.y - 1:
				if matrix[i][j] != TILE.NONE:
					return false
			else:
				return false
	return true


func add_lava():
	var strip_buffer: int = rand_int(strip_min, strip_max)
	var current_height: int = rand_int(ground_min + 2, map_size.y - 1)
	for x in range(map_size.x):
		# ensure bottom tile is always lava no matter what
		matrix[x][map_size.y - 1] = TILE.LAVA
		
		if strip_buffer <= 0:
			strip_buffer = rand_int(strip_min, strip_max)
			current_height = rand_int(floor_line[x] + 2, map_size.y - 1)
		# ensure lava has 4 spaces of padding from any nearby floor top or water bottom
		for i in range(0,4):
			if x - i >= 0:
				if floor_line[x - i] >= current_height - 4:
					current_height = floor_line[x - i] + 4
				if water_bottoms[x - i] >= current_height - 4:
					current_height = water_bottoms[x - i] + 4
				if pit_bottoms[x - i] >= current_height - 4:
					current_height = pit_bottoms[x - i] + 4
			if x + i <= map_size.x - 1:
				if floor_line[x + i] >= current_height - 4:
					current_height = floor_line[x + i] + 4
				if water_bottoms[x + i] >= current_height - 4:
					current_height = water_bottoms[x + i] + 4
				if pit_bottoms[x + i] >= current_height - 4:
					current_height = pit_bottoms[x + i] + 4
		lava_line.append(current_height)
		for y in range(current_height, map_size.y):
			matrix[x][y] = TILE.LAVA
		strip_buffer -= 1

func can_spike_go_here(coord: Vector2):
	# flag invalid if too close to existing tile
	for i in range(1,3):
		if coord.x - i > 0 and matrix[coord.x - i][coord.y] != TILE.NONE:
			return false
		if coord.x + i < map_size.x - 1 and matrix[coord.x + i][coord.y] != TILE.NONE:
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

func is_tile_a_spike(x: int, y: int):
	return TILE.keys()[matrix[x][y]].begins_with("SPIKE")

func render_matrix():
	for x in range(map_size.x):
		for y in range(map_size.y):
			var t
			match matrix[x][y]:
				TILE.GROUND_FLOOR:
					t = tile_ground.instance()
					render_ground(t,x,y,true)
				TILE.GROUND_CEIL:
					t = tile_ground.instance()
					render_ground(t,x,y,false)
				TILE.WATER:
					t = tile_water_surface.instance() if water_tops[x] == y else tile_water_fill.instance()
				TILE.LAVA:
					t = tile_lava_surface.instance() if lava_tops[x] == y else tile_lava_fill.instance()
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
					t = render_platform(x,y)
				TILE.PLATFORM_SPIKE:
					t = render_platform_spike(x,y)
			if t:
				t.position = Vector2(x * 16, y * 16)
				add_child(t)

func render_platform(x: int, y: int):
	var has_neighbor_left: bool = false
	var has_neighbor_right: bool = false
	if x - 1 >= 0 and matrix[x - 1][y] == TILE.PLATFORM:
		has_neighbor_left = true
	if x + 1 <= map_size.x - 1 and matrix[x + 1][y] == TILE.PLATFORM:
		has_neighbor_right = true
	var suffix = ""
	if !has_neighbor_left and !has_neighbor_right:
		suffix = "_small"
	elif has_neighbor_left and !has_neighbor_right:
		suffix = "_right"
	elif !has_neighbor_left and has_neighbor_right:
		suffix = "_left"
	elif has_neighbor_left and has_neighbor_right:
		suffix = "_middle"
	var tile_path = "res://Scenes/Tiles/platform_" + platform_sprites[x][y] + suffix + ".tscn"
	var tile_platform = load(tile_path)
	if suffix == "_small" and platform_sprites[x][y] != "01":
		print("x:" + str(x) + ",y:" + str(y) + ",tile_path: " + tile_path)
	return tile_platform.instance()

func render_platform_spike(x: int, y: int):
	var has_neighbor_left: bool = false
	var has_neighbor_right: bool = false
	if x - 1 >= 0 and y - 1 >= 0 and matrix[x - 1][y - 1] == TILE.PLATFORM:
		has_neighbor_left = true
	if x + 1 <= map_size.x - 1 and y - 1 >= 0 and matrix[x + 1][y - 1] == TILE.PLATFORM:
		has_neighbor_right = true
	var suffix = ""
	if !has_neighbor_left and !has_neighbor_right:
		suffix = "_small_spike"
	elif has_neighbor_left and !has_neighbor_right:
		suffix = "_right_spike"
	elif !has_neighbor_left and has_neighbor_right:
		suffix = "_left_spike"
	elif has_neighbor_left and has_neighbor_right:
		suffix = "_middle_spike"
	var tile_platform_spike_path = "res://Scenes/Tiles/platform_" + platform_sprites[x][y] + suffix + ".tscn"
	var tile_platform_spike = load(tile_platform_spike_path)
	return tile_platform_spike.instance()

func render_ground(tile: Node2D, x: int, y: int, is_floor: bool):
	 # mask: bleft,left,uleft,up,uright,right,bright,bot,rising,falling
	var neighbors_bitmask: String = "0000000000"
	var neighbor: int = TILE.GROUND_FLOOR if is_floor else TILE.GROUND_CEIL
	
	# if tile is near edge of map, keep its default fill tile
	if x - 1 < 0 or y - 1 < 0 or x + 1 > map_size.x - 1 or y + 1 > map_size.y - 1:
		return
	
	# otherwise, check neighbors
	if has_neighbor(x - 1, y + 1, neighbor):
		neighbors_bitmask[0] = "1" # bottom left
	if has_neighbor(x - 1, y, neighbor):
		neighbors_bitmask[1] = "1" # left
	if has_neighbor(x - 1, y - 1, neighbor):
		neighbors_bitmask[2] = "1" # upper left
	if has_neighbor(x, y - 1, neighbor):
		neighbors_bitmask[3] = "1" # up
	if has_neighbor(x + 1, y - 1, neighbor):
		neighbors_bitmask[4] = "1" # upper right
	if has_neighbor(x + 1, y, neighbor):
		neighbors_bitmask[5] = "1" # right
	if has_neighbor(x + 1, y + 1, neighbor):
		neighbors_bitmask[6] = "1" # bottom right
	if has_neighbor(x, y + 1, neighbor):
		neighbors_bitmask[7] = "1" # bottom
	# check for change in elevation if this is not a fill piece
	if neighbors_bitmask != "1111111100":
		if is_floor:
			if floor_line[x - 1] > floor_line[x] and floor_line[x + 1] > floor_line[x]:
				# flag as both rising and falling when single column of ground
				neighbors_bitmask[8] = "1" # falling if next is lower
				neighbors_bitmask[9] = "1" # falling if next is lower
			if floor_line[x + 1] > floor_line[x]:
				neighbors_bitmask[9] = "1" # falling if next is lower
			elif floor_line[x - 1] > floor_line[x]:
				neighbors_bitmask[8] = "1" # rising if prev is lower
		else:
			if ceiling_line[x - 1] < ceiling_line[x] and ceiling_line[x + 1] < ceiling_line[x]:
				return # figure out what to do when single column of dirt
			if ceiling_line[x + 1] < ceiling_line[x]:
				neighbors_bitmask[8] = "1" # rising if next is higher
			elif ceiling_line[x - 1] < ceiling_line[x]:
				neighbors_bitmask[9] = "1" # falling if prev is higher
		tile.set_ground_sprite(is_floor, neighbors_bitmask)

func has_neighbor(x: int, y: int, neighbor: int, match_water: bool = false, match_lava: bool = false):
	if matrix[x][y] == neighbor:
		return true
	elif matrix[x][y] == TILE.WATER and match_water:
		return true
	elif matrix[x][y] == TILE.LAVA and match_lava:
		return true
	
	return false

func rand_int(min_value: int,max_value: int, inclusive_range = true):
	if inclusive_range:
		max_value += 1
	var range_size = max_value - min_value
	return (randi() % range_size) + min_value
