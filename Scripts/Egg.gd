extends Node2D

signal nurture_pressed

var particle = preload("res://Scenes/ParticleIcon.tscn")
var thrown_icon = preload('res://Scenes/ThrownIcon.tscn')

export(int) var countdown: int = 10

var first_run = true

var nurture_percent_dict = {
	"Cold": 0.125,
	"Crystal": 0.125,
	"Dark": 0.125,
	"Hate": 0.125,
	"Heat": 0.125,
	"Light": 0.125,
	"Love": 0.125,
	"Slime": 0.125,
}

func _ready():
	connect("nurture_pressed", self, "_on_nurture_pressed")
	$CountdownLabel.text = "Seconds Remaining: " + str(countdown)
	#start()
	# disable_nurture()
	
func start():
	show()
	enable_nurture()
	
func _on_nurture_pressed(type):
	if first_run:
		hide_tutorial(type)
	throw_nurture_icon(type)
	calculate_nurture_percents(type)
	
func hide_tutorial(type, random=false):
	$Black.hide()
	$Tutorial.hide()
	for label in $ButtonLabels.get_children():
		label.hide()
	$Timer.start()
	$CountdownLabel.show()
	$ButtonLabels.first_run = false
	first_run = false
	if not random:
		$ButtonLabels.show_label(type)
	else:
		$ButtonLabels.show_label('Random')
	
func calculate_nurture_percents(type):
	var incr = 0.001
	var max_percent = 0.60
	var min_percent = 0.05
	for nurture_type in nurture_percent_dict.keys():
		if nurture_type != type and (nurture_percent_dict[type] + incr) <= max_percent and (nurture_percent_dict[type] - incr) >= min_percent:
			nurture_percent_dict[type] += incr
			nurture_percent_dict[nurture_type] -= incr

func calculate_thresholds():
	var thres_dict: Dictionary = {}
	var last_thres: float = 0.0
	for type in nurture_percent_dict.keys():
		var thres_of_type: float = last_thres + nurture_percent_dict[type]
		thres_dict[type] = thres_of_type
		last_thres = thres_of_type
	return thres_dict

func find_nurture_based_on_thres():
	var threshold_dict = calculate_thresholds()
	randomize()
	var rand = randf()
	var last_thres = 0.0
	for type in threshold_dict.keys():
		if rand > last_thres and rand <= threshold_dict[type]:
			return type
		last_thres = threshold_dict[type]

func throw_nurture_icon(type):
	var new_icon = thrown_icon.instance()
	new_icon.position = find_type_button_position(type)
	new_icon.texture = load('res://Assets/UI/'+type+'Icon.png')
	new_icon.target_pos = $EggSprite/ParticleStart.global_position
	new_icon.type = type
	$IconThrowContainer.add_child(new_icon)
	
func _on_EggCenter_area_entered(area):
	var icon = area.get_parent()
	show_nurture_particle(icon.type)
	icon.queue_free()
	
func find_type_button_position(type):
	for button in $ButtonContainer.get_children():
		if button.icon == type:
			return button.position

func show_nurture_particle(type):
	var new_particle = particle.instance()
	new_particle.icon_type = type
	$EggSprite/ParticleStart.add_child(new_particle)

func _on_RandomIcon_button_up():
	randomize()
	var random_nurture = nurture_percent_dict.keys()[randi() % 8]
	if first_run:
		hide_tutorial(random_nurture, true)
	throw_nurture_icon(random_nurture)
	calculate_nurture_percents(random_nurture)

func _on_Timer_timeout():
	if countdown == 0:
		$Timer.stop()
		$CountdownLabel.hide()
		$HatchingText.show()
		$EggSprite.play()
		save_creature()
		g.load_creature($CreatureBody)
		return disable_nurture()
	countdown -= 1
	$CountdownLabel.text = "Seconds Remaining: " + str(countdown)

func disable_nurture():
	$ButtonContainer.hide()
	for button in $ButtonContainer.get_children():
		button.disabled = true
		
func enable_nurture():
	for button in $ButtonContainer.get_children():
		button.disabled = false

func _on_EggSprite_animation_finished():
	$EggSprite.hide()
	$NameLabel.show()

func _on_NameEdit_text_changed():
		$EscapeButton.show()

func _on_EscapeButton_button_up():
	save_creature_name($NameLabel/NameEdit.text)
	get_tree().change_scene("res://Scenes/Game.tscn")

func _on_EggSprite_frame_changed():
	if $EggSprite.frame == 14:
		$CreatureBody.show()

func save_creature_name(name):
	var f = File.new()
	f.open("user://character_state.save", File.READ_WRITE)
	var json = JSON.parse(f.get_as_text())
	var data = json.result
	data['Name'] = name
	f.store_string(JSON.print(data, "  ", true))
	f.close()
	
func save_creature():
	## NOTE: Torso and Arms are the SAME
	var creature_parts = ['Torso', 'Tail', 'Head', 'Legs', 'Back']
	#001 - Cat
	#002 - Mole
	#003 - Bat
	#004 - Salamander
	#005 - Snake
	#006 - Fish
	#007 _ Rat
	#008 - Frog
	#009 - Duck
	#010 - Scorpion
	#011 - Turtle
	#012 - Porcupine
	#013 - Monkey
	
	var nurture_options = {
		"Dark": ['002', '003', '007', '012'],
		"Cold": ['006', '008', '009', '011'],
		"Hate": ['002', '003', '005', '007', '010'],
		"Love": ['001', '009', '012', '013'],
		"Crystal": ['002', '007', '011', '012'],
		"Heat": ['001', '004', '010', '013'],
		"Light": ['001', '008', '009', '013'],
		"Slime": ['004', '005', '006', '008', '010'],
	}
	
	var power_part_index = {
		"Head": {
			"001": g.power_parts.EXTRA_LIFE,
			"003": g.power_parts.BAT_PROTECTION,
			"006": g.power_parts.GILLS,
			"007": g.power_parts.RAT_PROTECTION,
			"008": g.power_parts.EXTRA_AIR
		},
		"Back": {
			"003": g.power_parts.FLYING,
			"009": g.power_parts.FLYING,
			"011": g.power_parts.TOP_SHIELD,
			"012": g.power_parts.TOP_ATTACK
		},
		"Legs": {
			"008": g.power_parts.DOUBLE_JUMP
		},
		"Tail": {
			"008": g.power_parts.SWIM,
			"010": g.power_parts.FORWARD_ATTACK
		},
		"Torso": {
			"013": g.power_parts.FORWARD_ATTACK
		}
	}
	
	var data = {
	"Name": "",
	"Arms": {
		"palette_name": "",
		"texture_num": "",
		"power_part": ""
	 },
	"Back": {
		"palette_name": "",
		"texture_num": "",
		"power_part": ""
	 },
	 "Head": {
		"palette_name": "",
		"texture_num": "",
		"power_part": ""
	 },
	 "Legs": {
		"palette_name": "",
		"texture_num": "",
		"power_part": ""
	 },
	 "Tail": {
		"palette_name": "",
		"texture_num": "",
		"power_part": ""
	 },
	 "Torso": {
		"palette_name": "",
		"texture_num": "",
		"power_part": ""
	 }
	}
	
	## Same palette for each part
	# var random_part_color = get_random_palette()
	##
	for part in creature_parts:
		var nurture_for_part = find_nurture_based_on_thres()
		randomize()
		var creature_base = nurture_options[nurture_for_part][randi() % nurture_options[nurture_for_part].size()]
		## Different palette for each part
		var random_part_color = get_random_palette()
		##
		var power = power_part_index[part][creature_base] if power_part_index[part].has(creature_base) else g.power_parts.NOTHING
		if part == 'Torso':
			# Do same for Arms
			data['Arms'].texture_num = creature_base
			data['Arms'].palette_name = random_part_color
			data['Arms'].power_part = power
		data[part].texture_num = creature_base
		data[part].palette_name = random_part_color
		data[part].power_part = power
	
	var f = File.new()
	f.open("user://character_state.save", File.WRITE)
	f.store_string(JSON.print(data, "  ", true))
	f.close()

func get_random_palette():
	var palettes = g.files_in_dir('res://Assets/Character/Palettes')
	for p in palettes:
		if '000' in p:
			palettes.erase(p)
	randomize()
	var rand_palette = palettes[randi() % palettes.size()]
	return rand_palette

