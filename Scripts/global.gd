extends Node

enum collision_layers {GROUND, WATER, LAVA, PLAYER, PLAYER_PROJECTILE, SPIKE, ENEMY, SPAWNER}

enum power_parts {
	EXTRA_LIFE,
	FLYING,
	SWIM,
	GILLS,
	EXTRA_AIR,
	DOUBLE_JUMP,
	TOP_ATTACK,
	FORWARD_ATTACK,
	TOP_SHIELD,
	RAT_PROTECTION,
	BAT_PROTECTION,
	NOTHING
}

var starting_over = false

func _ready():
	#OS.set_window_maximized(true)
	pass

func files_in_dir(path: String, keyword: String = "") -> Array:
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin(true, true)
	while true:
		var file = dir.get_next()
		if file == "":
			break
		if keyword != "" and file.find(keyword) == -1:
			continue
		if not file.begins_with(".") and file.ends_with(".import"):
			files.append(file.replace(".import", ""))
	dir.list_dir_end()
	return files

func make_shaders_unique(sprite: Sprite):
	var mat = sprite.get_material().duplicate()
	sprite.set_material(mat)
	
func load_creature(parent_node: Node2D, json_data=""):
	var data
	if json_data:
		data = JSON.parse(json_data).result
	else:
		var f = File.new()
		f.open("user://character_state.save", File.READ)
		var json = JSON.parse(f.get_as_text())
		f.close()
		data = json.result
	for part in parent_node.get_children():
		if part is Sprite:
			part.texture = load("res://Assets/Character/" + part.name + "/" + part.name + "_" + data[part.name].texture_num + ".png")
			part.material.set_shader_param("palette_swap", load("res://Assets/Character/Palettes/"+data[part.name].palette_name))
			part.material.set_shader_param("greyscale_palette", load("res://Assets/Character/Palettes/Bodycolor_000.png"))
			make_shaders_unique(part)
			
	var powers = []
	for d in data.keys():
		if d == "Name":
			continue
		if data[d].power_part != g.power_parts.NOTHING:
			powers.append(data[d].power_part)
	return powers # Array of power parts for loaded creature

func is_bit_enabled(mask, index):
	return mask & (1 << index) != 0

func enable_bit(mask, index):
	return mask | (1 << index)

func disable_bit(mask, index):
	return mask & ~(1 << index)

# Takes in a decimal value (int) and returns the binary value (int)
func dec2bin(var decimal_value):
	var binary_string = "" 
	var temp 
	var count = 31 # Checking up to 32 bits 
	while(count >= 0):
		temp = decimal_value >> count 
		if(temp & 1):
			binary_string = binary_string + "1"
		else:
			binary_string = binary_string + "0"
		count -= 1
	return int(binary_string)

func rand_int(min_value: int,max_value: int, inclusive_range = true):
	if inclusive_range:
		max_value += 1
	var range_size = max_value - min_value
	return (randi() % range_size) + min_value
