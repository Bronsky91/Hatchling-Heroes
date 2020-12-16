extends Control

var first_run = true

# Called when the node enters the scene tree for the first time.
func _ready():
	get_node('../ButtonContainer/HatchButton8/Area2D').connect('mouse_entered', self, '_on_mouse_entered', ['Love'])
	get_node('../ButtonContainer/HatchButton8/Area2D').connect('mouse_exited', self, '_on_mouse_exited', ['Love'])
	
	get_node('../ButtonContainer/HatchButton/Area2D').connect('mouse_entered', self, '_on_mouse_entered', ['Light'])
	get_node('../ButtonContainer/HatchButton/Area2D').connect('mouse_exited', self, '_on_mouse_exited', ['Light'])
	
	get_node('../ButtonContainer/HatchButton2/Area2D').connect('mouse_entered', self, '_on_mouse_entered', ['Heat'])
	get_node('../ButtonContainer/HatchButton2/Area2D').connect('mouse_exited', self, '_on_mouse_exited', ['Heat'])
	
	get_node('../ButtonContainer/HatchButton3/Area2D').connect('mouse_entered', self, '_on_mouse_entered', ['Slime'])
	get_node('../ButtonContainer/HatchButton3/Area2D').connect('mouse_exited', self, '_on_mouse_exited', ['Slime'])
	
	get_node('../ButtonContainer/HatchButton4/Area2D').connect('mouse_entered', self, '_on_mouse_entered', ['Hate'])
	get_node('../ButtonContainer/HatchButton4/Area2D').connect('mouse_exited', self, '_on_mouse_exited', ['Hate'])
	
	get_node('../ButtonContainer/HatchButton5/Area2D').connect('mouse_entered', self, '_on_mouse_entered', ['Dark'])
	get_node('../ButtonContainer/HatchButton5/Area2D').connect('mouse_exited', self, '_on_mouse_exited', ['Dark'])
	
	get_node('../ButtonContainer/HatchButton6/Area2D').connect('mouse_entered', self, '_on_mouse_entered', ['Cold'])
	get_node('../ButtonContainer/HatchButton6/Area2D').connect('mouse_exited', self, '_on_mouse_exited', ['Cold'])
	
	get_node('../ButtonContainer/HatchButton7/Area2D').connect('mouse_entered', self, '_on_mouse_entered', ['Crystal'])
	get_node('../ButtonContainer/HatchButton7/Area2D').connect('mouse_exited', self, '_on_mouse_exited', ['Crystal'])
	
	get_node('../ButtonContainer/RandomIcon').connect('mouse_entered', self, '_on_mouse_entered', ['Random'])
	get_node('../ButtonContainer/RandomIcon').connect('mouse_exited', self, '_on_mouse_exited', ['Random'])

func _on_mouse_entered(type):
	show_label(type)

func _on_mouse_exited(type):
	if not first_run:
		get_node(type+"Label").hide()

func show_label(type):
	get_node(type+"Label").show()
