extends Node

func _ready():
	OS.set_window_maximized(true)

func files_in_dir(path: String, keyword: String = "") -> Array:
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif keyword != "" and file.find(keyword) == -1:
			continue
		elif not file.begins_with(".") and not file.ends_with(".import"):
			files.append(file)
	dir.list_dir_end()
	return files

func make_shaders_unique(sprite: Sprite):
	var mat = sprite.get_material().duplicate()
	sprite.set_material(mat)
	
func load_creature(parent_node: Node2D):
	var f = File.new()
	f.open("res://SaveData/character_state.json", File.READ)
	var json = JSON.parse(f.get_as_text())
	f.close()
	var data = json.result
	for part in parent_node.get_children():
		if part is Sprite:
			part.texture = load("res://Assets/Character/" + part.name + "/" + part.name + "_" + data[part.name].texture_num + ".png")
			part.material.set_shader_param("palette_swap", load("res://Assets/Character/Palettes/"+data[part.name].palette_name))
			part.material.set_shader_param("greyscale_palette", load("res://Assets/Character/Palettes/Bodycolor_000.png"))
			make_shaders_unique(part)
