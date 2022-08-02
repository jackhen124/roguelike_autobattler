extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var color = Color(1,1,1)
var hbWidth = 15
var hbHeight = 75
var powerHeight = 10

var olPoints = []
var hPoints = []


var powerColor = Color(1,1,1)
var powerPoints = []
var powerOlPoints

var curHp = 10
var maxHp = 10
var power = 1

var oldColor = Color(1,1,1)
var curAnimation = 'none'
var chunkPoints = []
var flipped = false

var poison = 0
var poisonPoints = []

var armor = 0
var armorPoints = []


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
	if hp!=oldHp:
		var lowerY = getHeightBasedOnHp(curHp)
		var upperY = getHeightBasedOnHp(oldHp)
		var heightLost = upperY - lowerY
		if poisonPoints.size() > 0:
			for i in poisonPoints.size():
				poisonPoints[i].y += heightLost
		if armorPoints.size() > 0:
			for i in armorPoints.size():
				armorPoints[i].y += heightLost
		
		if animation == 'chunk':
			chunkPoints = []
			
			var xOffset = float(hbWidth) / 2.0
			chunkPoints.append(Vector2(-xOffset, -lowerY))
			chunkPoints.append(Vector2(xOffset, -lowerY))
			chunkPoints.append(Vector2(xOffset, -upperY))
			chunkPoints.append(Vector2(-xOffset, -upperY))
	curAnimation = animation
	

func setPower(num):
	power = num
	var prop = float(power) / float(maxHp)
	powerHeight = CustomFormulas.proportion(0, hbHeight, prop)
	var g = CustomFormulas.proportion(1,0, prop/2.0)
	powerColor = Color(1,1,0)
	powerColor.g = g
	var darkness = CustomFormulas.proportion(0,0.8, prop/3.0)
	powerColor = powerColor.darkened(darkness)
	setPowerPoints()
	
func setPoison(num):
	if num == poison:
		return
	
	poison = num
	call_deferred('setPoisonPoints', num)
	
		
func setPoisonPoints(num):
	poisonPoints = []
	if poison > 0:
		var p2 = Vector2(hPoints[2])
		var p3 = Vector2(hPoints[3])
		var p0 = p3
		p0.y += getHeightBasedOnHp(poison)
		var p1 = p2
		p1.y += getHeightBasedOnHp(poison)
		poisonPoints.append(p0)
		poisonPoints.append(p1)
		poisonPoints.append(p2)
		poisonPoints.append(p3)
		
		
func setArmor(num):
	if num == armor:
		return
	armor = num
	call_deferred('setArmorPoints', num)
	
func setArmorPoints(num):
	armorPoints = []
	if armor > 0:
		var p1 = Vector2(hPoints[2])
		var p0 = Vector2(hPoints[3])
		var p3 = p0
		p3.y -= getHeightBasedOnHp(armor)
		var p2 = p1
		p2.y -= getHeightBasedOnHp(armor)
		armorPoints.append(p0)
		armorPoints.append(p1)
		armorPoints.append(p2)
		armorPoints.append(p3)
	
func getHeightBasedOnHp(value):
	var prop = float(value) / float(maxHp)
	var hY = CustomFormulas.proportion(0, hbHeight, prop)
	return hY
	


func setPoints():
	if Global.avgStats.hp > 0:
		var hpRatio = float(maxHp) / float(Global.avgStats.hp)
		
		hbWidth =  13*hpRatio
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

func setPowerPoints(growDir = 'both'):
	
	var yOffset = float(powerHeight)/2.0
		
	var xOffset = float(hbWidth)/ 2.0
	
	
	powerPoints = []
	
	powerPoints.append(Vector2(-xOffset, yOffset))
	powerPoints.append(Vector2(xOffset, yOffset))
	powerPoints.append(Vector2(xOffset, -yOffset))
	powerPoints.append(Vector2(-xOffset, -yOffset))
	for i in powerPoints.size():
		var mult = 1
		if flipped:
			mult = -1
		powerPoints[i].x-= ((hbWidth) * mult)
	if growDir == 'both':
		for i in powerPoints.size():
			powerPoints[i].y -= float(hbHeight) / 2.0
	elif growDir == 'up':
		for i in powerPoints.size():
			powerPoints[i].y -= yOffset
		

func _draw():
	var w = 2
	var olColor = color.darkened(0.5)
	
	#black background
	draw_colored_polygon(olPoints, Color(0,0,0,0.4))
	
	if curAnimation == 'chunk':
		
		draw_colored_polygon(chunkPoints, oldColor)
	
	# current health
	draw_colored_polygon(hPoints, color)
	# POISON
	if poisonPoints.size() > 0:
		draw_colored_polygon(poisonPoints, Global.keywords.poison.color)
	# HEALTHBAR OUTLINE
	olColor = color.darkened(0.5)
	draw_line(olPoints[0], olPoints[1], olColor, w)
	draw_line(olPoints[1], olPoints[2], olColor, w)
	draw_line(olPoints[2], olPoints[3], olColor, w)
	draw_line(olPoints[3], olPoints[0], olColor, w)
	# ARMOR
	if armorPoints.size() > 0:
		olColor = Color(Global.keywords.armor.color).darkened(0.5)
		
		draw_colored_polygon(armorPoints, Global.keywords.armor.color)
		draw_line(armorPoints[0], armorPoints[1], olColor, w)
		draw_line(armorPoints[1], armorPoints[2], olColor, w)
		draw_line(armorPoints[2], armorPoints[3], olColor, w)
		draw_line(armorPoints[3], armorPoints[0], olColor, w)
	if powerPoints.size() > 0:
		olColor = powerColor.darkened(0.5)
		draw_colored_polygon(powerPoints, powerColor)
		draw_line(powerPoints[0], powerPoints[1], olColor, w)
		draw_line(powerPoints[1], powerPoints[2], olColor, w)
		draw_line(powerPoints[2], powerPoints[3], olColor, w)
		draw_line(powerPoints[3], powerPoints[0], olColor, w)
	


func _on_Button_pressed():
	setHp(5, 10, 'chunk')
	pass # Replace with function body.
