extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var unit = null
var player = null
export var type = ''
onready var button = $Button
var targetSpots = []

signal hover
signal unhover

var swapFromSpot = null
var giveUnit = null
# Called when the node enters the scene tree for the first time.
func _ready():
	$Particles.hide()
	if type == 'sell':
		$CoinLabel.hide()
	$Target.hide()
	#$Pos.position = rect_size / 2
	pass # Replace with function body.
	
func render(_type):
	type = _type
	connect('hover', Global.player.infoPanel, 'unitHover')
	connect('unhover', Global.player.infoPanel, 'unitUnhover')
	setup()
	
func _process(delta):
	update()

func setup():
	if type == 'battle':
		#$Sprite.hide()
		
		
		$Sprite.hide()
	else:
		
		$Sprite.show()
		button.show()
		if unit!=null:
			unit.get_node('Type1').show()
			unit.get_node('Type2').show()
	if type == 'store':
		$Sprite.self_modulate =Color(1,1,1,0.5)
		
		$CoinLabel.isPrice = true
	else:
		$CoinLabel.hide()
	if type == 'bench':
		$Sprite.self_modulate =Color(1,1,1,0.5)
		
	if type == 'lineup':
		$Sprite.self_modulate =Color(1,1,1,0.5)
	
		$Sprite.show()
		
	if type == 'graveyard':
		pass
	

func fill(newUnit, emptyUnitsOldSpot = true):
	#print('filling ', type, ' spot with unit: ', _unit.id)
	if type == 'store':
		modulate.a = 1
	
	if is_instance_valid(newUnit.get_parent()):
		#if type == 'sell' && unit!=null:
			#unit.queue_free()
		newUnit.get_parent().empty()
	unit = newUnit
	
	add_child(unit)
	unit.global_position = $Pos.global_position
	if type == 'store':
		$CoinLabel.setCoins(Global.unitLibrary[unit.id]['tier'])
	if type == 'lineup':
		#call_deferred('updateSynergies')
		get_parent().updateSynergies()
	if type == 'bench' || type == 'graveyard':
		unit.resetCurStats()
		unit.updateInfo()
	if type == 'sell':
		
		Global.player.unitSold(unit)
		unit.die()
		#empty()
		
		
func finishSwap():
	
	swapFromSpot.fill(giveUnit)
	
	
func updateSynergies():
	get_parent().needsSynergyUpdate = true
	
func empty(freeUnit = false):
	#$CoinLabel.hide()
	if type == 'store':
		modulate.a = 0.2
	if unit!= null:
		remove_child(unit)
		if freeUnit:
			unit.queue_free()
		unit = null
		if type == 'lineup':
			get_parent().updateSynergies()
			#call_deferred('updateSynergies')

			
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
	
	


func _on_Button_pressed():
	if type != 'battle':
		if unit!= null && unit != Global.player.holding: #spot is full
			if type == 'store': #buy unit
				Global.player.buyUnit(unit)
				Global.player.unitInfoPanel.hide()
			elif type == 'bench' || 'lineup': #click spot with unit
				if Global.player.holding== null: #grab unit
					Global.player.holding = unit
					
				elif Global.player.holding != null:# swap units
					var unitGet = Global.player.holding
					var unitGive = unit
					var otherSpot = Global.player.holding.get_parent()
					
					remove_child(unitGive)
					otherSpot.remove_child(unitGet)
					fill(unitGet)
					otherSpot.fill(unitGive)
					
					
					Global.player.holding = null
					
					pass
					
		else: #spot is empty
			
			if type == 'store':
				pass
			else:
				if Global.player.holding != null: #place held unit in empty spot
					
					fill(Global.player.holding)
					Global.player.holding = null
				else: # clicked empty spot
					pass
			
	pass # Replace with function body.
	
func highlight(color = Color(1,1,1)):
	$Sprite.show()
	$Sprite.modulate = color
	$Sprite.modulate.a = 1
	
	$Sprite.self_modulate.a = 1
	
func targetHighlight(spot):
	#spot.get_node('Sprite').modulate = Color(1.5,0.8,0.8,1)
	spot.get_node('Target').show()
	targetSpots.append(spot)
	



	
func unhighlight():
	$Sprite.modulate = Color(1,1,1)
	$Sprite.hide()
	$Target.hide()
	for target in targetSpots:
		target.unhighlight()
	targetSpots = []
	
func _draw():
	pass
	#if targetSpots.size() > 0:
		#for i in targetSpots.size():
			#draw_line($Sprite.position, targetSpots[i].get_node('Sprite').global_position - global_position, Color(1,1,1), 5)


func _on_Button_mouse_entered():
	if is_instance_valid(Global.player):
		if !is_instance_valid(Global.player.cam):
			return
		var curCam = Global.player.cam
		var y = $Pos.global_position.y - Global.player.unitInfoPanel.rect_size.y / 2
		var yOffset = 200
		if $Pos.global_position.y > curCam.get_camera_screen_center().y:
			yOffset = -abs(yOffset)
		y += yOffset
		var x = $Pos.global_position.x - Global.player.unitInfoPanel.rect_size.x / 2
		Global.player.unitInfoPanel.rect_global_position = Vector2(x,y)
		Global.player.unitInfoPanel.render(unit)
	if is_instance_valid(unit):
		emit_signal('hover', unit)
		$Sprite.self_modulate.a = 1
		if type != 'battle':
			$Particles.show()
	pass # Replace with function body.


func _on_Button_mouse_exited():
	unHover()
	#$Sprite/Sprite.hide()
	pass # Replace with function body.

func unHover():
	$Particles.hide()
	$Sprite.self_modulate.a = 0.3
	if is_instance_valid(unit):
		emit_signal('unhover')
	Global.player.unitInfoPanel.hide()
