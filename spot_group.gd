extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export var disToCover = 100
var startDisToCover 
export var percentVertical = 0

var minPos
var maxPos


# Called when the node enters the scene tree for the first time.
func _ready():
	startDisToCover = disToCover
	updatePositions()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update()
	pass
func updatePositions():
	disToCover = CustomFormulas.proportion(startDisToCover, startDisToCover*0.75, percentVertical)
	var i = 0
	var numSpots = get_children().size()
	#print('setting up group with disTocover: ',disToCover, ' and numSpots: ',numSpots)
	var xOffset = (float(disToCover)/float(numSpots+1)) * (1-percentVertical)
	var yOffset = (float(disToCover)/float(numSpots+1)) * percentVertical
	var vectorOffset = Vector2(xOffset, yOffset)
	#print('offset: ',offset)
	var vectorDisToCover = Vector2(disToCover*(1-percentVertical), disToCover*percentVertical)
	minPos = -vectorDisToCover/2
	maxPos = minPos  + vectorOffset + (vectorOffset*get_children().size())
	for spot in get_children():
		
		
		#var pos = -float(disToCover)/2 + offset + offset*i
		
		
		var pos = -vectorDisToCover/2 + vectorOffset + (vectorOffset*i)
		

		spot.position = pos
		spot.get_node('Button').modulate.a = 1-percentVertical
			
		i+=1

func _draw():
	draw_circle(Vector2(0,0), 60, Color(1,1,1, 0.1))
	draw_line(minPos, maxPos, Color(1,1,1), 2)
	#draw_line(minPos, maxPos, Color(1,1,1), 2)
