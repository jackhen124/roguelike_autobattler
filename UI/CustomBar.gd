extends Node2D
var color = Color(1,1,1)
var hbWidth = 15
var hbHeight = 60

var olPoints = []
var hPoints = []

var curValue = 10
var maxValue = 10

var oldColor = Color(1,1,1)
var curAnimation = 'none'
var chunkPoints = []
var flipped = false
# Called when the node enters the scene tree for the first time.
func _ready():
	
	setPoints()
	
	pass # Replace with function body.

func _process(delta):
	if curAnimation == 'chunk':
		oldColor.a -= delta*0.85
		for i in range(chunkPoints.size()):
			if !flipped:
				chunkPoints[i].x-=delta*35
			else:
				chunkPoints[i].x+=delta*35
			
			if oldColor.a <= 0:
				curAnimation = 'none'
	update()
	
func setValue(newValue, animation):
	var oldValue = curValue
	
	
	setPoints()
	if animation == 'chunk' && newValue != oldValue:
		chunkPoints = []
		var lowerY = getHeightBasedOnValue(curValue)
		var upperY = getHeightBasedOnValue(oldValue)
		var xOffset = float(hbWidth) / 2.0
		chunkPoints.append(Vector2(-xOffset, -lowerY))
		chunkPoints.append(Vector2(xOffset, -lowerY))
		chunkPoints.append(Vector2(xOffset, -upperY))
		chunkPoints.append(Vector2(-xOffset, -upperY))
	curAnimation = animation


	
	
func getHeightBasedOnValue(value):
	var prop = float(value) / float(maxValue)
	var hY = CustomFormulas.proportion(0, hbHeight, prop)
	return hY
	


func setPoints():
	if Global.avgStats.hp > 0:
		var hpRatio = float(maxValue) / float(Global.avgStats.hp)
		
		hbWidth =  12*hpRatio
	else:
		hbWidth = 15
	var xOffset = float(hbWidth)/ 2.0
	olPoints = []
	
	olPoints.append(Vector2(-xOffset, 0))
	olPoints.append(Vector2(xOffset, 0))
	olPoints.append(Vector2(xOffset, -hbHeight))
	olPoints.append(Vector2(-xOffset, -hbHeight))
	
	hPoints = []
	hPoints.append(olPoints[0])
	hPoints.append(olPoints[1])
	var prop = float(curValue) / float(maxValue)
	var hY = CustomFormulas.proportion(0, hbHeight, prop)
	hPoints.append(Vector2(xOffset, -hY))
	hPoints.append(Vector2(-xOffset, -hY))


func _draw():
	var w = 2
	var olColor = color.darkened(0.4)
	
	draw_colored_polygon(olPoints, Color(0,0,0,0.5))
	if curAnimation == 'chunk':
		
		draw_colored_polygon(chunkPoints, oldColor)
		
	draw_colored_polygon(hPoints, color)
	draw_line(olPoints[0], olPoints[1], olColor, w)
	draw_line(olPoints[1], olPoints[2], olColor, w)
	draw_line(olPoints[2], olPoints[3], olColor, w)
	draw_line(olPoints[3], olPoints[0], olColor, w)
	
	
