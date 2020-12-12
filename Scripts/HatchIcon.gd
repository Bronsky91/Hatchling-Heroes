extends Sprite


var icon_dict = {
	"Dark": "res://Assets/UI/DarkIcon.png",
	"Cold": "res://Assets/UI/ColdIcon.png",
	"Hate": "res://Assets/UI/HateIcon.png",
	"Love": "res://Assets/UI/LoveIcon.png",
	"Crystal": "res://Assets/UI/CrystalIcon.png",
	"Heat": "res://Assets/UI/HeatIcon.png",
	"Light": "res://Assets/UI/LightIcon.png",
	"Slime": "res://Assets/UI/SlimeIcon.png"
}

export (String) var icon = "Dark"

var mouse_hovering: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$HatchIcon.texture = load(icon_dict[icon])


func _unhandled_input(event):
	if event.is_action_released("left_click") and mouse_hovering:
		get_parent().emit_signal("nurture_pressed", icon)


func _on_Area2D_mouse_entered():
	mouse_hovering = true


func _on_Area2D_mouse_exited():
	mouse_hovering = false
