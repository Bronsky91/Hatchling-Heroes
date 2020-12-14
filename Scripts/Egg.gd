extends Node2D

signal nurture_pressed

var particle = preload("res://Scenes/ParticleIcon.tscn")
var countdown: int = 5

var nurture_percent_dict = {
	"Dark": 0.125,
	"Cold": 0.125,
	"Hate": 0.125,
	"Love": 0.125,
	"Crystal": 0.125,
	"Heat": 0.125,
	"Light": 0.125,
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
	var thres_dict = nurture_percent_dict
	var last_thres: float = 0.0
	for type in thres_dict.keys():
		var thres_of_type: float = last_thres + nurture_percent_dict[type]
		thres_dict[type] = thres_of_type
		last_thres = thres_of_type
	return thres_dict

func show_nurture_particle(type):
	var new_particle = particle.instance()
	new_particle.icon_type = type
	$EggSprite/ParticleStart.add_child(new_particle)


func _on_RandomIcon_button_up():
	randomize()
	var random_nurture = nurture_percent_dict.keys()[randi() % 8]
	show_nurture_particle(random_nurture)
	# nurture_percent_dict[random_nurture] += 1

func _on_Timer_timeout():
	if countdown == 0:
		$Timer.stop()
		$CountdownLabel.text = "It's Hatching!"
		$EggSprite.play()
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
	save_creature()
	get_tree().change_scene("res://Scenes/Game.tscn")

func load_creature():
	for part in $CreatureBody.get_children():
		if part is Sprite:
			part.texture = load("res://Assets/Character/" + part.name + "/" + part.name + "_" + "001" + ".png") 

func _on_EggSprite_frame_changed():
	if $EggSprite.frame == 14:
		$CreatureBody.show()

func save_creature():
	## NOTE: Torsa and Arms are the SAME
	var creature_parts = ['Torso', 'Arms', 'Tail', 'Head', 'Legs', 'Back']
	var thresold_dict = calculate_thresholds()
	
	var f = File.new()
	f.open("res://SaveData/character_state.json", File.READ)
	var json = JSON.parse(f.get_as_text())
	f.close()
	var data = json.result

	for part in creature_parts:
		if part == 'Arms':
			pass # Do same as Torso
		data[part].texture_num = '001'
		data[part].palette_num = '003'

	f = File.new()
	f.open("res://SaveData/character_state.json", File.WRITE)
	f.store_string(JSON.print(data, "  ", true))
	f.close()
