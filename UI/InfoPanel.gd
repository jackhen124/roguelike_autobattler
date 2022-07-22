extends Panel


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var elementIndicators = $ElementPanel/ElementIndicators
# Called when the node enters the scene tree for the first time.
func _ready():
	$UnitPanel.hide()
	var i = 0
	for elementName in Global.elementLibrary:
		var curInd = elementIndicators.get_child(i)
		curInd.name = elementName
		
		
		curInd.get_node('TextureRect').texture = load('res://types/sprites/'+elementName+'.png')
		curInd.connect('hover', self, 'elementHover', [curInd.name])
		i+=1
	pass # Replace with function body.


func spotHover(spot):
	if spot.unit != null:
		$UnitPanel.show()
		$UnitPanel/Sprite.texture = load(str('res://units/sprites/',spot.unit.unitName,'.png'))
		$UnitPanel/Type1.texture = load(str('res://types/sprites/',spot.unit.types[0],'.png'))
		$UnitPanel/Type2.texture = load(str('res://types/sprites/',spot.unit.types[1],'.png'))
		$UnitPanel/HealthIndicator.setHp(spot.unit.hp, spot.unit.maxHp, true)
		$UnitPanel/Description.generateDesc(spot.unit.desc)
	

func elementHover(elementName):
	$UnitPanel.hide()
	$ElementPanel/Description.elementName = elementName
	$ElementPanel/Description.generateDesc(Global.elementLibrary[elementName]['desc'])
	
func _on_Label_meta_hover_started(meta):
	pass # Replace with function body.
