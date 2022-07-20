extends Panel


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$UnitPanel.hide()
	pass # Replace with function body.


func spotHover(spot):
	if spot.unit != null:
		$UnitPanel.show()
		$UnitPanel/Sprite.texture = load(str('res://units/sprites/',spot.unit.unitName,'.png'))
		$UnitPanel/Type1.texture = load(str('res://types/sprites/',spot.unit.types[0],'.png'))
		$UnitPanel/Type2.texture = load(str('res://types/sprites/',spot.unit.types[1],'.png'))
		$UnitPanel/HealthIndicator.set(spot.unit.hp, spot.unit.maxHp)
		$UnitPanel/Label.text = spot.unit.desc
	
