extends Node



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_Start_button_up():
	$Title/Options.emit_signal("index_update", 0)
	$Title.hide()
	$Egg.start()
	

func _on_HighScores_button_up():
	$Title/Options.emit_signal("index_update", 1)


func _on_Options_button_up():
	$Title/Options.emit_signal("index_update", 2)
