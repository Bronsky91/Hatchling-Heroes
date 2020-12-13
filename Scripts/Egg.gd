extends Node2D

signal nurture_pressed

var particle = preload("res://Scenes/ParticleIcon.tscn")
var countdown: int = 1

var nurture_count_dict = {
	"Dark": 0,
	"Cold": 0,
	"Hate": 0,
	"Love": 0,
	"Crystal": 0,
	"Heat": 0,
	"Light": 0,
	"Slime": 0
}

func _ready():
	connect("nurture_pressed", self, "_on_nurture_pressed")
	$CountdownLabel.text = "Seconds Remaining: " + str(countdown)

func _on_nurture_pressed(type):
	show_nurture_particle(type)
	nurture_count_dict[type] += 1
	print(nurture_count_dict)

func show_nurture_particle(type):
	var new_particle = particle.instance()
	new_particle.icon_type = type
	$EggSprite/ParticleStart.add_child(new_particle)


func _on_RandomIcon_button_up():
	randomize()
	var random_nurture = nurture_count_dict.keys()[randi() % 8]
	show_nurture_particle(random_nurture)
	nurture_count_dict[random_nurture] += 1

func _on_Timer_timeout():
	if countdown == 0:
		$Timer.stop()
		$CountdownLabel.text = "It's Hatching!"
		$EggSprite.play()
		load_creature()
		$CreatureBody.show()
		return disable_nurture()
	countdown -= 1
	$CountdownLabel.text = "Seconds Remaining: " + str(countdown)

func disable_nurture():
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

func save_creature():
	var creature_parts = ['Torso', 'Tail', 'Head', 'Legs', 'Arms', 'Back']

	var f = File.new()
	f.open("res://SaveData/character_state.json", File.READ)
	var json = JSON.parse(f.get_as_text())
	f.close()
	var data = json.result

	for part in creature_parts:
		data[part].texture_num = '001'
		data[part].palette_num = '003'

	f = File.new()
	f.open("res://SaveData/character_state.json", File.WRITE)
	f.store_string(JSON.print(data, "  ", true))
	f.close()
