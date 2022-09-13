extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var drawHorizontal = false
var color = Color(1,1,1)
var hbWidth = 15
var hbHeight = 75
var powerHeight = 10
var powerPos = null

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

var points = {}



var curHeights = null
var targetHeights = null

var changing = []
var copyData

var changeSpeed = 8
# Called when the node enters the scene tree for the first time.
func _ready():
	
	#setPoints()
	$HpLabel.add_color_override("font_color", Color(1,1,1,1))
	$Power/PowerLabel.add_color_override("font_color", Color(1,1,1,1))
	$Power/Sprite.modulate = Color(Global.keywords.power.color)
	pass # Replace with function body.

func _process(delta):
	#if curAnimation == 'chunk' || curAnimation == 'poison':
		#oldColor.a -= delta*0.85
		#for i in range(chunkPoints.size()):
			#if !flipped:
				#chunkPoints[i].x-=delta*35
			#else:
				#chunkPoints[i].x+=delta*35
			
			#if oldColor.a <= 0:
				#curAnimation = 'none'
	for type in changing:
		if points[type]['cur']['height'] != points[type]['target']['height']:
			var speedMult = 0.6
			var speed = changeSpeed+ speedMult*CustomFormulas.diff(points[type]['cur']['height'], points[type]['target']['height'])
			points[type]['cur']['height'] = move_toward(points[type]['cur']['height'], points[type]['target']['height'], delta*speed)
			
		else:
			changing.remove(changing.find(type))
		if type == 'hp':
			var prop = float(points[type]['cur']['height']) / float(hbHeight)
			setColor(prop)
			
	if changing.size() > 0:
		setPoints('cur')
		
	update()
	
func copyValues(copy):
	points = copy.points
	maxHp = copy.maxHp
	updateHbWidth(maxHp)
	
func setValues(data, maxHp, targetOrCur = 'cur', animation = 'change'):
	
	curAnimation = animation
	$HpLabel.text = str(data.hp)
	updateHbWidth(maxHp)
	
	var firstSet = false
	if points.size() == 0:
		firstSet = true
	for i in data:
		var height = getHeightBasedOnHp(data[i])
		if firstSet:
			points[i] = {'target':{}, 'cur':{}}
			#points[i]['cur']['height'] = height
			#points[i]['target']['height'] = height
			
		points[i][targetOrCur]['height'] = height
		
		
	
	
	setPoints(targetOrCur)
	if targetOrCur == 'target':
		for type in points:
			if points[type]['target']['height'] != points[type]['cur']['height']:
				changing.append(type)
	setColor(float(data.hp) / float(maxHp))
	
	
func setPoints(targetOrCur): #set upper/lower points based on height
	for type in points:
		var upperY
		var lowerY
		
		if type == 'armor':
			upperY = -abs(points['hp'][targetOrCur]['height'])
			lowerY = upperY + points['armor'][targetOrCur]['height']
			
		elif type == 'hp':
			upperY = -abs(points['hp'][targetOrCur]['height'])
			lowerY = 0
		elif type == 'poison':
			upperY = -abs(points['hp'][targetOrCur]['height'])
			lowerY = upperY + points['poison'][targetOrCur]['height']
			
			
		points[type][targetOrCur]['upper'] = upperY
		points[type][targetOrCur]['lower']= lowerY
		
func setColor(prop):
	color = CustomFormulas.redToGreen(prop).darkened(0.1)
	$BgSprite.modulate = color.darkened(0.3)
		
func updateHbWidth(_maxHp):
	maxHp = _maxHp
	
	if Global.avgStats.hp > 0:
		var hpRatio = float(maxHp) / float(Global.avgStats.hp)
		
		hbWidth =  14*hpRatio
	
	olPoints = [] + generatePointArray(0, hbHeight)
	
func generatePointArray(lowerY, height, offset = 0, width = hbWidth):
	var xOffset = nearestEven(float(width) /2)
	
	var lowerLeft = Vector2(-xOffset-offset, lowerY)
	var lowerRight = Vector2(xOffset+offset, lowerY)
	var upperY = lowerY - height
	var upperLeft = Vector2(-xOffset-offset, upperY-offset)
	var upperRight = Vector2(xOffset+offset, upperY-offset)
	return [lowerLeft, lowerRight, upperRight, upperLeft]
	pass

func nearestEven(num):
	var result = int(round(num))
	if result % 2 != 0:
		if result > num:
			result -=1
		else:
			result +=1
	return result
	
func getHeightBasedOnHp(value):
	var prop = float(value) / float(maxHp)
	var hY = CustomFormulas.proportion(0, hbHeight, prop)
	return hY
		
func _draw():
	
	draw_colored_polygon(olPoints, Color(0,0,0,0.4))
	var hpPoints = [] + generatePointArray(points['hp']['cur']['lower'], points['hp']['cur']['height'])
	draw_colored_polygon(hpPoints, color)
	if changing.has('hp'):
		var changePoints
		var whiteHeight = CustomFormulas.diff(points['hp']['cur']['height'], points['hp']['target']['height'])
		if points['hp']['cur']['height'] > points['hp']['target']['height']: #hp going down
			
			changePoints = generatePointArray(points['hp']['target']['upper'], whiteHeight)
		else: #hp going up
			changePoints = generatePointArray(points['hp']['target']['upper'] + whiteHeight, whiteHeight)
		draw_colored_polygon(changePoints, Color(1,1,1))
	
	
		
	var olColor
	var w
	
	if points.poison.cur.height > 0:
		olColor = Color(Global.keywords.poison.color)#.darkened(0.5)
		w = 4
		var pHeight = points['poison']['cur']['height']
		var pLower = points['poison']['cur']['lower']
		
		var pPoints = []+generatePointArray(pLower, pHeight, -1)
		
		#draw_colored_polygon(pPoints, Global.keywords.poison.color)
		
		draw_line(pPoints[0], pPoints[1], olColor, w)
		draw_line(pPoints[1],pPoints[2], olColor, w)
		draw_line(pPoints[2], pPoints[3], olColor, w)
		draw_line(pPoints[3], pPoints[0], olColor, w)
	
	#OUTLINE
	olColor = color.darkened(0.6)
	w = 2
	draw_line(olPoints[0], olPoints[1], olColor, w)
	draw_line(olPoints[1], olPoints[2], olColor, w)
	draw_line(olPoints[2], olPoints[3], olColor, w)
	draw_line(olPoints[3], olPoints[0], olColor, w)
	
	if points['armor']['cur']['height'] > 0:
		olColor = Color(Global.keywords.armor.color)#.darkened(0.5)
		var armorHeight = points['armor']['cur']['height']
		var armorLower = points['armor']['cur']['lower']
		
	
		var armorPoints = []+generatePointArray(armorLower, armorHeight,4)
		
		#draw_colored_polygon(armorPoints, Global.keywords.armor.color)
		w = 6
		#draw_line(armorPoints[0], armorPoints[1], olColor, w)
		draw_line(armorPoints[1], armorPoints[2], olColor, w)
		draw_line(armorPoints[2], armorPoints[3], olColor, w)
		draw_line(armorPoints[3], armorPoints[0], olColor, w)
	

	
	
# EVERYTHING UNDER IS NO LONGER USED
func setHp(hp, _maxHp, animation = 'none'):
	if hp == 0:
		hp = 0.1
	var oldHp = curHp
	curHp = hp
	#maxHp = _maxHp
	var hpPercent
	#if maxHp <= 1:
		#hpPercent = 0
	#else:
		#hpPercent = float(hp-1)/float(maxHp-1)
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
	#setPoints()
	if hp!=oldHp:
		var lowerY = getHeightBasedOnHp(curHp)
		var upperY = getHeightBasedOnHp(oldHp)
		var heightLost = upperY - lowerY
		
		
		if animation == 'chunk' || animation == 'poison':
			
			
			var lowerBy = 0
			
			if animation == 'poison':
				oldColor = Color(Global.keywords.poison.color)
			chunkPoints = []
			lowerY -= curHeights['armor'] + curHeights['poison']
			upperY -= curHeights['armor'] + curHeights['poison']
			var xOffset = float(hbWidth) / 2.0
			chunkPoints.append(Vector2(-xOffset, -lowerY))
			chunkPoints.append(Vector2(xOffset, -lowerY))
			chunkPoints.append(Vector2(xOffset, -upperY))
			chunkPoints.append(Vector2(-xOffset, -upperY))
		
	curAnimation = animation
	
func setNormalPowerPos():
	pass

func setBattlePowerPos():
	pass

func setPower(num):
	power = num
	var prop = float(power) / float(1)
	powerHeight = CustomFormulas.proportion(0, hbHeight, prop)
	var g = CustomFormulas.proportion(1,0, prop/2.0)
	powerColor = Color(1,1,0)
	powerColor.g = g
	var darkness = CustomFormulas.proportion(0,0.8, prop/3.0)
	powerColor = powerColor.darkened(darkness)
	$Power/PowerLabel.text = str(num)
	
	setPowerPoints()
	

func setPointsOld():
	if Global.avgStats.hp > 0:
		var hpRatio = float(maxHp) / float(Global.avgStats.hp)
		
		hbWidth =  15*hpRatio
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
	
func setPowerPointsNewUnused():
	
	var xOffset = float(powerHeight)/2.0
		
	var yOffset = float(hbWidth)/ 2.0
	
	
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
		
		


func _drawOld():
	var w = 2
	var olColor = color.darkened(0.5)
	
	#black background
	draw_colored_polygon(olPoints, Color(0,0,0,0.4))
	
	
	
	# current health
	draw_colored_polygon(hPoints, color)
	# POISON
	#if poisonPoints.size() > 0:
		#draw_colored_polygon(poisonPoints, Global.keywords.poison.color)
	# HEALTHBAR OUTLINE
	olColor = color.darkened(0.5)
	draw_line(olPoints[0], olPoints[1], olColor, w)
	draw_line(olPoints[1], olPoints[2], olColor, w)
	draw_line(olPoints[2], olPoints[3], olColor, w)
	draw_line(olPoints[3], olPoints[0], olColor, w)
	# ARMOR
	#if armorPoints.size() > 0:
	if true:#armor
		olColor = Color(Global.keywords.armor.color).darkened(0.5)
		
		#draw_colored_polygon(armorPoints, Global.keywords.armor.color)
		#draw_line(armorPoints[0], armorPoints[1], olColor, w)
		#draw_line(armorPoints[1], armorPoints[2], olColor, w)
		#draw_line(armorPoints[2], armorPoints[3], olColor, w)
		#draw_line(armorPoints[3], armorPoints[0], olColor, w)
		
	if curAnimation == 'chunk' || curAnimation == 'poison':
		if chunkPoints.size() >= 4:
			draw_colored_polygon(chunkPoints, oldColor)
	#if powerPoints.size() > 0:
		#olColor = powerColor.darkened(0.5)
		#draw_colored_polygon(powerPoints, powerColor)
		#draw_line(powerPoints[0], powerPoints[1], olColor, w)
		#draw_line(powerPoints[1], powerPoints[2], olColor, w)
		#draw_line(powerPoints[2], powerPoints[3], olColor, w)
		#draw_line(powerPoints[3], powerPoints[0], olColor, w)
	


func _on_Button_pressed():
	setHp(5, 10, 'chunk')
	pass # Replace with function body.
