extends CanvasLayer

var current_index = 0
var disabled_input = true

onready var arrow_positions = $GameOverLabel/ArrowPositions.get_children()
onready var button_options = [$GameOverLabel/StartOver, $GameOverLabel/Exit]


signal index_update

func _ready():
	connect("index_update", self, "_on_index_update")
	
func game_over():
	$GameOverLabel.show()
	$GameOverLabel/StartOver.disabled = false
	$GameOverLabel/Exit.disabled = false
	$BlackBG.show()
	disabled_input = false
	
func _on_index_update(new_index):
	current_index = new_index
	$GameOverLabel/Arrow.position = arrow_positions[new_index].position

func _unhandled_input(event):
	if not disabled_input:
		if event.is_action_released("ui_down"):
			move_arrow_down()
		if event.is_action_released("ui_up"):
			move_arrow_up()
		if event.is_action_released("ui_accept"):
			button_options[current_index].emit_signal("button_up")

func move_arrow_down():
	if current_index < 1:
		emit_signal("index_update", current_index + 1)
	else:
		emit_signal("index_update", 0)

func move_arrow_up():
	if current_index > 0:
		emit_signal("index_update", current_index - 1)
	else:
		emit_signal("index_update", 1)


func _on_StartOver_button_up():
	g.starting_over = true
	get_tree().change_scene("res://Scenes/Menu.tscn")

func _on_Exit_button_up():
	g.starting_over = false
	get_tree().change_scene("res://Scenes/Menu.tscn")


func _on_StartOver_mouse_entered():
	emit_signal("index_update", 0)


func _on_Exit_mouse_entered():
	emit_signal("index_update", 1)
