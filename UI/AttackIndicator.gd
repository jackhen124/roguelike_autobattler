extends Node2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var baseScale = Vector2(1,1)
var prop
var flipped = false

var width = 5
var value
var color = Color(1,1,1)
var aPoints = []
# Called when the node enters the scene tree for the first time.

func _ready():
	baseScale = scale
	$AttackLabel.add_color_override("font_color", Color(1,1,1,1))
	
	pass # Replace with function body.


func setAttack(num):
	$AttackLabel.text = str(num)
	if num == 0:
		num = 0.1
	prop = float(num)/float(Global.avgStats.power)
	print('attack: '+str(num))
	print('prop '+ str(prop))
	
		
	
	var g = CustomFormulas.proportion(1,0, prop/2.0)
	color = Color(1,1,0)
	color.g = g
	var darkness = CustomFormulas.proportion(0,0.8, prop/3.0)
	color = color.darkened(darkness)
	$Sprite.modulate = color
	value = num
	#setPoints()
	#call_deferred('setScale')
	
func setScale():
	return
	if flipped:
		scale = baseScale*prop
		scale.x = -baseScale.x*prop
	else:
		scale.x = baseScale.x*prop
	scale.y = baseScale.y*prop

func setFlipped():
	flipped = true
	setScale()
	
func getHeightBasedOnAttack(value):
	var hY = value*3
	return hY
	


func setAttackPoints(growDir = 'up'):
	
	
	var yOffset = value*3
	if Global.avgStats.hp > 0:
		var aRatio = float(value) / float(Global.avgStats.hp)
		
		width =  12*aRatio
	else:
		width = 15
	var xOffset = float(width)/ 2.0
	
	
	aPoints = []
	
	aPoints.append(Vector2(-xOffset, yOffset))
	aPoints.append(Vector2(xOffset, yOffset))
	aPoints.append(Vector2(xOffset, -yOffset))
	aPoints.append(Vector2(-xOffset, -yOffset))
	
	if growDir == 'up':
		for i in aPoints.size():
			aPoints[i].y -= yOffset
			


func _draw():
	var w = 2
	#var olColor = color.darkened(0.2)
	
	draw_colored_polygon(aPoints, color)
	
