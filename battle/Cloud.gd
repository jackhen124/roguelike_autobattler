extends Sprite


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var speed = 6.2

var yRange = 45
var speedRange 
var scaleRange = 0.4
# Called when the node enters the scene tree for the first time.
func _ready():
	var ySize = Global.rng.randf_range(1-scaleRange,1+scaleRange)
	var xSize = Global.rng.randf_range(ySize-scaleRange,ySize+scaleRange)
	
	var depthValue = (ySize + xSize) / 2
	
	z_index = (depthValue)  * 10
	speed*= depthValue
	
	position.y += Global.rng.randi_range(-yRange,yRange)
	
	#modulate.a = depthValue
	
	
	scale.y *= ySize
	scale.x *= xSize
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position.x += speed*delta
	if position.x > 1500:
		queue_free()
	pass
