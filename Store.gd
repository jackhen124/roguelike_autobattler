extends Panel


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	
	pass # Replace with function body.

func refresh(level = 1):
	for spot in $Selection.get_children():
		#var unit = load('res://units/Unit.tscn').instance()
		#var rand = Global.rng.randi_range(0, Global.unitLibrary.size()-1)
		var randomUnit = Global.randomUnitBasedOn(Global.player.stageNum)
		#unit.render(randomUnit)
		var unit = Global.instanceUnit(randomUnit)
		spot.empty(true)
		spot.render('store')
		spot.player = get_parent().get_parent()
		spot.fill(unit)
		



func _on_RerollButton_pressed():
	
	pass # Replace with function body.
