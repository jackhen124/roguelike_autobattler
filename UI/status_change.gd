extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var flipped = false
var flipScale = 1
var speed = 55

var dis = 70
# Called when the node enters the scene tree for the first time.
func _ready():
	
	
	pass # Replace with function body.

func start():
	flipScale = 1
	if flipped:
		flipScale *=-1
	if flipped:
		rect_global_position.x += get_parent().rect_size.x
	var tween = get_node("Tween")
	tween.interpolate_property(self, "rect_position:x",
	rect_position.x,  rect_position.x-(dis*flipScale), 1.8,
	Tween.TRANS_QUAD, Tween.EASE_OUT)
	tween.start()
# Called every frame. 'delta' is the elapsed time since the previous frame.


func _on_Tween_tween_all_completed():
	if modulate.a == 0:
		queue_free()
	else:
		var tween = get_node("Tween")
		tween.interpolate_property(self, "rect_position:x",
		rect_position.x,  dis, 1.8,
		Tween.TRANS_QUAD, Tween.EASE_IN)
		tween.start()
		tween.interpolate_property(self, "modulate:a",
		1,  0, 1,
		Tween.TRANS_QUAD, Tween.EASE_IN)
		tween.start()
	pass # Replace with function body.
