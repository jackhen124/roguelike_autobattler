extends Panel


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var elementIndicators = $ElementPanel/ElementIndicators
# Called when the node enters the scene tree for the first time.
func _ready():
	
	var i = 0
	for elementName in Global.elementLibrary:
		var curInd = elementIndicators.get_child(i)
		curInd.name = elementName
		curInd.render(elementName)
		
		
		#curInd.get_node('TextureRect').texture = load('res://types/sprites/'+elementName+'.png')
		curInd.connect('hover', self, 'elementHover', [curInd.name])
		#curInd.updateIndicators(0)
		i+=1
	pass # Replace with function body.


func unitHover(unit):
	$ElementPanel/ElementIndicators.get_node(unit.types[0]).hl()
	$ElementPanel/ElementIndicators.get_node(unit.types[1]).hl()
	
func unitUnhover():
	for ind in $ElementPanel/ElementIndicators.get_children():
		ind.unHl()

func elementHover(elementName):
	
	$ElementPanel/Description.elementName = elementName
	$ElementPanel/Description.generateDesc(Global.elementLibrary[elementName]['desc'])
	
func _on_Label_meta_hover_started(meta):
	pass # Replace with function body.

func updateSynergies(typeCounts):
	for element in typeCounts:
		$ElementPanel/ElementIndicators.get_node(element).updateIndicators(typeCounts[element])
