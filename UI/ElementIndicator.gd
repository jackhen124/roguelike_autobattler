extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
signal hover
signal unhover

var darkMod = Color(0.8, 0.8, 0.8)
# Called when the node enters the scene tree for the first time.
func _ready():
	modulate = darkMod
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_TextureButton_mouse_entered():
	modulate = Color(1,1,1)
	emit_signal('hover')
	pass # Replace with function body.


func _on_TextureButton_mouse_exited():
	modulate = darkMod
	emit_signal('unhover')
	pass # Replace with function body.
