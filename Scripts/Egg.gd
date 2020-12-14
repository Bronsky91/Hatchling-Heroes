extends Node2D

signal nurture_pressed

var particle = preload("res://Scenes/ParticleIcon.tscn")
var countdown: int = 5

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

func _on_nurture_pressed(type):
	show_nurture_particle(type)
	calculate_nurture_percents(type)
	
func calculate_nurture_percents(type):
	var incr = 0.01
	var max_percent = 0.30
	var min_percent = 0.05
	for nurture_type in nurture_percent_dict.keys():
		if nurture_type != type and nurture_percent_dict[type] + incr <= max_percent and nurture_percent_dict[type] - incr >= min_percent:
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

func show_nurture_particle(type):
	var new_particle = particle.instance()
	new_particle.icon_type = type
	$EggSprite/ParticleStart.add_child(new_particle)


func _on_RandomIcon_button_up():
	randomize()
	var random_nurture = nurture_percent_dict.keys()[randi() % 8]
	show_nurture_particle(random_nurture)
	calculate_nurture_percents(random_nurture)
	save_creature()

func _on_Timer_timeout():
	if countdown == 0:
		$Timer.stop()
		$CountdownLabel.text = "It's Hatching!"
		$EggSprite.play()
		save_creature()
		load_creature()
		return disable_nurture()
	countdown -= 1
	$CountdownLabel.text = "Seconds Remaining: " + str(countdown)

func disable_nurture():
	$ButtonContainer.hide()
	for button in $ButtonContainer.get_children():
		button.disabled = true

func _on_EggSprite_animation_finished():
	$EggSprite.hide()
	$NameLabel.show()

func _on_NameEdit_text_changed():
		$EscapeButton.show()

func _on_EscapeButton_button_up():
	get_tree().change_scene("res://Scenes/Game.tscn")

func load_creature():
	var f = File.new()
	f.open("res://SaveData/character_state.json", File.READ)
	var json = JSON.parse(f.get_as_text())
	f.close()
	var data = json.result
	for part in $CreatureBody.get_children():
		if part is Sprite:
			part.texture = load("res://Assets/Character/" + part.name + "/" + part.name + "_" + data[part.name].texture_num + ".png") 

func _on_EggSprite_frame_changed():
	if $EggSprite.frame == 14:
		$CreatureBody.show()

func save_creature():
	## NOTE: Torsa and Arms are the SAME
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
	var nurture_options = {
		"Dark": ['002', '003', '007'],
		"Cold": ['006', '008', '009'],
		"Hate": ['002', '003', '005', '007'],
		"Love": ['001', '009'],
		"Crystal": ['002', '007'],
		"Heat": ['001', '004', '010'],
		"Light": ['001', '008', '009'],
		"Slime": ['004', '005', '006', '008'],
	}

	
	var f = File.new()
	f.open("res://SaveData/character_state.json", File.READ)
	var json = JSON.parse(f.get_as_text())
	f.close()
	var data = json.result

	for part in creature_parts:
		var nurture_for_part = find_nurture_based_on_thres()
		randomize()
		var creature_base = nurture_options[nurture_for_part][randi() % nurture_options[nurture_for_part].size()]
		if part == 'Torso':
			# Do same for Arms
			data['Arms'].texture_num = creature_base
		data[part].texture_num = creature_base
		#data[part].palette_num = creature_base

	f = File.new()
	f.open("res://SaveData/character_state.json", File.WRITE)
	f.store_string(JSON.print(data, "  ", true))
	f.close()
