extends Panel


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func render(unit):
	if !is_instance_valid(unit):
		hide()
		return
	show()
	
	$HealthIndicator.copyValues(unit.get_node('HealthIndicator'))
	$AttackIndicator.setAttack(unit.curStats.power)
	$ElementIndicator1.render(unit.types[0])
	$ElementIndicator2.render(unit.types[1]) 
	$Description.generateDesc(unit.desc)
	$Name.text = unit.id

