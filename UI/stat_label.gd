extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var goingUp = false
var goingDown = false

var upperLimit = -40
onready var tween = $Tween
var time = 0.9
var tweenTrans = Tween.TRANS_QUAD
var curAmount = null
var color

var flipped = false
# Called when the node enters the scene tree for the first time.
func _ready():
	
	pass # Replace with function body.
	
func flip():
	flipped = true
	setAmount(curAmount)

func setAmount(amount):
	
	
	
		
	#print('rendering label: '+label.text)	
	if Global.keywords[name].has('color'):
		color = Color(Global.keywords[name].color)#.lightened(0.2)
	elif Global.elementLibrary[name].has('color'):
		color = Color(Global.elementLibrary[name].color)#.lightened(0.2)
	if amount < 0:
		color = color.contrasted()
	get_node("Panel").modulate = color
	get_node("Label").add_color_override("font_color", color.lightened(0.2))
	
	
		
	if amount == 0:
		hide()
		#modulate = Color(0.5,0.5,0.5,0.5)
	else:
		show()
		modulate = Color(1,1,1,1)
	showChange(amount)
	
	setText()
	
func setText():
	if Global.keywords[name].has('abrev'):
		$Label.text = Global.keywords[name]['abrev']
	else:
		$Label.text = name
	if flipped:
		$Label.text += ' '+str(curAmount)
	else:
		$Label.text = str(curAmount)+' '+$Label.text
	
func showChange(newAmount):
	if curAmount!= newAmount:
		if curAmount!= null:
			var newChange = load('res://UI/StatusChange.tscn').instance()
			add_child(newChange)
			newChange.flipped = flipped
			var change = newAmount - curAmount
			if change > 0:
				change = '+'+str(change)
			newChange.get_node('Label').text = str(change)
			newChange.get_node('Panel').modulate = color
			newChange.get_node("Label").add_color_override("font_color", Color(0,0,0))
			newChange.start()
	curAmount = newAmount

func render(statusName, amount):
	show()
	#print('rendering label: '+statusName+ '  '+str(amount))
	curAmount = amount
	
	
	var text = ''
	
	if Global.keywords[statusName].has('abrev'):
		text = Global.keywords[statusName]['abrev']
	else:
		text = statusName
	
	
		
	#print('rendering label: '+label.text)	
	if Global.keywords[statusName].has('color'):
		color = Color(Global.keywords[statusName].color)#.lightened(0.2)
	elif Global.elementLibrary[statusName].has('color'):
		color = Color(Global.elementLibrary[statusName].color)#.lightened(0.2)
	if amount < 0:
		color = color.contrasted()
	$Movable.get_node("Panel").modulate = color
	$Movable.get_node("Label").add_color_override("font_color", color.lightened(0.2))
	


func _on_Tween_tween_all_completed():
	if goingUp:
		goingUp = false
		goingDown = true
		tween.interpolate_property($Movable, "rect_position:y",
		$Movable.rect_position.y, 0, time *0.75,
		tweenTrans, Tween.EASE_IN)
		tween.start()
	pass # Replace with function body.
