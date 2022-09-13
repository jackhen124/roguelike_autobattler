extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export var disToCover = 100
var startDisToCover 
export var percentVertical = 0

var minPos
var maxPos

var synergyTiers = {}
var typeCounts = {}


var enemyEffects = {}
var allyEffects = {}


# Called when the node enters the scene tree for the first time.
func _ready():
	startDisToCover = disToCover
	updatePositions()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	update()
	pass
func updatePositions():
	disToCover = CustomFormulas.proportion(startDisToCover, startDisToCover*0.75, percentVertical)
	var i = 0
	var numSpots = get_children().size()
	#print('setting up group with disTocover: ',disToCover, ' and numSpots: ',numSpots)
	var xOffset = (float(disToCover)/float(numSpots+1)) * (1-percentVertical)
	var yOffset = (float(disToCover)/float(numSpots+1)) * percentVertical
	var vectorOffset = Vector2(xOffset, yOffset)
	#print('offset: ',offset)
	var vectorDisToCover = Vector2(disToCover*(1-percentVertical), disToCover*percentVertical)
	minPos = -vectorDisToCover/2
	maxPos = minPos  + vectorOffset + (vectorOffset*get_children().size())
	for spot in get_children():
		
		
		#var pos = -float(disToCover)/2 + offset + offset*i
		
		
		var pos = -vectorDisToCover/2 + vectorOffset + (vectorOffset*i)
		

		spot.position = pos
		spot.get_node('Button').modulate.a = 1-percentVertical
			
		i+=1

func _draw():
	#draw_circle(Vector2(0,0), 60, Color(1,1,1, 0.1))
	#draw_line(minPos, maxPos, Color(1,1,1), 2)
	#draw_line(minPos, maxPos, Color(1,1,1), 2)
	pass

func getUnits():
	var result = []
	for spot in get_children():
		result.append(spot.unit)
	return result
	
func updateSynergies():
	typeCounts = {}
	for spot in get_children():
		if spot.unit != null:
			
			for type in spot.unit.types:
				
				if !typeCounts.has(type):
					typeCounts[type] = 1
				else:
					typeCounts[type] +=1
			spot.unit.resetCurStats()
	for type in typeCounts:
		synergyTiers[type] = 0
		var curEffectAmount = 0
		for tierIndex in Global.elementLibrary[type].unitsNeeded.size():
			if typeCounts[type] >= Global.elementLibrary[type].unitsNeeded[tierIndex]:
				curEffectAmount =  Global.elementLibrary[type].effectPerStack[tierIndex]
				synergyTiers[type] +=1
		if curEffectAmount > 0:
		
			for spot in get_children():
				if spot.unit != null:
					match type:
						'aquatic':
							enemyEffects['aquatic'] = curEffectAmount
					match type:
						'earthen':
							spot.unit.changeStat('armor', curEffectAmount)
					match type:
						'solar':
							allyEffects['solar'] = curEffectAmount
					match type:
						'toxic':
							enemyEffects['toxic'] = curEffectAmount
					match type:
						'glacial':
							enemyEffects['glacial'] = curEffectAmount
					match type:
						'lunar':
							allyEffects['lunar'] = curEffectAmount
					match type:
						'floral':
							spot.unit.changeStat('regeneration', curEffectAmount)
	if name== 'LineupSpots':
		Global.player.infoPanel.updateSynergies(typeCounts)
