extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
signal hover
signal unhover
export var lightOnHover = false
var darkMod = Color(0.7, 0.7, 0.7)
var elementName
# Called when the node enters the scene tree for the first time.
func _ready():
	if lightOnHover:
		$TextureRect.modulate = darkMod
	else:
		$SynergyTiers.hide()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func render(_elementName):
	elementName = _elementName
	$TextureRect.texture = load('res://types/sprites/'+elementName+'.png')
	
	updateIndicators(0)

func _on_TextureButton_mouse_entered():
	hl()
	emit_signal('hover')
	pass # Replace with function body.


func _on_TextureButton_mouse_exited():
	if lightOnHover:
		unHl()
		
	emit_signal('unhover')
	pass # Replace with function body.
	
func updateIndicators(numUnits):
	var color = Color(Global.elementLibrary[elementName]['color'])
	#print(name+' unitsneeded size: '+str(Global.elementLibrary[elementName].unitsNeeded.size()))
	for i in $SynergyTiers.get_children().size():
		 
		if Global.elementLibrary[elementName].unitsNeeded.size() <= i:
			$SynergyTiers.get_node(str(i+1)).modulate.a = 0
			#print('	hid '+str(i+1))
		elif numUnits >= Global.elementLibrary[elementName].unitsNeeded[i]:
			$SynergyTiers.get_node(str(i+1)).show()
			#$SynergyTiers.get_node(str(i+1)).modulate = Color(2,2,2)
			$SynergyTiers.get_node(str(i+1)).modulate = color.lightened(0.2)
		else:
			$SynergyTiers.get_node(str(i+1)).show()
			var d = 0.2
			if i >0:
				if numUnits >= Global.elementLibrary[elementName].unitsNeeded[i-1] +1:
					d *=1.5
			#$SynergyTiers.get_node(str(i+1)).modulate = Color(d,d,d)
			$SynergyTiers.get_node(str(i+1)).modulate = color.darkened(1-d)

func hl():
	$TextureRect.modulate = Color(1,1,1)
	rect_scale = Vector2(1.35,1.35)

func unHl():
	rect_scale = Vector2(1,1)
	$TextureRect.modulate = darkMod	
