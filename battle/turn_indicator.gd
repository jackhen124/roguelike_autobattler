extends Sprite


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var target = null
signal moveComplete

var atTarget = false
# Called when the node enters the scene tree for the first time.
func _ready():
	
	pass # Replace with function body.

func _process(delta):
	if target!= null:
		var offsetY = 20
		var targetPos = target.global_position + Vector2(0,offsetY)
		var speed = 160 + global_position.distance_to(targetPos)*2
		if !atTarget:
			global_position = global_position.move_toward(targetPos, delta*speed)
			if global_position == targetPos && !atTarget:
				emit_signal('moveComplete')
				atTarget = true
		else:
			global_position = targetPos
func move(unit):
	show()
	target = unit
	atTarget = false
