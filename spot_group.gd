extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export var disToCover = 100
var startDisToCover 
export var percentVertical = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	startDisToCover = disToCover
	update()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func update():
	disToCover = CustomFormulas.proportion(startDisToCover, startDisToCover*0.75, percentVertical)
	var i = 0
	var numSpots = get_children().size()
	#print('setting up group with disTocover: ',disToCover, ' and numSpots: ',numSpots)
	var xOffset = (float(disToCover)/float(numSpots+1)) * (1-percentVertical)
	var yOffset = (float(disToCover)/float(numSpots+1)) * percentVertical
	var vectorOffset = Vector2(xOffset, yOffset)
	#print('offset: ',offset)
	for spot in get_children():
		
		
		#var pos = -float(disToCover)/2 + offset + offset*i
		var vectorDisToCover = Vector2(disToCover*(1-percentVertical), disToCover*percentVertical)
		
		var pos = -vectorDisToCover/2 + vectorOffset + (vectorOffset*i)
		

		spot.position = pos
		
			
		i+=1
