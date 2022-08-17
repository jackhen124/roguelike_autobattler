extends Unit


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	hasOnAttack = true
	pass # Replace with function body.


func onAttack():
	.onAttack()
	applyEffect('poison', 1, curTarget)
	
