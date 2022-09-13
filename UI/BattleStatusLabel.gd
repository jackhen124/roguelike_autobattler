extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var goingUp = false
var goingDown = false
onready var label = $Movable/Label
var upperLimit = -40
onready var tween = $Tween
var time = 0.9
var tweenTrans = Tween.TRANS_QUAD
var curAmount = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	
	pass # Replace with function body.



func render(statusName, amount, isChange):
	show()
	#print('rendering label: '+statusName+ '  '+str(amount))
	curAmount = amount
	
	label = $Movable/Label
	var text = ''
	label.text = ''
	if Global.keywords[statusName].has('abrev'):
		text = Global.keywords[statusName]['abrev']
	else:
		text = statusName
	if isChange:
		label.text += text + ' '
		if amount > 0:
			
			label.text += '+'

		label.text += str(amount)
	else:
		label.text += str(amount) + ' '
		label.text += text
		
	#print('rendering label: '+label.text)	
	if Global.keywords[statusName].has('color'):
		modulate = Color(Global.keywords[statusName].color)#.lightened(0.2)
	elif Global.elementLibrary[statusName].has('color'):
		modulate = Color(Global.elementLibrary[statusName].color)#.lightened(0.2)
	
	if isChange:
		tween = $Tween
		goingUp = true
		$Movable.rect_position.y = 50
		
		tween.interpolate_property($Movable, "rect_position:y",
		$Movable.rect_position.y, -40, time,
		tweenTrans, Tween.EASE_OUT)
		tween.start()


func _on_Tween_tween_all_completed():
	if goingUp:
		goingUp = false
		goingDown = true
		tween.interpolate_property($Movable, "rect_position:y",
		$Movable.rect_position.y, 0, time *0.75,
		tweenTrans, Tween.EASE_IN)
		tween.start()
	pass # Replace with function body.
