extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var color = Color(1,1,1)
var hbWidth = 15
var hbHeight = 60

var olPoints = []
var hPoints = []

var curHp = 10
var maxHp = 10

var oldColor = Color(1,1,1)
var curAnimation = 'none'
var chunkPoints = []
var flipped = false
# Called when the node enters the scene tree for the first time.
func _ready():
	
	setPoints()
	$HpLabel.add_color_override("font_color", Color(1,1,1,1))
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

func setHp(hp, _maxHp, animation = 'none'):
	var oldHp = curHp
	curHp = hp
	maxHp = _maxHp
	var hpPercent = float(hp-1)/float(maxHp-1)
	var r = 0
	var g 
	var b = 0.5
	r = min(-2.25*hpPercent +2.25, 1)
	g = min(2*hpPercent-0.35,1)
	b = max(hpPercent-0.5,0)
	oldColor = color
	
	color = Color(r,g,b)
	
	
	
	$BgSprite.modulate = color.darkened(0.3)
	
	$HpLabel.text = str(hp)
	
	
	color = Color(r,g,b)
	setPoints()
	if animation == 'chunk' && hp != oldHp:
		chunkPoints = []
		var lowerY = getHeightBasedOnHp(curHp)
		var upperY = getHeightBasedOnHp(oldHp)
		var xOffset = float(hbWidth) / 2.0
		chunkPoints.append(Vector2(-xOffset, -lowerY))
		chunkPoints.append(Vector2(xOffset, -lowerY))
		chunkPoints.append(Vector2(xOffset, -upperY))
		chunkPoints.append(Vector2(-xOffset, -upperY))
	curAnimation = animation
	
	
func getHeightBasedOnHp(value):
	var prop = float(value) / float(maxHp)
	var hY = CustomFormulas.proportion(0, hbHeight, prop)
	return hY
	


func setPoints():
	if Global.avgStats.hp > 0:
		var hpRatio = float(maxHp) / float(Global.avgStats.hp)
		
		hbWidth =  2+12*hpRatio
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
	var prop = float(curHp) / float(maxHp)
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
	
	

	


func _on_Button_pressed():
	setHp(5, 10, 'chunk')
	pass # Replace with function body.
