extends Node

# Called when the node enters the scene tree for the first time.
func _ready():
	$AudioStreamPlayer.stream = load("res://Assets/Music/Main_Menu_Track_Game_Jam1.wav")
	# $AudioStreamPlayer.play()

func _on_Start_button_up():
	$AudioStreamPlayer.stream = load("res://Assets/Music/Egg_Creation_Menu2_lower.wav")
	$AudioStreamPlayer.play()
	get_node("Title/Options").emit_signal("index_update", 0)
	$Title.hide()
	$Title/Options.disable_input = true
	$Egg.start()

func _on_HighScores_button_up():
	get_node("Title/Options").emit_signal("index_update", 1)
	$Title.hide()
	$Title/Options.disable_input = true
	$HighScores.show()

func _on_Options_button_up():
	get_node("Title/Options").emit_signal("index_update", 2)


func _on_Back_button_up():
	$HighScores.hide()
	$Title.show()

