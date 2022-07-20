extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var unit = null
var player = null
var type = ''
onready var button = $Button


# Called when the node enters the scene tree for the first time.
func _ready():
	
	#$Pos.position = rect_size / 2
	pass # Replace with function body.
	
func render(_type):
	type = _type
	setup()
	

func setup():
	if type == 'battle':
		$Button.modulate = Color(0.8,0.8,1, 0.2)
		button.hide()
		if unit!= null:
			unit.get_node('Type1').hide()
			unit.get_node('Type2').hide()
	else:
		button.show()
		if unit!=null:
			unit.get_node('Type1').show()
			unit.get_node('Type2').show()
	if type == 'store':
		
		$Button.modulate = Color(1,1,0.8)
	if type == 'bench':
		$Button.modulate = Color(0.9, 1, 0.8).darkened(0.3)
		
	if type == 'lineup':
		$Button.modulate = Color(0.9, 0.9, 1)
	if type == 'graveyard':
		pass

func fill(_unit):
	#print('filling ', type, ' spot with unit: ', _unit.id)
	
	if is_instance_valid(_unit.get_parent()):
		_unit.get_parent().empty()
	unit = _unit
	add_child(unit)
	unit.global_position = $Pos.global_position
	setup()
	
func empty(freeUnit = false):
	if unit!= null:
		remove_child(unit)
		if freeUnit:
			unit.queue_free()
		unit = null
	

			
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
	
	


func _on_Button_pressed():
	if !Global.player.battling:
		if unit!= null && unit != player.holding: #spot is full
			if type == 'store': #buy unit
				player.buyUnit(unit)
				
			elif type == 'bench' || 'lineup': #click spot with unit
				if player.holding== null: #grab unit
					player.holding = unit
					
				else:# swap units
					pass
					
		else: #spot is empty
			if type == 'store':
				pass
			else:
				if player.holding != null: #place held unit in empty spot
					
					fill(player.holding)
					player.holding = null
				else: # clicked empty spot
					pass
	pass # Replace with function body.


func _on_Button_mouse_entered():
	Global.player.spotHover(self)
	pass # Replace with function body.
