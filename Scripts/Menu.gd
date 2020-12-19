extends Node

# Called when the node enters the scene tree for the first time.
func _ready():
	if not g.starting_over:
		$AudioStreamPlayer.stream = load("res://Assets/Music/Main_Menu_Track_Game_Jam1.wav")
		#if not OS.is_debug_build():
		$AudioStreamPlayer.play()
	else:
		start_head_screen()

func _on_Start_button_up():
	start_head_screen()
	
func start_head_screen():
	$AudioStreamPlayer.stream = load("res://Assets/Music/Egg_Creation_Menu2_lower.wav")
	#if not OS.is_debug_build():
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


func _on_Back_button_up():
	$HighScores.hide()
	$Title.show()

