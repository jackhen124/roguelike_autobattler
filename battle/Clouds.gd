extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var cloudScene = preload('res://battle/Cloud.tscn')
var cloudTimer = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	var numClouds = 7
	for i in range(numClouds):
		spawn(true)
		
	pass # Replace with function body.

func spawn(randomX = false):
	
	var newCloud = cloudScene.instance()
	add_child(newCloud)
	if randomX:
		var randX = Global.rng.randi_range(0, 1300)
		newCloud.position.x = randX
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if cloudTimer<=0:
		spawn()
		cloudTimer = CustomFormulas.randomValue(23, 0.2)
	cloudTimer -= delta
	pass
