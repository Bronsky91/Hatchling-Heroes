extends Control

var current_index = 0
onready var arrow_positions = $ArrowPositions.get_children()
onready var button_options = [$Start, $HighScores, $Options]

var disable_input = false

signal index_update

func _ready():
	connect("index_update", self, "_on_index_update")
	
func _on_index_update(new_index):
	current_index = new_index
	$Arrow.position = arrow_positions[new_index].position

func _unhandled_input(event):
	if not disable_input:
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

func _on_Start_mouse_entered():
	emit_signal("index_update", 0)
	
func _on_HighScores_mouse_entered():
	emit_signal("index_update", 1)


